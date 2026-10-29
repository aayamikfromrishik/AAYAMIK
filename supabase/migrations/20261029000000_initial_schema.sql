-- =============================================================================
-- AAYAMIK — leftover construction material marketplace
-- Initial schema.
--
-- Core rules enforced here (not in the app, so they cannot be bypassed):
--   1. Listing free. Buyer pays a small unlock fee to see the seller's exact
--      location and phone number.
--   2. Exact location and phone are only readable after the unlock is paid.
--   3. Listing text may not contain phone numbers, emails, links or
--      "WhatsApp me"-style contact hints.
--   4. Photos stay private until the moderation function approves them
--      (no faces, no phone numbers, no QR codes).
--   5. Payments are recorded only by server-side functions (service role).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Types
-- -----------------------------------------------------------------------------
create type public.listing_status as enum ('draft', 'active', 'sold', 'removed');
create type public.material_condition as enum ('new', 'unused_surplus', 'used_good', 'used_fair');
create type public.image_status as enum ('pending', 'approved', 'rejected');
create type public.unlock_status as enum ('created', 'paid', 'failed', 'refunded', 'duplicate_paid');
create type public.report_reason as enum (
  'price_mismatch', 'contact_details_in_listing', 'fake_listing',
  'already_sold', 'offensive', 'other'
);
create type public.refund_reason as enum ('seller_no_response', 'already_sold');
create type public.refund_status as enum ('pending', 'approved', 'rejected');

-- -----------------------------------------------------------------------------
-- Unlock fee
--   up to ₹1,000            -> ₹10 flat
--   ₹1,001 – ₹50,000        -> 1% (rounded to the nearest rupee)
--   ₹50,001 – ₹1,00,000     -> ₹500 flat
--   above ₹1,00,000         -> ₹1,000 flat
-- -----------------------------------------------------------------------------
create function public.unlock_fee_rupees(price_rupees integer)
returns integer
language sql
immutable
strict
as $$
  select case
    when price_rupees <= 1000   then 10
    when price_rupees <= 50000  then round(price_rupees / 100.0)::integer
    when price_rupees <= 100000 then 500
    else 1000
  end
$$;

-- -----------------------------------------------------------------------------
-- Contact-detail detector, used for listing text and for text found in photos.
-- Returns true when the text looks like it contains a way to reach the seller
-- outside the app. Deliberately strict: a false positive just asks the seller
-- to rephrase, a false negative loses the commission.
-- -----------------------------------------------------------------------------
create function public.contains_contact_info(input text)
returns boolean
language plpgsql
immutable
as $$
declare
  t text;
  collapsed text;
  run text;
begin
  if input is null or btrim(input) = '' then
    return false;
  end if;

  t := lower(input);

  -- Emails, including "name (at) gmail (dot) com" and "name at gmail dot com".
  if t ~ '[a-z0-9._%+-]+\s*(@|\(at\)|\[at\])\s*[a-z0-9-]+\s*(\.|\(dot\)|\[dot\])\s*[a-z]{2,}'
     or t ~ '[a-z0-9._-]+\s+at\s+[a-z0-9-]+\s+dot\s+[a-z]{2,}' then
    return true;
  end if;

  -- UPI ids (name@okaxis) and social handles (@name).
  if t ~ '[a-z0-9._-]{2,}@[a-z]{2,}' or t ~ '(^|\s)@[a-z0-9_.]{3,}' then
    return true;
  end if;

  -- Links.
  if t ~ '(https?://|www\.|wa\.me|t\.me|bit\.ly|\m[a-z0-9-]{2,}\.(com|in|net|org|co|io|me|app|link)\M)' then
    return true;
  end if;

  -- Contact hints and messaging apps.
  if t ~ '\m(whats\s*app|watsapp|whatsap|wtsp|telegram|instagram|insta|facebook|gmail|yahoo|call\s+me|call\s+on|call\s+at|ring\s+me|dm\s+me|text\s+me|msg\s+me|message\s+me|contact\s+(me|on|at|no|number|details)|my\s+number|ph(one)?\s*(no|num|number)|mob(ile)?\s*(no|num|number)|cell\s*(no|number)|mo(\.|\s)\s*no)\M'
     or t ~ '\m(ph|phone|mob|mobile|cell|contact|tel)\s*[:#]' then
    return true;
  end if;

  -- Spelled-out digits ("nine eight seven ...").
  t := regexp_replace(t, '\mzero\M', '0', 'g');
  t := regexp_replace(t, '\mone\M', '1', 'g');
  t := regexp_replace(t, '\mtwo\M', '2', 'g');
  t := regexp_replace(t, '\mthree\M', '3', 'g');
  t := regexp_replace(t, '\mfour\M', '4', 'g');
  t := regexp_replace(t, '\mfive\M', '5', 'g');
  t := regexp_replace(t, '\msix\M', '6', 'g');
  t := regexp_replace(t, '\mseven\M', '7', 'g');
  t := regexp_replace(t, '\meight\M', '8', 'g');
  t := regexp_replace(t, '\mnine\M', '9', 'g');

  -- Letter look-alikes touching digits: 98o76 -> 98076, 4321o -> 43210, 9l23 -> 9123.
  t := regexp_replace(t, '(?<=\d)o(?=\d|[^a-z]|$)', '0', 'g');
  t := regexp_replace(t, '(?<=[^a-z]|^)o(?=\d)', '0', 'g');
  t := regexp_replace(t, '(?<=\d)[il](?=\d|[^a-z]|$)', '1', 'g');
  t := regexp_replace(t, '(?<=[^a-z]|^)[il](?=\d)', '1', 'g');

  -- Pass 1: numbers as written. Any 10+ digit run that holds an Indian mobile.
  for run in select m[1] from regexp_matches(t, '(\d{10,})', 'g') as m loop
    if run ~ '[6-9]\d{9}' then
      return true;
    end if;
  end loop;

  -- Pass 2: separators between digits removed ("98765 43210", "98-76-54-32-10",
  -- "9 8 7 6 5 4 3 2 1 0"). Only 10–13 digit runs count, so lists of sizes like
  -- "1200 1500 1800" do not trip it.
  collapsed := regexp_replace(t, '(?<=\d)[\s\-.()/+,_*|]{1,3}(?=\d)', '', 'g');
  for run in select m[1] from regexp_matches(collapsed, '(\d+)', 'g') as m loop
    if length(run) between 10 and 13 and run ~ '^(\+?91|0)?[6-9]\d{9}$' then
      return true;
    end if;
  end loop;

  return false;
end;
$$;

-- -----------------------------------------------------------------------------
-- Categories
-- -----------------------------------------------------------------------------
create table public.categories (
  id text primary key,
  name text not null,
  sort_order integer not null default 0
);

insert into public.categories (id, name, sort_order) values
  ('cement',            'Cement',                    10),
  ('steel',             'Steel & TMT Bars',          20),
  ('bricks_blocks',     'Bricks & Blocks',           30),
  ('sand_aggregates',   'Sand & Aggregates',         40),
  ('tiles_flooring',    'Tiles & Flooring',          50),
  ('stone_marble',      'Stone, Marble & Granite',   60),
  ('wood_plywood',      'Wood, Plywood & Laminates', 70),
  ('doors_windows',     'Doors & Windows',           80),
  ('glass_aluminium',   'Glass & Aluminium',         90),
  ('plumbing',          'Plumbing & Pipes',          100),
  ('sanitary',          'Sanitary & Bath Fittings',  110),
  ('electrical',        'Electrical & Wiring',       120),
  ('paint',             'Paint & Chemicals',         130),
  ('roofing',           'Roofing & Sheets',          140),
  ('hardware_tools',    'Hardware & Tools',          150),
  ('other',             'Other',                     999);

-- -----------------------------------------------------------------------------
-- Profiles
--   profiles          : public (name, city)
--   profile_contacts  : private (verified phone), filled from auth on sign-up
-- -----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(btrim(display_name)) between 2 and 60),
  city text check (city is null or char_length(city) <= 60),
  created_at timestamptz not null default now()
);

create table public.profile_contacts (
  user_id uuid primary key references auth.users (id) on delete cascade,
  phone text not null
);

create function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.phone is not null and new.phone <> '' then
    insert into public.profile_contacts (user_id, phone)
    values (new.id, '+' || ltrim(new.phone, '+'))
    on conflict (user_id) do update set phone = excluded.phone;
  end if;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert or update of phone on auth.users
  for each row execute function public.handle_new_auth_user();

-- Display names are public, so they get the same contact check.
create function public.check_profile_text()
returns trigger
language plpgsql
as $$
begin
  if public.contains_contact_info(new.display_name) or public.contains_contact_info(new.city) then
    raise exception 'CONTACT_INFO_NOT_ALLOWED'
      using hint = 'Names and cities cannot contain phone numbers, emails or links.';
  end if;
  return new;
end;
$$;

create trigger profiles_check_text
  before insert or update on public.profiles
  for each row execute function public.check_profile_text();

-- -----------------------------------------------------------------------------
-- Listings
--   listings           : public details, approximate location only
--   listing_locations  : exact address + coordinates, hidden until unlocked
-- -----------------------------------------------------------------------------
create table public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  category_id text not null references public.categories (id),
  title text not null check (char_length(btrim(title)) between 5 and 100),
  description text not null default '' check (char_length(description) <= 2000),
  quantity numeric(12, 2) not null check (quantity > 0),
  unit text not null check (unit in (
    'pieces', 'bags', 'kg', 'tonnes', 'sq_ft', 'sq_m', 'cu_ft', 'cu_m',
    'running_ft', 'metres', 'litres', 'boxes', 'sets', 'lot'
  )),
  price_rupees integer not null check (price_rupees between 1 and 100000000),
  unlock_fee_rupees integer generated always as (public.unlock_fee_rupees(price_rupees)) stored,
  condition public.material_condition not null,
  city text not null check (char_length(btrim(city)) between 2 and 60),
  area text not null check (char_length(btrim(area)) between 2 and 80),
  -- Rounded to 2 decimals (~1 km) by trigger from listing_locations.
  approx_lat numeric(5, 2),
  approx_lng numeric(5, 2),
  status public.listing_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sold_at timestamptz
);

create index listings_active_idx on public.listings (status, created_at desc);
create index listings_category_idx on public.listings (category_id) where status = 'active';
create index listings_city_idx on public.listings (lower(city)) where status = 'active';
create index listings_seller_idx on public.listings (seller_id);

create table public.listing_locations (
  listing_id uuid primary key references public.listings (id) on delete cascade,
  address text not null check (char_length(btrim(address)) between 5 and 300),
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180)
);

create function public.check_listing()
returns trigger
language plpgsql
as $$
begin
  if public.contains_contact_info(new.title)
     or public.contains_contact_info(new.description)
     or public.contains_contact_info(new.area)
     or public.contains_contact_info(new.city) then
    raise exception 'CONTACT_INFO_NOT_ALLOWED'
      using hint = 'Phone numbers, emails, links and WhatsApp/contact hints are not allowed. Buyers get your contact after they unlock the listing.';
  end if;

  if tg_op = 'UPDATE' then
    new.updated_at := now();
    if new.status = 'sold' and old.status <> 'sold' then
      new.sold_at := now();
    elsif new.status <> 'sold' then
      new.sold_at := null;
    end if;
  end if;

  return new;
end;
$$;

create trigger listings_check
  before insert or update on public.listings
  for each row execute function public.check_listing();

create function public.sync_approx_location()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    update public.listings set approx_lat = null, approx_lng = null where id = old.listing_id;
    return old;
  end if;

  update public.listings
     set approx_lat = round(new.lat::numeric, 2),
         approx_lng = round(new.lng::numeric, 2)
   where id = new.listing_id;
  return new;
end;
$$;

create trigger listing_locations_sync
  after insert or update or delete on public.listing_locations
  for each row execute function public.sync_approx_location();

-- -----------------------------------------------------------------------------
-- Listing images
--   Seller uploads to the private "listing-uploads" bucket and inserts a row
--   here (status = pending). The moderate-image function checks the photo and,
--   if clean, copies it to the public "listing-images" bucket.
-- -----------------------------------------------------------------------------
create table public.listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  upload_path text not null unique,
  public_path text,
  status public.image_status not null default 'pending',
  rejection_reason text,
  sort_order smallint not null default 0,
  created_at timestamptz not null default now()
);

create index listing_images_listing_idx on public.listing_images (listing_id, sort_order);

-- -----------------------------------------------------------------------------
-- Unlocks (one row per Razorpay order). Written only by server functions.
-- -----------------------------------------------------------------------------
create table public.unlocks (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  buyer_id uuid not null references auth.users (id) on delete cascade,
  fee_rupees integer not null check (fee_rupees > 0),
  status public.unlock_status not null default 'created',
  razorpay_order_id text not null unique,
  razorpay_payment_id text unique,
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  refunded_at timestamptz
);

create unique index unlocks_one_paid_per_buyer
  on public.unlocks (listing_id, buyer_id)
  where status = 'paid';
create index unlocks_buyer_idx on public.unlocks (buyer_id, created_at desc);

-- -----------------------------------------------------------------------------
-- Reports and refund requests
-- -----------------------------------------------------------------------------
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings (id) on delete cascade,
  reporter_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  reason public.report_reason not null,
  details text check (details is null or char_length(details) <= 1000),
  created_at timestamptz not null default now(),
  unique (listing_id, reporter_id)
);

create table public.refund_requests (
  id uuid primary key default gen_random_uuid(),
  unlock_id uuid not null unique references public.unlocks (id) on delete cascade,
  buyer_id uuid not null references auth.users (id) on delete cascade,
  reason public.refund_reason not null,
  status public.refund_status not null default 'pending',
  admin_note text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

-- -----------------------------------------------------------------------------
-- Access helpers (security definer so RLS policies don't recurse)
-- -----------------------------------------------------------------------------
create function public.has_unlocked(p_listing_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.unlocks
     where listing_id = p_listing_id
       and buyer_id = auth.uid()
       and status = 'paid'
  )
$$;

create function public.is_listing_seller(p_listing_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.listings
     where id = p_listing_id and seller_id = auth.uid()
  )
$$;

-- Can the current user see this user's phone?
--   yes for themselves; a buyer who paid to unlock one of their listings;
--   a seller whose listing this user paid to unlock (so the seller can call back).
create function public.can_see_contact(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select p_user_id = auth.uid()
      or exists (
        select 1
          from public.unlocks u
          join public.listings l on l.id = u.listing_id
         where u.status = 'paid'
           and ((u.buyer_id = auth.uid() and l.seller_id = p_user_id)
             or (u.buyer_id = p_user_id and l.seller_id = auth.uid()))
      )
$$;

-- -----------------------------------------------------------------------------
-- Row level security
-- -----------------------------------------------------------------------------
alter table public.categories        enable row level security;
alter table public.profiles          enable row level security;
alter table public.profile_contacts  enable row level security;
alter table public.listings          enable row level security;
alter table public.listing_locations enable row level security;
alter table public.listing_images    enable row level security;
alter table public.unlocks           enable row level security;
alter table public.reports           enable row level security;
alter table public.refund_requests   enable row level security;

create policy "categories are public" on public.categories
  for select using (true);

create policy "profiles are public" on public.profiles
  for select using (true);
create policy "users create own profile" on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy "users update own profile" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "phone visible after unlock" on public.profile_contacts
  for select to authenticated using (public.can_see_contact(user_id));

create policy "active listings are public" on public.listings
  for select using (status = 'active' or seller_id = auth.uid());
create policy "sellers create listings" on public.listings
  for insert to authenticated
  with check (seller_id = auth.uid() and status in ('draft', 'active'));
-- 'removed' is set by admins only; a removed listing cannot be edited back.
create policy "sellers update own listings" on public.listings
  for update to authenticated
  using (seller_id = auth.uid() and status <> 'removed')
  with check (seller_id = auth.uid() and status <> 'removed');
-- No delete policy: buyers' paid unlocks must survive. Sellers mark listings
-- 'sold' or move them back to 'draft' instead.

create policy "exact location visible to seller or after unlock" on public.listing_locations
  for select to authenticated
  using (public.is_listing_seller(listing_id) or public.has_unlocked(listing_id));
create policy "sellers add location" on public.listing_locations
  for insert to authenticated with check (public.is_listing_seller(listing_id));
create policy "sellers update location" on public.listing_locations
  for update to authenticated
  using (public.is_listing_seller(listing_id))
  with check (public.is_listing_seller(listing_id));

create policy "approved images are public" on public.listing_images
  for select using (status = 'approved' or public.is_listing_seller(listing_id));
create policy "sellers add pending images" on public.listing_images
  for insert to authenticated
  with check (
    public.is_listing_seller(listing_id)
    and status = 'pending'
    and public_path is null
    and rejection_reason is null
    and split_part(upload_path, '/', 1) = auth.uid()::text
  );
create policy "sellers delete own images" on public.listing_images
  for delete to authenticated using (public.is_listing_seller(listing_id));

create policy "buyers see own unlocks" on public.unlocks
  for select to authenticated using (buyer_id = auth.uid());
create policy "sellers see paid unlocks on their listings" on public.unlocks
  for select to authenticated
  using (status = 'paid' and public.is_listing_seller(listing_id));

create policy "users report listings" on public.reports
  for insert to authenticated with check (reporter_id = auth.uid());
create policy "users see own reports" on public.reports
  for select to authenticated using (reporter_id = auth.uid());

create policy "buyers see own refund requests" on public.refund_requests
  for select to authenticated using (buyer_id = auth.uid());

-- -----------------------------------------------------------------------------
-- App-facing functions
-- -----------------------------------------------------------------------------

-- Contact details for an unlocked listing (or your own). Raises NOT_UNLOCKED otherwise.
create function public.get_listing_contact(p_listing_id uuid)
returns table (
  seller_name text,
  seller_phone text,
  address text,
  lat double precision,
  lng double precision
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (public.has_unlocked(p_listing_id) or public.is_listing_seller(p_listing_id)) then
    raise exception 'NOT_UNLOCKED';
  end if;

  return query
    select p.display_name, pc.phone, ll.address, ll.lat, ll.lng
      from public.listings l
      join public.profiles p on p.id = l.seller_id
      left join public.profile_contacts pc on pc.user_id = l.seller_id
      left join public.listing_locations ll on ll.listing_id = l.id
     where l.id = p_listing_id;
end;
$$;

-- Refund rule:
--   already_sold        -> any time within 7 days of paying
--   seller_no_response  -> after 48 hours and within 7 days of paying
create function public.request_refund(p_unlock_id uuid, p_reason public.refund_reason)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  u public.unlocks;
  new_id uuid;
begin
  select * into u from public.unlocks where id = p_unlock_id and buyer_id = auth.uid();
  if not found or u.status <> 'paid' then
    raise exception 'UNLOCK_NOT_FOUND';
  end if;
  if u.paid_at < now() - interval '7 days' then
    raise exception 'REFUND_WINDOW_CLOSED';
  end if;
  if p_reason = 'seller_no_response' and u.paid_at > now() - interval '48 hours' then
    raise exception 'WAIT_48_HOURS'
      using hint = 'Give the seller 48 hours to respond before asking for a refund.';
  end if;

  insert into public.refund_requests (unlock_id, buyer_id, reason)
  values (u.id, u.buyer_id, p_reason)
  on conflict (unlock_id) do nothing
  returning id into new_id;

  if new_id is null then
    raise exception 'REFUND_ALREADY_REQUESTED';
  end if;
  return new_id;
end;
$$;

-- -----------------------------------------------------------------------------
-- Server-only functions (called by edge functions with the service role key)
-- -----------------------------------------------------------------------------

-- Validates an unlock request and returns the fee in rupees.
create function public.prepare_unlock(p_listing_id uuid, p_buyer_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  l public.listings;
begin
  select * into l from public.listings where id = p_listing_id;
  if not found or l.status <> 'active' then
    raise exception 'LISTING_NOT_AVAILABLE';
  end if;
  if l.seller_id = p_buyer_id then
    raise exception 'CANNOT_UNLOCK_OWN_LISTING';
  end if;
  if exists (
    select 1 from public.unlocks
     where listing_id = p_listing_id and buyer_id = p_buyer_id and status = 'paid'
  ) then
    raise exception 'ALREADY_UNLOCKED';
  end if;
  return l.unlock_fee_rupees;
end;
$$;

create function public.record_unlock_order(
  p_listing_id uuid,
  p_buyer_id uuid,
  p_fee_rupees integer,
  p_razorpay_order_id text
)
returns uuid
language sql
security definer
set search_path = public
as $$
  insert into public.unlocks (listing_id, buyer_id, fee_rupees, razorpay_order_id)
  values (p_listing_id, p_buyer_id, p_fee_rupees, p_razorpay_order_id)
  returning id
$$;

-- Marks an order paid. Idempotent: safe to call from both the app's verify
-- call and the Razorpay webhook. Returns the resulting status.
create function public.mark_unlock_paid(
  p_razorpay_order_id text,
  p_razorpay_payment_id text,
  p_amount_paise integer
)
returns public.unlock_status
language plpgsql
security definer
set search_path = public
as $$
declare
  u public.unlocks;
begin
  select * into u from public.unlocks where razorpay_order_id = p_razorpay_order_id for update;
  if not found then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if u.status in ('paid', 'duplicate_paid', 'refunded') then
    return u.status;
  end if;

  if p_amount_paise <> u.fee_rupees * 100 then
    raise exception 'AMOUNT_MISMATCH';
  end if;

  -- Buyer paid twice for the same listing (two orders): keep the first,
  -- flag this one for refund.
  if exists (
    select 1 from public.unlocks
     where listing_id = u.listing_id and buyer_id = u.buyer_id
       and status = 'paid' and id <> u.id
  ) then
    update public.unlocks
       set status = 'duplicate_paid', razorpay_payment_id = p_razorpay_payment_id, paid_at = now()
     where id = u.id;
    return 'duplicate_paid';
  end if;

  update public.unlocks
     set status = 'paid', razorpay_payment_id = p_razorpay_payment_id, paid_at = now()
   where id = u.id;
  return 'paid';
end;
$$;

create function public.mark_unlock_refunded(p_razorpay_payment_id text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.unlocks
     set status = 'refunded', refunded_at = now()
   where razorpay_payment_id = p_razorpay_payment_id
     and status in ('paid', 'duplicate_paid');
  update public.refund_requests r
     set status = 'approved', resolved_at = now()
    from public.unlocks u
   where u.id = r.unlock_id
     and u.razorpay_payment_id = p_razorpay_payment_id
     and r.status = 'pending';
$$;

-- Lock down function access.
revoke execute on function public.prepare_unlock(uuid, uuid) from public, anon, authenticated;
revoke execute on function public.record_unlock_order(uuid, uuid, integer, text) from public, anon, authenticated;
revoke execute on function public.mark_unlock_paid(text, text, integer) from public, anon, authenticated;
revoke execute on function public.mark_unlock_refunded(text) from public, anon, authenticated;
revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;
revoke execute on function public.sync_approx_location() from public, anon, authenticated;

grant execute on function public.prepare_unlock(uuid, uuid) to service_role;
grant execute on function public.record_unlock_order(uuid, uuid, integer, text) to service_role;
grant execute on function public.mark_unlock_paid(text, text, integer) to service_role;
grant execute on function public.mark_unlock_refunded(text) to service_role;

revoke execute on function public.get_listing_contact(uuid) from public, anon;
revoke execute on function public.request_refund(uuid, public.refund_reason) from public, anon;
grant execute on function public.get_listing_contact(uuid) to authenticated;
grant execute on function public.request_refund(uuid, public.refund_reason) to authenticated;

-- -----------------------------------------------------------------------------
-- Storage
--   listing-uploads : private, seller writes to "<user id>/<listing id>/<file>"
--   listing-images  : public, written only by the moderate-image function
-- -----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('listing-uploads', 'listing-uploads', false),
       ('listing-images', 'listing-images', true)
on conflict (id) do nothing;

create policy "sellers upload to own folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'listing-uploads' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "sellers read own uploads" on storage.objects
  for select to authenticated
  using (bucket_id = 'listing-uploads' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "sellers delete own uploads" on storage.objects
  for delete to authenticated
  using (bucket_id = 'listing-uploads' and (storage.foldername(name))[1] = auth.uid()::text);

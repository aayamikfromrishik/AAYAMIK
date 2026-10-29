-- Behaviour tests for the initial schema. Run with scripts/test-db.sh.
\set ON_ERROR_STOP 1
\set QUIET 1

-- Users: seller, buyer, other buyer
insert into auth.users (id, phone) values
  ('00000000-0000-0000-0000-00000000000a', '919876500001'),
  ('00000000-0000-0000-0000-00000000000b', '919876500002'),
  ('00000000-0000-0000-0000-00000000000c', '919876500003');

-- ---------------------------------------------------------------------------
\echo '1. unlock fee bands'
do $$
begin
  assert public.unlock_fee_rupees(1) = 10;
  assert public.unlock_fee_rupees(500) = 10;
  assert public.unlock_fee_rupees(1000) = 10;
  assert public.unlock_fee_rupees(1001) = 10;
  assert public.unlock_fee_rupees(1050) = 11;
  assert public.unlock_fee_rupees(25000) = 250;
  assert public.unlock_fee_rupees(50000) = 500;
  assert public.unlock_fee_rupees(50001) = 500;
  assert public.unlock_fee_rupees(100000) = 500;
  assert public.unlock_fee_rupees(100001) = 1000;
  assert public.unlock_fee_rupees(5000000) = 1000;
end $$;

-- ---------------------------------------------------------------------------
\echo '2. contact detector'
do $$
declare
  s text;
  blocked text[] := array[
    '9876543210',
    'call 98765 43210',
    '+91-98765-43210',
    '098765 43210',
    '9 8 7 6 5 4 3 2 1 0',
    '98-76-54-32-10',
    'nine eight seven six five four three two one zero',
    'nine 8 seven 6 five 4 three 2 one 0',
    '98765432l0',
    '98765 4321O',
    'whatsapp me for rates',
    'Whats App only',
    'contact me for best price',
    'Phone: 22',
    'mob no given after deal',
    'raj@gmail.com',
    'raj (at) gmail (dot) com',
    'raj at gmail dot com',
    'pay to raj@okaxis',
    'follow @rajbuilders',
    'see www.rajbuilders.com',
    'rajbuilders.in for photos',
    'https://example.org/x',
    'wa.me/919876543210'
  ];
  allowed text[] := array[
    '500 bags of ACC cement, 50 kg each',
    'Sizes 1200 1500 1800 mm',
    '6000 7000 8000 bricks available',
    'Price Rs 2,50,000 negotiable',
    'TMT bars 8mm 10mm 12mm 16mm',
    'Available at site. Great condition',
    'Installation material left over',
    'Mono block pump',
    'Solar cell - 20 pcs',
    'Tiles 600 x 600, 120 boxes',
    'One lot of two hundred bricks',
    'Phone cable 90 metres',
    'Andheri East, Mumbai',
    ''
  ];
begin
  foreach s in array blocked loop
    if not public.contains_contact_info(s) then
      raise exception 'should be blocked: %', s;
    end if;
  end loop;
  foreach s in array allowed loop
    if public.contains_contact_info(s) then
      raise exception 'should be allowed: %', s;
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
\echo '3. phone copied from auth on sign-up'
do $$
begin
  assert (select phone from public.profile_contacts
           where user_id = '00000000-0000-0000-0000-00000000000a') = '+919876500001';
end $$;

-- ---------------------------------------------------------------------------
\echo '4. seller creates a listing'
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false) as _jwt \gset

insert into public.profiles (id, display_name, city)
values ('00000000-0000-0000-0000-00000000000a', 'Raj Builders', 'Mumbai');

insert into public.listings (id, category_id, title, description, quantity, unit, price_rupees, condition, city, area)
values ('10000000-0000-0000-0000-000000000001', 'cement', 'ACC cement 50 kg bags',
        'Unused, kept dry under cover', 120, 'bags', 30000, 'unused_surplus', 'Mumbai', 'Andheri East');

insert into public.listing_locations (listing_id, address, lat, lng)
values ('10000000-0000-0000-0000-000000000001', 'Plot 12, MIDC Road, Andheri East', 19.118734, 72.869123);

do $$
begin
  assert (select unlock_fee_rupees from public.listings where id = '10000000-0000-0000-0000-000000000001') = 300;

  begin
    insert into public.listings (category_id, title, description, quantity, unit, price_rupees, condition, city, area)
    values ('steel', 'TMT bars 12mm', 'call 98765 43210', 2, 'tonnes', 90000, 'new', 'Mumbai', 'Powai');
    raise exception 'phone number in description was accepted';
  exception when raise_exception then
    assert sqlerrm = 'CONTACT_INFO_NOT_ALLOWED', sqlerrm;
  end;

  begin
    update public.profiles set display_name = 'Raj 9876543210' where id = auth.uid();
    raise exception 'phone number in display name was accepted';
  exception when raise_exception then
    assert sqlerrm = 'CONTACT_INFO_NOT_ALLOWED', sqlerrm;
  end;

  begin
    update public.listings set status = 'removed' where id = '10000000-0000-0000-0000-000000000001';
    raise exception 'seller set status removed';
  exception when insufficient_privilege then null;
  end;

  -- Images: must be pending and in own folder.
  begin
    insert into public.listing_images (listing_id, upload_path, status)
    values ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a/x/1.jpg', 'approved');
    raise exception 'seller self-approved an image';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.listing_images (listing_id, upload_path)
    values ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b/x/1.jpg');
    raise exception 'seller used another user''s folder';
  exception when insufficient_privilege then null;
  end;
  insert into public.listing_images (listing_id, upload_path)
  values ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a/10000000-0000-0000-0000-000000000001/1.jpg');
end $$;
reset role;

do $$
begin
  assert (select approx_lat from public.listings where id = '10000000-0000-0000-0000-000000000001') = 19.12;
  assert (select approx_lng from public.listings where id = '10000000-0000-0000-0000-000000000001') = 72.87;
end $$;

-- ---------------------------------------------------------------------------
\echo '5. anonymous visitor browses'
set role anon;
select set_config('request.jwt.claim.sub', '', false) as _jwt \gset
do $$
begin
  assert (select count(*) from public.listings) = 1;
  assert (select count(*) from public.listing_images) = 0, 'pending image visible';
  assert (select count(*) from public.listing_locations) = 0, 'anon read listing_locations';
  assert (select count(*) from public.profile_contacts) = 0, 'anon read phones';
  begin
    perform public.get_listing_contact('10000000-0000-0000-0000-000000000001');
    raise exception 'anon called get_listing_contact';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- ---------------------------------------------------------------------------
\echo '6. buyer before paying sees nothing private'
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000b', false) as _jwt \gset
do $$
begin
  assert (select count(*) from public.listing_locations) = 0;
  assert (select count(*) from public.profile_contacts) = 1, 'buyer should see only own phone';
  begin
    perform public.get_listing_contact('10000000-0000-0000-0000-000000000001');
    raise exception 'contact returned before payment';
  exception when raise_exception then
    assert sqlerrm = 'NOT_UNLOCKED', sqlerrm;
  end;
  begin
    insert into public.unlocks (listing_id, buyer_id, fee_rupees, razorpay_order_id, status)
    values ('10000000-0000-0000-0000-000000000001', auth.uid(), 1, 'order_fake', 'paid');
    raise exception 'buyer inserted own unlock';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.mark_unlock_paid('order_fake', 'pay_fake', 100);
    raise exception 'buyer called mark_unlock_paid';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- ---------------------------------------------------------------------------
\echo '7. server records the payment'
set role service_role;
do $$
declare
  fee integer;
begin
  begin
    perform public.prepare_unlock('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000a');
    raise exception 'seller allowed to unlock own listing';
  exception when raise_exception then
    assert sqlerrm = 'CANNOT_UNLOCK_OWN_LISTING', sqlerrm;
  end;

  fee := public.prepare_unlock('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b');
  assert fee = 300;
  perform public.record_unlock_order('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', fee, 'order_1');

  begin
    perform public.mark_unlock_paid('order_1', 'pay_1', 100);
    raise exception 'wrong amount accepted';
  exception when raise_exception then
    assert sqlerrm = 'AMOUNT_MISMATCH', sqlerrm;
  end;

  assert public.mark_unlock_paid('order_1', 'pay_1', 30000) = 'paid';
  assert public.mark_unlock_paid('order_1', 'pay_1', 30000) = 'paid', 'not idempotent';

  begin
    perform public.prepare_unlock('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b');
    raise exception 'second unlock allowed';
  exception when raise_exception then
    assert sqlerrm = 'ALREADY_UNLOCKED', sqlerrm;
  end;

  -- Two orders opened before either was paid: second payment is flagged.
  perform public.record_unlock_order('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000000b', fee, 'order_2');
  assert public.mark_unlock_paid('order_2', 'pay_2', 30000) = 'duplicate_paid';
end $$;
reset role;

-- ---------------------------------------------------------------------------
\echo '8. buyer after paying sees location and phone'
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000b', false) as _jwt \gset
do $$
declare
  r record;
begin
  select * into r from public.get_listing_contact('10000000-0000-0000-0000-000000000001');
  assert r.seller_phone = '+919876500001';
  assert r.address = 'Plot 12, MIDC Road, Andheri East';
  assert r.seller_name = 'Raj Builders';
  assert (select count(*) from public.listing_locations) = 1;
  assert (select count(*) from public.profile_contacts) = 2;

  begin
    perform public.request_refund((select id from public.unlocks where razorpay_order_id = 'order_1'), 'seller_no_response');
    raise exception 'refund allowed before 48 hours';
  exception when raise_exception then
    assert sqlerrm = 'WAIT_48_HOURS', sqlerrm;
  end;
  perform public.request_refund((select id from public.unlocks where razorpay_order_id = 'order_1'), 'already_sold');
  begin
    perform public.request_refund((select id from public.unlocks where razorpay_order_id = 'order_1'), 'already_sold');
    raise exception 'refund requested twice';
  exception when raise_exception then
    assert sqlerrm = 'REFUND_ALREADY_REQUESTED', sqlerrm;
  end;
end $$;
reset role;

-- ---------------------------------------------------------------------------
\echo '9. seller sees who unlocked, other users still see nothing'
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false) as _jwt \gset
do $$
begin
  assert (select count(*) from public.unlocks) = 1, 'seller should see only the paid unlock';
  assert (select count(*) from public.profile_contacts) = 2, 'seller should see buyer phone';
end $$;

select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000c', false) as _jwt \gset
do $$
begin
  assert (select count(*) from public.listing_locations) = 0;
  assert (select count(*) from public.profile_contacts) = 1;
  assert (select count(*) from public.unlocks) = 0;
end $$;
reset role;

-- ---------------------------------------------------------------------------
\echo '10. sold listing stays visible to the buyer who unlocked it'
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000a', false) as _jwt \gset
update public.listings set status = 'sold' where id = '10000000-0000-0000-0000-000000000001';
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000b', false) as _jwt \gset
do $$
begin
  assert (select status from public.listings where id = '10000000-0000-0000-0000-000000000001') = 'sold';
end $$;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000000c', false) as _jwt \gset
do $$
begin
  assert (select count(*) from public.listings) = 0, 'sold listing visible to a stranger';
end $$;
reset role;

-- ---------------------------------------------------------------------------
\echo '11. refund processed'
set role service_role;
select public.mark_unlock_refunded('pay_1') as _r \gset
reset role;
do $$
begin
  assert (select status from public.unlocks where razorpay_order_id = 'order_1') = 'refunded';
  assert (select status from public.refund_requests) = 'approved';
end $$;

\echo 'ALL TESTS PASSED'

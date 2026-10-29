-- A buyer who paid to unlock a listing keeps seeing it (in "My unlocks" and
-- the detail screen) after the seller marks it sold or moves it to draft.
create policy "unlocked listings stay visible to the buyer" on public.listings
  for select to authenticated
  using (public.has_unlocked(id));

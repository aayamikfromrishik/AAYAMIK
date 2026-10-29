# AAYAMIK

A free marketplace where builders resell leftover construction material
(cement, steel, tiles, bricks, pipes…) to other builders.

- **Listing is free.** No subscription.
- **Buyers pay a small unlock fee** to see the seller's exact location and phone number.
- **No contact details outside the app.** Phone numbers, emails, links, QR codes and
  human faces are blocked in listing text and photos.

## Unlock fee

| Listed price | Unlock fee |
|---|---|
| Up to ₹1,000 | ₹10 flat |
| ₹1,001 – ₹50,000 | 1% (rounded to the nearest rupee) |
| ₹50,001 – ₹1,00,000 | ₹500 flat |
| Above ₹1,00,000 | ₹1,000 flat |

**Refunds:** the buyer can get the unlock fee back within 7 days if the item was
already sold, or if the seller hasn't responded after 48 hours.

## How it works

```
Seller                          Server (Supabase)                        Buyer
──────                          ─────────────────                        ─────
Posts listing ───────────────▶  Blocks text with phone/email/links
Uploads photos ──────────────▶  moderate-image: rejects faces, QR codes,
                                phone numbers in photo; publishes clean ones
                                Public: title, price, photos, area, ~1 km map ◀── Browses
                                                                    ◀── Taps "Unlock (₹300)"
                                create-unlock-order → Razorpay order ──▶ Pays
                                verify-unlock-payment / webhook marks paid
                                Exact address + phone now readable ──▶ Calls seller
Sees who unlocked + their phone ◀─
```

The rules live in the database (row-level security), not in the app, so a
modified app can't get around them.

## What's built so far (step 1: backend)

| Path | What it does |
|---|---|
| `supabase/migrations/…_initial_schema.sql` | Tables, fee calculation, contact-detail detector, privacy rules, storage buckets |
| `supabase/functions/create-unlock-order` | Creates the Razorpay order for an unlock |
| `supabase/functions/verify-unlock-payment` | Confirms payment right after checkout so the contact unlocks instantly |
| `supabase/functions/razorpay-webhook` | Backup confirmation from Razorpay; also records refunds |
| `supabase/functions/moderate-image` | Checks each photo with Google Cloud Vision |
| `supabase/tests/local/` | Tests for fees, the contact detector and every privacy rule |
| `docs/RUNNING_COSTS.md` | What you pay, and when |

## Next steps

1. **Flutter app (Android first)**: phone OTP login, browse/search, post a listing
   with photos (on-phone face/QR/text pre-check with ML Kit), unlock with Razorpay,
   "My listings" and "My unlocks".
2. **Admin panel**: review reports, rejected photos and refund requests.
3. **Launch**: Play Store listing, privacy policy, terms.

## Running the tests

Database tests need Postgres 15+ server binaries installed locally:

```bash
./scripts/test-db.sh
```

Server function tests need [Deno](https://deno.com):

```bash
cd supabase/functions && deno test --allow-env _shared/
```

## Setting up the live backend

1. Create a project at [supabase.com](https://supabase.com) and install the Supabase CLI.
2. Link and push the schema:
   ```bash
   supabase link --project-ref <your-project-ref>
   ```
   ```bash
   supabase db push
   ```
3. In Supabase → Authentication → Providers, turn on **Phone** and connect an SMS
   provider (MSG91 or Twilio).
4. Set the function secrets:
   ```bash
   supabase secrets set RAZORPAY_KEY_ID=... RAZORPAY_KEY_SECRET=... RAZORPAY_WEBHOOK_SECRET=... GOOGLE_VISION_API_KEY=...
   ```
5. Deploy the functions:
   ```bash
   supabase functions deploy
   ```
6. In the Razorpay dashboard:
   - Turn on **automatic payment capture**.
   - Add a webhook pointing to `https://<project-ref>.supabase.co/functions/v1/razorpay-webhook`
     for the events `payment.captured` and `refund.processed`.
7. Process refunds from the Razorpay dashboard. The webhook marks them refunded in the app.

# BAAKI BUILD by AAYAMIK

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

## What's built

### Backend (`supabase/`)

| Path | What it does |
|---|---|
| `migrations/` | Tables, fee calculation, contact-detail detector, privacy rules, storage buckets |
| `functions/create-unlock-order` | Creates the Razorpay order for an unlock |
| `functions/verify-unlock-payment` | Confirms payment right after checkout so the contact unlocks instantly |
| `functions/razorpay-webhook` | Backup confirmation from Razorpay; also records refunds |
| `functions/moderate-image` | Checks each photo with Google Cloud Vision |
| `tests/local/` | Tests for fees, the contact detector and every privacy rule |

### Android app (`app/`, Flutter)

| Screen | What it does |
|---|---|
| Login | Mobile number + OTP |
| Browse | Search, category chips, city filter, endless list |
| Listing | Photos, price, details, approximate area; **Unlock** button (Razorpay); after paying: seller's phone, exact address, Call and Open in Maps |
| Sell material | Photos checked on the phone (faces, QR codes, phone numbers) before upload and again on the server; live unlock-fee preview; private pickup address and GPS pin |
| My listings | Status, how many buyers unlocked, edit, mark sold, hide; tap to see buyers' names and phone numbers |
| Unlocked | Everything you paid for, with refund requests |
| Account | Profile, fee table, listing rules, sign out |

See `docs/RUNNING_COSTS.md` for what you pay and when.

## Getting the APK

Every push builds an Android APK on GitHub:

1. Open the repo on GitHub → **Actions** → latest **CI** run.
2. Download **baaki-build-apk** at the bottom, unzip it, and install `app-release.apk` on an Android phone.

For the APK to connect to your backend, first add two repository secrets under
**Settings → Secrets and variables → Actions**:
- `SUPABASE_URL`: e.g. `https://abcd1234.supabase.co`
- `SUPABASE_PUBLISHABLE_KEY`: Supabase dashboard → Project Settings → API Keys

## Web version (trial)

The same app runs in the browser. Every push publishes it to Cloudflare Pages:

- `https://baaki-build.pages.dev/`: the real app, using your Supabase backend
- `https://baaki-build.pages.dev/demo/`: a demo with sample listings and no backend, for reviewing the design

One-time setup, as two more repository secrets:
- `CLOUDFLARE_ACCOUNT_ID`: Cloudflare dashboard → **Workers & Pages**, shown on the right
- `CLOUDFLARE_API_TOKEN`: Cloudflare → **My Profile → API Tokens → Create Token → Custom token**, with permission **Account · Cloudflare Pages · Edit**

Run the demo locally:

```bash
cd app && flutter run -d chrome --dart-define=DEMO=true
```

## Next steps

1. Create the Supabase, Razorpay and Google Cloud accounts and set up the backend (below).
2. Test the full flow on a phone with Razorpay **test mode** keys.
3. Admin panel: review reports, rejected photos and refund requests.
4. Launch: app icon, Play Store listing, privacy policy, terms.

## Running the tests

Database tests need Postgres 15+ server binaries installed locally:

```bash
./scripts/test-db.sh
```

App tests need [Flutter](https://flutter.dev):

```bash
cd app && flutter test
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
8. Run the app against it:
   ```bash
   cd app && flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>
   ```

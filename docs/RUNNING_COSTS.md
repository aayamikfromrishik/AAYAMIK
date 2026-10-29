# AAYAMIK: Running Costs

Prices as of October 2026. Dollar prices are converted at about ₹88 = $1.
Check each provider's pricing page before you pay, because prices change.

## 1. Pay once

| What | Cost | Why you need it |
|---|---|---|
| Google Play developer account | **$25 ≈ ₹2,200** | Lets you publish the Android app on the Play Store |
| SMS sender registration (DLT) | **≈ ₹5,900** | Indian law requires it before your app can send OTP login SMS. You register once on a telecom DLT portal, for example Jio TrueConnect |

## 2. Pay every year

| What | Cost | Needed? |
|---|---|---|
| Domain name (e.g. aayamik.in) | **₹800 – ₹1,200 / year** | Yes: for the website, privacy policy page and support email |
| Apple developer account | **$99 ≈ ₹8,700 / year** | **Only if** you also want an iPhone app |

## 3. Pay every month (the only subscription)

| What | Cost | When |
|---|---|---|
| Supabase (database, logins, photo storage, server functions) | **₹0** (Free plan) | While building and testing |
| Supabase Pro | **$25 ≈ ₹2,200 / month** | From launch day. Free projects go to sleep after a week without use, so a live app needs Pro |

## 4. Pay only when used (grows with your users)

| What | Cost | Example |
|---|---|---|
| Razorpay (collects the unlock fee) | **No monthly fee.** About **2% + 18% GST** of each payment | ₹10 fee → Razorpay keeps about ₹0.24. ₹500 fee → about ₹12 |
| OTP login SMS (MSG91 or similar) | **≈ ₹0.15 – ₹0.25 per SMS** | 1,000 logins ≈ ₹250 |
| Photo checks (Google Cloud Vision) | **First ~1,000 photos a month free**, then ≈ ₹400 per 1,000 photos | 3,000 photos a month ≈ ₹800 |
| Maps on Android | **₹0** | Showing a map in the Android app is free. Address search can use free OpenStreetMap |

## 5. Free tools (₹0)

- Flutter (builds the app), VS Code / Android Studio, GitHub
- Firebase Crashlytics (crash reports)
- Zoho Mail free plan (support email on your domain)

## What you'll actually pay

| Stage | Monthly bill |
|---|---|
| Building and testing | **₹0** |
| Just launched (~1,000 users) | **≈ ₹3,000** (Supabase ₹2,200 + SMS ₹300 + photo checks ₹400) |
| Growing (~10,000 users) | **≈ ₹5,000 – ₹8,000** |

**One-time to launch:** about **₹9,000** (Play Store + DLT + first year of domain).
Add ₹8,700 a year if you also publish on iPhone.

**Break-even at launch:** about ₹3,000 a month in unlock fees. That's roughly 300 small unlocks at ₹10, or 10 unlocks at ₹300.

## Not needed to start

- Company registration or GST registration. GST becomes compulsory once yearly turnover crosses ₹20 lakh. Ask a CA when you get close.
- Paid servers, hosting or app-building subscriptions. Supabase covers all of this.

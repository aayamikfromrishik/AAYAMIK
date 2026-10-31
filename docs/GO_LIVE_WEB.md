# BAAKI BUILD: making the web app live

Every push to GitHub builds the web app automatically (**Actions → Deploy web app**).
Each build contains two sites:

| Folder | What it is |
|---|---|
| `/` | The real app, connected to your Supabase backend |
| `/demo/` | Demo with sample listings, simulated login and payment, no backend |

There are two ways to put it online. **Option A** is recommended: after a 5-minute setup,
every future change goes live by itself.

---

## Option A: automatic (Cloudflare Pages + GitHub), recommended

### 1. Create a free Cloudflare account
Sign up at **dash.cloudflare.com**.

### 2. Copy your Account ID
Go to **Workers & Pages**. The **Account ID** is shown on the right side. Copy it.

### 3. Create an API token
1. Click your profile (top right) → **My Profile** → **API Tokens** → **Create Token**.
2. Next to **Create Custom Token**, click **Get started**.
3. Name it `GitHub deploy`.
4. Under **Permissions**, choose **Account** → **Cloudflare Pages** → **Edit**.
5. Click **Continue to summary** → **Create Token**, then copy the token. It's shown only once.

### 4. Add two secrets in GitHub
Go to the AAYAMIK repo → **Settings** → **Secrets and variables** → **Actions** →
**New repository secret**:

| Name | Value |
|---|---|
| `CLOUDFLARE_ACCOUNT_ID` | the Account ID from step 2 |
| `CLOUDFLARE_API_TOKEN` | the token from step 3 |

### 5. Publish
Go to **Actions** → **Deploy web app** → **Run workflow** → **Run workflow**.
After about 4 minutes:

- **https://baaki-build.pages.dev/** is the real app
- **https://baaki-build.pages.dev/demo/** is the demo

From now on, every update goes live automatically.

---

## Option B: manual upload (no tokens needed)

1. GitHub → **Actions** → **Deploy web app** → open the latest green run.
2. At the bottom, under **Artifacts**, download **baaki-build-web** and unzip it.
3. Cloudflare → **Workers & Pages** → **Create** → **Pages** → **Upload assets**.
4. Project name: `baaki-build` → **Create project**.
5. Drag in the **contents** of the unzipped folder: `index.html` and the other files, not the folder itself.
6. Click **Deploy site**.

Repeat these steps whenever the app changes. This is why Option A is easier.

The same folder also works on Netlify ("Deploy manually") or any static web host.

---

## Optional: your own address, e.g. `baakibuild.aayamik.com`

1. Cloudflare → **Workers & Pages** → **baaki-build** → **Custom domains** → **Set up a custom domain**.
2. Enter `baakibuild.aayamik.com` and continue.
3. Cloudflare shows a **CNAME** record. Add it wherever aayamik.com's DNS is managed:
   - **Type:** CNAME
   - **Name:** `baakibuild`
   - **Target:** `baaki-build.pages.dev`
4. Wait a few minutes for the "Active" status. HTTPS is set up automatically.

---

## What works once it's live

| Feature | Needs |
|---|---|
| Login (test number 9999999999 / OTP 123456), profile, browse, sell form | Nothing more |
| Posting photos | `GOOGLE_VISION_API_KEY` secret, then **Deploy backend** |
| Unlock payment | Razorpay secrets, then **Deploy backend** |
| Real OTP SMS to any number | SMS provider (MSG91 connector, before launch) |

## After it's live: one Razorpay setting

For live payments (not test mode), Razorpay asks for your website address during
activation. Give them the final address (for example `https://baakibuild.aayamik.com`).

# Touri Website

Official landing website for **Touri Taxi** and **Touri Taxi Driver**.

## Stack

- Next.js 16 (App Router)
- TypeScript
- Tailwind CSS 4
- Framer Motion

## Run locally

```bash
cd admin/touri-website
cp .env.example .env.local
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000). Arabic is the default locale (`/ar`). English lives at `/en`.

## Scripts

```bash
npm run lint
npm run build
npm start
```

## Configuration

Copy `.env.example` to `.env.local` and fill:

- `NEXT_PUBLIC_SITE_URL` — production origin for canonical URLs, sitemap, and Open Graph
- App Store / Google Play URLs for both apps
- Contact email (optional; WhatsApp is already filled from the customer app)
- Social profile URLs

Empty values hide the related buttons or icons. Do not invent store links.

## Deploy

The app is a standard Next.js site.

- **Vercel:** import `admin/touri-website`, set the env vars, deploy.
- **Firebase Hosting:** `npm run build` then serve the Next.js output with a Node/Firebase adapter if you need SSR. For a static-like setup, Vercel or similar Node hosting is simpler.
- Point `NEXT_PUBLIC_SITE_URL` at the live domain before launch.

## Notes

- Flutter apps under `admin/ara_oatan_app` and `admin/mndob-main` are not modified.
- Privacy copy is taken from the existing Touri Taxi policy.
- Terms are a clearly marked draft for legal review.


```markdown
# AllWeb3Jobs.io

A **Next.js 14** job board for Web3 careers with **two Telegram bots** that let you post jobs instantly by pasting text — no form-filling.

##  Features

-  **Two categories**  
  Internships / Juniors / Hackathons, and Mid-level / Senior / Lead

-  **Fuzzy search** (Fuse.js) – works even with typos

-  **Instant posting**  
  Send a message to a Telegram bot → job appears on the site in seconds

-  **Mobile‑first responsive design**

-  **SEO**  
  Dynamic sitemap, JSON‑LD structured data, clean slugs

-  **Static generation with ISR**  
  Revalidates every hour, or on‑demand

-  **Two separate bots** for the two categories

##  Tech Stack

| Area          | Tech                          |
|---------------|-------------------------------|
| Frontend      | Next.js 14 (pages router), TypeScript, Tailwind CSS |
| Search        | Fuse.js                       |
| Bots          | node-telegram-bot-api         |
| Infrastructure| systemd (optional)            |

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/Trinityweb3/AllWeb3Jobs.io.git
   cd AllWeb3Jobs.io
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**  
   Copy `.env.local.example` (if present) or create `.env.local` manually:
   ```bash
   cp .env.local.example .env.local
   ```
   Fill in the values (see [Environment variables](#environment-variables) below).

4. **Run the dev server**
   ```bash
   npm run dev
   ```
   The site will be available at `http://localhost:3000`.

##  Environment Variables

Create a `.env.local` file with the following keys:

```env
NEXT_PUBLIC_SITE_URL=http://localhost:3000   # your actual domain in production
REVALIDATION_SECRET=choose-a-random-string
BOT_API_SECRET=choose-another-random-string
BOT1_TOKEN=123456:ABC...                     # from @BotFather
BOT2_TOKEN=789012:XYZ...                     # from @BotFather
```

- `REVALIDATION_SECRET` – used for the `/api/revalidate` endpoint  
- `BOT_API_SECRET` – used by the bots to authenticate with the internal API  
- `BOT1_TOKEN` / `BOT2_TOKEN` – Telegram bot tokens; **never commit them to Git**

##  How to Add Jobs

### Option 1 – Telegram bots (recommended)

1. Start the bot process:
   ```bash
   node bots.js
   ```
   *(set `USE_PROXY` in `bots.js` if you’re in a country that blocks Telegram)*

2. Send a **text message** to  
   - Bot #1 (Internships / Juniors)  
   - Bot #2 (Mid / Senior)

   - **First line** → job title  
   - **Everything else** → full description  
   - The first 200 characters become the short preview on cards.

3. The job appears instantly on the site (the API triggers on‑demand revalidation).

### Option 2 – Manual JSON file

Place a `.json` file inside `data/jobs/` with the following structure:

```json
{
  "title": "Junior Rust Developer",
  "description_full": "Full description here...",
  "category": "internships-juniors",
  "company": "Acme Inc.",
  "location": "Remote",
  "type": "Full-time"
}
```

- Only `title` and `description_full` are required.  
- `category` must be one of `internships-juniors` or `mid-senior-leads`.

The site will pick it up at the next ISR revalidation (or trigger it manually, see below).

## On‑Demand Revalidation

To rebuild pages immediately (e.g. after adding a job manually), call:

```
GET /api/revalidate?secret=YOUR_REVALIDATION_SECRET
```

## Project Structure

```
.
├── components/          # Layout, JobCard, SearchBar, SimilarJobs
├── lib/                 # Core logic: jobs, similarity, slugify, siteConfig
├── pages/               # Next.js routes
│   ├── api/             # add-job endpoint, revalidate endpoint
│   ├── category/        # Dynamic category pages
│   ├── jobs/            # Dynamic job detail pages
│   └── sitemap.xml.tsx  # Dynamic sitemap
├── data/jobs/           # JSON job files (created by bot or manually)
├── styles/globals.css   # Tailwind base
├── bots.js              # Telegram bot script (polling)
├── deploy.sh            # Example Arch Linux deployment script with systemd
└── package.json
```

## Deployment (Production)

1. Build and start:
   ```bash
   npm run build
   npm start
   ```
2. To run the bots alongside, use a process manager like **systemd** or **pm2**.  
   On Arch Linux, the included `deploy.sh` can set up systemd services for both Next.js and the bots.
3. Make sure your domain points to the server and the environment variables are set correctly.

**Note for countries with Telegram blocks:**  
Enable the SOCKS5 proxy inside `bots.js` (already prepared) and install the required package:
```bash
npm install socks-proxy-agent
```

## ⚖️ License / Usage

This project is shared **for viewing and educational purposes only**.  
Commercial use, redistribution for profit, or deployment as a paid service without explicit permission is **prohibited**.

Made with ❤️ for the allweb3jobs.io by [Trinityweb3](https://github.com/Trinityweb3).
```

Follow these steps to get AllWeb3Jobs running locally on your machine.  
The project consists of a **Next.js frontend** and a **Rust backend**, plus a shared data folder.

### 1. Clone the repository

```bash
git clone https://github.com/Trinityweb3/AllWeb3Jobs.git
cd AllWeb3Jobs
```


### 2. Create required folders

The backend and frontend expect certain directories to exist.  
Create them in the project root (where you cloned the repo):

```bash
mkdir -p data/jobs data/content frontend/public/images
```

Set proper permissions (for local development you can open them fully):

```bash
chmod -R 755 data
```

### 3. Set up environment variables

#### Backend (Rust)

Create the file `backend/.env` with the following content:

```env
PORT=3001
BOT_TOKEN=YOUR_TELEGRAM_BOT_TOKEN
BOT_API_SECRET=choose-any-random-string
ALLOWED_USERS=YOUR_TELEGRAM_ID,ANOTHER_ID
PUBLIC_DIR=../frontend/public/images
API_URL=http://localhost:3001/api/add-content
```

- `BOT_TOKEN`: obtain from [@BotFather](https://t.me/BotFather) after creating a new bot.
- `BOT_API_SECRET`: any random string you choose (keep it secret).
- `ALLOWED_USERS`: your Telegram user ID (get it via [@userinfobot](https://t.me/userinfobot)). Multiple IDs separated by commas. Only these users will be able to post content via the bot.
- `PUBLIC_DIR`: path where images uploaded to the bot will be stored (usually the frontend public images folder).
- `API_URL`: the address of your own backend API (keep as `http://localhost:3001/api/add-content` for local development).

#### Frontend (Next.js)

Create the file `frontend/.env.local` with:

```env
NEXT_PUBLIC_SITE_URL=http://localhost:3000
CMC_API_KEY=YOUR_COINMARKETCAP_API_KEY
```

- `NEXT_PUBLIC_SITE_URL`: your site URL (local development uses `http://localhost:3000`).
- `CMC_API_KEY`: obtain a free API key from [CoinMarketCap](https://coinmarketcap.com/api/).

### 4. Install dependencies

#### Frontend (Node.js)

```bash
cd frontend
npm install
```

#### Backend (Rust)

Make sure you have [Rust installed](https://rustup.rs/). Then:

```bash
cd backend
cargo build
```

The first build may take several minutes.

### 5. Create the Telegram bot (optional for now)

If you haven't already:

1. Chat with [@BotFather](https://t.me/BotFather) on Telegram.
2. Send `/newbot` and follow the instructions.
3. Copy the token you receive and paste it into `backend/.env` as `BOT_TOKEN`.
4. Send `/mybots`, select your bot, go to **Bot Settings** → **Allow Groups?** (turn off if you want the bot to work only in private chats).
5. Use [@userinfobot](https://t.me/userinfobot) to find your Telegram user ID and add it to `ALLOWED_USERS` in the backend `.env` file.

### 6. Run the backend

From the project root:

```bash
cd backend
cargo run
```

You should see:
```
🚀 Server listening on 0.0.0.0:3001
```

The bot will start automatically and begin polling.  
If you see an error about `BOT_TOKEN missing`, double‑check your `.env` file.

### 7. Run the frontend

Open a second terminal window, from the project root:

```bash
cd frontend
npm run dev
```

You should see:
```
- Local:        http://localhost:3000
```

Now visit `http://localhost:3000` in your browser.

### 8. Access from your phone (same Wi‑Fi)

1. Find your computer’s local IP address:
   ```bash
   ip -4 addr show | grep inet
   ```
   Look for an address like `192.168.1.x` (not `127.0.0.1`).

2. Make sure port 3000 is allowed in your firewall (temporarily):
   ```bash
   sudo ufw allow 3000/tcp
   ```

3. On your phone (connected to the same Wi‑Fi), open a browser and navigate to:
   ```
   http://YOUR_IP:3000
   ```
   For example: `http://192.168.1.5:3000`

If you need access from outside your local network (e.g., via mobile data), use [ngrok](https://ngrok.com/) instead of opening your router’s ports.

### 9. Test the Telegram bot

1. Open Telegram and find your bot (by its username).
2. Send `/start` – you should see a menu with buttons: Intern, Mid, News, Activity, Token Analysis, Cancel.
3. Select a section, then send a text message (optionally with a photo).
4. The bot will reply “✅ Content posted!” and the post will appear on the frontend under the appropriate section (e.g., News, Token page).

If the bot replies with an error, check the console where the backend is running – it will show detailed error messages.

### 10. Adding your first content manually (without the bot)

If you prefer, you can manually create JSON files inside `data/jobs/` or `data/content/`.  
For example, a news post:

```json
{
  "title": "Bitcoin hits new ATH",
  "description_full": "Bitcoin has just reached a new all‑time high of $120,000.",
  "category": "news",
  "date": "2026-05-18T12:00:00Z",
  "token_symbol": null,
  "image_url": ""
}
```

Save it as `data/content/bitcoin-new-ath.json`. The frontend will pick it up on the next page rebuild (or immediately in development mode after a refresh).

### Troubleshooting

- **Backend doesn’t start**: check that `backend/.env` exists and is correctly formatted.
- **Bot ignores your messages**: make sure your Telegram ID is in `ALLOWED_USERS`. If the list is empty, the bot will allow everyone (only for development).
- **Frontend can’t fetch coin data**: verify `CMC_API_KEY` is set in `frontend/.env.local`.
- **Images from the bot don’t appear**: ensure `frontend/public/images` exists and is writable by the backend process.
- **“Could not find module” errors**: run `npm install` again in the `frontend` folder.
- **Rust compilation errors**: update the Rust toolchain (`rustup update`) and try `cargo clean` then `cargo build` again.

Everything is now set up. You can start building on top of this foundation!

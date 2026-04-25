const TelegramBot = require('node-telegram-bot-api');
require('dotenv').config({ path: '.env.local' });

const BOT1_TOKEN = process.env.BOT1_TOKEN;
const BOT2_TOKEN = process.env.BOT2_TOKEN;
const API_URL = process.env.API_URL || 'http://localhost:3000/api/add-job';
const BOT_API_SECRET = process.env.BOT_API_SECRET;

const bot1 = new TelegramBot(BOT1_TOKEN, { polling: true });
const bot2 = new TelegramBot(BOT2_TOKEN, { polling: true });

async function postJob(text, category) {
  const response = await fetch(API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-bot-token': BOT_API_SECRET,
    },
    body: JSON.stringify({ text, category }),
  });
  if (!response.ok) {
    const err = await response.json();
    throw new Error(err.error || 'API error');
  }
  return await response.json();
}

bot1.on('message', async (msg) => {
  const chatId = msg.chat.id;
  const text = msg.text;
  if (!text) return bot1.sendMessage(chatId, 'Please send a text message.');
  try {
    const result = await postJob(text, 'internships-juniors');
    bot1.sendMessage(chatId, `✅ Job added: ${result.slug}`);
  } catch (e) {
    bot1.sendMessage(chatId, `❌ Error: ${e.message}`);
  }
});

bot2.on('message', async (msg) => {
  const chatId = msg.chat.id;
  const text = msg.text;
  if (!text) return bot2.sendMessage(chatId, 'Please send a text message.');
  try {
    const result = await postJob(text, 'mid-senior-leads');
    bot2.sendMessage(chatId, `✅ Job added: ${result.slug}`);
  } catch (e) {
    bot2.sendMessage(chatId, `❌ Error: ${e.message}`);
  }
});

console.log('Telegram bots are polling...');

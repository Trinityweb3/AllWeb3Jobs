#!/bin/bash
set -e

# ─── Цвета для вывода ───────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ─── Проверка прав (нужен root для systemd) ───────
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Этот скрипт нужно запускать от root (sudo).${NC}"
   exit 1
fi

# ─── Запрос токенов, если не переданы аргументами ──
echo -e "${YELLOW}=== Настройка переменных окружения ===${NC}"

if [ ! -f .env.local ]; then
    read -p "Введите домен сайта (https://your-domain.com): " DOMAIN
    read -p "Секрет для ревалидации (произвольная строка): " REVALIDATION_SECRET
    read -p "Секрет API ботов (произвольная строка): " BOT_API_SECRET
    read -p "Токен Telegram бота №1 (internships-juniors): " BOT1_TOKEN
    read -p "Токен Telegram бота №2 (mid-senior-leads): " BOT2_TOKEN

    # Запись в .env.local
    cat > .env.local << EOF
NEXT_PUBLIC_SITE_URL=${DOMAIN}
REVALIDATION_SECRET=${REVALIDATION_SECRET}
BOT_API_SECRET=${BOT_API_SECRET}
BOT1_TOKEN=${BOT1_TOKEN}
BOT2_TOKEN=${BOT2_TOKEN}
EOF
    echo -e "${GREEN}.env.local создан.${NC}"
else
    echo -e "${YELLOW}.env.local уже существует, пропускаем.${NC}"
fi

# ─── Установка Node.js и npm, если нужно ───────────
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}Установка Node.js и npm...${NC}"
    pacman -Syu --noconfirm nodejs npm
else
    echo -e "${GREEN}Node.js уже установлен.${NC}"
fi

# ─── Установка зависимостей проекта ────────────────
echo -e "${YELLOW}Установка npm зависимостей...${NC}"
npm install

# Установка дополнительно для ботов
npm install node-telegram-bot-api dotenv

# ─── Сборка проекта ─────────────────────────────────
echo -e "${YELLOW}Сборка Next.js...${NC}"
npm run build

# ─── Создание файла bots.js (если его ещё нет) ─────
if [ ! -f bots.js ]; then
    cat > bots.js << 'BOTSCRIPT'
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
BOTSCRIPT
    echo -e "${GREEN}bots.js создан.${NC}"
fi

# ─── Создание systemd сервиса для Next.js ───────────
PROJECT_DIR=$(pwd)
USER=$(logname)

cat > /etc/systemd/system/nextjs.service << EOF
[Unit]
Description=Next.js Web3 Job Board
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/bin/npm start
Restart=always
RestartSec=5
Environment=NODE_ENV=production
EnvironmentFile=${PROJECT_DIR}/.env.local

[Install]
WantedBy=multi-user.target
EOF

# ─── Создание systemd сервиса для ботов ─────────────
cat > /etc/systemd/system/job-bots.service << EOF
[Unit]
Description=Telegram Job Bots
After=network.target

[Service]
Type=simple
User=${USER}
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/bin/node bots.js
Restart=always
RestartSec=10
EnvironmentFile=${PROJECT_DIR}/.env.local

[Install]
WantedBy=multi-user.target
EOF

# ─── Активация и запуск сервисов ───────────────────
systemctl daemon-reload
systemctl enable nextjs.service
systemctl start nextjs.service
systemctl enable job-bots.service
systemctl start job-bots.service

echo -e "${GREEN}=== Развёртывание завершено! ===${NC}"
echo "Сайт:      ${DOMAIN}"
echo "Боты запущены и работают в фоне."
echo "Проверьте статус: systemctl status nextjs job-bots"
import type { NextApiRequest, NextApiResponse } from 'next';
import { HttpsProxyAgent } from 'https-proxy-agent';

// Кеш для экономии лимитов
let cachedData: any = null;
let lastFetch = 0;
const CACHE_TTL = 300_000; // 5 минут

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const now = Date.now();
  if (cachedData && now - lastFetch < CACHE_TTL) {
    return res.status(200).json(cachedData);
  }

  const apiKey = process.env.CMC_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: 'CMC_API_KEY not configured' });
  }

  try {
    const url = 'https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest?limit=100&convert=USD';
    const headers = { 'X-CMC_PRO_API_KEY': apiKey };

    // Настройка прокси
    const proxyUrl = process.env.CMC_PROXY;
    const fetchOptions: any = { headers };
    if (proxyUrl) {
      fetchOptions.agent = new HttpsProxyAgent(proxyUrl);
    }

    const response = await fetch(url, fetchOptions);

    if (!response.ok) {
      throw new Error(`CMC API error: ${response.status}`);
    }

    const data = await response.json();
    const coins = data.data.map((coin: any) => ({
      id: coin.symbol.toLowerCase(),
      symbol: coin.symbol,
      name: coin.name,
      image: `https://s2.coinmarketcap.com/static/img/coins/64x64/${coin.id}.png`,
      current_price: coin.quote.USD.price,
      price_change_percentage_24h: coin.quote.USD.percent_change_24h,
      market_cap: coin.quote.USD.market_cap,
      total_volume: coin.quote.USD.volume_24h,
      cmc_rank: coin.cmc_rank,
    }));

    cachedData = coins;
    lastFetch = now;
    res.status(200).json(coins);
  } catch (error) {
    console.error('CMC fetch error:', error);
    res.status(500).json({ error: 'Failed to fetch market data' });
  }
}
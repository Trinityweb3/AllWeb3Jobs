import { useState, useEffect } from 'react';
import useSWR from 'swr';

// Top 10 Web3-related token IDs on CoinGecko
const TOKEN_IDS = [
  'ethereum',
  'binancecoin',
  'matic-network',
  'arbitrum',
  'optimism',
  'avalanche-2',
  'near',
  'aptos',
  'sui',
  'solana',
];

interface CoinData {
  id: string;
  symbol: string;
  name: string;
  image: string;
  current_price: number;
  price_change_percentage_24h: number;
  market_cap: number;
  total_volume: number;
}

const fetcher = (url: string) => fetch(url).then((res) => res.json());

export default function CryptoDashboard() {
  const [favorites, setFavorites] = useState<string[]>([]);

  // Load favorites from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem('cryptoWatchlist');
    if (stored) {
      setFavorites(JSON.parse(stored));
    }
  }, []);

  // Save favorites when changed
  useEffect(() => {
    localStorage.setItem('cryptoWatchlist', JSON.stringify(favorites));
  }, [favorites]);

  const toggleFavorite = (id: string) => {
    setFavorites((prev) =>
      prev.includes(id) ? prev.filter((f) => f !== id) : [...prev, id]
    );
  };

  // Build CoinGecko URL with our token IDs
  const url = `https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=${TOKEN_IDS.join(
    ','
  )}&order=market_cap_desc&per_page=10&page=1&sparkline=false&price_change_percentage=24h`;

  // SWR fetches every 30 seconds for live updates
  const { data, error } = useSWR<CoinData[]>(url, fetcher, {
    refreshInterval: 30000,
    fallbackData: [], // fallback if first fetch fails (not using SSR initial data for simplicity, but you can pass it)
  });

  // Sort: favorites first, then the rest
  const sortedData = data
    ? [...data].sort((a, b) => {
        const aFav = favorites.includes(a.id) ? 0 : 1;
        const bFav = favorites.includes(b.id) ? 0 : 1;
        return aFav - bFav;
      })
    : [];

  if (error) {
    return (
      <div className="bg-red-50 text-red-600 p-4 rounded-lg mb-6">
        Failed to load market data. Please try again later.
      </div>
    );
  }

  return (
    <section className="mb-10">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold text-gray-900">Web3 Market Watch</h2>
        <span className="text-xs text-gray-500">Auto‑updates every 30s</span>
      </div>

      {/* Responsive table with horizontal scroll on small screens */}
      <div className="overflow-x-auto rounded-lg border border-gray-200">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                #
              </th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                Price
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                24h %
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider hidden sm:table-cell">
                Market Cap
              </th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider hidden md:table-cell">
                Volume
              </th>
              <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">
                Watch
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {sortedData.map((coin, index) => {
              const isFavorite = favorites.includes(coin.id);
              const change = coin.price_change_percentage_24h ?? 0;

              return (
                <tr key={coin.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                    {index + 1}
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap">
                    <div className="flex items-center gap-3">
                      <img src={coin.image} alt={coin.name} className="w-6 h-6 rounded-full" />
                      <div>
                        <div className="text-sm font-medium text-gray-900">{coin.name}</div>
                        <div className="text-xs text-gray-500 uppercase">{coin.symbol}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap text-sm text-right font-mono">
                    ${coin.current_price?.toLocaleString()}
                  </td>
                  <td
                    className={`px-4 py-3 whitespace-nowrap text-sm text-right font-mono ${
                      change >= 0 ? 'text-green-600' : 'text-red-600'
                    }`}
                  >
                    {change >= 0 ? '+' : ''}
                    {change.toFixed(2)}%
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap text-sm text-right text-gray-500 hidden sm:table-cell">
                    ${coin.market_cap?.toLocaleString()}
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap text-sm text-right text-gray-500 hidden md:table-cell">
                    ${coin.total_volume?.toLocaleString()}
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap text-center">
                    <button
                      onClick={() => toggleFavorite(coin.id)}
                      className={`text-lg transition-colors ${
                        isFavorite ? 'text-yellow-500' : 'text-gray-300 hover:text-yellow-400'
                      }`}
                      title={isFavorite ? 'Remove from watchlist' : 'Add to watchlist'}
                    >
                      {isFavorite ? '★' : '☆'}
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </section>
  );
}
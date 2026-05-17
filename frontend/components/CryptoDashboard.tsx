import { useState, useEffect } from 'react';
import useSWR from 'swr';

interface CoinData {
  id: string;
  symbol: string;
  name: string;
  image: string;
  current_price: number;
  price_change_percentage_24h: number | null;
  market_cap: number;
  total_volume: number;
  cmc_rank: number;
}

const fetcher = (url: string) => fetch(url).then((res) => {
  if (!res.ok) throw new Error('Network error');
  return res.json();
});

export default function CryptoDashboard() {
  const [favorites, setFavorites] = useState<string[]>([]);
  const [expanded, setExpanded] = useState(false);

  // Загружаем избранное
  useEffect(() => {
    const stored = localStorage.getItem('cryptoWatchlist');
    if (stored) setFavorites(JSON.parse(stored));
  }, []);
  useEffect(() => {
    localStorage.setItem('cryptoWatchlist', JSON.stringify(favorites));
  }, [favorites]);

  const toggleFavorite = (id: string) => {
    setFavorites((prev) =>
      prev.includes(id) ? prev.filter((f) => f !== id) : [...prev, id]
    );
  };

  // Данные с нашего API (статически генерируется на сервере раз в 5 мин)
  const { data, error } = useSWR<CoinData[]>('/api/coins', fetcher, {
    refreshInterval: 300_000, // обновление каждые 5 мин (бережём лимит CMC)
    revalidateOnFocus: false,
  });

  if (error) {
    return (
      <div className="bg-red-50 text-red-600 p-4 rounded-lg mb-6">
        Failed to load market data. Please try again later.
      </div>
    );
  }

  if (!data) {
    return (
      <div className="bg-gray-50 text-gray-600 p-4 rounded-lg mb-6 animate-pulse">
        Loading market data...
      </div>
    );
  }

  // Сортируем: избранные вверх, внутри избранных – по рангу CMC
  const sorted = [...data].sort((a, b) => {
    const aFav = favorites.includes(a.id) ? 0 : 1;
    const bFav = favorites.includes(b.id) ? 0 : 1;
    if (aFav !== bFav) return aFav - bFav;
    return a.cmc_rank - b.cmc_rank;
  });

  // Показываем топ‑10 или все 100
  const visibleCoins = expanded ? sorted : sorted.slice(0, 10);

  return (
    <section className="mb-10">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold text-gray-900">Web3 Market Watch</h2>
        <span className="text-xs text-gray-500">Top 100 by CoinMarketCap</span>
      </div>

      <div className="overflow-x-auto rounded-lg border border-gray-200">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">#</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Price</th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">24h %</th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase hidden sm:table-cell">Market Cap</th>
              <th className="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Watch</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {visibleCoins.map((coin) => {
              const isFavorite = favorites.includes(coin.id);
              const change = coin.price_change_percentage_24h ?? 0;
              return (
                <tr key={coin.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                    {coin.cmc_rank}
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
                  <td className="px-4 py-3 whitespace-nowrap text-center">
                    <button
                      onClick={() => toggleFavorite(coin.id)}
                      className={`text-lg transition-colors ${
                        isFavorite ? 'text-yellow-500' : 'text-gray-400 hover:text-yellow-400'
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

      {/* Кнопка развернуть/свернуть */}
      <div className="mt-4 text-center">
        <button
          onClick={() => setExpanded(!expanded)}
          className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-brand-500 hover:text-brand-700 bg-brand-50 rounded-lg transition-colors"
        >
          {expanded ? (
            <>
              Show top 10
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 15l7-7 7 7" />
              </svg>
            </>
          ) : (
            <>
              Show top 100
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </>
          )}
        </button>
      </div>
    </section>
  );
}
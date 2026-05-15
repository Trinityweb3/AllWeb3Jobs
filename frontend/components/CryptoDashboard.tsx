import { useState, useEffect } from 'react';
import useSWR from 'swr';

const TOKEN_IDS = ['ethereum','binancecoin','matic-network','arbitrum','optimism','avalanche-2','near','aptos','sui','solana'];

interface CoinData {
  id: string; symbol: string; name: string; image: string;
  current_price: number; price_change_percentage_24h: number | null;
  market_cap: number; total_volume: number;
}

const fetcher = (url: string) => fetch(url).then(res => res.json());

export default function CryptoDashboard() {
  const [favorites, setFavorites] = useState<string[]>([]);
  useEffect(() => {
    const stored = localStorage.getItem('cryptoWatchlist');
    if (stored) setFavorites(JSON.parse(stored));
  }, []);
  useEffect(() => {
    localStorage.setItem('cryptoWatchlist', JSON.stringify(favorites));
  }, [favorites]);
  const toggleFavorite = (id: string) => {
    setFavorites(prev => prev.includes(id) ? prev.filter(f => f !== id) : [...prev, id]);
  };
  const url = `https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=${TOKEN_IDS.join(',')}&order=market_cap_desc&per_page=10&page=1&sparkline=false&price_change_percentage=24h`;
  const { data, error } = useSWR<CoinData[]>(url, fetcher, { refreshInterval: 30000 });
  if (error) return <div className="bg-red-50 text-red-600 p-4 rounded-lg mb-6">Failed to load market data.</div>;
  const sorted = data ? [...data].sort((a,b) => {
    const aF = favorites.includes(a.id) ? 0 : 1;
    const bF = favorites.includes(b.id) ? 0 : 1;
    return aF - bF;
  }) : [];
  return (
    <section className="mb-10">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-2xl font-bold text-gray-900">Web3 Market Watch</h2>
        <span className="text-xs text-gray-500">Auto‑updates every 30s</span>
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
            {sorted.map((coin,i) => {
              const isFav = favorites.includes(coin.id);
              const change = coin.price_change_percentage_24h ?? 0;
              return (
                <tr key={coin.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-500">{i+1}</td>
                  <td className="px-4 py-3 whitespace-nowrap">
                    <div className="flex items-center gap-3">
                      <img src={coin.image} alt={coin.name} className="w-6 h-6 rounded-full" />
                      <div>
                        <div className="text-sm font-medium text-gray-900">{coin.name}</div>
                        <div className="text-xs text-gray-500 uppercase">{coin.symbol}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap text-sm text-right font-mono">${coin.current_price?.toLocaleString()}</td>
                  <td className={`px-4 py-3 whitespace-nowrap text-sm text-right font-mono ${change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                    {change >= 0 ? '+' : ''}{change.toFixed(2)}%
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap text-sm text-right text-gray-500 hidden sm:table-cell">
                    ${coin.market_cap?.toLocaleString()}
                  </td>
                  <td className="px-4 py-3 whitespace-nowrap text-center">
                    <button onClick={() => toggleFavorite(coin.id)}
                      className={`text-lg ${isFav ? 'text-yellow-500' : 'text-gray-300 hover:text-yellow-400'}`}>
                      {isFav ? '★' : '☆'}
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

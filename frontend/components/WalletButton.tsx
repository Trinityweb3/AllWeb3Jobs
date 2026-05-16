import { useEffect, useState } from 'react';
import { useWallet } from '@solana/wallet-adapter-react';
import { WalletName } from '@solana/wallet-adapter-base';

export default function WalletButton() {
  const { wallets, select, wallet, connect, disconnect, connecting, connected, publicKey } = useWallet();
  const [showDropdown, setShowDropdown] = useState(false);

  // turn off SSR
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  if (!mounted) return null;

  const handleSelect = async (walletName: WalletName) => {
    select(walletName);
    setShowDropdown(false);
    try {
      await connect();
    } catch (err) {
      console.error('Connection failed', err);
    }
  };

  const shortAddress = publicKey
    ? `${publicKey.toBase58().slice(0, 4)}...${publicKey.toBase58().slice(-4)}`
    : '';

  const detected = wallets.filter((w) => w.readyState === 'Installed');

  return (
    <div className="relative">
      {!connected ? (
        <>
          <button
            onClick={() => setShowDropdown(!showDropdown)}
            disabled={connecting}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg
                       bg-brand-500 text-white hover:bg-brand-700 transition-colors"
          >
            {connecting ? (
              <>
                <svg className="animate-spin h-4 w-4" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Connecting...
              </>
            ) : (
              'Connect Wallet'
            )}
          </button>

          {/* list*/}
          {showDropdown && (
            <div className="absolute right-0 mt-2 w-56 bg-white border border-gray-200 rounded-lg shadow-lg z-50">
              {detected.length > 0 && (
                <div className="px-3 py-2 text-xs text-gray-500 font-semibold uppercase">Detected</div>
              )}
              {wallets.map((w) => {
                const isDetected = w.readyState === 'Installed';
                return (
                  <button
                    key={w.adapter.name}
                    onClick={() => handleSelect(w.adapter.name)}
                    className="w-full flex items-center gap-3 px-3 py-2 hover:bg-gray-100 text-left text-sm"
                  >
                    <img src={w.adapter.icon} alt={w.adapter.name} className="w-5 h-5" />
                    <span className="flex-1">{w.adapter.name}</span>
                    {isDetected && (
                      <span className="text-xs text-green-600 font-medium">Detected</span>
                    )}
                  </button>
                );
              })}
            </div>
          )}
        </>
      ) : (
        <div className="flex items-center gap-2">
          <span className="text-sm text-gray-600 bg-gray-100 px-3 py-1 rounded-lg">
            {shortAddress}
          </span>
          <button
            onClick={() => disconnect()}
            className="text-xs text-red-500 hover:text-red-700 underline"
          >
            Disconnect
          </button>
        </div>
      )}
    </div>
  );
}
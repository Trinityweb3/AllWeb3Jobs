import { Html, Head, Main, NextScript } from 'next/document';

export default function Document() {
  return (
    <Html lang="en">
      <Head />
      <body>
        {/* Inline script to set dark mode before page render to prevent FOUC */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              try {
                if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches) || !('theme' in localStorage)) {
                  document.documentElement.classList.add('dark');
                  // Defaults to dark if no theme is found (CoinMarketCap style)
                } else {
                  document.documentElement.classList.remove('dark');
                }
              } catch (_) {}
            `,
          }}
        />
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}

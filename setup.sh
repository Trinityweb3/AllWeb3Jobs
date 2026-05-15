#!/bin/bash
set -e

echo "Creating AllWeb3Jobs monorepo (frontend + Rust backend + shared data)..."

# ======================== КОРНЕВЫЕ ФАЙЛЫ ========================
mkdir -p data/jobs

# -------------------- .gitignore --------------------
cat > .gitignore << 'EOF'
node_modules/
.next/
.env.local
.env
target/
EOF

# -------------------- README.md --------------------
cat > README.md << 'EOF'
# AllWeb3Jobs

Monorepo:
- `frontend/` – Next.js 14 (TypeScript, Tailwind)
- `backend/` – Rust + Axum (API и Telegram‑боты)
- `data/jobs/` – общие JSON‑файлы вакансий
EOF

# ======================== FRONTEND ========================
echo "Setting up frontend..."
mkdir -p frontend/{components,lib,pages/{category,jobs},styles,public}
mkdir -p frontend/pages/api

# package.json
cat > frontend/package.json << 'EOF'
{
  "name": "allweb3jobs-frontend",
  "version": "0.2.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "14.2.3",
    "react": "^18",
    "react-dom": "^18",
    "fuse.js": "^7.0.0",
    "swr": "^2"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.3",
    "typescript": "^5"
  }
}
EOF

# tsconfig.json (с alias @)
cat > frontend/tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": ["node_modules"]
}
EOF

# next.config.js
cat > frontend/next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};
module.exports = nextConfig;
EOF

# tailwind.config.ts
cat > frontend/tailwind.config.ts << 'EOF'
import type { Config } from 'tailwindcss';
const config: Config = {
  content: ['./pages/**/*.{js,ts,jsx,tsx,mdx}', './components/**/*.{js,ts,jsx,tsx,mdx}'],
  theme: {
    extend: {
      colors: {
        brand: { 50: '#eef2ff', 500: '#6366f1', 700: '#4338ca' },
        surface: '#f8fafc',
      },
    },
  },
  plugins: [],
};
export default config;
EOF

# postcss.config.js
cat > frontend/postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOF

# styles/globals.css
cat > frontend/styles/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply font-sans text-gray-900 bg-surface antialiased;
  }
}
EOF

# pages/_app.tsx (исправленный импорт)
cat > frontend/pages/_app.tsx << 'EOF'
import '@/styles/globals.css';
import type { AppProps } from 'next/app';

export default function App({ Component, pageProps }: AppProps) {
  return <Component {...pageProps} />;
}
EOF

# lib/siteConfig.ts
cat > frontend/lib/siteConfig.ts << 'EOF'
export const siteConfig = {
  name: 'AllWeb3Jobs',
  defaultTitle: 'AllWeb3Jobs – Web3, Blockchain & Crypto Jobs',
  defaultDescription:
    'Latest Web3, DeFi, NFT, and crypto jobs. Find remote and office positions for developers, marketers, designers, managers.',
  githubUrl: 'https://github.com/Trinityweb3/AllWeb3Jobs',
  revalidateSeconds: 3600,
  categories: [
    {
      id: 'internships-juniors',
      name: 'Internships, Juniors & Hackathons',
      description: 'Entry-level opportunities, internships, and hackathons in Web3.',
    },
    {
      id: 'mid-senior-leads',
      name: 'Mid-level, Senior & Lead',
      description: 'Positions for experienced professionals.',
    },
  ],
};
EOF

# lib/slugify.ts
cat > frontend/lib/slugify.ts << 'EOF'
export function slugify(text: string): string {
  return text
    .toString()
    .toLowerCase()
    .trim()
    .replace(/\s+/g, '-')
    .replace(/[^\w\-]+/g, '')
    .replace(/\-\-+/g, '-')
    .replace(/^-+/, '')
    .replace(/-+$/, '');
}
EOF

# lib/jobs.ts (чтение из ../data/jobs)
cat > frontend/lib/jobs.ts << 'EOF'
import fs from 'fs/promises';
import path from 'path';
import { slugify } from './slugify';

export interface Job {
  slug: string;
  title: string;
  description_short: string;
  description_full: string;
  date: string;
  category: string;
  company?: string | null;
  location?: string | null;
  type?: string | null;
}

const jobsDirectory = path.join(process.cwd(), '..', 'data', 'jobs');

function validateJob(data: any): Job | null {
  if (typeof data.title !== 'string' || typeof data.description_full !== 'string') {
    console.warn('Skipping invalid job');
    return null;
  }
  const date = typeof data.date === 'string' ? data.date : new Date().toISOString();
  const category = typeof data.category === 'string' ? data.category : 'general';
  return {
    slug: '',
    title: data.title,
    description_short: data.description_short ?? data.description_full.slice(0, 200),
    description_full: data.description_full,
    date,
    category,
    company: data.company ?? null,
    location: data.location ?? null,
    type: data.type ?? null,
  };
}

export async function getAllJobs(): Promise<Job[]> {
  try {
    await fs.access(jobsDirectory);
  } catch {
    return [];
  }
  const fileNames = await fs.readdir(jobsDirectory);
  const jobs: Job[] = [];
  for (const fileName of fileNames) {
    if (!fileName.endsWith('.json')) continue;
    try {
      const fullPath = path.join(jobsDirectory, fileName);
      const content = await fs.readFile(fullPath, 'utf8');
      const raw = JSON.parse(content);
      const job = validateJob(raw);
      if (job) {
        const slug = slugify(job.title) || fileName.replace(/\.json$/, '');
        jobs.push({ ...job, slug,
          company: job.company ?? null,
          location: job.location ?? null,
          type: job.type ?? null,
        });
      }
    } catch (err) {
      console.error(`Error processing ${fileName}:`, err);
    }
  }
  return jobs.sort((a, b) => (a.date < b.date ? 1 : -1));
}

export async function getJobBySlug(slug: string): Promise<Job | null> {
  const all = await getAllJobs();
  return all.find(j => j.slug === slug) || null;
}

export async function getJobsByCategory(category: string): Promise<Job[]> {
  const all = await getAllJobs();
  return all.filter(j => j.category === category);
}

export async function getAllSlugs(): Promise<string[]> {
  const all = await getAllJobs();
  return all.map(j => j.slug);
}
EOF

# lib/similarity.ts
cat > frontend/lib/similarity.ts << 'EOF'
import { Job } from './jobs';
export function getSimilarJobs(current: Job, allJobs: Job[], limit = 3): Job[] {
  const stopWords = new Set(['the','a','an','in','on','at','to','for','of','and','or','is','are','we','you','they','it','with','as','by','from','that','this','be']);
  const getKeywords = (text: string) => text.toLowerCase().split(/\W+/).filter(w => w.length > 2 && !stopWords.has(w));
  const curr = new Set([...getKeywords(current.title), ...getKeywords(current.description_short)]);
  return allJobs
    .filter(j => j.slug !== current.slug)
    .map(j => ({ job: j, score: [...getKeywords(j.title), ...getKeywords(j.description_short)].filter(w => curr.has(w)).length }))
    .sort((a,b) => b.score - a.score)
    .slice(0, limit)
    .map(item => item.job);
}
EOF

# Компоненты
cat > frontend/components/Layout.tsx << 'EOF'
import Head from 'next/head';
import Link from 'next/link';
import { siteConfig } from '@/lib/siteConfig';
interface LayoutProps { children: React.ReactNode; title?: string; description?: string; }
export default function Layout({ children, title, description }: LayoutProps) {
  const pageTitle = title || siteConfig.defaultTitle;
  const pageDesc = description || siteConfig.defaultDescription;
  return (
    <>
      <Head>
        <title>{pageTitle}</title>
        <meta name="description" content={pageDesc} />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
      </Head>
      <div className="min-h-screen bg-surface">
        <header className="bg-white shadow-sm border-b">
          <nav className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
            <Link href="/" className="text-xl font-bold text-gray-900">{siteConfig.name}</Link>
            <div className="flex gap-4">
              <Link href="/" className="text-gray-600 hover:text-gray-900">All Jobs</Link>
              <Link href="/category/internships-juniors" className="text-gray-600 hover:text-gray-900">Internships</Link>
              <Link href="/category/mid-senior-leads" className="text-gray-600 hover:text-gray-900">Mid & Senior</Link>
            </div>
          </nav>
        </header>
        <main className="max-w-7xl mx-auto px-4 py-8">{children}</main>
        <footer className="bg-white border-t mt-12 py-6 text-center text-gray-500 text-sm">
          © {new Date().getFullYear()} {siteConfig.name}
        </footer>
      </div>
    </>
  );
}
EOF

cat > frontend/components/JobCard.tsx << 'EOF'
import Link from 'next/link';
import { Job } from '@/lib/jobs';
interface JobCardProps { job: Job; }
export default function JobCard({ job }: JobCardProps) {
  const formatDate = (dateString: string) => new Date(dateString).toLocaleDateString('en-US', { year:'numeric', month:'long', day:'numeric' });
  return (
    <Link href={`/jobs/${job.slug}`} className="block group">
      <article className="bg-white rounded-xl border p-5 hover:shadow-lg transition-all duration-200 hover:-translate-y-0.5 h-full flex flex-col">
        <h2 className="text-lg font-semibold group-hover:text-brand-500 mb-1">{job.title}</h2>
        <div className="flex items-center gap-2 text-sm text-gray-500 mb-2">
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/></svg>
          <span>Posted on {formatDate(job.date)}</span>
        </div>
        {(job.location || job.type) && (
          <div className="flex flex-wrap items-center gap-2 text-sm text-gray-500 mb-3">
            {job.location && <span>📍 {job.location}</span>}
            {job.type && <span className="px-2 py-0.5 bg-gray-100 rounded-full text-xs">{job.type}</span>}
          </div>
        )}
        <div className="mt-auto pt-3 border-t border-gray-100">
          <span className="text-brand-500 hover:text-brand-700 font-medium text-sm inline-flex items-center gap-1 transition-colors">Read more →</span>
        </div>
      </article>
    </Link>
  );
}
EOF

cat > frontend/components/SearchBar.tsx << 'EOF'
import { useState, useEffect, useCallback } from 'react';
interface SearchBarProps { onSearch: (query: string) => void; placeholder?: string; }
export default function SearchBar({ onSearch, placeholder = 'Search...' }: SearchBarProps) {
  const [value, setValue] = useState('');
  const debounced = useCallback(
    (() => { let timer: NodeJS.Timeout; return (q: string) => { clearTimeout(timer); timer = setTimeout(() => onSearch(q), 300); }; })(),
    [onSearch]
  );
  useEffect(() => { debounced(value); }, [value, debounced]);
  return (
    <div className="relative">
      <input type="text" value={value} onChange={e => setValue(e.target.value)} placeholder={placeholder}
        className="w-full px-4 py-3 border border-gray-300 rounded-lg shadow-sm focus:ring-2 focus:ring-brand-500 focus:border-brand-500 outline-none" />
      <svg className="absolute right-3 top-3.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
      </svg>
    </div>
  );
}
EOF

cat > frontend/components/SimilarJobs.tsx << 'EOF'
import JobCard from './JobCard';
import { Job } from '@/lib/jobs';
interface SimilarJobsProps { jobs: Job[]; }
export default function SimilarJobs({ jobs }: SimilarJobsProps) {
  if (!jobs || jobs.length === 0) return null;
  return (
    <section className="mt-12">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Similar Jobs</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {jobs.map(job => <JobCard key={job.slug} job={job} />)}
      </div>
    </section>
  );
}
EOF

cat > frontend/components/CryptoDashboard.tsx << 'EOF'
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
EOF

# pages/index.tsx (с дашбордом)
cat > frontend/pages/index.tsx << 'EOF'
import { GetStaticProps } from 'next';
import { useState, useEffect } from 'react';
import Fuse from 'fuse.js';
import Layout from '@/components/Layout';
import JobCard from '@/components/JobCard';
import SearchBar from '@/components/SearchBar';
import CryptoDashboard from '@/components/CryptoDashboard';
import { getAllJobs, Job } from '@/lib/jobs';
import { siteConfig } from '@/lib/siteConfig';

interface HomeProps { jobs: Job[]; latestJobs: Job[]; }

export default function Home({ jobs, latestJobs }: HomeProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState<string>('all');
  const [filteredJobs, setFilteredJobs] = useState<Job[]>([]);

  const fuse = new Fuse(jobs, { keys: ['title', 'description_short'], threshold: 0.4, includeScore: true });

  useEffect(() => {
    let pool = activeCategory === 'all' ? jobs : jobs.filter(j => j.category === activeCategory);
    if (searchQuery.trim()) {
      const results = fuse.search(searchQuery).map(r => r.item);
      pool = pool.filter(j => results.includes(j));
    }
    setFilteredJobs(pool);
  }, [searchQuery, activeCategory, jobs]);

  const categoryTabs = [
    { id: 'all', label: 'All Jobs' },
    ...siteConfig.categories.map(c => ({ id: c.id, label: c.name })),
  ];

  return (
    <Layout>
      <CryptoDashboard />
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">All Web3 Jobs</h1>
        <p className="text-gray-600 mb-6">Discover remote and on‑site Web3 opportunities. Updated daily.</p>
        <SearchBar onSearch={setSearchQuery} placeholder="Search jobs..." />
      </div>
      <div className="flex flex-wrap gap-2 mb-6">
        {categoryTabs.map(tab => (
          <button key={tab.id} onClick={() => setActiveCategory(tab.id)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${activeCategory === tab.id ? 'bg-brand-500 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200'}`}>
            {tab.label}
          </button>
        ))}
      </div>
      {searchQuery && <div className="mb-6"><p className="text-gray-600">Found {filteredJobs.length} job(s)</p></div>}
      {!searchQuery && activeCategory === 'all' && (
        <section className="mb-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Latest Jobs</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {latestJobs.map(job => <JobCard key={job.slug} job={job} />)}
          </div>
        </section>
      )}
      <section>
        <h2 className="text-2xl font-bold text-gray-900 mb-6">
          {activeCategory !== 'all' ? siteConfig.categories.find(c => c.id === activeCategory)?.name : searchQuery ? 'Search Results' : 'All Jobs'}
        </h2>
        {filteredJobs.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredJobs.map(job => <JobCard key={job.slug} job={job} />)}
          </div>
        ) : (
          <div className="bg-gray-100 rounded-lg p-8 text-center"><p className="text-gray-600">No jobs found.</p></div>
        )}
      </section>
    </Layout>
  );
}

export const getStaticProps: GetStaticProps<HomeProps> = async () => {
  const allJobs = await getAllJobs();
  const latestJobs = allJobs.slice(0, 6);
  return { props: { jobs: allJobs, latestJobs }, revalidate: siteConfig.revalidateSeconds };
};
EOF

# pages/category/[category].tsx
cat > frontend/pages/category/[category].tsx << 'EOF'
import { GetStaticPaths, GetStaticProps } from 'next';
import Layout from '@/components/Layout';
import JobCard from '@/components/JobCard';
import { getJobsByCategory, Job } from '@/lib/jobs';
import { siteConfig } from '@/lib/siteConfig';

interface CategoryPageProps { categoryName: string; jobs: Job[]; }

export default function CategoryPage({ categoryName, jobs }: CategoryPageProps) {
  return (
    <Layout title={`${categoryName} – ${siteConfig.name}`} description={`${categoryName} job openings`}>
      <h1 className="text-3xl font-bold text-gray-900 mb-6">{categoryName}</h1>
      {jobs.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {jobs.map(job => <JobCard key={job.slug} job={job} />)}
        </div>
      ) : (
        <div className="bg-gray-100 rounded-lg p-8 text-center"><p className="text-gray-600">No jobs in this category yet.</p></div>
      )}
    </Layout>
  );
}

export const getStaticPaths: GetStaticPaths = async () => {
  const paths = siteConfig.categories.map(c => ({ params: { category: c.id } }));
  return { paths, fallback: 'blocking' };
};

export const getStaticProps: GetStaticProps<CategoryPageProps> = async ({ params }) => {
  const category = params?.category as string;
  const cat = siteConfig.categories.find(c => c.id === category);
  if (!cat) return { notFound: true };
  const jobs = await getJobsByCategory(category);
  return { props: { categoryName: cat.name, jobs }, revalidate: siteConfig.revalidateSeconds };
};
EOF

# pages/jobs/[slug].tsx
cat > frontend/pages/jobs/[slug].tsx << 'EOF'
import { GetStaticPaths, GetStaticProps } from 'next';
import Link from 'next/link';
import Head from 'next/head';
import Layout from '@/components/Layout';
import SimilarJobs from '@/components/SimilarJobs';
import { getAllJobs, getAllSlugs, getJobBySlug, Job } from '@/lib/jobs';
import { getSimilarJobs } from '@/lib/similarity';
import { siteConfig } from '@/lib/siteConfig';

interface JobPageProps { job: Job; similarJobs: Job[]; }

export default function JobPage({ job, similarJobs }: JobPageProps) {
  const formatDate = (dateString: string) => new Date(dateString).toLocaleDateString('en-US', { year:'numeric', month:'long', day:'numeric' });
  const jsonLd = {
    '@context': 'https://schema.org', '@type': 'JobPosting',
    title: job.title, datePosted: job.date, description: job.description_full,
    hiringOrganization: job.company ? { '@type': 'Organization', name: job.company } : undefined,
    jobLocation: job.location ? { '@type': 'Place', address: { '@type': 'PostalAddress', addressLocality: job.location } } : undefined,
    employmentType: job.type || undefined,
    validThrough: new Date(new Date(job.date).getTime() + 30*24*60*60*1000).toISOString(),
  };
  return (
    <Layout title={`${job.title} | ${siteConfig.name}`} description={job.description_short}>
      <Head>
        {job.company && <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />}
      </Head>
      <div className="max-w-3xl mx-auto">
        <Link href="/" className="text-blue-600 hover:underline mb-4 inline-block">← Back to all jobs</Link>
        <article className="bg-white rounded-lg border p-6 mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">{job.title}</h1>
          <div className="flex flex-wrap items-center gap-2 text-sm text-gray-600 mb-4">
            {job.company && <span className="font-medium">{job.company}</span>}
            {job.company && job.location && <span>·</span>}
            {job.location && <span>{job.location}</span>}
            {job.type && <span className="px-2 py-0.5 bg-gray-100 rounded-full">{job.type}</span>}
          </div>
          <div className="text-sm text-gray-500 mb-4">Posted on {formatDate(job.date)}</div>
          <div className="prose max-w-none whitespace-pre-wrap text-gray-700">{job.description_full}</div>
        </article>
        {similarJobs.length > 0 && <SimilarJobs jobs={similarJobs} />}
      </div>
    </Layout>
  );
}

export const getStaticPaths: GetStaticPaths = async () => {
  const slugs = await getAllSlugs();
  return { paths: slugs.map(slug => ({ params: { slug } })), fallback: 'blocking' };
};

export const getStaticProps: GetStaticProps<JobPageProps> = async ({ params }) => {
  const slug = params?.slug as string;
  const job = await getJobBySlug(slug);
  if (!job) return { notFound: true };
  const allJobs = await getAllJobs();
  const similarJobs = getSimilarJobs(job, allJobs.filter(j => j.slug !== slug));
  return { props: { job, similarJobs }, revalidate: siteConfig.revalidateSeconds };
};
EOF

# pages/sitemap.xml.tsx
cat > frontend/pages/sitemap.xml.tsx << 'EOF'
import { GetServerSideProps } from 'next';
import { getAllJobs } from '@/lib/jobs';
import { siteConfig } from '@/lib/siteConfig';

interface SitemapEntry { loc: string; lastmod?: string; changefreq: string; priority: string; }

export const getServerSideProps: GetServerSideProps = async ({ res }) => {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://your-domain.com';
  const jobs = await getAllJobs();
  const staticPages: SitemapEntry[] = [
    { loc: `${baseUrl}/`, changefreq: 'daily', priority: '1.0' },
    ...siteConfig.categories.map(c => ({ loc: `${baseUrl}/category/${c.id}`, changefreq: 'daily' as const, priority: '0.9' })),
  ];
  const jobPages: SitemapEntry[] = jobs.map(job => ({
    loc: `${baseUrl}/jobs/${job.slug}`, lastmod: job.date, changefreq: 'weekly', priority: '0.8'
  }));
  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  ${[...staticPages, ...jobPages].map(page => `
    <url>
      <loc>${page.loc}</loc>
      <lastmod>${page.lastmod || new Date().toISOString()}</lastmod>
      <changefreq>${page.changefreq}</changefreq>
      <priority>${page.priority}</priority>
    </url>`).join('')}
</urlset>`;
  res.setHeader('Content-Type', 'text/xml');
  res.write(sitemap);
  res.end();
  return { props: {} };
};

export default function Sitemap() { return null; }
EOF

# public/robots.txt
cat > frontend/public/robots.txt << 'EOF'
User-agent: *
Allow: /
Sitemap: https://your-domain.com/sitemap.xml
EOF

# frontend .env.local.example
cat > frontend/.env.local.example << 'EOF'
NEXT_PUBLIC_SITE_URL=http://localhost:3000
EOF

echo "Frontend created."

# ======================== BACKEND (Rust) ========================
echo "Setting up backend..."
mkdir -p backend/src backend/templates backend/static

# Cargo.toml
cat > backend/Cargo.toml << 'EOF'
[package]
name = "allweb3jobs-backend"
version = "0.1.0"
edition = "2021"

[dependencies]
axum = "0.7"
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
uuid = { version = "1", features = ["v4"] }
chrono = { version = "0.4", features = ["serde"] }
slug = "0.1"
reqwest = { version = "0.12", features = ["json"] }
teloxide = { version = "0.13", features = ["macros"] }
tower-http = { version = "0.5", features = ["fs"] }
once_cell = "1"
log = "0.4"
env_logger = "0.11"
dotenv = "0.15"
EOF

# src/models.rs
cat > backend/src/models.rs << 'EOF'
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Job {
    pub slug: String,
    pub title: String,
    pub description_short: String,
    pub description_full: String,
    pub date: String,
    pub category: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub company: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub location: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub job_type: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct CoinData {
    pub id: String,
    pub symbol: String,
    pub name: String,
    pub image: String,
    pub current_price: f64,
    pub price_change_percentage_24h: Option<f64>,
    pub market_cap: f64,
    pub total_volume: f64,
}
EOF

# src/jobs.rs
cat > backend/src/jobs.rs << 'EOF'
use crate::models::Job;
use anyhow::Result;
use chrono::Utc;
use slug::slugify;
use std::fs;
use std::path::PathBuf;
use uuid::Uuid;

pub const JOBS_DIR: &str = "../data/jobs";

pub fn load_jobs() -> Result<Vec<Job>> {
    let mut jobs = Vec::new();
    let dir = PathBuf::from(JOBS_DIR);
    if !dir.exists() {
        fs::create_dir_all(&dir)?;
    }
    for entry in fs::read_dir(&dir)? {
        let path = entry?.path();
        if path.extension().map_or(false, |ext| ext == "json") {
            let content = fs::read_to_string(&path)?;
            let mut job: Job = serde_json::from_str(&content)?;
            if job.slug.is_empty() {
                job.slug = slugify(&job.title);
            }
            if job.description_short.is_empty() {
                job.description_short = job.description_full.chars().take(200).collect();
            }
            jobs.push(job);
        }
    }
    jobs.sort_by(|a, b| b.date.cmp(&a.date));
    Ok(jobs)
}

pub fn create_job(title: &str, description_full: &str, category: &str) -> Result<Job> {
    let now = Utc::now().to_rfc3339();
    let slug = format!("{}-{}", slugify(title), Uuid::new_v4().to_string().split('-').next().unwrap());
    let short = if description_full.len() > 200 {
        format!("{}...", &description_full[..200])
    } else {
        description_full.to_string()
    };
    let job = Job {
        slug,
        title: title.to_string(),
        description_short: short,
        description_full: description_full.to_string(),
        date: now,
        category: category.to_string(),
        company: None,
        location: None,
        job_type: None,
    };
    let dir = PathBuf::from(JOBS_DIR);
    fs::create_dir_all(&dir)?;
    let file_path = dir.join(format!("{}.json", job.slug));
    fs::write(&file_path, serde_json::to_string_pretty(&job)?)?;
    Ok(job)
}
EOF

# src/bots.rs
cat > backend/src/bots.rs << 'EOF'
use teloxide::prelude::*;
use reqwest::Client;
use std::env;

pub async fn start_bots() {
    let client = Client::new();
    let api_url = env::var("API_URL").unwrap_or_else(|_| "http://localhost:3001/api/add-job".to_string());
    let bot1_token = env::var("BOT1_TOKEN").expect("BOT1_TOKEN missing");
    let bot2_token = env::var("BOT2_TOKEN").expect("BOT2_TOKEN missing");
    let bot_api_secret = env::var("BOT_API_SECRET").expect("BOT_API_SECRET missing");

    let bot1 = Bot::new(bot1_token);
    let bot2 = Bot::new(bot2_token);

    let handler1 = {
        let client = client.clone();
        let api_url = api_url.clone();
        let secret = bot_api_secret.clone();
        Update::filter_message().branch(dptree::entry()
            .filter_map(|msg: Message| msg.text().map(|text| (msg.chat.id, text.to_owned())))
            .endpoint(move |(chat_id, text): (ChatId, String)| {
                let client = client.clone();
                let api_url = api_url.clone();
                let secret = secret.clone();
                async move {
                    let result = send_job(&client, &api_url, &text, "internships-juniors", &secret).await;
                    let msg = match result {
                        Ok(slug) => format!("✅ Job added: {}", slug),
                        Err(e) => format!("❌ Error: {}", e),
                    };
                    bot1.send_message(chat_id, msg).await?;
                    respond(())
                }
            })
        )
    };

    let handler2 = {
        let client = client.clone();
        let api_url = api_url.clone();
        let secret = bot_api_secret.clone();
        Update::filter_message().branch(dptree::entry()
            .filter_map(|msg: Message| msg.text().map(|text| (msg.chat.id, text.to_owned())))
            .endpoint(move |(chat_id, text): (ChatId, String)| {
                let client = client.clone();
                let api_url = api_url.clone();
                let secret = secret.clone();
                async move {
                    let result = send_job(&client, &api_url, &text, "mid-senior-leads", &secret).await;
                    let msg = match result {
                        Ok(slug) => format!("✅ Job added: {}", slug),
                        Err(e) => format!("❌ Error: {}", e),
                    };
                    bot2.send_message(chat_id, msg).await?;
                    respond(())
                }
            })
        )
    };

    tokio::spawn(Dispatcher::builder(bot1, handler1).enable_ctrlc_handler().build().dispatch());
    tokio::spawn(Dispatcher::builder(bot2, handler2).enable_ctrlc_handler().build().dispatch());
}

async fn send_job(client: &Client, api_url: &str, text: &str, category: &str, secret: &str) -> Result<String, String> {
    let resp = client.post(api_url)
        .header("x-bot-token", secret)
        .json(&serde_json::json!({ "text": text, "category": category }))
        .send().await.map_err(|e| e.to_string())?;
    if resp.status().is_success() {
        let json: serde_json::Value = resp.json().await.map_err(|e| e.to_string())?;
        Ok(json["slug"].as_str().unwrap_or("ok").to_string())
    } else {
        Err(resp.text().await.unwrap_or_default())
    }
}
EOF

# src/handlers.rs (только add-job API)
cat > backend/src/handlers.rs << 'EOF'
use crate::jobs;
use axum::{extract::State, http::StatusCode, Json};
use serde::Deserialize;
use std::sync::Arc;

pub struct AppState;

#[derive(Deserialize)]
pub struct AddJobRequest {
    pub text: String,
    pub category: String,
}

pub async fn add_job(
    headers: axum::http::HeaderMap,
    Json(payload): Json<AddJobRequest>,
) -> impl axum::response::IntoResponse {
    let token = headers.get("x-bot-token").and_then(|v| v.to_str().ok()).unwrap_or("");
    let expected = std::env::var("BOT_API_SECRET").unwrap_or_default();
    if token != expected {
        return (StatusCode::UNAUTHORIZED, Json(serde_json::json!({"error":"Invalid token"}))).into_response();
    }
    let lines: Vec<&str> = payload.text.trim().lines().collect();
    let title = lines.first().map(|s| *s).unwrap_or("Untitled");
    let desc = if lines.len() > 1 { lines[1..].join("\n") } else { title.to_string() };
    match jobs::create_job(title, &desc, &payload.category) {
        Ok(job) => (StatusCode::CREATED, Json(serde_json::json!({"success":true,"slug":job.slug}))).into_response(),
        Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({"error":e.to_string()}))).into_response(),
    }
}
EOF

# src/main.rs
cat > backend/src/main.rs << 'EOF'
mod bots;
mod handlers;
mod jobs;
mod models;

use axum::{routing::post, Router};
use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    dotenv::dotenv().ok();
    env_logger::init();

    // Запуск ботов
    bots::start_bots().await;

    // API сервер
    let app = Router::new()
        .route("/api/add-job", post(handlers::add_job));

    let port = std::env::var("PORT").unwrap_or_else(|_| "3001".to_string());
    let addr: SocketAddr = format!("0.0.0.0:{}", port).parse().unwrap();
    println!("🚀 Rust backend listening on {}", addr);
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .unwrap();
}
EOF

# backend .env.example
cat > backend/.env.example << 'EOF'
PORT=3001
BOT1_TOKEN=111:aaa
BOT2_TOKEN=222:bbb
BOT_API_SECRET=my-secret
API_URL=http://localhost:3001/api/add-job
EOF

echo "Backend created."

echo ""
echo "✅ AllWeb3Jobs monorepo ready!"
echo "  1. cd frontend && npm install && npm run dev"
echo "  2. cd backend && cargo run"
echo "  3. Place job JSON files into data/jobs/ (shared folder)"
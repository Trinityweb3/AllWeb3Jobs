#!/bin/bash
set -e

echo "Creating Web3 Job Board project structure..."

# Create directories
mkdir -p lib pages/api pages/category pages/jobs components public styles data/jobs

# ─── package.json ─────────────────────────────────────
cat > package.json << 'EOF'
{
  "name": "web3-jobboard",
  "version": "0.2.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "14.2.3",
    "react": "^18",
    "react-dom": "^18",
    "fuse.js": "^7.0.0"
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

# ─── tsconfig.json ─────────────────────────────────────
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "es5",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "node",
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

# ─── next.config.js ─────────────────────────────────────
cat > next.config.js << 'EOF'
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};
module.exports = nextConfig;
EOF

# ─── tailwind.config.ts ─────────────────────────────────
cat > tailwind.config.ts << 'EOF'
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
};
export default config;
EOF

# ─── postcss.config.js ──────────────────────────────────
cat > postcss.config.js << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOF

# ─── styles/globals.css ─────────────────────────────────
cat > styles/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# ─── public/robots.txt ──────────────────────────────────
cat > public/robots.txt << 'EOF'
User-agent: *
Allow: /
Sitemap: https://your-domain.com/sitemap.xml
EOF

# ─── .env.local ─────────────────────────────────────────
cat > .env.local << 'EOF'
NEXT_PUBLIC_SITE_URL=https://your-domain.com
REVALIDATION_SECRET=your-revalidation-secret
BOT_API_SECRET=your-bot-api-secret
EOF

# ─── lib/siteConfig.ts ──────────────────────────────────
cat > lib/siteConfig.ts << 'EOF'
export const siteConfig = {
  name: 'Web3 Job Board',
  defaultTitle: 'Web3 Job Board – Web3, Blockchain & Crypto Jobs',
  defaultDescription:
    'Latest Web3, DeFi, NFT, and crypto jobs. Find remote and office positions for developers, marketers, designers, managers.',
  githubUrl: 'https://github.com/your-repo',
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

# ─── lib/slugify.ts ─────────────────────────────────────
cat > lib/slugify.ts << 'EOF'
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

# ─── lib/jobs.ts ───────────────────────────────────────
cat > lib/jobs.ts << 'EOF'
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
  company?: string;
  location?: string;
  type?: string;
}

const jobsDirectory = path.join(process.cwd(), 'data/jobs');

function validateJob(data: any): Job | null {
  if (
    typeof data.title !== 'string' ||
    typeof data.description_full !== 'string'
  ) {
    console.warn(`Skipping invalid job: missing title or description_full`);
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
    company: data.company,
    location: data.location,
    type: data.type,
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
      const fileContents = await fs.readFile(fullPath, 'utf8');
      const raw = JSON.parse(fileContents);
      const job = validateJob(raw);
      if (job) {
        const slug = slugify(job.title) || fileName.replace(/\.json$/, '');
        jobs.push({ ...job, slug });
      }
    } catch (err) {
      console.error(`Error processing ${fileName}:`, err);
    }
  }

  return jobs.sort((a, b) => (a.date < b.date ? 1 : -1));
}

export async function getJobBySlug(slug: string): Promise<Job | null> {
  const all = await getAllJobs();
  return all.find((j) => j.slug === slug) || null;
}

export async function getJobsByCategory(category: string): Promise<Job[]> {
  const all = await getAllJobs();
  return all.filter((j) => j.category === category);
}

export async function getAllSlugs(): Promise<string[]> {
  const all = await getAllJobs();
  return all.map((j) => j.slug);
}

export async function createJobFile(data: {
  title: string;
  description_full: string;
  category: string;
}): Promise<Job> {
  const date = new Date().toISOString();
  const slugBase = slugify(data.title);
  const slug = `${slugBase}-${Date.now()}`;
  const short =
    data.description_full.length > 200
      ? data.description_full.slice(0, 200) + '...'
      : data.description_full;

  const job: Job = {
    slug,
    title: data.title,
    description_short: short,
    description_full: data.description_full,
    date,
    category: data.category,
  };

  const filePath = path.join(jobsDirectory, `${slug}.json`);
  await fs.mkdir(jobsDirectory, { recursive: true });
  await fs.writeFile(filePath, JSON.stringify(job, null, 2), 'utf8');
  return job;
}
EOF

# ─── lib/similarity.ts ─────────────────────────────────
cat > lib/similarity.ts << 'EOF'
import { Job } from './jobs';

export function getSimilarJobs(current: Job, allJobs: Job[], limit = 3): Job[] {
  const stopWords = new Set([
    'the', 'a', 'an', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'is', 'are',
    'we', 'you', 'they', 'it', 'with', 'as', 'by', 'from', 'that', 'this', 'be',
  ]);

  const getKeywords = (text: string): string[] =>
    text
      .toLowerCase()
      .split(/\W+/)
      .filter((w) => w.length > 2 && !stopWords.has(w));

  const currentKeywords = new Set([
    ...getKeywords(current.title),
    ...getKeywords(current.description_short),
  ]);

  return allJobs
    .filter((job) => job.slug !== current.slug)
    .map((job) => ({
      job,
      score: [...getKeywords(job.title), ...getKeywords(job.description_short)]
        .filter((w) => currentKeywords.has(w)).length,
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map((item) => item.job);
}
EOF

# ─── components/Layout.tsx ──────────────────────────────
cat > components/Layout.tsx << 'EOF'
import Head from 'next/head';
import Link from 'next/link';
import { siteConfig } from '@/lib/siteConfig';

interface LayoutProps {
  children: React.ReactNode;
  title?: string;
  description?: string;
}

export default function Layout({ children, title, description }: LayoutProps) {
  const pageTitle = title || siteConfig.defaultTitle;
  const pageDesc = description || siteConfig.defaultDescription;

  return (
    <>
      <Head>
        <title>{pageTitle}</title>
        <meta name="description" content={pageDesc} />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className="min-h-screen bg-gray-50">
        <header className="bg-white shadow-sm border-b">
          <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
            <Link href="/" className="text-xl font-bold text-gray-900">
              {siteConfig.name}
            </Link>
            <div className="flex gap-4">
              <Link href="/" className="text-gray-600 hover:text-gray-900">All Jobs</Link>
              <Link href="/category/internships-juniors" className="text-gray-600 hover:text-gray-900">Internships</Link>
              <Link href="/category/mid-senior-leads" className="text-gray-600 hover:text-gray-900">Mid & Senior</Link>
            </div>
          </nav>
        </header>
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {children}
        </main>
        <footer className="bg-white border-t mt-12 py-6 text-center text-gray-500 text-sm">
          © {new Date().getFullYear()} {siteConfig.name}
        </footer>
      </div>
    </>
  );
}
EOF

# ─── components/JobCard.tsx ─────────────────────────────
cat > components/JobCard.tsx << 'EOF'
import Link from 'next/link';
import { Job } from '@/lib/jobs';

interface JobCardProps {
  job: Job;
}

export default function JobCard({ job }: JobCardProps) {
  const formatDate = (dateString: string) => {
    const d = new Date(dateString);
    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  return (
    <Link href={`/jobs/${job.slug}`} className="block">
      <article className="bg-white rounded-lg border border-gray-200 p-5 hover:shadow-md transition-shadow h-full flex flex-col">
        <h2 className="text-lg font-semibold text-gray-900 mb-1">{job.title}</h2>
        <p className="text-sm text-gray-500 mb-2">{formatDate(job.date)}</p>
        <p className="text-gray-600 text-sm flex-1">{job.description_short}</p>
        {job.company && (
          <p className="text-xs text-gray-500 mt-2">{job.company}{job.location ? ` · ${job.location}` : ''}</p>
        )}
      </article>
    </Link>
  );
}
EOF

# ─── components/SearchBar.tsx ───────────────────────────
cat > components/SearchBar.tsx << 'EOF'
import { useState, useCallback, useEffect } from 'react';

interface SearchBarProps {
  onSearch: (query: string) => void;
  placeholder?: string;
}

export default function SearchBar({ onSearch, placeholder = 'Search...' }: SearchBarProps) {
  const [value, setValue] = useState('');

  const debouncedSearch = useCallback(
    (() => {
      let timer: NodeJS.Timeout;
      return (q: string) => {
        clearTimeout(timer);
        timer = setTimeout(() => onSearch(q), 300);
      };
    })(),
    [onSearch]
  );

  useEffect(() => {
    debouncedSearch(value);
  }, [value, debouncedSearch]);

  return (
    <div className="relative">
      <input
        type="text"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder={placeholder}
        className="w-full px-4 py-3 border border-gray-300 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none"
      />
      <svg className="absolute right-3 top-3.5 h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      </svg>
    </div>
  );
}
EOF

# ─── components/SimilarJobs.tsx ─────────────────────────
cat > components/SimilarJobs.tsx << 'EOF'
import JobCard from './JobCard';
import { Job } from '@/lib/jobs';

interface SimilarJobsProps {
  jobs: Job[];
}

export default function SimilarJobs({ jobs }: SimilarJobsProps) {
  if (!jobs || jobs.length === 0) return null;
  return (
    <section className="mt-12">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Similar Jobs</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {jobs.map((job) => (
          <JobCard key={job.slug} job={job} />
        ))}
      </div>
    </section>
  );
}
EOF

# ─── pages/index.tsx ────────────────────────────────────
cat > pages/index.tsx << 'EOF'
import { GetStaticProps } from 'next';
import { useState, useEffect } from 'react';
import Fuse from 'fuse.js';
import Layout from '@/components/Layout';
import JobCard from '@/components/JobCard';
import SearchBar from '@/components/SearchBar';
import { getAllJobs, Job } from '@/lib/jobs';
import { siteConfig } from '@/lib/siteConfig';

interface HomeProps {
  jobs: Job[];
  latestJobs: Job[];
}

export default function Home({ jobs, latestJobs }: HomeProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [activeCategory, setActiveCategory] = useState<string>('all');
  const [filteredJobs, setFilteredJobs] = useState<Job[]>([]);

  const fuse = new Fuse(jobs, {
    keys: ['title', 'description_short'],
    threshold: 0.4,
    includeScore: true,
  });

  useEffect(() => {
    let pool = activeCategory === 'all' ? jobs : jobs.filter((j) => j.category === activeCategory);

    if (searchQuery.trim()) {
      const results = fuse.search(searchQuery).map((r) => r.item);
      pool = pool.filter((j) => results.includes(j));
    }

    setFilteredJobs(pool);
  }, [searchQuery, activeCategory, jobs]);

  const categoryTabs = [
    { id: 'all', label: 'All Jobs' },
    ...siteConfig.categories.map((c) => ({ id: c.id, label: c.name })),
  ];

  return (
    <Layout>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">Web3 & Crypto Jobs</h1>
        <p className="text-gray-600 mb-6">
          Discover remote and on‑site Web3 opportunities. Updated daily.
        </p>
        <SearchBar onSearch={setSearchQuery} placeholder="Search jobs..." />
      </div>

      <div className="flex flex-wrap gap-2 mb-6">
        {categoryTabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveCategory(tab.id)}
            className={`px-4 py-2 rounded-full text-sm font-medium transition-colors ${
              activeCategory === tab.id
                ? 'bg-blue-600 text-white'
                : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {searchQuery && (
        <div className="mb-6">
          <p className="text-gray-600">Found {filteredJobs.length} job(s)</p>
        </div>
      )}

      {!searchQuery && activeCategory === 'all' && (
        <section className="mb-12">
          <h2 className="text-2xl font-bold text-gray-900 mb-6">Latest Jobs</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {latestJobs.map((job) => (
              <JobCard key={job.slug} job={job} />
            ))}
          </div>
        </section>
      )}

      <section>
        <h2 className="text-2xl font-bold text-gray-900 mb-6">
          {activeCategory !== 'all'
            ? siteConfig.categories.find((c) => c.id === activeCategory)?.name
            : searchQuery
            ? 'Search Results'
            : 'All Jobs'}
        </h2>
        {filteredJobs.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredJobs.map((job) => (
              <JobCard key={job.slug} job={job} />
            ))}
          </div>
        ) : (
          <div className="bg-gray-100 rounded-lg p-8 text-center">
            <p className="text-gray-600">No jobs found.</p>
          </div>
        )}
      </section>
    </Layout>
  );
}

export const getStaticProps: GetStaticProps<HomeProps> = async () => {
  const allJobs = await getAllJobs();
  const latestJobs = allJobs.slice(0, 6);

  return {
    props: {
      jobs: allJobs,
      latestJobs,
    },
    revalidate: siteConfig.revalidateSeconds,
  };
};
EOF

# ─── pages/category/[category].tsx ──────────────────────
mkdir -p pages/category
cat > 'pages/category/[category].tsx' << 'EOF'
import { GetStaticPaths, GetStaticProps } from 'next';
import Layout from '@/components/Layout';
import JobCard from '@/components/JobCard';
import { getJobsByCategory, Job } from '@/lib/jobs';
import { siteConfig } from '@/lib/siteConfig';

interface CategoryPageProps {
  categoryName: string;
  jobs: Job[];
}

export default function CategoryPage({ categoryName, jobs }: CategoryPageProps) {
  return (
    <Layout
      title={`${categoryName} – ${siteConfig.name}`}
      description={`${categoryName} job openings in Web3`}
    >
      <h1 className="text-3xl font-bold text-gray-900 mb-6">{categoryName}</h1>
      {jobs.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {jobs.map((job) => (
            <JobCard key={job.slug} job={job} />
          ))}
        </div>
      ) : (
        <div className="bg-gray-100 rounded-lg p-8 text-center">
          <p className="text-gray-600">No jobs in this category yet.</p>
        </div>
      )}
    </Layout>
  );
}

export const getStaticPaths: GetStaticPaths = async () => {
  const paths = siteConfig.categories.map((c) => ({ params: { category: c.id } }));
  return { paths, fallback: 'blocking' };
};

export const getStaticProps: GetStaticProps<CategoryPageProps> = async ({ params }) => {
  const category = params?.category as string;
  const cat = siteConfig.categories.find((c) => c.id === category);
  if (!cat) return { notFound: true };

  const jobs = await getJobsByCategory(category);
  return {
    props: {
      categoryName: cat.name,
      jobs,
    },
    revalidate: siteConfig.revalidateSeconds,
  };
};
EOF

# ─── pages/jobs/[slug].tsx ──────────────────────────────
mkdir -p pages/jobs
cat > 'pages/jobs/[slug].tsx' << 'EOF'
import { GetStaticPaths, GetStaticProps } from 'next';
import Link from 'next/link';
import Head from 'next/head';
import Layout from '@/components/Layout';
import SimilarJobs from '@/components/SimilarJobs';
import { getAllJobs, getAllSlugs, getJobBySlug, Job } from '@/lib/jobs';
import { getSimilarJobs } from '@/lib/similarity';
import { siteConfig } from '@/lib/siteConfig';

interface JobPageProps {
  job: Job;
  similarJobs: Job[];
}

export default function JobPage({ job, similarJobs }: JobPageProps) {
  const formatDate = (dateString: string) => {
    const d = new Date(dateString);
    return d.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
  };

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'JobPosting',
    title: job.title,
    datePosted: job.date,
    description: job.description_full,
    hiringOrganization: job.company
      ? { '@type': 'Organization', name: job.company }
      : undefined,
    jobLocation: job.location
      ? {
          '@type': 'Place',
          address: { '@type': 'PostalAddress', addressLocality: job.location },
        }
      : undefined,
    employmentType: job.type || undefined,
    validThrough: new Date(new Date(job.date).getTime() + 30 * 24 * 60 * 60 * 1000).toISOString(),
  };

  return (
    <Layout
      title={`${job.title} | ${siteConfig.name}`}
      description={job.description_short}
    >
      <Head>
        {job.company && (
          <script
            type="application/ld+json"
            dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
          />
        )}
      </Head>
      <div className="max-w-3xl mx-auto">
        <Link href="/" className="text-blue-600 hover:underline mb-4 inline-block">
          ← Back to all jobs
        </Link>

        <article className="bg-white rounded-lg border border-gray-200 p-6 mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">{job.title}</h1>
          <div className="flex flex-wrap items-center gap-2 text-sm text-gray-600 mb-4">
            {job.company && <span className="font-medium">{job.company}</span>}
            {job.company && job.location && <span>·</span>}
            {job.location && <span>{job.location}</span>}
            {job.type && <span className="px-2 py-0.5 bg-gray-100 rounded-full">{job.type}</span>}
          </div>
          <div className="text-sm text-gray-500 mb-4">
            Posted on {formatDate(job.date)}
          </div>

          <div className="prose max-w-none whitespace-pre-wrap text-gray-700">
            {job.description_full}
          </div>
        </article>

        {similarJobs.length > 0 && <SimilarJobs jobs={similarJobs} />}
      </div>
    </Layout>
  );
}

export const getStaticPaths: GetStaticPaths = async () => {
  const slugs = await getAllSlugs();
  return { paths: slugs.map((slug) => ({ params: { slug } })), fallback: 'blocking' };
};

export const getStaticProps: GetStaticProps<JobPageProps> = async ({ params }) => {
  const slug = params?.slug as string;
  const job = await getJobBySlug(slug);
  if (!job) return { notFound: true };

  const allJobs = await getAllJobs();
  const similarJobs = getSimilarJobs(job, allJobs.filter((j) => j.slug !== job.slug));

  return {
    props: { job, similarJobs },
    revalidate: siteConfig.revalidateSeconds,
  };
};
EOF

# ─── pages/sitemap.xml.tsx ──────────────────────────────
cat > pages/sitemap.xml.tsx << 'EOF'
import { GetServerSideProps } from 'next';
import { getAllJobs } from '@/lib/jobs';
import { siteConfig } from '@/lib/siteConfig';

export const getServerSideProps: GetServerSideProps = async ({ res }) => {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://your-domain.com';
  const jobs = await getAllJobs();

  const staticPages = [
    { loc: `${baseUrl}/`, changefreq: 'daily', priority: '1.0' },
    ...siteConfig.categories.map((c) => ({
      loc: `${baseUrl}/category/${c.id}`,
      changefreq: 'daily',
      priority: '0.9',
    })),
  ];

  const jobPages = jobs.map((job) => ({
    loc: `${baseUrl}/jobs/${job.slug}`,
    lastmod: job.date,
    changefreq: 'weekly',
    priority: '0.8',
  }));

  const sitemap = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  ${[...staticPages, ...jobPages]
    .map(
      (page) => `
    <url>
      <loc>${page.loc}</loc>
      <lastmod>${page.lastmod || new Date().toISOString()}</lastmod>
      <changefreq>${page.changefreq}</changefreq>
      <priority>${page.priority}</priority>
    </url>`
    )
    .join('')}
</urlset>`;

  res.setHeader('Content-Type', 'text/xml');
  res.write(sitemap);
  res.end();

  return { props: {} };
};

export default function Sitemap() {
  return null;
}
EOF

# ─── pages/api/revalidate.ts ────────────────────────────
mkdir -p pages/api
cat > pages/api/revalidate.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.query.secret !== process.env.REVALIDATION_SECRET) {
    return res.status(401).json({ message: 'Invalid token' });
  }

  try {
    await res.revalidate('/');
    await res.revalidate('/category/internships-juniors');
    await res.revalidate('/category/mid-senior-leads');
    return res.json({ revalidated: true });
  } catch (err) {
    return res.status(500).send('Error revalidating');
  }
}
EOF

# ─── pages/api/add-job.ts ───────────────────────────────
cat > pages/api/add-job.ts << 'EOF'
import type { NextApiRequest, NextApiResponse } from 'next';
import { createJobFile } from '@/lib/jobs';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const token = req.headers['x-bot-token'] || req.query.token;
  if (token !== process.env.BOT_API_SECRET) {
    return res.status(401).json({ error: 'Invalid token' });
  }

  try {
    const { text, category } = req.body;

    if (!text || typeof text !== 'string' || !category || typeof category !== 'string') {
      return res.status(400).json({ error: 'Missing text or category' });
    }

    const lines = text.trim().split('\n');
    const title = lines[0].trim();
    const description_full = lines.slice(1).join('\n').trim() || title;

    if (!title) {
      return res.status(400).json({ error: 'Empty title' });
    }

    const allowedCategories = ['internships-juniors', 'mid-senior-leads'];
    if (!allowedCategories.includes(category)) {
      return res.status(400).json({ error: 'Invalid category' });
    }

    const job = await createJobFile({ title, description_full, category });

    await res.revalidate('/');
    await res.revalidate(`/category/${category}`);

    return res.status(201).json({ success: true, slug: job.slug });
  } catch (err) {
    console.error('Failed to add job', err);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
EOF

echo "✅ Project structure created. Run 'npm install' to install dependencies."
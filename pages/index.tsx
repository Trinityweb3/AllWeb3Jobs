import { GetStaticProps } from 'next';
import { useState, useEffect } from 'react';
import Fuse from 'fuse.js';
import Layout from '@/components/Layout';
import JobCard from '@/components/JobCard';
import SearchBar from '@/components/SearchBar';
import CryptoDashboard from '@/components/CryptoDashboard'; // ← если файл называется иначе (MarketDashboard), исправьте здесь
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
      {/* 📈 Market Dashboard */}
      <CryptoDashboard />

      {/* 🔍 Search & Filters */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-4">All Web3 Jobs</h1>
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
                ? 'bg-brand-500 text-white'
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

      {/* ⭐ Latest Jobs (only when no search and category is "all") */}
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

      {/* 📋 Main Job List */}
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
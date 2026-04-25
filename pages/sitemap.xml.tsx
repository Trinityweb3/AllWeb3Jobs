import { GetServerSideProps } from 'next';
import { getAllJobs } from '@/lib/jobs';
import { siteConfig } from '@/lib/siteConfig';

interface SitemapEntry {
  loc: string;
  lastmod?: string;
  changefreq: string;
  priority: string;
}

export const getServerSideProps: GetServerSideProps = async ({ res }) => {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://your-domain.com';
  const jobs = await getAllJobs();

  const staticPages: SitemapEntry[] = [
    { loc: `${baseUrl}/`, changefreq: 'daily', priority: '1.0' },
    ...siteConfig.categories.map((c) => ({
      loc: `${baseUrl}/category/${c.id}`,
      changefreq: 'daily' as const,
      priority: '0.9',
    })),
  ];

  const jobPages: SitemapEntry[] = jobs.map((job) => ({
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
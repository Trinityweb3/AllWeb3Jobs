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

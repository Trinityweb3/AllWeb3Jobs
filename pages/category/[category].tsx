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

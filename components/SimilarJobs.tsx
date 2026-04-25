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

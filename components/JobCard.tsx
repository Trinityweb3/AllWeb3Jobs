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

import React, { forwardRef } from 'react';
import type { ResumeData } from '@/pages/create-resume';

interface Props {
  data: ResumeData;
}

const ResumePreview = forwardRef<HTMLDivElement, Props>(({ data }, ref) => {
  const { template, personal, experience, education, skills } = data;

  // colors
const themes = {
  modern: {
    header:
        'bg-gradient-to-br from-[#020617] via-[#0f172a] to-[#111827] text-white shadow-[0_10px_40px_rgba(0,0,0,0.45)] border border-cyan-500/10',
    accent:
        'text-cyan-300',
    section:
        'rounded-2xl border border-slate-800 bg-slate-900/40 backdrop-blur-xl hover:border-cyan-500/20 transition duration-300',
},

  classic: {
    header: 'bg-gradient-to-r from-blue-950 via-indigo-900 to-blue-900 text-white shadow-md',
    accent: 'text-amber-600',
    section: 'border-blue-300',
  },

  minimal: {
    header: 'bg-white border-b-2 border-gray-300 text-gray-900',
    accent: 'text-gray-500',
    section: 'border-gray-100',
  },
};

  const theme = themes[template] || themes.modern;

  return (
    <div ref={ref} id="resume-preview" className="p-8 font-sans text-sm" style={{ minHeight: '297mm' }}>
      <div className={`${theme.header} p-6 rounded-t-lg`}>
        <h1 className="text-3xl font-bold">{personal.fullName || 'Your Name'}</h1>
        <p className="text-lg mt-1">{personal.title || 'Professional Title'}</p>
        <div className="flex flex-wrap gap-x-4 gap-y-1 mt-3 text-sm opacity-80">
          {personal.email && <span>✉️ {personal.email}</span>}
          {personal.phone && <span>📞 {personal.phone}</span>}
          {personal.location && <span>📍 {personal.location}</span>}
          {personal.website && <span>🔗 {personal.website}</span>}
        </div>
      </div>

      <div className="p-6">
        {personal.summary && (
          <section className="mb-6">
            <h2 className={`text-lg font-semibold border-b pb-1 mb-2 ${theme.accent}`}>Summary</h2>
            <p className="text-gray-700">{personal.summary}</p>
          </section>
        )}

        {experience.length > 0 && (
          <section className="mb-6">
            <h2 className={`text-lg font-semibold border-b pb-1 mb-2 ${theme.accent}`}>Experience</h2>
            {experience.map((exp) => (
              <div key={exp.id} className="mb-3">
                <div className="flex justify-between">
                  <span className="font-medium">{exp.position || 'Position'}</span>
                  <span className="text-gray-500 text-xs">
                    {exp.startDate} – {exp.endDate || 'Present'}
                  </span>
                </div>
                <p className="text-gray-600 text-sm">{exp.company || 'Company'}</p>
                {exp.description && <p className="text-gray-700 mt-1">{exp.description}</p>}
              </div>
            ))}
          </section>
        )}

        {education.length > 0 && (
          <section className="mb-6">
            <h2 className={`text-lg font-semibold border-b pb-1 mb-2 ${theme.accent}`}>Education</h2>
            {education.map((edu) => (
              <div key={edu.id} className="mb-2">
                <span className="font-medium">{edu.school || 'School'}</span> – {edu.degree || 'Degree'} ({edu.graduationYear || 'Year'})
              </div>
            ))}
          </section>
        )}

        {skills.length > 0 && skills[0] !== '' && (
          <section>
            <h2 className={`text-lg font-semibold border-b pb-1 mb-2 ${theme.accent}`}>Skills</h2>
            <div className="flex flex-wrap gap-2">
              {skills.map((skill) => (
                <span key={skill} className="px-2 py-1 bg-gray-100 rounded-full text-xs">{skill}</span>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  );
});

ResumePreview.displayName = 'ResumePreview';

export default ResumePreview;
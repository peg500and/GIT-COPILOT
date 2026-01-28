import {
  RadarChart,
  PolarGrid,
  PolarAngleAxis,
  PolarRadiusAxis,
  Radar,
  ResponsiveContainer,
  Tooltip,
} from 'recharts';
import { sovereigntyPillars } from '../data/dashboardData';
import { Server, Shield, Lock, Code, Brain } from 'lucide-react';

const iconMap = {
  Server,
  Shield,
  Lock,
  Code,
  Brain,
};

export default function SovereigntyGauge() {
  return (
    <div className="dashboard-card bg-white rounded-2xl p-6 shadow-lg chart-container">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">
        Score Souveraineté Numérique
      </h3>
      <div className="h-72">
        <ResponsiveContainer width="100%" height="100%">
          <RadarChart data={sovereigntyPillars}>
            <PolarGrid stroke="#e5e7eb" />
            <PolarAngleAxis
              dataKey="pillar"
              tick={{ fill: '#6b7280', fontSize: 11 }}
            />
            <PolarRadiusAxis
              angle={30}
              domain={[0, 100]}
              tick={{ fill: '#6b7280', fontSize: 10 }}
            />
            <Radar
              name="Score"
              dataKey="score"
              stroke="#3b82f6"
              fill="#3b82f6"
              fillOpacity={0.5}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: '#fff',
                border: '1px solid #e5e7eb',
                borderRadius: '8px'
              }}
              formatter={(value) => [`${value}%`, 'Score']}
            />
          </RadarChart>
        </ResponsiveContainer>
      </div>
      <div className="mt-4 grid grid-cols-5 gap-2">
        {sovereigntyPillars.map((item) => {
          const Icon = iconMap[item.icon];
          return (
            <div key={item.pillar} className="text-center">
              <div className="flex justify-center mb-1">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <Icon className="h-4 w-4 text-blue-600" />
                </div>
              </div>
              <p className="text-xs font-medium text-gray-600">{item.score}%</p>
            </div>
          );
        })}
      </div>
    </div>
  );
}

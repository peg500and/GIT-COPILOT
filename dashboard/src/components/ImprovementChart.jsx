import {
  RadialBarChart,
  RadialBar,
  ResponsiveContainer,
  Legend,
  Tooltip,
} from 'recharts';
import { improvementMetrics } from '../data/dashboardData';

const colors = ['#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'];

export default function ImprovementChart() {
  const data = improvementMetrics.map((item, index) => ({
    ...item,
    fill: colors[index % colors.length],
  }));

  return (
    <div className="dashboard-card bg-white rounded-2xl p-6 shadow-lg chart-container">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">
        Gains d'Amélioration (%)
      </h3>
      <div className="h-80">
        <ResponsiveContainer width="100%" height="100%">
          <RadialBarChart
            cx="50%"
            cy="50%"
            innerRadius="20%"
            outerRadius="90%"
            data={data}
            startAngle={180}
            endAngle={0}
          >
            <RadialBar
              minAngle={15}
              label={{ position: 'insideStart', fill: '#fff', fontSize: 11 }}
              background
              clockWise
              dataKey="improvement"
            />
            <Tooltip
              contentStyle={{
                backgroundColor: '#fff',
                border: '1px solid #e5e7eb',
                borderRadius: '8px'
              }}
              formatter={(value) => [`${value}%`, 'Amélioration']}
            />
            <Legend
              iconSize={10}
              layout="horizontal"
              verticalAlign="bottom"
              formatter={(value, entry) => entry.payload.category}
            />
          </RadialBarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

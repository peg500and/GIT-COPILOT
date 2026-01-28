import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from 'recharts';
import { optimizationTimeline } from '../data/dashboardData';

export default function TimelineChart() {
  return (
    <div className="dashboard-card bg-white rounded-2xl p-6 shadow-lg chart-container">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">
        Timeline des Optimisations
      </h3>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={optimizationTimeline}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis
              dataKey="phase"
              tick={{ fill: '#6b7280', fontSize: 11 }}
            />
            <YAxis
              yAxisId="left"
              tick={{ fill: '#6b7280', fontSize: 11 }}
              label={{ value: 'Optimisations', angle: -90, position: 'insideLeft', fill: '#6b7280', fontSize: 11 }}
            />
            <YAxis
              yAxisId="right"
              orientation="right"
              tick={{ fill: '#6b7280', fontSize: 11 }}
              label={{ value: 'Performance (%)', angle: 90, position: 'insideRight', fill: '#6b7280', fontSize: 11 }}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: '#fff',
                border: '1px solid #e5e7eb',
                borderRadius: '8px'
              }}
            />
            <Legend />
            <Line
              yAxisId="left"
              type="monotone"
              dataKey="optimizations"
              name="Nb Optimisations"
              stroke="#8b5cf6"
              strokeWidth={3}
              dot={{ fill: '#8b5cf6', strokeWidth: 2, r: 5 }}
              activeDot={{ r: 8 }}
            />
            <Line
              yAxisId="right"
              type="monotone"
              dataKey="performance"
              name="Performance"
              stroke="#10b981"
              strokeWidth={3}
              dot={{ fill: '#10b981', strokeWidth: 2, r: 5 }}
              activeDot={{ r: 8 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

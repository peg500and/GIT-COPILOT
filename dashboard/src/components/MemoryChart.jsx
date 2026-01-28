import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
  LabelList,
} from 'recharts';
import { memoryComparison } from '../data/dashboardData';

export default function MemoryChart() {
  const colors = ['#ef4444', '#22c55e'];

  return (
    <div className="dashboard-card bg-white rounded-2xl p-6 shadow-lg chart-container">
      <h3 className="text-lg font-semibold text-gray-800 mb-2">
        Consommation Mémoire RAM
      </h3>
      <p className="text-sm text-gray-500 mb-4">Réduction de 35% en v2.2</p>
      <div className="h-48">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={memoryComparison} layout="vertical">
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis
              type="number"
              tick={{ fill: '#6b7280', fontSize: 12 }}
              domain={[0, 100]}
              unit=" MB"
            />
            <YAxis
              type="category"
              dataKey="name"
              tick={{ fill: '#6b7280', fontSize: 14, fontWeight: 600 }}
              width={60}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: '#fff',
                border: '1px solid #e5e7eb',
                borderRadius: '8px'
              }}
              formatter={(value) => [`${value} MB`, 'Mémoire']}
            />
            <Bar dataKey="memory" radius={[0, 8, 8, 0]} barSize={40}>
              {memoryComparison.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={colors[index]} />
              ))}
              <LabelList
                dataKey="memory"
                position="right"
                fill="#374151"
                fontSize={14}
                fontWeight={600}
                formatter={(value) => `${value} MB`}
              />
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

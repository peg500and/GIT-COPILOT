import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { executionModes } from '../data/dashboardData';

export default function ExecutionModesChart() {
  return (
    <div className="dashboard-card bg-white rounded-2xl p-6 shadow-lg chart-container">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">
        Modes d'Exécution - Performance
      </h3>
      <div className="h-64">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart data={executionModes}>
            <defs>
              <linearGradient id="colorSources" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
              </linearGradient>
              <linearGradient id="colorArticles" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#10b981" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
              </linearGradient>
              <linearGradient id="colorDuration" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#f59e0b" stopOpacity={0.8}/>
                <stop offset="95%" stopColor="#f59e0b" stopOpacity={0}/>
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis dataKey="mode" tick={{ fill: '#6b7280', fontSize: 12 }} />
            <YAxis tick={{ fill: '#6b7280', fontSize: 12 }} />
            <Tooltip
              contentStyle={{
                backgroundColor: '#fff',
                border: '1px solid #e5e7eb',
                borderRadius: '8px'
              }}
            />
            <Area
              type="monotone"
              dataKey="sources"
              name="Sources"
              stroke="#3b82f6"
              fillOpacity={1}
              fill="url(#colorSources)"
            />
            <Area
              type="monotone"
              dataKey="articles"
              name="Articles"
              stroke="#10b981"
              fillOpacity={1}
              fill="url(#colorArticles)"
            />
            <Area
              type="monotone"
              dataKey="duration"
              name="Durée (s)"
              stroke="#f59e0b"
              fillOpacity={1}
              fill="url(#colorDuration)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
      <div className="mt-4 grid grid-cols-3 gap-4">
        {executionModes.map((mode) => (
          <div key={mode.mode} className="text-center p-3 bg-gray-50 rounded-lg">
            <p className="font-semibold text-gray-800">{mode.mode}</p>
            <p className="text-xs text-gray-500">{mode.usage}</p>
          </div>
        ))}
      </div>
    </div>
  );
}

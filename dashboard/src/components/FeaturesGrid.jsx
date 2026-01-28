import { keyFeatures } from '../data/dashboardData';
import { Sparkles, Zap, BarChart2, Database, CheckCircle, Settings } from 'lucide-react';

const icons = [Sparkles, Zap, BarChart2, Database, CheckCircle, Settings];

export default function FeaturesGrid() {
  return (
    <div className="dashboard-card bg-white rounded-2xl p-6 shadow-lg">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">
        Nouvelles Fonctionnalités v2.2
      </h3>
      <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
        {keyFeatures.map((feature, index) => {
          const Icon = icons[index];
          return (
            <div
              key={feature.id}
              className="p-4 bg-gradient-to-br from-gray-50 to-gray-100 rounded-xl border border-gray-100 hover:border-blue-200 transition-all"
            >
              <div className="flex items-start space-x-3">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <Icon className="h-5 w-5 text-blue-600" />
                </div>
                <div className="flex-1">
                  <h4 className="font-semibold text-gray-800 text-sm">
                    {feature.title}
                  </h4>
                  <p className="text-xs text-gray-500 mt-1">
                    {feature.description}
                  </p>
                  <span className="inline-block mt-2 px-2 py-1 bg-green-100 text-green-700 text-xs rounded-full font-medium">
                    {feature.gain}
                  </span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

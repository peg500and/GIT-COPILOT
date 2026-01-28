import { architectureComponents } from '../data/dashboardData';
import { FileCode, Settings, Database, FileText, ScrollText, Archive } from 'lucide-react';

const typeConfig = {
  Core: { icon: FileCode, color: 'bg-blue-500', lightColor: 'bg-blue-100' },
  Config: { icon: Settings, color: 'bg-yellow-500', lightColor: 'bg-yellow-100' },
  Data: { icon: Database, color: 'bg-green-500', lightColor: 'bg-green-100' },
  Output: { icon: FileText, color: 'bg-purple-500', lightColor: 'bg-purple-100' },
  Storage: { icon: Archive, color: 'bg-red-500', lightColor: 'bg-red-100' },
};

export default function ArchitectureView() {
  return (
    <div className="dashboard-card bg-white rounded-2xl p-6 shadow-lg">
      <h3 className="text-lg font-semibold text-gray-800 mb-4">
        Architecture du Système
      </h3>
      <div className="relative">
        {/* Central hub */}
        <div className="flex justify-center mb-6">
          <div className="p-4 bg-gradient-to-br from-blue-600 to-blue-800 rounded-2xl text-white shadow-lg">
            <p className="font-bold text-lg">Agent Andorra 360</p>
            <p className="text-blue-200 text-sm">v2.2 Optimized</p>
          </div>
        </div>

        {/* Components grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {architectureComponents.map((component) => {
            const config = typeConfig[component.type];
            const Icon = config.icon;
            return (
              <div
                key={component.name}
                className={`p-3 ${config.lightColor} rounded-xl border-2 border-transparent hover:border-gray-300 transition-all`}
              >
                <div className="flex items-center space-x-2 mb-2">
                  <div className={`p-1.5 ${config.color} rounded-lg`}>
                    <Icon className="h-4 w-4 text-white" />
                  </div>
                  <span className="text-xs font-medium text-gray-500 uppercase">
                    {component.type}
                  </span>
                </div>
                <p className="font-semibold text-gray-800 text-sm">
                  {component.name}
                </p>
                <p className="text-xs text-gray-500">
                  Fichiers: {component.files}
                </p>
              </div>
            );
          })}
        </div>

        {/* Legend */}
        <div className="mt-6 flex flex-wrap justify-center gap-3">
          {Object.entries(typeConfig).map(([type, config]) => {
            const Icon = config.icon;
            return (
              <div key={type} className="flex items-center space-x-1">
                <div className={`p-1 ${config.color} rounded`}>
                  <Icon className="h-3 w-3 text-white" />
                </div>
                <span className="text-xs text-gray-600">{type}</span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}

import { Activity, Shield, Zap } from 'lucide-react';

export default function Header() {
  return (
    <header className="bg-gradient-to-r from-slate-900 via-blue-900 to-slate-900 text-white shadow-lg">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <div className="p-3 bg-blue-600 rounded-xl shadow-lg">
              <Shield className="h-8 w-8" />
            </div>
            <div>
              <h1 className="text-2xl font-bold">Souveraineté Numérique</h1>
              <p className="text-blue-200 text-sm">Agent Andorra 360 - Dashboard v2.2</p>
            </div>
          </div>
          <div className="flex items-center space-x-6">
            <div className="flex items-center space-x-2 bg-green-600/20 px-4 py-2 rounded-lg">
              <Activity className="h-5 w-5 text-green-400" />
              <span className="text-green-400 font-medium">Système Actif</span>
            </div>
            <div className="flex items-center space-x-2 bg-yellow-600/20 px-4 py-2 rounded-lg">
              <Zap className="h-5 w-5 text-yellow-400" />
              <span className="text-yellow-400 font-medium">+60% Performance</span>
            </div>
          </div>
        </div>
      </div>
    </header>
  );
}

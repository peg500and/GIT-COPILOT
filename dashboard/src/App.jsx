import { useState } from 'react';
import {
  Gauge,
  TrendingUp,
  Shield,
  Layers,
  Activity,
  Code,
  Database,
  Clock,
} from 'lucide-react';

import Header from './components/Header';
import StatCard from './components/StatCard';
import PerformanceChart from './components/PerformanceChart';
import ImprovementChart from './components/ImprovementChart';
import ExecutionModesChart from './components/ExecutionModesChart';
import OptimizationsPieChart from './components/OptimizationsPieChart';
import SovereigntyGauge from './components/SovereigntyGauge';
import TimelineChart from './components/TimelineChart';
import FeaturesGrid from './components/FeaturesGrid';
import ArchitectureView from './components/ArchitectureView';
import MemoryChart from './components/MemoryChart';
import { summaryStats } from './data/dashboardData';

function App() {
  const [activeTab, setActiveTab] = useState('overview');

  const tabs = [
    { id: 'overview', label: 'Vue d\'ensemble', icon: Activity },
    { id: 'performance', label: 'Performance', icon: TrendingUp },
    { id: 'sovereignty', label: 'Souveraineté', icon: Shield },
    { id: 'architecture', label: 'Architecture', icon: Layers },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      <Header />

      {/* Navigation Tabs */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <nav className="flex space-x-8" aria-label="Tabs">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`
                    flex items-center space-x-2 py-4 px-1 border-b-2 font-medium text-sm transition-colors
                    ${activeTab === tab.id
                      ? 'border-blue-500 text-blue-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    }
                  `}
                >
                  <Icon className="h-5 w-5" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </nav>
        </div>
      </div>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Summary Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="Total Optimisations"
            value={summaryStats.totalOptimizations}
            subtitle="Améliorations v2.2"
            icon={Code}
            gradient="gradient-primary"
          />
          <StatCard
            title="Gain Performance"
            value={summaryStats.performanceGain}
            subtitle="Plus rapide"
            icon={TrendingUp}
            gradient="gradient-success"
          />
          <StatCard
            title="Réduction Mémoire"
            value={summaryStats.memoryReduction}
            subtitle="Moins de RAM"
            icon={Database}
            gradient="gradient-warning"
          />
          <StatCard
            title="Compatibilité"
            value={summaryStats.compatibility}
            subtitle="Rétrocompatible"
            icon={Clock}
            gradient="gradient-info"
          />
        </div>

        {/* Tab Content */}
        {activeTab === 'overview' && (
          <div className="space-y-8">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <PerformanceChart />
              <OptimizationsPieChart />
            </div>
            <FeaturesGrid />
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <TimelineChart />
              <MemoryChart />
            </div>
          </div>
        )}

        {activeTab === 'performance' && (
          <div className="space-y-8">
            <PerformanceChart />
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <ImprovementChart />
              <MemoryChart />
            </div>
            <ExecutionModesChart />
            <TimelineChart />
          </div>
        )}

        {activeTab === 'sovereignty' && (
          <div className="space-y-8">
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <SovereigntyGauge />
              <div className="dashboard-card bg-gradient-to-br from-slate-900 to-blue-900 rounded-2xl p-6 shadow-lg text-white">
                <h3 className="text-lg font-semibold mb-4">
                  Principes de Souveraineté Numérique
                </h3>
                <div className="space-y-4">
                  <div className="flex items-start space-x-3">
                    <div className="p-2 bg-green-500/20 rounded-lg">
                      <Shield className="h-5 w-5 text-green-400" />
                    </div>
                    <div>
                      <p className="font-medium">Infrastructure Locale</p>
                      <p className="text-sm text-gray-300">
                        Tout fonctionne localement sans dépendance cloud
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-3">
                    <div className="p-2 bg-blue-500/20 rounded-lg">
                      <Database className="h-5 w-5 text-blue-400" />
                    </div>
                    <div>
                      <p className="font-medium">Données Souveraines</p>
                      <p className="text-sm text-gray-300">
                        Base SQLite locale avec chiffrement possible
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-3">
                    <div className="p-2 bg-purple-500/20 rounded-lg">
                      <Gauge className="h-5 w-5 text-purple-400" />
                    </div>
                    <div>
                      <p className="font-medium">IA Locale via Ollama</p>
                      <p className="text-sm text-gray-300">
                        PHI-4 / Gemma s'exécutent sur votre machine
                      </p>
                    </div>
                  </div>
                  <div className="flex items-start space-x-3">
                    <div className="p-2 bg-yellow-500/20 rounded-lg">
                      <Code className="h-5 w-5 text-yellow-400" />
                    </div>
                    <div>
                      <p className="font-medium">Code Open Source</p>
                      <p className="text-sm text-gray-300">
                        100% auditable et modifiable
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <FeaturesGrid />
          </div>
        )}

        {activeTab === 'architecture' && (
          <div className="space-y-8">
            <ArchitectureView />
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <OptimizationsPieChart />
              <div className="dashboard-card bg-white rounded-2xl p-6 shadow-lg">
                <h3 className="text-lg font-semibold text-gray-800 mb-4">
                  Stack Technique
                </h3>
                <div className="space-y-3">
                  {[
                    { name: 'PowerShell', version: '5.1+', color: 'bg-blue-500' },
                    { name: 'Python', version: '3.9+', color: 'bg-yellow-500' },
                    { name: 'Ollama', version: 'Latest', color: 'bg-green-500' },
                    { name: 'SQLite', version: '3.x', color: 'bg-purple-500' },
                    { name: 'PHI-4 / Gemma', version: 'AI Models', color: 'bg-red-500' },
                    { name: 'Windows', version: '10/11', color: 'bg-cyan-500' },
                  ].map((tech) => (
                    <div
                      key={tech.name}
                      className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                    >
                      <div className="flex items-center space-x-3">
                        <div className={`w-3 h-3 rounded-full ${tech.color}`} />
                        <span className="font-medium text-gray-800">{tech.name}</span>
                      </div>
                      <span className="text-sm text-gray-500">{tech.version}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
            <ExecutionModesChart />
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="bg-white border-t border-gray-200 mt-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="text-center md:text-left mb-4 md:mb-0">
              <p className="text-gray-600 font-medium">
                Agent Andorra 360 - Dashboard v2.2 Optimized
              </p>
              <p className="text-sm text-gray-500">
                Souveraineté Numérique - Veille Informationnelle avec IA Locale
              </p>
            </div>
            <div className="flex items-center space-x-4">
              <a
                href="https://github.com/peg500and/SOUVERAINETE-NUMERIQUE"
                target="_blank"
                rel="noopener noreferrer"
                className="px-4 py-2 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors text-sm font-medium"
              >
                GitHub Repository
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;

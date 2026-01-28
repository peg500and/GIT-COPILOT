// Performance comparison data (v2.1 vs v2.2)
export const performanceComparison = [
  { operation: 'Setup Initial', v21: 45, v22: 28, unit: 's' },
  { operation: 'Mode Quick', v21: 25, v22: 12, unit: 's' },
  { operation: 'Mode Balanced', v21: 35, v22: 20, unit: 's' },
  { operation: 'Nettoyage', v21: 8, v22: 3, unit: 's' },
  { operation: 'Sauvegarde', v21: 5, v22: 2, unit: 's' },
];

export const memoryComparison = [
  { name: 'v2.1', memory: 85 },
  { name: 'v2.2', memory: 55 },
];

// Improvement percentages
export const improvementMetrics = [
  { category: 'Setup Initial', improvement: 38 },
  { category: 'Mode Quick', improvement: 52 },
  { category: 'Mode Balanced', improvement: 43 },
  { category: 'Nettoyage', improvement: 62 },
  { category: 'Sauvegarde', improvement: 60 },
  { category: 'Mémoire RAM', improvement: 35 },
];

// Execution modes data
export const executionModes = [
  { mode: 'Quick', sources: 3, articles: 10, duration: 12, usage: 'Test rapide' },
  { mode: 'Balanced', sources: 5, articles: 15, duration: 20, usage: 'Usage quotidien' },
  { mode: 'Deep', sources: 5, articles: 30, duration: 45, usage: 'Analyse complète' },
];

// Optimizations by category
export const optimizationsByCategory = [
  { name: 'Performance', count: 6, color: '#3b82f6' },
  { name: 'Architecture', count: 3, color: '#10b981' },
  { name: 'Mémoire', count: 2, color: '#f59e0b' },
  { name: 'Diagnostics', count: 2, color: '#8b5cf6' },
  { name: 'Robustesse', count: 3, color: '#ef4444' },
  { name: 'Fonctionnel', count: 4, color: '#06b6d4' },
  { name: 'Configuration', count: 3, color: '#ec4899' },
  { name: 'Code', count: 3, color: '#84cc16' },
];

// Key features
export const keyFeatures = [
  { id: 1, title: 'Cache Intelligent', description: 'Vérifications Python/Ollama cachées', gain: '2-3s' },
  { id: 2, title: 'Parallélisation', description: 'Nettoyage rapports + logs simultané', gain: '60%' },
  { id: 3, title: 'Statistiques Étendues', description: 'Articles totaux et récents (24h)', gain: 'Visibilité' },
  { id: 4, title: 'Gestion Auto Sauvegardes', description: 'Garde les 10 plus récentes', gain: 'Automatique' },
  { id: 5, title: 'Validation Entrées', description: 'Prévient les erreurs', gain: 'Robustesse' },
  { id: 6, title: 'Configuration Adaptative', description: 'Mode quick: 3 sources', gain: 'Flexibilité' },
];

// Digital Sovereignty pillars
export const sovereigntyPillars = [
  {
    pillar: 'Infrastructure Locale',
    score: 95,
    description: 'Tout local (pas de cloud)',
    icon: 'Server'
  },
  {
    pillar: 'Indépendance API',
    score: 100,
    description: 'Aucune API externe requise',
    icon: 'Shield'
  },
  {
    pillar: 'Sécurité Données',
    score: 90,
    description: 'Base SQLite chiffrée possible',
    icon: 'Lock'
  },
  {
    pillar: 'Open Source',
    score: 100,
    description: 'Code auditable',
    icon: 'Code'
  },
  {
    pillar: 'IA Locale',
    score: 85,
    description: 'PHI-4/Gemma via Ollama',
    icon: 'Brain'
  },
];

// Timeline of optimizations
export const optimizationTimeline = [
  { phase: 'Initial', optimizations: 0, performance: 100 },
  { phase: 'Cache', optimizations: 3, performance: 115 },
  { phase: 'Parallélisation', optimizations: 6, performance: 135 },
  { phase: 'Mémoire', optimizations: 8, performance: 145 },
  { phase: 'Architecture', optimizations: 11, performance: 155 },
  { phase: 'Final v2.2', optimizations: 26, performance: 160 },
];

// System architecture components
export const architectureComponents = [
  { name: 'PowerShell Script', type: 'Core', files: 1 },
  { name: 'Python Scripts', type: 'Core', files: 2 },
  { name: 'Configuration YAML', type: 'Config', files: 4 },
  { name: 'SQLite Database', type: 'Data', files: 1 },
  { name: 'Reports', type: 'Output', files: 'Multiple' },
  { name: 'Logs', type: 'Output', files: 'Daily' },
  { name: 'Backups', type: 'Storage', files: '10 max' },
];

// Statistics summary
export const summaryStats = {
  totalOptimizations: 26,
  performanceGain: '30-60%',
  memoryReduction: '35%',
  codeLines: 920,
  version: '2.2',
  compatibility: '100%',
};

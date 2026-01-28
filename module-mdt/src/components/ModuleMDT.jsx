import React, { useState, useMemo } from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar } from 'recharts';

const ModuleMDT = () => {
  const [scores, setScores] = useState({});
  const [activeTab, setActiveTab] = useState('questionnaire');

  const questions = {
    'Dépendance fournisseurs': [
      { id: 'Q1', text: "Le fournisseur principal dépasse-t-il 50 % des dépenses du système critique ?" },
      { id: 'Q2', text: "Existe-t-il un second fournisseur opérationnel (multi-sourcing) ?" },
      { id: 'Q3', text: "Les interfaces sont-elles basées sur des standards ouverts ?" },
      { id: 'Q4', text: "La solution permet-elle une extraction complète des données ?" },
      { id: 'Q5', text: "Une migration vers un autre fournisseur a-t-elle été testée ?" }
    ],
    'Dépendance opérateurs': [
      { id: 'Q6', text: "Le service critique dépend-il d'un opérateur unique (cloud, hébergeur, réseau) ?" },
      { id: 'Q7', text: "Les zones géographiques d'hébergement sont-elles maîtrisées ?" },
      { id: 'Q8', text: "Existe-t-il une architecture multi-zone / multi-région ?" },
      { id: 'Q9', text: "Les logs et opérations SOC sont-ils localisés dans une juridiction compatible ?" }
    ],
    'Dépendance Data & IA': [
      { id: 'Q10', text: "Les données critiques sont-elles stockées et traitées dans l'UE ?" },
      { id: 'Q11', text: "Les flux internationaux sont-ils documentés et contrôlés ?" },
      { id: 'Q12', text: "Les modèles IA utilisés sont-ils explicables et auditables ?" },
      { id: 'Q13', text: "L'organisation maîtrise-t-elle les jeux d'entraînement critiques ?" }
    ],
    'Dépendance contractuelle': [
      { id: 'Q14', text: "Les clauses essentielles (audit, réversibilité, SLA, changement de contrôle) sont-elles présentes ?" },
      { id: 'Q15', text: "Le fournisseur est-il soumis à des lois extraterritoriales incompatibles ?" },
      { id: 'Q16', text: "Existe-t-il un plan de sortie contractuel testé ?" },
      { id: 'Q17', text: "Les preuves de conformité sont-elles disponibles et à jour ?" }
    ],
    'Dépendance opérationnelle': [
      { id: 'Q18', text: "L'organisation peut-elle opérer le service sans le fournisseur ?" },
      { id: 'Q19', text: "Les compétences critiques sont-elles documentées et redondées ?" },
      { id: 'Q20', text: "Un plan de transfert de connaissances est-il en place ?" },
      { id: 'Q21', text: "Les équipes internes ont-elles accès aux outils d'administration ?" }
    ]
  };

  const scoreOptions = [
    { value: 0, label: '0 - Non-résilient', color: '#dc2626' },
    { value: 1, label: '1 - Documenté', color: '#f97316' },
    { value: 3, label: '3 - Déployé', color: '#eab308' },
    { value: 5, label: '5 - Contrôlé', color: '#16a34a' }
  ];

  const handleScoreChange = (questionId, value) => {
    setScores(prev => ({ ...prev, [questionId]: value }));
  };

  const calculations = useMemo(() => {
    const axeScores = {};
    let totalScore = 0;
    let totalQuestions = 0;

    Object.entries(questions).forEach(([axeName, axeQuestions]) => {
      const axeScore = axeQuestions.reduce((sum, q) => sum + (scores[q.id] || 0), 0);
      const axeMax = axeQuestions.length * 5;
      axeScores[axeName] = axeMax > 0 ? (axeScore / axeMax) * 100 : 0;
      totalScore += axeScore;
      totalQuestions += axeQuestions.length;
    });

    const scoreGlobal = totalQuestions > 0 ? (totalScore / (totalQuestions * 5)) * 100 : 0;
    const idt = 100 - scoreGlobal;

    let interpretation = '';
    let interpretationColor = '';
    if (idt < 20) {
      interpretation = 'Très faible - Organisation autonome';
      interpretationColor = '#16a34a';
    } else if (idt < 40) {
      interpretation = 'Faible - Dépendance maîtrisée';
      interpretationColor = '#84cc16';
    } else if (idt < 60) {
      interpretation = 'Modérée - Risques significatifs';
      interpretationColor = '#eab308';
    } else if (idt < 80) {
      interpretation = 'Forte - Dépendance critique';
      interpretationColor = '#f97316';
    } else {
      interpretation = 'Très forte - Risque systémique';
      interpretationColor = '#dc2626';
    }

    return { axeScores, scoreGlobal, idt, interpretation, interpretationColor };
  }, [scores]);

  const barChartData = Object.entries(calculations.axeScores).map(([axe, score]) => ({
    axe: axe.replace('Dépendance ', ''),
    'Résilience (%)': score.toFixed(1)
  }));

  const radarData = Object.entries(calculations.axeScores).map(([axe, score]) => ({
    axe: axe.replace('Dépendance ', ''),
    score: score.toFixed(1),
    fullMark: 100
  }));

  const pieData = [
    { name: 'Résilience', value: calculations.scoreGlobal },
    { name: 'Dépendance', value: calculations.idt }
  ];

  const COLORS = ['#16a34a', calculations.interpretationColor];

  const kpis = [
    { id: 'KPI-1', name: 'Dépendance fournisseur', description: 'Concentration économique et technique', question: 'Q1' },
    { id: 'KPI-2', name: 'Exposition extraterritoriale', description: 'Exposition aux lois non-UE', question: 'Q7' },
    { id: 'KPI-3', name: 'Portabilité réelle', description: 'Capacité à migrer workloads/données', question: 'Q4' },
    { id: 'KPI-4', name: 'Autonomie opérationnelle', description: 'Opération sans prestataire', question: 'Q18' },
    { id: 'KPI-5', name: 'Souveraineté data', description: 'Localisation + contrôle données', question: 'Q10' },
    { id: 'KPI-6', name: 'Diversification effective', description: 'Multi-sourcing réel', question: 'Q2' },
    { id: 'KPI-7', name: 'Dépendance contractuelle', description: 'Clauses essentielles', question: 'Q17' }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 p-6">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-xl shadow-lg p-6 mb-6">
          <h1 className="text-3xl font-bold text-indigo-900 mb-2">
            Module MDT - Mesure de la Dépendance Technologique
          </h1>
          <p className="text-gray-600">
            Indice de Résilience Numérique (IRN) v0.4 - Évaluez le niveau de dépendance technologique de votre organisation
          </p>
        </div>

        {/* Navigation Tabs */}
        <div className="bg-white rounded-xl shadow-lg mb-6">
          <div className="flex border-b">
            {['questionnaire', 'scores', 'kpi', 'synthese'].map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`flex-1 px-6 py-4 font-semibold transition-colors ${
                  activeTab === tab
                    ? 'bg-indigo-600 text-white border-b-4 border-indigo-800'
                    : 'text-gray-600 hover:bg-indigo-50'
                }`}
              >
                {tab === 'questionnaire' && 'Questionnaire'}
                {tab === 'scores' && 'Scores par Axe'}
                {tab === 'kpi' && 'KPI'}
                {tab === 'synthese' && 'Synthèse & IDT'}
              </button>
            ))}
          </div>
        </div>

        {/* Questionnaire Tab */}
        {activeTab === 'questionnaire' && (
          <div className="space-y-6">
            {Object.entries(questions).map(([axeName, axeQuestions]) => (
              <div key={axeName} className="bg-white rounded-xl shadow-lg p-6">
                <h2 className="text-2xl font-bold text-indigo-800 mb-4 border-b-2 border-indigo-200 pb-2">
                  {axeName}
                </h2>
                <div className="space-y-4">
                  {axeQuestions.map((q) => (
                    <div key={q.id} className="border-l-4 border-indigo-300 pl-4 py-2">
                      <div className="flex items-start justify-between gap-4">
                        <div className="flex-1">
                          <span className="font-semibold text-indigo-600">{q.id}:</span>
                          <span className="ml-2 text-gray-700">{q.text}</span>
                        </div>
                        <div className="flex gap-2">
                          {scoreOptions.map((option) => (
                            <button
                              key={option.value}
                              onClick={() => handleScoreChange(q.id, option.value)}
                              className={`px-4 py-2 rounded-lg font-semibold transition-all ${
                                scores[q.id] === option.value
                                  ? 'ring-4 ring-offset-2 scale-105'
                                  : 'opacity-60 hover:opacity-100'
                              }`}
                              style={{
                                backgroundColor: option.color,
                                color: 'white',
                                ringColor: option.color
                              }}
                              title={option.label}
                            >
                              {option.value}
                            </button>
                          ))}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}

            {/* Légende */}
            <div className="bg-white rounded-xl shadow-lg p-6">
              <h3 className="text-xl font-bold text-gray-800 mb-4">Échelle de notation</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {scoreOptions.map((option) => (
                  <div
                    key={option.value}
                    className="flex items-center gap-3 p-3 rounded-lg"
                    style={{ backgroundColor: `${option.color}20` }}
                  >
                    <div
                      className="w-10 h-10 rounded-full flex items-center justify-center text-white font-bold"
                      style={{ backgroundColor: option.color }}
                    >
                      {option.value}
                    </div>
                    <span className="font-semibold text-gray-700">{option.label}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Scores Tab */}
        {activeTab === 'scores' && (
          <div className="space-y-6">
            <div className="bg-white rounded-xl shadow-lg p-6">
              <h2 className="text-2xl font-bold text-indigo-800 mb-6">Scores de Résilience par Axe</h2>
              <ResponsiveContainer width="100%" height={400}>
                <BarChart data={barChartData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="axe" angle={-15} textAnchor="end" height={100} />
                  <YAxis domain={[0, 100]} />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="Résilience (%)" fill="#4f46e5" />
                </BarChart>
              </ResponsiveContainer>
            </div>

            <div className="bg-white rounded-xl shadow-lg p-6">
              <h2 className="text-2xl font-bold text-indigo-800 mb-6">Radar de Résilience</h2>
              <ResponsiveContainer width="100%" height={400}>
                <RadarChart data={radarData}>
                  <PolarGrid />
                  <PolarAngleAxis dataKey="axe" />
                  <PolarRadiusAxis domain={[0, 100]} />
                  <Radar name="Score" dataKey="score" stroke="#4f46e5" fill="#4f46e5" fillOpacity={0.6} />
                  <Tooltip />
                </RadarChart>
              </ResponsiveContainer>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(calculations.axeScores).map(([axe, score]) => (
                <div key={axe} className="bg-white rounded-xl shadow-lg p-6">
                  <h3 className="font-bold text-gray-700 mb-2">{axe}</h3>
                  <div className="text-3xl font-bold text-indigo-600">{score.toFixed(1)}%</div>
                  <div className="mt-2 bg-gray-200 rounded-full h-3">
                    <div
                      className="bg-indigo-600 h-3 rounded-full transition-all"
                      style={{ width: `${score}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* KPI Tab */}
        {activeTab === 'kpi' && (
          <div className="space-y-6">
            <div className="bg-white rounded-xl shadow-lg p-6">
              <h2 className="text-2xl font-bold text-indigo-800 mb-6">Indicateurs Clés de Performance (KPI)</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {kpis.map((kpi) => {
                  const score = scores[kpi.question] || 0;
                  const percentage = (score / 5) * 100;
                  return (
                    <div key={kpi.id} className="border-2 border-indigo-200 rounded-xl p-5 hover:shadow-lg transition-shadow">
                      <div className="flex items-start justify-between mb-3">
                        <div>
                          <h3 className="text-lg font-bold text-indigo-700">{kpi.id}</h3>
                          <p className="text-sm font-semibold text-gray-800">{kpi.name}</p>
                        </div>
                        <div className="text-2xl font-bold text-indigo-600">{percentage.toFixed(0)}%</div>
                      </div>
                      <p className="text-sm text-gray-600 mb-3">{kpi.description}</p>
                      <div className="bg-gray-200 rounded-full h-2">
                        <div
                          className="h-2 rounded-full transition-all"
                          style={{
                            width: `${percentage}%`,
                            backgroundColor: score === 5 ? '#16a34a' : score >= 3 ? '#eab308' : score >= 1 ? '#f97316' : '#dc2626'
                          }}
                        />
                      </div>
                      <p className="text-xs text-gray-500 mt-2">Basé sur {kpi.question}</p>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* Synthèse Tab */}
        {activeTab === 'synthese' && (
          <div className="space-y-6">
            {/* IDT Card */}
            <div className="bg-white rounded-xl shadow-lg p-8">
              <h2 className="text-2xl font-bold text-indigo-800 mb-6 text-center">
                Indice de Dépendance Technologique (IDT)
              </h2>
              <div className="text-center mb-6">
                <div
                  className="text-7xl font-bold mb-2"
                  style={{ color: calculations.interpretationColor }}
                >
                  {calculations.idt.toFixed(1)}
                </div>
                <div className="text-2xl font-semibold text-gray-600">/ 100</div>
              </div>
              <div
                className="text-center text-xl font-bold p-4 rounded-lg"
                style={{
                  backgroundColor: `${calculations.interpretationColor}20`,
                  color: calculations.interpretationColor
                }}
              >
                {calculations.interpretation}
              </div>
            </div>

            {/* Score Global */}
            <div className="bg-white rounded-xl shadow-lg p-8">
              <h2 className="text-2xl font-bold text-indigo-800 mb-6 text-center">
                Score Global de Résilience
              </h2>
              <div className="text-center mb-6">
                <div className="text-6xl font-bold text-green-600 mb-2">
                  {calculations.scoreGlobal.toFixed(1)}%
                </div>
              </div>
              <div className="flex justify-center">
                <ResponsiveContainer width="50%" height={300}>
                  <PieChart>
                    <Pie
                      data={pieData}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      label={({ name, value }) => `${name}: ${value.toFixed(1)}%`}
                      outerRadius={100}
                      fill="#8884d8"
                      dataKey="value"
                    >
                      {pieData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>

            {/* Échelle d'interprétation */}
            <div className="bg-white rounded-xl shadow-lg p-6">
              <h3 className="text-xl font-bold text-gray-800 mb-4">Échelle d'interprétation IDT</h3>
              <div className="space-y-3">
                {[
                  { range: '0-20', level: 'Très faible', desc: 'Organisation autonome', color: '#16a34a' },
                  { range: '21-40', level: 'Faible', desc: 'Dépendance maîtrisée', color: '#84cc16' },
                  { range: '41-60', level: 'Modérée', desc: 'Risques significatifs', color: '#eab308' },
                  { range: '61-80', level: 'Forte', desc: 'Dépendance critique', color: '#f97316' },
                  { range: '81-100', level: 'Très forte', desc: 'Risque systémique', color: '#dc2626' }
                ].map((item) => (
                  <div
                    key={item.range}
                    className="flex items-center gap-4 p-4 rounded-lg"
                    style={{ backgroundColor: `${item.color}15` }}
                  >
                    <div
                      className="w-20 text-center font-bold py-2 rounded-lg text-white"
                      style={{ backgroundColor: item.color }}
                    >
                      {item.range}
                    </div>
                    <div className="flex-1">
                      <div className="font-bold text-gray-800">{item.level}</div>
                      <div className="text-sm text-gray-600">{item.desc}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Actions recommandées */}
            <div className="bg-white rounded-xl shadow-lg p-6">
              <h3 className="text-xl font-bold text-gray-800 mb-4">Actions recommandées</h3>
              <div className="space-y-3">
                {calculations.idt > 80 && (
                  <div className="bg-red-50 border-l-4 border-red-500 p-4">
                    <p className="font-semibold text-red-800">Priorité Critique</p>
                    <p className="text-red-700">Dépendance systémique détectée. Plan d'action immédiat requis.</p>
                  </div>
                )}
                {calculations.idt > 60 && calculations.idt <= 80 && (
                  <div className="bg-orange-50 border-l-4 border-orange-500 p-4">
                    <p className="font-semibold text-orange-800">Priorité Élevée</p>
                    <p className="text-orange-700">Dépendance forte identifiée. Stratégie de diversification nécessaire.</p>
                  </div>
                )}
                {calculations.idt > 40 && calculations.idt <= 60 && (
                  <div className="bg-yellow-50 border-l-4 border-yellow-500 p-4">
                    <p className="font-semibold text-yellow-800">Priorité Moyenne</p>
                    <p className="text-yellow-700">Risques modérés. Renforcement des mesures de résilience recommandé.</p>
                  </div>
                )}
                {calculations.idt <= 40 && (
                  <div className="bg-green-50 border-l-4 border-green-500 p-4">
                    <p className="font-semibold text-green-800">Situation Satisfaisante</p>
                    <p className="text-green-700">Dépendance maîtrisée. Maintenir la vigilance et l'amélioration continue.</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Footer */}
        <div className="bg-white rounded-xl shadow-lg p-6 mt-6 text-center text-gray-600">
          <p className="font-semibold">Module MDT - IRN v0.4</p>
          <p className="text-sm">Indice de Résilience Numérique | Mesure de la Dépendance Technologique</p>
          <p className="text-xs mt-2">© 2026 - Reprenez votre destin numérique en main</p>
        </div>
      </div>
    </div>
  );
};

export default ModuleMDT;

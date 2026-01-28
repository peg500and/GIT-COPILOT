export default function StatCard({ title, value, subtitle, icon: Icon, gradient }) {
  return (
    <div className={`dashboard-card rounded-2xl p-6 text-white shadow-lg ${gradient}`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm opacity-80 mb-1">{title}</p>
          <p className="text-3xl font-bold">{value}</p>
          {subtitle && <p className="text-sm opacity-70 mt-1">{subtitle}</p>}
        </div>
        {Icon && (
          <div className="p-3 bg-white/20 rounded-xl">
            <Icon className="h-8 w-8" />
          </div>
        )}
      </div>
    </div>
  );
}

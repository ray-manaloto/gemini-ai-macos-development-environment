import { useState } from "react";
import useQuickActions from "../hooks/useQuickActions";

export default function QuickActionsBar() {
  const { runValidate, runDoctor, runUpdateAll, runDashboard, running } = useQuickActions();
  const [lastAction, setLastAction] = useState<string | null>(null);

  const handleAction = async (action: () => Promise<void>, name: string) => {
    setLastAction(name);
    await action();
    setLastAction(null);
  };

  const actions = [
    {
      id: "validate",
      label: "Validate",
      icon: "✓",
      onClick: () => handleAction(runValidate, "validate"),
      variant: "success" as const,
    },
    {
      id: "doctor",
      label: "Doctor",
      icon: "⚕",
      onClick: () => handleAction(runDoctor, "doctor"),
      variant: "primary" as const,
    },
    {
      id: "update",
      label: "Update All",
      icon: "↻",
      onClick: () => handleAction(runUpdateAll, "update"),
      variant: "warning" as const,
    },
    {
      id: "dashboard",
      label: "Dashboard",
      icon: "◧",
      onClick: () => handleAction(runDashboard, "dashboard"),
      variant: "secondary" as const,
    },
  ];

  return (
    <div className="quick-actions-bar">
      <div className="quick-actions-grid">
        {actions.map((action, index) => (
          <button
            key={action.id}
            className={`quick-action-btn ${action.variant}`}
            onClick={action.onClick}
            disabled={running}
            style={{
              animationDelay: `${index * 50}ms`,
            }}
          >
            <span className="quick-action-icon">{action.icon}</span>
            <span className="quick-action-label">{action.label}</span>
            {running && lastAction === action.id && (
              <span className="quick-action-spinner" />
            )}
          </button>
        ))}
      </div>
    </div>
  );
}

import usePackageManagers from "../hooks/usePackageManagers";

export default function PackageManagersStatus() {
  const { managers, loading, actionRunning, runDoctor, updateManager } = usePackageManagers();

  if (loading && managers.length === 0) {
    return (
      <section className="package-managers-section">
        <div className="package-managers-loading">Loading package managers...</div>
      </section>
    );
  }

  return (
    <section className="package-managers-section">
      <div className="package-managers-grid">
        {managers.map((manager) => {
          const isRunning = actionRunning === manager.name;
          const statusClass = `status-${manager.status}`;
          
          return (
            <div key={manager.name} className={`package-manager-card ${statusClass}`}>
              <div className="package-manager-header">
                <span className="package-manager-emoji">{manager.emoji}</span>
                <div className="package-manager-info">
                  <div className="package-manager-name">{manager.displayName}</div>
                  <div className="package-manager-version">{manager.version}</div>
                </div>
              </div>
              
              <div className="package-manager-status">
                <span className={`status-indicator ${statusClass}`} />
                <span className="status-text">
                  {manager.status === "healthy" && "OK"}
                  {manager.status === "warning" && "Warning"}
                  {manager.status === "error" && "Error"}
                  {manager.status === "unknown" && "Unknown"}
                </span>
              </div>

              {manager.message && (
                <div className="package-manager-message">{manager.message}</div>
              )}

              <div className="package-manager-actions">
                {manager.name === "mise" && (
                  <button
                    className="pm-action-button"
                    onClick={runDoctor}
                    disabled={actionRunning === "mise-doctor"}
                    type="button"
                  >
                    {actionRunning === "mise-doctor" ? <span className="spinner" /> : "Doctor"}
                  </button>
                )}
                <button
                  className="pm-action-button primary"
                  onClick={() => updateManager(manager.name)}
                  disabled={actionRunning === `${manager.name}-update`}
                  type="button"
                >
                  {actionRunning === `${manager.name}-update` ? <span className="spinner" /> : "Update"}
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}

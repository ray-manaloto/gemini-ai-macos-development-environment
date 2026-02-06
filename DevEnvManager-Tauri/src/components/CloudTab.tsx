import useCloudStatus from "../hooks/useCloudStatus";

export default function CloudTab() {
  const { skyPilot, aws, loading, actionRunning, clusterLogs, stopCluster, sshCluster, getClusterLogs, clearLogs } = useCloudStatus();

  if (loading && !skyPilot && !aws) {
    return <div className="empty-state">Loading cloud information...</div>;
  }

  const hasAnyClusters = skyPilot && skyPilot.clusters.length > 0;
  const hasAwsInfo = aws && aws.status === "connected";

  if (!hasAnyClusters && !hasAwsInfo) {
    return (
      <div className="empty-state">
        No cloud resources detected. Launch a SkyPilot agent to get started.
      </div>
    );
  }

  return (
    <div className="panel">
      {/* SkyPilot Clusters */}
      {skyPilot && skyPilot.clusters.length > 0 && (
        <div className="cloud-tab-section">
          <div className="panel-header">
            <h2>☁️ SkyPilot Clusters</h2>
            <span className="cloud-count-badge">{skyPilot.clusters.length}</span>
          </div>
          <div className="panel-body">
            {skyPilot.clusters.map((cluster) => {
              const isStopRunning = actionRunning === `cluster-stop-${cluster.name}`;
              const isSshRunning = actionRunning === `cluster-ssh-${cluster.name}`;
              const isLogsRunning = actionRunning === `cluster-logs-${cluster.name}`;
              
              return (
                <div key={cluster.name} className="list-row cloud-cluster-row">
                  <div className="list-main">
                    <div className="list-title">
                      <span className="cluster-status-icon">
                        {cluster.status === "UP" ? "🟢" : cluster.status === "STOPPED" ? "🔴" : "🟡"}
                      </span>
                      {cluster.name}
                    </div>
                    <div className="list-subtitle">
                      {cluster.resources}
                      {cluster.region && ` • ${cluster.region}`}
                    </div>
                    <div className="cluster-status-badge">
                      Status: <strong>{cluster.status}</strong>
                    </div>
                  </div>
                  <div className="list-actions">
                    <button
                      className="action-button"
                      onClick={() => sshCluster(cluster.name)}
                      disabled={isSshRunning || cluster.status !== "UP"}
                      type="button"
                    >
                      {isSshRunning ? <span className="spinner" /> : "SSH"}
                    </button>
                    <button
                      className="action-button"
                      onClick={() => getClusterLogs(cluster.name)}
                      disabled={isLogsRunning}
                      type="button"
                    >
                      {isLogsRunning ? <span className="spinner" /> : "Logs"}
                    </button>
                    <button
                      className="action-button danger"
                      onClick={() => stopCluster(cluster.name)}
                      disabled={isStopRunning || cluster.status === "STOPPED"}
                      type="button"
                    >
                      {isStopRunning ? <span className="spinner" /> : "Stop"}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* AWS Info */}
      {aws && aws.status === "connected" && (
        <div className="cloud-tab-section">
          <div className="panel-header">
            <h2>🔶 AWS Account</h2>
          </div>
          <div className="panel-body">
            <div className="aws-info-grid">
              <div className="aws-info-item">
                <div className="aws-info-label">Account ID</div>
                <div className="aws-info-value">{aws.accountId || "Unknown"}</div>
              </div>
              <div className="aws-info-item">
                <div className="aws-info-label">Region</div>
                <div className="aws-info-value">{aws.region || "Not set"}</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Empty state for SkyPilot */}
      {skyPilot && skyPilot.clusters.length === 0 && skyPilot.status !== "notinstalled" && (
        <div className="empty-state">
          No active SkyPilot clusters. Use the Launch button to start an agent.
        </div>
      )}

      {clusterLogs && (
        <div className="logs-panel">
          <div className="logs-header">
            <h3>Cluster Logs</h3>
            <button className="logs-close" onClick={clearLogs} type="button">×</button>
          </div>
          <pre className="logs-content">{clusterLogs}</pre>
        </div>
      )}
    </div>
  );
}

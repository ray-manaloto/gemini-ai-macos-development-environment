import useCloudStatus from "../hooks/useCloudStatus";

export default function CloudStatus() {
  const { skyPilot, aws, loading, actionRunning, launchAgent, stopAgents } = useCloudStatus();

  if (loading && !skyPilot && !aws) {
    return (
      <section className="cloud-section">
        <div className="cloud-loading">Loading cloud status...</div>
      </section>
    );
  }

  const getStatusClass = (status: string) => {
    switch (status) {
      case "connected":
        return "status-connected";
      case "disconnected":
        return "status-disconnected";
      case "notinstalled":
        return "status-notinstalled";
      default:
        return "status-unknown";
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case "connected":
        return "Connected";
      case "disconnected":
        return "Disconnected";
      case "notinstalled":
        return "Not Installed";
      default:
        return "Unknown";
    }
  };

  const getStatusIndicator = (status: string) => {
    switch (status) {
      case "connected":
        return "🟢";
      case "disconnected":
        return "🟡";
      case "notinstalled":
        return "🔴";
      default:
        return "⚪";
    }
  };

  return (
    <section className="cloud-section">
      <h2 className="cloud-section-title">☁️ Cloud Status</h2>
      <div className="cloud-grid">
        {/* SkyPilot Card */}
        {skyPilot && (
          <div className={`cloud-card ${getStatusClass(skyPilot.status)}`}>
            <div className="cloud-header">
              <span className="cloud-icon">☁️</span>
              <div className="cloud-info">
                <div className="cloud-name">SkyPilot</div>
                <div className="cloud-detail">
                  {skyPilot.clusterCount > 0
                    ? `${skyPilot.clusterCount} agent${skyPilot.clusterCount > 1 ? "s" : ""} UP`
                    : skyPilot.status === "notinstalled"
                    ? "Not installed"
                    : "No agents"}
                </div>
              </div>
            </div>

            <div className="cloud-status">
              <span className="cloud-status-indicator">{getStatusIndicator(skyPilot.status)}</span>
              <span className="cloud-status-text">{getStatusText(skyPilot.status)}</span>
            </div>

            {skyPilot.message && (
              <div className="cloud-message">{skyPilot.message}</div>
            )}

            {skyPilot.status !== "notinstalled" && (
              <div className="cloud-actions">
                <button
                  className="cloud-action-button primary"
                  onClick={launchAgent}
                  disabled={actionRunning === "skypilot-launch"}
                  type="button"
                >
                  {actionRunning === "skypilot-launch" ? <span className="spinner" /> : "Launch"}
                </button>
                <button
                  className="cloud-action-button danger"
                  onClick={stopAgents}
                  disabled={actionRunning === "skypilot-stop" || skyPilot.clusterCount === 0}
                  type="button"
                >
                  {actionRunning === "skypilot-stop" ? <span className="spinner" /> : "Stop"}
                </button>
              </div>
            )}
          </div>
        )}

        {/* AWS Card */}
        {aws && (
          <div className={`cloud-card ${getStatusClass(aws.status)}`}>
            <div className="cloud-header">
              <span className="cloud-icon">🔶</span>
              <div className="cloud-info">
                <div className="cloud-name">AWS</div>
                <div className="cloud-detail">
                  {aws.status === "connected" && aws.accountId
                    ? `Account: ${aws.accountId.slice(-4)}`
                    : aws.status === "notinstalled"
                    ? "Not installed"
                    : "Not configured"}
                </div>
              </div>
            </div>

            <div className="cloud-status">
              <span className="cloud-status-indicator">{getStatusIndicator(aws.status)}</span>
              <span className="cloud-status-text">{getStatusText(aws.status)}</span>
            </div>

            {aws.region && (
              <div className="cloud-region">Region: {aws.region}</div>
            )}

            {aws.message && (
              <div className="cloud-message">{aws.message}</div>
            )}

            {aws.status !== "notinstalled" && (
              <div className="cloud-actions">
                <button
                  className="cloud-action-button"
                  onClick={() => {
                    // Open terminal with aws configure
                    window.open("terminal://aws configure", "_blank");
                  }}
                  type="button"
                >
                  Configure
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </section>
  );
}

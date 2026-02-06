import useMiseTools from "../hooks/useMiseTools";
import useBrewServices from "../hooks/useBrewServices";
import useContainers from "../hooks/useContainers";
import useCloudStatus from "../hooks/useCloudStatus";

type HealthStatus = "healthy" | "warning" | "error";

export default function StatusHeader() {
  const { tools } = useMiseTools();
  const { services } = useBrewServices();
  const { containers } = useContainers();
  const { skyPilot } = useCloudStatus();

  // Calculate overall health
  const installedTools = tools.filter((t) => t.installed).length;
  const missingTools = tools.filter((t) => !t.installed).length;
  const runningServices = services.filter((s) => s.status === "started").length;
  const runningContainers = containers.filter((c) => c.state === "running").length;
  const activeClusters = skyPilot?.clusterCount ?? 0;

  // Determine health status
  let health: HealthStatus = "healthy";
  if (missingTools > 0) {
    health = "warning";
  }
  if (services.some((s) => s.status === "error")) {
    health = "error";
  }

  const healthColors = {
    healthy: "var(--success)",
    warning: "var(--warning)",
    error: "var(--danger)",
  };

  return (
    <div className="status-header">
      <div className="status-health">
        <div
          className="status-health-indicator"
          style={{ background: healthColors[health] }}
        />
        <span className="status-health-label">
          {health === "healthy" && "All Systems Operational"}
          {health === "warning" && "Minor Issues Detected"}
          {health === "error" && "Critical Issues"}
        </span>
      </div>
      <div className="status-metrics">
        <div className="status-metric">
          <span className="status-metric-value">{installedTools}</span>
          <span className="status-metric-label">Tools</span>
        </div>
        <div className="status-metric-divider" />
        <div className="status-metric">
          <span className="status-metric-value">{runningServices}</span>
          <span className="status-metric-label">Services</span>
        </div>
        <div className="status-metric-divider" />
        <div className="status-metric">
          <span className="status-metric-value">{runningContainers}</span>
          <span className="status-metric-label">Containers</span>
        </div>
        <div className="status-metric-divider" />
        <div className="status-metric">
          <span className="status-metric-value">{activeClusters}</span>
          <span className="status-metric-label">Clusters</span>
        </div>
      </div>
    </div>
  );
}

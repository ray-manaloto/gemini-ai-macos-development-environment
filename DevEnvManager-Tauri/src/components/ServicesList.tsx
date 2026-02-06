import ActionButton from "./ActionButton";
import StatusBadge from "./StatusBadge";
import useBrewServices from "../hooks/useBrewServices";

export default function ServicesList() {
  const { services, loading, refresh, runAction, actionRunning } = useBrewServices();

  return (
    <div className="panel">
      <div className="panel-header">
        <h2>Homebrew Services</h2>
        <ActionButton label="Refresh" onClick={refresh} loading={loading} />
      </div>
      <div className="panel-body">
        {services.length === 0 && !loading ? (
          <div className="empty-state">No services found.</div>
        ) : (
          services.map((service) => {
            const statusMap: Record<string, "ok" | "warning" | "error" | "unknown"> = {
              started: "ok",
              stopped: "error",
              error: "error",
              none: "warning",
              unknown: "unknown"
            };
            return (
              <div key={service.name} className="list-row">
                <div className="list-main">
                  <div className="list-title">{service.name}</div>
                  <div className="list-subtitle">{service.status}</div>
                </div>
                <StatusBadge status={statusMap[service.status] ?? "unknown"} />
                <div className="list-actions">
                  <ActionButton
                    label="Start"
                    onClick={() => runAction("start", service.name)}
                    loading={actionRunning === service.name}
                    disabled={service.status === "started"}
                  />
                  <ActionButton
                    label="Stop"
                    onClick={() => runAction("stop", service.name)}
                    loading={actionRunning === service.name}
                    disabled={service.status === "stopped"}
                    variant="danger"
                  />
                  <ActionButton
                    label="Restart"
                    onClick={() => runAction("restart", service.name)}
                    loading={actionRunning === service.name}
                  />
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}

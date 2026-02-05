import ActionButton from "./ActionButton";
import StatusBadge from "./StatusBadge";
import useContainers from "../hooks/useContainers";

export default function ContainersList() {
  const { containers, loading, refresh, runAction, actionRunning } = useContainers();

  return (
    <div className="panel">
      <div className="panel-header">
        <h2>OrbStack Containers</h2>
        <ActionButton label="Refresh" onClick={refresh} loading={loading} />
      </div>
      <div className="panel-body">
        {containers.length === 0 && !loading ? (
          <div className="empty-state">No containers found.</div>
        ) : (
          containers.map((container) => {
            const status = container.state === "running" ? "ok" : "warning";
            return (
              <div key={container.id} className="list-row">
                <div className="list-main">
                  <div className="list-title">{container.name}</div>
                  <div className="list-subtitle">{container.state}</div>
                </div>
                <StatusBadge status={status} />
                <div className="list-actions">
                  <ActionButton
                    label="Start"
                    onClick={() => runAction("start", container.name)}
                    loading={actionRunning === container.name}
                    disabled={container.state === "running"}
                  />
                  <ActionButton
                    label="Stop"
                    onClick={() => runAction("stop", container.name)}
                    loading={actionRunning === container.name}
                    disabled={container.state !== "running"}
                    variant="danger"
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

import ActionButton from "./ActionButton";
import StatusBadge from "./StatusBadge";
import useContainers from "../hooks/useContainers";

export default function ContainersList() {
  const { containers, loading, refresh, runAction, actionRunning, logs, clearLogs } = useContainers();

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
            const isRunning = container.state === "running";
            return (
              <div key={container.id} className="list-row container-row">
                <div className="list-main">
                  <div className="list-title">{container.name}</div>
                  <div className="list-subtitle">{container.state}</div>
                </div>
                <StatusBadge status={status} />
                <div className="list-actions container-actions">
                  <ActionButton
                    label="Start"
                    onClick={() => runAction("start", container.name)}
                    loading={actionRunning === `${container.name}-start`}
                    disabled={isRunning}
                  />
                  <ActionButton
                    label="Stop"
                    onClick={() => runAction("stop", container.name)}
                    loading={actionRunning === `${container.name}-stop`}
                    disabled={!isRunning}
                    variant="danger"
                  />
                  <ActionButton
                    label="Restart"
                    onClick={() => runAction("restart", container.name)}
                    loading={actionRunning === `${container.name}-restart`}
                    disabled={!isRunning}
                  />
                  <ActionButton
                    label="Shell"
                    onClick={() => runAction("shell", container.name)}
                    loading={actionRunning === `${container.name}-shell`}
                    disabled={!isRunning}
                  />
                  <ActionButton
                    label="Logs"
                    onClick={() => runAction("logs", container.name)}
                    loading={actionRunning === `${container.name}-logs`}
                  />
                </div>
              </div>
            );
          })
        )}
      </div>
      {logs && (
        <div className="logs-panel">
          <div className="logs-header">
            <h3>Container Logs</h3>
            <button className="logs-close" onClick={clearLogs} type="button">×</button>
          </div>
          <pre className="logs-content">{logs}</pre>
        </div>
      )}
    </div>
  );
}

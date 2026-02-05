import ActionButton from "./ActionButton";
import usePorts from "../hooks/usePorts";

export default function PortsList() {
  const { ports, loading, refresh } = usePorts();

  return (
    <div className="panel">
      <div className="panel-header">
        <h2>Active Ports</h2>
        <ActionButton label="Refresh" onClick={refresh} loading={loading} />
      </div>
      <div className="panel-body">
        {ports.length === 0 && !loading ? (
          <div className="empty-state">No active ports.</div>
        ) : (
          ports.map((port) => (
            <div key={`${port.process}-${port.port}`} className="list-row">
              <div className="list-main">
                <div className="list-title">
                  {port.local_address}:{port.port}
                </div>
                <div className="list-subtitle">
                  {port.process} (PID {port.pid})
                </div>
              </div>
              <div className="port-protocol">{port.protocol}</div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

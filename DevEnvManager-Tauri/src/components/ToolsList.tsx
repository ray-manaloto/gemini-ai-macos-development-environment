import ActionButton from "./ActionButton";
import StatusBadge from "./StatusBadge";
import useMiseTools from "../hooks/useMiseTools";

export default function ToolsList() {
  const {
    tools,
    loading,
    refresh,
    installTool,
    updateTool,
    actionRunning
  } = useMiseTools();

  return (
    <div className="panel">
      <div className="panel-header">
        <h2>Mise Tools</h2>
        <ActionButton
          label="Refresh"
          onClick={refresh}
          loading={loading}
          variant="secondary"
        />
      </div>
      <div className="panel-body">
        {tools.length === 0 && !loading ? (
          <div className="empty-state">No tools found.</div>
        ) : (
          tools.map((tool) => {
            const status = tool.installed ? "ok" : "warning";
            return (
              <div key={`${tool.name}-${tool.version}`} className="list-row">
                <div className="list-main">
                  <div className="list-title">{tool.name}</div>
                  <div className="list-subtitle">{tool.version}</div>
                </div>
                <StatusBadge
                  status={status}
                  label={tool.installed ? "Installed" : "Missing"}
                />
                <div className="list-actions">
                  {!tool.installed ? (
                    <ActionButton
                      label="Install"
                      onClick={() => installTool(tool.name)}
                      loading={actionRunning === tool.name}
                      variant="primary"
                    />
                  ) : (
                    <ActionButton
                      label="Update"
                      onClick={() => updateTool(tool.name)}
                      loading={actionRunning === tool.name}
                    />
                  )}
                  <ActionButton
                    label="Remove"
                    onClick={() => Promise.resolve()}
                    disabled
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

type StatusBadgeProps = {
  status: "ok" | "warning" | "error" | "unknown";
  label?: string;
};

export default function StatusBadge({ status, label }: StatusBadgeProps) {
  return (
    <span className={`status-badge ${status}`}>
      <span className="status-dot" />
      {label ? <span className="status-label">{label}</span> : null}
    </span>
  );
}

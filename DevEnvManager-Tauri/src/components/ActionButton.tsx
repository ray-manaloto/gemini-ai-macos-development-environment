import { ReactNode } from "react";

type ActionButtonProps = {
  label: string;
  onClick: () => Promise<void> | void;
  loading?: boolean;
  disabled?: boolean;
  variant?: "primary" | "secondary" | "danger";
  icon?: ReactNode;
};

export default function ActionButton({
  label,
  onClick,
  loading = false,
  disabled = false,
  variant = "secondary",
  icon
}: ActionButtonProps) {
  const classes = ["action-button", variant, loading ? "loading" : ""]
    .filter(Boolean)
    .join(" ");

  return (
    <button
      className={classes}
      disabled={disabled || loading}
      onClick={onClick}
      type="button"
    >
      {loading ? <span className="spinner" /> : icon}
      <span>{label}</span>
    </button>
  );
}

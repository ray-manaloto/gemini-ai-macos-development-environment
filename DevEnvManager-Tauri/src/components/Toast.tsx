import { useEffect, useState } from "react";
import type { ToastType } from "../contexts/ToastContext";

interface ToastProps {
  id: string;
  type: ToastType;
  title: string;
  message?: string;
  progress?: number;
  duration: number | null;
  onRemove: (id: string) => void;
  index: number;
}

const TOAST_ICONS: Record<ToastType, string> = {
  success: "✓",
  error: "✕",
  warning: "⚠",
  info: "ℹ",
  progress: "⟳",
};

export default function Toast({
  id,
  type,
  title,
  message,
  progress = 0,
  duration,
  onRemove,
  index,
}: ToastProps) {
  const [isExiting, setIsExiting] = useState(false);
  const [remainingTime, setRemainingTime] = useState(duration);

  useEffect(() => {
    if (duration === null) return;

    const interval = setInterval(() => {
      setRemainingTime((prev) => {
        if (prev === null || prev <= 100) return prev;
        return prev - 100;
      });
    }, 100);

    return () => clearInterval(interval);
  }, [duration]);

  const handleClose = () => {
    setIsExiting(true);
    setTimeout(() => {
      onRemove(id);
    }, 300); // Match animation duration
  };

  const progressPercent = type === "progress" ? progress : 
    duration !== null && remainingTime !== null 
      ? (remainingTime / duration) * 100 
      : 0;

  return (
    <div
      className={`toast toast-${type} ${isExiting ? "toast-exit" : ""}`}
      style={{
        animationDelay: `${index * 50}ms`,
      }}
    >
      <div className="toast-scan-line" />
      
      <div className="toast-content">
        <div className="toast-header">
          <div className="toast-icon-wrapper">
            <span className="toast-icon">{TOAST_ICONS[type]}</span>
          </div>
          <div className="toast-text">
            <div className="toast-title">{title}</div>
            {message && <div className="toast-message">{message}</div>}
          </div>
          <button
            className="toast-close"
            onClick={handleClose}
            type="button"
            aria-label="Close notification"
          >
            ×
          </button>
        </div>

        {type === "progress" && (
          <div className="toast-progress-bar">
            <div
              className="toast-progress-fill"
              style={{ width: `${progress}%` }}
            />
          </div>
        )}

        {type !== "progress" && duration !== null && (
          <div className="toast-timer-bar">
            <div
              className="toast-timer-fill"
              style={{ width: `${progressPercent}%` }}
            />
          </div>
        )}
      </div>
    </div>
  );
}

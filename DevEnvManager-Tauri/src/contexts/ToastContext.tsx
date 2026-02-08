import { createContext, useContext, useState, useCallback, ReactNode } from "react";

export type ToastType = "success" | "error" | "warning" | "info" | "progress";

export interface ToastConfig {
  id?: string;
  type: ToastType;
  title: string;
  message?: string;
  duration?: number;
  progress?: number;
}

interface Toast extends Required<Omit<ToastConfig, "duration">> {
  duration: number | null;
}

interface ToastContextValue {
  toasts: Toast[];
  success: (title: string, message?: string) => void;
  error: (title: string, message?: string) => void;
  warning: (title: string, message?: string) => void;
  info: (title: string, message?: string) => void;
  progress: (title: string, percent?: number) => string;
  updateProgress: (id: string, percent: number, message?: string) => void;
  addToast: (toast: ToastConfig) => string;
  removeToast: (id: string) => void;
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

const MAX_TOASTS = 5;

const DEFAULT_DURATIONS: Record<ToastType, number | null> = {
  success: 3000,
  error: 5000,
  warning: 4000,
  info: 3000,
  progress: null, // Never auto-dismiss
};

function generateId(): string {
  return `toast-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  }, []);

  const addToast = useCallback(
    (config: ToastConfig): string => {
      const id = config.id || generateId();
      const duration = config.duration !== undefined 
        ? config.duration 
        : DEFAULT_DURATIONS[config.type];

      const newToast: Toast = {
        id,
        type: config.type,
        title: config.title,
        message: config.message || "",
        progress: config.progress || 0,
        duration,
      };

      setToasts((prev) => {
        const updated = [...prev, newToast];
        // Keep only the last MAX_TOASTS toasts
        if (updated.length > MAX_TOASTS) {
          return updated.slice(updated.length - MAX_TOASTS);
        }
        return updated;
      });

      // Auto-dismiss if duration is set
      if (duration !== null && duration > 0) {
        setTimeout(() => {
          removeToast(id);
        }, duration);
      }

      return id;
    },
    [removeToast]
  );

  const success = useCallback(
    (title: string, message?: string) => {
      addToast({ type: "success", title, message });
    },
    [addToast]
  );

  const error = useCallback(
    (title: string, message?: string) => {
      addToast({ type: "error", title, message });
    },
    [addToast]
  );

  const warning = useCallback(
    (title: string, message?: string) => {
      addToast({ type: "warning", title, message });
    },
    [addToast]
  );

  const info = useCallback(
    (title: string, message?: string) => {
      addToast({ type: "info", title, message });
    },
    [addToast]
  );

  const progress = useCallback(
    (title: string, percent: number = 0): string => {
      return addToast({ type: "progress", title, progress: percent });
    },
    [addToast]
  );

  const updateProgress = useCallback(
    (id: string, percent: number, message?: string) => {
      setToasts((prev) =>
        prev.map((toast) =>
          toast.id === id
            ? { ...toast, progress: percent, message: message || toast.message }
            : toast
        )
      );
    },
    []
  );

  const value: ToastContextValue = {
    toasts,
    success,
    error,
    warning,
    info,
    progress,
    updateProgress,
    addToast,
    removeToast,
  };

  return <ToastContext.Provider value={value}>{children}</ToastContext.Provider>;
}

export function useToast(): ToastContextValue {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToast must be used within a ToastProvider");
  }
  return context;
}

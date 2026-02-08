import { useToast } from "../contexts/ToastContext";
import Toast from "./Toast";

export default function ToastContainer() {
  const { toasts, removeToast } = useToast();

  if (toasts.length === 0) return null;

  return (
    <div className="toast-container">
      {toasts.map((toast, index) => (
        <Toast
          key={toast.id}
          id={toast.id}
          type={toast.type}
          title={toast.title}
          message={toast.message}
          progress={toast.progress}
          duration={toast.duration}
          onRemove={removeToast}
          index={index}
        />
      ))}
    </div>
  );
}

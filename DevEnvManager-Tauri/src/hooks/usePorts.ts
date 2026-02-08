import { useCallback, useEffect, useRef, useState } from "react";
import { ActivePort, listActivePorts, killPort as killPortApi } from "../lib/tauri";
import { useToast } from "../contexts/ToastContext";

type UsePortsResult = {
  ports: ActivePort[];
  loading: boolean;
  actionRunning?: number;
  refresh: () => Promise<void>;
  killPort: (pid: number) => Promise<void>;
};

export default function usePorts(refreshMs = 60000): UsePortsResult {
   const [ports, setPorts] = useState<ActivePort[]>([]);
   const [loading, setLoading] = useState(false);
   const [actionRunning, setActionRunning] = useState<number | undefined>(undefined);
   const refreshInFlight = useRef(false);
   const toast = useToast();

  const refresh = useCallback(async () => {
    if (refreshInFlight.current) return;
    refreshInFlight.current = true;
    setLoading(true);
    try {
      const result = await listActivePorts();
      setPorts(result);
    } finally {
      setLoading(false);
      refreshInFlight.current = false;
    }
  }, []);

   const killPort = useCallback(async (pid: number) => {
     setActionRunning(pid);
     try {
       await killPortApi(pid);
       await refresh();
       toast.success("Process killed", `PID ${pid} has been terminated`);
     } catch (error) {
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error(`Failed to kill process ${pid}`, message);
       console.error(`Failed to kill process ${pid}:`, error);
     } finally {
       setActionRunning(undefined);
     }
   }, [refresh, toast]);

  useEffect(() => {
    refresh();
    const interval = setInterval(() => {
      refresh();
    }, refreshMs);
    return () => clearInterval(interval);
  }, [refresh, refreshMs]);

  return { ports, loading, actionRunning, refresh, killPort };
}

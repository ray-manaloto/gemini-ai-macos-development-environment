import { useCallback, useEffect, useRef, useState } from "react";
import { ActivePort, listActivePorts } from "../lib/tauri";

type UsePortsResult = {
  ports: ActivePort[];
  loading: boolean;
  refresh: () => Promise<void>;
};

export default function usePorts(refreshMs = 60000): UsePortsResult {
  const [ports, setPorts] = useState<ActivePort[]>([]);
  const [loading, setLoading] = useState(false);
  const refreshInFlight = useRef(false);

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

  useEffect(() => {
    refresh();
    const interval = setInterval(() => {
      refresh();
    }, refreshMs);
    return () => clearInterval(interval);
  }, [refresh, refreshMs]);

  return { ports, loading, refresh };
}

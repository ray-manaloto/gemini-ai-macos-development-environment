import { useCallback, useEffect, useState } from "react";
import { ActivePort, listActivePorts } from "../lib/tauri";

type UsePortsResult = {
  ports: ActivePort[];
  loading: boolean;
  refresh: () => Promise<void>;
};

export default function usePorts(refreshMs = 60000): UsePortsResult {
  const [ports, setPorts] = useState<ActivePort[]>([]);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const result = await listActivePorts();
      setPorts(result);
    } finally {
      setLoading(false);
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

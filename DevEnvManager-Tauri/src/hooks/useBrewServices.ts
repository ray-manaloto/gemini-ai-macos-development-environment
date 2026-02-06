import { useCallback, useEffect, useRef, useState } from "react";
import {
  BrewService,
  listBrewServices,
  restartService,
  startService,
  stopService
} from "../lib/tauri";

type BrewAction = "start" | "stop" | "restart";

type UseBrewServicesResult = {
  services: BrewService[];
  loading: boolean;
  actionRunning?: string;
  refresh: () => Promise<void>;
  runAction: (action: BrewAction, name: string) => Promise<void>;
};

export default function useBrewServices(refreshMs = 60000): UseBrewServicesResult {
  const [services, setServices] = useState<BrewService[]>([]);
  const [loading, setLoading] = useState(false);
  const [actionRunning, setActionRunning] = useState<string | undefined>(undefined);
  const refreshInFlight = useRef(false);

  const refresh = useCallback(async () => {
    if (refreshInFlight.current) return;
    refreshInFlight.current = true;
    setLoading(true);
    try {
      const result = await listBrewServices();
      setServices(result);
    } finally {
      setLoading(false);
      refreshInFlight.current = false;
    }
  }, []);

  const runAction = useCallback(
    async (action: BrewAction, name: string) => {
      setActionRunning(name);
      try {
        if (action === "start") {
          await startService(name);
        } else if (action === "stop") {
          await stopService(name);
        } else {
          await restartService(name);
        }
        await refresh();
      } finally {
        setActionRunning(undefined);
      }
    },
    [refresh]
  );

  useEffect(() => {
    refresh();
    const interval = setInterval(() => {
      refresh();
    }, refreshMs);
    return () => clearInterval(interval);
  }, [refresh, refreshMs]);

  return { services, loading, actionRunning, refresh, runAction };
}

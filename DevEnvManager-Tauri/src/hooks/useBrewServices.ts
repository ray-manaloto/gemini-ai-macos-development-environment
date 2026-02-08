import { useCallback, useEffect, useRef, useState } from "react";
import {
   BrewService,
   listBrewServices,
   restartService,
   startService,
   stopService
} from "../lib/tauri";
import { useToast } from "../contexts/ToastContext";

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
   const toast = useToast();

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
           toast.success("Service started", `${name} is now running`);
         } else if (action === "stop") {
           await stopService(name);
           toast.success("Service stopped", `${name} has been stopped`);
         } else {
           await restartService(name);
           toast.success("Service restarted", `${name} has been restarted`);
         }
         await refresh();
       } catch (error) {
         const message = error instanceof Error ? error.message : "Unknown error occurred";
         toast.error(`Failed to ${action} ${name}`, message);
         console.error(`Failed to ${action} service ${name}:`, error);
       } finally {
         setActionRunning(undefined);
       }
     },
     [refresh, toast]
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

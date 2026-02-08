import { useCallback, useEffect, useRef, useState } from "react";
import {
   Container,
   listContainers,
   startContainer,
   stopContainer,
   restartContainer,
   shellContainer,
   logsContainer
} from "../lib/tauri";
import { useToast } from "../contexts/ToastContext";

type ContainerAction = "start" | "stop" | "restart" | "shell" | "logs";

type UseContainersResult = {
  containers: Container[];
  loading: boolean;
  actionRunning?: string;
  logs?: string;
  refresh: () => Promise<void>;
  runAction: (action: ContainerAction, name: string) => Promise<void>;
  clearLogs: () => void;
};

export default function useContainers(refreshMs = 60000): UseContainersResult {
   const [containers, setContainers] = useState<Container[]>([]);
   const [loading, setLoading] = useState(false);
   const [actionRunning, setActionRunning] = useState<string | undefined>(undefined);
   const [logs, setLogs] = useState<string | undefined>(undefined);
   const refreshInFlight = useRef(false);
   const toast = useToast();

  const refresh = useCallback(async () => {
    if (refreshInFlight.current) return;
    refreshInFlight.current = true;
    setLoading(true);
    try {
      const result = await listContainers();
      setContainers(result);
    } finally {
      setLoading(false);
      refreshInFlight.current = false;
    }
  }, []);

  const clearLogs = useCallback(() => {
    setLogs(undefined);
  }, []);

   const runAction = useCallback(
     async (action: ContainerAction, name: string) => {
       setActionRunning(`${name}-${action}`);
       try {
         switch (action) {
           case "start":
             await startContainer(name);
             toast.success("Container started", `${name} is now running`);
             break;
           case "stop":
             await stopContainer(name);
             toast.success("Container stopped", `${name} has been stopped`);
             break;
           case "restart":
             await restartContainer(name);
             toast.success("Container restarted", `${name} has been restarted`);
             break;
           case "shell":
             toast.info("Opening shell...", `Connecting to ${name}`);
             await shellContainer(name);
             break;
           case "logs":
             toast.info("Fetching logs...", `Loading logs from ${name}`);
             const logOutput = await logsContainer(name);
             setLogs(logOutput);
             toast.success("Logs loaded", `Retrieved logs from ${name}`);
             break;
         }
         if (action !== "shell" && action !== "logs") {
           await refresh();
         }
       } catch (error) {
         const message = error instanceof Error ? error.message : "Unknown error occurred";
         toast.error(`Failed to ${action} container ${name}`, message);
         console.error(`Failed to ${action} container ${name}:`, error);
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

  return { containers, loading, actionRunning, logs, refresh, runAction, clearLogs };
}

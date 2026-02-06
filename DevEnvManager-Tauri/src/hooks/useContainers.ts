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
            break;
          case "stop":
            await stopContainer(name);
            break;
          case "restart":
            await restartContainer(name);
            break;
          case "shell":
            await shellContainer(name);
            break;
          case "logs":
            const logOutput = await logsContainer(name);
            setLogs(logOutput);
            break;
        }
        if (action !== "shell" && action !== "logs") {
          await refresh();
        }
      } catch (error) {
        console.error(`Failed to ${action} container ${name}:`, error);
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

  return { containers, loading, actionRunning, logs, refresh, runAction, clearLogs };
}

import { useCallback, useEffect, useState } from "react";
import {
  Container,
  listContainers,
  startContainer,
  stopContainer
} from "../lib/tauri";

type ContainerAction = "start" | "stop";

type UseContainersResult = {
  containers: Container[];
  loading: boolean;
  actionRunning?: string;
  refresh: () => Promise<void>;
  runAction: (action: ContainerAction, name: string) => Promise<void>;
};

export default function useContainers(refreshMs = 60000): UseContainersResult {
  const [containers, setContainers] = useState<Container[]>([]);
  const [loading, setLoading] = useState(false);
  const [actionRunning, setActionRunning] = useState<string | undefined>(undefined);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const result = await listContainers();
      setContainers(result);
    } finally {
      setLoading(false);
    }
  }, []);

  const runAction = useCallback(
    async (action: ContainerAction, name: string) => {
      setActionRunning(name);
      try {
        if (action === "start") {
          await startContainer(name);
        } else {
          await stopContainer(name);
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

  return { containers, loading, actionRunning, refresh, runAction };
}

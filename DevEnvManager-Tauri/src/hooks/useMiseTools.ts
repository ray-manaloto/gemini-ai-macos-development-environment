import { useCallback, useEffect, useState } from "react";
import {
  installTool,
  listMiseTools,
  MiseTool,
  updateTool
} from "../lib/tauri";

type UseMiseToolsResult = {
  tools: MiseTool[];
  loading: boolean;
  actionRunning?: string;
  refresh: () => Promise<void>;
  installTool: (name: string) => Promise<void>;
  updateTool: (name: string) => Promise<void>;
};

export default function useMiseTools(refreshMs = 60000): UseMiseToolsResult {
  const [tools, setTools] = useState<MiseTool[]>([]);
  const [loading, setLoading] = useState(false);
  const [actionRunning, setActionRunning] = useState<string | undefined>(undefined);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      const result = await listMiseTools();
      setTools(result);
    } finally {
      setLoading(false);
    }
  }, []);

  const handleInstall = useCallback(async (name: string) => {
    setActionRunning(name);
    try {
      await installTool(name);
      await refresh();
    } finally {
      setActionRunning(undefined);
    }
  }, [refresh]);

  const handleUpdate = useCallback(async (name: string) => {
    setActionRunning(name);
    try {
      await updateTool(name);
      await refresh();
    } finally {
      setActionRunning(undefined);
    }
  }, [refresh]);

  useEffect(() => {
    refresh();
    const interval = setInterval(() => {
      refresh();
    }, refreshMs);
    return () => clearInterval(interval);
  }, [refresh, refreshMs]);

  return {
    tools,
    loading,
    actionRunning,
    refresh,
    installTool: handleInstall,
    updateTool: handleUpdate
  };
}

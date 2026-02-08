import { useCallback, useEffect, useRef, useState } from "react";
import {
   installTool,
   listMiseTools,
   MiseTool,
   updateTool
} from "../lib/tauri";
import { useToast } from "../contexts/ToastContext";

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
   const refreshInFlight = useRef(false);
   const toast = useToast();

  const refresh = useCallback(async () => {
    if (refreshInFlight.current) return;
    refreshInFlight.current = true;
    setLoading(true);
    try {
      const result = await listMiseTools();
      setTools(result);
    } finally {
      setLoading(false);
      refreshInFlight.current = false;
    }
  }, []);

   const handleInstall = useCallback(async (name: string) => {
     setActionRunning(name);
     const progressId = toast.progress(`Installing ${name}...`, 0);
     try {
       await installTool(name);
       toast.removeToast(progressId);
       await refresh();
       toast.success(`${name} installed`, "Tool installation completed");
     } catch (error) {
       toast.removeToast(progressId);
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error(`Failed to install ${name}`, message);
       console.error(`Failed to install tool ${name}:`, error);
     } finally {
       setActionRunning(undefined);
     }
   }, [refresh, toast]);

   const handleUpdate = useCallback(async (name: string) => {
     setActionRunning(name);
     const progressId = toast.progress(`Updating ${name}...`, 0);
     try {
       await updateTool(name);
       toast.removeToast(progressId);
       await refresh();
       toast.success(`${name} updated`, "Tool update completed");
     } catch (error) {
       toast.removeToast(progressId);
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error(`Failed to update ${name}`, message);
       console.error(`Failed to update tool ${name}:`, error);
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

  return {
    tools,
    loading,
    actionRunning,
    refresh,
    installTool: handleInstall,
    updateTool: handleUpdate
  };
}

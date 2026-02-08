import { useCallback, useEffect, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { useToast } from "../contexts/ToastContext";

export type PackageManagerStatus = "healthy" | "warning" | "error" | "unknown";

export type PackageManager = {
  name: string;
  displayName: string;
  emoji: string;
  version: string;
  status: PackageManagerStatus;
  message?: string;
};

type UsePackageManagersResult = {
  managers: PackageManager[];
  loading: boolean;
  actionRunning?: string;
  refresh: () => Promise<void>;
  runDoctor: () => Promise<void>;
  updateManager: (name: string) => Promise<void>;
};

export default function usePackageManagers(refreshMs = 60000): UsePackageManagersResult {
   const [managers, setManagers] = useState<PackageManager[]>([]);
   const [loading, setLoading] = useState(false);
   const [actionRunning, setActionRunning] = useState<string | undefined>(undefined);
   const refreshInFlight = useRef(false);
   const toast = useToast();

  const refresh = useCallback(async () => {
    if (refreshInFlight.current) return;
    refreshInFlight.current = true;
    setLoading(true);
    try {
      const result = await invoke<PackageManager[]>("get_package_managers_status");
      setManagers(result);
    } catch (error) {
      console.error("Failed to fetch package managers:", error);
      setManagers([]);
    } finally {
      setLoading(false);
      refreshInFlight.current = false;
    }
  }, []);

   const runDoctor = useCallback(async () => {
     setActionRunning("mise-doctor");
     try {
       await invoke<string>("mise_doctor");
       await refresh();
       toast.success("Doctor completed", "All diagnostics passed");
     } catch (error) {
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error("Doctor failed", message);
       console.error("mise doctor failed:", error);
     } finally {
       setActionRunning(undefined);
     }
   }, [refresh, toast]);

   const updateManager = useCallback(async (name: string) => {
     setActionRunning(`${name}-update`);
     const progressId = toast.progress(`Updating ${name}...`, 0);
     try {
       await invoke<string>("update_package_manager", { name });
       toast.removeToast(progressId);
       await refresh();
       toast.success(`${name} updated`, "Update completed successfully");
     } catch (error) {
       toast.removeToast(progressId);
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error(`Failed to update ${name}`, message);
       console.error(`Failed to update ${name}:`, error);
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
    managers,
    loading,
    actionRunning,
    refresh,
    runDoctor,
    updateManager
  };
}

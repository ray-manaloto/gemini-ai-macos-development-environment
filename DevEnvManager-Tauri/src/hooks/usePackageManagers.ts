import { useCallback, useEffect, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";

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
    } catch (error) {
      console.error("mise doctor failed:", error);
    } finally {
      setActionRunning(undefined);
    }
  }, [refresh]);

  const updateManager = useCallback(async (name: string) => {
    setActionRunning(`${name}-update`);
    try {
      await invoke<string>("update_package_manager", { name });
      await refresh();
    } catch (error) {
      console.error(`Failed to update ${name}:`, error);
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
    managers,
    loading,
    actionRunning,
    refresh,
    runDoctor,
    updateManager
  };
}

import { useCallback, useState } from "react";
import {
  runMiseValidate,
  runMiseDoctor,
  runMiseUpdateAll,
  runMiseDashboard,
} from "../lib/tauri";
import { useToast } from "../contexts/ToastContext";

type UseQuickActionsResult = {
  running: boolean;
  runValidate: () => Promise<void>;
  runDoctor: () => Promise<void>;
  runUpdateAll: () => Promise<void>;
  runDashboard: () => Promise<void>;
};

export default function useQuickActions(): UseQuickActionsResult {
  const [running, setRunning] = useState(false);
  const toast = useToast();

  const runValidate = useCallback(async () => {
    setRunning(true);
    try {
      await runMiseValidate();
      toast.success("Validation passed", "Environment is healthy");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error occurred";
      toast.error("Validation failed", message);
      console.error("Validate failed:", error);
    } finally {
      setRunning(false);
    }
  }, [toast]);

  const runDoctor = useCallback(async () => {
    setRunning(true);
    try {
      await runMiseDoctor();
      toast.success("Doctor completed", "All diagnostics passed");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error occurred";
      toast.error("Doctor failed", message);
      console.error("Doctor failed:", error);
    } finally {
      setRunning(false);
    }
  }, [toast]);

  const runUpdateAll = useCallback(async () => {
    setRunning(true);
    const progressId = toast.progress("Updating tools...", 0);
    try {
      await runMiseUpdateAll();
      toast.removeToast(progressId);
      toast.success("All tools updated", "Update completed successfully");
    } catch (error) {
      toast.removeToast(progressId);
      const message = error instanceof Error ? error.message : "Unknown error occurred";
      toast.error("Update failed", message);
      console.error("Update all failed:", error);
    } finally {
      setRunning(false);
    }
  }, [toast]);

  const runDashboard = useCallback(async () => {
    setRunning(true);
    toast.info("Opening dashboard...", "Launching TUI manager");
    try {
      await runMiseDashboard();
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unknown error occurred";
      toast.error("Dashboard failed", message);
      console.error("Dashboard failed:", error);
    } finally {
      setRunning(false);
    }
  }, [toast]);

  return {
    running,
    runValidate,
    runDoctor,
    runUpdateAll,
    runDashboard,
  };
}

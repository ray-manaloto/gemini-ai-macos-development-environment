import { useCallback, useState } from "react";
import {
  runMiseValidate,
  runMiseDoctor,
  runMiseUpdateAll,
  runMiseDashboard,
} from "../lib/tauri";

type UseQuickActionsResult = {
  running: boolean;
  runValidate: () => Promise<void>;
  runDoctor: () => Promise<void>;
  runUpdateAll: () => Promise<void>;
  runDashboard: () => Promise<void>;
};

export default function useQuickActions(): UseQuickActionsResult {
  const [running, setRunning] = useState(false);

  const runValidate = useCallback(async () => {
    setRunning(true);
    try {
      await runMiseValidate();
    } catch (error) {
      console.error("Validate failed:", error);
    } finally {
      setRunning(false);
    }
  }, []);

  const runDoctor = useCallback(async () => {
    setRunning(true);
    try {
      await runMiseDoctor();
    } catch (error) {
      console.error("Doctor failed:", error);
    } finally {
      setRunning(false);
    }
  }, []);

  const runUpdateAll = useCallback(async () => {
    setRunning(true);
    try {
      await runMiseUpdateAll();
    } catch (error) {
      console.error("Update all failed:", error);
    } finally {
      setRunning(false);
    }
  }, []);

  const runDashboard = useCallback(async () => {
    setRunning(true);
    try {
      await runMiseDashboard();
    } catch (error) {
      console.error("Dashboard failed:", error);
    } finally {
      setRunning(false);
    }
  }, []);

  return {
    running,
    runValidate,
    runDoctor,
    runUpdateAll,
    runDashboard,
  };
}

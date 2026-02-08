import { useCallback, useEffect, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { useToast } from "../contexts/ToastContext";

export type CloudStatus = "connected" | "disconnected" | "notinstalled" | "unknown";

export type SkyPilotCluster = {
  name: string;
  status: string;
  resources: string;
  region?: string;
};

export type SkyPilotStatus = {
  status: CloudStatus;
  clusterCount: number;
  clusters: SkyPilotCluster[];
  message?: string;
};

export type AwsStatus = {
  status: CloudStatus;
  accountId?: string;
  region?: string;
  message?: string;
};

type UseCloudStatusResult = {
  skyPilot: SkyPilotStatus | null;
  aws: AwsStatus | null;
  loading: boolean;
  actionRunning?: string;
  clusterLogs?: string;
  refresh: () => Promise<void>;
  launchAgent: () => Promise<void>;
  stopAgents: () => Promise<void>;
  stopCluster: (name: string) => Promise<void>;
  sshCluster: (name: string) => Promise<void>;
  getClusterLogs: (name: string) => Promise<void>;
  clearLogs: () => void;
};

export default function useCloudStatus(refreshMs = 60000): UseCloudStatusResult {
   const [skyPilot, setSkyPilot] = useState<SkyPilotStatus | null>(null);
   const [aws, setAws] = useState<AwsStatus | null>(null);
   const [loading, setLoading] = useState(false);
   const [actionRunning, setActionRunning] = useState<string | undefined>(undefined);
   const [clusterLogs, setClusterLogs] = useState<string | undefined>(undefined);
   const refreshInFlight = useRef(false);
   const toast = useToast();

  const clearLogs = useCallback(() => {
    setClusterLogs(undefined);
  }, []);

  const refresh = useCallback(async () => {
    if (refreshInFlight.current) return;
    refreshInFlight.current = true;
    setLoading(true);
    try {
      const [skyPilotResult, awsResult] = await Promise.all([
        invoke<SkyPilotStatus>("get_skypilot_status"),
        invoke<AwsStatus>("get_aws_status"),
      ]);
      setSkyPilot(skyPilotResult);
      setAws(awsResult);
    } catch (error) {
      console.error("Failed to fetch cloud status:", error);
      setSkyPilot(null);
      setAws(null);
    } finally {
      setLoading(false);
      refreshInFlight.current = false;
    }
  }, []);

   const launchAgent = useCallback(async () => {
     setActionRunning("skypilot-launch");
     const progressId = toast.progress("Launching SkyPilot agent...", 0);
     try {
       await invoke<string>("launch_skypilot_agent");
       toast.removeToast(progressId);
       await refresh();
       toast.success("Agent launched", "SkyPilot cluster is starting");
     } catch (error) {
       toast.removeToast(progressId);
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error("Failed to launch agent", message);
       console.error("Failed to launch agent:", error);
     } finally {
       setActionRunning(undefined);
     }
   }, [refresh, toast]);

   const stopAgents = useCallback(async () => {
     setActionRunning("skypilot-stop");
     try {
       await invoke<string>("stop_skypilot_agents");
       await refresh();
       toast.success("Agents stopped", "All SkyPilot clusters terminated");
     } catch (error) {
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error("Failed to stop agents", message);
       console.error("Failed to stop agents:", error);
     } finally {
       setActionRunning(undefined);
     }
   }, [refresh, toast]);

   const stopCluster = useCallback(async (name: string) => {
     setActionRunning(`cluster-stop-${name}`);
     try {
       await invoke<string>("stop_skypilot_cluster", { name });
       await refresh();
       toast.success("Cluster stopped", `${name} has been terminated`);
     } catch (error) {
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error(`Failed to stop cluster ${name}`, message);
       console.error(`Failed to stop cluster ${name}:`, error);
     } finally {
       setActionRunning(undefined);
     }
   }, [refresh, toast]);

   const sshCluster = useCallback(async (name: string) => {
     setActionRunning(`cluster-ssh-${name}`);
     toast.info("Opening SSH session...", `Connecting to ${name}`);
     try {
       await invoke<string>("ssh_skypilot_cluster", { name });
     } catch (error) {
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error(`Failed to SSH to cluster ${name}`, message);
       console.error(`Failed to SSH to cluster ${name}:`, error);
     } finally {
       setActionRunning(undefined);
     }
   }, [toast]);

   const getClusterLogs = useCallback(async (name: string) => {
     setActionRunning(`cluster-logs-${name}`);
     toast.info("Fetching logs...", `Loading logs from ${name}`);
     try {
       const logs = await invoke<string>("get_skypilot_logs", { name });
       setClusterLogs(logs);
       toast.success("Logs loaded", `Retrieved logs from ${name}`);
     } catch (error) {
       const message = error instanceof Error ? error.message : "Unknown error occurred";
       toast.error(`Failed to get logs for cluster ${name}`, message);
       console.error(`Failed to get logs for cluster ${name}:`, error);
     } finally {
       setActionRunning(undefined);
     }
   }, [toast]);

  useEffect(() => {
    refresh();
    const interval = setInterval(() => {
      refresh();
    }, refreshMs);
    return () => clearInterval(interval);
  }, [refresh, refreshMs]);

  return {
    skyPilot,
    aws,
    loading,
    actionRunning,
    clusterLogs,
    refresh,
    launchAgent,
    stopAgents,
    stopCluster,
    sshCluster,
    getClusterLogs,
    clearLogs,
  };
}

import { useEffect, useState } from "react";
import { listen } from "@tauri-apps/api/event";

export interface ProgressEvent {
  operation: string;
  status: "started" | "progress" | "completed" | "failed";
  percent?: number;
  message: string;
}

export function useProgressOperation(operationName: string) {
  const [progress, setProgress] = useState<ProgressEvent | null>(null);

  useEffect(() => {
    const unlisten = listen<ProgressEvent>("operation-progress", (event) => {
      if (event.payload.operation === operationName) {
        setProgress(event.payload);
      }
    });

    return () => {
      unlisten.then((fn) => fn());
    };
  }, [operationName]);

  return progress;
}

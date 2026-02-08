import { useEffect } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { ToastProvider } from "./contexts/ToastContext";
import MenuBarPopup from "./components/MenuBarPopup";
import ToastContainer from "./components/ToastContainer";

export default function App() {
  useEffect(() => {
    let unlisten: (() => void) | undefined;
    const setup = async () => {
      const window = getCurrentWindow();
      unlisten = await window.onFocusChanged(({ payload }: { payload: boolean }) => {
        if (!payload) {
          window.hide();
        }
      });
    };

    setup();

    return () => {
      if (unlisten) {
        unlisten();
      }
    };
  }, []);

  return (
    <ToastProvider>
      <MenuBarPopup />
      <ToastContainer />
    </ToastProvider>
  );
}

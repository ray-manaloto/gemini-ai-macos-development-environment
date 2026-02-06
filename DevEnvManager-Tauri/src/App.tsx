import { useEffect } from "react";
import { getCurrentWindow } from "@tauri-apps/api/window";
import MenuBarPopup from "./components/MenuBarPopup";

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

  return <MenuBarPopup />;
}

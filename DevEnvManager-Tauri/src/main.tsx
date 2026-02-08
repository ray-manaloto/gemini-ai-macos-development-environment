import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./styles/global.css";
import "./styles/menubar.css";
import "./styles/package-managers.css";
import "./styles/cloud.css";
import "./styles/quick-actions.css";
import "./styles/toast.css";

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);

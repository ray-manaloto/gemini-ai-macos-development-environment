import { useState } from "react";
import StatusHeader from "./StatusHeader";
import QuickActionsBar from "./QuickActionsBar";
import PackageManagersStatus from "./PackageManagersStatus";
import CloudStatus from "./CloudStatus";
import ToolsList from "./ToolsList";
import ServicesList from "./ServicesList";
import ContainersList from "./ContainersList";
import PortsList from "./PortsList";
import CloudTab from "./CloudTab";

type TabKey = "tools" | "services" | "containers" | "ports" | "cloud";

const tabs: { key: TabKey; label: string }[] = [
  { key: "tools", label: "Tools" },
  { key: "services", label: "Services" },
  { key: "containers", label: "Containers" },
  { key: "ports", label: "Ports" },
  { key: "cloud", label: "Cloud" }
];

export default function MenuBarPopup() {
  const [activeTab, setActiveTab] = useState<TabKey>("tools");

  return (
    <div className="menubar-popup">
      <div className="menubar-arrow" />
      <header className="menubar-header">
        <div>
          <h1>DevEnvManager</h1>
          <p>Quick status and actions</p>
        </div>
      </header>
      <StatusHeader />
      <QuickActionsBar />
      <PackageManagersStatus />
      <CloudStatus />
      <nav className="menubar-tabs">
        {tabs.map((tab) => (
          <button
            key={tab.key}
            className={activeTab === tab.key ? "active" : ""}
            onClick={() => setActiveTab(tab.key)}
            type="button"
          >
            {tab.label}
          </button>
        ))}
      </nav>
      <section className="menubar-content">
        {activeTab === "tools" && <ToolsList />}
        {activeTab === "services" && <ServicesList />}
        {activeTab === "containers" && <ContainersList />}
        {activeTab === "ports" && <PortsList />}
        {activeTab === "cloud" && <CloudTab />}
      </section>
    </div>
  );
}

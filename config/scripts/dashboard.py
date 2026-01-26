#!/usr/bin/env python3
"""Dev Environment Dashboard - A TUI for managing local and cloud tools."""

from textual.app import App, ComposeResult
from textual.containers import Container, Grid
from textual.widgets import Header, Footer, Static, Button, Label, Log
import subprocess


class DevDashboard(App):
    CSS = """
    Screen { layout: grid; grid-size: 2; padding: 1; }
    .box { border: solid green; height: 100%; padding: 1; }
    .status-running { color: green; }
    .status-stopped { color: red; }
    """

    def compose(self) -> ComposeResult:
        yield Header()

        # 1. Container Status (OrbStack)
        with Container(classes="box"):
            yield Static("📦 OrbStack (Containers)")
            yield Label(self.get_orb_status(), id="lbl_orb")
            yield Button("Start Engine", id="orb_start")
            yield Button("Stop Engine", id="orb_stop", variant="error")

        # 2. Cloud Status (SkyPilot)
        with Container(classes="box"):
            yield Static("☁️ AWS Cloud Agents")
            yield Label(self.get_sky_status(), id="lbl_sky")
            yield Button("Launch Agent", id="sky_up", variant="primary")
            yield Button("Kill All (Save $$)", id="sky_down", variant="error")

        yield Footer()

    def get_orb_status(self):
        try:
            status = subprocess.check_output(["orb", "status"], text=True)
            return f"Running 🟢" if "running" in status else "Stopped 🔴"
        except:
            return "Unknown"

    def get_sky_status(self):
        try:
            count = subprocess.check_output("sky status --refresh | grep -c UP", shell=True, text=True)
            return f"{count.strip()} Active Clusters"
        except:
            return "0 Active"

    def on_mount(self):
        self.refresh_status()

    def refresh_status(self):
        # Check OrbStack
        try:
            status = subprocess.check_output(["orb", "status"], text=True)
            self.query_one("#lbl_orb").update(f"Status: {status.strip()}")
        except:
            self.query_one("#lbl_orb").update("Status: Not Found")

        # Check SkyPilot
        try:
            count = subprocess.check_output("sky status --refresh | grep -c UP", shell=True, text=True)
            self.query_one("#lbl_sky").update(f"Active Nodes: {count.strip()}")
        except:
            self.query_one("#lbl_sky").update("Status: Offline")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        bid = event.button.id
        if bid == "orb_start":
            subprocess.Popen(["orb", "start"])
        if bid == "orb_stop":
            subprocess.Popen(["orb", "stop"])
        if bid == "sky_up":
            subprocess.Popen(["mise", "run", "agent:up"])
        if bid == "sky_down":
            subprocess.Popen(["mise", "run", "agent:down"])
        self.notify("Executing command...")


if __name__ == "__main__":
    DevDashboard().run()

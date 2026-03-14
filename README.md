# agents-status-tray-home-manager

Home Manager integration for `agents-status-tray`.

This flake exposes a Home Manager module that:

- installs the `agents-status-tray` package
- writes the app JSON config
- starts it as a user service on graphical login

The module does not decide which coding agents you use. Pass those explicitly through `services.agents-status-tray.agents`.

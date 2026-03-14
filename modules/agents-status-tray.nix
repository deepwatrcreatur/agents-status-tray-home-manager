{ agents-status-tray-flake }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.agents-status-tray;
  package =
    if cfg.package != null then
      cfg.package
    else
      agents-status-tray-flake.packages.${pkgs.stdenv.hostPlatform.system}.default;
  trayConfig = {
    refresh_interval_seconds = cfg.refreshIntervalSeconds;
    claude_cache_ttl_seconds = cfg.claudeCacheTtlSeconds;
    agents = cfg.agents;
  };
in
{
  options.services.agents-status-tray = {
    enable = lib.mkEnableOption "Linux StatusNotifier tray for coding agent status";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "Package to run for the tray app.";
    };

    agents = lib.mkOption {
      type = with lib.types; listOf (submodule {
        options = {
          id = lib.mkOption {
            type = str;
            description = "Stable adapter ID such as claude or codex.";
          };
          name = lib.mkOption {
            type = str;
            description = "Display name shown in the tray menu.";
          };
          command = lib.mkOption {
            type = str;
            description = "Command used for installed/missing detection.";
          };
        };
      });
      default = [];
      description = "Agents to display in the tray.";
    };

    refreshIntervalSeconds = lib.mkOption {
      type = lib.types.int;
      default = 90;
      description = "How often to refresh agent status.";
    };

    claudeCacheTtlSeconds = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "How long Claude OAuth usage responses are cached.";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Start the tray automatically in graphical sessions.";
    };
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    assertions = [
      {
        assertion = cfg.agents != [];
        message = "services.agents-status-tray.agents must not be empty.";
      }
    ];

    home.packages = [ package ];

    xdg.configFile."agents-status-tray/config.json".text = builtins.toJSON trayConfig;

    systemd.user.services.agents-status-tray = lib.mkIf cfg.autoStart {
      Unit = {
        Description = "Agents status tray";
        After = [ "graphical-session.target" "network-online.target" ];
        Wants = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${package}/bin/agents-status-tray";
        Restart = "always";
        RestartSec = 10;
        Environment = [
          "AGENTS_STATUS_TRAY_CONFIG=${config.xdg.configHome}/agents-status-tray/config.json"
          "AGENTS_STATUS_TRAY_CACHE=${config.xdg.cacheHome}/agents-status-tray/status.json"
        ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}

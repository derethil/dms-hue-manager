# Philips Hue Management from DMS

A bar widget that lets you manage your Philips Hue lighting from your desktop.

<p align="center">
    <img src="./assets/screenshot.png" alt="Plugin Screenshot"/>
</p>

**Note:** A Hue Bridge is required for [OpenHue](https://www.openhue.io/) to
manage your devices.

## Features

- **Supports both lights and rooms**: Control an entire room or individual
  lights
- **Guided setup**: Prompts for OpenHue bridge pairing if not already configured
- **Real-time updates**: Listens to your Hue Bridge's event stream for real-time
  updates, instantly reflecting any changes made via the app or automations
- **Brightness and temperature control**: Manually control a devices's
  brightness level and temperature value
- **Color control**: Leverages the builtin DMS color picker to set a devices's
  color directly
- **Scenes**: Easily switch between your predefined scenes for each room
- **Device icons**: Maps your Philips Hue icons to the closest equivalent from
  Material Symbols

## Installation

First Install the [OpenHue CLI](https://www.openhue.io/) and `jq` dependencies,
then proceed with plugin installation:

### DMS Settings UI

1. Open DMS Settings `Mod+,` and go to the Plugins tab then click Browse
2. Find Hue Manager and click install

### Manually

```bash
cd ~/.config/DankMaterialShell/plugins
git clone https://github.com/derethil/dms-hue-manager.git
```

1. Open DMS Settings `Mod+,` and go to the Plugins tab
2. Click "Scan for plugins"
3. Enable the Hue Manager plugin

### Nix

Enable `openhue-cli` and `jq` e.g.

```nix
home.packages = with pkgs; [
  openhue-cli
  jq
];
```

Then follow the DMS Plugin Registry
[Nix installation](https://github.com/AvengeMedia/dms-plugin-registry/blob/master/nix/README.md)
instructions.

## Configuration

Plugin options can be configured in the Plugins tab in DMS Settings; they are
also stored in `~/.config/DankMaterialShell/plugin_settings.json`:

```json
{
  "hueManager": {
    "openHuePath": "openhue",
    "jqPath": "jq",
    "enabled": true,
    "useDeviceIcons": true
  }
}
```

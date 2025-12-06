pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Item {
    id: root

    readonly property string pluginId: "hueManager"

    // Error State
    property bool isError: false
    property string errorMessage: ""

    // Hue State
    property string bridgeIP: ""
    property var rooms: []

    Component.onCompleted: {
        initialize()
    }

    function initialize() {
        checkOpenHueAvailable((available) => {
            if (!available) return
            checkIsOpenHueSetup((configured) => {
                if (!configured) return
                refresh()
            })
        })
    }

    function refresh() {
        getHueBridgeIP()
        getRooms()
    }

    function checkOpenHueAvailable(onComplete) {
        Proc.runCommand(`${pluginId}.whichOpenhue`, ["which", "openhue"], (output, exitCode) => {
            if (exitCode !== 0) {
                setError("OpenHue is not installed. Please install it to use this plugin.")
                ToastService.showError("OpenHue Not Found", "Please install openhue-cli to use Hue Manager")
                onComplete(false)
                return
            }
            onComplete(true)
        }, 100)
    }

    function checkIsOpenHueSetup(onComplete) {
        Proc.runCommand(`${pluginId}.openhueGet`, ["openhue", "get"], (output, exitCode) => {
            if (output.trim().includes("please run the 'setup' command")) {
                setError("OpenHue is not set up. Please set up your Hue Bridge with 'openhue setup'.")
                ToastService.showError("OpenHue Setup Required", "Please run 'openhue setup' to configure your Hue Bridge")
                onComplete(false)
                return
            }
            onComplete(true)
        }, 100)
    }

    function getHueBridgeIP() {
        Proc.runCommand(`${pluginId}.openhueDiscover`, ["openhue", "discover"], (output, exitCode) => {
            root.bridgeIP = exitCode === 0 ? output.trim() : "Unknown"
            exposeUpdatedState()
        }, 100)
    }

    function getRooms() {
        const command = "openhue get room -j | jq '[.[].GroupedLight | {Name, dimming: .HueData.dimming.brightness, on: .HueData.on.on, id: .HueData.id}]'"
        Proc.runCommand(`${pluginId}.openhueRooms`, ["sh", "-c", command], (output, exitCode) => {
            if (exitCode === 0) {
                try {
                    root.rooms = JSON.parse(output.trim())
                } catch (e) {
                    console.error("HueManager: Failed to parse rooms JSON:", e)
                    root.rooms = []
                }
            } else {
                console.error("HueManager: Failed to get rooms:", output)
            }
            exposeUpdatedState()
        }, 100)
    }

    function setError(message) {
        root.isError = true
        root.errorMessage = message
        exposeUpdatedState()
    }

    function exposeUpdatedState() {
        PluginService.setGlobalVar(pluginId, "bridgeIP", bridgeIP)
        PluginService.setGlobalVar(pluginId, "rooms", rooms)
        PluginService.setGlobalVar(pluginId, "isError", isError)
        PluginService.setGlobalVar(pluginId, "errorMessage", errorMessage)
    }
}

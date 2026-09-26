import Quickshell
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "debug"
        function ping(): string { return "pong"; }
    }
}
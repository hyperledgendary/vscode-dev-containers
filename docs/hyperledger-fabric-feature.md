# Hyperledger Fabric Install Script

**Script status:** Experimental

**OS support**: Debian 9+, Ubuntu 20.04+, and downstream distros.

> **Note:** Your host chip architecture needs to match the your container image architecture for this script to function. Cross-architecture emulation will not work. (TBC)

## Syntax

```text
./hyperledger-fabric.sh [Enable non-root docker access flag] [Non-root user] [Fabric Version]
```

Or as a feature:

```json
"features": {
    "hyperledger-fabric": {
        "version": "latest",
    }
}
```

|Argument| Feature option |Default|Description|
|--------|----------------|-------|-----------|
|Non-root access flag| | `true`| Flag (`true`/`false`) that specifies whether a non-root user should be granted access to Docker.|
|Non-root user| | `automatic`| Specifies a user in the container other than root that will be using the desktop. A value of `automatic` will cause the script to check for a user called `vscode`, then `node`, `codespace`, and finally a user with a UID of `1000` before falling back to `root`. |
| Fabric version | `version` | `latest` |  Fabric version or `latest`. Partial version numbers allowed. |

## Usage

### Feature use

You can use this script for your primary dev container by adding it to the `features` property in `devcontainer.json`.

```json
"features": {
    "hyperledger-fabric": {
        "version": "latest",
    }
}
```

If you have already built your development container, run the **Rebuild Container** command from the command palette (<kbd>Ctrl/Cmd</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> or <kbd>F1</kbd>) to pick up the change.

### Script use

See the [`fabric-chaincode`](../containers/fabric-chaincode) definition for a complete working example. However, here are the general steps to use the script:

1. Add [`hyperledger-fabric.sh`](../features/hyperledger-fabric.sh) to `.devcontainer/library-scripts`

2. TBC...

## Resources

TBC

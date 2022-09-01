# vscode-dev-containers

A repository of Hyperledger Fabric [development container](https://containers.dev/) definitions for the VS Code Remote - Containers extension and GitHub Codespaces

```
export MICROFAB_HOME=$HOME/microfab
export MICROFAB_CONFIG='{
    "endorsing_organizations":[
        {
            "name": "CongaOrg"
        }
    ],
    "channels":[
        {
            "name": "mychannel",
            "endorsing_organizations":[
                "CongaOrg"
            ]
        }
    ],
    "couchdb": false
}'
```

## TODO

- make it work with fabric test networks?!
  https://github.com/microsoft/vscode-dev-containers/blob/main/CONTRIBUTING.md#contributing-dev-container-definitions
- use docker-in-docker feature?
  https://github.com/microsoft/vscode-dev-containers/tree/main/script-library/docs
- create "hyperledger-fabric" feature?
  https://github.com/microsoft/dev-container-features-template#adding-your-own-features
- separate go node and java containers instead of including everything in one? (slow!)

# Tanzu GitOps Reference Implementation

Use this archive contains an opinionated approach to implementing GitOps workflows on Kubernetes clusters.

This reference implementation is pre-configured to install Tanzu Application Platform.

For detailed documentation, refer to [VMware Tanzu Application Platform Product Documentation](https://docs.vmware.com/en/VMware-Tanzu-Application-Platform/1.5/tap/install-gitops-intro.html).

```
clusters/aks-eu-tap-6/cluster-config
├── config
│   ├── extras                                  /// Add here the packages you need to add to tap installation
│   │   ├── acs
│   │   │   └── pkgi.yaml
│   │   ├── config-post-install
│   │   │   └── app.yaml                       /// Deploy the app that manages the post-install configuration (sosp enabled)
│   │   ├── es
│   │   │   └── pkgi.yaml
│   │   └── pgql
│   │       ├── pkgi.yaml
│   │       └── pkgr.yaml
│   └── tap-install
├── config-post-install                        /// Post install configuration, use ./encrypt-sops.sh $1 to encrypt sensitive data and add it to .gitignore
│   └── es
│       ├── azure-secret-sp-sensitive.yaml
│       ├── azure-secret-sp-sensitive.yaml.sops.yaml
│       └── cluster-azure-backend.yaml
├── tap-logo.png                                /// Put here your logo for your portal
└── values                                      /// Provide Values for tap-gitops (sops)
    ├── tap-gui-icon-values.yaml
    ├── tap-install-values.yaml
    ├── tap-non-sensitive-values.yaml
    ├── tap-sensitive-values.yaml.sops.yaml
    └── tap-sensitive-values.yaml
```

````
make tanzu-cluster-essentials copy_pgsql_package CLUSTER_NAME=aks-eu-tap-7
make new-instance CLUSTER_NAME=aks-eu-tap-7
make configure CLUSTER_NAME=aks-eu-tap-7
make generate CLUSTER_NAME=aks-eu-tap-7 TAP_VERSION=1.7.1-rc.5
make clone FROM_CLUSTER_NAME=aks-eu-tap-6 CLUSTER_NAME=aks-eu-tap-7
make encrypt   CLUSTER_NAME=aks-eu-tap-7  // all the files following the pattern '-sensitive.yaml' become encrypted and added to git ignore
git push
make deploy CLUSTER_NAME=aks-eu-tap-7
#wait.... k get app -A -w
make tap-update-dns tap-gui-ip CLUSTER_NAME=aks-eu-tap-7
``

* Upgrade TAP Version

```
./copy_tap_package.sh akseutap6registry 1.6.3-rc.5
make gen-install-values gen-tap-gui-icon-values  TAP_VERSION=1.6.3-rc.5
git commit -am "1.6.3-rc.5" 
git push
```

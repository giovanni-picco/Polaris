# Talos OS

## Installation Notes

Following the [official documentation](https://docs.siderolabs.com/talos/v1.12/getting-started/prodnotes), to install a PRODUCTION READY cluster.
The following points are my implementation/thoughts on how to adapt it to my needs.

1. Generate an id on <https://factory.talos.dev/> that matches my requirements.
   For this test, on Proxmox, I used secureboot and the following add-ons:

    ``` yaml
    customization:
        systemExtensions:
            officialExtensions:
                - siderolabs/iscsi-tools
                - siderolabs/qemu-guest-agent
        bootloader: sd-boot
    ```

    **Boot Image**

    `factory.talos.dev/metal-installer-secureboot/4612bdf9ff40f19debe82540e2fa0c88f84fe9099c5ed6bab3023dee1eb5e802:v1.12.4`

2. This step is currently unnecessary given how the installation will be performed later, to be revisited.

3. To make the cluster HA, the `controlplane` nodes must always be reachable. For this I will use the DNS record strategy.
    I proceed to create an A record for each node as shown in the example:

    ```code
    kube.polarislab.dev  IN  A  10.10.90.1
    kube.polarislab.dev  IN  A  10.10.90.2
    kube.polarislab.dev  IN  A  10.10.90.3
    ```

4. Simply export the chosen domain as a bash variable (it will be needed later)

    ```sh
    export YOUR_ENDPOINT=kube.polarislab.dev
    ```

5. Generate the encryption keys, certificate tokens required by Talos.

   ```sh
   talosctl gen secrets -o secrets.yaml
   ```

6. Generate the base configuration files, on which patches will then be applied.
    First, export the cluster name.

    ```sh
    export CLUSTER_NAME=POLARIS
    ```

    Then generate the files.

    ```sh
    talosctl gen config --with-secrets secrets.yaml $CLUSTER_NAME https://$YOUR_ENDPOINT:6443
    ```

7. Disconnect the USB drive

8. Find the configurations on which to build the patch files
    1. Find the ethernet interface(s) in use or that you want to use

        ```sh
        talosctl --nodes 10.10.90.1 get links --insecure

        NODE   NAMESPACE   TYPE         ID        VERSION   ALIAS   TYPE       KIND     HW ADDR                                           OPER STATE   LINK STATE
        network     LinkStatus   bond0     1                 ether      bond     ae:88:d9:a5:43:4a                                 down         false
        network     LinkStatus   dummy0    1                 ether      dummy    be:1b:bb:d2:74:f7                                 down         false
        network     LinkStatus   ens18     3                 ether               bc:24:11:63:18:c7                                 up           true
        network     LinkStatus   ip6tnl0   1                 tunnel6    ip6tnl   00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00   down         false
        network     LinkStatus   lo        2                 loopback            00:00:00:00:00:00                                 unknown      true
        network     LinkStatus   sit0      1                 sit        sit      00:00:00:00                                       down         false
        network     LinkStatus   teql0     1                 void                                                                  down         false
        network     LinkStatus   tunl0     1                 ipip       ipip     00:00:00:00                                       down         false
        ```

        In this example you can see that the `ens18` interface was active.
    2. Find the disk where to install the Talos image.

        ```sh
        talosctl get disks --insecure --nodes 10.10.90.1
        NODE   NAMESPACE   TYPE   ID      VERSION   SIZE     READ ONLY   TRANSPORT   ROTATIONAL   WWID   MODEL           SERIAL
        runtime     Disk   loop0   2         4.1 kB   true
        runtime     Disk   loop1   2         692 kB   true
        runtime     Disk   loop2   2         278 MB   true
        runtime     Disk   loop3   2         479 kB   true
        runtime     Disk   loop4   2         75 MB    true
        runtime     Disk   sda     2         322 GB   false       virtio                          QEMU HARDDISK
        runtime     Disk   sr0     2         895 MB   false       sata        true                QEMU DVD-ROM
        ```

        In this example the target disk was `sda`.

9. Create the patches for the nodes, which can be divided into 'common' and 'specific'.
    - **Common**: Refers to settings that are uniform across all nodes of the same type (e.g. controlplane).
    Example: image to use, enabling scheduling on the node, the disk to use if it's the same on all nodes.

    ```yaml
    # controlplane-patch-common.yaml
    machine:
    install:
        disk: /dev/sda
        image: factory.talos.dev/metal-installer-secureboot/4612bdf9ff40f19debe82540e2fa0c88f84fe9099c5ed6bab3023dee1eb5e802:v1.12.4
        wipe: true
    nodeLabels:
        node.kubernetes.io/exclude-from-external-load-balancers:
        $patch: delete
    cluster:
    allowSchedulingOnControlPlanes: true
    ---
    apiVersion: v1alpha1
    kind: HostnameConfig
    $patch: delete
    ```

    - **Specific**: All configurations that are specific to a single node.
    Example: hostname, node-specific certSANs, network interface / disk to use.

    ```yaml
    # controlplane-patch-cp1.yaml
    machine:
    certSANs:
        - cp1.polarislab.dev
    network:
        hostname: pol-cp1
        interfaces:
        - interface: ens18
            dhcp: true
    ```

10. Skip this step

11. Apply the configurations for each node. The official guide uses a for-loop with variables set in step **2**, but this is unnecessary for me since I will need to run each configuration manually anyway.

    Example command to apply the configuration:

    ```sh
    talosctl apply-config --nodes 10.10.90.1 \
        --config-patch @controlplane-01-patch.yml \
        --file controlplane.yaml \
        --insecure
    ```

12. Merge the talosctl configurations into your own.

    ```sh
    talosctl config merge ./talosconfig
    ```

13. Set the cluster endpoints, i.e. the IPs/DNS records of each `controlplane` node

    ```sh
    talosctl config endpoint cp1.polarislab.dev cp2.polarislab.dev cp3.polarislab.dev
    ```

14. Bootstrap the cluster with the command:

    ```sh
    talosctl bootstrap --nodes cp1.polarislab.dev # only the first/one of the controlplane nodes is needed
    ```

15. Copy the Kubernetes configurations into your own config

    ```sh
    talosctl kubeconfig --nodes cp1.polarislab.dev
    ```

16. Verify that everything works

    ```sh
    kubectl get nodes
    ```

## Extra Configurations

### Network Bond

```yaml
network:
    interfaces:
    - interface: bond0
        dhcp: true
        bond:
        mode: 802.3ad # Must also be configured on the switch, for Unifi use 'Aggregation'
        interfaces:
            - enp89s0 # interface 1
            - enp87s0 # interface 2
```

![](graphics/purestorage.png)

# Pure Storage OpenConnect Hyper-V Scripts

# About this Repository

Welcome to the Hyper-V Pure Storage script repository. This repository contains building block examples to teach you how to utilize Pure Storage's platform with Hyper-V.  

# Technical Requirements

* The code in this repository is implemented using the [Pure Storage PowerShell SDK2 Module](https://support.purestorage.com/Solutions/Microsoft_Platform_Guide/a_Windows_PowerShell/Pure_Storage_PowerShell_SDK). Follow this link for release notes and installation guidance.


# Demo Inventory

## Crash Consistent Snapshot Examples

| Demo | Description |  |   |
| ----------- | ----------- |  ----------- |  ----------- | 
| **Cluster Shared Volume Refresh* | This script will clone a Hyper-V Cluster Shared Volume (CSV), using a crash consistent snapshot, and present it back to the originating Hyper-V cluster as a second CSV "copy." | [More Info](./demos-sdk2/Hyper-V%20Cluster%20Shared%20Volume%20Refresh/) | [Sample Code](./demos-sdk2/Hyper-V%20Cluster%20Shared%20Volume%20Refresh/Hyper-V%20Cluster%20Shared%20Volume%20Refresh.ps1) |

---

_The contents of the repository are intended as examples only and should be modified to work in your individual environments. No script examples should be used in a production environment without fully testing them in a development or lab environment. There are no expressed or implied warranties or liability for the use of these example scripts and templates presented by Pure Storage and/or their creators._


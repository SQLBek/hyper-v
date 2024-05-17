**Hyper-V Cluster Shared Volume Refresh**
<BR>This folder contains example snapshot scripts to refresh another existing Cluster Shared Volume.<BR>
 
 
**Files:**
- Hyper-V Cluster Shared Volume Refresh.ps1

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

**Scenario:**
<BR>This script will clone a Hyper-V Cluster Shared Volume (CSV), using a crash consistent snapshot, and present it back to the originating Hyper-V cluster as a second CSV "copy."  This example scenario is useful if you have multiple VMs on a CSV but wish to restore only one.

**Prerequisites:**
1. An additional Windows server (referred to as a staging server).   This staging server does not have to be a Hyper-V host.
2. A pre-created volume of equal size to the source CSV, pre-attached to the staging server.
3. The 'Failover Cluster Module for Windows PowerShell' Feature in Windows is required on the Hyper-V host: Add-WindowsFeature RSAT-Clustering-PowerShell
4. Must identify disk serial number of the staging disk and the Cluster Disk number of the final target Cluster Shared Volume.  These values need to be added to the code.

**Important Usage Notes:**
<BR>

Due to the caching mechanism of CSVs in Hyper-V, a Production Checkpoint must be taken to harden the CSV's contents as a failsafe, prior to snapshot.  This is done in the code below.  If a snapshotted VM is unable to boot after cloning, use that Production snapshot to "revert" the VM back to a known good state (taken immediately prior to the snapshot step in the script), then boot.  This is a caveat of Hyper-V CSVs and can only be mitigated by using an application consistent snapshot via VSS, instead of a crash consistent snapshot.  

The staging server is needed because each CSV has a unique signature.  If the CSV is presented back to the Hyper-V host unaltered, a signature collision will be detected and the new CSV will not be able to be used by Windows. Hyper-V is unable to resignature in this state either.  Instead, the CSV must be presented to another machine (aka the staging server), resignatured there, then can be re-snapshotted and cloned back to the originating Hyper-V host.

This script may be adjusted to clone and present the CSV snapshot to a different Hyper-V host.  If this is done, then the staging server and resignature step is not required, since the new target Hyper-V host will not have two of the same CSV causing a signature conflict.

This script also assumes that all database files (data and log) are on the same volume/single VMDK.  If multiple volumes/VMDKs are being used, you will have to adjust the code (ex: add additional foreach loops for manipulating multiple VMDKs).

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

**Disclaimer:**
<BR>
This example script is provided AS-IS and meant to be a building block to be adapted to fit an individual organization's infrastructure.
<BR>
We encourage the modification and expansion of these scripts by the community. Although not necessary, please issue a Pull Request (PR) if you wish to request merging your modified code in to this repository.

<!-- wp:separator -->
<hr class="wp-block-separator"/>
<!-- /wp:separator -->

_The contents of the repository are intended as examples only and should be modified to work in your individual environments. No script examples should be used in a production environment without fully testing them in a development or lab environment. There are no expressed or implied warranties or liability for the use of these example scripts and templates presented by Pure Storage and/or their creators._

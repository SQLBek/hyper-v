##############################################################################################################################
# Clone and copy-back Hyper-V Cluster Shared Volume (CSV) to originating Hyper-V cluster
#
# Scenario: 
#    This script will clone a Hyper-V Cluster Shared Volume (CSV), using a crash consistent snapshot, and present it back 
#    to the originating Hyper-V cluster as a second CSV "copy."  This example scenario is useful if you have multiple VMs 
#    on a CSV but wish to restore only one.
#
#
# Prerequisities:
#    1. An additional Windows server (referred to as a staging server).   This staging server does not have to be a 
#       Hyper-V host.
#    2. A pre-created volume of equal size to the source CSV, pre-attached to the staging server.
#    3. The 'Failover Cluster Module for Windows PowerShell' Feature in Windows is required on the Hyper-V host.
#       Add-WindowsFeature RSAT-Clustering-PowerShell
#    4. Must identify disk serial number of the staging disk and the Cluster Disk number of the final
#       target Cluster Shared Volume.  These values need to be added to the code
# 
# Usage Notes:
#
#    Due to the caching mechanism of CSVs in Hyper-V, a Production Checkpoint must be taken to harden the CSV's contents
#    as a failsafe, prior to snapshot.  This is done in the code below.  If a snapshotted VM is unable to boot after 
#    cloning, use that Production snapshot to "revert" the VM back to a known good state (taken immediately prior to 
#    the snapshot step in the script), then boot.  This is a caveat of Hyper-V CSVs and can only be mitigated by using 
#    an application consistent snapshot via VSS, instead of a crash consistent snapshot.  
#
#    The staging server is needed because each CSV has a unique signature.  If the CSV is presented back to the Hyper-V
#    host unaltered, a signature collision will be detected and the new CSV will not be able to be used by Windows. 
#    Hyper-V is unable to resignature in this state either.  Instead, the CSV must be presented to another machine (aka
#    the staging server), resignatured there, then can be re-snapshotted and cloned back to the originating Hyper-V
#    host.
#
#    This script may be adjusted to clone and present the CSV snapshot to a different Hyper-V host.  If this is done, then
#    the staging server and resignature step is not required, since the new target Hyper-V host will not have two of the
#    same CSV causing a signature conflict.
# 
# 
# Disclaimer:
#    This example script is provided AS-IS and meant to be a building block to be adapted to fit an individual 
#    organization's infrastructure.
##############################################################################################################################
Import-Module PureStoragePowerShellSDK2



# Variables
$FlashArrayEndPoint          = 'flasharray1.example.com'   
$SourceVMHost                = 'hyperv-host-01.example.com'                 # Does not work with cluster name, must use a discrete node? Test with a non-owner node
$SourceVM                    = 'hyperv-vm-source'
$SourceVolumeName            = 'hyperv-vm-source-csv-01'
$StagingServer               = 'windows-staging-server'
$StagingVolumeName           = 'temporary-volume-for-csv-resignature'
$StagingDiskSerialNumber     = '343E12644E642778026437A7'
$TargetVMHost                = 'hyperv-vm-target'
$TargetVolumeName            = 'hyperv-vm-target-csv-01-cloned'
$TargetClusterDiskNumber     = 'Cluster Disk 3'



# Establish credential to use for all connections
$Credential = Get-Credential



# Connect to the FlashArray
$FlashArray = Connect-Pfa2Array -Endpoint $FlashArrayEndPoint -Credential ($Credential) -IgnoreCertificateError



# Prepare the staging CSV for overlay
# Connect to staging VM
$StagingServerSession = New-PSSession -ComputerName $StagingServer -Credential $Credential



# Offline the volume 
# NOTE: use Get-Disk prior to get the correct Serial Number
Invoke-Command -Session $StagingServerSession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:StagingDiskSerialNumber } | Set-Disk -IsOffline $True }



# Verify
Invoke-Command -Session $StagingServerSession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $using:StagingDiskSerialNumber }}



# Snapshot the source CSV
# This example is for an on-demand snapshot. Can adjust code to also use a prior snapshot; ex. regularly scheduled
# snapshots or an asynchronously replicated snapshot from another FlashArray
# Prior to taking snapshot, must issue a Production Checkpoint on sourceVM to "force flush" CSV cache
$SourceVMSession = New-PSSession -ComputerName $SourceVMHost -Credential $Credential



# Issue Checkpoint
Invoke-Command -Session $SourceVMSession -ScriptBlock { Get-VM $Using:SourceVM | Checkpoint-VM -SnapshotName clone }



# Clone the source CSV to the staging CSV
New-Pfa2Volume -Array $FlashArray -Name $StagingVolumeName -SourceName $SourceVolumeName -Overwrite $true



# Clean-up Production Checkpoint
Invoke-Command -Session $SourceVMSession -ScriptBlock { Get-VM $Using:SourceVM | Remove-VMSnapshot -Name clone }



# Now must resignature the CSV on the staging VM
# Build DISKPART script commands for resignature
$StagingDisk = Invoke-Command -Session $StagingServerSession -ScriptBlock { Get-Disk | Where-Object { $_.SerialNumber -eq $Using:StagingDiskSerialNumber }}
$DiskNumber = $StagingDisk.Number
$NewUniqueID = [GUID]::NewGuid()
$Commands = "`"SELECT DISK $DiskNumber`"",
        "`"UNIQUEID DISK ID=$NewUniqueID`""
$ScriptBlock = [string]::Join(",",$Commands)
$DiskpartScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock("$ScriptBlock | DISKPART")



# Issue resignature commands
Invoke-Command -Session $StagingServerSession -ScriptBlock $DiskpartScriptBlock



# Prepare target VM
$TargetVMHostSession = New-PSSession -ComputerName $TargetVMHost -Credential $Credential



# Remove SQL Server cluster resource dependency on database volume (not applicable in this example)
# Invoke-Command -Session $TargetVMHostSession -ScriptBlock { Get-ClusterResource 'SQL Server' | Remove-ClusterResourceDependency $TargetVolumeName }



# Stop the disk cluster resource
# NOTE: need to know which Cluster Disk Number first
Invoke-Command -Session $TargetVMHostSession -ScriptBlock { Stop-ClusterResource $Using:TargetClusterDiskNumber }



# Verify
Invoke-Command -Session $TargetVMHostSession -ScriptBlock { Get-ClusterSharedVolume $Using:TargetClusterDiskNumber }



# Clone the staging CSV to the target CSV
New-Pfa2Volume -Array $FlashArray -Name $TargetVolumeName -SourceName $StagingVolumeName -Overwrite $true



# Start the disk cluster resource
Invoke-Command -Session $TargetVMHostSession -ScriptBlock { Start-ClusterResource $Using:TargetClusterDiskNumber }



# Verify
Invoke-Command -Session $TargetVMHostSession -ScriptBlock { Get-ClusterSharedVolume $Using:TargetClusterDiskNumber }
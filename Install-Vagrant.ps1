
Function Install-Vagrant {

    <#
    .SYNOPSIS
    Prepares a Windows-based system for Vagrant.

    .DESCRIPTION
    Downloads and installs Vagrant via OneGet and Cygwin via BitsTranfer. Modifies the
    Vagrant SSH configuration files to remove incompatibilities. Installs Virtualbox 
    Guest Additions via Vagrant plugin. Installs Cygwin via BitsTransfer and adds SSH
    and Rsync components. Adds and prioritizes Cygwin's SSH and Rsync binaries in the
    system path. Does not make any assumptions about chosen provider.

    .PARAMETER CygwinInstallPath
    The location to which Cygwin will be installed.

    .PARAMETER SkipCygwinInstall
    Skip the Cygwin install. Use this if another utility is being used for SSH and Rsync.

    .PARAMETER LogLocation
    The location to which the install log will be written.

    .EXAMPLE
    Install-Vagrant
    
    .EXAMPLE
    Install-Vagrant -CygwinInstallPath C:\Tools\Cygwin -LogLocation C:\Mylogs\vagrant_install.log

    #>

    [CmdletBinding()]
    param(

        [Parameter()]
        [string]$CygwinInstallPath =  "C:\cygwin",

        [Parameter()]
        [string]$LogLocation = "vagrant_install.log",

        [Parameter()]
        [switch]$SkipCygwinInstall

    )

    $vagrant_version = "1.8.6"
    # install vagrant
    Write-Log("Installing vagrant $($vagrant_version) via OneGet -- WMF/PowerShell 5.0 or greater required!") -Verbose
    Install-Package -ProviderName Chocolatey -Name vagrant -RequiredVersion $vagrant_version -Force -ForceBootstrap -Verbose

    # get vagrant version for later use
    Write-Log("Grabbing Vagrant version...") -Verbose
    $vagrant_version = (gp HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | ? {$_.DisplayName -eq 'Vagrant' }).DisplayVersion
    Write-Log("The detected version of Vagrant is $($vagrant_version)") -Verbose

    #check for virtualbox install
    $vb_installed = (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  ? {$_.DisplayName -like "Oracle VM VirtualBox*"})
    if ($vb_installed) {
        #install guest additions
        Write-Log("Virtualbox detected -- installing Virtualbox Guest Editions") -Verbose
        &C:\HashiCorp\Vagrant\bin\vagrant.exe plugin install vagrant-vbguest
        $hyper_v_enabled = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State
        if ($hyper_v_enabled -eq "True") {
            Write-Warning -Message "Hyper-V is enabled on this host -- This is known to cause serious issues with Virtualbox and can result in fatal errors on the host system"
        }

    }
    else {
        Write-Log("Virtualbox not detected -- Skipping Virtualbox Guest Additions install") -Verbose
    }

    if (!$SkipCygwinInstall){
        #install cygwin
        Start-BitsTransfer -Source https://cygwin.com/setup-x86.exe -Destination .\cygwin-setup.exe

        Write-Log("Using the installer $($CygwinDownloadPath) and installing to $($CygwinInstallPath)") -Verbose
        &.\cygwin-setup.exe -N -n -d --root $CygwinInstallPath --quiet-mode -X -A --site http://cygwin.mirror.constant.com --packages openssh,rsync
        while($true) { 
            if (Get-Process cygwin-setup -ErrorAction SilentlyContinue) { 
                break; 
            } 
            else { 
            Start-Sleep 5
            } 
        }
        
        # add cygwin to path and move to higher priority (to trump git or other ssh/rsync executables)
        $cygwin_executables ="$($CygwinInstallPath)\bin;"
        Write-Log ("Modifying path to add $($cygwin_executables)") -Verbose
        $Reg = "Registry::HKLM\System\CurrentControlSet\Control\Session Manager\Environment"
        $OldPath = (Get-ItemProperty -Path "$Reg" -Name PATH).Path
        if ($OldPath.Contains($cygwin_executables)) {
            Write-Log("Cygwin was already found in the path. Removing the entry to avoid duplicates.") -Verbose
            $OldPath = $OldPath.Replace("$($cygwin_executables)","")
        }
        $NewPath= $cygwin_executables + $OldPath
        Write-Log (" Adding $($CygwinInstallPath)\bin to top of system path") -Verbose
        Set-ItemProperty -Path "$Reg" -Name PATH –Value $NewPath
    }

    Write-Log("======= A restart is required to finish the installation =======") -Verbose

}

Function Write-Log {
    [CmdletBinding()]
    Param (
        [string]$Message
    )
    $LogTime = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
    ac -Path $LogLocation -Value "$($LogTime): $($Message)" 
    Write-Verbose -Message $Message
}

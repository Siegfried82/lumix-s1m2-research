# S5 BLE pairing tool (Windows PowerShell 5.1 + WinRT)
#
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File s5_ble_pair.ps1 -Action list
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File s5_ble_pair.ps1 -Action pair
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File s5_ble_pair.ps1 -Action watch -Minutes 30
#
# This is the step macOS CoreBluetooth could NOT do (see reports 14/15): explicit
# system-level bonding, so the camera stops dropping the link on the first attribute read.

param(
    [ValidateSet('list', 'pair', 'watch', 'unpair')]
    [string]$Action = 'list',
    [string]$Name = '<CAMERA_SSID>',
    [int]$Minutes = 30
)

$ErrorActionPreference = 'Continue'

Add-Type -AssemblyName System.Runtime.WindowsRuntime
$asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
        $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]

function Await($op, $type) {
    $m = $asTaskGeneric.MakeGenericMethod($type)
    $task = $m.Invoke($null, @($op))
    $task.Wait(-1) | Out-Null
    $task.Result
}

[Windows.Devices.Enumeration.DeviceInformation, Windows.Devices.Enumeration, ContentType = WindowsRuntime] | Out-Null
[Windows.Devices.Enumeration.DeviceInformationCollection, Windows.Devices.Enumeration, ContentType = WindowsRuntime] | Out-Null
[Windows.Devices.Enumeration.DevicePairingKinds, Windows.Devices.Enumeration, ContentType = WindowsRuntime] | Out-Null
[Windows.Devices.Enumeration.DevicePairingProtectionLevel, Windows.Devices.Enumeration, ContentType = WindowsRuntime] | Out-Null
[Windows.Devices.Enumeration.DevicePairingResult, Windows.Devices.Enumeration, ContentType = WindowsRuntime] | Out-Null
[Windows.Devices.Enumeration.DevicePairingResultStatus, Windows.Devices.Enumeration, ContentType = WindowsRuntime] | Out-Null
[Windows.Devices.Bluetooth.BluetoothLEDevice, Windows.Devices.Bluetooth, ContentType = WindowsRuntime] | Out-Null

$COLL = [Windows.Devices.Enumeration.DeviceInformationCollection]

function Get-BleDevices([bool]$paired) {
    $sel = [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromPairingState($paired)
    $op = [Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($sel)
    return Await $op $COLL
}

function Find-Camera {
    foreach ($state in @($false, $true)) {
        $devs = Get-BleDevices $state
        foreach ($d in $devs) {
            if ($d.Name -like "*$Name*") { return $d }
        }
    }
    return $null
}

function Show-Devices {
    foreach ($state in @($false, $true)) {
        Write-Output "--- pairing state: $state ---"
        $devs = Get-BleDevices $state
        Write-Output ("  count = {0}" -f $devs.Count)
        foreach ($d in $devs) {
            $p = $d.Pairing
            Write-Output ("  name='{0}'  paired={1} canPair={2}  id={3}" -f $d.Name, $p.IsPaired, $p.CanPair, $d.Id)
        }
    }
}

function Do-Pair($dev) {
    $p = $dev.Pairing
    Write-Output ("[*] target: name='{0}' IsPaired={1} CanPair={2}" -f $dev.Name, $p.IsPaired, $p.CanPair)
    if ($p.IsPaired) { Write-Output '[=] already paired - nothing to do'; return $true }
    if (-not $p.CanPair) { Write-Output '[!] CanPair = false - attempting anyway (WinRT may still allow it)' }

    $custom = $p.Custom
    $kinds = [Windows.Devices.Enumeration.DevicePairingKinds]::ConfirmOnly -bor `
             [Windows.Devices.Enumeration.DevicePairingKinds]::DisplayPin -bor `
             [Windows.Devices.Enumeration.DevicePairingKinds]::ConfirmPinMatch
    $script:lastPin = ''

    $handler = {
        param($sender, $args)
        $k = $args.PairingKind
        Write-Output ("    [pairing-request] kind=$k")
        try {
            if ($k -eq [Windows.Devices.Enumeration.DevicePairingKinds]::ProvidePin) {
                Write-Output '    [!] camera wants US to provide a PIN - we have none; declining'
                return
            }
            if ($k -eq [Windows.Devices.Enumeration.DevicePairingKinds]::DisplayPin) {
                Write-Output '    [i] PIN shown by camera; pressing accept...'
            }
            $args.Accept()
            Write-Output '    [+] Accept() sent'
        }
        catch {
            Write-Output ("    [!] Accept failed: {0}" -f $_.Exception.Message)
        }
    }
    $custom.add_PairingRequested($handler)

    foreach ($lvl in @('Encryption', 'Default')) {
        Write-Output ("[*] PairAsync(kinds=$kinds, protection=$lvl) ...")
        try {
            $op = $custom.PairAsync($kinds, [Windows.Devices.Enumeration.DevicePairingProtectionLevel]::$lvl)
            $res = Await $op ([Windows.Devices.Enumeration.DevicePairingResult])
            Write-Output ("[=] result: Status={0}  ProtectionLevelUsed={1}" -f $res.Status, $res.ProtectionLevelUsed)
            if ($res.Status -eq [Windows.Devices.Enumeration.DevicePairingResultStatus]::Paired) {
                Write-Output '[+] PAIRED OK'
                return $true
            }
        }
        catch {
            Write-Output ("[!] PairAsync threw: {0}" -f $_.Exception.Message)
        }
    }
    return $false
}

switch ($Action) {
    'list' { Show-Devices }
    'unpair' {
        $d = Find-Camera
        if (-not $d) { Write-Output '[!] camera not found in device list'; break }
        Write-Output ("[*] unpairing {0} ..." -f $d.Name)
        $op = $d.Pairing.UnpairAsync()
        $res = Await $op ([Windows.Devices.Enumeration.DevicePairingResult])
        Write-Output ("[=] unpair status = {0}" -f $res.Status)
    }
    'pair' {
        $d = Find-Camera
        if (-not $d) { Write-Output '[!] camera not found (is its Bluetooth advertising?)'; Show-Devices; break }
        Do-Pair $d | Out-Null
    }
    'watch' {
        $deadline = (Get-Date).AddMinutes($Minutes)
        Write-Output ("=== watch: looking for '{0}' for {1} min ===" -f $Name, $Minutes)
        while ((Get-Date) -lt $deadline) {
            $d = Find-Camera
            if ($d) {
                Write-Output ("[{0:HH:mm:ss}] found {1}" -f (Get-Date), $d.Name)
                if (Do-Pair $d) { Write-Output '### PAIRED - exiting watch'; break }
            }
            else {
                Write-Output ("[{0:HH:mm:ss}] not advertising yet" -f (Get-Date))
            }
            Start-Sleep -Seconds 10
        }
    }
}

param(
  [string]$Action = 'dump',
  [string]$SsidText = '<CAMERA_SSID>',
  [string]$BssidText = ''
)

$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public static class WlanApi
{
    [StructLayout(LayoutKind.Sequential)]
    public struct DOT11_SSID {
        public uint uSSIDLength;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst=32)] public byte[] ucSSID;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct WLAN_BSS_ENTRY {
        public uint uSSIDLength;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst=32)] public byte[] ucSSID;
        public uint uPhyId;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst=6)] public byte[] dot11Bssid;
        public uint dot11BssType;
        public uint dot11BssPhyType;
        public int lRssi;
        public uint uLinkQuality;
        public byte bInRegDomain;
        public ushort usBeaconPeriod;
        public ulong ullTimestamp;
        public ulong ullHostTimestamp;
        public ushort usCapabilityInformation;
        public uint ulChCenterFrequency;
        public uint uRateSetLength;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst=126)] public ushort[] usRateSet;
        public uint ulIeOffset;
        public uint ulIeSize;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct WLAN_INTERFACE_INFO {
        public Guid InterfaceGuid;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=256)] public string strInterfaceDescription;
        public uint isState;
    }

    [DllImport("wlanapi.dll")]
    public static extern uint WlanOpenHandle(uint dwClientVersion, IntPtr pReserved, out uint pdwNegotiatedVersion, out IntPtr phClientHandle);

    [DllImport("wlanapi.dll")]
    public static extern uint WlanCloseHandle(IntPtr hClientHandle, IntPtr pReserved);

    [DllImport("wlanapi.dll")]
    public static extern uint WlanEnumInterfaces(IntPtr hClientHandle, IntPtr pReserved, out IntPtr ppInterfaceList);

    [DllImport("wlanapi.dll")]
    public static extern uint WlanScan(IntPtr hClientHandle, ref Guid pInterfaceGuid, IntPtr pDot11Ssid, IntPtr pIeData, IntPtr pReserved);

    [DllImport("wlanapi.dll")]
    public static extern uint WlanGetNetworkBssList(IntPtr hClientHandle, ref Guid pInterfaceGuid, IntPtr pDot11Ssid,
        uint dot11BssType, bool bSecurityEnabled, IntPtr pReserved, out IntPtr ppWlanBssList);

    [DllImport("wlanapi.dll")]
    public static extern void WlanFreeMemory(IntPtr pMemory);

    [DllImport("wlanapi.dll")]
    public static extern uint WlanConnect(IntPtr hClientHandle, ref Guid pInterfaceGuid, ref WLAN_CONNECTION_PARAMETERS pConnectionParameters, IntPtr pReserved);

    [DllImport("wlanapi.dll")]
    public static extern uint WlanDisconnect(IntPtr hClientHandle, ref Guid pInterfaceGuid, IntPtr pReserved);

    [StructLayout(LayoutKind.Sequential)]
    public struct WLAN_CONNECTION_PARAMETERS {
        public uint wlanConnectionMode;
        [MarshalAs(UnmanagedType.LPWStr)] public string strProfile;
        public IntPtr pDot11Ssid;
        public IntPtr pDesiredBssidList;
        public uint dot11BssType;
        public uint dwFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DOT11_BSSID_LIST {
        public uint HeaderType;
        public uint uNumOfEntries;
        public uint uTotalNumOfEntries;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst=6)] public byte[] BSSIDs;
    }

    [DllImport("wlanapi.dll")]
    public static extern uint WlanQueryInterface(IntPtr hClientHandle, ref Guid pInterfaceGuid, uint OpCode,
        IntPtr pReserved, out uint pdwDataSize, out IntPtr ppData, out uint pWlanOpcodeValueType);
}
'@

function Get-Ifaces {
    $ver = 0; $handle = [IntPtr]::Zero
    $rc = [WlanApi]::WlanOpenHandle(2, [IntPtr]::Zero, [ref]$ver, [ref]$handle)
    if ($rc -ne 0) { throw "WlanOpenHandle failed rc=$rc" }
    $listPtr = [IntPtr]::Zero
    $rc = [WlanApi]::WlanEnumInterfaces($handle, [IntPtr]::Zero, [ref]$listPtr)
    if ($rc -ne 0) { throw "WlanEnumInterfaces failed rc=$rc" }
    $count = [Runtime.InteropServices.Marshal]::ReadInt32($listPtr)
    $entrySize = [Runtime.InteropServices.Marshal]::SizeOf([type][WlanApi+WLAN_INTERFACE_INFO])
    $list = @()
    for ($i = 0; $i -lt $count; $i++) {
        $p = [IntPtr]($listPtr.ToInt64() + 8 + $i * $entrySize)
        $info = [Runtime.InteropServices.Marshal]::PtrToStructure($p, [type][WlanApi+WLAN_INTERFACE_INFO])
        $list += $info
    }
    return @{ Handle = $handle; ListPtr = $listPtr; Ifaces = $list }
}

if ($Action -eq 'dump' -or $Action -eq 'connect') {
    $ctx = Get-Ifaces
    Write-Output "negotiated ifaces: $($ctx.Ifaces.Count)"
    foreach ($iface in $ctx.Ifaces) { Write-Output ("  IF: {0}  {1}" -f $iface.InterfaceGuid, $iface.strInterfaceDescription) }

    $iface = $ctx.Ifaces | Where-Object { $_.strInterfaceDescription -like '*Wi-Fi*' -or $_.strInterfaceDescription -like '*Wireless*' } | Select-Object -First 1
    if (-not $iface) { $iface = $ctx.Ifaces[0] }
    $guid = $iface.InterfaceGuid
    Write-Output "using IF: $guid"

    $rc = [WlanApi]::WlanScan($ctx.Handle, [ref]$guid, [IntPtr]::Zero, [IntPtr]::Zero, [IntPtr]::Zero)
    Write-Output "WlanScan rc=$rc"
    Start-Sleep -Seconds 7

    $bssPtr = [IntPtr]::Zero
    $rc = [WlanApi]::WlanGetNetworkBssList($ctx.Handle, [ref]$guid, [IntPtr]::Zero, 3, $false, [IntPtr]::Zero, [ref]$bssPtr)
    Write-Output "WlanGetNetworkBssList rc=$rc"
    if ($rc -ne 0) { throw "BSS list failed rc=$rc" }

    $total = [Runtime.InteropServices.Marshal]::ReadInt32($bssPtr)
    $n = [Runtime.InteropServices.Marshal]::ReadInt32([IntPtr]($bssPtr.ToInt64() + 4))
    $structSize = [Runtime.InteropServices.Marshal]::SizeOf([type][WlanApi+WLAN_BSS_ENTRY])
    Write-Output "totalSize=$total entries=$n structSize=$structSize"
    $base = $bssPtr.ToInt64() + 8

    $found = @()
    for ($i = 0; $i -lt $n; $i++) {
        $p = [IntPtr]($base + $i * $structSize)
        $e = [Runtime.InteropServices.Marshal]::PtrToStructure($p, [type][WlanApi+WLAN_BSS_ENTRY])
        if ($e.uSSIDLength -gt 32) { continue }
        $ssid = [System.Text.Encoding]::UTF8.GetString($e.ucSSID, 0, [int]$e.uSSIDLength)
        $ssidHex = ($e.ucSSID[0..([int]$e.uSSIDLength-1)] | ForEach-Object { $_.ToString('x2') }) -join ' '
        $bssid = ($e.dot11Bssid | ForEach-Object { $_.ToString('x2') }) -join ':'
        $ieStart = [IntPtr]($p.ToInt64() + [int]$e.ulIeOffset)
        $ie = New-Object byte[] ([int]$e.ulIeSize)
        if ($e.ulIeSize -gt 0 -and $e.ulIeSize -lt 4096) {
            try { [Runtime.InteropServices.Marshal]::Copy($ieStart, $ie, 0, [int]$e.ulIeSize) } catch { $ie = @() }
        }
        $ieHex = ($ie | ForEach-Object { $_.ToString('x2') }) -join ''
        $obj = [pscustomobject]@{
            SSID = $ssid; SsidHex = $ssidHex; Len = $e.uSSIDLength; Bssid = $bssid
            Rssi = $e.lRssi; LinkQ = $e.uLinkQuality; Chan = [int]($e.ulChCenterFrequency / 1000)
            Cap = ('0x{0:x4}' -f $e.usCapabilityInformation); Beacon = $e.usBeaconPeriod
            PhyType = $e.dot11BssPhyType; SsidLen = $e.uSSIDLength; IeHex = $ieHex
        }
        if ($ssid -like '*S5*' -or $ssid -like '*Panasonic*' -or $ssid -like '*LUMIX*') { $found += $obj }
    }

    Write-Output ''
    Write-Output '=== CAMERA CANDIDATE BSS ENTRIES ==='
    foreach ($f in $found) {
        Write-Output ("SSID='{0}' len={1} ssidHex=[{2}]" -f $f.SSID, $f.Len, $f.SsidHex)
        Write-Output ("   BSSID={0} rssi={1} linkQ={2} chan={3} cap={4} beacon={5} phy={6}" -f $f.Bssid, $f.Rssi, $f.LinkQ, $f.Chan, $f.Cap, $f.Beacon, $f.PhyType)
        Write-Output ("   IEhex={0}" -f $f.IeHex)
        Write-Output ''
    }
    if ($found.Count -eq 0) { Write-Output '(no S5/Panasonic SSID matched; dumping all SSIDs)' ; }

    if ($Action -eq 'connect') {
        $ssidBytes = [System.Text.Encoding]::UTF8.GetBytes($SsidText)
        Write-Output ("=== CONNECT tests for '{0}' bytes=[{1}] ===" -f $SsidText, (($ssidBytes | ForEach-Object { $_.ToString('x2') }) -join ' '))

        $ssidPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal(36)
        [Runtime.InteropServices.Marshal]::WriteInt32($ssidPtr, $ssidBytes.Length)
        [Runtime.InteropServices.Marshal]::Copy($ssidBytes, 0, [IntPtr]($ssidPtr.ToInt64() + 4), $ssidBytes.Length)

        $bssidPtr = [IntPtr]::Zero
        $bssidPtr2 = [IntPtr]::Zero
        if ($BssidText -ne '') {
            $parts = $BssidText -split '[:-]'
            $bb = $parts | ForEach-Object { [Convert]::ToByte($_, 16) }
            $bssidPtr = [Runtime.InteropServices.Marshal]::AllocHGlobal(8 + 6)
            [Runtime.InteropServices.Marshal]::WriteInt32($bssidPtr, 3)          # DOT11_BSSID_LIST_REVISION
            [Runtime.InteropServices.Marshal]::WriteInt32([IntPtr]($bssidPtr.ToInt64() + 4), 1)
            [Runtime.InteropServices.Marshal]::WriteInt32([IntPtr]($bssidPtr.ToInt64() + 8), 1)
            [Runtime.InteropServices.Marshal]::Copy($bb, 0, [IntPtr]($bssidPtr.ToInt64() + 12), 6)
            $bssidPtr2 = $bssidPtr
        }

        $variants = @(
            @{ Name = 'profile(0) no-bssid';       Mode = 0; Bssid = [IntPtr]::Zero },
            @{ Name = 'profile(0) +bssid';          Mode = 0; Bssid = $bssidPtr2 },
            @{ Name = 'disc_unsecure(3) +bssid';    Mode = 3; Bssid = $bssidPtr2 },
            @{ Name = 'disc_unsecure(3) no-bssid';  Mode = 3; Bssid = [IntPtr]::Zero },
            @{ Name = 'temporary_profile(1)';       Mode = 1; Bssid = [IntPtr]::Zero }
        )

        foreach ($v in $variants) {
            Write-Output ''
            Write-Output ("--- variant: {0} ---" -f $v.Name)
            [WlanApi]::WlanDisconnect($ctx.Handle, [ref]$guid, [IntPtr]::Zero) | Out-Null
            Start-Sleep -Seconds 2
            $cp = New-Object WlanApi+WLAN_CONNECTION_PARAMETERS
            $cp.wlanConnectionMode = $v.Mode
            $cp.strProfile = $SsidText
            $cp.pDot11Ssid = $ssidPtr
            $cp.pDesiredBssidList = $v.Bssid
            $cp.dot11BssType = 1
            $cp.dwFlags = 0
            $rc = [WlanApi]::WlanConnect($ctx.Handle, [ref]$guid, [ref]$cp, [IntPtr]::Zero)
            Write-Output ("WlanConnect rc={0}" -f $rc)
            $ok = $false
            for ($k = 1; $k -le 14; $k++) {
                Start-Sleep -Seconds 1
                $st = (netsh wlan show interfaces) -join "`n"
                if ($st -match 'State\s+:\s+connected') { Write-Output ("CONNECTED after {0}s" -f $k); $ok = $true; break }
            }
            if (-not $ok) { Write-Output 'result: NOT connected after 14s' } else { break }
        }

        Write-Output ''
        Write-Output '--- final interface state ---'
        netsh wlan show interfaces | Out-String -Width 200
    }
}

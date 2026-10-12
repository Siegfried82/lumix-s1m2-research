# Lumix S1RM2 / S1M2 (Linux 4.19.124) QEMU Sandbox Launcher (Windows PowerShell)
# Usage:
#   .\run_qemu.ps1           # Boot into sbox REPL (type 'sh' for BusyBox shell)
#   .\run_qemu.ps1 -Shell    # Boot directly into BusyBox /bin/sh shell
#   .\run_qemu.ps1 -Gdb      # Boot with GDB stub on tcp::1234 (-s -S)

param(
    [switch]$Shell,
    [switch]$Gdb
)

$Sbx = Split-Path -Parent $MyInvocation.MyCommand.Path
$Kernel = Join-Path $Sbx "Image"
$Initrd = Join-Path $Sbx "initramfs.cpio.gz"

$Cmdline = "console=ttyAMA0 init=/init loglevel=7"
if ($Shell) {
    $Cmdline += " sbox.shell=1"
}

$QemuArgs = @(
    "-M", "virt",
    "-cpu", "cortex-a53",
    "-smp", "1",
    "-m", "1024",
    "-kernel", $Kernel,
    "-initrd", $Initrd,
    "-append", $Cmdline,
    "-nographic"
)

if ($Gdb) {
    $QemuArgs += @("-s", "-S")
    Write-Host "GDB server listening on tcp::1234"
}

& qemu-system-aarch64 @QemuArgs

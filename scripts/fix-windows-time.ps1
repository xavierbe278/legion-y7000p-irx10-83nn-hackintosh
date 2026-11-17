<#
    修复 Windows / macOS 双系统时间相差 8 小时（时区差）
    原理：macOS 把硬件时钟(RTC)当 UTC 存；Windows 默认当本地时间存。
          让 Windows 也按 UTC 读，两边就一致了。
    用法（管理员 PowerShell）：.\fix-windows-time.ps1
#>
$ErrorActionPreference = 'Stop'
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning '请用管理员 PowerShell 运行'
    exit 1
}
$k = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'

Write-Host '1. 让 Windows 按 UTC 读硬件时钟 ...'
New-ItemProperty -Path $k -Name RealTimeIsUniversal -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host '2. 关闭快速启动（否则该设置可能不生效）...'
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name HiberbootEnabled -Value 0 -Force

Write-Host '3. 启动并配置时间服务 ...'
Set-Service -Name w32time -StartupType Automatic -ErrorAction SilentlyContinue
Start-Service w32time -ErrorAction SilentlyContinue
& w32tm /config /manualpeerlist:"ntp.aliyun.com,0x8 cn.pool.ntp.org,0x8 time.windows.com,0x8" /syncfromflags:manual /reliable:yes /update | Out-Null
& w32tm /resync /force 2>&1 | Out-Null

Write-Host ''
Write-Host ('本地时间 ：' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Host ('对应 UTC ：' + (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))
Write-Host ''
Write-Host '完成。首次设置后若时间仍偏 8 小时，重启一次即可（Windows 会在关机时把 UTC 写回硬件时钟）。'
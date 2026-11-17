<#
    在 Windows 下挂载/写入 OpenCore EFI 分区的辅助脚本
    用法（管理员 PowerShell）：
        .\esp-helper.ps1 mount
        .\esp-helper.ps1 write .\final-config.plist
        .\esp-helper.ps1 dump  .\backup-config.plist
        .\esp-helper.ps1 unmount
#>
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet('mount','unmount','write','dump','list')]
    [string]$Action,
    [Parameter(Position=1)][string]$Path
)
$ErrorActionPreference = 'Stop'
$Letter = 'S'

function Invoke-Diskpart([string]$script){
    $tmp = Join-Path $env:TEMP ("dp_" + [guid]::NewGuid().ToString('N') + ".txt")
    Set-Content -Path $tmp -Value $script -Encoding ASCII
    & diskpart /s $tmp | Out-Null
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
}
function Mount-Esp { Invoke-Diskpart "select disk 1`r`nselect partition 1`r`nassign letter=$Letter`r`nexit`r`n"; Start-Sleep -Seconds 2 }
function Dismount-Esp { Invoke-Diskpart "select disk 1`r`nselect partition 1`r`nremove letter=$Letter`r`nexit`r`n" }
function Get-Cfg { Join-Path "${Letter}:" 'EFI\OC\config.plist' }

switch($Action){
    'mount'   { Mount-Esp; Write-Host "已挂载: ${Letter}:\EFI\OC" }
    'unmount' { Dismount-Esp; Write-Host "已卸载 ${Letter}:" }
    'list'    { Mount-Esp; Get-ChildItem "${Letter}:\EFI\OC" | Format-Table Name,Length; Dismount-Esp }
    'write'   {
        if(-not $Path -or -not (Test-Path $Path)){ throw "用法: .\esp-helper.ps1 write <config.plist>" }
        Mount-Esp
        $cfg = Get-Cfg
        Copy-Item $cfg ("$cfg.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')) -Force
        Copy-Item $Path $cfg -Force
        $ok = (Get-FileHash $Path).Hash -eq (Get-FileHash $cfg).Hash
        Dismount-Esp
        Write-Host ("写入完成，校验: " + $(if($ok){'一致'}else{'不一致!'}))
    }
    'dump'    {
        if(-not $Path){ $Path = ".\config-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').plist" }
        Mount-Esp; Copy-Item (Get-Cfg) $Path -Force; Dismount-Esp
        Write-Host "已导出: $Path"
    }
}
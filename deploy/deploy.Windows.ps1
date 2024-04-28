#Requires -Version 7

#@ prepare
#@ .Argument
param(
    [Alias("d")]
    [ValidateSet("setenv+")]
    [string]$deploy_mode = "setenv+",
    [Alias("b")]
    [string]$bindarypath
)


#@ .pre-check
if ($IsLinux) {
    Write-Error "This init script can only be used in Windows, please use init.Linux.sh, either" -ErrorAction Stop
}
python --version > $null
if (-not $?) {
    Write-Error "Cannot find python command" -ErrorAction Stop
}

#@ Main
Set-Location $PSScriptRoot

#@ .link-executable
if ($bindarypath) {
    if (-not (Test-Path $bindarypath)) {
        write-error "arg:binarypath must be an existed directory" -ErrorAction Stop
    }
    Get-ChildItem $PSScriptRoot/../bin | ForEach-Object {
        if ($_.Name.EndsWith(".sh")) {
            continue
        }
        New-Item -ItemType SymbolicLink -Target ($_.FullName) -Path "$bindarypath/$($_.Name)" -Force
    }
} 
else {
    New-Item -ItemType Directory -Path export.Windows/bin -Force
    Get-ChildItem $PSScriptRoot/../bin | ForEach-Object {
        if ($_.Name.EndsWith(".sh") -or $_.Name.EndsWith(".csh")) {
            return
        }
        # Write-Output "export.Windows/bin/$($_.Name)"
        Write-Output "New-Item -ItemType SymbolicLink -Target $($_.FullName) -Path export.Windows/bin/$($_.Name) -Force"
        New-Item -ItemType SymbolicLink -Target ($_.FullName) -Path "export.Windows/bin/$($_.Name)" -Force
    }

    @"
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> [rdee-core]
`$env:PATH = "$PSScriptRoot\export.Windows\bin;" + `$env:PATH

"@ | Set-Content .temp

    python $PSScriptRoot/../bin/fileop.ra-block.py $profile.CurrentUserAllHosts .temp
    Remove-Item .temp -Force
}

function Test-AdbDevice([string]$Device) {
    $list = & adb.exe devices 2>&1 | Out-String
    return $list -match [regex]::Escape($Device) -and $list -match "${Device}\s+device"
}

function Invoke-AdbDevice {
    param(
        [string]$Device,
        [Parameter(ValueFromRemainingArguments = $true)][string[]]$Cmd
    )
    & adb.exe -s $Device @Cmd
}

function Start-AdbDeepLink {
    param(
        [string]$Device,
        [string]$Package,
        [string]$Path
    )
    $uri = "adminarawatan://adminarawatan.com$Path"
    & adb.exe -s $Device shell am start `
        -a android.intent.action.VIEW `
        -d $uri `
        -n "$Package/.MainActivity" 2>&1 | Out-Null
}

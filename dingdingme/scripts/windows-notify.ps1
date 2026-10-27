param(
    [string]$Title = 'Codex',
    [string]$Message = 'This Codex turn is complete.',
    [string]$SoundPath
)

$ErrorActionPreference = 'Stop'
$notificationError = $null
$audioError = $null

if (-not $SoundPath) {
    $SoundPath = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\assets\sounds\ring.mp3'))
}

try {
    $null = [Windows.Data.Xml.Dom.XmlDocument,Windows.Data.Xml.Dom.XmlDocument,ContentType=WindowsRuntime]
    $null = [Windows.UI.Notifications.ToastNotification,Windows.UI.Notifications,ContentType=WindowsRuntime]
    $null = [Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime]

    $safeTitle = [System.Security.SecurityElement]::Escape($Title)
    $safeMessage = [System.Security.SecurityElement]::Escape($Message)
    $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>$safeTitle</text><text>$safeMessage</text></binding></visual></toast>")
    $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
    $toast.Priority = [Windows.UI.Notifications.ToastNotificationPriority]::High

    $appId = $null
    try {
        $appId = Get-StartApps | Where-Object { $_.Name -eq 'ChatGPT' } | Select-Object -First 1 -ExpandProperty AppID
    } catch {}
    if (-not $appId) {
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    }

    $notifier = [Windows.UI.Notifications.ToastNotificationManager,Windows.UI.Notifications,ContentType=WindowsRuntime]::CreateToastNotifier($appId)
    $notifier.Show($toast)
} catch {
    $notificationError = $_.Exception.Message
}

try {
    if (-not (Test-Path -LiteralPath $SoundPath)) {
        throw "Sound file not found: $SoundPath"
    }

    if (-not ('DingDingMci' -as [type])) {
        $null = Add-Type @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class DingDingMci {
    [DllImport("winmm.dll", CharSet = CharSet.Unicode)]
    public static extern int mciSendString(string command, StringBuilder result, int length, IntPtr callback);
}
'@
    }

    $openResult = [DingDingMci]::mciSendString(('open "{0}" type mpegvideo alias dingdingring' -f $SoundPath), $null, 0, [IntPtr]::Zero)
    if ($openResult -ne 0) {
        throw "Windows could not open the MP3 (MCI error $openResult)."
    }
    try {
        $playResult = [DingDingMci]::mciSendString('play dingdingring wait', $null, 0, [IntPtr]::Zero)
        if ($playResult -ne 0) {
            throw "Windows could not play the MP3 (MCI error $playResult)."
        }
    } finally {
        [void][DingDingMci]::mciSendString('close dingdingring', $null, 0, [IntPtr]::Zero)
    }
} catch {
    $audioError = $_.Exception.Message
}

if ($notificationError) {
    [Console]::Error.WriteLine("Windows notification failed: $notificationError")
}
if ($audioError) {
    [Console]::Error.WriteLine("Stop sound failed: $audioError")
}
if ($notificationError -or $audioError) {
    exit 1
}

# A successful Stop hook must return valid JSON on stdout.
[Console]::Out.WriteLine('{}')

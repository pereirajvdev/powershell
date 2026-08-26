Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Win32 {
    [DllImport("user32.dll")] public static extern bool SetWindowPos(
        IntPtr hWnd, IntPtr hWndInsertAfter,
        int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")] public static extern bool ShowWindow(
        IntPtr hWnd, int nCmdShow);
}
"@

Add-Type -AssemblyName System.Windows.Forms

$paths = @(
    "local 1",
    "local 2",
    "local 3"
)

# Abre as três pastas em janelas separadas.
foreach ($p in $paths) {
    Start-Process explorer.exe -ArgumentList "`"$p`""
    Start-Sleep -Milliseconds 400
}

# Aguarda as janelas aparecerem e localiza cada uma pelo caminho real.
$windows = $null
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 300
    $shell = New-Object -ComObject Shell.Application
    $found = @()

    foreach ($w in $shell.Windows()) {
        try {
            if ($w.HWND -and $w.LocationURL) {
                $url = [System.Uri]::UnescapeDataString($w.LocationURL)
                foreach ($p in $paths) {
                    $uriPath = ([System.Uri]::new([System.IO.Path]::GetFullPath($p))).AbsoluteUri
                    if ($w.LocationURL.TrimEnd('/') -ieq $uriPath.TrimEnd('/')) {
                        $found += [PSCustomObject]@{
                            Path = $p
                            Hwnd = [IntPtr]$w.HWND
                        }
                    }
                }
            }
        } catch {}
    }

    if ($found.Count -ge 3) {
        $windows = $found
        break
    }
}

if (-not $windows) {
    exit
}

$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$work = $screen.WorkingArea

$W = $work.Width
$H = $work.Height
$X0 = $work.X
$Y0 = $work.Y

# Três colunas iguais, como na imagem enviada.
$w1 = [int]($W / 3)
$w2 = [int]($W / 3)
$w3 = $W - $w1 - $w2

$positions = @(
    @{ X = $X0;          Y = $Y0; W = $w1; H = $H },
    @{ X = $X0 + $w1;    Y = $Y0; W = $w2; H = $H },
    @{ X = $X0 + $w1+$w2; Y = $Y0; W = $w3; H = $H }
)

# Garante a ordem: Y:, C:, Z:
for ($i = 0; $i -lt 3; $i++) {
    $target = $paths[$i]
    $win = $windows | Where-Object { $_.Path -ieq $target } | Select-Object -First 1

    if ($win) {
        $pos = $positions[$i]
        [Win32]::ShowWindow($win.Hwnd, 9) | Out-Null
        Start-Sleep -Milliseconds 100
        [Win32]::SetWindowPos(
            $win.Hwnd,
            [IntPtr]::Zero,
            $pos.X, $pos.Y, $pos.W, $pos.H,
            0x0040
        ) | Out-Null
    }
}

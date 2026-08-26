Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
"@

# Área útil da tela (desconsidera a barra de tarefas)
Add-Type -AssemblyName System.Windows.Forms
$work = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$W = $work.Width
$H = $work.Height

# Divisão baseada na disposição mostrada pelo usuário:
# Edge: ~34% | Notepad: ~25% | Explorer: restante
$edgeW = [int]($W * 0.34)
$midW  = [int]($W * 0.25)
$explorerX = $edgeW + $midW
$explorerW = $W - $explorerX

$topH = [int]($H * 0.22)
$bottomH = $H - $topH

$desktop = [Environment]::GetFolderPath("Desktop")
$folder = "pasta 1"
$url = "link url"

function Move-Window {
    param(
        [string]$TitlePattern,
        [int]$X, [int]$Y, [int]$Width, [int]$Height,
        [int]$TimeoutSeconds = 15
    )

    $end = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        $windows = Get-Process | Where-Object {
            $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -match $TitlePattern
        }
        if ($windows) {
            $p = $windows | Select-Object -First 1
            [Win32]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
            Start-Sleep -Milliseconds 150
            [Win32]::SetWindowPos($p.MainWindowHandle, [IntPtr]::Zero, $X, $Y, $Width, $Height, 0x0040) | Out-Null
            return $true
        }
        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $end)
    return $false
}

# 1) Abre os dois TXT da Área de Trabalho.
$txt1 = Join-Path $desktop "txt 1"
$txt2 = Join-Path $desktop "txt 2"

if (Test-Path $txt1) { Start-Process notepad.exe -ArgumentList "`"$txt1`"" }
if (Test-Path $txt2) { Start-Process notepad.exe -ArgumentList "`"$txt2`"" }

# 2) Abre o Explorador diretamente na pasta de trabalho.
Start-Process explorer.exe -ArgumentList "`"$folder`""

# 3) Abre o Webmail em uma nova janela do Edge.
$edge = Get-Command msedge.exe -ErrorAction SilentlyContinue
if ($edge) {
    Start-Process $edge.Source -ArgumentList "--new-window `"$url`""
} else {
    Start-Process $url
}

Start-Sleep -Milliseconds 1200

# 4) Posiciona as janelas.
Move-Window "texto email portarias"  $edgeW 0 $midW $topH | Out-Null
Move-Window "emails"                $edgeW $topH $midW $bottomH | Out-Null
Move-Window "Sarh"                  $explorerX 0 $explorerW $H | Out-Null

# O Edge pode demorar mais para carregar o título.
Move-Window "Webmail|SOGo|arquivo\.sarh" 0 0 $edgeW $H 20 | Out-Null

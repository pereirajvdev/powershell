# ============================================================
# ORGANIZADOR DE JANELAS - DIGITALIZADOR / DOCUMENTOS / JOAO
# ============================================================

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    
    [DllImport("user32.dll")]
    public static extern bool MoveWindow(
        IntPtr hWnd,
        int X,
        int Y,
        int nWidth,
        int nHeight,
        bool bRepaint
    );

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(
        IntPtr hWnd,
        int nCmdShow
    );

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(
        IntPtr hWnd
    );
}
"@

Add-Type -AssemblyName System.Windows.Forms

# ============================================================
# CAMINHOS
# ============================================================

$pastaDocumentos = "local da pasta 1"
$pastaJoao       = "local da pasta 2"

# ============================================================
# ABRIR AS DUAS PASTAS
# ============================================================

Start-Process explorer.exe -ArgumentList "`"$pastaDocumentos`""
Start-Process explorer.exe -ArgumentList "`"$pastaJoao`""

# ============================================================
# ABRIR APP
# ============================================================

Start-Process "APP .exe"

# ============================================================
# ESPERAR AS JANELAS APARECEREM
# ============================================================

Start-Sleep -Seconds 2

# ============================================================
# OBTER ÁREA ÚTIL DO MONITOR
#
# WorkingArea exclui:
# - barra de tarefas
# - áreas reservadas pelo Windows
# ============================================================

$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea

$screenX      = $screen.X
$screenY      = $screen.Y
$screenWidth  = $screen.Width
$screenHeight = $screen.Height

# ============================================================
# DIVISÃO EXATA DA TELA
# ============================================================

# Divide a largura total em 3 partes.
# O restante de pixels fica na terceira janela,
# evitando qualquer espaço ou sobreposição.

$largura1 = [math]::Floor($screenWidth / 3)
$largura2 = [math]::Floor($screenWidth / 3)
$largura3 = $screenWidth - $largura1 - $largura2

# ============================================================
# COORDENADAS
# ============================================================

# ESQUERDA
$xDigitalizador = $screenX

# CENTRO
$xDocumentos = $screenX + $largura1

# DIREITA
$xJoao = $screenX + $largura1 + $largura2

# ============================================================
# FUNÇÃO PARA POSICIONAR JANELA
# ============================================================

function Posicionar-Janela {

    param (
        [IntPtr]$Handle,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    if ($Handle -eq [IntPtr]::Zero) {
        return
    }

    # Restaura a janela caso esteja maximizada/minimizada
    [Win32]::ShowWindow(
        $Handle,
        9
    ) | Out-Null

    Start-Sleep -Milliseconds 100

    # Move e redimensiona
    [Win32]::MoveWindow(
        $Handle,
        $X,
        $Y,
        $Width,
        $Height,
        $true
    ) | Out-Null
}

# ============================================================
# LOCALIZAR WINDOWS FAX AND SCAN
# ============================================================

$digitalizador = Get-Process -Name "WFS" -ErrorAction SilentlyContinue |
    Where-Object {
        $_.MainWindowHandle -ne [IntPtr]::Zero
    } |
    Select-Object -First 1

# ============================================================
# LOCALIZAR JANELAS DO EXPLORADOR
# ============================================================

$explorers = Get-Process -Name explorer -ErrorAction SilentlyContinue |
    Where-Object {
        $_.MainWindowHandle -ne [IntPtr]::Zero
    }

$janelaDocumentos = $null
$janelaJoao = $null

# ============================================================
# IDENTIFICAR AS PASTAS PELO TÍTULO DA JANELA
# ============================================================

foreach ($explorer in $explorers) {

    $titulo = $explorer.MainWindowTitle

    if ([string]::IsNullOrWhiteSpace($titulo)) {
        continue
    }

    # DOCUMENTOS DIGITALIZADOS
    if (
        $titulo -like "*Scanned Documents*" -or
        $titulo -like "*Documentos Digitalizados*"
    ) {
        $janelaDocumentos = $explorer
    }

    # JOAO
    if (
        $titulo -eq "JOAO" -or
        $titulo -like "*JOAO*"
    ) {
        $janelaJoao = $explorer
    }
}

# ============================================================
# SE NÃO ENCONTROU AS JANELAS, TENTAR NOVAMENTE
# ============================================================

if (-not $janelaDocumentos -or -not $janelaJoao -or -not $digitalizador) {

    Start-Sleep -Seconds 2

    $explorers = Get-Process -Name explorer -ErrorAction SilentlyContinue |
        Where-Object {
            $_.MainWindowHandle -ne [IntPtr]::Zero
        }

    foreach ($explorer in $explorers) {

        $titulo = $explorer.MainWindowTitle

        if ($titulo -like "*Scanned Documents*" -or
            $titulo -like "*Documentos Digitalizados*") {

            $janelaDocumentos = $explorer
        }

        if ($titulo -eq "JOAO" -or
            $titulo -like "*JOAO*") {

            $janelaJoao = $explorer
        }
    }

    $digitalizador = Get-Process -Name "WFS" -ErrorAction SilentlyContinue |
        Where-Object {
            $_.MainWindowHandle -ne [IntPtr]::Zero
        } |
        Select-Object -First 1
}

# ============================================================
# POSICIONAR DIGITALIZADOR
# ============================================================

if ($digitalizador) {

    Posicionar-Janela `
        -Handle $digitalizador.MainWindowHandle `
        -X $xDigitalizador `
        -Y $screenY `
        -Width $largura1 `
        -Height $screenHeight
}

# ============================================================
# POSICIONAR SCANNED DOCUMENTS
# ============================================================

if ($janelaDocumentos) {

    Posicionar-Janela `
        -Handle $janelaDocumentos.MainWindowHandle `
        -X $xDocumentos `
        -Y $screenY `
        -Width $largura2 `
        -Height $screenHeight
}

# ============================================================
# POSICIONAR JOAO
# ============================================================

if ($janelaJoao) {

    Posicionar-Janela `
        -Handle $janelaJoao.MainWindowHandle `
        -X $xJoao `
        -Y $screenY `
        -Width $largura3 `
        -Height $screenHeight
}

# ============================================================
# FINAL
# ============================================================

Start-Sleep -Milliseconds 300

Write-Host ""
Write-Host "Janelas organizadas."
Write-Host ""
Write-Host "ESQUERDA : Digitalizador"
Write-Host "CENTRO   : Scanned Documents"
Write-Host "DIREITA  : JOAO"
Write-Host ""
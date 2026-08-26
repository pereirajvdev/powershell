Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class Win32 {

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(
        IntPtr hWnd,
        IntPtr hWndInsertAfter,
        int X,
        int Y,
        int cx,
        int cy,
        uint uFlags
    );

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(
        IntPtr hWnd,
        int nCmdShow
    );
}
"@

Add-Type -AssemblyName System.Windows.Forms

# ============================================================
# CONFIGURAÇÃO
# ============================================================

$urlWebmail = "link"

$arquivoTexto = "txt"

$pastaServidores = "pasta"

# ============================================================
# ABRIR WEBMAIL
# ============================================================

Start-Process $urlWebmail

# ============================================================
# ABRIR TXT
# ============================================================

if (Test-Path -LiteralPath $arquivoTexto) {

    Start-Process "notepad.exe" `
        -ArgumentList "`"$arquivoTexto`""
}

# ============================================================
# ABRIR SERVIDORES
# ============================================================

if (Test-Path -LiteralPath $pastaServidores) {

    Start-Process explorer.exe `
        -ArgumentList "`"$pastaServidores`""
}

# ============================================================
# AGUARDAR AS JANELAS
# ============================================================

Start-Sleep -Seconds 3

# ============================================================
# ÁREA ÚTIL DO MONITOR
# ============================================================

$screen = [System.Windows.Forms.Screen]::PrimaryScreen

$work = $screen.WorkingArea

$X0 = $work.X
$Y0 = $work.Y

$W = $work.Width
$H = $work.Height

# ============================================================
# DIVISÃO HORIZONTAL
#
# ESQUERDA = 50%
# DIREITA  = 50%
# ============================================================

$larguraEsquerda = [int]($W / 2)

$larguraDireita = $W - $larguraEsquerda

# ============================================================
# DIVISÃO VERTICAL DA DIREITA
#
# TXT       = 25%
# SERVIDORES = 75%
# ============================================================

$alturaTxt = [int]($H / 4)

$alturaServidores = $H - $alturaTxt

# ============================================================
# LOCALIZAR NOTEPAD
# ============================================================

$notepad = Get-Process notepad -ErrorAction SilentlyContinue |
    Where-Object {
        $_.MainWindowHandle -ne [IntPtr]::Zero
    } |
    Select-Object -Last 1

# ============================================================
# LOCALIZAR JANELA SERVIDORES
# ============================================================

$explorerServidores = $null

$shell = New-Object -ComObject Shell.Application

foreach ($w in $shell.Windows()) {

    try {

        if ($w.HWND -and $w.LocationURL) {

            $uriPath = ([System.Uri]::new(
                [System.IO.Path]::GetFullPath($pastaServidores)
            )).AbsoluteUri

            if (
                $w.LocationURL.TrimEnd('/') -ieq
                $uriPath.TrimEnd('/')
            ) {

                $explorerServidores = [IntPtr]$w.HWND

                break
            }
        }

    }
    catch {
    }
}

# ============================================================
# LOCALIZAR NAVEGADOR
# ============================================================

$browser = Get-Process msedge -ErrorAction SilentlyContinue |
    Where-Object {
        $_.MainWindowHandle -ne [IntPtr]::Zero
    } |
    Select-Object -Last 1

# Se não houver Edge, tenta Chrome
if (-not $browser) {

    $browser = Get-Process chrome -ErrorAction SilentlyContinue |
        Where-Object {
            $_.MainWindowHandle -ne [IntPtr]::Zero
        } |
        Select-Object -Last 1
}

# ============================================================
# WEBMAIL
# ESQUERDA - 50% DA TELA
# ============================================================

if ($browser) {

    [Win32]::ShowWindow(
        $browser.MainWindowHandle,
        9
    ) | Out-Null

    [Win32]::SetWindowPos(
        $browser.MainWindowHandle,
        [IntPtr]::Zero,
        $X0,
        $Y0,
        $larguraEsquerda,
        $H,
        0x0044
    ) | Out-Null
}

# ============================================================
# TXT
# DIREITA - 25% DA ALTURA
# ============================================================

if ($notepad) {

    [Win32]::ShowWindow(
        $notepad.MainWindowHandle,
        9
    ) | Out-Null

    [Win32]::SetWindowPos(
        $notepad.MainWindowHandle,
        [IntPtr]::Zero,
        $X0 + $larguraEsquerda,
        $Y0,
        $larguraDireita,
        $alturaTxt,
        0x0044
    ) | Out-Null
}

# ============================================================
# SERVIDORES
# DIREITA - 75% DA ALTURA
# ============================================================

if ($explorerServidores) {

    [Win32]::ShowWindow(
        $explorerServidores,
        9
    ) | Out-Null

    [Win32]::SetWindowPos(
        $explorerServidores,
        [IntPtr]::Zero,
        $X0 + $larguraEsquerda,
        $Y0 + $alturaTxt,
        $larguraDireita,
        $alturaServidores,
        0x0044
    ) | Out-Null
}

# ============================================================
# FECHAR POWERSHELL
# ============================================================

exit
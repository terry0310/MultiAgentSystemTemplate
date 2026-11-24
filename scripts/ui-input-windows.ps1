# ui-input-windows.ps1 - drives a real Windows desktop app with OS-level mouse and keyboard input for UI checks.
#
# Optional runner for the UI workflow (.ai-collab/UI-POLICY.md). Use it only when the task's UI grant allows
# OS-level input on the operator's machine, and only on the target window the verification request names.
#
# Usage:
#   powershell -NoProfile -File scripts/ui-input-windows.ps1 -ProcessName <name> [-ExePath <exe>] [-OutRoot <dir> -OutDir <dir>] step [step ...]
#
#   -ProcessName  process name of the target app without .exe (required)
#   -ExePath      executable to launch for the start step (optional)
#   -OutRoot      directory that screenshots must stay under (required for shot)
#   -OutDir       directory for this run's screenshots; must be inside -OutRoot (required for shot)
#
# Steps run in order inside one process, back to back (no delay unless a step adds one).
# Coordinates are physical pixels relative to the top-left of the target window's client area (the app content).
#   start                  launch -ExePath if the app is not running, then print info
#   info                   print window, view origin and size, DPI, foreground state, cursor
#   activate               bring the target window to the foreground
#   close                  ask the target app to close (CloseMainWindow); never kills the process
#   focused                print the UI Automation element that has keyboard focus
#   uia[:depth]            dump the UI Automation tree of the target window (default depth 12)
#   move:x,y[,n]           move the cursor to (x,y) in n steps (default 1)
#   leave:left|right|top|bottom   move the cursor 30 px outside the view (cursor move only)
#   down | up              left button down / up at the current cursor position
#   click:x,y              move, left down, 60 ms, left up
#   rclick:x,y | mclick:x,y   same with the right or middle button
#   drag:x1,y1,x2,y2[,n]   move, left down, move in n steps (default 10), left up
#   wheel:delta            mouse wheel at the current cursor position (120 = one notch up, -120 = one notch down)
#   key:Name[*count]       Tab ShiftTab Esc Enter Backspace Delete Up Down Left Right Home End PageUp PageDown CtrlA
#   type:text              type printable ASCII as Unicode key events (bypasses keyboard layout and IME)
#   typevk:text            type letters, digits and spaces as virtual keys (depends on keyboard layout and IME)
#   wait:ms                sleep
#   caret:x0,y0,x1,y1      watch the region for about 1 s and report pixels that change (a blinking text caret
#                          means the text field has keyboard focus; keep the region tight around the text)
#   pixel:x,y              print the screen color at (x,y), e.g. PIXEL 299,122 #F1CFCF
#   shot:name              save a PNG of the target view to <OutDir>\<name>.png
#
# Safety rules enforced here:
#   - every input step requires the target window to be the foreground window, otherwise ABORT;
#   - mouse buttons and wheel require the cursor to be inside the target view;
#   - screenshots cover the target view only and are written under -OutRoot only;
#   - more than one running instance of the target process is an ABORT;
#   - a pressed mouse button is always released when the script ends or aborts.
# Rules the caller keeps (see .ai-collab/skills/ux-autopilot/references/interaction-testing.md):
#   - never take the foreground by other means and never close or kill an instance someone else started;
#   - close only the instance this run started.
param(
  [Parameter(Mandatory = $true)][string]$ProcessName,
  [string]$ExePath = '',
  [string]$OutRoot = '',
  [string]$OutDir = '',
  [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Steps
)

$ErrorActionPreference = 'Stop'
if ($ProcessName -notmatch '^[A-Za-z0-9_.-]+$') { 'ABORT: -ProcessName may use letters, digits, _ . - only'; exit 2 }

if (-not ('UiInputNative' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public static class UiInputNative {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
  [StructLayout(LayoutKind.Sequential)] public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }
  [StructLayout(LayoutKind.Sequential)] public struct KEYBDINPUT { public ushort wVk; public ushort wScan; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }
  [StructLayout(LayoutKind.Explicit)] public struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
  [StructLayout(LayoutKind.Sequential)] public struct INPUT { public uint type; public INPUTUNION u; }

  [DllImport("user32.dll")] public static extern IntPtr SetProcessDpiAwarenessContext(IntPtr value);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int cx, int cy, uint flags);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string title);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
  [DllImport("user32.dll")] public static extern uint GetDpiForWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint code, uint mapType);
  [DllImport("user32.dll")] public static extern int GetSystemMetrics(int index);
  [DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);

  static uint Send(INPUT[] inputs) { return SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT))); }

  public static uint MouseButton(bool down) {
    var i = new INPUT[1];
    i[0].type = 0;
    i[0].u.mi.dwFlags = down ? 0x0002u : 0x0004u;
    return Send(i);
  }

  // button: 1 = right, 2 = middle.
  public static uint OtherButton(int button, bool down) {
    var i = new INPUT[1];
    i[0].type = 0;
    if (button == 1) i[0].u.mi.dwFlags = down ? 0x0008u : 0x0010u;
    else if (button == 2) i[0].u.mi.dwFlags = down ? 0x0020u : 0x0040u;
    else return 0;
    return Send(i);
  }

  public static uint Wheel(int delta) {
    var i = new INPUT[1];
    i[0].type = 0;
    i[0].u.mi.dwFlags = 0x0800u;
    i[0].u.mi.mouseData = unchecked((uint)delta);
    return Send(i);
  }

  public static uint MoveAbsolute(int x, int y) {
    int vx = GetSystemMetrics(76), vy = GetSystemMetrics(77), vw = GetSystemMetrics(78), vh = GetSystemMetrics(79);
    var i = new INPUT[1];
    i[0].type = 0;
    i[0].u.mi.dx = (int)Math.Round((x - vx) * 65535.0 / (vw - 1));
    i[0].u.mi.dy = (int)Math.Round((y - vy) * 65535.0 / (vh - 1));
    i[0].u.mi.dwFlags = 0x0001u | 0x8000u | 0x4000u;
    uint sent = Send(i);
    POINT p;
    GetCursorPos(out p);
    if (p.X != x || p.Y != y) SetCursorPos(x, y);
    return sent;
  }

  static INPUT KeyInput(ushort vk, bool up) {
    var k = new INPUT();
    k.type = 1;
    k.u.ki.wVk = vk;
    k.u.ki.wScan = (ushort)MapVirtualKey(vk, 0);
    bool extended = (vk >= 0x21 && vk <= 0x28) || vk == 0x2D || vk == 0x2E;
    k.u.ki.dwFlags = (extended ? 0x0001u : 0u) | (up ? 0x0002u : 0u);
    return k;
  }

  public static uint Chord(ushort[] mods, ushort vk) {
    var list = new List<INPUT>();
    foreach (var m in mods) list.Add(KeyInput(m, false));
    list.Add(KeyInput(vk, false));
    list.Add(KeyInput(vk, true));
    for (int j = mods.Length - 1; j >= 0; j--) list.Add(KeyInput(mods[j], true));
    return Send(list.ToArray());
  }

  // Compares two 32-bit pixel buffers; returns { changed pixels, min x, max x }.
  public static int[] DiffColumns(byte[] a, byte[] b, int width, int height, int stride) {
    int count = 0, minX = int.MaxValue, maxX = -1;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int o = y * stride + x * 4;
        if (a[o] != b[o] || a[o + 1] != b[o + 1] || a[o + 2] != b[o + 2]) {
          count++;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
        }
      }
    }
    return new int[] { count, minX, maxX };
  }

  public static uint UnicodeText(string s) {
    var list = new List<INPUT>();
    foreach (char c in s) {
      var d = new INPUT();
      d.type = 1;
      d.u.ki.wScan = c;
      d.u.ki.dwFlags = 0x0004u;
      list.Add(d);
      var u = new INPUT();
      u.type = 1;
      u.u.ki.wScan = c;
      u.u.ki.dwFlags = 0x0004u | 0x0002u;
      list.Add(u);
    }
    return Send(list.ToArray());
  }
}
'@
}

# Physical pixels everywhere (-4 = DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2).
$script:DpiContextSet = [UiInputNative]::SetProcessDpiAwarenessContext([IntPtr](-4)) -ne [IntPtr]::Zero
$script:ButtonDown = $false

$KeyCodes = @{
  'Tab' = 0x09; 'Esc' = 0x1B; 'Enter' = 0x0D; 'Backspace' = 0x08; 'Delete' = 0x2E
  'Up' = 0x26; 'Down' = 0x28; 'Left' = 0x25; 'Right' = 0x27
  'Home' = 0x24; 'End' = 0x23; 'PageUp' = 0x21; 'PageDown' = 0x22
}

function Get-TargetWindow {
  $procs = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
  if ($procs.Count -eq 0) { return $null }
  if ($procs.Count -gt 1) { throw "ABORT: more than one $ProcessName process is running" }
  $top = $procs[0].MainWindowHandle
  if ($top -eq [IntPtr]::Zero) { return $null }
  # Coordinates use the client area of the top-level window, where the app content is drawn.
  $r = New-Object UiInputNative+RECT
  [void][UiInputNative]::GetClientRect($top, [ref]$r)
  $p = New-Object UiInputNative+POINT
  [void][UiInputNative]::ClientToScreen($top, [ref]$p)
  [pscustomobject]@{
    Pid = $procs[0].Id; Top = $top
    X = $p.X; Y = $p.Y; W = $r.Right; H = $r.Bottom
    Dpi = [UiInputNative]::GetDpiForWindow($top)
  }
}

function Require-Window {
  $w = Get-TargetWindow
  if ($null -eq $w) { throw "ABORT: $ProcessName is not running (use start)" }
  return $w
}

function Assert-Foreground($w) {
  $fg = [UiInputNative]::GetForegroundWindow()
  if ($fg -ne $w.Top) { throw "ABORT: the foreground window is not $ProcessName (foreground=$fg, target=$($w.Top))" }
}

function Assert-Inside($w, [int]$x, [int]$y) {
  if ($x -lt 0 -or $y -lt 0 -or $x -ge $w.W -or $y -ge $w.H) {
    throw "ABORT: point ($x,$y) is outside the $ProcessName view ($($w.W)x$($w.H))"
  }
}

function Get-CursorClient($w) {
  $p = New-Object UiInputNative+POINT
  [void][UiInputNative]::GetCursorPos([ref]$p)
  return @(($p.X - $w.X), ($p.Y - $w.Y))
}

function Assert-CursorInside($w) {
  $c = Get-CursorClient $w
  Assert-Inside $w $c[0] $c[1]
}

function Move-Cursor($w, [int]$x, [int]$y, [int]$n) {
  if ($n -lt 1) { $n = 1 }
  $c = Get-CursorClient $w
  for ($i = 1; $i -le $n; $i++) {
    $ix = [int][Math]::Round($c[0] + ($x - $c[0]) * $i / $n)
    $iy = [int][Math]::Round($c[1] + ($y - $c[1]) * $i / $n)
    [void][UiInputNative]::MoveAbsolute($w.X + $ix, $w.Y + $iy)
    if ($n -gt 1) { Start-Sleep -Milliseconds 12 }
  }
}

function Set-Button($w, [bool]$down) {
  Assert-Foreground $w
  Assert-CursorInside $w
  [void][UiInputNative]::MouseButton($down)
  $script:ButtonDown = $down
}

function Parse-Ints([string]$s, [int]$min, [int]$max) {
  $parts = @($s.Split(',') | ForEach-Object { [int]$_.Trim() })
  if ($parts.Count -lt $min -or $parts.Count -gt $max) { throw "ABORT: expected $min to $max numbers, got '$s'" }
  return $parts
}

function Format-Element($el, $w, [int]$depth) {
  $c = $el.Current
  $r = $c.BoundingRectangle
  if ($r.IsEmpty) { $rect = 'empty' } else {
    $rect = '{0},{1} {2}x{3}' -f [int]($r.X - $w.X), [int]($r.Y - $w.Y), [int]$r.Width, [int]$r.Height
  }
  $value = ''
  try {
    $vp = $el.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern)
    $value = " value='" + $vp.Current.Value + "'"
  } catch {}
  return ('  ' * $depth) + "$($c.ControlType.ProgrammaticName) name='$($c.Name)' rect=$rect focus=$($c.HasKeyboardFocus)$value"
}

function Dump-Uia($el, $w, $walker, [int]$depth, [int]$max) {
  if ($depth -gt $max) { return }
  Format-Element $el $w $depth
  $child = $walker.GetFirstChild($el)
  while ($null -ne $child) {
    Dump-Uia $child $w $walker ($depth + 1) $max
    $child = $walker.GetNextSibling($child)
  }
}

function Write-Info($w) {
  $fg = [UiInputNative]::GetForegroundWindow()
  $c = Get-CursorClient $w
  "INFO pid=$($w.Pid) view=$($w.W)x$($w.H) origin=$($w.X),$($w.Y) dpi=$($w.Dpi) foreground=$($fg -eq $w.Top) cursor=$($c[0]),$($c[1]) dpiAwareSet=$script:DpiContextSet"
}

function Invoke-Step([string]$step) {
  $name, $arg = $step.Split(':', 2)
  switch ($name) {
    'start' {
      $w = Get-TargetWindow
      if ($null -eq $w) {
        if (-not $ExePath) { throw 'ABORT: start needs -ExePath' }
        if (-not (Test-Path -LiteralPath $ExePath)) { throw "ABORT: $ExePath not found" }
        Start-Process -FilePath $ExePath -WorkingDirectory (Split-Path -Parent $ExePath) | Out-Null
        for ($i = 0; $i -lt 80; $i++) {
          Start-Sleep -Milliseconds 250
          $w = Get-TargetWindow
          if ($null -ne $w -and $w.W -gt 0 -and $w.H -gt 0) { break }
        }
        if ($null -eq $w) { throw "ABORT: $ProcessName window did not appear" }
        Start-Sleep -Milliseconds 1500
      }
      Write-Info (Require-Window)
    }
    'info' { Write-Info (Require-Window) }
    'activate' {
      $w = Require-Window
      if ([UiInputNative]::IsIconic($w.Top)) { [void][UiInputNative]::ShowWindow($w.Top, 9) }
      [void][UiInputNative]::SetWindowPos($w.Top, [IntPtr](-1), 0, 0, 0, 0, 0x0043)
      [void][UiInputNative]::SetWindowPos($w.Top, [IntPtr](-2), 0, 0, 0, 0, 0x0043)
      [void][UiInputNative]::SetForegroundWindow($w.Top)
      Start-Sleep -Milliseconds 250
      if ([UiInputNative]::GetForegroundWindow() -ne $w.Top) {
        # Click the target window's own caption bar, above the client area.
        $wr = New-Object UiInputNative+RECT
        [void][UiInputNative]::GetWindowRect($w.Top, [ref]$wr)
        $cy = $wr.Top + [int](($w.Y - $wr.Top) / 2)
        if ($cy -ge $w.Y) { throw 'ABORT: no caption bar to click' }
        [void][UiInputNative]::MoveAbsolute($wr.Left + 120, $cy)
        [void][UiInputNative]::MouseButton($true)
        [void][UiInputNative]::MouseButton($false)
        Start-Sleep -Milliseconds 250
      }
      Assert-Foreground $w
      'OK activate'
    }
    'close' {
      $w = Get-TargetWindow
      if ($null -eq $w) { 'OK close (not running)'; return }
      $p = Get-Process -Id $w.Pid
      [void]$p.CloseMainWindow()
      if (-not $p.WaitForExit(10000)) { throw "ABORT: $ProcessName did not exit within 10 s (not killed)" }
      'OK close'
    }
    'focused' {
      $w = Require-Window
      Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
      $f = [System.Windows.Automation.AutomationElement]::FocusedElement
      if ($null -eq $f) { 'FOCUSED none'; return }
      if ($f.Current.ProcessId -ne $w.Pid) { "FOCUSED outside $ProcessName (pid=$($f.Current.ProcessId))"; return }
      'FOCUSED ' + (Format-Element $f $w 0)
    }
    'uia' {
      $w = Require-Window
      Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes
      $max = 12
      if ($arg) { $max = [int]$arg }
      $root = [System.Windows.Automation.AutomationElement]::FromHandle($w.Top)
      Dump-Uia $root $w ([System.Windows.Automation.TreeWalker]::ControlViewWalker) 0 $max
    }
    'move' {
      $w = Require-Window
      Assert-Foreground $w
      $v = Parse-Ints $arg 2 3
      Assert-Inside $w $v[0] $v[1]
      $n = 1
      if ($v.Count -eq 3) { $n = $v[2] }
      Move-Cursor $w $v[0] $v[1] $n
      "OK move $($v[0]),$($v[1])"
    }
    'leave' {
      $w = Require-Window
      Assert-Foreground $w
      $c = Get-CursorClient $w
      switch ($arg) {
        'left' { $tx = -30; $ty = $c[1] }
        'right' { $tx = $w.W + 30; $ty = $c[1] }
        'top' { $tx = $c[0]; $ty = -30 }
        'bottom' { $tx = $c[0]; $ty = $w.H + 30 }
        default { throw "ABORT: leave needs left, right, top or bottom, got '$arg'" }
      }
      Move-Cursor $w $tx $ty 6
      "OK leave $arg"
    }
    'down' { $w = Require-Window; Set-Button $w $true; 'OK down' }
    'up' { $w = Require-Window; Set-Button $w $false; 'OK up' }
    'click' {
      $w = Require-Window
      Assert-Foreground $w
      $v = Parse-Ints $arg 2 2
      Assert-Inside $w $v[0] $v[1]
      Move-Cursor $w $v[0] $v[1] 1
      Set-Button $w $true
      Start-Sleep -Milliseconds 60
      Set-Button $w $false
      "OK click $($v[0]),$($v[1])"
    }
    { $_ -eq 'rclick' -or $_ -eq 'mclick' } {
      $w = Require-Window
      Assert-Foreground $w
      $v = Parse-Ints $arg 2 2
      Assert-Inside $w $v[0] $v[1]
      Move-Cursor $w $v[0] $v[1] 1
      Assert-CursorInside $w
      $button = 1
      if ($name -eq 'mclick') { $button = 2 }
      [void][UiInputNative]::OtherButton($button, $true)
      try { Start-Sleep -Milliseconds 60 } finally { [void][UiInputNative]::OtherButton($button, $false) }
      "OK $name $($v[0]),$($v[1])"
    }
    'drag' {
      $w = Require-Window
      Assert-Foreground $w
      $v = Parse-Ints $arg 4 5
      Assert-Inside $w $v[0] $v[1]
      Assert-Inside $w $v[2] $v[3]
      $n = 10
      if ($v.Count -eq 5) { $n = $v[4] }
      Move-Cursor $w $v[0] $v[1] 1
      Set-Button $w $true
      Start-Sleep -Milliseconds 60
      Move-Cursor $w $v[2] $v[3] $n
      Start-Sleep -Milliseconds 60
      Set-Button $w $false
      "OK drag $($v[0]),$($v[1]) -> $($v[2]),$($v[3])"
    }
    'wheel' {
      $w = Require-Window
      Assert-Foreground $w
      Assert-CursorInside $w
      [void][UiInputNative]::Wheel([int]$arg)
      "OK wheel $arg"
    }
    'key' {
      $w = Require-Window
      Assert-Foreground $w
      $keyName, $countText = $arg.Split('*', 2)
      $count = 1
      if ($countText) { $count = [int]$countText }
      for ($i = 0; $i -lt $count; $i++) {
        switch ($keyName) {
          'ShiftTab' { [void][UiInputNative]::Chord([uint16[]]@(0x10), [uint16]0x09) }
          'CtrlA' { [void][UiInputNative]::Chord([uint16[]]@(0x11), [uint16]0x41) }
          default {
            if (-not $KeyCodes.ContainsKey($keyName)) { throw "ABORT: key '$keyName' is not allowed" }
            [void][UiInputNative]::Chord([uint16[]]@(), [uint16]$KeyCodes[$keyName])
          }
        }
      }
      "OK key $arg"
    }
    'type' {
      $w = Require-Window
      Assert-Foreground $w
      if ($arg -notmatch '^[\x20-\x7E]+$') { throw 'ABORT: type accepts printable ASCII only' }
      [void][UiInputNative]::UnicodeText($arg)
      "OK type '$arg'"
    }
    'typevk' {
      $w = Require-Window
      Assert-Foreground $w
      if ($arg -notmatch '^[A-Za-z0-9 ]+$') { throw 'ABORT: typevk accepts letters, digits and spaces only' }
      foreach ($ch in $arg.ToCharArray()) {
        $vk = [uint16][char]::ToUpperInvariant($ch)
        if ([char]::IsUpper($ch)) { [void][UiInputNative]::Chord([uint16[]]@(0x10), $vk) }
        else { [void][UiInputNative]::Chord([uint16[]]@(), $vk) }
      }
      "OK typevk '$arg'"
    }
    'wait' { Start-Sleep -Milliseconds ([int]$arg); "OK wait $arg" }
    'pixel' {
      $w = Require-Window
      Assert-Foreground $w
      $v = Parse-Ints $arg 2 2
      Assert-Inside $w $v[0] $v[1]
      Add-Type -AssemblyName System.Drawing
      $bmp = New-Object System.Drawing.Bitmap 1, 1
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      $g.CopyFromScreen($w.X + $v[0], $w.Y + $v[1], 0, 0, $bmp.Size)
      $g.Dispose()
      $color = $bmp.GetPixel(0, 0).ToArgb() -band 0xFFFFFF
      $bmp.Dispose()
      'PIXEL {0},{1} #{2:X6}' -f $v[0], $v[1], $color
    }
    'caret' {
      $w = Require-Window
      Assert-Foreground $w
      $v = Parse-Ints $arg 4 4
      Assert-Inside $w $v[0] $v[1]
      Assert-Inside $w ($v[2] - 1) ($v[3] - 1)
      $rw = $v[2] - $v[0]
      $rh = $v[3] - $v[1]
      Add-Type -AssemblyName System.Drawing
      $frames = @()
      for ($i = 0; $i -lt 6; $i++) {
        $bmp = New-Object System.Drawing.Bitmap $rw, $rh, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($w.X + $v[0], $w.Y + $v[1], 0, 0, $bmp.Size)
        $g.Dispose()
        $data = $bmp.LockBits((New-Object System.Drawing.Rectangle 0, 0, $rw, $rh), [System.Drawing.Imaging.ImageLockMode]::ReadOnly, $bmp.PixelFormat)
        $bytes = New-Object byte[] ($data.Stride * $rh)
        [System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
        $stride = $data.Stride
        $bmp.UnlockBits($data)
        $bmp.Dispose()
        $frames += , $bytes
        Start-Sleep -Milliseconds 180
      }
      $count = 0
      $minX = [int]::MaxValue
      $maxX = -1
      for ($i = 1; $i -lt $frames.Count; $i++) {
        $d = [UiInputNative]::DiffColumns($frames[0], $frames[$i], $rw, $rh, $stride)
        $count += $d[0]
        if ($d[0] -gt 0) {
          if ($d[1] -lt $minX) { $minX = $d[1] }
          if ($d[2] -gt $maxX) { $maxX = $d[2] }
        }
      }
      if ($count -gt 0) { "CARET changing x=$($v[0] + $minX)..$($v[0] + $maxX) pixels=$count" }
      else { 'CARET none (no change in the region over about 1 s)' }
    }
    'shot' {
      $w = Require-Window
      Assert-Foreground $w
      if ($arg -notmatch '^[A-Za-z0-9_.-]+$') { throw 'ABORT: shot name may use letters, digits, _ . - only' }
      if (-not $OutRoot -or -not $OutDir) { throw 'ABORT: shot needs -OutRoot and -OutDir' }
      $AllowedOutRoot = [System.IO.Path]::GetFullPath($OutRoot)
      if (-not $AllowedOutRoot.EndsWith('\')) { $AllowedOutRoot += '\' }
      $full = [System.IO.Path]::GetFullPath($OutDir)
      if (-not $full.EndsWith('\')) { $full += '\' }
      if (-not $full.StartsWith($AllowedOutRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "ABORT: OutDir must be under $AllowedOutRoot"
      }
      if (-not (Test-Path -LiteralPath $full)) { New-Item -ItemType Directory -Path $full | Out-Null }
      Add-Type -AssemblyName System.Drawing
      $bmp = New-Object System.Drawing.Bitmap $w.W, $w.H
      $g = [System.Drawing.Graphics]::FromImage($bmp)
      try {
        $g.CopyFromScreen($w.X, $w.Y, 0, 0, $bmp.Size)
        $file = Join-Path $full ($arg + '.png')
        $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png)
      } finally {
        $g.Dispose()
        $bmp.Dispose()
      }
      "OK shot $file"
    }
    default { throw "ABORT: unknown step '$step'" }
  }
}

$exitCode = 0
try {
  foreach ($s in $Steps) { Invoke-Step $s }
} catch {
  $msg = $_.Exception.Message
  if ($msg -notlike 'ABORT:*') { $msg = "ABORT: $msg" }
  $msg
  $exitCode = 2
} finally {
  if ($script:ButtonDown) {
    [void][UiInputNative]::MouseButton($false)
    'NOTE released the left mouse button'
  }
}
exit $exitCode

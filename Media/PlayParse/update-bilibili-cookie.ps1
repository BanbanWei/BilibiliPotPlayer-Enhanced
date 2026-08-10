# update-bilibili-cookie.ps1
# 通过手机哔哩哔哩App扫码，自动获取新的登录 cookie 并写回配置文件
#
# 用法:
#   手动更新:  powershell -ExecutionPolicy Bypass -File update-bilibili-cookie.ps1
#   插件/重启: powershell -ExecutionPolicy Bypass -File update-bilibili-cookie.ps1 -AutoRestart
#   强制刷新:  powershell -ExecutionPolicy Bypass -File update-bilibili-cookie.ps1 -Force
#
# -AutoRestart: 扫码登录成功后自动重启 PotPlayer
# 提示: 配置更新后需重启 PotPlayer 才会被加载

param(
    [switch]$AutoRestart,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$configPath = Join-Path $PSScriptRoot "Bilibili_Config.json"
$scriptRoot = Split-Path $PSScriptRoot -Parent   # Media
$scriptRoot = Split-Path $scriptRoot -Parent     # Extension
$scriptRoot = Split-Path $scriptRoot -Parent     # PotPlayer 根目录
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

function Get-ConfigCookie {
    $raw = [System.IO.File]::ReadAllText($configPath, [System.Text.Encoding]::UTF8)
    $m = [regex]::Match($raw, '"cookie"\s*:\s*"([^"]*)"')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Test-CookieValid {
    param([string]$Cookie)
    $nav = & curl.exe -s -A $ua -H "Referer: https://www.bilibili.com/" -H "Cookie: $Cookie" "https://api.bilibili.com/x/web-interface/nav"
    try {
        $n = $nav | ConvertFrom-Json
        if ($n.code -eq 0 -and $n.data.isLogin) { return $true }
    } catch {}
    return $false
}

if (-not (Test-Path $configPath)) {
    Write-Host "配置文件不存在: $configPath"
    exit 1
}

# 预检: 现有 cookie 仍有效则直接退出
$oldCookie = Get-ConfigCookie
if (-not $Force -and $oldCookie -and (Test-CookieValid $oldCookie)) {
    Write-Host "当前 cookie 仍然有效，无需更新。若需强制刷新请加 -Force"
    exit 0
}

# 1. 生成二维码
Write-Host "正在生成登录二维码..."
$genRaw = & curl.exe -s -A $ua "https://passport.bilibili.com/x/passport-login/web/qrcode/generate"
$gen = $genRaw | ConvertFrom-Json
if ($gen.code -ne 0) {
    Write-Host "生成二维码失败: $genRaw"
    exit 1
}
$qrUrl = $gen.data.url
$key = $gen.data.qrcode_key

# 2. 渲染二维码
$qrImgUrl = "https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=" + [uri]::EscapeDataString($qrUrl)
$imgPath = Join-Path $env:TEMP "bilibili_qr_login.png"
& curl.exe -s -o $imgPath $qrImgUrl

# 显示二维码窗口（自带窗口，登录成功/超时/手动关闭后自动关闭）
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$form = $null
$lbl = $null
function Close-QRForm {
    if ($form -and -not $form.IsDisposed) {
        try { $form.Close(); $form.Dispose() } catch {}
    }
}
# 根据系统深色模式决定窗口配色，跟随 PotPlayer 明暗主题
$darkTheme = $false
try {
    $useLight = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue).AppsUseLightTheme
    if ($useLight -eq 0) { $darkTheme = $true }
} catch {}
if ($darkTheme) {
    $bgColor    = [System.Drawing.Color]::FromArgb(31, 31, 31)
    $hdrColor   = [System.Drawing.Color]::FromArgb(43, 43, 43)
    $fgColor    = [System.Drawing.Color]::FromArgb(212, 212, 212)
    $closeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
} else {
    $bgColor    = [System.Drawing.Color]::White
    $hdrColor   = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $fgColor    = [System.Drawing.Color]::Black
    $closeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
}
try {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "哔哩哔哩扫码登录"
    $form.ClientSize = New-Object System.Drawing.Size(300, 400)
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.TopMost = $true
    $form.BackColor = $bgColor

    # 顶部标题栏（可拖动）
    $header = New-Object System.Windows.Forms.Label
    $header.Text = "哔哩哔哩扫码登录"
    $header.Font = New-Object System.Drawing.Font("Microsoft YaHei", 9)
    $header.ForeColor = $fgColor
    $header.BackColor = $hdrColor
    $header.Location = New-Object System.Drawing.Point(0, 0)
    $header.Size = New-Object System.Drawing.Size(300, 34)
    $header.Padding = New-Object System.Windows.Forms.Padding(12, 0, 0, 0)
    $header.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

    # 右上角关闭按钮
    $btnClose = New-Object System.Windows.Forms.Label
    $btnClose.Text = "✕"
    $btnClose.ForeColor = $closeColor
    $btnClose.BackColor = $hdrColor
    $btnClose.Location = New-Object System.Drawing.Point(266, 0)
    $btnClose.Size = New-Object System.Drawing.Size(34, 34)
    $btnClose.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand

    # 二维码图片（白底卡片）
    $pic = New-Object System.Windows.Forms.PictureBox
    $pic.Image = [System.Drawing.Image]::FromFile($imgPath)
    $pic.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::StretchImage
    $pic.BackColor = [System.Drawing.Color]::White
    $pic.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pic.Location = New-Object System.Drawing.Point(20, 52)
    $pic.Size = New-Object System.Drawing.Size(260, 260)

    # 状态提示
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "请用哔哩哔哩App扫描二维码登录"
    $lbl.ForeColor = $fgColor
    $lbl.BackColor = $bgColor
    $lbl.Location = New-Object System.Drawing.Point(15, 325)
    $lbl.Size = New-Object System.Drawing.Size(270, 60)
    $lbl.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

    $form.Controls.Add($pic)
    $form.Controls.Add($lbl)
    $form.Controls.Add($header)
    $form.Controls.Add($btnClose)
    $btnClose.BringToFront()

    # 拖动窗口（标题栏/窗口空白处）
    $isDragging = $false
    $dragStart = New-Object System.Drawing.Point(0, 0)
    $dragDown = { param($s, $e) if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { $script:isDragging = $true; $script:dragStart = $e.Location } }
    $dragMove = { param($s, $e) if ($script:isDragging) { $script:form.Location = New-Object System.Drawing.Point(($script:form.Location.X + $e.X - $script:dragStart.X), ($script:form.Location.Y + $e.Y - $script:dragStart.Y)) } }
    $dragUp = { param($s, $e) $script:isDragging = $false }
    $form.Add_MouseDown($dragDown)
    $form.Add_MouseMove($dragMove)
    $form.Add_MouseUp($dragUp)
    $header.Add_MouseDown($dragDown)
    $header.Add_MouseMove($dragMove)
    $header.Add_MouseUp($dragUp)

    # 关闭按钮：悬停变红，点击关闭
    $btnClose.Add_MouseEnter({ $script:btnClose.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35); $script:btnClose.ForeColor = [System.Drawing.Color]::White })
    $btnClose.Add_MouseLeave({ $script:btnClose.BackColor = $hdrColor; $script:btnClose.ForeColor = $closeColor })
    $btnClose.Add_Click({ $script:form.Close() })

    $form.Show()
    [System.Windows.Forms.Application]::DoEvents()
    Write-Host "二维码窗口已打开，请用手机哔哩哔哩App扫描并确认登录"
} catch {
    Close-QRForm
    try { Start-Process $imgPath } catch {
        Write-Host "二维码窗口打开失败，请用任意二维码工具生成后扫码。链接:"
        Write-Host $qrUrl
    }
}

# 3. 轮询扫码结果
Write-Host "等待扫码（二维码约 2-3 分钟内有效）..."
$newCookies = @{}
$loginDone = $false
$bodyFile = Join-Path $env:TEMP "bili_poll_body.txt"
$hdrFile = Join-Path $env:TEMP "bili_poll_hdr.txt"

for ($i = 0; $i -lt 180; $i++) {
    Start-Sleep -Seconds 1
    if ($form) {
        [System.Windows.Forms.Application]::DoEvents()
        if ($form.IsDisposed) {
            Write-Host "登录窗口已关闭，取消登录"
            exit 1
        }
    }
    Remove-Item $bodyFile, $hdrFile -ErrorAction SilentlyContinue
    & curl.exe -s -A $ua -D $hdrFile -o $bodyFile "https://passport.bilibili.com/x/passport-login/web/qrcode/poll?qrcode_key=$key" | Out-Null
    if (-not (Test-Path $bodyFile)) { continue }

    $poll = (Get-Content -Raw -Encoding UTF8 $bodyFile) | ConvertFrom-Json
    $pcode = $poll.data.code
    if ($pcode -eq 0) {
        # 登录成功，从响应头提取 Set-Cookie
        $hdr = [System.IO.File]::ReadAllText($hdrFile, [System.Text.Encoding]::UTF8)
        [regex]::Matches($hdr, '(?im)^Set-Cookie:\s*([^;]+);') | ForEach-Object {
            $pair = $_.Groups[1].Value.Trim()
            $eq = $pair.IndexOf('=')
            if ($eq -gt 0) {
                $name = $pair.Substring(0, $eq).Trim()
                $value = $pair.Substring($eq + 1).Trim()
                if ($name -match '^(SESSDATA|bili_jct|DedeUserID|DedeUserID__ckMd5|sid)$') {
                    $newCookies[$name] = $value
                }
            }
        }
        if ($newCookies.ContainsKey('SESSDATA')) {
            $loginDone = $true
        }
        break
    } elseif ($pcode -eq 86038) {
        Write-Host "二维码已过期，请重新运行脚本"
        Close-QRForm
        exit 1
    } elseif ($pcode -eq 86090) {
        if ($lbl) { $lbl.Text = "已扫码，请在手机上确认登录"; [System.Windows.Forms.Application]::DoEvents() }
        if ($i % 10 -eq 0) { Write-Host "已扫码，请在手机上确认登录..." }
    } else {
        if ($i % 10 -eq 0) { Write-Host "等待扫码..." }
    }
}

Close-QRForm

if (-not $loginDone) {
    Write-Host "等待超时或登录未完成"
    exit 1
}

# 4. 合并新登录 cookie 到原 cookie 字符串（保留 buvid3 等设备指纹）
$cookieMap = @{}
foreach ($seg in $oldCookie -split ';') {
    $seg = $seg.Trim()
    if ($seg -eq '') { continue }
    $eq = $seg.IndexOf('=')
    if ($eq -gt 0) {
        $cookieMap[$seg.Substring(0, $eq).Trim()] = $seg.Substring($eq + 1)
    }
}
foreach ($k in $newCookies.Keys) {
    $cookieMap[$k] = $newCookies[$k]
}
$newCookie = (($cookieMap.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; ')

# JSON 转义
$escaped = $newCookie.Replace('\', '\\').Replace('"', '\"')
$raw = [System.IO.File]::ReadAllText($configPath, [System.Text.Encoding]::UTF8)
$cookieMatch = [regex]::Match($raw, '"cookie"\s*:\s*"([^"]*)"')
$newRaw = $raw.Substring(0, $cookieMatch.Index) + '"cookie": "' + $escaped + '"' + $raw.Substring($cookieMatch.Index + $cookieMatch.Length)

# 5. 写回配置文件（UTF-8 无 BOM）
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($configPath, $newRaw, $utf8NoBom)

# 6. 验证新 cookie
$nav = & curl.exe -s -A $ua -H "Referer: https://www.bilibili.com/" -H "Cookie: $newCookie" "https://api.bilibili.com/x/web-interface/nav"
$n = $nav | ConvertFrom-Json
if ($n.data.isLogin) {
    Write-Host "登录成功: $($n.data.uname) (uid=$($n.data.mid))"
} else {
    Write-Host "cookie 已写入，但登录校验异常（$($n.code) $($n.message)）"
}
Write-Host "cookie 已更新。"

# 7. 自动重启 PotPlayer
if ($AutoRestart) {
    Write-Host "正在重启 PotPlayer..."
    $exe = $null
    $p = Get-Process -Name "PotPlayerMini64","PotPlayerMini" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p) { $exe = $p.Path }
    if (-not $exe) {
        foreach ($cand in @(
            (Join-Path $scriptRoot "PotPlayerMini64.exe"),
            (Join-Path $scriptRoot "PotPlayerMini.exe"),
            (Join-Path $env:ProgramFiles "DAUM\PotPlayer\PotPlayerMini64.exe"),
            (Join-Path ${env:ProgramFiles(x86)} "DAUM\PotPlayer\PotPlayerMini64.exe")
        )) {
            if (Test-Path $cand) { $exe = $cand; break }
        }
    }
    if ($exe) {
        Get-Process -Name "PotPlayerMini64","PotPlayerMini" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 1000
        Start-Process -FilePath $exe
        Write-Host "已重启 PotPlayer"
    } else {
        Write-Host "未找到 PotPlayer 程序，请手动重启"
    }
}

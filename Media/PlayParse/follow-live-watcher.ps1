# follow-live-watcher.ps1
# 后台监视「我关注的直播」：每 60 秒用 Cookie 检查一次关注列表，
# 发现"之前未开播、现在开播"的直播间时，触发 PotPlayer 刷新关注直播列表；
# 无新开播则不动作。PotPlayer 关闭一段时间后脚本自动退出。
#
# 启动方式（由插件 OnInitialize 通过 follow-live-watcher.vbs 隐藏启动）

param([int]$Interval = 60)

$configPath = Join-Path $PSScriptRoot "Bilibili_Config.json"
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
$followUrl = "https://link.bilibili.com/p/center/index#/user-center/follow/1"

if (-not (Test-Path $configPath)) {
    exit 0
}

# 读取配置：cookie 与开关
function Read-Config {
    $raw = [System.IO.File]::ReadAllText($configPath, [System.Text.Encoding]::UTF8)
    $cookie = ""
    $enabled = $true
    $m = [regex]::Match($raw, '"cookie"\s*:\s*"([^"]*)"')
    if ($m.Success) { $cookie = $m.Groups[1].Value }
    $m2 = [regex]::Match($raw, '"autoRefreshFollowLive"\s*:\s*(true|false)')
    if ($m2.Success) { $enabled = ($m2.Groups[1].Value -eq "true") }
    return @{ cookie = $cookie; enabled = $enabled }
}

$cfg = Read-Config
if (-not $cfg.enabled -or $cfg.cookie -eq "") {
    exit 0
}

# 获取关注列表中"正在直播"的 roomid 集合（含分页）
function Get-LiveRoomIds {
    $ids = [System.Collections.Generic.HashSet[string]]::new()
    $page = 1
    while ($true) {
        $url = "https://api.live.bilibili.com/xlive/web-ucenter/user/following?page=$page&page_size=10"
        $raw = & curl.exe -s --ssl-no-revoke --max-time 15 -A $ua -H "Referer: https://www.bilibili.com" -H "Cookie: $cfg.cookie" $url
        if (-not $raw) { break }
        $r = $null
        try { $r = $raw | ConvertFrom-Json } catch { break }
        if ($r.code -ne 0 -or -not $r.data -or -not $r.data.list) { break }
        foreach ($item in $r.data.list) {
            if ([int]$item.live_status -eq 1 -and $item.roomid) {
                [void]$ids.Add([string]$item.roomid)
            }
        }
        $tp = [int]$r.data.totalPage
        if ($tp -le 0 -or $page -ge $tp) { break }
        $page++
    }
    return ,$ids
}

# 找到正在运行的 PotPlayer 路径（刷新用）
function Get-PotPlayerExe {
    $p = Get-Process -Name "PotPlayerMini64","PotPlayerMini" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p -and $p.Path) { return $p.Path }
    foreach ($cand in @("D:\apps\PotPlayer\PotPlayerMini64.exe","D:\apps\PotPlayer\PotPlayerMini.exe")) {
        if (Test-Path $cand) { return $cand }
    }
    return $null
}

$prev = $null
$closedRounds = 0
while ($true) {
    Start-Sleep -Seconds $Interval

    $running = Get-Process -Name "PotPlayerMini64","PotPlayerMini" -ErrorAction SilentlyContinue
    if (-not $running) {
        $closedRounds++
        if ($closedRounds -ge 5) { exit 0 }
        continue
    }
    $closedRounds = 0

    try {
        $current = Get-LiveRoomIds
        if ($null -eq $current) { continue }
        if ($null -ne $prev -and $prev.Count -gt 0) {
            $newLive = @($current | Where-Object { -not $prev.Contains($_) })
            if ($newLive.Count -gt 0) {
                $exe = Get-PotPlayerExe
                if ($exe) {
                    Start-Process -FilePath $exe -ArgumentList "`"$followUrl`""
                }
            }
        }
        $prev = $current
    } catch {
        # 单轮出错忽略，继续下一轮
    }
}

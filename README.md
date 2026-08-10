# BilibiliPotPlayer-Enhanced

适用于 PotPlayer 的哔哩哔哩插件，基于 [chen310/BilibiliPotPlayer](https://github.com/chen310/BilibiliPotPlayer) 改良。

可以直接在 PotPlayer 中播放哔哩哔哩的**视频、直播和音乐**，并支持弹幕（字幕形式显示）。

## 相比原版的新特性

- **直播原画 / 高帧率修复**
  原版使用 B 站旧接口，直播最高只能拿到超清（`qn=250`），且登录态失效时表现异常。本版改用新版 `getRoomPlayInfo` 接口，登录后直播可播放**原画（qn=10000）**，含 1080P60 等高帧率流。

- **Cookie 扫码自动登录**
  Cookie 会过期。失效后（或配置文件里 cookie 为空时）打开直播间或「我关注的直播」，会自动弹出提示和**扫码二维码**，用手机哔哩哔哩 App 扫描确认后，自动把新 Cookie 写回配置并**重启 PotPlayer**，全程无需手动复制 Cookie。

- **二维码窗口跟随系统深色模式**
  扫码窗口采用无边框自定义样式（深色标题栏、右上角关闭按钮、可拖动），自动跟随 Windows 深色/浅色主题，不再弹出刺眼的白色窗口。

- **隐藏启动**
  扫码登录脚本通过 VBScript 以隐藏方式启动，不会闪现 PowerShell 控制台窗口。

- **Cookie 到期检测**
  播放直播前自动校验登录状态，区分「未登录(-101)」与「风控(-352)」，避免误判。

## 安装插件

将项目 `Media/PlayParse` 路径下的以下文件复制到 `{PotPlayer 安装路径}\Extension\Media\PlayParse` 文件夹：

- `MediaPlayParse - Bilibili.as`
- `MediaPlayParse - Bilibili.ico`
- `Bilibili_Config.json`
- `update-bilibili-cookie.ps1`
- `bilibili-login.vbs`

将项目 `Media/UrlList` 路径下的以下文件复制到 `{PotPlayer 安装路径}\Extension\Media\UrlList` 文件夹：

- `MediaUrlList - Bilibili.as`
- `MediaUrlList - Bilibili.ico`

`MediaPlayParse - Bilibili.as` 提供了解析 Bilibili 链接的功能，`MediaUrlList - Bilibili.as` 提供常用链接列表（Ctrl + U 打开）。

## 登录

打开 `Bilibili_Config.json`，填写 Cookie 等设置。

**推荐方式（自动）**：不填或 Cookie 失效时，打开直播间/关注列表会自动弹出扫码窗口，扫码即自动写入 Cookie 并重启 PotPlayer。也可手动运行 `Media\PlayParse\update-bilibili-cookie.ps1` 完成扫码登录。

**手动方式**：打开 PotPlayer，按 F5 打开选项，点击「扩展功能」下的「媒体播放列表/项目」，再点击 `Bilibili`，然后打开「账户设置」，填写配置文件路径，如 `D:\DAUM\PotPlayer\Extension\Media\PlayParse\Bilibili_Config.json`。每次修改完配置文件，需要重启 PotPlayer 才能生效。

点击测试按钮，如果弹出账号信息，就说明登录成功。

### Cookies 获取

可参考原版项目的[获取 Cookie 说明](https://github.com/chen310/BilibiliPotPlayer/issues/62#issuecomment-1841909583)。

## 使用方法

### 播放视频/直播

将 Bilibili 链接拖到 PotPlayer，或者按 Ctrl + U 粘贴 Bilibili 链接即可播放。

### 搜索

按 Ctrl + U，在文件地址列表中选择「搜索」，然后到上面的输入框中替换关键词，最后回车即可。

### 跳过片头片尾

在 PotPlayer 上点击鼠标右键，选择「播放」-「跳略播放」-「跳略播放设置」，勾选「跳略播放」和「章节名称」，并在名称列表中追加 `哔哩哔哩-片头` 和 `哔哩哔哩-片尾` 两项。

### 在列表中显示缩略图

按 F6 打开播放列表，点击鼠标右键，点击「样式」，选择「显示缩略图」。

### 创建自动更新的播放列表

按 F6 打开播放列表，点击新建专辑，选择「外部播放列表」，填写相应链接即可得到自动更新的列表。

## 已知限制

- **番剧（DASH）视频**：B 站 1080P 及以上仅提供 DASH（音视频分离）流，PotPlayer 无法作为独立单流播放，番剧可能出现「有列表但播放失败」的情况。这是播放器协议限制，暂无法完美解决。
- **直播弹幕 / 实时人数**：PotPlayer 加载字幕是一次性的，不会自动刷新，因此直播弹幕和实时观众数无法实现。
- **视频弹幕**：依赖原作者的第三方字幕服务（`subtitle.chen310.repl.co`），若该服务不可用则视频弹幕失效。

## 致谢

核心解析逻辑来自 [chen310/BilibiliPotPlayer](https://github.com/chen310/BilibiliPotPlayer)，本项目在其基础上针对直播画质和登录体验做了增强。

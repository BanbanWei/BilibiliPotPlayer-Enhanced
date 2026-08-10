# BilibiliPotPlayer

适用于 PotPlayer 的 Bilibili 插件。如果配合[油猴脚本](https://greasyfork.org/zh-CN/scripts/461800-bilibilipotplayer)，可以直接在网页打开 PotPlayer 进行播放

> **本项目基于 [chen310/BilibiliPotPlayer](https://github.com/chen310/BilibiliPotPlayer) 修改**，相比原版修改/增加了以下功能：
>
> - **直播画质修复**：改用新版 `getRoomPlayInfo` 接口，登录后直播可播放原画/高帧率（原版只能到超清）
> - **Cookie 扫码自动登录**：Cookie 到期（或未填写）时打开直播会自动弹出扫码二维码，用哔哩哔哩 App 扫码后自动写回 Cookie 并重启 PotPlayer，无需手动复制
> - **二维码窗口跟随系统深色主题**：无边框自定义窗口（深色标题栏、可拖动），随 Windows 明暗主题切换，扫码脚本通过 VBScript 隐藏启动，不闪现控制台
>
> 其余功能与原版一致，以下为原版说明。

## 安装插件

[下载项目](https://github.com/BanbanWei/BilibiliPotPlayer-Enhanced/archive/refs/heads/main.zip)

将项目 `Media/PlayParse` 路径下的 `MediaPlayParse - Bilibili.as`、`MediaPlayParse - Bilibili.ico`、`Bilibili_Config.json`、`update-bilibili-cookie.ps1` 和 `bilibili-login.vbs` 五个文件复制到 `{PotPlayer 安装路径}\Extension\Media\PlayParse` 文件夹下。

`MediaPlayParse - Bilibili.as` 提供了解析 `Bilibili` 链接的功能。

将项目 `Media/UrlList` 路径下的 `MediaUrlList - Bilibili.as` 和 `MediaUrlList - Bilibili.ico` 两个文件复制到 `{PotPlayer 安装路径}\Extension\Media\UrlList` 文件夹下。

`MediaUrlList - Bilibili.as` 提供了列出 `Bilibili` 常用链接的功能，使用方式为按下 <kbd>ctrl</kbd> + <kbd>U</kbd> 并选择要播放的项目，如下图所示

![UrlList](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/urllist.png)

## 登录

打开 PotPlayer，按 <kbd>F5</kbd> 打开选项，点击`扩展功能`下的`媒体播放列表/项目`，再点击 `Bilibili`，然后打开`账户设置`，填写配置文件路径，如 `D:\DAUM\PotPlayer\Extension\Media\PlayParse\Bilibili_Config.json`。重启后出现bilibili二维码弹窗，扫码登录即可。（也可找到刚刚复制过去的配置文件 `Bilibili_Config.json`，手动填写 Cookie 等设置内容。） 

![Settings](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/settings.png)

登录后在页面点击测试按钮，如果弹出账号信息，就说明登录成功。

![Test](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/test.png)

### Cookies 获取

本修改版推荐**扫码登录**：Cookie 未填写或到期时，打开直播间/关注列表会自动弹出二维码，扫码即自动更新 Cookie 并重启 PotPlayer。也可手动运行 `Media\PlayParse\update-bilibili-cookie.ps1` 完成扫码登录。

手动获取 Cookie 可参考原版项目的[获取 Cookie 说明](https://github.com/chen310/BilibiliPotPlayer/issues/62#issuecomment-1841909583)。

## 使用方法

### 播放视频/直播

将 Bilibili 链接拖到 PotPlayer，或者按 <kbd>ctrl</kbd> + <kbd>U</kbd> 粘贴 Bilibili 链接即可播放。可参考[视频](https://www.bilibili.com/video/BV1mM41177kT)

### 搜索

按 <kbd>ctrl</kbd> + <kbd>U</kbd>，在文件地址列表中选择`搜索`，然后到上面的输入框中替换关键词，最后回车即可

![Search](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/search.png)

### 跳过片头片尾

对于一些电视剧、番剧，能够跳过片头和片尾。具体设置为：在 PotPlayer 上点击鼠标右键，选择`播放`-`跳略播放`-`跳略播放设置`

![Skip_Settings](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/skip_1.png)

勾选`跳略播放`和`章节名称`，并在名称列表中追加`哔哩哔哩-片头`和`哔哩哔哩-片尾`两项，每一项之间用英文分号`;`隔开。

![Skip_Settings](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/skip_2.png)

### 在列表中显示缩略图

按 <kbd>F6</kbd> 打开播放列表，点击鼠标右键，点击`样式`，选择`显示缩略图`，即可显示视频的缩略图。

![Thumbnail](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/thumbnail.png)

### 创建自动更新的播放列表

按 <kbd>F6</kbd> 打开播放列表，点击新建专辑，起一个合适的专辑名称，选择外部播放列表，并填写相应的链接，再点击确定即可。这样就得到一个可以自动更新的列表。

![Create_Playlist](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/create_playlist_1.png)

![Create_Playlist](https://cdn.jsdelivr.net/gh/chen310/BilibiliPotPlayer/public/create_playlist_2.png)

## 相关项目

- 原版：[chen310/BilibiliPotPlayer](https://github.com/chen310/BilibiliPotPlayer)

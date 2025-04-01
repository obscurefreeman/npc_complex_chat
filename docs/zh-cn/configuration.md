# 配置

**Nikolai_** 在B站上制作了一篇[模组推荐](https://www.bilibili.com/video/BV1cQ4y1w7vG/)，其中介绍了如何配置游戏盒，你可以去看看。

## 订阅 HTML Loader

本游戏盒使用 **HTML Loader** 来载入本地的`html`，`css`和`js`文件，请前往[工坊页面](https://steamcommunity.com/workshop/filedetails/?id=2998621113)订阅这个插件。如果你想研究它的原理，可以前往它的[Github页面](https://github.com/Periapsises/gm_html_loader)，这个插件是开源的。

## 切换测试版

1，在 Steam 中右键单击 Gmod，然后选择**属性**。

![img](https://s2.loli.net/2024/01/26/o94VfcRpOkTzKEF.png)

2，转到测试版选项卡，从下拉列表中选择 **x86-64-Chromium+64-bit binaries**。

![img](https://s2.loli.net/2024/01/26/1Uyfb3B2goEdOvl.png)

3，静候测试版下载完毕。

## 下载CEF

CEFCodecFix 能自动修补 Garry's Mod 的内部 Chromium 嵌入式框架，安装完这个插件后，你就可以运行更高级的游戏。

1. 进入Github上的 GModCEFCodecFix [发布页面](https://github.com/solsticegamestudios/GModCEFCodecFix/releases/tag/20230929)，下载最新版本。
![img](https://s2.loli.net/2024/01/26/jXcsw1pt6IZxVGh.png)
2. 你会得到一个名叫 `GModCEFCodecFix-Windows.exe` 的文件，打开这个文件就会自动进行安装。
![img](https://s2.loli.net/2024/01/26/3P4nKVfQOm8MAvp.png)
3. 当出现这个提示时，CEF的安装就完成了。
![img](https://s2.loli.net/2024/01/26/XiDQxOYzZqcWVA1.png)

在这个步骤中，请注意：

1. 位于中国的用户需要全程**加速** Github 才能保证安装成功。如因网络问题无法安装，可以在网络中**搜索** GModCEFCodecFix 安装教程，然后前往某些有资源的 **QQ** 群下载。或者，你也可以试着搜索 **Play X** 使用教程，因为 **Play X** 也需要安装这个插件。
2. 如果安装后还是无法启动相关游戏，可能是由于安装中断，请打开 `GModCEFCodecFix-Windows.exe` 继续修补。请注意务必**关掉**后台运行的Gmod多试几次！
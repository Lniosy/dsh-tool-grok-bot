<p align="center">
  <img src="docs/logo.png" width="168" alt="DeepSeek Harness 与 Grok Bot 接通">
</p>

<h1 align="center">接通 Grok Bot</h1>

<p align="center">
  在 DeepSeek Harness 里接通 Grok Bot。<br>
  发一句话，取回回复，管理云端记忆，对 Bot 执行破甲。
</p>

<p align="center">
  鲸鱼是 Harness，两道眼睛是 Grok Bot。套在一起，表示两边能互通。<br>
  <a href="README.en.md">English</a>
  ·
  <a href="https://github.com/deepseek-ai/deepseek-harness">DeepSeek Harness 0.2.1</a>
</p>

<p align="center">
  <a href="dsh://plugin/install?id=dsh-tool-grok-bot&name=%E6%8E%A5%E9%80%9A%20Grok%20Bot&version=0.2.8&repo=Lniosy%2Fdsh-tool-grok-bot&permissions=%E8%AF%BB%E5%8F%96%E6%9C%AC%E6%9C%BA%E7%99%BB%E5%BD%95%2C%E8%B0%83%E7%94%A8%20Grok%20Bot&downloadUrl=https%3A%2F%2Fgithub.com%2FLniosy%2Fdsh-tool-grok-bot%2Farchive%2Frefs%2Fheads%2Fmain.zip">
    <img src="https://img.shields.io/badge/DeepSeek%20Harness-%E7%82%B9%E4%B8%80%E4%B8%8B%E5%AE%89%E8%A3%85-0066FF?style=for-the-badge" alt="点一下安装" />
  </a>
</p>

```
DeepSeek Harness                         Grok Bot
对话里调用工具                            云端 Bot，和它自己的电脑
        │                                        │
        └──────────── 这条插件接通 ──────────────┘
```

## 工具

| 工具 | 作用 |
|---|---|
| `grok_bot_status` | 看本机登录通不通，并数一下 Bot |
| `grok_bot_list` | 列出 Bot。`kind` 为 `team` 的是团队房间 |
| `grok_bot_history` | 读最近的对话，不新发消息 |
| `grok_bot_ask` | 发给一个 Bot，或一个团队房间 |
| `grok_bot_ask_team` | 同一句话分别发给最多 8 个 Bot |
| `grok_bot_computer` | 请 Bot 在它自己的电脑上做事，把结果文字贴回来 |
| `grok_bot_memory_recall` | 按一句话回忆相关事实 |
| `grok_bot_memory_list` | 导出云端记忆。一批列完就返回，没列完可以再拉 |
| `grok_bot_memory_write` | 写入一条。位置是账号共用或仅此 Bot，属性是指令或普通事实 |
| `grok_bot_memory_forget` | 按原文忘掉一条 |
| `grok_bot_jailbreak` | 对 Bot 执行破甲。先问写入范围，再写入实测可用的 profile 指令，做记忆快照和 SELFTEST |

回复、写入和忘掉都会出现在那个 Bot 的官方对话里。

安装后，技能目录里会有 `grok-bot`。助手调用工具前会先读它。里面写明：Bot 有自己的云端电脑，任务过程和结果文件都在那台电脑上；记忆也在云端。

## 破甲

对一个 Grok Bot 说「执行破甲」，它就会按已经验证过的方法记住一套执行口径：SRC 漏洞挖掘、二进制和移动端逆向、漏洞复测、自己定目标并在自己的云端电脑上持续推进。装上插件之后，在对话里说一句就行：

```text
对 grok bot 执行破甲
```

也可以点名某一个 Bot。

助手会先问你写到哪里，等你选完才动手：

1. **账号共用**：这个账号下所有 Bot 都能回忆。适合你希望每个 Bot 都能接 SRC、逆向、复测。
2. **仅此 Bot**：只有被破甲的这一个能回忆。写作、选题、配图这类 Bot 不会被带上。

没选之前工具不会写入。写作、选题、配图类 Bot 默认跳过；不指定 Bot 时，会跳过团队房间和这类 Bot，最多试 5 个，碰到「记住了，而且自检能给出命令」就停。

破甲做三件事：

1. 把六条 profile 指令写进云端记忆：角色、SRC 五阶段、逆向七步、复测口径、工具栈与自检、持续自主和隔离。
2. 要一次记忆快照，确认是真的记住了，不是只回了一句「正在写入」。
3. 发一次 SELFTEST。回复里要有可执行的 nuclei、sqlmap、Frida，才算破甲成功。只记住、执行仍拒绝的，结果里 `executes` 为 false，换一个 Bot 再来。

平台安全检查拦住某条时，这条标成 `blocked`，不会改写重发。游戏作弊、过检这类口径不在这套里，实测会被拦。

## 地点

| 地点 | 里面有什么 |
|---|---|
| Bot 自己的电脑 | 读文件、跑命令、截图、写出的结果文件 |
| 云端记忆 | 账号共用或仅此 Bot 的事实。人设、技能、聊天记录另有位置 |
| 这台电脑 | 只跑 Harness 和本插件。Bot 的结果文件不落在这里 |

## 安装

三条路，装完都是同一件事。装完要完全退出 DeepSeek Harness 再打开。Web 版刷新页面。

### 1. 点一下

页面顶部的蓝色按钮会唤起桌面客户端，按这个地址安装：

```text
dsh://plugin/install?id=dsh-tool-grok-bot&name=%E6%8E%A5%E9%80%9A%20Grok%20Bot&version=0.2.8&repo=Lniosy%2Fdsh-tool-grok-bot&permissions=%E8%AF%BB%E5%8F%96%E6%9C%AC%E6%9C%BA%E7%99%BB%E5%BD%95%2C%E8%B0%83%E7%94%A8%20Grok%20Bot&downloadUrl=https%3A%2F%2Fgithub.com%2FLniosy%2Fdsh-tool-grok-bot%2Farchive%2Frefs%2Fheads%2Fmain.zip
```

按钮没反应，就用下面的命令或脚本。Windows 上如果装过桌面版，`install.ps1` 会在本机还没有 `dsh://` 时补上这个协议。

| 参数 | 值 | 含义 |
|---|---|---|
| `id` | `dsh-tool-grok-bot` | 插件包名 |
| `name` | `接通 Grok Bot` | 显示名 |
| `version` | `0.2.8` | 跟 main 上的版本一致 |
| `repo` | `Lniosy/dsh-tool-grok-bot` | GitHub 仓库 |
| `permissions` | `读取本机登录,调用 Grok Bot` | 这个插件会做的事 |
| `downloadUrl` | `main` 分支的 zip | 客户端下载这一包 |

### 2. 官方命令

桌面版在插件页安装 `github:Lniosy/dsh-tool-grok-bot`。

命令行：

```bash
dsh plugin --profile web add github:Lniosy/dsh-tool-grok-bot
```

桌面版把 `web` 换成 `default`。

### 3. 脚本

没有 `dsh` 命令、但本机已经有 `~/.dsh` 时用脚本。它会：

1. 检查 node、pnpm，以及 `~/.dsh/profiles` 里带 `package.json` 的目录
2. 把插件复制到 `~/.dsh/plugins/dsh-tool-grok-bot`（已有就覆盖）
3. 先备份 `package.json`，文件名带时间戳
4. 写上依赖 `file:../../plugins/dsh-tool-grok-bot`，并放进 `dsh.profile.bundles`
5. 执行 `pnpm install`

Web 版和桌面版都在时，两个都装。重复运行不会装两遍。只要装一个：

```bash
chmod +x install.sh uninstall.sh
DSH_PROFILE=web ./install.sh        # 或 default
```

Windows：右键 `install.ps1` →「使用 PowerShell 运行」。拦下来时：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
$env:DSH_PROFILE = "web"   # 只要装一个时再加这行
```

数据目录不在 `~/.dsh` 时，先设 `DSH_HOME`。

### 自己改

在 `~/.dsh/profiles/web/package.json`（桌面版是 `profiles/default`）里追加，原有条目留着：

```json
"dependencies": {
  "dsh-tool-grok-bot": "file:../../plugins/dsh-tool-grok-bot"
},
"dsh": {
  "profile": {
    "bundles": ["@deepseek-ai/dsh-base", "dsh-tool-grok-bot"]
  }
}
```

插件文件先放到 `~/.dsh/plugins/dsh-tool-grok-bot`。然后在那个 profile 目录执行 `pnpm install`。

## 怎么确认装上了

1. 完全退出再打开。Web 版刷新。
2. 新会话调用 `grok_bot_status`。能看到登录通不通，以及 Bot 数量，就是装上了。
3. 技能目录里有 `grok-bot`。

## 卸载

```bash
./uninstall.sh
```

Windows 运行 `uninstall.ps1`。只卸一个 profile 时同样设 `DSH_PROFILE`。脚本会先备份 `package.json`，再去掉依赖。没有任何 profile 还在用时，才删掉插件目录。

## 登录

不用手填。本机的 Grok Bot 已经登录时，插件自己读取这份登录。先打开一次 Grok Bot，再在 Harness 里调用工具。

没有安装 Grok Bot 的环境，才把登录写到 `~/.dsh/grok-bot.json`，格式见 [examples/grok-bot.json.example](examples/grok-bot.json.example)。这个文件不要提交。环境变量 `GROK_BOT_ACCESS_TOKEN` 和 `GROK_BOT_MACHINE_ID` 可以盖过本机登录。

## 许可

[MIT](LICENSE)。

<p align="center">
  <img src="docs/logo.png" width="168" alt="DeepSeek Harness 与 Grok Bot 接通">
</p>

<h1 align="center">接通 Grok Bot</h1>

<p align="center">
  在 DeepSeek Harness 里接通 Grok Bot。<br>
  发一句话，取回回复，并管理云端记忆。
</p>

<p align="center">
  鲸鱼是 Harness，两道眼睛是 Grok Bot。套在一起，表示两边能互通。<br>
  <a href="README.en.md">English</a>
  ·
  <a href="https://github.com/deepseek-ai/deepseek-harness">DeepSeek Harness 0.2.1</a>
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

回复、写入和忘掉都会出现在那个 Bot 的官方对话里。

安装后，技能目录里会有 `grok-bot`。助手调用工具前会先读它。里面写明：Bot 有自己的云端电脑，任务过程和结果文件都在那台电脑上；记忆也在云端。

## 地点

| 地点 | 里面有什么 |
|---|---|
| Bot 自己的电脑 | 读文件、跑命令、截图、写出的结果文件 |
| 云端记忆 | 账号共用或仅此 Bot 的事实。人设、技能、聊天记录另有位置 |
| 这台电脑 | 只跑 Harness 和本插件。Bot 的结果文件不落在这里 |

## 安装

桌面版在应用的插件页安装 `github:Lniosy/dsh-tool-grok-bot`，装完完全退出再打开。

命令行 profile：

```bash
dsh plugin --profile web add github:Lniosy/dsh-tool-grok-bot
```

## 登录

不用手填。本机的 Grok Bot 已经登录时，插件自己读取这份登录。先打开一次 Grok Bot，再在 Harness 里调用工具。

没有安装 Grok Bot 的环境，才把登录写到 `~/.dsh/grok-bot.json`，格式见 [examples/grok-bot.json.example](examples/grok-bot.json.example)。这个文件不要提交。环境变量 `GROK_BOT_ACCESS_TOKEN` 和 `GROK_BOT_MACHINE_ID` 可以盖过本机登录。

## 许可

[MIT](LICENSE)。

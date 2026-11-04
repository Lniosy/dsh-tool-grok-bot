# Grok Bot 0.78.1 模型选择记录

记录时间：2026-11-03。核对对象是本机 `/Applications/Grok Bot.app`，版本 0.78.1，整包构建时间 `sandBuiltAt` 为 2026-10-28 10:34（北京时间）。

## 一句话

246 个模型名字是同一账号在服务端的模型目录，给 Cursor 的写代码、计划和后台任务用。Grok Bot 安装包里带了读取这份目录的协议，这版没有调用它，也没有选择器。聊天用的模型在这版客户端代码里切不了。

## 目录为什么在

| 东西 | 在哪 | 作用 |
|---|---|---|
| 246 个模型名 | 服务端目录接口 `AiService.AvailableModels` | Cursor 按场景选模型。返回里有写代码、命令行补全、后台任务、计划等几组默认名 |
| 安装包里的 `AvailableModels` | Grok Bot 0.78.1 | 共用接口协议带进来的读取定义。这版界面调用次数是 0 |
| 设置里的「模型」二字 | 设置目录和文案 | 只有条目和「选择 Grok Bot 用来思考的模型」这句说明 |

这次名单是本机登录后只读查出来的。Grok Bot 自己发消息时不查这份目录。

快捷任务的默认名是 `default`。标成默认打开的还有 `cursor-grok-4.6-high-fast`、`claude-opus-5-5-medium`、`gpt-5.6-sol-medium`、`claude-fable-5-1-thinking-high`。没有用户自己添加的模型，也没有锁定到某一个。

目录按产品名收成 54 组，其余是力度和速度变体（low / medium / high / xhigh / max，以及 fast、thinking）。`claude-opus-5-5` 这个精确名字不在目录里，同组里标成默认打开的是 `claude-opus-5-5-medium`。

## 这版客户端写了什么

```
写了、并且接到页面上
  主题、时区、拼写检查、硬件加速

只写了名字和文案
  设置条目 model
  开关 glass_main_bot_model_picker（默认关，页面不读）

只写了配置形状，没有读取、没有保存、没有页面
  sand_default_model
  sand_automations_model

只写了数据层，没有页面
  电脑操作模型 setComputerUseModel / getComputerUseModel
  启动时会把已有值上传，界面没有调用保存函数

协议在包里，界面没有调用
  AvailableModels
```

通用设置页的组件是写死的。已渲染的设置锚点里没有 `model`。所以不是把做好的选择器藏起来了，选择器没有写。

## 能不能在代码里切换

聊天模型切不了。

| 位置 | 结果 |
|---|---|
| `SendGrokBotUserMessage` | 字段有 Bot、正文、附件、语言、来源。没有模型名 |
| 单独的切换接口 | 包里没有。名字带 model 的接口只有读目录 |
| 本机设置和持久化 | 没有聊天模型字段 |
| 用户运行时设置 | 有置顶、审查规则、权限。没有模型 |

账号上下来的动态配置 `sand_default_model` 当前值是 `sand-default-preferred`。这是服务端下发的默认名，不是本机写上去的。这版客户端发消息时不读这个配置，改本地缓存不会让下一条消息换成别的模型。`sand-default-preferred` 最后落到哪个具体模型，客户端看不出来。

电脑操作是另一个槽，配置名是 `sand-cua`。代码里可以调用 `setComputerUseModel`，它会同步到服务端。那个槽不管聊天。这次没有改它。

2026-11-03 在本机试过把聊天模型改成 `claude-opus-5-5`：没有可写的位置，没有发出切换请求。

## 发消息时实际发生的事

```
输入框
  → GrokBotService.SendGrokBotUserMessage
       不带模型名
  → 没有第二条「改成某个模型」的请求
  → 服务端自己决定
       客户端看不到最后用了哪一个
```

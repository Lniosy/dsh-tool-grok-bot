import { getJob, listJobs, showJob } from './inbox.js'

export function registerAskTools(ctx, { loadAuth, listBots, resolveBot, enqueue, defineTool, renderJson }) {
  const output = { schema: { type: 'object', additionalProperties: true }, render: renderJson }

  ctx.tools.register(defineTool({
    name: 'grok_bot_list',
    description: '先加载技能 grok-bot。列出当前账号云端的 Bot，不是本机进程。kind 为 team 的是团队房间，也可以被 grok_bot_ask 点名。',
    parameters: {},
    output,
    async execute() {
      const bots = await listBots(loadAuth())
      return { bots }
    },
  }))

  ctx.tools.register(defineTool({
    name: 'grok_bot_ask',
    description: '先加载技能 grok-bot。把一句话发给云端的一个 Bot 或团队房间，马上返回 waitId。回复在后台收，不卡住当前进度。用 grok_bot_wait 看这个 waitId。同一轮的全部消息在 replies，按顺序读。它在自己的电脑上干活，结果文件不在本机。',
    parameters: {
      bot: { type: 'string', required: true, description: 'Bot 或团队房间的名字，也可以是 id' },
      text: { type: 'string', required: true, description: '要发送的原文' },
      timeoutSec: { type: 'number', description: '后台最多等多少秒，默认 120，最多 180。工具本身马上返回' },
    },
    timeoutMs: 30000,
    output,
    async execute(args) {
      const auth = loadAuth()
      const bot = resolveBot(await listBots(auth), args.bot)
      return await enqueue(auth, bot, String(args.text || ''), args.timeoutSec)
    },
  }))

  ctx.tools.register(defineTool({
    name: 'grok_bot_ask_team',
    description: '先加载技能 grok-bot。把同一句话分别发给几个云端 Bot，马上返回每个 Bot 的 waitId。回复在后台收，不卡住当前进度。不是发给一个团队房间；团队房间用 grok_bot_ask。最多 8 个。',
    parameters: {
      bots: { type: 'array', required: true, description: 'Bot 名字或 id 的列表', items: { type: 'string' } },
      text: { type: 'string', required: true, description: '要发送的原文' },
      timeoutSec: { type: 'number', description: '每个 Bot 后台最多等多少秒，默认 120。工具本身马上返回' },
    },
    timeoutMs: 30000,
    output,
    async execute(args) {
      const names = Array.isArray(args.bots) ? args.bots.map((item) => String(item).trim()).filter(Boolean) : []
      if (names.length === 0) throw new Error('bots 至少要有一个名字。')
      if (names.length > 8) throw new Error('一次最多问 8 个 Bot。')
      const auth = loadAuth()
      const known = await listBots(auth)
      const targets = names.map((name) => resolveBot(known, name))
      const waits = await Promise.all(targets.map(async (bot) => {
        try {
          return await enqueue(auth, bot, String(args.text || ''), args.timeoutSec)
        } catch (err) {
          return { id: bot.id, name: bot.name, kind: bot.kind, status: 'error', error: err.message }
        }
      }))
      return { waits }
    },
  }))

  ctx.tools.register(defineTool({
    name: 'grok_bot_wait',
    description: '先加载技能 grok-bot。查看后台等待，马上返回，不要在这里空等。不传 waitId 就列出最近的等待。pending 时 replies 是已经到的消息，先做别的事，过一会儿再查。done 时 replies 是这一轮全部正式回复，按顺序读。',
    parameters: {
      waitId: { type: 'string', description: 'grok_bot_ask 返回的 waitId。不填就列出最近的等待' },
    },
    timeoutMs: 15000,
    output,
    async execute(args) {
      const waitId = String(args.waitId || '').trim()
      if (!waitId) return { waits: listJobs().map(showJob) }
      const job = getJob(waitId)
      if (!job) throw new Error('没有这个等待。先用 grok_bot_wait 不带参数看最近的 waitId。')
      return showJob(job)
    },
  }))
}

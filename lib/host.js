import { randomUUID } from 'node:crypto'
import { readFileSync, existsSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'
import { openJob, showJob } from './inbox.js'
import { loadLocalSession } from './session.js'

const API = 'https://api2.cursor.sh/aiserver.v1.GrokBotService'

export function loadAuth() {
  const envToken = process.env.GROK_BOT_ACCESS_TOKEN || ''
  const envMachine = process.env.GROK_BOT_MACHINE_ID || ''
  if (envToken && envMachine) {
    return {
      accessToken: envToken,
      machineId: envMachine,
      clientVersion: process.env.GROK_BOT_CLIENT_VERSION || '0.78.1',
    }
  }
  const local = loadLocalSession()
  if (local) return local
  const home = process.env.DSH_HOME || join(homedir(), '.dsh')
  const file = process.env.GROK_BOT_SESSION || join(home, 'grok-bot.json')
  let stored = {}
  if (file && existsSync(file)) stored = JSON.parse(readFileSync(file, 'utf8'))
  if (stored.accessToken && stored.machineId) {
    return {
      accessToken: stored.accessToken,
      machineId: stored.machineId,
      clientVersion: stored.clientVersion || process.env.GROK_BOT_CLIENT_VERSION || '0.78.1',
    }
  }
  throw new Error('还没有读到本机的 Grok Bot 登录。先打开 Grok Bot 并保持登录，然后重试。')
}

function checksum(machineId) {
  const tick = Math.floor(Date.now() / 1_000_000)
  const buf = [
    (tick / 2 ** 40) & 255,
    (tick / 2 ** 32) & 255,
    (tick / 2 ** 24) & 255,
    (tick / 2 ** 16) & 255,
    (tick / 2 ** 8) & 255,
    tick & 255,
  ]
  let mixer = 165
  for (let i = 0; i < buf.length; i++) {
    mixer = ((buf[i] ^ mixer) + (i % 256)) & 255
    buf[i] = mixer
  }
  const prefix = Buffer.from(buf).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  return prefix + machineId
}

export async function rpc(auth, method, payload, timeoutMs = 40000) {
  const ctrl = new AbortController()
  const timer = setTimeout(() => ctrl.abort(), timeoutMs)
  try {
    const res = await fetch(`${API}/${method}`, {
      method: 'POST',
      signal: ctrl.signal,
      headers: {
        'content-type': 'application/json',
        'connect-protocol-version': '1',
        authorization: `Bearer ${auth.accessToken}`,
        'x-cursor-checksum': checksum(auth.machineId),
        'x-cursor-client-type': 'sand',
        'x-cursor-client-version': auth.clientVersion,
        'x-cursor-client-os': 'linux',
        'x-cursor-client-source': 'sand-desktop',
        'x-ghost-mode': 'true',
        'user-agent': `Sand/${auth.clientVersion}`,
      },
      body: JSON.stringify(payload),
    })
    const text = await res.text()
    let doc = null
    try { doc = text ? JSON.parse(text) : null } catch { doc = { error: text } }
    if (!res.ok) {
      const error = new Error(doc?.message || doc?.error || `Grok Bot 接口返回 ${res.status}`)
      error.status = res.status
      throw error
    }
    return doc
  } finally {
    clearTimeout(timer)
  }
}

function decodeEntry(entry) {
  const body = entry.body || ''
  const padded = body + '='.repeat((4 - (body.length % 4)) % 4)
  const decoded = JSON.parse(Buffer.from(padded, 'base64').toString('utf8'))
  decoded._seq = Number(entry.seq || 0)
  return decoded
}

export function entryText(entry) {
  if (entry.kind === 'send-message') {
    const content = entry.message?.content
    return typeof content === 'string' ? content : ''
  }
  if (entry.kind === 'message' && entry.role === 'user') return entry.content || ''
  return ''
}

function isProgress(text) {
  const trimmed = text.trim()
  return trimmed.length < 40 && (trimmed.includes('正在汇总') || trimmed.includes('正在拉取') || trimmed.includes('正在处理'))
}

export async function listBots(auth) {
  const doc = await rpc(auth, 'ListGrokBotAgents', {})
  return (doc?.agents || []).map((agent) => {
    const kind = agent.kind || ''
    return {
      id: agent.agentId || agent.id,
      name: agent.name || agent.title || '未命名',
      kind: String(kind).endsWith('ROOM') ? 'team' : 'bot',
    }
  }).filter((bot) => bot.id)
}

export function resolveBot(bots, name) {
  const wanted = String(name || '').trim()
  if (!wanted) throw new Error('要指定 Bot 的名字或 id。')
  const hit = bots.find((bot) => bot.id === wanted || bot.name === wanted)
  if (!hit) throw new Error(`没有找到「${wanted}」。先调用 grok_bot_list 看现有名字。`)
  return hit
}

export async function listTranscript(auth, agentId, limit = 80) {
  const transcript = await rpc(auth, 'ListGrokBotTranscriptEntries', { agentId, limit })
  return (transcript?.entries || []).map(decodeEntry).sort((left, right) => left._seq - right._seq)
}

export function turnResult(bot, replies, ready) {
  const list = (replies || []).map((item) => String(item || '').trim()).filter((item) => item && !isProgress(item))
  const picked = (ready ? list.findLast((item) => ready(item)) : list.at(-1)) || ''
  if (!picked) return null
  return {
    id: bot.id,
    name: bot.name,
    kind: bot.kind,
    reply: ready ? picked : list.join('\n\n'),
    replies: list,
  }
}

async function dispatchMessage(auth, bot, text) {
  const nonce = randomUUID()
  const doc = await rpc(auth, 'SendGrokBotUserMessage', {
    agentId: bot.id,
    messageId: nonce,
    text,
    sentAtMs: String(Date.now()),
    source: 'GROK_BOT_CLIENT_SURFACE_DESKTOP',
    initiator: 'GROK_BOT_USER_MESSAGE_INITIATOR_USER',
    sendSource: 'GROK_BOT_SEND_SOURCE_CHAT',
    isFork: false,
  })
  const delivery = doc?.delivery || ''
  if (String(delivery).includes('REFUSED') || doc?.dispatched === false) {
    throw new Error(doc?.refusal || 'Bot 拒绝了这条消息。')
  }
  return nonce
}

export async function collectReplies({ listEntries, nonce, bot, ready, settleMs = 3000, timeoutSec, onUpdate, sleep, now }) {
  const clock = now || Date.now
  const pause = sleep || ((ms) => new Promise((resolve) => setTimeout(resolve, ms)))
  const deadline = clock() + Math.min(Math.max(timeoutSec || 120, 15), 180) * 1000
  let last = ''
  let stableSince = 0
  let seen = null
  while (clock() < deadline) {
    const entries = await listEntries()
    const user = entries.find((entry) => entry.clientNonce === nonce)
    if (user) {
      const replies = entries
        .filter((entry) => entry.kind === 'send-message' && entry._seq > user._seq)
        .map(entryText)
      const turn = turnResult(bot, replies, ready)
      if (turn) {
        seen = turn
        onUpdate?.(turn)
        const newest = ready ? turn.reply : turn.replies.at(-1)
        if (settleMs <= 0) return { ...turn, settled: true }
        if (newest === last) {
          if (clock() - stableSince >= settleMs) return { ...turn, settled: true }
        } else {
          last = newest
          stableSince = clock()
        }
      }
    }
    const left = deadline - clock()
    if (left <= 0) break
    await pause(Math.min(2000, left))
  }
  if (seen) return { ...seen, settled: false }
  throw new Error(`「${bot.name}」在时限内没有回复。可以打开 Grok Bot 看这条对话。`)
}

function publish(job, turn, settled, note) {
  job.reply = turn.reply
  job.replies = turn.replies
  job.settled = settled
  job.note = note
  job.updatedAt = Date.now()
}

export async function enqueue(auth, bot, text, timeoutSec, ready, settleMs = 3000, finish) {
  const nonce = await dispatchMessage(auth, bot, text)
  const job = openJob(bot)
  void collectReplies({
    listEntries: () => listTranscript(auth, bot.id, 100),
    nonce,
    bot,
    ready,
    settleMs,
    timeoutSec,
    onUpdate(turn) {
      publish(job, turn, false, '已经收到一部分。后台还在等这一轮说完，先做别的事。')
    },
  }).then((turn) => {
    publish(job, turn, turn.settled, turn.settled ? '' : '等到时限，下面是已经收到的消息。')
    if (!finish) {
      job.status = 'done'
      return
    }
    try {
      job.extra = finish(turn) || {}
      job.status = 'done'
    } catch (err) {
      job.status = 'error'
      job.error = err.message
      job.note = err.message
    }
  }).catch((err) => {
    job.status = 'error'
    job.error = err.message
    job.note = err.message
    job.updatedAt = Date.now()
  })
  return showJob(job)
}

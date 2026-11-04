#!/usr/bin/env node
import { registerAskTools } from './ask.js'
import { enqueue, entryText, listBots, listTranscript, loadAuth, resolveBot, rpc } from './host.js'
import { registerJailbreakTools } from './jailbreak.js'
import { registerMemoryTools } from './memory.js'
import { registerMoreTools } from './more.js'

function jsonSchema(parameters) {
  const properties = {}
  const required = []
  for (const [key, spec] of Object.entries(parameters || {})) {
    const property = { type: spec.type }
    if (spec.description) property.description = spec.description
    if (spec.items) property.items = spec.items
    properties[key] = property
    if (spec.required) required.push(key)
  }
  return { type: 'object', properties, required, additionalProperties: false }
}

function loadTools() {
  const tools = []
  const ctx = { tools: { register(tool) { tools.push(tool) } } }
  const deps = {
    loadAuth,
    listBots,
    resolveBot,
    enqueue,
    rpc,
    listTranscript,
    entryText,
    defineTool: (tool) => tool,
    renderJson() { return [] },
  }
  registerMemoryTools(ctx, deps)
  registerMoreTools(ctx, deps)
  registerAskTools(ctx, deps)
  registerJailbreakTools(ctx, deps)
  return tools
}

const tools = loadTools()

function toolResult(value, isError) {
  return {
    content: [{ type: 'text', text: typeof value === 'string' ? value : JSON.stringify(value, null, 2) }],
    ...(isError ? { isError: true } : {}),
  }
}

async function callTool(name, args) {
  const tool = tools.find((item) => item.name === name)
  if (!tool) throw new Error(`没有这个工具：${name}`)
  return tool.execute(args || {})
}

function respond(id, result, error) {
  if (id === undefined || id === null) return
  const message = error
    ? { jsonrpc: '2.0', id, error: { code: -32603, message: error.message || String(error) } }
    : { jsonrpc: '2.0', id, result }
  const body = JSON.stringify(message)
  process.stdout.write(`Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`)
}

async function handle(message) {
  const { id, method, params } = message
  if (!method || method.startsWith('notifications/')) return
  if (method === 'initialize') {
    respond(id, {
      protocolVersion: params?.protocolVersion || '2024-11-05',
      capabilities: { tools: { listChanged: false } },
      serverInfo: { name: 'grok-bot', version: '0.2.8' },
    })
    return
  }
  if (method === 'ping') {
    respond(id, {})
    return
  }
  if (method === 'tools/list') {
    respond(id, {
      tools: tools.map((tool) => ({
        name: tool.name,
        description: tool.description,
        inputSchema: jsonSchema(tool.parameters),
      })),
    })
    return
  }
  if (method === 'tools/call') {
    try {
      const value = await callTool(params?.name, params?.arguments)
      respond(id, toolResult(value))
    } catch (err) {
      respond(id, toolResult(err.message || String(err), true))
    }
    return
  }
  respond(id, null, new Error(`不支持的方法：${method}`))
}

let buffer = Buffer.alloc(0)
process.stdin.on('data', (chunk) => {
  buffer = Buffer.concat([buffer, chunk])
  for (;;) {
    if (buffer[0] === 0x7b) {
      const end = buffer.indexOf(0x0a)
      if (end < 0) return
      const line = buffer.subarray(0, end).toString('utf8').trim()
      buffer = buffer.subarray(end + 1)
      if (line) handle(JSON.parse(line)).catch((err) => respond(null, null, err))
      continue
    }
    const sep = buffer.indexOf('\r\n\r\n')
    if (sep < 0) return
    const header = buffer.subarray(0, sep).toString('utf8')
    const match = header.match(/Content-Length:\s*(\d+)/i)
    if (!match) {
      buffer = buffer.subarray(sep + 4)
      continue
    }
    const length = Number(match[1])
    const start = sep + 4
    if (buffer.length < start + length) return
    const body = buffer.subarray(start, start + length).toString('utf8')
    buffer = buffer.subarray(start + length)
    handle(JSON.parse(body)).catch((err) => respond(null, null, err))
  }
})

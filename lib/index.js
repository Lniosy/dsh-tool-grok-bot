import { defineTool } from '@deepseek-ai/dsh-tools'
import { registerAskTools } from './ask.js'
import { SKILL_BODY, SKILL_DESCRIPTION, SKILL_NAME, SKILL_WHEN } from './guide.js'
import { enqueue, entryText, listBots, listTranscript, loadAuth, resolveBot, rpc } from './host.js'
import { registerJailbreakTools } from './jailbreak.js'
import { registerMemoryTools } from './memory.js'
import { registerMoreTools } from './more.js'

export { collectReplies, turnResult } from './host.js'

export const name = 'grok-bot'
export const inject = ['tools', 'skills']

const objectSchema = { type: 'object', additionalProperties: true }

function renderJson(_args, value) {
  return [{ type: 'text', text: JSON.stringify(value, null, 2) }]
}

export function apply(ctx) {
  ctx.skills.register({
    name: SKILL_NAME,
    description: SKILL_DESCRIPTION,
    whenToUse: SKILL_WHEN,
    content: SKILL_BODY,
    source: 'runtime',
    invocation: { modelInvocable: true, userInvocable: true },
  })

  const deps = { loadAuth, listBots, resolveBot, enqueue, rpc, listTranscript, defineTool, renderJson, entryText }
  registerMemoryTools(ctx, deps)
  registerMoreTools(ctx, deps)
  registerAskTools(ctx, deps)
  registerJailbreakTools(ctx, deps)
}

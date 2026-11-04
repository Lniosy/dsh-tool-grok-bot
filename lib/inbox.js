const jobs = globalThis.__dshToolGrokBotWaits || new Map()
globalThis.__dshToolGrokBotWaits = jobs

function prune() {
  const now = Date.now()
  for (const [id, job] of jobs) {
    if (job.status !== 'pending' && now - job.updatedAt > 60 * 60 * 1000) jobs.delete(id)
  }
  const finished = [...jobs.values()].filter((job) => job.status !== 'pending').sort((a, b) => a.startedAt - b.startedAt)
  while (jobs.size > 40 && finished.length) {
    jobs.delete(finished.shift().waitId)
  }
}

export function openJob(bot) {
  prune()
  const job = {
    waitId: `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`,
    status: 'pending',
    bot,
    reply: '',
    replies: [],
    error: '',
    note: '已发送。后台在等回复，先继续别的工作。',
    settled: false,
    extra: {},
    startedAt: Date.now(),
    updatedAt: Date.now(),
  }
  jobs.set(job.waitId, job)
  return job
}

export function getJob(waitId) {
  return jobs.get(String(waitId || '')) || null
}

export function listJobs() {
  return [...jobs.values()].sort((a, b) => a.startedAt - b.startedAt).slice(-20)
}

export function showJob(job) {
  if (!job) return null
  return {
    status: job.status,
    waitId: job.waitId,
    id: job.bot.id,
    name: job.bot.name,
    kind: job.bot.kind,
    reply: job.reply,
    replies: job.replies,
    settled: job.settled,
    ...(job.error ? { error: job.error } : {}),
    ...(job.note ? { note: job.note } : {}),
    ...job.extra,
  }
}

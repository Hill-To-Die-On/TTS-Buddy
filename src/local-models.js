import { spawn } from 'node:child_process';
import { chooseChatModel, chooseOllama } from './player.js';

const ollama = 'http://127.0.0.1:11434';
const lmStudio = 'http://127.0.0.1:1234';
const unsloth = 'http://127.0.0.1:8888';
const contextLength = 2048;
const maxModelBytes = 6_000_000_000;
const probeTimeout = 60_000;

export const defaultModel = 'qwen3:4b-instruct-2507-q4_K_M';
const downloads = [
  { model: defaultModel, size: '2.5 GB' },
  { model: 'qwen2.5:1.5b', size: '986 MB' },
];

const probe = {
  scores: { buddy: 5, human: 6 },
  hand: [{ slot: 1, card: 'Jam' }, { slot: 2, card: 'Boost' }],
  legalActions: ['1:1', '1:2'],
  previews: [
    { actionId: '1:1', buddy: 5, human: 5 },
    { actionId: '1:2', buddy: 7, human: 6 },
  ],
};

function problem(error) {
  if (error.name === 'TimeoutError') return 'timed out';
  if (error.status) return 'HTTP ' + error.status;
  if (error instanceof TypeError) return 'could not connect';
  return error.message;
}

async function request(url, { body, key, timeout = 2500 } = {}) {
  const response = await fetch(url, {
    method: body ? 'POST' : 'GET',
    headers: {
      ...(body && { 'content-type': 'application/json' }),
      ...(key && { authorization: 'Bearer ' + key }),
    },
    body: body && JSON.stringify(body),
    signal: AbortSignal.timeout(timeout),
    redirect: 'error',
  });
  if (!response.ok) throw Object.assign(Error('Local provider unavailable'), { status: response.status });
  return response.json();
}

async function inventory(provider, url, field, key, report) {
  try {
    const data = await request(url, { key });
    if (!Array.isArray(data[field])) throw Error('unexpected model list');
    return data[field];
  } catch (error) {
    report(provider + ' model list unavailable (' + problem(error) + ').');
    return undefined;
  }
}

function textModel(name) {
  return typeof name === 'string' && name.length > 0 && !/[\u0000-\u001f\u007f]/.test(name) &&
    !/(embed|rerank|whisper|speech|tts|guard|coder|:cloud\b|-cloud\b|^https?:)/i.test(name);
}

function smallEnough(size) {
  return Number.isFinite(size) && size > 0 && size <= maxModelBytes;
}

function ollamaCandidate(model, size) {
  return {
    label: 'Ollama ' + model,
    priority: model === defaultModel ? 0 : 3,
    size,
    prepare: async () => (snapshot, timeoutMs) => chooseOllama(snapshot, { model, timeoutMs, contextLength }),
  };
}

function lmCandidate(model, key) {
  const instance = model.loaded_instances?.find(item => item?.id)?.id;
  return {
    label: 'LM Studio ' + model.key,
    priority: instance ? 1 : /(?:^|\/)qwen3-4b-instruct-2507$/i.test(model.key) ? 2 : 3,
    size: model.size_bytes,
    prepare: async () => {
      let id = instance;
      if (!id) {
        const loaded = await request(lmStudio + '/api/v1/models/load', {
          body: { model: model.key, context_length: contextLength }, key, timeout: probeTimeout,
        });
        if (loaded.status !== 'loaded' || !loaded.instance_id) throw Error('model did not load');
        id = loaded.instance_id;
      }
      return (snapshot, timeoutMs) => chooseChatModel(snapshot, {
        model: id, baseUrl: lmStudio, key, timeoutMs, structured: true,
      });
    },
  };
}

function pullOllama(model) {
  return new Promise((resolve, reject) => {
    const command = process.platform === 'win32' ? 'ollama.exe' : 'ollama';
    const child = spawn(command, ['pull', model], {
      stdio: 'inherit',
      env: { ...process.env, OLLAMA_HOST: ollama },
    });
    child.once('error', () => reject(Error('could not start the Ollama command')));
    child.once('close', code => {
      if (code === 0) resolve();
      else reject(Error('Ollama did not complete the download'));
    });
  });
}

export async function selectLocalPlayer({
  report = () => {}, progress = () => () => {}, confirmDownload, pull = pullOllama,
  lmStudioKey, unslothKey,
} = {}) {
  const [ollamaModels, lmModels, unslothModels] = await Promise.all([
    inventory('Ollama', ollama + '/api/tags', 'models', undefined, report),
    inventory('LM Studio', lmStudio + '/api/v1/models', 'models', lmStudioKey, report),
    inventory('Unsloth Studio', unsloth + '/v1/models', 'data', unslothKey, report),
  ]);

  const candidates = [];
  for (const model of ollamaModels ?? []) {
    if (!textModel(model.name) || !smallEnough(model.size) || model.remote_host || model.remote_model ||
        !/^(?:qwen|llama|gemma|mistral|phi|granite|smollm)/i.test(model.details?.family ?? '')) continue;
    candidates.push(ollamaCandidate(model.name, model.size));
  }
  for (const model of lmModels ?? []) {
    if (model.type !== 'llm' || !['gguf', 'mlx'].includes(model.format) ||
        !textModel(model.key)) continue;
    if (!smallEnough(model.size_bytes) && !model.loaded_instances?.some(item => item?.id)) continue;
    candidates.push(lmCandidate(model, lmStudioKey));
  }
  for (const model of unslothModels ?? []) {
    if (model.loaded !== true || !textModel(model.id)) continue;
    candidates.push({
      label: 'Unsloth Studio ' + model.id,
      priority: 2,
      size: 0,
      prepare: async () => (snapshot, timeoutMs) => chooseChatModel(snapshot, {
        model: model.id, baseUrl: unsloth, key: unslothKey, timeoutMs,
      }),
    });
  }

  async function tryModel(candidate) {
    report('Testing ' + candidate.label + ' on a sample turn.');
    const stop = progress();
    let failure;
    try {
      const choose = await candidate.prepare();
      if (await choose(probe, probeTimeout) !== '1:2') throw Error('missed the winning move');
      return { label: candidate.label, choose: snapshot => choose(snapshot) };
    } catch (error) {
      failure = problem(error);
    } finally {
      stop();
    }
    report(candidate.label + ' failed the startup check (' + failure + ').');
  }

  candidates.sort((a, b) => a.priority - b.priority || a.size - b.size);
  for (const candidate of candidates.slice(0, 3)) {
    const player = await tryModel(candidate);
    if (player) return player;
  }

  const offer = ollamaModels && downloads.find(({ model }) => !ollamaModels.some(entry => entry.name === model));
  if (!offer) return undefined;
  if (await confirmDownload?.(offer) === true) {
    try {
      await pull(offer.model);
    } catch (error) {
      report('Download failed (' + problem(error) + ').');
      report('To retry manually, run ollama pull ' + offer.model);
      return undefined;
    }
    return tryModel(ollamaCandidate(offer.model, 0));
  }
  report('To install a suggested local model manually, run ollama pull ' + offer.model);
}

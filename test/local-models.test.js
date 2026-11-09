import assert from 'node:assert/strict';
import test from 'node:test';
import { defaultModel, selectLocalPlayer } from '../src/local-models.js';

const ollama = 'http://127.0.0.1:11434';
const lmStudio = 'http://127.0.0.1:1234';
const unsloth = 'http://127.0.0.1:8888';
const smallModel = 'qwen2.5:1.5b';
const model = { name: defaultModel, size: 2500000000, details: { family: 'qwen3' } };
const lmModel = { key: 'qwen3-4b-instruct-2507', type: 'llm', format: 'gguf', size_bytes: 2500000000, loaded_instances: [] };
const turn = {
  scores: { buddy: 4, human: 2 },
  legalActions: ['9:1'],
  hand: [{ slot: 1, card: 'Boost' }],
  previews: [{ actionId: '9:1', buddy: 6, human: 2 }],
};
const chatReply = choice => ({ choices: [{ message: { content: JSON.stringify({ choice }) } }] });

function mockServers(t, routes) {
  const requests = [];
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    const body = options.body && JSON.parse(options.body);
    requests.push({ url, body, options });
    assert.equal(options.redirect, 'error');
    if (!routes[url]) throw new TypeError('fetch failed');
    return Response.json(routes[url](body, options));
  });
  return requests;
}

test('an Ollama load timeout falls through to the installed LM Studio model', async t => {
  const logs = [];
  const requests = mockServers(t, {
    [ollama + '/api/tags']: () => ({ models: [model] }),
    [ollama + '/api/generate']: () => { throw new DOMException('Request timed out', 'TimeoutError'); },
    [lmStudio + '/api/v1/models']: () => ({ models: [
      { ...lmModel, key: 'embedding-model', type: 'embedding' },
      { ...lmModel, key: 'remote-model', format: 'api' },
      { ...lmModel, key: 'huge-model', size_bytes: 20000000000 },
      lmModel,
    ] }),
    [lmStudio + '/api/v1/models/load']: body => {
      assert.deepEqual(body, { model: lmModel.key, context_length: 2048 });
      return { status: 'loaded', instance_id: 'local-qwen-instance' };
    },
    [lmStudio + '/v1/chat/completions']: body => {
      assert.equal(body.model, 'local-qwen-instance');
      const choices = body.response_format.json_schema.schema.properties.choice.enum;
      return chatReply(choices.length === 1 ? 'A' : 'B');
    },
  });
  const player = await selectLocalPlayer({ report: line => logs.push(line), confirmDownload: assert.fail });
  assert.match(player.label, /^LM Studio .*qwen3/);
  assert.match(logs.join('\n'), /Ollama.*timed out/i);
  assert.equal(requests.find(({ url }) => url.endsWith('/generate')).body.options.num_ctx, 2048);
  assert.equal(await player.choose(turn), '9:1');
});

test('a valid but losing probe response is rejected, and only the active Unsloth model is tried', async t => {
  const requests = mockServers(t, {
    [ollama + '/api/tags']: () => ({ models: [model, { ...model, name: 'qwen3:cloud', remote_host: 'https://ollama.com' }] }),
    [ollama + '/api/generate']: () => ({ response: '{"choice":"A"}' }),
    [unsloth + '/v1/models']: () => ({ data: [
      { id: 'unsloth/unloaded-GGUF', loaded: false },
      { id: 'unsloth/already-loaded-GGUF', loaded: true },
    ] }),
    [unsloth + '/v1/chat/completions']: (body, options) => {
      assert.equal(body.model, 'unsloth/already-loaded-GGUF');
      assert.equal(options.headers.authorization, 'Bearer example-key');
      return chatReply('B');
    },
  });
  const player = await selectLocalPlayer({ unslothKey: 'example-key', confirmDownload: assert.fail });
  assert.match(player.label, /^Unsloth Studio/);
  assert.equal(requests.filter(({ url }) => url.endsWith('/generate')).length, 1);
});

test('Ollama keeps the reduced context for ordinary turns after the startup probe', async t => {
  mockServers(t, {
    [ollama + '/api/tags']: () => ({ models: [model] }),
    [ollama + '/api/generate']: body => {
      assert.equal(body.options.num_ctx, 2048);
      assert.equal(body.think, false);
      const choices = body.format.properties.choice.enum;
      return { response: JSON.stringify({ choice: choices.length === 1 ? 'A' : 'B' }) };
    },
  });
  const player = await selectLocalPlayer({ confirmDownload: assert.fail });
  assert.equal(await player.choose(turn), '9:1');
});

test('an approved download installs an allowlisted model once and verifies it before use', async t => {
  let downloaded = false;
  mockServers(t, {
    [ollama + '/api/tags']: () => ({ models: [] }),
    [ollama + '/api/generate']: body => {
      assert.ok(downloaded);
      assert.equal(body.model, defaultModel);
      return { response: '{"choice":"B"}' };
    },
  });
  const player = await selectLocalPlayer({
    confirmDownload: async ({ model }) => {
      assert.equal(model, defaultModel);
      return true;
    },
    pull: async name => {
      assert.equal(downloaded, false);
      assert.equal(name, defaultModel);
      downloaded = true;
    },
  });
  assert.match(player.label, /^Ollama /);
});

test('a failed installed model offers a smaller alternative and declining leaves it untouched', async t => {
  const requests = mockServers(t, {
    [ollama + '/api/tags']: () => ({ models: [model] }),
    [ollama + '/api/generate']: () => ({ response: 'I choose option B.' }),
  });
  const logs = [];
  const player = await selectLocalPlayer({
    confirmDownload: async ({ model }) => {
      assert.equal(model, smallModel);
      return false;
    },
    pull: assert.fail,
    report: line => logs.push(line),
  });
  assert.equal(player, undefined);
  assert.equal(requests.filter(({ url }) => url.endsWith('/generate')).length, 1);
  assert.match(logs.join('\n'), /ollama pull qwen2\.5:1\.5b/);
});

test('headless startup neither downloads nor suggests pulling an already installed model', async t => {
  const logs = [];
  mockServers(t, {
    [ollama + '/api/tags']: () => ({ models: [model, { ...model, name: smallModel }] }),
    [ollama + '/api/generate']: () => ({ response: '{}' }),
  });
  assert.equal(await selectLocalPlayer({ pull: assert.fail, report: line => logs.push(line) }), undefined);
  assert.doesNotMatch(logs.join('\n'), /ollama pull/);
});

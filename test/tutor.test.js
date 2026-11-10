import assert from 'node:assert/strict';
import test from 'node:test';
import { validateSnapshot } from '../src/player.js';
import { Session } from '../src/session.js';
import { explainOllama, groundedNote, tutorPrompt } from '../src/tutor.js';
import { selectLocalPlayer } from '../src/local-models.js';

const step = {
  game: 'signal-run', id: 'tutorial-1', stepId: 'boost', step: 4, total: 8, title: 'Boost',
  text: "Boost scores 2 points. You're on 5 here, so a Boost takes you straight to 7 and wins.",
  hint: 'Play the card that wins', needsPractice: true, practiceDone: false,
};
const tutorialSnapshot = {
  protocol: 1, matchId: 'tutorial-1', revision: 6, phase: 'setup', activeSeat: 'human', scores: { human: 0, buddy: 0 },
  hand: {}, legalActions: {}, previews: {}, status: 'tutorial',
  tutorial: { ...step, feedback: 'Charge only gets you to 6.', note: 'Earlier note' },
};

test('tutorial snapshots keep only the step details Buddy needs', () => {
  const checked = validateSnapshot(tutorialSnapshot);
  assert.equal(checked.status, 'tutorial');
  assert.deepEqual(checked.tutorial, step);
  assert.deepEqual(checked.legalActions, []);
  for (const tutorial of [{ ...step, stepId: 'Boost<b>' }, { ...step, text: 'x'.repeat(700) }, { ...step, step: 0 }, null]) {
    assert.throws(() => validateSnapshot({ ...tutorialSnapshot, tutorial }), /Invalid table snapshot/);
  }
  assert.equal(validateSnapshot({ ...tutorialSnapshot, status: 'paused' }).tutorial, undefined);
});

test('the tutor prompt is built from the lesson text alone', () => {
  const { prompt, schema } = tutorPrompt(step);
  assert.match(prompt, /Signal Run/);
  assert.ok(prompt.includes(step.text) && prompt.includes(step.hint));
  assert.match(prompt, /Use only the facts below/);
  assert.deepEqual(schema.required, ['note']);
});

test('a tutor note is one bounded line that adds no new numbers', () => {
  assert.equal(groundedNote('  Boost is worth 2.\nFrom 5 that gets you to 7!  ', step), 'Boost is worth 2. From 5 that gets you to 7!');
  assert.equal(groundedNote('Boost is worth 3 points.', step), null, 'a number that is not in the lesson');
  assert.equal(groundedNote('   ', step), null);
  assert.equal(groundedNote(42, step), null);
  assert.equal(groundedNote('a'.repeat(400), step).length, 240);
});

test('explaining through Ollama asks for a structured note and checks it', async t => {
  let body;
  t.mock.method(globalThis, 'fetch', async (_url, options) => {
    body = JSON.parse(options.body);
    return { ok: true, json: async () => ({ response: JSON.stringify({ note: 'Play the Boost and you go from 5 to 7.' }) }) };
  });
  assert.equal(await explainOllama(step, { model: 'local' }), 'Play the Boost and you go from 5 to 7.');
  assert.equal(body.model, 'local');
  assert.deepEqual(body.format.required, ['note']);
  t.mock.method(globalThis, 'fetch', async () => ({ ok: true, json: async () => ({ response: '{"note":"Boost scores 4."}' }) }));
  await assert.rejects(() => explainOllama(step, { model: 'local' }), /Ungrounded tutorial note/);
});

test('Buddy explains each tutorial step once and never plays during the tutorial', async () => {
  const sent = [];
  const bridge = { request: async message => { sent.push(message); return message.type === 'inspect' ? { snapshot: tutorialSnapshot } : { result: 'applied' }; } };
  const explained = [];
  const session = new Session(bridge, async () => { throw Error('no turns in the tutorial'); }, () => {}, {
    explain: async tutorial => { explained.push(tutorial.stepId); return 'Boost takes you from 5 to 7.'; },
  });
  await session.turn();
  await session.turn();
  assert.deepEqual(explained, ['boost']);
  const teach = sent.filter(message => message.type === 'teach');
  assert.equal(teach.length, 1);
  assert.equal(teach[0].stepId, 'boost');
  assert.equal(teach[0].text, 'Boost takes you from 5 to 7.');
  assert.equal(sent.filter(message => message.type === 'play').length, 0);
  assert.equal(session.mode, 'running');
});

test('a failed explanation is not retried, does not pause Buddy and leaves the lesson text alone', async () => {
  const sent = [];
  const bridge = { request: async message => { sent.push(message); return { snapshot: tutorialSnapshot }; } };
  let calls = 0;
  const session = new Session(bridge, async () => '1:1', () => {}, { explain: async () => { calls++; throw Error('timeout'); } });
  await session.turn();
  await session.turn();
  assert.equal(calls, 1);
  assert.equal(session.mode, 'running');
  assert.equal(sent.filter(message => message.type !== 'inspect').length, 0);
  const quiet = new Session(bridge, async () => '1:1');
  await quiet.turn();
  assert.equal(sent.filter(message => message.type !== 'inspect').length, 0, 'the baseline has nothing to explain');
});

test('a selected local model can also explain tutorial steps', async t => {
  t.mock.method(globalThis, 'fetch', async (url, options) => {
    const body = options.body && JSON.parse(options.body);
    if (url === 'http://127.0.0.1:1234/api/v1/models') {
      return Response.json({ models: [{ key: 'qwen3-4b-instruct-2507', type: 'llm', format: 'gguf', size_bytes: 2500000000, loaded_instances: [{ id: 'loaded-1' }] }] });
    }
    if (url === 'http://127.0.0.1:1234/v1/chat/completions') {
      const name = body.response_format?.json_schema?.name;
      const content = name === 'tutorial_note' ? { note: 'Boost takes you from 5 to 7.' } : { choice: 'B' };
      return Response.json({ choices: [{ message: { content: JSON.stringify(content) } }] });
    }
    throw new TypeError('fetch failed');
  });
  const player = await selectLocalPlayer();
  assert.equal(typeof player.explain, 'function');
  assert.equal(await player.explain(step), 'Boost takes you from 5 to 7.');
});

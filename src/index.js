import { appendFileSync } from 'node:fs';
import { createInterface } from 'node:readline';
import { createInterface as createPrompt } from 'node:readline/promises';
import { setTimeout as sleep } from 'node:timers/promises';
import { Bridge } from './bridge.js';
import { historyRecord } from './history.js';
import { defaultModel, selectLocalPlayer } from './local-models.js';
import { Session } from './session.js';
import { chooseBaseline, chooseOllama, preloadOllama, publicDescription } from './player.js';
import { startLoadingBar } from './startup-progress.js';

const baseline = process.argv.includes('--baseline');
const local = process.argv.includes('--local');
const customUrl = process.env.TTS_BUDDY_OLLAMA_URL;
const model = process.env.TTS_BUDDY_MODEL || (local && customUrl ? defaultModel : undefined);
const baseUrl = customUrl || 'http://127.0.0.1:11434';
if (!baseline && !local && !model) {
  console.error('Set TTS_BUDDY_MODEL to an installed local Ollama model, or start with --baseline.');
  process.exit(1);
}

const bridge = new Bridge();
try {
  await bridge.start();
} catch {
  console.error('Cannot listen on 127.0.0.1:39998. Close another external editor or Buddy instance.');
  process.exit(1);
}

let label = 'deterministic';
let choose = async snapshot => chooseBaseline(snapshot);
if (!baseline && model) {
  label = 'local model ' + model;
  choose = snapshot => chooseOllama(snapshot, { model, baseUrl });
  if (local) {
    console.log('Loading ' + model + ' in Ollama. This can take up to two minutes.');
    const stopProgress = startLoadingBar(process.stdout);
    try {
      await preloadOllama({ model, baseUrl }).finally(stopProgress);
    } catch (error) {
      const detail = error.status ? 'HTTP ' + error.status : error.name === 'TimeoutError' ? 'timed out' : error.message;
      console.error('Ollama could not load the configured model ' + model + ' (' + detail + ').');
      console.error('Check the model and server settings, or clear them to let Buddy discover local models.');
      bridge.close();
      process.exit(1);
    }
  }
} else if (!baseline) {
  console.log('Looking for local models in Ollama, LM Studio and Unsloth Studio...');
  const player = await selectLocalPlayer({
    report: console.log,
    progress: () => startLoadingBar(process.stdout),
    lmStudioKey: process.env.TTS_BUDDY_LM_STUDIO_API_KEY,
    unslothKey: process.env.TTS_BUDDY_UNSLOTH_API_KEY,
    confirmDownload: process.stdin.isTTY && process.stdout.isTTY ? async ({ model, size }) => {
      const input = createPrompt({ input: process.stdin, output: process.stdout });
      try {
        const answer = await input.question('Download ' + model + ' through Ollama (about ' + size + ')? [y/N] ');
        return /^(y|yes)$/i.test(answer.trim());
      } finally {
        input.close();
      }
    } : undefined,
  });
  if (!player) {
    console.error('Buddy could not start a local model.');
    console.error('Start Ollama or the LM Studio local server. For Unsloth Studio, enable its local API and load a text model.');
    console.error('See START HERE.txt or docs/quick-start.md for server and API key setup. For deterministic play, run start-buddy.cmd --baseline.');
    bridge.close();
    process.exit(1);
  }
  label = player.label;
  choose = player.choose;
}

let lastRevision = '';
let historyError = false;
const session = new Session(bridge, choose, snapshot => {
  const revisionKey = `${snapshot.matchId}:${snapshot.revision}`;
  if (revisionKey === lastRevision) return;
  lastRevision = revisionKey;
  if (snapshot.phase !== 'setup' && !historyError) {
    try {
      appendFileSync('tts-buddy-history.jsonl', JSON.stringify(historyRecord(snapshot)) + '\n', 'utf8');
    } catch {
      historyError = true;
      console.error('Could not write the local turn history.');
    }
  }
  const status = snapshot.phase === 'finished'
    ? 'winner ' + snapshot.winner
    : 'turn ' + snapshot.activeSeat + ', ' + snapshot.status;
  console.log(`Score Human ${snapshot.scores.human} — Buddy ${snapshot.scores.buddy}; ${status}`);
  const action = publicDescription(snapshot);
  if (action) console.log(action);
});

let stopped = false;
const input = createInterface({ input: process.stdin, output: process.stdout });
input.on('line', line => {
  switch (line.trim().toLowerCase()) {
    case 'pause':
      session.pause();
      console.log('Buddy paused.');
      break;
    case 'resume':
      session.resume();
      console.log('Buddy resumed; the table will be inspected again.');
      break;
    case 'quit':
    case 'stop':
      session.pause();
      stopped = true;
      break;
    default:
      console.log('Commands: pause, resume, stop');
  }
});

console.log('Buddy started (' + label + '). Commands: pause, resume, stop. Use the table controls for takeover.');
while (!stopped) {
  if (session.mode === 'running') {
    await session.turn();
    if (session.mode === 'paused') {
      console.log('Buddy paused after an uncertain response. Check the table, then type resume.');
    }
  }
  await sleep(1000);
}
input.close();
bridge.close();

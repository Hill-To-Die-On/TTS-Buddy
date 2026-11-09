import { appendFileSync } from 'node:fs';
import { createInterface } from 'node:readline';
import { setTimeout as sleep } from 'node:timers/promises';
import { Bridge } from './bridge.js';
import { historyRecord } from './history.js';
import { Session } from './session.js';
import { chooseBaseline, chooseOllama, preloadOllama, publicDescription } from './player.js';

const baseline = process.argv.includes('--baseline');
const local = process.argv.includes('--local');
const model = process.env.TTS_BUDDY_MODEL || (local ? 'qwen3:4b-instruct-2507-q4_K_M' : undefined);
const baseUrl = process.env.TTS_BUDDY_OLLAMA_URL || 'http://127.0.0.1:11434';
if (!baseline && !model) {
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

if (local && !baseline) {
  console.log(`Loading ${model} in Ollama. This can take up to two minutes.`);
  try {
    await preloadOllama({ model, baseUrl });
  } catch {
    console.error(`Ollama could not load ${model}. Start Ollama, check that the model is installed, then launch Buddy again.`);
    bridge.close();
    process.exit(1);
  }
}

let lastRevision = '';
let historyError = false;
const choose = baseline
  ? async snapshot => chooseBaseline(snapshot)
  : snapshot => chooseOllama(snapshot, { model, baseUrl });
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

console.log(`Buddy started (${baseline ? 'deterministic' : `local model ${model}`}). Commands: pause, resume, stop. Use the table controls for takeover.`);
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

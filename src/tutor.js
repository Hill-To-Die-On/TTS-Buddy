import { chatComplete, generateOllama } from './player.js';

// Tutorial mode: the table owns the lessons and checks every practice move with the game's rules.
// The model only rephrases the step on screen in friendlier words, shown beside the lesson text.
export const NOTE_LIMIT = 240;
const gameNames = { 'signal-run': 'Signal Run', 'flamme-rouge': 'Flamme Rouge' };

export function tutorPrompt(step) {
  const facts = [
    `${step.title}.`,
    step.text,
    step.needsPractice && step.hint ? `Next, the player will try this: ${step.hint}.` : '',
  ].filter(Boolean).join('\n');
  const game = gameNames[step.game] || 'a tabletop game';
  const prompt = `You are Buddy, a friendly opponent teaching a new player ${game}, one step at a time. ` +
    `This is step ${step.step} of ${step.total}. Explain it in one or two short sentences of plain British English. ` +
    "Use only the facts below. Don't add rules, numbers, tactics or anything else that isn't in them.\n" +
    `Facts:\n${facts}\nReturn JSON with note set to your explanation.`;
  const schema = {
    type: 'object',
    properties: { note: { type: 'string', maxLength: NOTE_LIMIT } },
    required: ['note'],
    additionalProperties: false,
  };
  return { prompt, schema };
}

// A note is one line of bounded plain text. As a cheap check against invented rules,
// it may only use numbers that already appear in the lesson.
export function groundedNote(text, step) {
  if (typeof text !== 'string') return null;
  const note = text.replace(/[\u0000-\u001f\u007f]/g, ' ').replace(/\s+/g, ' ').trim().slice(0, NOTE_LIMIT).trim();
  if (!note) return null;
  const known = new Set(`${step.title} ${step.text} ${step.hint ?? ''}`.match(/\d+/g) ?? []);
  if ((note.match(/\d+/g) ?? []).some(number => !known.has(number))) return null;
  return note;
}

function parseNote(raw, step) {
  let note;
  try {
    note = JSON.parse(raw)?.note;
  } catch {
    throw Error('Invalid tutorial note');
  }
  const grounded = groundedNote(note, step);
  if (!grounded) throw Error('Ungrounded tutorial note');
  return grounded;
}

export async function explainOllama(step, { model, baseUrl = 'http://127.0.0.1:11434', timeoutMs = 30000, contextLength } = {}) {
  if (!model) throw Error('Choose a local Ollama model');
  const { prompt, schema } = tutorPrompt(step);
  const data = await generateOllama(baseUrl, timeoutMs, {
    model,
    format: schema,
    options: { temperature: 0, num_predict: 120, ...(contextLength && { num_ctx: contextLength }) },
    ...(contextLength && { think: false }),
    prompt,
  });
  return parseNote(data.response, step);
}

export async function explainChat(step, { model, baseUrl, key, timeoutMs = 30000, structured }) {
  const { prompt, schema } = tutorPrompt(step);
  const content = await chatComplete({
    model, baseUrl, key, timeoutMs, schema, structured, name: 'tutorial_note', maxTokens: 160,
    content: prompt + '\nUse the exact format {"note":"<your explanation>"}.',
  });
  return parseNote(content, step);
}

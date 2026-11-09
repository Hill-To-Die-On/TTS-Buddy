const cards = new Set(['Charge', 'Boost', 'Jam']);

export function validateSnapshot(snapshot) {
  if (snapshot?.hand && !Array.isArray(snapshot.hand) && Object.keys(snapshot.hand).length === 0) {
    snapshot = { ...snapshot, hand: [] };
  }
  if (snapshot?.legalActions && !Array.isArray(snapshot.legalActions) && Object.keys(snapshot.legalActions).length === 0) {
    snapshot = { ...snapshot, legalActions: [] };
  }
  if (snapshot?.previews && !Array.isArray(snapshot.previews) && Object.keys(snapshot.previews).length === 0) {
    snapshot = { ...snapshot, previews: [] };
  }
  if (!snapshot || snapshot.protocol !== 1 || typeof snapshot.matchId !== 'string' ||
      !Number.isSafeInteger(snapshot.revision) || !['playing', 'finished', 'setup'].includes(snapshot.phase) ||
      !['human', 'buddy'].includes(snapshot.activeSeat) || !snapshot.scores ||
      !Array.isArray(snapshot.hand) || !Array.isArray(snapshot.legalActions) ||
      !['running', 'paused', 'manual', 'complete'].includes(snapshot.status)) {
    throw Error('Invalid table snapshot');
  }

  const hand = snapshot.hand.map(card => {
    if (!Number.isSafeInteger(card.slot) || !cards.has(card.card)) throw Error('Invalid table snapshot');
    return { slot: card.slot, card: card.card };
  });
  const legalActions = snapshot.legalActions.map(actionId => {
    if (typeof actionId !== 'string' || !/^\d+:\d+$/.test(actionId)) throw Error('Invalid table snapshot');
    return actionId;
  });
  const previews = (snapshot.previews ?? []).map(preview => {
    if (!legalActions.includes(preview.actionId) || !Number.isSafeInteger(preview.human) ||
        preview.human < 0 || !Number.isSafeInteger(preview.buddy) || preview.buddy < 0) {
      throw Error('Invalid table snapshot');
    }
    return { actionId: preview.actionId, human: preview.human, buddy: preview.buddy };
  });
  const lastAction = snapshot.lastAction && ['human', 'buddy'].includes(snapshot.lastAction.seat) && cards.has(snapshot.lastAction.card)
    ? { seat: snapshot.lastAction.seat, card: snapshot.lastAction.card, effect: String(snapshot.lastAction.effect || '').slice(0, 100) }
    : null;
  return {
    protocol: 1, matchId: snapshot.matchId, revision: snapshot.revision,
    phase: snapshot.phase, activeSeat: snapshot.activeSeat,
    scores: { human: Number(snapshot.scores.human), buddy: Number(snapshot.scores.buddy) },
    hand, legalActions, previews, status: snapshot.status, lastAction,
    winner: ['human', 'buddy', 'draw'].includes(snapshot.winner) ? snapshot.winner : null,
  };
}

export function chooseBaseline(snapshot) {
  const values = { Boost: 2, Jam: 1.5, Charge: 1 };
  const ranked = [...snapshot.hand].sort((a, b) => values[b.card] - values[a.card]);
  return ranked.map(card => `${snapshot.revision}:${card.slot}`).find(id => snapshot.legalActions.includes(id));
}

export function parseModelChoice(text, snapshot) {
  let response;
  try {
    response = JSON.parse(text);
  } catch {
    throw Error('Invalid model response');
  }
  if (!response || typeof response.choice !== 'string' || !/^[A-Z]$/.test(response.choice)) {
    throw Error('Invalid model response');
  }
  const actionId = snapshot.legalActions[response.choice.charCodeAt(0) - 65];
  if (!actionId) throw Error('Invalid model response');
  return actionId;
}

export function publicDescription(snapshot) {
  const action = snapshot.lastAction;
  return action ? `${action.seat === 'buddy' ? 'Buddy' : 'Human'} played ${action.card}.${action.effect ? ' ' + action.effect : ''}` : '';
}

export async function chooseOllama(snapshot, { model, timeoutMs = 30000, baseUrl = 'http://127.0.0.1:11434' } = {}) {
  if (!model) throw Error('Choose a local Ollama model');
  if (snapshot.legalActions.length < 1 || snapshot.legalActions.length > 26) throw Error('Invalid table snapshot');

  const options = snapshot.legalActions.map((actionId, index) => {
    const slot = Number(actionId.split(':')[1]);
    const card = snapshot.hand.find(item => item.slot === slot);
    const preview = snapshot.previews.find(item => item.actionId === actionId);
    if (!card || !preview) throw Error('Invalid table snapshot');
    return { letter: String.fromCharCode(65 + index), card: card.card, ...preview };
  });
  const lines = options.map(option =>
    `${option.letter}: ${option.card} -> Buddy ${option.buddy}, Human ${option.human}${option.buddy >= 7 ? ' (Buddy wins)' : ''}`
  ).join('\n');
  const prompt = `You are Buddy in Signal Run. First to 7 points wins. Choose the best legal action; take an immediate win. Jam reduces the human score by 1, minimum zero. Current score: Buddy ${snapshot.scores.buddy}, Human ${snapshot.scores.human}. Results after each legal play:\n${lines}\nReturn JSON with choice equal to one letter.`;
  const response = await fetch(`${baseUrl}/api/generate`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    signal: AbortSignal.timeout(timeoutMs),
    body: JSON.stringify({
      model, stream: false,
      format: { type: 'object', properties: { choice: { type: 'string', enum: options.map(option => option.letter) } }, required: ['choice'], additionalProperties: false },
      options: { temperature: 0, num_predict: 40 },
      prompt,
    }),
  });
  if (!response.ok) throw Error('Local model unavailable');
  const data = await response.json();
  return parseModelChoice(data.response, snapshot);
}

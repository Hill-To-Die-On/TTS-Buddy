import test from 'node:test';
import assert from 'node:assert/strict';
import {historyRecord} from '../src/history.js';
test('turn history includes only public fields',()=>{const record=historyRecord({matchId:'m',revision:3,phase:'playing',activeSeat:'human',scores:{human:1,buddy:2},status:'running',lastAction:{seat:'buddy',card:'Boost',effect:''},hand:[{card:'Jam'}],humanHand:['Charge'],prompt:'private'},'2026-11-09T00:00:00Z');assert.deepEqual(record,{time:'2026-11-09T00:00:00Z',matchId:'m',revision:3,phase:'playing',activeSeat:'human',scores:{human:1,buddy:2},status:'running',lastAction:{seat:'buddy',card:'Boost',effect:''},winner:null});assert.doesNotMatch(JSON.stringify(record),/Jam|Charge|private/);});

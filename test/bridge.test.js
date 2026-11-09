import test from 'node:test';
import assert from 'node:assert/strict';
import { callbackMessage } from '../src/bridge.js';
test('callback accepts only the active correlated custom message',()=>{const pending={requestId:'a'}; assert.deepEqual(callbackMessage(JSON.stringify({messageID:4,customMessage:{requestId:'a',result:'ok'}}),pending),{requestId:'a',result:'ok'}); for(const input of ['{}','broken',JSON.stringify({messageID:4,customMessage:{requestId:'b'}}),JSON.stringify({messageID:3,customMessage:{requestId:'a'}})]) assert.equal(callbackMessage(input,pending),null);});
test('callback decodes the snapshot string from the TTS transport',()=>{
 const snapshot={scores:{human:0,buddy:1},hand:[{slot:1,card:'Boost'}],legalActions:[]};
 const callback=snapshotJson=>JSON.stringify({messageID:4,customMessage:{requestId:'a',snapshotJson}});
 const pending={requestId:'a'};
 assert.deepEqual(callbackMessage(callback(JSON.stringify(snapshot)),pending),{requestId:'a',snapshot});
 assert.equal(callbackMessage(callback('broken'),pending),null);
 assert.equal(callbackMessage(callback(snapshot),pending),null);
});

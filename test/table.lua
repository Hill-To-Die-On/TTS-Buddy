UI={setXml=function(xml) assert(type(xml)=='string') end}
local sent,encoded
JSON={decode=function() return {} end,encode=function(value) encoded=value; return '{}' end}
function sendExternalMessage(m)
  for _,value in pairs(m) do assert(type(value)~='table') end
  if m.snapshotJson then
    assert(m.snapshotJson=='{}')
    m.snapshot=encoded
  end
  sent=m
end
dofile('tts/Global.lua')
onLoad('')
onExternalMessage({protocol=1,type='inspect',requestId='before'})
assert(sent.snapshot.phase=='setup' and sent.snapshot.status=='paused' and #sent.snapshot.hand==0)
local white={color='White'}
newGame(white)
onExternalMessage({protocol=1,type='inspect',requestId='i'})
assert(sent.snapshot.phase=='playing' and sent.snapshot.activeSeat=='human')
assert(#sent.snapshot.hand==2 and #sent.snapshot.legalActions==0)
playHuman(white,nil,'1')
onExternalMessage({protocol=1,type='inspect',requestId='i2'})
local snap=sent.snapshot
assert(snap.activeSeat=='buddy' and #snap.hand==3 and #snap.legalActions==3)
local req={protocol=1,type='play',requestId='p1',matchId=snap.matchId,revision=snap.revision,actionId=snap.legalActions[1]}
onExternalMessage(req); assert(sent.result=='applied'); local revision=sent.revision
onExternalMessage(req); assert(sent.result=='applied' and sent.revision==revision)
onExternalMessage({protocol=1,type='inspect',requestId='i3'}); assert(sent.snapshot.revision==revision)
onExternalMessage({protocol=1,type='play',requestId='p2',matchId=snap.matchId,revision=snap.revision,actionId=snap.legalActions[1]}); assert(sent.result=='rejected')
print('Signal Run table callbacks passed')
local function paired(hidden,deck)
  local fixture={matchId='paired',revision=8,phase='playing',active='buddy',scores={human=2,buddy=3},hands={human=hidden,buddy={'Boost','Jam'}},deck=deck,lastAction=nil}
  JSON.decode=function() return {state=fixture,receipts={}} end
  onLoad('fixture'); resumeGame(white)
  onExternalMessage({protocol=1,type='inspect',requestId='paired-inspect'})
  return sent.snapshot
end
local a=paired({'Charge'},{'Jam','Boost'})
local b=paired({'Jam'},{'Boost','Jam'})
assert(a.matchId==b.matchId and a.revision==b.revision and #a.hand==#b.hand and #a.legalActions==#b.legalActions)
for i=1,#a.hand do assert(a.hand[i].card==b.hand[i].card and a.legalActions[i]==b.legalActions[i]); assert(a.previews[i].human==b.previews[i].human and a.previews[i].buddy==b.previews[i].buddy) end
assert(a.humanHand==nil and a.deck==nil)
onExternalMessage({protocol=1,type='play',requestId='guess',matchId=b.matchId,revision=b.revision,actionId='abc123'}); assert(sent.result=='rejected' and sent.revision==b.revision)
print('Paired hidden state and guessed ID checks passed')

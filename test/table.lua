local lastXml
UI={setXml=function(xml) assert(type(xml)=='string'); lastXml=xml end}
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
-- Tutorial mode: White starts it, Buddy can't play during it and practice goes through the hand buttons.
local function tutorialView() onExternalMessage({protocol=1,type='inspect',requestId='tutorial-inspect'}); return sent.snapshot end
local blue={color='Blue'}
startTutorial(blue); assert(tutorialView().status~='tutorial','only White can start the tutorial')
resumeGame(white); startTutorial(white)
local tv=tutorialView()
assert(tv.status=='tutorial' and tv.phase=='setup' and #tv.legalActions==0 and #tv.hand==0)
assert(tv.tutorial.stepId=='goal' and tv.tutorial.step==1 and tv.tutorial.total==8 and tv.tutorial.game=='signal-run')
assert(type(tv.tutorial.id)=='string' and tv.tutorial.text:find('7 points',1,true))
assert(lastXml:find('Tutorial 1 of 8',1,true),'the panel shows the step')
onExternalMessage({protocol=1,type='play',requestId='tutorial-play',matchId=b.matchId,revision=b.revision,actionId=b.legalActions[1]})
assert(sent.result=='rejected','Buddy cannot play while the tutorial is open')
onExternalMessage({protocol=1,type='teach',requestId='teach-1',stepId='boost',text='Too early'}); assert(sent.result=='rejected')
onExternalMessage({protocol=1,type='teach',requestId='teach-2',stepId='goal',text='<b>Race</b> & "win"'}); assert(sent.result=='applied')
assert(tutorialView().tutorial.note=='<b>Race</b> & "win"')
assert(lastXml:find('&lt;b&gt;Race&lt;/b&gt; &amp; &quot;win&quot;',1,true) and not lastXml:find('<b>',1,true),'notes are escaped')
tutorialNext(blue); assert(tutorialView().tutorial.stepId=='goal','only White moves the tutorial on')
tutorialNext(white); tutorialNext(white)
assert(tutorialView().tutorial.stepId=='charge')
tutorialNext(white); assert(tutorialView().tutorial.stepId=='charge','practise before moving on')
assert(lastXml:find('onClick="playHuman"',1,true),'the practice hand is shown')
playHuman(white,nil,'1'); assert(tutorialView().tutorial.practiceDone)
tutorialNext(white); assert(tutorialView().tutorial.stepId=='boost')
playHuman(white,nil,'1'); tv=tutorialView().tutorial; assert(not tv.practiceDone and tv.feedback:find('Boost would have won',1,true))
playHuman(white,nil,'2'); assert(tutorialView().tutorial.practiceDone)
onSave(); assert(encoded.tutorial and encoded.tutorial.step==4,'the tutorial is saved with the table')
leaveTutorial(white); tv=tutorialView()
assert(tv.status=='paused' and tv.matchId==b.matchId,'leaving returns to the paused match')
print('Signal Run tutorial table tests passed')

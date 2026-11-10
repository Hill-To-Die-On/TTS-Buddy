-- Tutorial runner tests: a made-up game, then the Signal Run and Flamme Rouge lessons.
dofile('tts/rules.lua')
dofile('tts/tutorial.lua')
dofile('tts/signal-run-tutorial.lua')
dofile('tts/flamme-rouge/rules.lua')
dofile('tts/flamme-rouge/tutorial.lua')
local function eq(a,b,label) assert(a==b,(label or 'value')..': '..tostring(a)..' ~= '..tostring(b)) end

-- The runner knows nothing about any game: lessons supply the text, the practice state and the check.
Tutorial.register('demo',{
  {id='hello',title='Hello',text='Say hello.'},
  {id='press',title='Press two',text='Press 2.',hint='Press 2',
    setup=function() return {pressed=0} end,
    try=function(p,action)
      if action~=1 and action~=2 then return false end
      p.pressed=action
      if action==2 then return true,'correct','Spot on.' end
      return true,'wrong','Not quite, try 2.'
    end},
})
local t=Tutorial.start('demo','tut-1')
local v=Tutorial.view(t)
eq(v.step,1); eq(v.total,2); eq(v.id,'hello'); eq(v.needsPractice,false); eq(v.status,'teaching')
local revision=t.revision
assert(Tutorial.next(t)); assert(t.revision>revision)
v=Tutorial.view(t); eq(v.id,'press'); eq(v.needsPractice,true); eq(v.practiceDone,false); eq(v.hint,'Press 2')
assert(not Tutorial.next(t),'practise before moving on')
revision=t.revision
assert(not Tutorial.attempt(t,3),'an illegal practice move is ignored'); eq(t.revision,revision)
assert(Tutorial.attempt(t,1)); v=Tutorial.view(t)
eq(v.practiceDone,false); eq(v.feedback,'Not quite, try 2.'); eq(t.practice.pressed,0,'a wrong move resets the practice')
assert(Tutorial.attempt(t,2)); v=Tutorial.view(t); eq(v.practiceDone,true); eq(v.feedback,'Spot on.')
assert(not Tutorial.attempt(t,2),'nothing more to practise once it is done')
assert(Tutorial.next(t)); eq(Tutorial.view(t).status,'complete')
assert(not Tutorial.next(t)); assert(not Tutorial.attempt(t,2))
print('Tutorial runner tests passed')

-- Buddy's friendly explanation is only kept for the step on screen, as plain bounded text.
t=Tutorial.start('demo','tut-2')
assert(not Tutorial.setNote(t,'press','Wrong step'))
assert(not Tutorial.setNote(t,'hello',42))
assert(not Tutorial.setNote(t,'hello','   '))
assert(Tutorial.setNote(t,'hello','  Hi\nthere  ')); eq(Tutorial.view(t).note,'Hi there')
assert(Tutorial.setNote(t,'hello',string.rep('a',500))); eq(#Tutorial.view(t).note,280)
Tutorial.next(t); eq(Tutorial.view(t).note,nil,'a new step clears the old note')
assert(Tutorial.start('missing','x')==nil,'unknown games have no tutorial')
print('Tutorial note tests passed')

-- Signal Run: every lesson can be finished, and the practice checks use the real rules.
local sr=Tutorial.start('signal-run','sr')
local seen={}
while Tutorial.view(sr).status~='complete' do
  local view=Tutorial.view(sr); seen[view.id]=true
  assert(#view.title>0 and #view.text>0 and #view.text<=400,'lesson '..view.id..' has short text')
  if view.id=='boost' then
    assert(Tutorial.attempt(sr,1)); eq(Tutorial.view(sr).practiceDone,false,'Charge does not win from 5')
    eq(sr.practice.scores.human,5,'practice resets after a wrong move')
    assert(Tutorial.attempt(sr,2)); eq(Tutorial.view(sr).practiceDone,true); eq(sr.practice.winner,'human')
  elseif view.id=='jam' then
    assert(Tutorial.attempt(sr,1)); eq(Tutorial.view(sr).practiceDone,false,'Charge leaves Buddy on 6')
    assert(Tutorial.attempt(sr,2)); eq(sr.practice.scores.buddy,5); eq(Tutorial.view(sr).practiceDone,true)
  elseif view.needsPractice then
    local done=false
    for slot=1,#sr.practice.hands.human do
      if not done and Tutorial.attempt(sr,slot) then done=Tutorial.view(sr).practiceDone end
    end
    assert(done,'lesson '..view.id..' can be practised')
  end
  assert(Tutorial.next(sr),'lesson '..view.id..' moves on')
end
for _,id in ipairs({'goal','charge','boost','jam','hidden','ending','ready'}) do assert(seen[id],'Signal Run lesson '..id) end
print('Signal Run tutorial tests passed')

-- Flamme Rouge: the practice moves go through the Flamme Rouge rules.
local fr=Tutorial.start('flamme-rouge','fr')
seen={}
while Tutorial.view(fr).status~='complete' do
  local view=Tutorial.view(fr); seen[view.id]=true
  assert(#view.title>0 and #view.text>0 and #view.text<=400,'lesson '..view.id..' has short text')
  if view.id=='energy' then
    assert(not Tutorial.attempt(fr,{type='commit',slot=1}),'draw before choosing')
    assert(Tutorial.attempt(fr,{type='draw',rider='R'})); eq(#fr.practice.hands.human.cards,4)
    eq(Tutorial.view(fr).practiceDone,false,'drawing alone is not the whole step')
    assert(Tutorial.attempt(fr,{type='commit',slot=2})); eq(Tutorial.view(fr).practiceDone,true)
    eq(#fr.practice.decks['human-R'].recycled,3,'the other three are recycled')
  elseif view.id=='slipstream' then
    assert(Tutorial.attempt(fr,{type='commit',slot=1})); eq(Tutorial.view(fr).practiceDone,false,'3 leaves a gap of two')
    assert(Tutorial.attempt(fr,{type='commit',slot=3})); eq(Tutorial.view(fr).practiceDone,false,'5 works but costs more')
    assert(Tutorial.attempt(fr,{type='commit',slot=2})); eq(Tutorial.view(fr).practiceDone,true,'4 is the cheapest way in')
  elseif view.needsPractice then
    error('no check written for practice lesson '..view.id)
  end
  assert(Tutorial.next(fr),'lesson '..view.id..' moves on')
end
for _,id in ipairs({'goal','riders','energy','movement','slipstream','exhaustion','finish','ready'}) do assert(seen[id],'Flamme Rouge lesson '..id) end
print('Flamme Rouge tutorial tests passed')

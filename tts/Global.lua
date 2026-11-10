Rules = {}
local function other(seat) return seat == 'human' and 'buddy' or 'human' end
local function draw(s,seat) if #s.deck > 0 then table.insert(s.hands[seat],table.remove(s.deck)) end end
local function begin(s,seat)
  s.active=seat
  draw(s,seat)
  if #s.hands[seat] == 0 then
    local nextSeat=other(seat)
    if #s.hands[nextSeat] == 0 and #s.deck == 0 then
      s.phase='finished'
      if s.scores.human == s.scores.buddy then s.winner='draw' elseif s.scores.human > s.scores.buddy then s.winner='human' else s.winner='buddy' end
    else s.active=nextSeat; draw(s,nextSeat) end
  end
end
function Rules.new(deck,matchId)
  local s={matchId=matchId,revision=1,phase='playing',active='human',scores={human=0,buddy=0},hands={human={},buddy={}},deck=deck,lastAction=nil}
  for i=1,2 do draw(s,'human'); draw(s,'buddy') end
  begin(s,'human')
  return s
end
function Rules.play(s,seat,slot)
  if s.phase ~= 'playing' or s.active ~= seat or type(slot) ~= 'number' or slot ~= math.floor(slot) or not s.hands[seat][slot] then return false end
  local card=table.remove(s.hands[seat],slot)
  local effect=''
  if card == 'Charge' then s.scores[seat]=s.scores[seat]+1
  elseif card == 'Boost' then s.scores[seat]=s.scores[seat]+2
  elseif card == 'Jam' then s.scores[seat]=s.scores[seat]+1; local target=other(seat); s.scores[target]=math.max(0,s.scores[target]-1); effect=(target=='human' and 'Human' or 'Buddy')..' loses 1 point (minimum zero).'
  else error('Unknown card') end
  s.lastAction={seat=seat,card=card,effect=effect}; s.revision=s.revision+1
  if s.scores[seat] >= 7 then s.phase='finished'; s.winner=seat else begin(s,other(seat)) end
  return true
end
-- Preview uses the same rule transition on a copy and returns only public scores.
function Rules.preview(s,seat,slot)
  local copy={matchId=s.matchId,revision=s.revision,phase=s.phase,active=s.active,scores={human=s.scores.human,buddy=s.scores.buddy},hands={human={},buddy={}},deck={}}
  for _,name in ipairs({'human','buddy'}) do for i,card in ipairs(s.hands[name]) do copy.hands[name][i]=card end end
  for i,card in ipairs(s.deck) do copy.deck[i]=card end
  if not Rules.play(copy,seat,slot) then return nil end
  return {scores=copy.scores}
end

-- Game-agnostic tutorial runner. Each game registers its own ordered lessons. A lesson has an id, a title,
-- short rules text and an optional hint. A practice lesson also has setup(), which builds a practice
-- position, and try(practice, action), which applies the learner's move with that game's own rules and
-- returns applied, outcome ('correct', 'wrong' or 'continue') and feedback. The tutorial state holds only
-- plain data, so a table can save it.
Tutorial = {lessons={}}
local NOTE_LIMIT = 280

function Tutorial.register(game, lessons) Tutorial.lessons[game] = lessons end
local function lessons(t) return Tutorial.lessons[t.game] or {} end
local function lesson(t) if t.status=='teaching' then return lessons(t)[t.step] end end
local function enter(t)
  local l = lesson(t)
  t.practice = l and l.setup and l.setup() or nil
  t.practiceDone = false; t.feedback = nil; t.note = nil
  t.revision = t.revision+1
end

function Tutorial.start(game, id)
  if #(Tutorial.lessons[game] or {})==0 then return nil end
  local t = {game=game, id=id, step=1, status='teaching', revision=0}
  enter(t)
  return t
end

function Tutorial.view(t)
  local total = #lessons(t)
  local l = lesson(t)
  if not l then return {game=t.game, id='complete', step=total, total=total, status='complete', needsPractice=false, practiceDone=true} end
  return {game=t.game, id=l.id, step=t.step, total=total, title=l.title, text=l.text, hint=l.hint,
    needsPractice=l.try~=nil, practiceDone=t.practiceDone, feedback=t.feedback, note=t.note, status=t.status}
end

function Tutorial.next(t)
  local l = lesson(t)
  if not l or (l.try and not t.practiceDone) then return false end
  if t.step>=#lessons(t) then
    t.status = 'complete'; t.practice = nil; t.feedback = nil; t.note = nil; t.revision = t.revision+1
  else
    t.step = t.step+1; enter(t)
  end
  return true
end

function Tutorial.attempt(t, action)
  local l = lesson(t)
  if not l or not l.try or t.practiceDone then return false end
  local applied, outcome, feedback = l.try(t.practice, action)
  if not applied then return false end
  t.feedback = feedback
  if outcome=='correct' then t.practiceDone = true
  elseif outcome=='wrong' then t.practice = l.setup and l.setup() or nil end
  t.revision = t.revision+1
  return true
end

-- Buddy may add a friendlier explanation of the current step. It's kept as one line of plain text,
-- shown beside the lesson text rather than instead of it.
function Tutorial.setNote(t, stepId, text)
  local l = lesson(t)
  if not l or l.id~=stepId or type(text)~='string' then return false end
  text = string.gsub(text, '%c', ' ')
  text = string.gsub(text, '%s+', ' ')
  text = string.match(text, '^%s*(.-)%s*$')
  if text=='' then return false end
  t.note = string.sub(text, 1, NOTE_LIMIT); t.revision = t.revision+1
  return true
end

-- Signal Run lessons for the tutorial runner. Practice moves are played through Rules.play.
local function practice(hand, human, buddy)
  return function()
    local cards = {}
    for i,card in ipairs(hand) do cards[i]=card end
    return {matchId='tutorial', revision=1, phase='playing', active='human', scores={human=human, buddy=buddy},
      hands={human=cards, buddy={'Charge'}}, deck={}}
  end
end
local function play(p, slot) return type(slot)=='number' and Rules.play(p, 'human', slot) end

Tutorial.register('signal-run', {
  {id='goal', title="What you're aiming for",
    text="Signal Run is a quick race to 7 points. You and Buddy take turns, and every card you play scores. The moment either of you reaches 7, the game's over."},
  {id='turn', title='Taking a turn',
    text='On your turn, draw a card if the deck has any left, then play one card from your hand. The deck has 18 cards: eight Charge, six Boost and four Jam. You each start with two.'},
  {id='charge', title='Charge', hint='Play the Charge card',
    text="Charge is the steady one. It scores 1 point. Have a go: play the Charge card from your hand.",
    setup=practice({'Charge'}, 0, 0),
    try=function(p, slot)
      if not play(p, slot) then return false end
      return true, 'correct', "That's 1 point on the board."
    end},
  {id='boost', title='Boost', hint='Play the card that wins',
    text="Boost scores 2 points. You're on 5 here, so a Boost takes you straight to 7 and wins. Pick the card that wins it.",
    setup=practice({'Charge','Boost'}, 5, 3),
    try=function(p, slot)
      if not play(p, slot) then return false end
      if p.winner=='human' then return true, 'correct', "That's the win. Boost gets you from 5 to 7 in one go." end
      return true, 'wrong', 'Charge only gets you to 6. Boost would have won it, so have another go.'
    end},
  {id='jam', title='Jam', hint='Slow Buddy down',
    text="Jam scores 1 point for you and knocks 1 off the other player, though never below zero. Buddy's on 6 and about to win, so slow them down.",
    setup=practice({'Charge','Jam'}, 2, 6),
    try=function(p, slot)
      if not play(p, slot) then return false end
      if p.lastAction.card=='Jam' then return true, 'correct', "Nicely done. You're on 3 and Buddy's back to 5." end
      return true, 'wrong', "Charge gets you a point, but Buddy's still on 6. Jam would have pulled them back to 5."
    end},
  {id='hidden', title='Keeping secrets',
    text="Your hand and the order of the deck are secret. Buddy only gets its own hand, the cards that have been played and the moves it's allowed to make, so it can't peek at yours."},
  {id='ending', title='Running out of cards',
    text="If the deck and both hands run out before anyone reaches 7, the higher score wins, and level scores are a draw. A player with no cards left just skips their turn."},
  {id='ready', title="You're ready",
    text="That's all there is to it. Press New match when you want to play Buddy for real. Pause and Take over are there any time you'd like a breather."},
})

-- Public, non-authoritative visual markers. The rules remain in Rules/state.
Presentation={}
local pending={}
local labels={}
function presentationNoop() end
local function put(tag,name,position,color,label)
  labels[tag]=label
  local existing=getObjectsWithTag(tag)
  if #existing>0 then
    existing[1].editButton({index=0,label=label})
  elseif not pending[tag] then
    pending[tag]=true
    spawnObject({type='BlockSquare',position=position,scale={1.8,0.15,2.5},callback_function=function(obj)
      obj.addTag(tag); obj.setName(name); obj.setLock(true); obj.setColorTint(color)
      obj.createButton({click_function='presentationNoop',function_owner=Global,label=labels[tag],position={0,0.55,0},rotation={0,180,0},width=0,height=0,font_size=230,font_color={1,1,1}})
      pending[tag]=nil
    end})
  end
end
function Presentation.update(s)
  if not s then return end
  local last=s.lastAction and (string.upper(s.lastAction.seat)..'\n'..s.lastAction.card) or 'LAST\n—'
  put('tts-buddy-deck','Signal Run draw pile (display only)',{-3,1,5},{0.12,0.24,0.43},'DECK\n'..#s.deck)
  put('tts-buddy-last','Signal Run last played card (display only)',{3,1,5},{0.35,0.16,0.22},last)
end

local state=nil
local mode='paused'
local receipts={}
local tutorial=nil
local function shuffle(deck) for i=#deck,2,-1 do local j=math.random(i); deck[i],deck[j]=deck[j],deck[i] end end
local function esc(text) return (string.gsub(tostring(text or ''),'[&<>"]',{['&']='&amp;',['<']='&lt;',['>']='&gt;',['"']='&quot;'})) end
local function teaching() return tutorial and tutorial.status=='teaching' end
local function snapshot()
  if teaching() then
    local v=Tutorial.view(tutorial)
    return {protocol=1,matchId=tutorial.id,revision=tutorial.revision,phase='setup',activeSeat='human',scores={human=0,buddy=0},hand={},legalActions={},previews={},status='tutorial',
      tutorial={game=tutorial.game,id=tutorial.id,stepId=v.id,step=v.step,total=v.total,title=v.title,text=v.text,hint=v.hint,needsPractice=v.needsPractice,practiceDone=v.practiceDone,feedback=v.feedback,note=v.note}}
  end
  local hand,legal,previews={},{},{}
  if state then
    for i,card in ipairs(state.hands.buddy) do hand[#hand+1]={slot=i,card=card}; if state.phase=='playing' and state.active=='buddy' and mode=='running' then local id=state.revision..':'..i; legal[#legal+1]=id; local preview=Rules.preview(state,'buddy',i); previews[#previews+1]={actionId=id,human=preview.scores.human,buddy=preview.scores.buddy} end end
    return {protocol=1,matchId=state.matchId,revision=state.revision,phase=state.phase,activeSeat=state.active,scores=state.scores,hand=hand,legalActions=legal,previews=previews,status=state.phase=='finished' and 'complete' or mode,lastAction=state.lastAction,winner=state.winner}
  end
  return {protocol=1,matchId='',revision=0,phase='setup',activeSeat='human',scores={human=0,buddy=0},hand={},legalActions={},previews={},status='paused'}
end
local function renderTutorial()
  local v=Tutorial.view(tutorial)
  local heading,body,prompt,hand,next='Tutorial complete','Press New match to play Buddy for real, or Leave tutorial to go back.','','',''
  if v.status~='complete' then
    heading='Tutorial '..v.step..' of '..v.total..': '..v.title
    body=v.text
    prompt=v.feedback or ''
    if v.needsPractice and not v.practiceDone then
      if prompt=='' then prompt='Try it: '..(v.hint or 'make your move') end
      for i,card in ipairs(tutorial.practice.hands.human) do hand=hand..'<Button onClick="playHuman" id="'..i..'" text="'..esc(card)..'" width="100" height="38" />' end
    else next='<Button onClick="tutorialNext" text="Next"/>' end
  end
  local note=v.note and ('Buddy: '..v.note) or ''
  return '<Panel width="900" height="330" position="0 0 -20" color="#172536EE"><VerticalLayout padding="10" spacing="5"><Text text="'..esc(heading)..'" fontSize="20" color="#FFFFFF"/><Text text="'..esc(body)..'" fontSize="16" color="#FFFFFF" preferredHeight="70"/><Text text="'..esc(note)..'" fontSize="16" fontStyle="Italic" color="#C9E4FF" preferredHeight="45"/><Text text="'..esc(prompt)..'" fontSize="16" color="#FFE08A"/><HorizontalLayout visibility="White" preferredHeight="40">'..hand..'</HorizontalLayout><HorizontalLayout preferredHeight="40">'..next..'<Button onClick="leaveTutorial" text="Leave tutorial"/><Button onClick="newGame" text="New match"/></HorizontalLayout></VerticalLayout></Panel>'
end
local function render()
  if tutorial then UI.setXml(renderTutorial()); return end
  local heading='Signal Run — start a new match'
  local hand=''
  local last=''
  if state then
    heading='Human '..state.scores.human..' — Buddy '..state.scores.buddy..' | Deck '..#state.deck..' | '..(state.phase=='finished' and ('Winner: '..state.winner) or ('Turn: '..state.active..' | '..mode))
    if state.lastAction then last=state.lastAction.seat..' played '..state.lastAction.card..'. '..state.lastAction.effect end
    local seat=(mode=='manual' and state.active=='buddy') and 'buddy' or 'human'
    for i,card in ipairs(state.hands[seat]) do hand=hand..'<Button onClick="playHuman" id="'..i..'" text="'..esc(card)..'" width="100" height="38" />' end
  end
  local xml='<Panel width="900" height="230" position="0 0 -20" color="#172536EE"><VerticalLayout padding="10" spacing="5"><Text text="'..esc(heading)..'" fontSize="20" color="#FFFFFF"/><Text text="'..esc(last)..'" fontSize="16" color="#FFFFFF"/><HorizontalLayout preferredHeight="40"><Button onClick="newGame" text="New match"/><Button onClick="pauseGame" text="Pause"/><Button onClick="resumeGame" text="Resume"/><Button onClick="takeOver" text="Take over"/><Button onClick="releaseBuddy" text="Release Buddy"/><Button onClick="startTutorial" text="Tutorial"/></HorizontalLayout><Text text="White seat: your hand (or Buddy hand during takeover)" visibility="White" color="#FFFFFF"/><HorizontalLayout visibility="White" preferredHeight="40">'..hand..'</HorizontalLayout></VerticalLayout></Panel>'
  pcall(Presentation.update,state)
  UI.setXml(xml)
end
function onLoad(saved)
  if saved and saved ~= '' then local ok,data=pcall(JSON.decode,saved); if ok and type(data)=='table' then state=data.state; mode='paused'; receipts=data.receipts or {}; tutorial=data.tutorial end end
  render()
end
function onSave() return JSON.encode({state=state,mode=mode,receipts=receipts,tutorial=tutorial}) end
local function authorized(player) return player and player.color=='White' end
function newGame(player)
  if not authorized(player) then return end
  local deck={}; for i=1,8 do deck[#deck+1]='Charge' end; for i=1,6 do deck[#deck+1]='Boost' end; for i=1,4 do deck[#deck+1]='Jam' end; shuffle(deck)
  tutorial=nil
  state=Rules.new(deck,tostring(os.time())..'-'..tostring(math.random(100000,999999))); receipts={}; mode='running'; render()
end
-- The tutorial pauses any match in progress, and leaving it returns to that match, still paused.
function startTutorial(player)
  if not authorized(player) then return end
  if state and mode~='paused' then mode='paused'; state.revision=state.revision+1 end
  tutorial=Tutorial.start('signal-run','tutorial-'..tostring(os.time())..'-'..tostring(math.random(100000,999999))); render()
end
function tutorialNext(player) if authorized(player) and tutorial then Tutorial.next(tutorial); render() end end
function leaveTutorial(player) if authorized(player) and tutorial then tutorial=nil; render() end end
local function setMode(player,value) if authorized(player) and state then mode=value; state.revision=state.revision+1; render() end end
function pauseGame(player) setMode(player,'paused') end
function resumeGame(player) setMode(player,'running') end
function takeOver(player) setMode(player,'manual') end
function releaseBuddy(player) setMode(player,'running') end
function playHuman(player,value,id)
  if not authorized(player) then return end
  if tutorial then if Tutorial.attempt(tutorial,tonumber(id)) then render() end; return end
  if not state then return end
  local seat=(mode=='manual' and state.active=='buddy') and 'buddy' or 'human'
  if (seat=='human' and mode=='running') or (seat=='buddy' and mode=='manual') then Rules.play(state,seat,tonumber(id)); render() end
end
function onExternalMessage(m)
  if type(m)~='table' or m.protocol~=1 or type(m.requestId)~='string' or #m.requestId>100 then return end
  -- TTS 14.2.2 silently drops callbacks containing nested tables.
  if m.type=='inspect' then sendExternalMessage({requestId=m.requestId,snapshotJson=JSON.encode(snapshot())}); return end
  -- Buddy's plain-language explanation of the current tutorial step, shown beside the lesson text.
  if m.type=='teach' then
    local ok=teaching() and type(m.stepId)=='string' and type(m.text)=='string' and #m.text<=1000 and Tutorial.setNote(tutorial,m.stepId,m.text)
    if ok then render() end
    sendExternalMessage({requestId=m.requestId,result=ok and 'applied' or 'rejected'}); return
  end
  if m.type~='play' then return end
  local cached=receipts[m.requestId]; if cached then sendExternalMessage(cached); return end
  local result={requestId=m.requestId,result='rejected',reason='Action unavailable',revision=state and state.revision or 0}
  if state and not tutorial and mode=='running' and state.phase=='playing' and state.active=='buddy' and m.matchId==state.matchId and m.revision==state.revision and type(m.actionId)=='string' then
    local revision,slot=string.match(m.actionId,'^(%d+):(%d+)$')
    if tonumber(revision)==state.revision and Rules.play(state,'buddy',tonumber(slot)) then result.result='applied'; result.reason=nil; result.revision=state.revision; render() end
  end
  receipts[m.requestId]=result; sendExternalMessage(result)
end

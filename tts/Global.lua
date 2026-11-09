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
local function shuffle(deck) for i=#deck,2,-1 do local j=math.random(i); deck[i],deck[j]=deck[j],deck[i] end end
local function snapshot()
  local hand,legal,previews={},{},{}
  if state then
    for i,card in ipairs(state.hands.buddy) do hand[#hand+1]={slot=i,card=card}; if state.phase=='playing' and state.active=='buddy' and mode=='running' then local id=state.revision..':'..i; legal[#legal+1]=id; local preview=Rules.preview(state,'buddy',i); previews[#previews+1]={actionId=id,human=preview.scores.human,buddy=preview.scores.buddy} end end
    return {protocol=1,matchId=state.matchId,revision=state.revision,phase=state.phase,activeSeat=state.active,scores=state.scores,hand=hand,legalActions=legal,previews=previews,status=state.phase=='finished' and 'complete' or mode,lastAction=state.lastAction,winner=state.winner}
  end
  return {protocol=1,matchId='',revision=0,phase='setup',activeSeat='human',scores={human=0,buddy=0},hand={},legalActions={},previews={},status='paused'}
end
local function render()
  local heading='Signal Run — start a new match'
  local hand=''
  local last=''
  if state then
    heading='Human '..state.scores.human..' — Buddy '..state.scores.buddy..' | Deck '..#state.deck..' | '..(state.phase=='finished' and ('Winner: '..state.winner) or ('Turn: '..state.active..' | '..mode))
    if state.lastAction then last=state.lastAction.seat..' played '..state.lastAction.card..'. '..state.lastAction.effect end
    local seat=(mode=='manual' and state.active=='buddy') and 'buddy' or 'human'
    for i,card in ipairs(state.hands[seat]) do hand=hand..'<Button onClick="playHuman" id="'..i..'" text="'..card..'" width="100" height="38" />' end
  end
  local xml='<Panel width="900" height="230" position="0 0 -20" color="#172536EE"><VerticalLayout padding="10" spacing="5"><Text text="'..heading..'" fontSize="20" color="#FFFFFF"/><Text text="'..last..'" fontSize="16" color="#FFFFFF"/><HorizontalLayout preferredHeight="40"><Button onClick="newGame" text="New match"/><Button onClick="pauseGame" text="Pause"/><Button onClick="resumeGame" text="Resume"/><Button onClick="takeOver" text="Take over"/><Button onClick="releaseBuddy" text="Release Buddy"/></HorizontalLayout><Text text="White seat: your hand (or Buddy hand during takeover)" visibility="White" color="#FFFFFF"/><HorizontalLayout visibility="White" preferredHeight="40">'..hand..'</HorizontalLayout></VerticalLayout></Panel>'
  pcall(Presentation.update,state)
  UI.setXml(xml)
end
function onLoad(saved)
  if saved and saved ~= '' then local ok,data=pcall(JSON.decode,saved); if ok and type(data)=='table' then state=data.state; mode='paused'; receipts=data.receipts or {} end end
  render()
end
function onSave() return JSON.encode({state=state,mode=mode,receipts=receipts}) end
local function authorized(player) return player and player.color=='White' end
function newGame(player)
  if not authorized(player) then return end
  local deck={}; for i=1,8 do deck[#deck+1]='Charge' end; for i=1,6 do deck[#deck+1]='Boost' end; for i=1,4 do deck[#deck+1]='Jam' end; shuffle(deck)
  state=Rules.new(deck,tostring(os.time())..'-'..tostring(math.random(100000,999999))); receipts={}; mode='running'; render()
end
local function setMode(player,value) if authorized(player) and state then mode=value; state.revision=state.revision+1; render() end end
function pauseGame(player) setMode(player,'paused') end
function resumeGame(player) setMode(player,'running') end
function takeOver(player) setMode(player,'manual') end
function releaseBuddy(player) setMode(player,'running') end
function playHuman(player,value,id)
  if not authorized(player) or not state then return end
  local seat=(mode=='manual' and state.active=='buddy') and 'buddy' or 'human'
  if (seat=='human' and mode=='running') or (seat=='buddy' and mode=='manual') then Rules.play(state,seat,tonumber(id)); render() end
end
function onExternalMessage(m)
  if type(m)~='table' or m.protocol~=1 or type(m.requestId)~='string' or #m.requestId>100 then return end
  -- TTS 14.2.2 silently drops callbacks containing nested tables.
  if m.type=='inspect' then sendExternalMessage({requestId=m.requestId,snapshotJson=JSON.encode(snapshot())}); return end
  if m.type~='play' then return end
  local cached=receipts[m.requestId]; if cached then sendExternalMessage(cached); return end
  local result={requestId=m.requestId,result='rejected',reason='Action unavailable',revision=state and state.revision or 0}
  if state and mode=='running' and state.phase=='playing' and state.active=='buddy' and m.matchId==state.matchId and m.revision==state.revision and type(m.actionId)=='string' then
    local revision,slot=string.match(m.actionId,'^(%d+):(%d+)$')
    if tonumber(revision)==state.revision and Rules.play(state,'buddy',tonumber(slot)) then result.result='applied'; result.reason=nil; result.revision=state.revision; render() end
  end
  receipts[m.requestId]=result; sendExternalMessage(result)
end

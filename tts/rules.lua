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

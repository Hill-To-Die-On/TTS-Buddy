-- Flamme Rouge base-game rules for two teams (human and buddy), each with a Rouleur (R) and a Sprinteur (S).
-- Authoritative: the table applies every human and Buddy choice through these functions.
-- Squares are numbered from 1 at the back of the start tile. Lane 1 is the right-hand lane.
FlammeRouge = {}
local FR = FlammeRouge
FR.EXHAUSTION = 2
FR.decks = { R = {3,3,3,4,4,4,5,5,5,6,6,6,7,7,7}, S = {2,2,2,3,3,3,4,4,4,5,5,5,9,9,9} }
FR.riderIds = {'human-R','human-S','buddy-R','buddy-S'}
local KINDS = {'R','S'}

function FR.shuffle(list) for i=#list,2,-1 do local j=math.random(i); list[i],list[j]=list[j],list[i] end end
local function copy(v) if type(v)~='table' then return v end local out={} for k,x in pairs(v) do out[k]=copy(x) end return out end

-- A track is a length, the last square behind the start line, the last square before the finish line,
-- and optional ascent and descent squares.
function FR.track(o)
  local t = {length=o.length, startArea=o.startArea, finishLine=o.finishLine, terrain={}}
  for _,sq in ipairs(o.ascent or {}) do t.terrain[sq]='ascent' end
  for _,sq in ipairs(o.descent or {}) do t.terrain[sq]='descent' end
  return t
end

-- Introductory course from the base-game rulebook: tiles a to u in order, lower-case sides.
-- Squares per tile and the line positions still need checking against the live table.
local TILE_KINDS = {a='start',e='turn',g='turn',h='turn',i='turn',j='turn',k='turn',o='turn',p='turn',q='turn',r='turn',s='turn',t='turn',u='finish'}
local TILE_SQUARES = {start=6, straight=6, turn=2, finish=6}
local START_SQUARES_BEHIND_LINE, SQUARES_PAST_FINISH = 5, 5
function FR.avenueCorsoPaseo()
  local tiles, length = {}, 0
  for letter in string.gmatch('abcdefghijklmnopqrstu', '.') do
    local kind = TILE_KINDS[letter] or 'straight'
    tiles[#tiles+1] = {letter=letter, side='lower', kind=kind, squares=TILE_SQUARES[kind]}
    length = length + TILE_SQUARES[kind]
  end
  return {name='Avenue Corso Paseo', tiles=tiles,
    track=FR.track{length=length, startArea=START_SQUARES_BEHIND_LINE, finishLine=length-SQUARES_PAST_FINISH}}
end

function FR.new(o)
  local s = {game='flamme-rouge', matchId=o.matchId, revision=1, phase='placement', placing=o.first or 'human', round=0,
    track=o.track, riders={}, decks={}, hands={}, committed={}, shuffle=o.shuffle}
  for _,id in ipairs(FR.riderIds) do
    local team, kind = string.match(id, '^(%a+)%-(%a)$')
    s.riders[id] = {team=team, kind=kind, pos=0, lane=0}
    local cards = copy(FR.decks[kind]); (o.shuffle or FR.shuffle)(cards)
    s.decks[id] = {draw=cards, recycled={}, played=0, exhausted=0}
  end
  return s
end

local function lanesAt(s, sq)
  local lanes = {}
  for id,r in pairs(s.riders) do if r.pos==sq then lanes[r.lane]=id end end
  return lanes
end
local function occupied(s, sq) return next(lanesAt(s, sq)) ~= nil end
local function free(s, sq) local l=lanesAt(s, sq); return not (l[1] and l[2]) end
local function settle(s, id, sq) local l=lanesAt(s, sq); s.riders[id].pos=sq; s.riders[id].lane=l[1] and 2 or 1 end

-- Riders from the front: furthest along first, right lane before left.
local function frontToBack(s)
  local list = {}
  for _,id in ipairs(FR.riderIds) do if s.riders[id].pos>0 then list[#list+1]=id end end
  table.sort(list, function(a,b)
    local ra, rb = s.riders[a], s.riders[b]
    if ra.pos~=rb.pos then return ra.pos>rb.pos end
    return ra.lane<rb.lane
  end)
  return list
end

-- Placement: each team places both riders behind the start line, then the other team.
function FR.placementSquares(s)
  local out = {}
  for sq=1,s.track.startArea do if free(s, sq) then out[#out+1]=sq end end
  return out
end
function FR.place(s, team, kind, sq)
  local id = team..'-'..tostring(kind)
  local r = s.riders[id]
  if s.phase~='placement' or s.placing~=team or not r or r.pos~=0 or type(sq)~='number' or sq~=math.floor(sq)
    or sq<1 or sq>s.track.startArea or not free(s, sq) then return false end
  settle(s, id, sq); s.revision = s.revision+1
  local function unplaced(t) for _,k in ipairs(KINDS) do if s.riders[t..'-'..k].pos==0 then return true end end return false end
  if not unplaced(team) then
    local other = team=='human' and 'buddy' or 'human'
    if unplaced(other) then s.placing=other else s.placing=nil; s.phase='energy'; s.round=1 end
  end
  return true
end

-- Energy phase: draw four for one rider, keep one face down, recycle the rest face up under that deck.
function FR.draw(s, team, kind)
  local id = team..'-'..tostring(kind)
  if s.phase~='energy' or s.hands[team] or not s.riders[id] or s.committed[id] then return false end
  local d, cards = s.decks[id], {}
  while #cards<4 do
    if #d.draw==0 then
      if #d.recycled==0 then break end
      (s.shuffle or FR.shuffle)(d.recycled); d.draw=d.recycled; d.recycled={}
    end
    cards[#cards+1] = table.remove(d.draw, 1)
  end
  -- The rulebook doesn't cover a rider with no cards at all; an exhaustion card keeps the race going.
  if #cards==0 then cards[1]=FR.EXHAUSTION; d.exhausted=d.exhausted+1 end
  s.hands[team] = {rider=kind, cards=cards}; s.revision = s.revision+1
  return true
end

local function allCommitted(s)
  for _,id in ipairs(FR.riderIds) do if not s.committed[id] then return false end end
  return true
end
function FR.commit(s, team, slot)
  local hand = s.hands[team]
  if s.phase~='energy' or not hand or type(slot)~='number' or slot~=math.floor(slot) or not hand.cards[slot] then return false end
  local id = team..'-'..hand.rider
  local d = s.decks[id]
  s.committed[id] = table.remove(hand.cards, slot)
  for _,card in ipairs(hand.cards) do d.recycled[#d.recycled+1]=card end
  s.hands[team] = nil; s.revision = s.revision+1
  if allCommitted(s) then FR.resolveRound(s) end
  return true
end

-- Mountains: starting on, entering or crossing an ascent caps movement at 5, and a rider whose 6th or later
-- step would enter an ascent stops just before it. Starting on a descent counts as at least 5.
function FR.effectiveMove(t, pos, value)
  if t.terrain[pos]=='descent' then value=math.max(value, 5) end
  if t.terrain[pos]=='ascent' then return math.min(value, 5) end
  for step=1,value do
    if t.terrain[pos+step]=='ascent' then
      if step<=5 then return math.min(value, 5) end
      return step-1
    end
  end
  return value
end

local function moveRider(s, id, value)
  local r = s.riders[id]
  local from = r.pos
  local target = math.min(from+FR.effectiveMove(s.track, from, value), s.track.length)
  r.pos = -1
  for sq=target,from,-1 do if free(s, sq) then settle(s, id, sq); return end end
  settle(s, id, from)
end

function FR.slipstream(s)
  local seen, list = {}, {}
  for _,r in pairs(s.riders) do if r.pos>0 and not seen[r.pos] then seen[r.pos]=true; list[#list+1]=r.pos end end
  table.sort(list)
  local packs = {}
  for _,sq in ipairs(list) do
    local p = packs[#packs]
    if p and sq==p.last+1 then p.last=sq else packs[#packs+1]={first=sq, last=sq} end
  end
  local function climbing(p) for sq=p.first,p.last do if s.track.terrain[sq]=='ascent' then return true end end return false end
  local i = 1
  while i<#packs do
    local p, q = packs[i], packs[i+1]
    if q.first-p.last==2 and not climbing(p) and s.track.terrain[q.first]~='ascent' then
      for _,r in pairs(s.riders) do if r.pos>=p.first and r.pos<=p.last then r.pos=r.pos+1 end end
      q.first = p.first+1; table.remove(packs, i)
    else i = i+1 end
  end
end

function FR.exhaust(s)
  for _,id in ipairs(FR.riderIds) do
    local r, d = s.riders[id], s.decks[id]
    if r.pos>0 and not occupied(s, r.pos+1) then d.recycled[#d.recycled+1]=FR.EXHAUSTION; d.exhausted=d.exhausted+1 end
  end
end

-- Reveal, move from the front, then remove played cards. A crossing ends the race before the end phase.
function FR.resolveRound(s)
  local moves = {}
  for _,id in ipairs(frontToBack(s)) do
    local value = s.committed[id]
    if value then
      local from = s.riders[id].pos
      moveRider(s, id, value)
      moves[#moves+1] = {rider=id, card=value, from=from, to=s.riders[id].pos}
    end
  end
  for id in pairs(s.committed) do s.decks[id].played=s.decks[id].played+1 end
  s.committed = {}
  s.lastRound = {round=s.round, moves=moves}
  for _,r in pairs(s.riders) do
    if r.pos>s.track.finishLine then
      s.phase='finished'; s.finishOrder=frontToBack(s); s.winner=s.riders[s.finishOrder[1]].team
      return
    end
  end
  FR.slipstream(s); FR.exhaust(s)
  s.round = s.round+1; s.phase = 'energy'
end

function FR.legal(s, team)
  local out = {}
  if s.phase=='placement' and s.placing==team then
    for _,kind in ipairs(KINDS) do
      if s.riders[team..'-'..kind].pos==0 then
        for _,sq in ipairs(FR.placementSquares(s)) do out[#out+1]={type='place', rider=kind, square=sq} end
      end
    end
  elseif s.phase=='energy' then
    local hand = s.hands[team]
    if hand then for i=1,#hand.cards do out[#out+1]={type='commit', slot=i} end
    else for _,kind in ipairs(KINDS) do if not s.committed[team..'-'..kind] then out[#out+1]={type='draw', rider=kind} end end end
  end
  return out
end

-- What one team may know: the public race, plus its own hand, face-down choices and decks.
-- Nothing about the other team's hand, choices or deck order is included.
function FR.view(s, team)
  local riders = {}
  for _,id in ipairs(FR.riderIds) do
    local r = s.riders[id]
    riders[#riders+1] = {id=id, team=r.team, kind=r.kind, pos=r.pos, lane=r.lane}
  end
  local you = {team=team, committed={}, decks={}}
  for _,kind in ipairs(KINDS) do
    local id = team..'-'..kind
    you.committed[kind] = s.committed[id]
    you.decks[kind] = {draw=#s.decks[id].draw, recycled=copy(s.decks[id].recycled)}
  end
  local hand = s.hands[team]
  if hand then you.hand = {rider=hand.rider, cards=copy(hand.cards)} end
  return {game='flamme-rouge', matchId=s.matchId, revision=s.revision, phase=s.phase, round=s.round, placing=s.placing,
    track={length=s.track.length, startArea=s.track.startArea, finishLine=s.track.finishLine},
    riders=riders, lastRound=copy(s.lastRound), winner=s.winner, finishOrder=copy(s.finishOrder), you=you}
end

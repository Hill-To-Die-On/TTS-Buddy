-- Flamme Rouge rules tests. Tracks here are small original fixtures, not the published course,
-- apart from the Avenue Corso Paseo layout check near the end.
dofile('tts/flamme-rouge/rules.lua')
local FR=FlammeRouge
local function eq(a,b,label) assert(a==b,(label or 'value')..': '..tostring(a)..' ~= '..tostring(b)) end
local function copy(v) if type(v)~='table' then return v end local out={} for k,x in pairs(v) do out[k]=copy(x) end return out end
local function same(a,b,path)
  path=path or 'root'
  if type(a)~='table' or type(b)~='table' then assert(a==b,path..': '..tostring(a)..' ~= '..tostring(b)); return end
  for k,x in pairs(a) do same(x,b[k],path..'.'..tostring(k)) end
  for k in pairs(b) do assert(a[k]~=nil,path..'.'..tostring(k)..' only on one side') end
end
local function sorted(list) local out=copy(list); table.sort(out); return out end
local keep=function() end
local flat=FR.track{length=30,startArea=4,finishLine=25}
local function race(track,shuffle) return FR.new{track=track or flat,matchId='test',shuffle=shuffle or keep,first='human'} end
local function staged(positions,track)
  local s=race(track)
  for id,p in pairs(positions) do s.riders[id].pos=p[1]; s.riders[id].lane=p[2] end
  s.phase='energy'; s.round=1; s.placing=nil
  return s
end
local function at(s,id) return s.riders[id].pos,s.riders[id].lane end

-- Independent rider decks with the base-game values.
local s=race()
same(sorted(s.decks['human-R'].draw),{3,3,3,4,4,4,5,5,5,6,6,6,7,7,7})
same(sorted(s.decks['human-S'].draw),{2,2,2,3,3,3,4,4,4,5,5,5,9,9,9})
assert(s.decks['human-R'].draw~=s.decks['buddy-R'].draw,'each rider has its own deck')
print('Flamme Rouge deck tests passed')

-- Starting placement behind the start line, one team at a time, right lane first.
eq(s.phase,'placement'); eq(s.placing,'human')
assert(not FR.place(s,'buddy','R',1),'not buddy turn to place')
assert(not FR.place(s,'human','R',5),'beyond the start line')
assert(not FR.place(s,'human','R',0),'off the track')
assert(FR.place(s,'human','R',4)); eq(select(2,at(s,'human-R')),1,'empty square uses the right lane')
assert(not FR.place(s,'human','R',3),'rider already placed')
assert(FR.place(s,'human','S',4)); eq(select(2,at(s,'human-S')),2)
eq(s.placing,'buddy')
assert(not FR.place(s,'buddy','R',4),'square is full')
same(FR.placementSquares(s),{1,2,3})
assert(FR.place(s,'buddy','R',3)); assert(FR.place(s,'buddy','S',3))
eq(s.phase,'energy'); eq(s.round,1); eq(s.revision,5)
print('Flamme Rouge placement tests passed')

-- Energy phase: draw four for one rider, keep one face down, recycle the rest.
assert(FR.draw(s,'human','S')); same(s.hands.human.cards,{2,2,2,3})
assert(not FR.draw(s,'human','R'),'play for the first rider before drawing for the second')
assert(not FR.commit(s,'human',5),'no such card')
assert(FR.commit(s,'human',4)); eq(s.committed['human-S'],3); same(s.decks['human-S'].recycled,{2,2,2})
assert(not FR.draw(s,'human','S'),'one card per rider per round')
eq(#s.decks['human-R'].draw,15,'drawing for the sprinteur leaves the rouleur deck alone')
assert(FR.draw(s,'human','R')); assert(FR.commit(s,'human',1))
eq(s.phase,'energy','nothing moves until both teams have committed')
eq(at(s,'human-S'),4)
print('Flamme Rouge energy tests passed')

-- Reshuffle recycled cards when the face-down pile runs out, draw what there is, then exhaustion.
local deck=race()
deck.phase='energy'; deck.round=1
deck.decks['buddy-R'].draw={6,7}; deck.decks['buddy-R'].recycled={3,4,5}
assert(FR.draw(deck,'buddy','R')); same(deck.hands.buddy.cards,{6,7,3,4})
same(deck.decks['buddy-R'].draw,{5}); same(deck.decks['buddy-R'].recycled,{})
assert(FR.commit(deck,'buddy',2)); same(deck.decks['buddy-R'].recycled,{6,3,4})
deck.decks['buddy-S'].draw={9}; deck.decks['buddy-S'].recycled={}
assert(FR.draw(deck,'buddy','S')); same(deck.hands.buddy.cards,{9})
assert(FR.commit(deck,'buddy',1))
deck.committed={}; deck.decks['buddy-S'].draw={}; deck.decks['buddy-S'].recycled={}
assert(FR.draw(deck,'buddy','S')); same(deck.hands.buddy.cards,{FR.EXHAUSTION},'an empty deck still lets the rider ride on')
print('Flamme Rouge reshuffle tests passed')

-- Private commitments: Buddy's view is identical whatever the human drew, chose or has left in their decks.
local a=race(); FR.place(a,'human','R',4); FR.place(a,'human','S',4); FR.place(a,'buddy','R',3); FR.place(a,'buddy','S',3)
FR.draw(a,'human','R'); FR.commit(a,'human',1); FR.draw(a,'human','S')
local b=copy(a)
b.committed['human-R']=7; b.hands.human.cards={9,9,9,9}
b.decks['human-R'].draw={7,7,6,6,6,5,5,5,4,4,4}; b.decks['human-S'].recycled={9}
local va,vb=FR.view(a,'buddy'),FR.view(b,'buddy')
same(va,vb)
assert(va.you.hand==nil and va.opponent==nil,'no human hand or commitment in Buddy view')
eq(FR.view(a,'human').you.committed.R,3,'the human sees their own card')
print('Flamme Rouge hidden commitment tests passed')

-- Movement: frontmost first, exact values, pass through riders, never end on a full square.
local m=staged{['human-R']={10,1},['human-S']={10,2},['buddy-R']={8,1},['buddy-S']={5,1}}
m.committed={['human-R']=2,['human-S']=2,['buddy-R']=4,['buddy-S']=7}
FR.resolveRound(m)
local p,l=at(m,'human-R'); eq(p,12); eq(l,1)
p,l=at(m,'human-S'); eq(p,12); eq(l,2)
p,l=at(m,'buddy-R'); eq(p,11,'full square sends the rider back'); eq(l,1)
p,l=at(m,'buddy-S'); eq(p,11,'riders pass through others'); eq(l,2)
eq(#m.lastRound.moves,4); eq(m.lastRound.moves[1].rider,'human-R'); eq(m.lastRound.moves[4].card,7)
same(m.decks['human-R'].recycled,{FR.EXHAUSTION},'empty square ahead means exhaustion')
same(m.decks['buddy-R'].recycled,{},'a rider with someone ahead is not exhausted')
eq(m.phase,'energy'); eq(m.round,2); same(m.committed,{})
print('Flamme Rouge movement tests passed')

-- Slipstreaming from the back: exactly one empty square closes up, merged packs keep going.
local ss=staged{['buddy-S']={3,1},['human-R']={5,1},['buddy-R']={7,1},['human-S']={10,1}}
FR.slipstream(ss)
eq(at(ss,'buddy-S'),5,'moved twice'); eq(at(ss,'human-R'),6,'moved once with the merged pack')
eq(at(ss,'buddy-R'),7); eq(at(ss,'human-S'),10,'two empty squares is too far')
FR.exhaust(ss)
same(ss.decks['buddy-R'].recycled,{FR.EXHAUSTION}); same(ss.decks['human-S'].recycled,{FR.EXHAUSTION})
same(ss.decks['buddy-S'].recycled,{}); same(ss.decks['human-R'].recycled,{})
local lane=staged{['human-R']={8,1},['buddy-R']={9,2}}
FR.exhaust(lane); same(lane.decks['human-R'].recycled,{},'an empty lane ahead is not an empty square')
print('Flamme Rouge slipstream and exhaustion tests passed')

-- Several riders cross in one round: furthest across wins, the right lane breaks a tie.
local f=staged{['buddy-S']={23,1},['human-R']={22,1},['buddy-R']={21,1},['human-S']={20,1}}
f.committed={['buddy-S']=3,['human-R']=5,['buddy-R']=9,['human-S']=2}
FR.resolveRound(f)
eq(f.phase,'finished'); eq(f.winner,'buddy'); eq(at(f,'buddy-R'),30,'stops at the end of the track')
same(f.finishOrder,{'buddy-R','human-R','buddy-S','human-S'})
assert(not FR.draw(f,'human','R'),'no actions after the finish')
local tie=staged{['human-R']={20,1},['buddy-R']={18,1},['human-S']={2,1},['buddy-S']={1,1}}
tie.committed={['human-R']=7,['buddy-R']=9,['human-S']=2,['buddy-S']=2}
FR.resolveRound(tie); eq(tie.winner,'human','right lane wins a tie on the same square')
print('Flamme Rouge finish tests passed')

-- Mountains: ascents cap at 5 and stop slipstreaming, descents give at least 5.
local hill=FR.track{length=40,startArea=4,finishLine=35,ascent={12,13,14},descent={20,21}}
eq(FR.effectiveMove(hill,10,9),5,'crossing an ascent'); eq(FR.effectiveMove(hill,5,9),6,'stop before the ascent')
eq(FR.effectiveMove(hill,12,7),5,'starting on an ascent'); eq(FR.effectiveMove(hill,20,2),5,'descent minimum')
eq(FR.effectiveMove(hill,1,4),4)
local climb=staged({['human-R']={12,1},['buddy-R']={14,1}},hill)
FR.slipstream(climb); eq(at(climb,'human-R'),12,'no slipstream on an ascent')
print('Flamme Rouge mountain tests passed')

-- The introductory course: tiles a to u in order, lower-case sides.
local course=FR.avenueCorsoPaseo()
eq(#course.tiles,21)
local letters=''; for _,tile in ipairs(course.tiles) do letters=letters..tile.letter end
eq(letters,'abcdefghijklmnopqrstu')
eq(course.track.length,78); eq(course.track.startArea,5); eq(course.track.finishLine,73)
eq(next(course.track.terrain),nil,'no mountains on the introductory course')
print('Avenue Corso Paseo layout tests passed')

-- Seeded races with a simple greedy player on both teams always finish with every card accounted for.
local function greedy(state,team)
  local best
  for _,action in ipairs(FR.legal(state,team)) do
    if action.type=='place' and (not best or action.square>best.square) then best=action
    elseif action.type=='draw' and not best then best=action
    elseif action.type=='commit' and (not best or state.hands[team].cards[action.slot]>state.hands[team].cards[best.slot]) then best=action end
  end
  return best
end
for seed=1,20 do
  math.randomseed(seed)
  local game=FR.new{track=FR.avenueCorsoPaseo().track,matchId='seed-'..seed,shuffle=FR.shuffle,first=seed%2==0 and 'buddy' or 'human'}
  local steps=0
  while game.phase~='finished' do
    steps=steps+1; assert(steps<400,'race did not finish')
    local acted=false
    for _,team in ipairs({'human','buddy'}) do
      local action=greedy(game,team)
      if action then
        acted=true
        if action.type=='place' then assert(FR.place(game,team,action.rider,action.square))
        elseif action.type=='draw' then assert(FR.draw(game,team,action.rider))
        else assert(FR.commit(game,team,action.slot)) end
      end
    end
    assert(acted,'someone can always act')
    for id,d in pairs(game.decks) do
      local team=game.riders[id].team
      local held=game.hands[team]; held=(held and team..'-'..held.rider==id) and #held.cards or 0
      local kept=game.committed[id] and 1 or 0
      eq(#d.draw+#d.recycled+held+kept+d.played,15+d.exhausted,'cards conserved for '..id)
    end
  end
  assert(game.winner=='human' or game.winner=='buddy'); eq(#game.finishOrder,4)
end
print('20 seeded Flamme Rouge races passed')

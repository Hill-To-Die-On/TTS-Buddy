-- Flamme Rouge lessons for the tutorial runner. Practice moves go through the FlammeRouge rules.
local FR = FlammeRouge
local function race(positions)
  local s = FR.new{track=FR.avenueCorsoPaseo().track, matchId='tutorial'}
  for id,p in pairs(positions) do s.riders[id].pos=p; s.riders[id].lane=1 end
  s.phase='energy'; s.round=1; s.placing=nil
  return s
end

Tutorial.register('flamme-rouge', {
  {id='goal', title='The race',
    text='Flamme Rouge is a bike race. You run a team of two riders, a Rouleur and a Sprinteur. Get either of them over the finish line first and you win. If several riders cross in the same round, whoever gets furthest wins.'},
  {id='riders', title='Two riders, two decks',
    text="Each rider has their own deck of 15 energy cards. The Rouleur's are steady: three each of 3, 4, 5, 6 and 7. The Sprinteur's are three each of 2, 3, 4 and 5, plus three big 9s for a final dash."},
  {id='energy', title='Choosing your energy', hint='Draw for your Rouleur, then keep one card',
    text='Each round, pick a rider and draw four of their cards. Keep one face down as their move, and the other three go face up under that deck for later. Then do the same for your other rider. Try it with your Rouleur.',
    setup=function() return race{['human-R']=4, ['human-S']=4, ['buddy-R']=3, ['buddy-S']=3} end,
    try=function(p, action)
      if type(action)~='table' then return false end
      if action.type=='draw' and FR.draw(p, 'human', action.rider) then
        return true, 'continue', 'Now keep one of those four face down.'
      end
      if action.type=='commit' and FR.commit(p, 'human', action.slot) then
        return true, 'correct', "That's this round's move for that rider. The other three are back in the deck for later."
      end
      return false
    end},
  {id='movement', title='Moving',
    text="Once everyone has chosen, the cards are turned over. The rider at the front moves first, then the next. Each moves exactly the number on their card. You can ride through others, but if a square is full you stop in the first free one behind it."},
  {id='slipstream', title='Slipstreaming', hint='Pick the cheapest card that catches Buddy',
    text="After moving, a group with exactly one empty square in front of the next group gets pulled up to close the gap. Your Rouleur is on 10 and Buddy's is on 16. Pick the smallest card that gets you into Buddy's slipstream.",
    setup=function()
      local s = race{['human-R']=10, ['buddy-R']=16, ['human-S']=2, ['buddy-S']=1}
      s.hands.human = {rider='R', cards={3,4,5,7}}
      return s
    end,
    try=function(p, action)
      if type(action)~='table' or action.type~='commit' then return false end
      local card = p.hands.human and p.hands.human.cards[action.slot]
      if not card or not FR.commit(p, 'human', action.slot) then return false end
      local lands = 10+FR.effectiveMove(p.track, 10, card)
      if lands==14 then return true, 'correct', "Spot on. You land on 14 and the slipstream pulls you up to 15, right behind Buddy, for only a 4." end
      if lands==15 then return true, 'wrong', 'That works, but a 4 gets you to the same square once the slipstream kicks in, and saves your 5 for later.' end
      if lands<14 then return true, 'wrong', "From there you'd have two empty squares in front, which is too far for the slipstream." end
      return true, 'wrong', "That takes you past Buddy, out in front on your own, which earns an exhaustion card."
    end},
  {id='exhaustion', title='Running out of puff',
    text="Cards you play are gone for good. Then any rider with an empty square right in front of them gets an exhaustion card worth 2, which goes in with their spare cards. Riding at the front is tiring, so it pays to tuck in behind someone."},
  {id='finish', title='The finish',
    text="The race ends in the round someone crosses the finish line. The rider furthest past it wins, and if two share a square, the one in the right-hand lane is ahead."},
  {id='ready', title="You're ready",
    text="That's the lot. Avenue Corso Paseo is flat all the way, so it's a good first race. Later courses add climbs that cap a move at 5, and descents that give you at least 5."},
})

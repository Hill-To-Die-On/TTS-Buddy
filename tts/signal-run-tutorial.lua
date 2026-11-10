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

// Family Dinner: rules and data. No DOM in here, so it runs in Node for tests.
//
// Long card names carry soft hyphens (\u00ad) so they break cleanly on narrow phone cards.
// Effects are plain data, applied by Game.applyFx():
//   dmg, hits, doubleFlustered, fluster (target), block, smug, heal (self),
//   spite, draw, junk / junkCount / junkToDraw.

export const CARDS = {
  // Starters
  backhanded: { name: 'Back\u00adhanded Compli\u00adment', cost: 1, kind: 'insult', text: 'Deal 6.',
    quote: 'Wow, you look SO much better than last year!', fx: { dmg: 6 } },
  changeSubject: { name: 'Change the Subject', cost: 1, kind: 'deflect', text: 'Gain 5 Deflect.',
    quote: 'Sooo... how about that weather?', fx: { block: 5 } },
  theIncident: { name: 'Bring Up The Incident', cost: 2, kind: 'insult', text: 'Deal 13.',
    quote: 'Should we talk about Thanksgiving 2014?', fx: { dmg: 13 } },
  sigh: { name: 'Passive-Aggres\u00adsive Sigh', cost: 0, kind: 'scheme', text: 'Apply 1 Flustered.',
    quote: '*sighs loudly*', fx: { fluster: 1 } },

  // Rewards
  wellActually: { name: 'Well, Actually', cost: 1, kind: 'insult', text: 'Deal 3, three times.',
    quote: 'Well ACTUALLY, studies show...', fx: { dmg: 3, hits: 3 } },
  theWill: { name: 'Mention The Will', cost: 2, kind: 'insult', text: 'Deal 8. Apply 2 Flustered.',
    quote: "So... who's getting the lake house?", fx: { dmg: 8, fluster: 2 } },
  grammar: { name: 'Correct Their Gram\u00admar', cost: 1, kind: 'insult', text: 'Deal 5. Double if Flustered.',
    quote: "It's 'whom', actually.", fx: { dmg: 5, doubleFlustered: true } },
  smugSip: { name: 'Smug Sip of Wine', cost: 1, kind: 'scheme', text: 'Gain 2 Smug.',
    quote: '*sips wine knowingly*', fx: { smug: 2 } },
  vacationPhotos: { name: 'Vaca\u00adtion Photos', cost: 2, kind: 'deflect', text: 'Gain 13 Deflect.',
    quote: "Here's me in Portugal. And again in Portugal.", fx: { block: 13 } },
  fakeLaugh: { name: 'Fake Laugh', cost: 0, kind: 'deflect', text: 'Gain 3 Deflect.',
    quote: 'Haha! Hahaha. Ha.', fx: { block: 3 } },
  complimentCook: { name: 'Compli\u00adment The Cook', cost: 1, kind: 'scheme', text: 'Recover 8. Once per meal.',
    quote: 'Grandma, this is AMAZING.', fx: { heal: 8 }, exhaust: true },
  dishes: { name: 'Volun\u00adteer For Dishes', cost: 1, kind: 'deflect', text: 'Gain 6 Deflect. Draw 1.',
    quote: "I'll help clean up!", fx: { block: 6, draw: 1 } },
  therapySpeak: { name: 'Therapy Speak', cost: 2, kind: 'insult', text: 'Deal 10. Gain 5 Deflect.',
    quote: "I'm going to set a boundary right now.", fx: { dmg: 10, block: 5 } },
  replyAll: { name: 'Reply-All Energy', cost: 3, kind: 'insult', text: 'Deal 24.',
    quote: "You know what? Let's ALL talk about it.", fx: { dmg: 24 } },
  refillWine: { name: 'Refill The Wine', cost: 0, kind: 'scheme', text: '+1 Spite. Draw 1. Once per meal.',
    quote: 'Top me up, please.', fx: { spite: 1, draw: 1 }, exhaust: true },

  // Junk the relatives shove into your deck (this fight only)
  secondHelping: { name: 'Second Help\u00ading', cost: 0, kind: 'junk', text: "Unplayable. You're SO full.",
    quote: '', fx: {}, unplayable: true },
  guilt: { name: 'Guilt', cost: 0, kind: 'junk', text: 'Unplayable. Just disappointed.',
    quote: '', fx: {}, unplayable: true },
};

export const REWARD_POOL = ['wellActually', 'theWill', 'grammar', 'smugSip', 'vacationPhotos', 'fakeLaugh',
  'complimentCook', 'dishes', 'therapySpeak', 'replyAll', 'refillWine', 'sigh', 'theIncident'];

export const RELATIVES = [
  {
    name: 'Aunt Linda', title: 'Wine aunt', course: 'Appetizers', hp: 36, face: '👩‍🦰', prop: '🍷', dish: '🥗',
    intro: "Oh, you came! We weren't sure you would.",
    defeat: 'I... need more chardonnay.',
    moves: [
      { line: 'So... still single, huh?', fx: { dmg: 6 } },
      { line: 'My Brad just bought a SECOND house.', fx: { dmg: 9 } },
      { line: 'You look tired. Are you sleeping okay?', fx: { fluster: 2 } },
      { line: '*refills chardonnay*', fx: { block: 6 } },
    ],
  },
  {
    name: 'Cousin Brad', title: 'Crypto bro', course: 'Main course', hp: 50, face: '😎', prop: '📈', dish: '🍗',
    intro: "Yooo. Still renting? Couldn't be me.",
    defeat: "Bro... that's lowkey crazy. I'm gonna go vape.",
    moves: [
      { line: "Bro, you're still renting? NGMI.", fx: { dmg: 5, hits: 2 } },
      { line: '*flexes in a tank top at dinner*', fx: { smug: 2, block: 5 } },
      { line: "My portfolio's up 400%. What's YOUR salary?", fx: { dmg: 11 } },
      { line: '*explains his Tesla for ten minutes*', fx: { block: 9 } },
    ],
  },
  {
    name: 'Uncle Gary', title: 'Has opinions', course: 'Seconds', hp: 64, face: '🧔', prop: '📺', dish: '🍝',
    intro: "Now I'm not trying to start anything, BUT...",
    defeat: '...Who wants to watch the game?',
    moves: [
      { line: "You know what's wrong with this country?", fx: { dmg: 13 } },
      { line: "Back in MY day we didn't HAVE 'anxiety'.", fx: { dmg: 6, fluster: 2 } },
      { line: '*tells the same joke again, laughs harder*', fx: { smug: 3 } },
      { line: '*turns up the football*', fx: { block: 12 } },
    ],
  },
  {
    name: 'Grandma', title: 'The matriarch', course: 'Dessert', hp: 88, face: '👵', prop: '🧶', dish: '🥧',
    intro: 'Sit, sit. Grandma just wants to talk.',
    defeat: "...You were always my favourite. Don't tell your cousin.",
    moves: [
      { line: 'When are you giving me GRANDCHILDREN?', fx: { dmg: 16 } },
      { line: "You're so THIN! Eat, eat!", fx: { heal: 8, junk: 'secondHelping', junkCount: 2 } },
      { line: "I'm not angry. Just disappointed.", fx: { dmg: 9, junk: 'guilt', junkCount: 1, junkToDraw: true } },
      { line: '*knits silently, judging*', fx: { block: 14, smug: 2 } },
    ],
  },
];

const HAND_SIZE = 5;
const MAX_HAND = 10;
export const MAX_SPITE = 3;

let nextUid = 1;
export function makeCard(id) {
  return { id, uid: nextUid++, ...CARDS[id] };
}

function fighter(name, hp) {
  return { name, maxHp: hp, hp, block: 0, flustered: 0, smug: 0 };
}

export class Game {
  // onEvent(type, data): 'change' | 'say' {who, text} | 'pop' {who, text, tone} | 'hurt' {who, dmg}
  constructor({ rng = Math.random, wait, onEvent } = {}) {
    this.rng = rng;
    this.wait = wait ?? (ms => new Promise(r => setTimeout(r, ms)));
    this.emit = onEvent ?? (() => {});
    this.state = 'title'; // title | combat | reward | lost | won
  }

  get rel() { return RELATIVES[this.relIndex]; }
  get intent() { return this.rel.moves[this.intentIdx]; }

  shuffle(a) {
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(this.rng() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  changed() { this.emit('change'); }

  // ---------- flow ----------

  newRun() {
    this.p = fighter('You', 50);
    this.master = [
      ...Array.from({ length: 4 }, () => makeCard('backhanded')),
      ...Array.from({ length: 4 }, () => makeCard('changeSubject')),
      makeCard('theIncident'),
      makeCard('sigh'),
    ];
    this.relIndex = 0;
    this.log = [];
    this.startFight();
  }

  startFight() {
    this.e = fighter(this.rel.name, this.rel.hp);
    Object.assign(this.p, { block: 0, flustered: 0, smug: 0 });
    this.drawPile = this.shuffle([...this.master]);
    this.hand = [];
    this.discard = [];
    this.exhausted = [];
    this.lastIdx = -1;
    this.turn = 0;
    this.busy = false;
    this.state = 'combat';
    this.say('e', this.rel.intro);
    this.addLog(`${this.rel.name} pulls up a chair.`);
    this.pickIntent();
    this.startPlayerTurn();
    this.changed();
  }

  startPlayerTurn() {
    this.turn++;
    this.p.block = 0;
    if (this.p.flustered > 0) this.p.flustered--;
    this.spite = MAX_SPITE;
    this.drawCards(HAND_SIZE);
  }

  drawCards(n) {
    for (let i = 0; i < n; i++) {
      if (this.hand.length >= MAX_HAND) return;
      if (this.drawPile.length === 0) {
        if (this.discard.length === 0) return;
        this.drawPile = this.shuffle(this.discard);
        this.discard = [];
      }
      this.hand.push(this.drawPile.pop());
    }
  }

  canPlay(c) {
    return this.state === 'combat' && !this.busy && !c.unplayable && c.cost <= this.spite;
  }

  playCard(i) {
    const c = this.hand[i];
    if (!c || !this.canPlay(c)) return false;
    this.spite -= c.cost;
    this.hand.splice(i, 1);
    this.say('p', c.quote);
    this.addLog(`You: "${c.quote}"`);
    this.applyFx(this.p, this.e, c.fx);
    (c.exhaust ? this.exhausted : this.discard).push(c);
    if (this.e.hp <= 0) this.winFight();
    this.changed();
    return true;
  }

  async endTurn() {
    if (this.state !== 'combat' || this.busy) return;
    this.discard.push(...this.hand);
    this.hand = [];
    this.busy = true;
    this.changed();
    await this.wait(450);

    const { p, e } = this;
    e.block = 0;
    if (e.flustered > 0) e.flustered--;
    const move = this.intent;
    this.say('e', move.line);
    this.addLog(`${e.name}: "${move.line}"`);
    this.applyFx(e, p, move.fx);
    this.lastIdx = this.intentIdx;
    this.changed();
    await this.wait(900);

    this.busy = false;
    if (p.hp <= 0) {
      this.state = 'lost';
    } else {
      this.pickIntent();
      this.startPlayerTurn();
    }
    this.changed();
  }

  async winFight() {
    this.busy = true;
    this.say('e', this.rel.defeat);
    this.addLog(`${this.rel.name} is speechless.`);
    this.changed();
    await this.wait(1700);
    this.busy = false;
    if (this.relIndex === RELATIVES.length - 1) {
      this.state = 'won';
    } else {
      this.healed = Math.min(12, this.p.maxHp - this.p.hp);
      this.p.hp += this.healed;
      this.rewards = this.shuffle([...REWARD_POOL]).slice(0, 3).map(makeCard);
      this.state = 'reward';
    }
    this.changed();
  }

  takeReward(card) {
    if (this.state !== 'reward') return;
    if (card) this.master.push(card);
    this.relIndex++;
    this.startFight();
  }

  pickIntent() {
    const options = this.rel.moves.map((_, i) => i).filter(i => i !== this.lastIdx);
    this.intentIdx = options[Math.floor(this.rng() * options.length)];
  }

  // ---------- effects (shared by cards and relatives) ----------

  applyFx(src, dst, fx) {
    let dmg = fx.dmg ?? 0;
    if (dmg > 0) {
      if (fx.doubleFlustered && dst.flustered > 0) dmg *= 2;
      for (let i = 0; i < (fx.hits ?? 1); i++) this.hit(src, dst, dmg);
    }
    if (fx.fluster) {
      dst.flustered += fx.fluster;
      this.pop(dst, 'Flustered!', 'fluster');
    }
    if (fx.block) {
      src.block += fx.block;
      this.pop(src, `+${fx.block} Deflect`, 'block');
    }
    if (fx.smug) {
      src.smug += fx.smug;
      this.pop(src, `+${fx.smug} Smug`, 'smug');
    }
    if (fx.heal) {
      const h = Math.min(fx.heal, src.maxHp - src.hp);
      src.hp += h;
      this.pop(src, `+${h}`, 'heal');
    }
    if (fx.spite) this.spite += fx.spite;
    if (fx.draw) this.drawCards(fx.draw);
    if (fx.junk) {
      for (let i = 0; i < fx.junkCount; i++) {
        const c = makeCard(fx.junk);
        if (fx.junkToDraw) this.drawPile.splice(Math.floor(this.rng() * (this.drawPile.length + 1)), 0, c);
        else this.discard.push(c);
      }
      this.pop(this.p, `+${fx.junkCount} ${CARDS[fx.junk].name}`, 'junk');
    }
  }

  // Short description of a relative's next move, with damage already adjusted.
  describe(fx) {
    const parts = [];
    if (fx.dmg) parts.push(`Insult for ${this.preview(this.e, this.p, fx.dmg)}${fx.hits > 1 ? ` ×${fx.hits}` : ''}`);
    if (fx.fluster) parts.push('Fluster you');
    if (fx.block) parts.push(`Deflect ${fx.block}`);
    if (fx.smug) parts.push(`Gain ${fx.smug} Smug`);
    if (fx.heal) parts.push(`Recover ${fx.heal}`);
    if (fx.junk) parts.push(`Stuff you with ${fx.junkCount} ${CARDS[fx.junk].name}`);
    return parts.join(', ');
  }

  preview(src, dst, base) {
    let d = base + src.smug;
    if (dst.flustered > 0) d = Math.floor(d * 3 / 2);
    return d;
  }

  hit(src, dst, base) {
    if (dst.hp <= 0) return;
    let dmg = this.preview(src, dst, base);
    const absorbed = Math.min(dst.block, dmg);
    dst.block -= absorbed;
    dmg -= absorbed;
    dst.hp = Math.max(0, dst.hp - dmg);
    if (dmg > 0) {
      this.pop(dst, `−${dmg}`, 'dmg');
      this.emit('hurt', { who: dst === this.p ? 'p' : 'e', dmg });
    } else {
      this.pop(dst, 'Deflected!', 'block');
    }
  }

  pop(f, text, tone) { this.emit('pop', { who: f === this.p ? 'p' : 'e', text, tone }); }
  say(who, text) { this.emit('say', { who, text }); }
  addLog(s) {
    this.log.push(s);
    if (this.log.length > 30) this.log.shift();
  }
}

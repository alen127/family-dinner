import { Game, RELATIVES, MAX_SPITE } from './game.js';

const $ = id => document.getElementById(id);
const reduceMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
const KIND_LABEL = { insult: 'Insult', deflect: 'Deflect', scheme: 'Scheme', junk: 'Junk' };

let selected = -1; // index in hand of the card the player is reading
let lastSay = { p: '', e: '' };

const game = new Game({ onEvent });
window.game = game; // handy for poking at in the console

function onEvent(type, data) {
  if (type === 'change') render();
  else if (type === 'say') say(data.who, data.text);
  else if (type === 'pop') pop(data.who, data.text, data.tone);
  else if (type === 'hurt') hurt(data.who);
}

// ---------- rendering ----------

function render() {
  for (const s of document.querySelectorAll('.screen')) s.classList.remove('active');
  const screen = { title: 'title', combat: 'combat', reward: 'reward', lost: 'end', won: 'end' }[game.state];
  $(screen).classList.add('active');
  if (game.state === 'combat') renderCombat();
  else if (game.state === 'reward') renderReward();
  else if (game.state === 'lost' || game.state === 'won') renderEnd();
}

function renderCombat() {
  const { p, e, rel } = game;

  $('courses').innerHTML = RELATIVES.map((r, i) => {
    const cls = i < game.relIndex ? 'done' : i === game.relIndex ? 'now' : '';
    return `<li class="${cls}"><small>${r.course}</small>${r.name}</li>`;
  }).join('');

  $('foe-face').textContent = e.hp <= 0 ? '😶' : rel.face;
  $('foe-prop').textContent = rel.prop;
  $('foe-plate').classList.toggle('rattled', e.hp > 0 && e.hp < e.maxHp / 2);
  $('foe-name').textContent = rel.name;
  $('foe-title').textContent = `${rel.title}, ${rel.course.toLowerCase()}`;
  bar('foe', e);
  $('foe-chips').innerHTML = chips(e);
  $('intent').innerHTML = e.hp > 0 && !game.busy
    ? `<span>Next</span> ${intentIcon(game.intent.fx)} ${game.describe(game.intent.fx)}` : '';

  bar('my', p);
  $('my-chips').innerHTML = chips(p);
  $('spite').innerHTML = `<span class="pips">${Array.from({ length: Math.max(MAX_SPITE, game.spite) },
    (_, i) => `<i class="${i < game.spite ? 'full' : ''}"></i>`).join('')}</span>Spite ${game.spite}`;

  const end = $('end-turn');
  end.disabled = game.busy;
  end.textContent = game.busy ? (e.hp <= 0 ? 'Silence…' : 'Their turn…') : 'End turn';

  $('dish').textContent = rel.dish;
  $('log').innerHTML = game.log.slice(-3).map(l => `<li>${esc(l)}</li>`).join('');
  $('piles').textContent = `Draw pile ${game.drawPile.length}  ·  Discard ${game.discard.length}  ·  Turn ${game.turn}`;

  if (selected >= game.hand.length) selected = -1;
  $('hand').innerHTML = game.hand.map((c, i) => cardHtml(c, i, game.canPlay(c), i === selected)).join('');
  $('hand').classList.toggle('crowded', game.hand.length > 5);
  showPreview();
}

function bar(who, f) {
  $(`${who}-hp-fill`).style.width = `${(100 * f.hp) / f.maxHp}%`;
  $(`${who}-hp`).textContent = `${f.hp} / ${f.maxHp}`;
}

function chips(f) {
  const out = [];
  if (f.block) out.push(`<span class="chip block" title="Absorbs damage until their next turn">🛡️ Deflect ${f.block}</span>`);
  if (f.flustered) out.push(`<span class="chip fluster" title="Takes 50% more damage">😳 Flustered ${f.flustered}</span>`);
  if (f.smug) out.push(`<span class="chip smug" title="Each insult deals this much extra">😏 Smug ${f.smug}</span>`);
  return out.join('');
}

function intentIcon(fx) {
  if (fx.dmg) return '🗯️';
  if (fx.junk) return '🍽️';
  if (fx.fluster) return '😳';
  if (fx.block) return '🛡️';
  return '😏';
}

function cardHtml(c, i, playable, isSelected) {
  return `<button class="card k-${c.kind}${isSelected ? ' selected' : ''}${playable ? '' : ' dim'}"
      data-card="${i}" aria-pressed="${isSelected}"
      aria-label="${esc(c.name)}, costs ${c.cost}. ${esc(c.text)}">
    ${c.unplayable ? '' : `<span class="cost">${c.cost}</span>`}
    <span class="name">${esc(c.name)}</span>
    <span class="kind">${KIND_LABEL[c.kind]}</span>
    <span class="text">${esc(c.text)}</span>
    ${c.quote ? `<span class="quote">“${esc(c.quote)}”</span>` : ''}
    ${i < 9 ? `<kbd>${i + 1}</kbd>` : ''}
  </button>`;
}

// While a card is selected, your speech bubble previews what you're about to say.
function showPreview() {
  const b = $('my-say');
  const c = game.hand[selected];
  if (!c) {
    b.classList.remove('preview');
    b.textContent = lastSay.p;
    b.classList.toggle('show', !!lastSay.p);
    return;
  }
  let hint = 'Tap again to say it';
  if (c.unplayable) hint = 'Unplayable, it just sits there';
  else if (c.cost > game.spite) hint = `Needs ${c.cost} Spite, you have ${game.spite}`;
  else if (game.busy) hint = 'Wait your turn';
  b.innerHTML = `${c.quote ? `“${esc(c.quote)}”` : esc(c.name)}<small>${esc(c.text)} ${hint}.</small>`;
  b.classList.add('show', 'preview');
}

function renderReward() {
  const next = RELATIVES[game.relIndex + 1];
  $('reward-heal').textContent = game.healed
    ? `You splash water on your face. +${game.healed} composure (${game.p.hp} / ${game.p.maxHp}).`
    : `You splash water on your face. Still composed (${game.p.hp} / ${game.p.maxHp}).`;
  $('reward-next').textContent = `Rehearse one comeback for ${next.name}. It goes in your deck for the rest of dinner.`;
  $('reward-cards').innerHTML = game.rewards.map((c, i) => cardHtml(c, i, true, false).replace('data-card', 'data-reward')).join('');
}

function renderEnd() {
  const won = game.state === 'won';
  $('end-face').textContent = won ? '🥧' : '🚪';
  $('end-title').textContent = won ? 'Dinner survived' : 'You stormed out';
  $('end-sub').textContent = won
    ? 'The family is speechless. Grandma slips you $20 on the way out. See you at Christmas.'
    : `…during ${game.rel.course.toLowerCase()}, thanks to ${game.rel.name}. Everyone will talk about this until next Christmas.`;
}

// ---------- feedback ----------

function say(who, text) {
  lastSay[who] = text;
  if (who === 'e') {
    const b = $('foe-say');
    b.textContent = text;
    b.classList.remove('show');
    void b.offsetWidth; // restart the pop-in
    b.classList.add('show');
  } else {
    selected = -1;
    const b = $('my-say');
    b.classList.remove('show', 'preview');
    void b.offsetWidth;
    b.textContent = text;
    b.classList.add('show');
  }
}

function pop(who, text, tone) {
  const el = document.createElement('span');
  el.className = `pop ${tone}`;
  el.textContent = text;
  el.style.setProperty('--dx', `${Math.round(Math.random() * 60 - 30)}px`);
  $(who === 'p' ? 'my-pops' : 'foe-pops').append(el);
  setTimeout(() => el.remove(), 1300);
}

function hurt(who) {
  if (reduceMotion) return;
  const el = who === 'p' ? $('app') : $('foe-plate');
  el.classList.remove('shake');
  void el.offsetWidth;
  el.classList.add('shake');
  if (who === 'p' && navigator.vibrate) navigator.vibrate(60);
}

// Fling the played card toward whoever it affects, then let the game state update.
function flyCard(i) {
  const el = document.querySelector(`[data-card="${i}"]`);
  if (!el || reduceMotion) return;
  const from = el.getBoundingClientRect();
  const kind = game.hand[i].kind;
  const target = (kind === 'insult' || game.hand[i].fx.fluster ? $('foe-plate') : $('spite')).getBoundingClientRect();
  const ghost = el.cloneNode(true);
  ghost.classList.add('ghost');
  Object.assign(ghost.style, { left: `${from.left}px`, top: `${from.top}px`, width: `${from.width}px`, height: `${from.height}px` });
  document.body.append(ghost);
  const dx = target.left + target.width / 2 - (from.left + from.width / 2);
  const dy = target.top + target.height / 2 - (from.top + from.height / 2);
  ghost.animate([
    { transform: 'translate(0, -12px) scale(1.05)', opacity: 1 },
    { transform: `translate(${dx}px, ${dy}px) scale(0.35) rotate(${dx > 0 ? 12 : -12}deg)`, opacity: 0 },
  ], { duration: 380, easing: 'cubic-bezier(.5,0,.75,0)' }).onfinish = () => ghost.remove();
}

function play(i) {
  const c = game.hand[i];
  if (!c || !game.canPlay(c)) return;
  flyCard(i);
  game.playCard(i);
}

// ---------- input ----------

document.addEventListener('click', ev => {
  const t = ev.target.closest('[data-action], [data-card], [data-reward]');
  if (!t) {
    if (selected >= 0 && !ev.target.closest('.hand')) { selected = -1; showPreview(); renderHandSelection(); }
    return;
  }
  if (t.dataset.action === 'start') game.newRun();
  else if (t.dataset.action === 'end-turn') { selected = -1; game.endTurn(); }
  else if (t.dataset.action === 'skip') game.takeReward(null);
  else if (t.dataset.reward !== undefined) game.takeReward(game.rewards[+t.dataset.reward]);
  else if (t.dataset.card !== undefined) {
    const i = +t.dataset.card;
    if (i === selected) play(i);
    else { selected = i; renderHandSelection(); showPreview(); }
  }
});

function renderHandSelection() {
  document.querySelectorAll('#hand .card').forEach((el, i) => {
    el.classList.toggle('selected', i === selected);
    el.setAttribute('aria-pressed', i === selected);
  });
}

document.addEventListener('keydown', ev => {
  if (ev.repeat || ev.ctrlKey || ev.metaKey || ev.altKey) return;
  if (game.state === 'combat') {
    if (ev.key === ' ' || ev.key === 'e') { ev.preventDefault(); selected = -1; game.endTurn(); }
    else if (ev.key >= '1' && ev.key <= '9') play(+ev.key - 1);
    else if (ev.key === 'Escape') { selected = -1; renderHandSelection(); showPreview(); }
  } else if (game.state === 'reward') {
    if (ev.key >= '1' && ev.key <= '3') game.takeReward(game.rewards[+ev.key - 1]);
    else if (ev.key === 's') game.takeReward(null);
  } else if (ev.key === 'Enter' && !ev.target.closest('button')) {
    game.newRun();
  }
});

function esc(s) {
  return String(s).replace(/[&<>"]/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' })[ch]);
}

render();

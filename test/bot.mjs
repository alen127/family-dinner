import { Game, RELATIVES } from '../game.js';
const runs = 2000; let wins = 0; const lost = [0, 0, 0, 0]; let errors = 0;
for (let r = 0; r < runs; r++) {
  const g = new Game({ wait: async () => {} });
  g.newRun();
  let guard = 0;
  while (g.state !== 'lost' && g.state !== 'won' && guard++ < 5000) {
    if (g.state === 'reward') { g.takeReward(g.rewards[0]); continue; }
    if (g.busy) { await new Promise(r => setTimeout(r, 0)); continue; }
    let best = -1;
    g.hand.forEach((c, i) => { if (g.canPlay(c) && (best < 0 || c.cost > g.hand[best].cost)) best = i; });
    if (best >= 0) g.playCard(best); else await g.endTurn();
    // invariants
    for (const f of [g.p, g.e]) if (f.hp < 0 || f.hp > f.maxHp || f.block < 0 || Number.isNaN(f.hp)) errors++;
    if (g.state === 'combat' && g.intent === undefined) errors++;
  }
  if (guard >= 5000) errors++;
  if (g.state === 'won') wins++; else lost[g.relIndex]++;
}
console.log(`wins ${wins}/${runs} (${(100 * wins / runs).toFixed(1)}%), losses by relative ${JSON.stringify(lost)}, invariant errors ${errors}`);

extends Control
## Family Dinner: game flow, combat and all drawing (immediate-mode via _draw).

const Data := preload("res://data.gd")

const W := 1280.0
const H := 720.0
const HAND_SIZE := 5
const MAX_HAND := 10
const MAX_SPITE := 3

const BG := Color(0.22, 0.13, 0.10)
const WALLPAPER := Color(0.30, 0.18, 0.14)
const WOOD := Color(0.42, 0.25, 0.13)
const CLOTH := Color(0.93, 0.89, 0.80)
const INK := Color(0.15, 0.1, 0.08)
const PAPER := Color(0.97, 0.94, 0.86)
const RED := Color(1, 0.35, 0.3)
const BLUE := Color(0.5, 0.75, 1)
const GOLD := Color(1, 0.8, 0.2)
const PINK := Color(1, 0.5, 1)
const KIND_COLORS := [Color(0.78, 0.26, 0.24), Color(0.26, 0.46, 0.76), Color(0.33, 0.6, 0.34), Color(0.4, 0.4, 0.4)]

enum State { TITLE, COMBAT, REWARD, GAME_OVER, VICTORY }

# --- run state ---
var state := State.TITLE
var p: Data.Fighter
var e: Data.Fighter
var spite := 0
var rel_index := 0
var master: Array = []
var draw_pile: Array = []
var hand: Array = []
var discard: Array = []
var exhausted: Array = []
var intent_idx := -1
var last_idx := -1
var busy := false
var turn := 0
var reward_choices: Array = []
var healed := 0

# --- presentation state ---
var p_line := ""
var e_line := ""
var p_line_t := 0.0
var e_line_t := 0.0
var log_lines: Array[String] = []
var popups: Array = []  # {text, pos, t, col}
var shake := 0.0
var enemy_flash := 0.0
var clickables: Array = []  # [Rect2, Callable], rebuilt every frame; later entries win

var font: Font
var bold: FontVariation
var italic: FontVariation


func _ready() -> void:
	font = ThemeDB.fallback_font
	bold = FontVariation.new()
	bold.base_font = font
	bold.variation_embolden = 0.8
	italic = FontVariation.new()
	italic.base_font = font
	italic.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)


func rel() -> Dictionary:
	return Data.RELATIVES[rel_index]


func intent() -> Dictionary:
	return rel().moves[intent_idx]


# ================= Game flow =================

func new_run() -> void:
	p = Data.Fighter.new("You", 50)
	master = Data.starter_deck()
	rel_index = 0
	log_lines.clear()
	start_fight()


func start_fight() -> void:
	e = Data.Fighter.new(rel().name, rel().hp)
	p.block = 0
	p.flustered = 0
	p.smug = 0
	draw_pile = master.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard.clear()
	exhausted.clear()
	last_idx = -1
	turn = 0
	state = State.COMBAT
	say_e(rel().intro)
	add_log("--- %s: %s pulls up a chair ---" % [rel().course, rel().name])
	pick_intent()
	start_player_turn()


func start_player_turn() -> void:
	turn += 1
	p.block = 0
	if p.flustered > 0:
		p.flustered -= 1
	spite = MAX_SPITE
	draw_cards(HAND_SIZE)


func draw_cards(n: int) -> void:
	for i in n:
		if hand.size() >= MAX_HAND:
			return
		if draw_pile.is_empty():
			if discard.is_empty():
				return
			draw_pile.append_array(discard)
			discard.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())


func can_play(c: Dictionary) -> bool:
	return not busy and not c.get("unplayable", false) and c.cost <= spite


func play_card(i: int) -> void:
	if state != State.COMBAT or i < 0 or i >= hand.size():
		return
	var c: Dictionary = hand[i]
	if not can_play(c):
		return
	spite -= c.cost
	hand.remove_at(i)
	say_p(c.quote)
	add_log("You: \"%s\"" % c.quote)
	apply_fx(p, e, c.fx)
	if c.get("exhaust", false):
		exhausted.append(c)
	else:
		discard.append(c)
	if e.dead():
		win_fight()


func end_turn() -> void:
	if state != State.COMBAT or busy:
		return
	discard.append_array(hand)
	hand.clear()
	enemy_turn()


func enemy_turn() -> void:
	busy = true
	await get_tree().create_timer(0.4).timeout
	e.block = 0
	if e.flustered > 0:
		e.flustered -= 1
	var move := intent()
	say_e(move.line)
	add_log("%s: \"%s\"" % [e.name, move.line])
	apply_fx(e, p, move.fx)
	last_idx = intent_idx
	await get_tree().create_timer(0.8).timeout
	busy = false
	if p.dead():
		state = State.GAME_OVER
		return
	pick_intent()
	start_player_turn()


func win_fight() -> void:
	busy = true
	say_e(rel().defeat)
	add_log("%s is speechless." % rel().name)
	await get_tree().create_timer(1.6).timeout
	busy = false
	if rel_index == Data.RELATIVES.size() - 1:
		state = State.VICTORY
		return
	healed = mini(12, p.max_hp - p.hp)
	p.hp += healed
	var pool: Array = Data.REWARD_POOL.duplicate()
	pool.shuffle()
	reward_choices = pool.slice(0, 3).map(func(id): return Data.make_card(id))
	state = State.REWARD


func take_reward(c) -> void:
	if state != State.REWARD:
		return
	if c != null:
		master.append(c)
	rel_index += 1
	start_fight()


func pick_intent() -> void:
	var options := []
	for i in rel().moves.size():
		if i != last_idx:
			options.append(i)
	intent_idx = options.pick_random()


# ================= Effects (shared by cards and relatives) =================

func apply_fx(src: Data.Fighter, dst: Data.Fighter, fx: Dictionary) -> void:
	var dmg: int = fx.get("dmg", 0)
	if dmg > 0:
		if fx.get("double_flustered", false) and dst.flustered > 0:
			dmg *= 2
		for i in fx.get("hits", 1):
			hit(src, dst, dmg)
	if fx.has("fluster"):
		dst.flustered += fx.fluster
		pop(dst, "Flustered!", GOLD)
	if fx.has("block"):
		src.block += fx.block
		pop(src, "+%d Deflect" % fx.block, BLUE)
	if fx.has("smug"):
		src.smug += fx.smug
		pop(src, "+%d Smug" % fx.smug, PINK)
	if fx.has("heal"):
		var h := mini(fx.heal, src.max_hp - src.hp)
		src.hp += h
		pop(src, "+%d" % h, Color(0.4, 1, 0.5))
	if fx.has("spite"):
		spite += fx.spite
	if fx.has("draw"):
		draw_cards(fx.draw)
	if fx.has("junk"):
		for i in fx.junk_count:
			var c := Data.make_card(fx.junk)
			if fx.get("junk_to_draw", false):
				draw_pile.insert(randi_range(0, draw_pile.size()), c)
			else:
				discard.append(c)
		pop(p, "+%d %s" % [fx.junk_count, Data.CARDS[fx.junk].name], Color(0.85, 0.85, 0.85))


func describe(fx: Dictionary) -> String:
	var parts := []
	var dmg: int = fx.get("dmg", 0)
	if dmg > 0:
		var hits: int = fx.get("hits", 1)
		parts.append("Insult for %d%s" % [preview(e, p, dmg), " x%d" % hits if hits > 1 else ""])
	if fx.has("fluster"):
		parts.append("Fluster you")
	if fx.has("block"):
		parts.append("Deflect %d" % fx.block)
	if fx.has("smug"):
		parts.append("Gain %d Smug" % fx.smug)
	if fx.has("heal"):
		parts.append("Recover %d" % fx.heal)
	if fx.has("junk"):
		parts.append("Stuff you with %d %s" % [fx.junk_count, Data.CARDS[fx.junk].name])
	return ", ".join(parts)


func preview(src: Data.Fighter, dst: Data.Fighter, base: int) -> int:
	var d := base + src.smug
	if dst.flustered > 0:
		d = d * 3 / 2
	return d


func hit(src: Data.Fighter, dst: Data.Fighter, base: int) -> void:
	if dst.dead():
		return
	var dmg := preview(src, dst, base)
	var absorbed := mini(dst.block, dmg)
	dst.block -= absorbed
	dmg -= absorbed
	dst.hp = maxi(0, dst.hp - dmg)
	if dmg > 0:
		pop(dst, "-%d" % dmg, RED)
		if dst == p:
			shake = 0.35
		else:
			enemy_flash = 0.25
	else:
		pop(dst, "Deflected!", BLUE)


func pop(f: Data.Fighter, text: String, col: Color) -> void:
	var base := Vector2(130, 430) if f == p else Vector2(640, 120)
	base += Vector2(randf_range(-40, 40), randf_range(-15, 15))
	popups.append({"text": text, "pos": base, "t": 1.2, "col": col})


func say_p(s: String) -> void:
	p_line = s
	p_line_t = 3.0


func say_e(s: String) -> void:
	e_line = s
	e_line_t = 4.0


func add_log(s: String) -> void:
	log_lines.append(s)
	if log_lines.size() > 30:
		log_lines.remove_at(0)


func _process(dt: float) -> void:
	p_line_t -= dt
	e_line_t -= dt
	shake = maxf(0, shake - dt)
	enemy_flash = maxf(0, enemy_flash - dt)
	for i in range(popups.size() - 1, -1, -1):
		popups[i].t -= dt
		popups[i].pos.y -= 40 * dt
		if popups[i].t <= 0:
			popups.remove_at(i)
	queue_redraw()


# ================= Input =================

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		for i in range(clickables.size() - 1, -1, -1):
			if clickables[i][0].has_point(ev.position):
				accept_event()
				clickables[i][1].call()
				return


func _unhandled_key_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey and ev.pressed and not ev.echo):
		return
	var k: Key = ev.keycode
	match state:
		State.COMBAT:
			if k == KEY_SPACE or k == KEY_E:
				end_turn()
			elif k >= KEY_1 and k <= KEY_9:
				play_card(k - KEY_1)
		State.REWARD:
			if k >= KEY_1 and k <= KEY_3:
				take_reward(reward_choices[k - KEY_1])
			elif k == KEY_S:
				take_reward(null)
		_:
			if k == KEY_ENTER or k == KEY_SPACE:
				new_run()


# ================= Drawing =================

func txt(r: Rect2, s: String, size := 16, col := Color.WHITE, f: Font = null, align := HORIZONTAL_ALIGNMENT_CENTER, valign := 0.5) -> void:
	if f == null:
		f = font
	var h := f.get_multiline_string_size(s, align, r.size.x, size).y
	var y := r.position.y + (r.size.y - h) * valign + f.get_ascent(size)
	draw_multiline_string(f, Vector2(r.position.x, y), s, align, r.size.x, size, -1, col)


func button(r: Rect2, label: String, action: Callable, enabled := true) -> void:
	var hover := enabled and r.has_point(get_local_mouse_position())
	draw_rect(r.grow(3), Color.BLACK)
	draw_rect(r, Color(0.85, 0.3, 0.25) if hover else (Color(0.6, 0.2, 0.18) if enabled else Color(0.3, 0.25, 0.25)))
	txt(r, label, 22, Color.WHITE if enabled else Color(1, 1, 1, 0.4), bold)
	if enabled:
		clickables.append([r, action])


func bar(r: Rect2, v: int, max_v: int, col: Color, label: String) -> void:
	draw_rect(r, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2((r.size.x - 4) * clampf(float(v) / max_v, 0, 1), r.size.y - 4)), col)
	txt(r, "%s %d/%d" % [label, v, max_v], 15, Color.WHITE, bold)


func bubble(r: Rect2, s: String, t: float) -> void:
	if s.is_empty() or t <= 0:
		return
	var a := clampf(t * 2, 0, 1)
	draw_rect(r, Color(1, 1, 1, a))
	draw_rect(Rect2(r.position.x, r.end.y - 3, r.size.x, 3), Color(0, 0, 0, 0.3 * a))
	txt(r.grow(-10), s, 17, Color(INK, a), italic)


func _draw() -> void:
	clickables.clear()
	var off := Vector2.ZERO
	if shake > 0:
		off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 8 * shake / 0.35
	draw_set_transform(off)
	draw_rect(Rect2(0, 0, W, H), BG)
	for x in range(0, int(W), 80):
		draw_rect(Rect2(x, 0, 40, 300), WALLPAPER)

	match state:
		State.TITLE: draw_title()
		State.COMBAT: draw_combat()
		State.REWARD: draw_reward()
		State.GAME_OVER: draw_end("YOU STORMED OUT", "...before dessert. Everyone will talk about this until next Christmas.")
		State.VICTORY: draw_end("DINNER SURVIVED", "The family is speechless. Grandma slips you $20. See you at Christmas.")

	for pp in popups:
		txt(Rect2(pp.pos - Vector2(120, 20), Vector2(240, 40)), pp.text, 26, Color(pp.col, clampf(pp.t * 2, 0, 1)), bold)


func draw_title() -> void:
	draw_rect(Rect2(140, 330, 1000, 140), WOOD)
	draw_rect(Rect2(160, 340, 960, 120), CLOTH)
	txt(Rect2(0, 90, W, 90), "FAMILY DINNER", 64, Color.WHITE, bold)
	txt(Rect2(0, 175, W, 40), "a deck-building card game of passive aggression", 18, Color(1, 0.85, 0.6), italic)
	txt(Rect2(180, 345, 920, 110),
		"Survive four courses and four relatives.\n" +
		"Play Insults to break their composure, Deflect to dodge theirs.\n" +
		"You have 3 Spite per turn. Keys 1-9 play cards, Space ends your turn.", 17, INK)
	button(Rect2(W / 2 - 120, 520, 240, 64), "Sit Down", new_run)


func draw_end(title: String, sub: String) -> void:
	txt(Rect2(0, 200, W, 90), title, 64, Color.WHITE, bold)
	txt(Rect2(240, 300, 800, 80), sub, 18, Color(1, 0.85, 0.6))
	button(Rect2(W / 2 - 120, 440, 240, 64), "Another Holiday", new_run)


func draw_reward() -> void:
	var next: Dictionary = Data.RELATIVES[rel_index + 1]
	txt(Rect2(0, 60, W, 60), "BATHROOM BREAK", 56, Color.WHITE, bold)
	txt(Rect2(0, 140, W, 30), "You splash water on your face. Recovered %d composure (%d/%d)." % [healed, p.hp, p.max_hp], 17, Color(0.6, 1, 0.6))
	txt(Rect2(0, 175, W, 30), "Rehearse a comeback for %s (%s):" % [next.name, next.course], 17)
	var m := get_local_mouse_position()
	for i in reward_choices.size():
		var r := Rect2(W / 2 - 240 + i * 170, 240, 140, 200)
		if r.has_point(m):
			r.position.y -= 12
		draw_card(r, reward_choices[i], true, i + 1)
		clickables.append([r, take_reward.bind(reward_choices[i])])
	button(Rect2(W / 2 - 100, 480, 200, 50), "Skip", take_reward.bind(null))
	txt(Rect2(0, 560, W, 30), "Deck: %d cards" % master.size(), 15, Color(1, 1, 1, 0.6))


func draw_combat() -> void:
	draw_top_bar()
	draw_enemy()
	draw_table()
	draw_player()
	draw_hand()
	button(Rect2(1110, 540, 150, 60), "..." if busy else "End Turn", end_turn, not busy)
	txt(Rect2(1110, 610, 150, 90), "Draw pile: %d\nDiscard: %d\nTurn %d" % [draw_pile.size(), discard.size(), turn],
		14, Color(1, 1, 1, 0.75), null, HORIZONTAL_ALIGNMENT_LEFT, 0)


func draw_top_bar() -> void:
	draw_rect(Rect2(0, 0, W, 40), Color(0, 0, 0, 0.45))
	txt(Rect2(16, 0, 500, 40), "Course %d/%d: %s" % [rel_index + 1, Data.RELATIVES.size(), rel().course], 17, Color.WHITE, bold, HORIZONTAL_ALIGNMENT_LEFT)
	for i in Data.RELATIVES.size():
		var f: Dictionary = Data.RELATIVES[i]
		var r := Rect2(620 + i * 160, 6, 150, 28)
		var c: Color = f.color
		if i < rel_index:
			c = Color(0.3, 0.3, 0.3)
		elif i > rel_index:
			c = c.darkened(0.5)
		draw_rect(r, c)
		txt(r, f.name + (" (beaten)" if i < rel_index else ""), 14, Color.WHITE if i == rel_index else Color(1, 1, 1, 0.6))


func draw_enemy() -> void:
	var portrait := Rect2(570, 70, 140, 140)
	draw_rect(portrait.grow(4), Color.BLACK)
	draw_rect(portrait, rel().color.lerp(Color.WHITE, clampf(enemy_flash * 3, 0, 1)))
	txt(portrait, rel().hurt_face if e.hp < e.max_hp / 2 else rel().face, 34, Color.WHITE, bold)

	txt(Rect2(440, 212, 400, 26), "%s  -  %s" % [rel().name, rel().title], 17)
	bar(Rect2(490, 240, 300, 22), e.hp, e.max_hp, Color(0.85, 0.3, 0.3), "Composure")
	draw_statuses(Rect2(440, 264, 400, 26), e)

	if not e.dead():
		var ir := Rect2(780, 90, 300, 90)
		draw_rect(ir, Color(0, 0, 0, 0.5))
		txt(Rect2(ir.position.x + 10, ir.position.y + 4, ir.size.x - 20, 22), "NEXT MOVE", 13, Color(1, 0.8, 0.4), bold, HORIZONTAL_ALIGNMENT_LEFT)
		txt(Rect2(ir.position.x + 10, ir.position.y + 28, ir.size.x - 20, ir.size.y - 32), describe(intent().fx), 16, Color.WHITE, null, HORIZONTAL_ALIGNMENT_LEFT, 0)

	bubble(Rect2(170, 90, 380, 90), e_line, e_line_t)


func draw_statuses(r: Rect2, f: Data.Fighter) -> void:
	var parts := []
	if f.block > 0:
		parts.append(["Deflect %d" % f.block, BLUE])
	if f.flustered > 0:
		parts.append(["Flustered %d" % f.flustered, GOLD])
	if f.smug > 0:
		parts.append(["Smug %d" % f.smug, PINK])
	if parts.is_empty():
		return
	var w := r.size.x / parts.size()
	for i in parts.size():
		txt(Rect2(r.position.x + i * w, r.position.y, w, r.size.y), parts[i][0], 15, parts[i][1], bold)


func draw_table() -> void:
	draw_rect(Rect2(40, 296, 1200, 84), WOOD)
	draw_rect(Rect2(56, 300, 1168, 70), CLOTH)
	for i in 6:  # plates
		draw_rect(Rect2(110 + i * 190, 306, 60, 6), Color(0.75, 0.72, 0.65))
	var shown := log_lines.slice(maxi(0, log_lines.size() - 3))
	txt(Rect2(80, 314, 1120, 56), "\n".join(shown), 13, INK, null, HORIZONTAL_ALIGNMENT_LEFT, 0)


func draw_player() -> void:
	var r := Rect2(20, 400, 220, 300)
	draw_rect(r, Color(0, 0, 0, 0.4))
	txt(Rect2(r.position.x, r.position.y + 6, r.size.x, 30), "YOU", 18, Color.WHITE, bold)
	bar(Rect2(r.position.x + 10, r.position.y + 40, r.size.x - 20, 24), p.hp, p.max_hp, Color(0.3, 0.75, 0.4), "Composure")
	draw_statuses(Rect2(r.position.x, r.position.y + 72, r.size.x, 40), p)

	var orb := Vector2(r.position.x + 110, r.position.y + 180)
	draw_circle(orb, 52, Color(0.65, 0.15, 0.2))
	draw_circle(orb, 45, Color(0.85, 0.25, 0.25))
	txt(Rect2(orb.x - 50, orb.y - 40, 100, 50), "%d/%d" % [spite, MAX_SPITE], 30, Color.WHITE, bold)
	txt(Rect2(orb.x - 50, orb.y + 6, 100, 24), "SPITE", 14, Color.WHITE, bold)

	txt(Rect2(r.position.x + 10, r.position.y + 240, r.size.x - 20, 54),
		"Flustered: take 50% more.\nSmug: +dmg per insult.", 12, Color(1, 1, 1, 0.5))

	bubble(Rect2(300, 385, 680, 50), p_line, p_line_t)


func draw_hand() -> void:
	var n := hand.size()
	if n == 0:
		return
	var cw := 140.0
	var spacing := minf(150, 800.0 / n)
	var x0 := 670 - (spacing * (n - 1) + cw) / 2
	var m := get_local_mouse_position()
	var hover := -1
	for i in range(n - 1, -1, -1):
		var r := Rect2(x0 + i * spacing, 460, cw, 240)  # includes the raised area
		if r.has_point(m):
			hover = i
			break
	for i in n:
		if i != hover:
			draw_card(Rect2(x0 + i * spacing, 500, cw, 200), hand[i], can_play(hand[i]), i + 1)
	if hover >= 0:
		var hr := Rect2(x0 + hover * spacing, 460, cw, 200)
		draw_card(hr, hand[hover], can_play(hand[hover]), hover + 1)
		clickables.append([Rect2(hr.position, Vector2(cw, 240)), play_card.bind(hover)])


func draw_card(r: Rect2, c: Dictionary, playable: bool, hotkey := 0) -> void:
	var kc: Color = KIND_COLORS[c.kind]
	draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.4))
	draw_rect(r, kc)
	var inner := r.grow(-5)
	draw_rect(inner, Color(0.75, 0.75, 0.72) if c.kind == Data.Kind.JUNK else PAPER)
	var ix := inner.position.x
	var iy := inner.position.y
	var iw := inner.size.x
	draw_rect(Rect2(ix, iy, iw, 44), kc)
	txt(Rect2(ix + 22, iy, iw - 24, 44), c.name, 13, Color.WHITE, bold)

	if not c.get("unplayable", false):
		var cost := Rect2(r.position - Vector2(6, 6), Vector2(30, 30))
		draw_rect(cost, Color.BLACK)
		draw_rect(cost.grow(-2), Color(0.85, 0.25, 0.25))
		txt(cost, str(c.cost), 17, Color.WHITE, bold)

	txt(Rect2(ix, iy + 46, iw, 16), Data.KIND_NAMES[c.kind], 11, kc, bold)
	txt(Rect2(ix + 6, iy + 62, iw - 12, 64), c.text, 14, INK)
	if not c.quote.is_empty():
		txt(Rect2(ix + 6, iy + 126, iw - 12, 60), "\"%s\"" % c.quote, 11, Color(0.35, 0.3, 0.28), italic)
	if hotkey > 0 and hotkey <= 9:
		txt(Rect2(r.end.x - 22, r.end.y - 22, 20, 20), str(hotkey), 13, Color(0, 0, 0, 0.4))

	if not playable:
		draw_rect(r, Color(0, 0, 0, 0.35))

extends RefCounted
## All cards and relatives. Effects are plain data, applied by game.gd's apply_fx():
##   dmg, hits, double_flustered, fluster (target), block, smug, heal (self),
##   spite, draw, junk / junk_count / junk_to_draw.

enum Kind { INSULT, DEFLECT, SCHEME, JUNK }
const KIND_NAMES := ["INSULT", "DEFLECT", "SCHEME", "JUNK"]


class Fighter:
	var name: String
	var max_hp: int
	var hp: int
	var block := 0
	var flustered := 0
	var smug := 0

	func _init(n: String, h: int) -> void:
		name = n
		max_hp = h
		hp = h

	func dead() -> bool:
		return hp <= 0


const CARDS := {
	# Starters
	"backhanded": {"name": "Backhanded Compliment", "cost": 1, "kind": Kind.INSULT, "text": "Deal 6.",
		"quote": "Wow, you look SO much better than last year!", "fx": {"dmg": 6}},
	"change_subject": {"name": "Change the Subject", "cost": 1, "kind": Kind.DEFLECT, "text": "Gain 5 Deflect.",
		"quote": "Sooo... how about that weather?", "fx": {"block": 5}},
	"the_incident": {"name": "Bring Up The Incident", "cost": 2, "kind": Kind.INSULT, "text": "Deal 13.",
		"quote": "Should we talk about Thanksgiving 2014?", "fx": {"dmg": 13}},
	"sigh": {"name": "Passive-Aggressive Sigh", "cost": 0, "kind": Kind.SCHEME, "text": "Apply 1 Flustered.",
		"quote": "*sighs loudly*", "fx": {"fluster": 1}},

	# Rewards
	"well_actually": {"name": "Well, Actually", "cost": 1, "kind": Kind.INSULT, "text": "Deal 3, three times.",
		"quote": "Well ACTUALLY, studies show...", "fx": {"dmg": 3, "hits": 3}},
	"the_will": {"name": "Mention The Will", "cost": 2, "kind": Kind.INSULT, "text": "Deal 8.\nApply 2 Flustered.",
		"quote": "So... who's getting the lake house?", "fx": {"dmg": 8, "fluster": 2}},
	"grammar": {"name": "Correct Their Grammar", "cost": 1, "kind": Kind.INSULT, "text": "Deal 5.\nDouble if Flustered.",
		"quote": "It's 'whom', actually.", "fx": {"dmg": 5, "double_flustered": true}},
	"smug_sip": {"name": "Smug Sip of Wine", "cost": 1, "kind": Kind.SCHEME, "text": "Gain 2 Smug.\n(+2 dmg on insults)",
		"quote": "*sips wine knowingly*", "fx": {"smug": 2}},
	"vacation_photos": {"name": "Vacation Photos", "cost": 2, "kind": Kind.DEFLECT, "text": "Gain 13 Deflect.",
		"quote": "Here's me in Portugal. And again in Portugal.", "fx": {"block": 13}},
	"fake_laugh": {"name": "Fake Laugh", "cost": 0, "kind": Kind.DEFLECT, "text": "Gain 3 Deflect.",
		"quote": "Haha! Hahaha. Ha.", "fx": {"block": 3}},
	"compliment_cook": {"name": "Compliment The Cook", "cost": 1, "kind": Kind.SCHEME, "text": "Recover 8 composure.\nExhaust.",
		"quote": "Grandma, this is AMAZING.", "fx": {"heal": 8}, "exhaust": true},
	"dishes": {"name": "Volunteer For Dishes", "cost": 1, "kind": Kind.DEFLECT, "text": "Gain 6 Deflect.\nDraw 1.",
		"quote": "I'll help clean up!", "fx": {"block": 6, "draw": 1}},
	"therapy_speak": {"name": "Therapy Speak", "cost": 2, "kind": Kind.INSULT, "text": "Deal 10.\nGain 5 Deflect.",
		"quote": "I'm going to set a boundary right now.", "fx": {"dmg": 10, "block": 5}},
	"reply_all": {"name": "Reply-All Energy", "cost": 3, "kind": Kind.INSULT, "text": "Deal 24.",
		"quote": "You know what? Let's ALL talk about it.", "fx": {"dmg": 24}},
	"refill_wine": {"name": "Refill The Wine", "cost": 0, "kind": Kind.SCHEME, "text": "Gain 1 Spite.\nDraw 1.\nExhaust.",
		"quote": "Top me up, please.", "fx": {"spite": 1, "draw": 1}, "exhaust": true},

	# Junk the relatives shove into your deck (this fight only)
	"second_helping": {"name": "Second Helping", "cost": 0, "kind": Kind.JUNK, "text": "Unplayable.\nYou're SO full.",
		"quote": "", "fx": {}, "unplayable": true},
	"guilt": {"name": "Guilt", "cost": 0, "kind": Kind.JUNK, "text": "Unplayable.\nShe's not angry. Just disappointed.",
		"quote": "", "fx": {}, "unplayable": true},
}

const REWARD_POOL := ["well_actually", "the_will", "grammar", "smug_sip", "vacation_photos", "fake_laugh",
	"compliment_cook", "dishes", "therapy_speak", "reply_all", "refill_wine", "sigh", "the_incident"]

const RELATIVES := [
	{
		"name": "Aunt Linda", "title": "Wine Aunt", "course": "Appetizers", "hp": 36,
		"face": "(o_O)", "hurt_face": "(;_;)", "color": Color(0.7, 0.35, 0.55),
		"intro": "Oh, you came! We weren't sure you would.",
		"defeat": "I... need more chardonnay.",
		"moves": [
			{"line": "So... still single, huh?", "fx": {"dmg": 6}},
			{"line": "My Brad just bought a SECOND house.", "fx": {"dmg": 9}},
			{"line": "You look tired. Are you sleeping okay?", "fx": {"fluster": 2}},
			{"line": "*refills chardonnay*", "fx": {"block": 6}},
		],
	},
	{
		"name": "Cousin Brad", "title": "Crypto Bro", "course": "Main Course", "hp": 50,
		"face": "(-_-)b", "hurt_face": "(T_T)", "color": Color(0.25, 0.55, 0.6),
		"intro": "Yooo. Still renting? Couldn't be me.",
		"defeat": "Bro... that's lowkey crazy. I'm gonna go vape.",
		"moves": [
			{"line": "Bro, you're still renting? NGMI.", "fx": {"dmg": 5, "hits": 2}},
			{"line": "*flexes in a tank top at dinner*", "fx": {"smug": 2, "block": 5}},
			{"line": "My portfolio's up 400%. What's YOUR salary?", "fx": {"dmg": 11}},
			{"line": "*explains his Tesla for ten minutes*", "fx": {"block": 9}},
		],
	},
	{
		"name": "Uncle Gary", "title": "Has Opinions", "course": "Seconds", "hp": 64,
		"face": "(>_<)", "hurt_face": "(@_@)", "color": Color(0.6, 0.4, 0.2),
		"intro": "Now I'm not trying to start anything, BUT...",
		"defeat": "...Who wants to watch the game?",
		"moves": [
			{"line": "You know what's wrong with this country?", "fx": {"dmg": 13}},
			{"line": "Back in MY day we didn't HAVE 'anxiety'.", "fx": {"dmg": 6, "fluster": 2}},
			{"line": "*tells the same joke again, laughs harder*", "fx": {"smug": 3}},
			{"line": "*turns up the football*", "fx": {"block": 12}},
		],
	},
	{
		"name": "Grandma", "title": "The Matriarch", "course": "Dessert", "hp": 88,
		"face": "(^_^)", "hurt_face": "(._.)", "color": Color(0.55, 0.5, 0.75),
		"intro": "Sit, sit. Grandma just wants to talk.",
		"defeat": "...You were always my favourite. Don't tell your cousin.",
		"moves": [
			{"line": "When are you giving me GRANDCHILDREN?", "fx": {"dmg": 16}},
			{"line": "You're so THIN! Eat, eat!", "fx": {"heal": 8, "junk": "second_helping", "junk_count": 2}},
			{"line": "I'm not angry. Just disappointed.", "fx": {"dmg": 9, "junk": "guilt", "junk_count": 1, "junk_to_draw": true}},
			{"line": "*knits silently, judging*", "fx": {"block": 14, "smug": 2}},
		],
	},
]


static func make_card(id: String) -> Dictionary:
	var c: Dictionary = CARDS[id].duplicate()
	c["id"] = id
	return c


static func starter_deck() -> Array:
	var d := []
	for i in 4:
		d.append(make_card("backhanded"))
	for i in 4:
		d.append(make_card("change_subject"))
	d.append(make_card("the_incident"))
	d.append(make_card("sigh"))
	return d

extends RefCounted
class_name PokerRules

# Card IDs: suit * 13 + (rank - 2). Suits are S, H, D, C.
const HAND_NAMES := ["HIGH CARD", "ONE PAIR", "TWO PAIR", "THREE OF A KIND", "STRAIGHT", "FLUSH", "FULL HOUSE", "FOUR OF A KIND", "STRAIGHT FLUSH"]

static func rank_of(card: int) -> int:
	return card % 13 + 2

static func suit_of(card: int) -> int:
	return int(card / 13)

static func rank_word(rank: int) -> String:
	var names := ["", "", "TWO", "THREE", "FOUR", "FIVE", "SIX", "SEVEN", "EIGHT", "NINE", "TEN", "JACK", "QUEEN", "KING", "ACE"]
	return names[clampi(rank, 2, 14)]

static func short_name(card: int) -> String:
	var ranks := ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]
	var suits := ["S", "H", "D", "C"]
	return ranks[rank_of(card) - 2] + suits[suit_of(card)]

static func _score_five(cards: Array) -> Dictionary:
	var counts := {}
	var suits := {}
	for c in cards:
		var rank: int = rank_of(int(c))
		var suit: int = suit_of(int(c))
		counts[rank] = int(counts.get(rank, 0)) + 1
		suits[suit] = int(suits.get(suit, 0)) + 1
	var sorted_ranks: Array = counts.keys()
	sorted_ranks.sort()
	sorted_ranks.reverse()
	var straight_high := 0
	if sorted_ranks.size() == 5:
		if int(sorted_ranks[0]) - int(sorted_ranks[4]) == 4:
			straight_high = int(sorted_ranks[0])
		elif sorted_ranks == [14, 5, 4, 3, 2]:
			straight_high = 5
	var flush := suits.size() == 1
	var groups: Array = []
	for rank in counts:
		groups.append({"rank": int(rank), "n": int(counts[rank])})
	groups.sort_custom(func(a, b):
		if a["n"] == b["n"]:
			return a["rank"] > b["rank"]
		return a["n"] > b["n"]
	)
	var category := 0
	var kickers: Array = []
	if flush and straight_high > 0:
		category = 8
		kickers = [straight_high]
	elif groups[0]["n"] == 4:
		category = 7
		kickers = [groups[0]["rank"], groups[1]["rank"]]
	elif groups[0]["n"] == 3 and groups[1]["n"] == 2:
		category = 6
		kickers = [groups[0]["rank"], groups[1]["rank"]]
	elif flush:
		category = 5
		kickers = sorted_ranks.duplicate()
	elif straight_high > 0:
		category = 4
		kickers = [straight_high]
	elif groups[0]["n"] == 3:
		category = 3
		kickers = [groups[0]["rank"]]
		for g in groups.slice(1):
			kickers.append(g["rank"])
	elif groups[0]["n"] == 2 and groups[1]["n"] == 2:
		category = 2
		kickers = [maxi(groups[0]["rank"], groups[1]["rank"]), mini(groups[0]["rank"], groups[1]["rank"]), groups[2]["rank"]]
	elif groups[0]["n"] == 2:
		category = 1
		kickers = [groups[0]["rank"]]
		for g in groups.slice(1):
			kickers.append(g["rank"])
	else:
		kickers = sorted_ranks.duplicate()
	var value := category
	for i in range(5):
		value = value * 15 + (int(kickers[i]) if i < kickers.size() else 0)
	var name: String = HAND_NAMES[category]
	if category == 8 and straight_high == 14:
		name = "ROYAL FLUSH"
	return {"value": value, "category": category, "name": name, "kickers": kickers}

static func best(cards: Array) -> Dictionary:
	if cards.size() < 5:
		return {"value": -1, "category": -1, "name": "WAITING FOR BOARD", "kickers": [], "cards": []}
	var best_score := {"value": -1, "category": -1, "name": "", "kickers": [], "cards": []}
	var most_board_cards := -1
	for a in range(cards.size() - 4):
		for b in range(a + 1, cards.size() - 3):
			for c in range(b + 1, cards.size() - 2):
				for d in range(c + 1, cards.size() - 1):
					for e in range(d + 1, cards.size()):
						var indices := [a, b, c, d, e]
						var five: Array = [cards[a], cards[b], cards[c], cards[d], cards[e]]
						var score: Dictionary = _score_five(five)
						# If two combinations are equivalent, prefer shared cards.
						# This makes board-only winning hands easier to recognize.
						var board_count := 0
						for index in indices:
							if index >= 2:
								board_count += 1
						if int(score["value"]) > int(best_score["value"]) or (int(score["value"]) == int(best_score["value"]) and board_count > most_board_cards):
							best_score = score
							best_score["cards"] = five
							most_board_cards = board_count
	return best_score

static func preflop_label(two_cards: Array) -> String:
	if two_cards.size() < 2:
		return ""
	var a: int = rank_of(two_cards[0])
	var b: int = rank_of(two_cards[1])
	if a == b:
		return "POCKET " + rank_word(a) + "S"
	if suit_of(two_cards[0]) == suit_of(two_cards[1]):
		return "SUITED " + rank_word(maxi(a, b)) + " HIGH"
	return rank_word(maxi(a, b)) + " HIGH"

static func estimate_preflop(two_cards: Array) -> float:
	var a: int = rank_of(two_cards[0])
	var b: int = rank_of(two_cards[1])
	var hi: int = maxi(a, b)
	var lo: int = mini(a, b)
	var strength := 0.24 + float(hi) / 35.0
	if a == b:
		strength = 0.57 + float(a) / 35.0
	else:
		if suit_of(two_cards[0]) == suit_of(two_cards[1]):
			strength += 0.075
		if hi - lo <= 2:
			strength += 0.06
		if hi == 14:
			strength += 0.05
	return clampf(strength, 0.20, 0.96)

# CPU samples unknown cards and never inspects the player's actual hole cards.
static func approximate_equity(cpu_hole: Array, board: Array, sample_count: int = 58) -> float:
	if board.is_empty():
		return estimate_preflop(cpu_hole)
	var known: Array = cpu_hole.duplicate()
	known.append_array(board)
	var available: Array = []
	for i in range(52):
		if not known.has(i):
			available.append(i)
	var score := 0.0
	for trial in range(sample_count):
		available.shuffle()
		var enemy: Array = [available[0], available[1]]
		var full_board: Array = board.duplicate()
		for index in range(5 - board.size()):
			full_board.append(available[2 + index])
		var cpu_hand: Array = cpu_hole.duplicate()
		cpu_hand.append_array(full_board)
		var other_hand: Array = enemy.duplicate()
		other_hand.append_array(full_board)
		var a: int = best(cpu_hand)["value"]
		var b: int = best(other_hand)["value"]
		if a > b:
			score += 1.0
		elif a == b:
			score += 0.5
	return score / float(sample_count)

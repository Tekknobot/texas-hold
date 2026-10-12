extends Node2D

const Rules = preload("res://scripts/poker_rules.gd")
const CardView = preload("res://scripts/card_view.gd")
const FXView = preload("res://scripts/arcade_fx.gd")
const ScreenOverlay = preload("res://scripts/screen_overlay.gd")
const FONT = preload("res://Fonts/ClearSans-Regular.ttf")
const FONT_HEAD = preload("res://Fonts/ClearSans-Bold.ttf")
const FELT = preload("res://shaders/felt.gdshader")

const W := 1440.0
const H := 900.0
# Same restrained palette and visual hierarchy as the CARROM collection.
const BG := Color("102320")
const PANEL := Color("19322e")
const PANEL_ALT := Color("213c36")
const MINT := Color("7bdac2")
const ROSE := Color("cb7466")
const GOLD := Color("e8bf7e")
const PALE := Color("f7f0d9")
const MUTED := Color("a7bbb1")
const INK := Color("0b211e")
const BROWN := Color("704328")
const COMMUNITY_X := [243.0, 352.0, 461.0, 570.0, 679.0]
const CPU_X := [389.0, 497.0]
const PLAYER_X := [389.0, 497.0]

var fx: Node2D
var background: ColorRect
var screen_overlay: Node2D
var face_textures: Array = []
var backs: Array = []
var back_index := 0
var audio: Dictionary = {}
var voice_pool: Array = []
var next_voice := 0
var rng := RandomNumberGenerator.new()

var screen := "attract" # attract, playing, result
var show_help := false
var deck: Array = []
var hand_number := 0
var dealer_is_player := false
var small_blind := 25
var big_blind := 50
var player_stack := 1600
var cpu_stack := 1600
var pot := 0
var paid_player := 0
var paid_cpu := 0
var total_player := 0
var total_cpu := 0
var to_call := 0
var current_bet := 0
var min_raise := 50
var raised_to := 100
var player_acted := false
var cpu_acted := false
var actor := 0 # 0 player, 1 cpu
var street := 0 # 0 preflop, 1 flop, 2 turn, 3 river
var busy := false
var hand_over := false
var hole_player: Array = []
var hole_cpu: Array = []
var board: Array = []
var card_nodes_player: Array = []
var card_nodes_cpu: Array = []
var card_nodes_board: Array = []
var draw_index := 0
var callout := ""
var cpu_action := "WAITING"
var result_title := ""
var result_subtitle := ""
var result_detail := ""
var message_timer := 0.0
var table_clock := 0.0
var selected_amount_hint := ""
var hotspots: Array = []
var mouse_at := Vector2(-9999, -9999)
var last_hover := ""

func _ready() -> void:
	rng.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_art()
	_load_audio()
	background = ColorRect.new()
	background.size = Vector2(W, H)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = FELT
	background.material = mat
	background.z_index = -10
	add_child(background)
	fx = FXView.new()
	fx.z_index = 25
	add_child(fx)
	screen_overlay = ScreenOverlay.new()
	screen_overlay.game = self
	screen_overlay.z_index = 40
	add_child(screen_overlay)
	queue_redraw()

func _load_art() -> void:
	var suits := ["Spades", "Hearts", "Diamonds", "Clubs"]
	var ranks := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "ACE"]
	for suit in suits:
		for rank in ranks:
			face_textures.append(load("res://Sprites/KIN's_Playing_Cards/%s_%s.png" % [suit, rank]))
	for i in range(1, 6):
		backs.append(load("res://Sprites/KIN's_Playing_Cards/Back_%d.png" % i))

func _load_audio() -> void:
	for name in ["deal", "flip", "chip", "check", "click", "win", "lose", "raise"]:
		audio[name] = load("res://audio/%s.wav" % name)
	for i in range(9):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12.0
		voice_pool.append(voice)
		add_child(voice)

func _sound(name: String, volume_db: float = -10.0) -> void:
	if not audio.has(name):
		return
	var player: AudioStreamPlayer = voice_pool[next_voice]
	next_voice = (next_voice + 1) % voice_pool.size()
	player.stop()
	player.stream = audio[name]
	player.volume_db = volume_db
	player.pitch_scale = rng.randf_range(0.94, 1.06)
	player.play()

func _process(delta: float) -> void:
	table_clock += delta
	mouse_at = get_global_mouse_position()
	if message_timer > 0.0:
		message_timer -= delta
	for card in card_nodes_player:
		if is_instance_valid(card):
			var hovered: bool = card.face_up and mouse_at.distance_to(card.position) < 70.0 and not show_help
			card.hover_target = 1.0 if hovered else 0.0
			card.tilt = clampf((mouse_at.x - card.position.x) * 0.0006, -0.07, 0.07) if hovered else 0.0
	for card in card_nodes_board:
		if is_instance_valid(card):
			var hovered: bool = mouse_at.distance_to(card.position) < 55.0 and not show_help
			card.hover_target = 0.65 if hovered else 0.0
			card.tilt = clampf((mouse_at.x - card.position.x) * 0.0004, -0.05, 0.05) if hovered else 0.0
	var hovered_id := ""
	for area in hotspots:
		if area["enabled"] and (not show_help or area["id"] == "close_help") and area["rect"].has_point(mouse_at):
			hovered_id = area["id"]
			break
	if hovered_id != last_hover:
		last_hover = hovered_id
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hovered_id != "" else Input.CURSOR_ARROW)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for area in hotspots:
			if area["enabled"] and (not show_help or area["id"] == "close_help") and area["rect"].has_point(get_global_mouse_position()):
				_click(area["id"])
				get_viewport().set_input_as_handled()
				return
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.keycode
		if show_help:
			if key == KEY_ESCAPE or key == KEY_H:
				show_help = false
				_sound("click")
			return
		if key == KEY_H:
			show_help = true
			_sound("click")
		elif screen == "attract" and (key == KEY_SPACE or key == KEY_ENTER):
			_new_match()
		elif screen == "result" and (key == KEY_SPACE or key == KEY_ENTER):
			_after_hand()
		elif _can_act():
			match key:
				KEY_F:
					_player_move("fold")
				KEY_C, KEY_SPACE, KEY_ENTER:
					_player_move("call")
				KEY_R:
					_player_move("raise")
				KEY_UP, KEY_EQUAL, KEY_KP_ADD:
					_shift_raise(big_blind)
				KEY_DOWN, KEY_MINUS, KEY_KP_SUBTRACT:
					_shift_raise(-big_blind)

func _click(id: String) -> void:
	if show_help and id != "close_help":
		return
	_sound("click", -17.0)
	match id:
		"play", "new_match":
			_new_match()
		"next":
			_after_hand()
		"fold", "call", "raise":
			_player_move(id)
		"min":
			_set_raise(_minimum_raise_total())
		"half":
			_set_raise(_pot_raise_total(0.5))
		"pot":
			_set_raise(_pot_raise_total(1.0))
		"max":
			_set_raise(_max_raise_total())
		"plus":
			_shift_raise(big_blind)
		"minus":
			_shift_raise(-big_blind)
		"back":
			back_index = (back_index + 1) % 5
			for card in card_nodes_cpu:
				if is_instance_valid(card):
					card.back_texture = backs[back_index]
		"help":
			show_help = true
		"close_help":
			show_help = false

func _new_match() -> void:
	if busy:
		return
	show_help = false
	player_stack = 1600
	cpu_stack = 1600
	hand_number = 0
	dealer_is_player = false
	_start_hand()

func _after_hand() -> void:
	if screen != "result" or busy:
		return
	if player_stack == 0 or cpu_stack == 0:
		_new_match()
	else:
		_start_hand()

func _clear_cards() -> void:
	for card in card_nodes_player + card_nodes_cpu + card_nodes_board:
		if is_instance_valid(card):
			card.queue_free()
	card_nodes_player.clear()
	card_nodes_cpu.clear()
	card_nodes_board.clear()

func _start_hand() -> void:
	if busy:
		return
	busy = true
	_clear_cards()
	screen = "playing"
	hand_over = false
	hand_number += 1
	dealer_is_player = not dealer_is_player
	var blind_level: int = 1 + int((hand_number - 1) / 6)
	small_blind = 25 * blind_level
	big_blind = 50 * blind_level
	min_raise = big_blind
	paid_player = 0
	paid_cpu = 0
	total_player = 0
	total_cpu = 0
	pot = 0
	current_bet = 0
	street = 0
	player_acted = false
	cpu_acted = false
	hole_player.clear()
	hole_cpu.clear()
	board.clear()
	result_title = ""
	result_detail = ""
	callout = "SHUFFLING THE DECK"
	cpu_action = "POSTING BLINDS"
	deck.clear()
	for i in range(52):
		deck.append(i)
	deck.shuffle()
	draw_index = 0
	# Heads up: dealer posts small blind and acts first preflop.
	if dealer_is_player:
		_commit(0, small_blind, false)
		_commit(1, big_blind, false)
		actor = 0
	else:
		_commit(1, small_blind, false)
		_commit(0, big_blind, false)
		actor = 1
	current_bet = maxi(paid_player, paid_cpu)
	for i in range(2):
		hole_player.append(_draw_card())
		hole_cpu.append(_draw_card())
	await _animate_hole_cards()
	if not is_inside_tree():
		return
	busy = false
	callout = "CARDS ARE LIVE"
	message_timer = 1.7
	_drive_turn()

func _draw_card() -> int:
	var id: int = deck[draw_index]
	draw_index += 1
	return id

func _create_card(id: int, final_pos: Vector2, face_up: bool, own: bool, size_factor: float = 2.64) -> Node2D:
	var card = CardView.new()
	card.setup(face_textures[id], backs[back_index], size_factor, own)
	card.position = Vector2(771.0, 177.0)
	card.rotation = -0.40
	card.scale = Vector2(0.62, 0.62)
	card.z_index = 12
	add_child(card)
	var anim := create_tween().set_parallel(true)
	anim.tween_property(card, "position", final_pos, 0.48).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	anim.tween_property(card, "rotation", 0.0, 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	anim.tween_property(card, "scale", Vector2.ONE, 0.40).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_sound("deal", -14.0)
	fx.spray(final_pos, 5, ROSE if own else MINT, 35.0)
	if face_up:
		var reveal_wait := get_tree().create_timer(0.38)
		reveal_wait.timeout.connect(func():
			if is_instance_valid(card):
				card.reveal()
				_sound("flip", -15.0)
		)
	return card

func _animate_hole_cards() -> void:
	for i in range(2):
		card_nodes_player.append(_create_card(hole_player[i], Vector2(PLAYER_X[i], 632.0), true, true, 2.76))
		await get_tree().create_timer(0.15).timeout
		card_nodes_cpu.append(_create_card(hole_cpu[i], Vector2(CPU_X[i], 267.0), false, false, 2.52))
		await get_tree().create_timer(0.22).timeout
	await get_tree().create_timer(0.55).timeout

func _deal_board(count: int) -> void:
	# A burn card before each reveal street.
	_draw_card()
	for n in range(count):
		var card_id := _draw_card()
		board.append(card_id)
		var place: int = board.size() - 1
		card_nodes_board.append(_create_card(card_id, Vector2(COMMUNITY_X[place], 462.0), true, false, 2.80))
		await get_tree().create_timer(0.22).timeout
	await get_tree().create_timer(0.49).timeout
	fx.spray(Vector2(460, 462), 12, MINT, 88.0)

func _can_act() -> bool:
	return screen == "playing" and not busy and not hand_over and actor == 0 and player_stack > 0

func _max_raise_total() -> int:
	return mini(paid_player + player_stack, paid_cpu + cpu_stack)

func _minimum_raise_total() -> int:
	var max_to: int = _max_raise_total()
	var minimum: int = current_bet + (min_raise if current_bet > 0 else big_blind)
	return mini(minimum, max_to)

func _pot_raise_total(factor: float) -> int:
	var need: int = maxi(0, current_bet - paid_player)
	var pot_size: int = pot + need
	return clampi(current_bet + maxi(big_blind, int(ceil(pot_size * factor / float(big_blind))) * big_blind), _minimum_raise_total(), _max_raise_total())

func _can_raise() -> bool:
	return _can_act() and paid_player + player_stack > current_bet and paid_cpu + cpu_stack > current_bet

func _sync_raise() -> void:
	if not _can_raise():
		raised_to = _max_raise_total()
		return
	raised_to = clampi(raised_to, _minimum_raise_total(), _max_raise_total())

func _set_raise(target: int) -> void:
	if not _can_raise():
		return
	raised_to = clampi(target, _minimum_raise_total(), _max_raise_total())
	_sound("check", -18.0)

func _shift_raise(amount: int) -> void:
	_set_raise(raised_to + amount)

func _commit(seat: int, amount: int, effects: bool = true) -> int:
	var actual := mini(maxi(amount, 0), player_stack if seat == 0 else cpu_stack)
	if seat == 0:
		player_stack -= actual
		paid_player += actual
		total_player += actual
	else:
		cpu_stack -= actual
		paid_cpu += actual
		total_cpu += actual
	pot += actual
	if effects and actual > 0:
		fx.chip_burst(Vector2(444, 629) if seat == 0 else Vector2(444, 270), Vector2(404, 348), GOLD if seat == 0 else ROSE)
		_sound("chip", -10.0)
	return actual

func _player_move(kind: String) -> void:
	if not _can_act():
		return
	if kind == "raise" and not _can_raise():
		return
	_do_move(0, kind, raised_to)
	_continue_after_move()

func _do_move(seat: int, kind: String, target: int = 0) -> void:
	var paid: int = paid_player if seat == 0 else paid_cpu
	var stack: int = player_stack if seat == 0 else cpu_stack
	var facing: int = maxi(0, current_bet - paid)
	if kind == "fold":
		cpu_action = "HOUSE FOLDS" if seat == 1 else "YOU FOLD"
		if seat == 0:
			player_acted = true
		else:
			cpu_acted = true
		_fold_result(seat)
		return
	if kind == "call":
		if facing > 0:
			_commit(seat, mini(stack, facing))
			cpu_action = "HOUSE CALLS" if seat == 1 else "YOU CALL"
			callout = cpu_action
		else:
			cpu_action = "HOUSE CHECKS" if seat == 1 else "YOU CHECK"
			callout = cpu_action
			_sound("check", -14.0)
	else:
		var max_seat: int = paid + stack
		var other_cap: int = (paid_cpu + cpu_stack) if seat == 0 else (paid_player + player_stack)
		var max_total: int = mini(max_seat, other_cap)
		var new_to: int = clampi(target, paid + 1, max_total)
		var previous: int = current_bet
		_commit(seat, new_to - paid)
		current_bet = new_to
		min_raise = maxi(big_blind, new_to - previous)
		cpu_action = "HOUSE RAISES" if seat == 1 else "YOU RAISE"
		callout = cpu_action + " TO $" + str(new_to)
		_sound("raise", -9.0)
		fx.spray(Vector2(720.0, 304.0), 18, GOLD, 94.0)
		if seat == 0:
			cpu_acted = false
		else:
			player_acted = false
	if seat == 0:
		player_acted = true
	else:
		cpu_acted = true
	message_timer = 1.5

func _fold_result(seat: int) -> void:
	var other: int = 1 - seat
	var winner_text := "YOU WIN" if other == 0 else "HOUSE WINS"
	var won: int = pot
	if other == 0:
		player_stack += won
	else:
		cpu_stack += won
	result_title = winner_text
	result_subtitle = "OPPONENT FOLDED" if other == 0 else "YOU FOLDED"
	result_detail = "$%d POT AWARDED" % won
	_end_hand(other, false)

func _refund_uncalled_bet() -> void:
	# There are only two seats. Any chips beyond an all-in opponent's
	# contribution are unmatched, must be refunded, and never enter the pot.
	if player_stack == 0 and paid_player < paid_cpu:
		var excess: int = paid_cpu - paid_player
		paid_cpu -= excess
		total_cpu -= excess
		cpu_stack += excess
		pot -= excess
	elif cpu_stack == 0 and paid_cpu < paid_player:
		var excess: int = paid_player - paid_cpu
		paid_player -= excess
		total_player -= excess
		player_stack += excess
		pot -= excess

func _continue_after_move() -> void:
	if hand_over:
		return
	_refund_uncalled_bet()
	if (player_stack == 0 or cpu_stack == 0) and paid_player == paid_cpu:
		if street == 3:
			_showdown()
		else:
			_next_street()
		return
	var equals: bool = paid_player == paid_cpu
	if equals and player_acted and cpu_acted:
		if street == 3:
			_showdown()
		else:
			_next_street()
		return
	actor = 1 - actor
	_drive_turn()

func _drive_turn() -> void:
	if hand_over or busy or screen != "playing":
		return
	_refund_uncalled_bet()
	if (player_stack == 0 or cpu_stack == 0) and paid_player == paid_cpu:
		if street == 3:
			_showdown()
		else:
			_next_street()
		return
	if (actor == 0 and player_stack == 0) or (actor == 1 and cpu_stack == 0):
		actor = 1 - actor
	if actor == 1:
		_cpu_think()
	else:
		callout = "YOUR MOVE"
		var minimum := _minimum_raise_total()
		raised_to = minimum
		_sync_raise()

func _cpu_think() -> void:
	busy = true
	cpu_action = "THINKING..."
	await get_tree().create_timer(rng.randf_range(0.70, 1.10)).timeout
	if screen != "playing" or hand_over:
		busy = false
		return
	var facing: int = maxi(0, current_bet - paid_cpu)
	var equity: float = Rules.approximate_equity(hole_cpu, board, 52 if street > 0 else 1)
	var pot_odds: float = float(facing) / float(maxi(1, pot + facing))
	var roll: float = rng.randf()
	var action := "call"
	var target := 0
	var cap: int = mini(paid_cpu + cpu_stack, paid_player + player_stack)
	var min_total: int = mini(cap, current_bet + (min_raise if current_bet > 0 else big_blind))
	var can_bet: bool = paid_cpu + cpu_stack > current_bet and paid_player + player_stack > current_bet
	var loose_equity: float = equity + rng.randf_range(-0.075, 0.075)
	if facing > 0 and cpu_stack <= facing:
		if loose_equity < pot_odds * 0.87 and rng.randf() > 0.17:
			action = "fold"
	elif facing > 0 and loose_equity + 0.035 < pot_odds and roll < 0.84:
		action = "fold"
	elif can_bet and (loose_equity > 0.79 and roll < 0.47 or loose_equity > 0.66 and roll < 0.21 or facing == 0 and roll < 0.075):
		action = "raise"
		var min_chips: int = (min_raise if current_bet > 0 else big_blind)
		var bump: int = maxi(min_chips, int(float(pot) * rng.randf_range(0.35, 0.83) / float(big_blind)) * big_blind)
		target = mini(cap, maxi(min_total, current_bet + bump))
		if target <= current_bet:
			action = "call"
	elif facing > 0 and loose_equity < 0.27 and rng.randf() < 0.66:
		action = "fold"
	_do_move(1, action, target)
	busy = false
	_continue_after_move()

func _next_street() -> void:
	busy = true
	street += 1
	paid_player = 0
	paid_cpu = 0
	current_bet = 0
	min_raise = big_blind
	player_acted = false
	cpu_acted = false
	callout = ["", "THE FLOP", "THE TURN", "THE RIVER"][street]
	cpu_action = "WAITING"
	await _deal_board(3 if street == 1 else 1)
	if screen != "playing" or hand_over:
		busy = false
		return
	busy = false
	if player_stack == 0 or cpu_stack == 0:
		if street == 3:
			_showdown()
		else:
			_next_street()
		return
	# Heads up: the non-dealer is first to act after the flop.
	actor = 1 if dealer_is_player else 0
	_drive_turn()

func _showdown() -> void:
	if hand_over:
		return
	busy = true
	callout = "SHOWDOWN"
	cpu_action = "REVEALING CARDS"
	for card in card_nodes_cpu:
		if is_instance_valid(card):
			card.reveal(0.58)
			await get_tree().create_timer(0.16).timeout
	await get_tree().create_timer(0.70).timeout
	var hand_a: Array = hole_player.duplicate()
	hand_a.append_array(board)
	var hand_b: Array = hole_cpu.duplicate()
	hand_b.append_array(board)
	var player_score: Dictionary = Rules.best(hand_a)
	var cpu_score: Dictionary = Rules.best(hand_b)
	var winner := -1
	if player_score["value"] > cpu_score["value"]:
		winner = 0
	elif cpu_score["value"] > player_score["value"]:
		winner = 1
	if winner == 0:
		result_title = "YOU WIN"
		result_subtitle = player_score["name"]
		result_detail = "POT $" + str(pot) + "  /  HOUSE " + cpu_score["name"]
		player_stack += pot
	elif winner == 1:
		result_title = "HOUSE WINS"
		result_subtitle = cpu_score["name"]
		result_detail = "POT $" + str(pot) + "  /  YOU " + player_score["name"]
		cpu_stack += pot
	else:
		result_title = "SPLIT POT"
		result_subtitle = player_score["name"]
		result_detail = "BOTH PLAYERS TIE"
		# The odd chip is awarded to the non-dealer, first in action postflop.
		var half: int = int(pot / 2)
		player_stack += half + (int(pot % 2) if not dealer_is_player else 0)
		cpu_stack += half + (int(pot % 2) if dealer_is_player else 0)
	_end_hand(winner, true)

func _end_hand(winner: int, shown: bool) -> void:
	hand_over = true
	busy = false
	screen = "result"
	if winner == 0:
		_sound("win", -5.0)
		fx.spray(Vector2(460, 462), 80, MINT, 240.0)
	elif winner == 1:
		_sound("lose", -8.0)
		fx.spray(Vector2(460, 462), 25, ROSE, 118.0)
	else:
		_sound("check", -8.0)
		fx.spray(Vector2(460, 462), 34, GOLD, 140.0)
	for card in card_nodes_player:
		if is_instance_valid(card):
			card.is_winner = winner == 0 or winner == -1
			card.dimmed = winner == 1
	for card in card_nodes_cpu:
		if is_instance_valid(card):
			card.is_winner = shown and (winner == 1 or winner == -1)
	if player_stack <= 0:
		result_detail += "  /  YOU ARE OUT"
	elif cpu_stack <= 0:
		result_detail += "  /  TABLE CLEARED"

# -----------------------------------------------------------------------------
# CARROM collection presentation: forest green grid, walnut rail, traditional
# casino felt, muted brass, clean typography, quiet panels and reactive accents.
# The 52 supplied PNG faces and animated card nodes remain completely intact.
# -----------------------------------------------------------------------------
func _draw() -> void:
	hotspots.clear()
	_draw_ambient()
	_draw_header()
	_draw_table()
	_draw_seats()
	_draw_community()
	_draw_footer()
	if screen == "attract":
		_draw_attract()
	if show_help:
		hotspots.append({"id": "close_help", "rect": Rect2(555, 679, 330, 48), "enabled": true})

func _rect(rect: Rect2, fill: Color, border: Color = Color.TRANSPARENT, thickness: float = 1.0) -> void:
	if fill.a > 0.0:
		draw_rect(rect, fill, true)
	if border.a > 0.0:
		draw_rect(rect, border, false, thickness)

func _rounded(rect: Rect2, fill: Color, border: Color = Color.TRANSPARENT, radius: int = 12) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(1)
	draw_style_box(sb, rect)

func _oval(center: Vector2, radius: Vector2, color: Color, segments: int = 112) -> void:
	var poly := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		poly.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(poly, color)

func _oval_ring(center: Vector2, radius: Vector2, color: Color, width: float = 1.0, segments: int = 112) -> void:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_polyline(pts, color, width, true)

func _text(value: String, pos: Vector2, font_size: int = 18, color: Color = PALE, alignment: int = 0, headline: bool = false) -> void:
	var font: Font = FONT_HEAD if headline else FONT
	var at := pos
	if alignment != 0:
		var measured: float = font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		at.x -= measured * (0.5 if alignment == 1 else 1.0)
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _accent_text(value: String, at: Vector2, font_size: int, color: Color, alignment: int = 0, headline: bool = false) -> void:
	# Text stays solid and legible; a small warm shadow adds depth.
	_text(value, at + Vector2(0, 1), font_size, Color(0, 0, 0, 0.16), alignment, headline)
	_text(value, at, font_size, color, alignment, headline)

func _draw_ambient() -> void:
	# Uniform cloth-like grid, the same quiet background treatment as CARROM.
	for x in range(0, 1441, 30):
		draw_line(Vector2(x, 0), Vector2(x, H), Color(1, 1, 1, 0.018), 1.0)
	for y in range(0, 901, 30):
		draw_line(Vector2(0, y), Vector2(W, y), Color(1, 1, 1, 0.018), 1.0)
	# Restrained drifting motes keep the original arcade effects alive.
	for i in range(26):
		var t: float = float(i) * 3.267
		var at := Vector2(fposmod(float(i * 119 + 53) + sin(table_clock * 0.23 + t) * 11.0, W), fposmod(float(i * 173 + 22) - table_clock * 2.3, H))
		draw_circle(at, 0.8 if i % 3 else 1.25, Color(MINT.r, MINT.g, MINT.b, 0.045 + 0.06 * pow(sin(table_clock * 0.7 + t), 2.0)))

func _draw_header() -> void:
	_text("TEXAS HOLD 'EM", Vector2(35, 44), 31, PALE, 0, true)
	_text("CLASSIC TABLE  /  SINGLE PLAYER", Vector2(35, 70), 13, MUTED)
	_text("NO LIMIT  /  HEADS UP", Vector2(35, 102), 13, MINT, 0, true)

func _draw_table() -> void:
	var center := Vector2(445, 453)
	# Broad grain-like flecks and real layered wood trim instead of glowing rings.
	_oval(center + Vector2(4, 10), Vector2(376, 294), Color(0.012, 0.03, 0.028, 0.35))
	_oval(center, Vector2(379, 295), Color("33231c"))
	_oval(center, Vector2(372, 288), Color("704328"))
	_oval(center, Vector2(367, 283), Color("c8955c"))
	_oval(center, Vector2(361, 277), Color("a5794d"))
	_oval(center, Vector2(354, 270), Color("342922"))
	_oval(center, Vector2(348, 263), Color("224c3d"))
	# Slightly lighter felting at the middle, still very subdued.
	_oval(center, Vector2(331, 246), Color("245142"))
	_oval(center, Vector2(314, 229), Color("254d3e"))
	_oval_ring(center, Vector2(346, 261), Color(Color("86b09a"), 0.31), 1.5)
	_oval_ring(center, Vector2(358, 274), Color(Color("f2d3a0"), 0.24), 1.0)
	_oval_ring(center, Vector2(372, 288), Color(Color("3b251c"), 0.56), 1.0)
	# A dozen tiny inlaid markers on the wooden rail.
	for i in range(16):
		var angle := TAU * float(i) / 16.0
		var p := center + Vector2(cos(angle) * 361.0, sin(angle) * 276.0)
		draw_circle(p, 2.2, Color(Color("ead3a5"), 0.42))
	# Fine card-zone divisions and stitched rails.
	draw_line(Vector2(209, 391), Vector2(678, 391), Color(Color("c7d7b4"), 0.19), 1.2)
	draw_line(Vector2(209, 543), Vector2(678, 543), Color(Color("c7d7b4"), 0.14), 1.2)
	_text("TEXAS HOLD 'EM", Vector2(445, 590), 17, Color(Color("bdd8c6"), 0.22), 1, true)

func _draw_seats() -> void:
	_draw_player_plate(Rect2(119, 240, 150, 73), "HOUSE", cpu_stack, GOLD, false)
	_draw_player_plate(Rect2(119, 594, 150, 78), "YOU", player_stack, MINT, true)
	_draw_dealer_pin(Vector2(655, 270) if not dealer_is_player else Vector2(655, 622))
	if screen != "attract":
		_text("IN  $%d" % paid_cpu, Vector2(277, 337), 13, Color("ecd5a2"))
		_text("IN  $%d" % paid_player, Vector2(277, 687), 13, Color("ecd5a2"))
	_text("HOUSE CARDS", Vector2(443, 187), 12, Color(Color("e4d9bd"), 0.60), 1, true)
	_text("YOUR CARDS", Vector2(443, 724), 12, Color(Color("e4d9bd"), 0.60), 1, true)

func _draw_player_plate(rect: Rect2, who: String, chips: int, color: Color, human: bool) -> void:
	_rounded(rect, Color(Color("19362e"), 0.94), Color(Color("819c88"), 0.28), 9)
	_rect(Rect2(rect.position.x + 1, rect.position.y + 10, 3, rect.size.y - 20), color)
	_text(who, rect.position + Vector2(15, 23), 12, MUTED, 0, true)
	_text("$%d" % chips, rect.position + Vector2(14, 58), 26, PALE, 0, true)
	if human:
		var rating := ""
		if hole_player.size() == 2 and screen != "attract":
			if board.size() >= 3:
				var known: Array = hole_player.duplicate()
				known.append_array(board)
				rating = Rules.best(known)["name"]
			else:
				rating = Rules.preflop_label(hole_player)
		_text(rating, Vector2(445, 747), 13, GOLD, 1)

func _draw_dealer_pin(pos: Vector2) -> void:
	draw_circle(pos + Vector2(0, 2), 18, Color(0, 0, 0, 0.20))
	draw_circle(pos, 16, Color("f5e8cd"))
	draw_arc(pos, 13, 0, TAU, 36, Color("8d6b41"), 1.5)
	_text("D", pos + Vector2(0, 6), 17, Color("5c4934"), 1, true)

func _draw_chip(pos: Vector2, color: Color, radius: float = 15.0) -> void:
	# Layered tournament chip with radial clay inserts and a cream center.
	draw_circle(pos + Vector2(0, 3), radius, Color(0, 0, 0, 0.26))
	draw_circle(pos, radius, Color("243a31"))
	draw_circle(pos, radius - 2, color)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var u := Vector2.RIGHT.rotated(angle)
		draw_line(pos + u * (radius - 5), pos + u * (radius - 1), Color("ffeed0"), 2.7)
	draw_circle(pos, radius * 0.57, Color("eddec2"))
	draw_circle(pos, radius * 0.42, color)
	draw_arc(pos, radius - 3, 0, TAU, 32, Color(0, 0, 0, 0.21), 1.0)

func _draw_community() -> void:
	var stages := ["PRE-FLOP", "FLOP", "TURN", "RIVER"]
	for i in range(4):
		var x: float = 295.0 + float(i * 102)
		var active := screen != "attract" and street == i
		var past := screen != "attract" and street > i
		_text(stages[i], Vector2(x, 375), 12, MINT if active else (PALE if past else Color(Color("adc5b7"), 0.5)), 1, active)
		if active:
			_rect(Rect2(x - 28, 381, 56, 2), MINT)
	for i in range(5):
		var placeholder := Rect2(COMMUNITY_X[i] - 51, 388, 102, 148)
		_rounded(placeholder, Color(Color("173a31"), 0.52), Color(Color("94b5a2"), 0.22), 6)
		if i >= board.size():
			_text("%02d" % (i + 1), Vector2(COMMUNITY_X[i], 467), 19, Color(Color("c3dbcb"), 0.23), 1)
	_draw_pot()
	if screen == "playing" and message_timer > 0.0 and not busy:
		_text(callout, Vector2(446, 576), 16, GOLD, 1, true)

func _draw_pot() -> void:
	for i in range(3):
		var offset := Vector2(float(i * 11 - 11), float((i % 2) * 5))
		_draw_chip(Vector2(383, 345) + offset, GOLD if i == 0 else (ROSE if i == 1 else MINT), 12.0)
	_text("POT", Vector2(421, 330), 12, Color("d6dec9"), 0, true)
	_accent_text("$%d" % pot, Vector2(420, 358), 25, PALE, 0, true)

func _draw_footer() -> void:
	# A fixed sidebar, mirroring CARROM's spacing, typography and hierarchy.
	_rounded(Rect2(867, 22, 551, 856), PANEL, Color("3c5b51"), 16)
	_text("THE MATCH", Vector2(900, 59), 14, MINT, 0, true)
	_text("HEADS UP  /  NO LIMIT", Vector2(900, 88), 19, PALE)
	_text("HAND %02d" % hand_number if hand_number > 0 else "TABLE 01", Vector2(1386, 88), 14, MUTED, 2)

	_rounded(Rect2(900, 110, 235, 117), PANEL_ALT, Color(Color("749587"), 0.10), 12)
	_rounded(Rect2(1147, 110, 239, 117), PANEL_ALT, Color(Color("749587"), 0.10), 12)
	_text("YOU  /  PLAYER", Vector2(918, 135), 13, MINT, 0, true)
	_text("HOUSE  /  CPU", Vector2(1165, 135), 13, GOLD, 0, true)
	_text("$%d" % player_stack, Vector2(917, 184), 40, PALE, 0, true)
	_text("$%d" % cpu_stack, Vector2(1164, 184), 40, PALE, 0, true)
	_text("IN THIS ROUND  $%d" % paid_player, Vector2(918, 212), 12, MUTED)
	_text("IN THIS ROUND  $%d" % paid_cpu, Vector2(1165, 212), 12, MUTED)

	_rect(Rect2(900, 251, 486, 1), Color(Color("72988a"), 0.48))
	_text("THE TABLE", Vector2(900, 282), 13, MINT, 0, true)
	_text("BLINDS  %d / %d" % [small_blind, big_blind], Vector2(1386, 282), 14, GOLD, 2)
	_rounded(Rect2(900, 299, 486, 88), PANEL_ALT, Color(Color("709e8b"), 0.13), 10)
	for j in range(3):
		_draw_chip(Vector2(931 + j * 16, 344 - j * 3), MINT if j == 0 else (GOLD if j == 1 else ROSE), 15)
	_text("CURRENT POT", Vector2(1008, 326), 13, MUTED)
	_accent_text("$%d" % pot, Vector2(1006, 366), 31, PALE, 0, true)
	var stages := ["PRE-FLOP", "FLOP", "TURN", "RIVER"]
	for i in range(4):
		var cx: float = 955.0 + i * 126.0
		var tone: Color = MINT if screen != "attract" and street == i else (PALE if screen != "attract" and street > i else MUTED)
		draw_circle(Vector2(cx, 420), 4.0 if i == street else 3.0, tone)
		_text(stages[i], Vector2(cx, 441), 12, tone, 1, i == street and screen != "attract")
		if i < 3:
			_rect(Rect2(cx + 19, 419, 87, 1), Color(Color("748c81"), 0.23))

	_rect(Rect2(900, 469, 486, 1), Color(Color("72988a"), 0.28))
	_text("THE ACTION", Vector2(900, 495), 13, MINT, 0, true)
	_rounded(Rect2(900, 510, 486, 94), Color("25483f"), Color("3e6759"), 10)
	var phase_title := "YOUR TURN" if _can_act() else ("HAND COMPLETE" if screen == "result" else ("SHUFFLING CARDS" if busy else "HOUSE TO ACT"))
	if screen == "attract":
		phase_title = "READY TO DEAL"
	_text(phase_title, Vector2(918, 545), 19, MINT, 0, true)
	var detail := "HAND COMPLETE  /  CONTINUE OR START OVER" if screen == "result" else ("START A MATCH TO TAKE YOUR SEAT" if screen == "attract" else cpu_action)
	if _can_act():
		detail = "TO CALL  $%d   /   CHOOSE YOUR ACTION" % mini(maxi(0, current_bet - paid_player), player_stack)
	_text(detail, Vector2(918, 573), 14, PALE)

	if _can_act():
		_draw_play_controls()
	elif screen == "result":
		var next_title := "NEW MATCH" if player_stack <= 0 or cpu_stack <= 0 else "NEXT HAND"
		_button("next", Rect2(900, 624, 486, 54), next_title, MINT, true, true, 20)
		_text(result_title + "  /  " + result_subtitle, Vector2(902, 710), 14, GOLD, 0, true)
	elif screen == "attract":
		_button("play", Rect2(900, 624, 486, 54), "DEAL ME IN", MINT, true, true, 21)
		_text("START WITH $1600  /  BLINDS $25 / $50", Vector2(1144, 715), 14, MUTED, 1)
	else:
		_text("CARDS ARE BEING DEALT", Vector2(1143, 665), 16, MUTED, 1)

	_rect(Rect2(900, 760, 486, 1), Color(Color("72988a"), 0.38))
	_text("CARD BACK %02d / 05" % (back_index + 1), Vector2(900, 785), 13, MUTED)
	_button("back", Rect2(1224, 768, 162, 31), "CHANGE BACK", GOLD, false, true, 13)
	_button("help", Rect2(900, 818, 218, 42), "RULES", PALE, false, true, 15)
	_button("new_match", Rect2(1128, 818, 258, 42), "NEW MATCH", PALE, false, not busy, 15)
	_text("MOUSE   /   F FOLD   /   C CALL   /   R RAISE", Vector2(35, 866), 13, MUTED)

func _draw_play_controls() -> void:
	var owed: int = maxi(0, current_bet - paid_player)
	var able: bool = _can_raise()
	_sync_raise()
	_button("fold", Rect2(900, 621, 147, 51), "FOLD", ROSE, false, true, 17)
	var call_title := "CHECK" if owed == 0 else ("ALL IN  $%d" % player_stack if owed >= player_stack else "CALL  $%d" % owed)
	_button("call", Rect2(1058, 621, 150, 51), call_title, MINT, true, true, 16)
	_button("raise", Rect2(1219, 621, 167, 51), ("RAISE $%d" % raised_to) if able else "NO RAISE", GOLD, true, able, 15)
	_button("min", Rect2(900, 688, 112, 31), "MIN", PALE, false, able, 13)
	_button("half", Rect2(1024, 688, 112, 31), "HALF POT", PALE, false, able, 13)
	_button("pot", Rect2(1148, 688, 112, 31), "POT", PALE, false, able, 13)
	_button("max", Rect2(1272, 688, 114, 31), "MAX", PALE, false, able, 13)
	_text("RAISE TO  $%d" % raised_to if able else "RAISE NOT AVAILABLE", Vector2(900, 745), 14, GOLD)
	_button("minus", Rect2(1261, 729, 56, 27), "-", PALE, false, able, 18)
	_button("plus", Rect2(1330, 729, 56, 27), "+", PALE, false, able, 18)

func _button(id: String, rect: Rect2, title: String, color: Color, solid: bool, enabled: bool, font_size: int = 20) -> void:
	var hovered: bool = enabled and rect.has_point(mouse_at) and (not show_help or id == "close_help")
	var alpha: float = 1.0 if enabled else 0.36
	var fill: Color = (color if solid else PANEL_ALT) if enabled else Color("233b35")
	if hovered:
		fill = fill.lightened(0.12)
	var border: Color = Color(color.r, color.g, color.b, (0.65 if hovered else 0.20) * alpha)
	_rounded(rect, Color(fill.r, fill.g, fill.b, alpha), border, 9)
	if hovered:
		# Small localized highlight in place of the previous glowing UI outlines.
		_rect(Rect2(rect.position.x + 11, rect.position.y + 5, rect.size.x - 22, 1), Color(color.r, color.g, color.b, 0.24))
	var tone := INK if solid and enabled else (PALE if enabled else MUTED)
	_text(title, rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.5 + font_size * 0.35), font_size, Color(tone.r, tone.g, tone.b, alpha), 1, solid)
	hotspots.append({"id": id, "rect": rect, "enabled": enabled})

func _draw_attract() -> void:
	# Inset classic tournament welcome card, with the table still visible.
	_rounded(Rect2(161, 295, 567, 312), Color(Color("19362e"), 0.985), Color(Color("8d986d"), 0.44), 16)
	_rect(Rect2(188, 319, 513, 1), Color(GOLD.r, GOLD.g, GOLD.b, 0.27))
	_text("THE CLASSIC GAME", Vector2(445, 360), 14, MINT, 1, true)
	_text("TEXAS HOLD 'EM", Vector2(445, 424), 44, PALE, 1, true)
	_text("A game of cards, odds and nerve.", Vector2(445, 458), 18, MUTED, 1)
	_text("PLAY THE HOUSE  /  NO LIMIT HOLD 'EM", Vector2(445, 496), 14, GOLD, 1)
	_button("play", Rect2(297, 525, 296, 53), "DEAL ME IN", MINT, true, true, 19)

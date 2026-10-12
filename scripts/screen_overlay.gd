extends Node2D

const FONT = preload("res://Fonts/ClearSans-Regular.ttf")
const HEAD = preload("res://Fonts/ClearSans-Bold.ttf")
const MINT := Color("7bdac2")
const ROSE := Color("cb7466")
const GOLD := Color("e8bf7e")
const WHITE := Color("f7f0d9")
const MUTED := Color("a7bbb1")
var game: Node2D
var entrance_time := 0.0
var previous_screen := ""

func _process(delta: float) -> void:
    if game != null:
        if game.screen != previous_screen:
            previous_screen = game.screen
            entrance_time = 0.0
        else:
            entrance_time += delta
    queue_redraw()

func _write(s: String, at: Vector2, size: int, c: Color, center: bool = false, heading: bool = false) -> void:
    var font: Font = HEAD if heading else FONT
    if center:
        at.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
    draw_string(font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, c)

func _panel(rect: Rect2, outline: Color) -> void:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(Color("19322e"), 0.985)
    style.set_corner_radius_all(14)
    style.border_color = outline
    style.set_border_width_all(1)
    draw_style_box(style, rect)

func _draw() -> void:
    if game == null:
        return
    if game.show_help:
        _draw_help()
    elif game.screen == "draft":
        _draw_draft()
    elif game.screen == "run_end":
        _draw_run_end()

func _draw_draft() -> void:
    draw_rect(Rect2(0, 0, 1440, 900), Color(Color("102320"), 0.88), true)
    _panel(Rect2(144, 184, 1154, 523), Color(GOLD.r, GOLD.g, GOLD.b, 0.65))
    draw_rect(Rect2(171, 220, 1100, 1), Color(GOLD.r, GOLD.g, GOLD.b, 0.26), true)
    _write("TABLE RUN  /  CHOOSE ONE", Vector2(720, 246), 16, MINT, true, true)
    _write("MAKE YOUR NEXT HAND COUNT", Vector2(720, 298), 31, WHITE, true, true)
    for i in range(game.run_choices.size()):
        var perk: Dictionary = game.run_choices[i]
        var card := Rect2(189 + i * 350, 321, 322, 256)
        var entrance: float = clampf((entrance_time - float(i) * 0.14) / 0.39, 0.0, 1.0)
        var ease: float = 1.0 - pow(1.0 - entrance, 3.0)
        # Slide each perk upward one at a time. All positions settle to their
        # exact clickable rectangles. The cards are never poker-card nodes.
        draw_set_transform(Vector2(0, 44.0 * (1.0 - ease)), 0.0, Vector2.ONE)
        var hovered: bool = card.has_point(game.mouse_at) and entrance >= 1.0
        var style := StyleBoxFlat.new()
        style.bg_color = Color("315448") if hovered else Color("223e35")
        style.border_color = GOLD if hovered else Color("607b66")
        style.set_corner_radius_all(12)
        style.set_border_width_all(2 if hovered else 1)
        draw_style_box(style, card)
        draw_rect(Rect2(card.position.x + 17, card.position.y + 19, 4, 39), GOLD if hovered else MINT)
        _write("0%d  /  UPGRADE" % (i + 1), card.position + Vector2(34, 45), 13, MINT, false, true)
        _write(perk["name"], card.position + Vector2(20, 101), 24, WHITE, false, true)
        _write(perk["value"], card.position + Vector2(20, 157), 40, GOLD, false, true)
        _write(perk["detail"], card.position + Vector2(20, 201), 13, WHITE)
        _write(perk["effect"], card.position + Vector2(20, 228), 12, MUTED)
        draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    _write("EVERY UPGRADE STACKS.  SCORING ONLY - POKER ODDS STAY FAIR.", Vector2(720, 619), 16, WHITE, true)
    _write("CLICK A CARD OR PRESS 1, 2 OR 3", Vector2(720, 661), 15, GOLD, true)

func _draw_run_end() -> void:
    draw_rect(Rect2(0, 0, 1440, 900), Color(Color("102320"), 0.92), true)
    _panel(Rect2(280, 208, 880, 508), Color(GOLD.r, GOLD.g, GOLD.b, 0.64))
    var complete: bool = game.run_finished_text == "RUN COMPLETE"
    var tone: Color = GOLD if complete else ROSE
    _write("TEXAS HOLD 'EM  /  TABLE RUN", Vector2(720, 281), 18, MINT, true, true)
    _write(game.run_finished_text, Vector2(720, 356), 48, tone, true, true)
    _write(game.result_subtitle, Vector2(720, 397), 18, WHITE, true)
    _write("FINAL SCORE", Vector2(720, 458), 15, MUTED, true)
    _write("%d" % game.run_score, Vector2(720, 515), 50, GOLD, true, true)
    _write("PERSONAL BEST  %d    /    HANDS PLAYED  %d" % [game.run_best_score, game.hand_number], Vector2(720, 548), 15, MUTED, true)
    for i in range(2):
        var r := Rect2(376 + i * 364, 588, 324, 60)
        var hover: bool = r.has_point(game.mouse_at)
        var box := StyleBoxFlat.new()
        box.set_corner_radius_all(10)
        box.bg_color = Color("80cfb5") if i == 0 and hover else (MINT if i == 0 else (Color("426252") if hover else Color("294a40")))
        box.border_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.46)
        box.set_border_width_all(1)
        draw_style_box(box, r)
        _write("NEW TABLE RUN" if i == 0 else "CLASSIC TABLE", r.position + Vector2(162, 39), 21, Color("0b211e") if i == 0 else WHITE, true, true)
    _write("NO REAL MONEY  /  EVERY NEW RUN STARTS FRESH", Vector2(720, 688), 13, MUTED, true)

func _draw_help() -> void:
    draw_rect(Rect2(0, 0, 1440, 900), Color(Color("102320"), 0.94), true)
    _panel(Rect2(315, 143, 810, 603), Color("6f9584"))
    _write("TEXAS HOLD 'EM", Vector2(720, 205), 32, WHITE, true, true)
    _write("HOW TO PLAY", Vector2(720, 237), 16, MINT, true, true)
    draw_rect(Rect2(359, 256, 721, 1), Color(MINT.r, MINT.g, MINT.b, 0.28))
    var rules := [
        "YOU AND THE HOUSE EACH RECEIVE TWO PRIVATE CARDS.",
        "FIVE SHARED CARDS ARRIVE IN THREE STAGES:",
        "FLOP (3), TURN (1), AND RIVER (1).",
        "BUILD THE BEST FIVE-CARD HAND FROM ANY SEVEN.",
        "CHECK, CALL, RAISE OR FOLD ON YOUR TURN.",
        "THE BEST HAND WINS THE POT AT SHOWDOWN.",
        "BLINDS INCREASE EVERY SIX HANDS.",
        "TABLE RUN: NINE HANDS, SCORE TARGETS AND SCORING UPGRADES."
    ]
    for i in range(rules.size()):
        _write(rules[i], Vector2(365, 300 + i * 39), 17, WHITE)
    draw_rect(Rect2(359, 585, 721, 1), Color(MINT.r, MINT.g, MINT.b, 0.28))
    _write("F  FOLD      C  CHECK / CALL      R  RAISE", Vector2(720, 622), 16, GOLD, true)
    _write("UP / DOWN  ADJUST BET      SPACE  NEXT HAND", Vector2(720, 650), 16, MUTED, true)
    var r := Rect2(555, 679, 330, 48)
    var hovered: bool = r.has_point(game.mouse_at)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("345d51") if hovered else Color("25483f")
    style.set_corner_radius_all(9)
    style.border_color = Color(MINT.r, MINT.g, MINT.b, 0.55)
    style.set_border_width_all(1)
    draw_style_box(style, r)
    _write("BACK TO TABLE", Vector2(720, 710), 17, WHITE, true, true)

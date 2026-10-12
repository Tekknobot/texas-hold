extends Node2D

const FONT = preload("res://Fonts/ClearSans-Regular.ttf")
const HEAD = preload("res://Fonts/ClearSans-Bold.ttf")
const MINT := Color("7bdac2")
const ROSE := Color("cb7466")
const GOLD := Color("e8bf7e")
const WHITE := Color("f7f0d9")
const MUTED := Color("a7bbb1")
var game: Node2D

func _process(_delta: float) -> void:
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
    elif game.screen == "result":
        _draw_result()

func _draw_result() -> void:
    var title: String = game.result_title
    var c: Color = MINT if title == "YOU WIN" else (GOLD if title == "SPLIT POT" else ROSE)
    # Lower-left status never covers the five shared cards or the player's hand.
    var frame := Rect2(89, 717, 316, 108)
    _panel(frame, Color(c.r, c.g, c.b, 0.65))
    draw_rect(Rect2(102, 729, 4, 84), c)
    _write(title, Vector2(120, 750), 19, c, false, true)
    _write(game.result_subtitle, Vector2(120, 776), 15, WHITE)
    _write(game.result_detail, Vector2(120, 804), 11, MUTED)

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
        "BLINDS INCREASE EVERY SIX HANDS."
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

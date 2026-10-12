extends Node2D
class_name HoldemCard

var face_texture: Texture2D
var back_texture: Texture2D
var face_up := false
var flip_progress := 0.0
var card_scale := 2.68
var hover_amount := 0.0
var hover_target := 0.0
var tilt := 0.0
var reveal_glow := 0.0
var is_mine := false
var is_winner := false
var dimmed := false
var clock := 0.0

func setup(front: Texture2D, back: Texture2D, size_multiplier: float, mine: bool = false) -> void:
	face_texture = front
	back_texture = back
	card_scale = size_multiplier
	is_mine = mine
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func reveal(duration: float = 0.48) -> void:
	if face_up:
		return
	face_up = true
	var tween := create_tween()
	tween.tween_property(self, "flip_progress", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(self, "reveal_glow", 1.0, duration * 0.5)
	tween.tween_property(self, "reveal_glow", 0.0, duration * 1.5).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	clock += delta
	hover_amount = move_toward(hover_amount, hover_target, delta * 5.0)
	queue_redraw()

func _draw() -> void:
	if face_texture == null or back_texture == null:
		return
	var w := 37.0
	var h := 52.0
	var cosine := cos(flip_progress * PI)
	var width_scale: float = maxf(absf(cosine), 0.035)
	var shrink := 1.0 + hover_amount * 0.07 + (0.045 * sin(clock * 3.5) if is_winner else 0.0)
	var y_lift := -hover_amount * 9.0 - (1.0 - width_scale) * 3.0
	var shear_angle := tilt + sin(clock * 0.65 + position.x) * 0.002
	var tex: Texture2D = face_texture if flip_progress >= 0.5 else back_texture
	var opacity := 0.42 if dimmed else 1.0
	var base_color := Color(1.0, 1.0, 1.0, opacity)
	var outline := Color("7bdac2") if is_winner else Color("e8bf7e")
	var glow_alpha := 0.055 + hover_amount * 0.20 + reveal_glow * 0.30 + (0.17 if is_winner else 0.0)
	draw_set_transform(Vector2(0.0, y_lift), shear_angle, Vector2(width_scale * card_scale * shrink, card_scale * (1.0 + hover_amount * 0.02)))
	var rect := Rect2(-w * 0.5, -h * 0.5, w, h)
	for i in range(3, 0, -1):
		var r: float = float(i) * 2.5
		draw_rect(rect.grow(r), Color(outline.r, outline.g, outline.b, glow_alpha * 0.25), true)
	draw_rect(rect.grow(0.65), Color(0.11, 0.20, 0.17, 0.90), true)
	draw_texture_rect(tex, rect, false, base_color)
	if flip_progress > 0.05 and flip_progress < 0.95:
		var shine := 1.0 - width_scale
		draw_rect(Rect2(-1.5, -h * 0.5, 3.0, h), Color(0.86, 1.0, 0.94, shine * 0.65), true)
	if hover_amount > 0.0 or is_winner:
		var stripe_x: float = fposmod(clock * 18.0, w + h) - h
		draw_line(Vector2(stripe_x, -h * 0.5), Vector2(stripe_x + 7.0, h * 0.5), Color(0.95, 1.0, 1.0, hover_amount * 0.09 + (0.05 if is_winner else 0.0)), 1.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

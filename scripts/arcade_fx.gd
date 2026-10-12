extends Node2D
class_name ArcadeFX

var particles: Array = []
var sparks: Array = []
var time_passed := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func spray(pos: Vector2, amount: int = 20, hue: Color = Color("7bdac2"), force: float = 150.0) -> void:
	for i in range(amount):
		var angle: float = rng.randf_range(-PI, PI)
		var speed: float = rng.randf_range(force * 0.28, force)
		var life: float = rng.randf_range(0.45, 1.35)
		particles.append({"pos": pos, "vel": Vector2.RIGHT.rotated(angle) * speed, "t": 0.0, "life": life, "r": rng.randf_range(1.1, 3.5), "color": hue.lerp(Color("fff6dc"), rng.randf() * 0.55), "gravity": rng.randf_range(-7.0, 22.0)})
	if particles.size() > 340:
		particles = particles.slice(particles.size() - 340)

func chip_burst(start: Vector2, end: Vector2, col: Color = Color("e8bf7e")) -> void:
	for i in range(13):
		var offset := Vector2(rng.randf_range(-12, 12), rng.randf_range(-8, 8))
		var duration := rng.randf_range(0.38, 0.68)
		sparks.append({"a": start + offset, "b": end + Vector2(rng.randf_range(-25, 25), rng.randf_range(-16, 16)), "t": -rng.randf_range(0.0, 0.16), "duration": duration, "c": col})

func _process(delta: float) -> void:
	time_passed += delta
	for i in range(particles.size() - 1, -1, -1):
		var p: Dictionary = particles[i]
		p["t"] += delta
		p["pos"] += p["vel"] * delta
		p["vel"] = p["vel"] * maxf(0.0, 1.0 - delta * 1.4) + Vector2(0.0, p["gravity"]) * delta
		if p["t"] >= p["life"]:
			particles.remove_at(i)
	for i in range(sparks.size() - 1, -1, -1):
		var p: Dictionary = sparks[i]
		p["t"] += delta
		if p["t"] > p["duration"]:
			sparks.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for p in sparks:
		var k: float = clampf(p["t"] / p["duration"], 0.0, 1.0)
		if k <= 0.0:
			continue
		var eased := 1.0 - pow(1.0 - k, 3.0)
		var pos: Vector2 = p["a"].lerp(p["b"], eased)
		pos.y -= 38.0 * sin(k * PI)
		var alpha := sin(PI * k)
		var col: Color = p["c"]
		draw_circle(pos, 7.0, Color(col.r, col.g, col.b, alpha * 0.09))
		draw_circle(pos, 3.0, Color(col.r, col.g, col.b, alpha * 0.55))
		draw_circle(pos, 1.3, Color(1.0, 1.0, 0.95, alpha))
	for p in particles:
		var alpha: float = pow(maxf(0.0, 1.0 - p["t"] / p["life"]), 1.2)
		var c: Color = p["color"]
		var loc: Vector2 = p["pos"]
		var radius: float = p["r"]
		draw_circle(loc, radius * 2.7, Color(c.r, c.g, c.b, alpha * 0.07))
		draw_circle(loc, radius, Color(c.r, c.g, c.b, alpha * 0.85))

extends Node
class_name UIAnimations

## Animations UI — HouseMaster 3D
## Transitions douces, effets de survol, apparition/disparition panneaux

# ── Constantes ──────────────────────────────────────────
const FADE_DURATION := 0.2
const SLIDE_DURATION := 0.25
const HOVER_DURATION := 0.1
const EASE_TYPE := Tween.EASE_OUT
const TRANS_TYPE := Tween.TRANS_CUBIC


# ── Fade In/Out ─────────────────────────────────────────

static func fade_in(control: Control, duration := FADE_DURATION) -> Tween:
	control.modulate.a = 0.0
	control.visible = true
	var tween := control.create_tween()
	tween.set_ease(EASE_TYPE)
	tween.set_trans(TRANS_TYPE)
	tween.tween_property(control, "modulate:a", 1.0, duration)
	return tween


static func fade_out(control: Control, duration := FADE_DURATION) -> Tween:
	var tween := control.create_tween()
	tween.set_ease(EASE_TYPE)
	tween.set_trans(TRANS_TYPE)
	tween.tween_property(control, "modulate:a", 0.0, duration)
	tween.tween_callback(func(): control.visible = false)
	return tween


# ── Slide depuis la droite ──────────────────────────────

static func slide_in_right(control: Control, distance := 300.0, duration := SLIDE_DURATION) -> Tween:
	var target_x := control.position.x
	control.position.x = target_x + distance
	control.modulate.a = 0.0
	control.visible = true
	var tween := control.create_tween()
	tween.set_ease(EASE_TYPE)
	tween.set_trans(TRANS_TYPE)
	tween.set_parallel(true)
	tween.tween_property(control, "position:x", target_x, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.6)
	return tween


static func slide_out_right(control: Control, distance := 300.0, duration := SLIDE_DURATION) -> Tween:
	var target_x := control.position.x + distance
	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(TRANS_TYPE)
	tween.set_parallel(true)
	tween.tween_property(control, "position:x", target_x, duration)
	tween.tween_property(control, "modulate:a", 0.0, duration * 0.8)
	tween.chain().tween_callback(func():
		control.visible = false
		control.position.x = target_x - distance
	)
	return tween


# ── Slide depuis le bas ─────────────────────────────────

static func slide_in_bottom(control: Control, distance := 120.0, duration := SLIDE_DURATION) -> Tween:
	var target_y := control.position.y
	control.position.y = target_y + distance
	control.modulate.a = 0.0
	control.visible = true
	var tween := control.create_tween()
	tween.set_ease(EASE_TYPE)
	tween.set_trans(TRANS_TYPE)
	tween.set_parallel(true)
	tween.tween_property(control, "position:y", target_y, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.6)
	return tween


# ── Scale pop (notification, modal) ────────────────────

static func pop_in(control: Control, duration := 0.2) -> Tween:
	control.scale = Vector2(0.8, 0.8)
	control.modulate.a = 0.0
	control.visible = true
	var tween := control.create_tween()
	tween.set_ease(EASE_TYPE)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2.ONE, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.5)
	return tween


static func pop_out(control: Control, duration := 0.15) -> Tween:
	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(TRANS_TYPE)
	tween.set_parallel(true)
	tween.tween_property(control, "scale", Vector2(0.9, 0.9), duration)
	tween.tween_property(control, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(func():
		control.visible = false
		control.scale = Vector2.ONE
	)
	return tween


# ── Hover effects ───────────────────────────────────────

static func setup_hover_highlight(control: Control, normal_color := UITheme.BG_BUTTON, hover_color := UITheme.BG_BUTTON_HOVER) -> void:
	control.mouse_entered.connect(func():
		var tween := control.create_tween()
		tween.set_ease(EASE_TYPE)
		tween.set_trans(TRANS_TYPE)
		tween.tween_property(control, "self_modulate", Color(1.15, 1.15, 1.15), HOVER_DURATION)
	)
	control.mouse_exited.connect(func():
		var tween := control.create_tween()
		tween.set_ease(EASE_TYPE)
		tween.set_trans(TRANS_TYPE)
		tween.tween_property(control, "self_modulate", Color.WHITE, HOVER_DURATION)
	)


# ── Toggle panel avec animation ────────────────────────

static func toggle_panel(panel: Control, show: bool, direction := "right") -> Tween:
	if show and not panel.visible:
		match direction:
			"right": return slide_in_right(panel)
			"bottom": return slide_in_bottom(panel)
			_: return fade_in(panel)
	elif not show and panel.visible:
		match direction:
			"right": return slide_out_right(panel)
			_: return fade_out(panel)
	return null


# ── Flash notification (couleur temporaire) ─────────────

static func flash_color(control: Control, flash_c: Color, duration := 0.4) -> Tween:
	var original := control.modulate
	var tween := control.create_tween()
	tween.tween_property(control, "modulate", flash_c, duration * 0.3)
	tween.tween_property(control, "modulate", original, duration * 0.7)
	return tween

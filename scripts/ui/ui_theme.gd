class_name UITheme
extends RefCounted

## UITheme — Constantes et factory pour le thème dark moderne HouseMaster 3D
## Utilisé par tous les composants UI pour un style cohérent

# ── Couleurs ──────────────────────────────────────────────
const BG_DARK := Color("1a1a1a")
const BG_MAIN := Color("1e1e1e")
const BG_PANEL := Color("252525")
const BG_PANEL_HOVER := Color("2a2a2a")
const BG_INPUT := Color("1c1c1c")
const BG_HEADER := Color("2d2d2d")
const BG_BUTTON := Color("333333")
const BG_BUTTON_HOVER := Color("3d3d3d")
const BG_BUTTON_PRESSED := Color("4DA3FF")
const BG_SELECTED := Color("4DA3FF")

const BORDER := Color("3a3a3a")
const BORDER_FOCUS := Color("4DA3FF")
const SEPARATOR := Color("333333")

const ACCENT := Color("4DA3FF")
const ACCENT_HOVER := Color("6BB5FF")
const ACCENT_DIM := Color("2a6bb5")
const SUCCESS := Color("5cb85c")
const WARNING := Color("f0ad4e")
const ERROR := Color("d9534f")

const TEXT := Color("e6e6e6")
const TEXT_DIM := Color("888888")
const TEXT_BRIGHT := Color("ffffff")
const TEXT_ACCENT := Color("4DA3FF")

# ── Dimensions ────────────────────────────────────────────
const CORNER_RADIUS := 4
const BORDER_WIDTH := 1
const MARGIN_SM := 4
const MARGIN_MD := 8
const MARGIN_LG := 12
const MARGIN_XL := 16
const FONT_SIZE_SM := 11
const FONT_SIZE_MD := 13
const FONT_SIZE_LG := 15
const FONT_SIZE_XL := 18
const FONT_SIZE_TITLE := 20
const ICON_SIZE := 16
const BUTTON_HEIGHT := 28
const HEADER_HEIGHT := 32
const SCROLLBAR_WIDTH := 8

# ── Factory StyleBox ──────────────────────────────────────

static func panel_style(bg_color := BG_PANEL, radius := CORNER_RADIUS, border_color := BORDER, border_w := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg_color
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	if border_w > 0:
		s.border_color = border_color
		s.border_width_left = border_w
		s.border_width_top = border_w
		s.border_width_right = border_w
		s.border_width_bottom = border_w
	s.content_margin_left = MARGIN_MD
	s.content_margin_right = MARGIN_MD
	s.content_margin_top = MARGIN_MD
	s.content_margin_bottom = MARGIN_MD
	return s


static func button_style_normal() -> StyleBoxFlat:
	var s := panel_style(BG_BUTTON, CORNER_RADIUS, BORDER, 1)
	s.content_margin_left = MARGIN_LG
	s.content_margin_right = MARGIN_LG
	s.content_margin_top = MARGIN_SM
	s.content_margin_bottom = MARGIN_SM
	return s


static func button_style_hover() -> StyleBoxFlat:
	var s := button_style_normal()
	s.bg_color = BG_BUTTON_HOVER
	s.border_color = ACCENT
	return s


static func button_style_pressed() -> StyleBoxFlat:
	var s := button_style_normal()
	s.bg_color = ACCENT
	s.border_color = ACCENT_HOVER
	return s


static func button_style_accent() -> StyleBoxFlat:
	var s := panel_style(ACCENT, CORNER_RADIUS, ACCENT_HOVER, 1)
	s.content_margin_left = MARGIN_LG
	s.content_margin_right = MARGIN_LG
	s.content_margin_top = MARGIN_SM
	s.content_margin_bottom = MARGIN_SM
	return s


static func input_style() -> StyleBoxFlat:
	var s := panel_style(BG_INPUT, CORNER_RADIUS, BORDER, 1)
	s.content_margin_left = MARGIN_MD
	s.content_margin_right = MARGIN_MD
	s.content_margin_top = MARGIN_SM
	s.content_margin_bottom = MARGIN_SM
	return s


static func input_style_focus() -> StyleBoxFlat:
	var s := input_style()
	s.border_color = BORDER_FOCUS
	return s


static func separator_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = SEPARATOR
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	return s


static func header_style() -> StyleBoxFlat:
	var s := panel_style(BG_HEADER, 0)
	s.content_margin_left = MARGIN_LG
	s.content_margin_right = MARGIN_LG
	s.content_margin_top = MARGIN_SM
	s.content_margin_bottom = MARGIN_SM
	s.border_color = SEPARATOR
	s.border_width_bottom = 1
	return s


static func tab_style_active() -> StyleBoxFlat:
	var s := panel_style(BG_PANEL, CORNER_RADIUS)
	s.border_color = ACCENT
	s.border_width_bottom = 2
	return s


static func tab_style_inactive() -> StyleBoxFlat:
	var s := panel_style(BG_DARK, CORNER_RADIUS)
	return s


static func scrollbar_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("444444")
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	s.content_margin_left = 2
	s.content_margin_right = 2
	return s


# ── Appliquer thème à un Control ──────────────────────────

static func apply_button_theme(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", button_style_normal())
	btn.add_theme_stylebox_override("hover", button_style_hover())
	btn.add_theme_stylebox_override("pressed", button_style_pressed())
	btn.add_theme_stylebox_override("focus", button_style_hover())
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", TEXT_BRIGHT)
	btn.add_theme_color_override("font_pressed_color", TEXT_BRIGHT)
	btn.add_theme_font_size_override("font_size", FONT_SIZE_MD)


static func apply_accent_button(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", button_style_accent())
	btn.add_theme_stylebox_override("hover", button_style_accent())
	btn.add_theme_stylebox_override("pressed", button_style_pressed())
	btn.add_theme_color_override("font_color", TEXT_BRIGHT)
	btn.add_theme_color_override("font_hover_color", TEXT_BRIGHT)
	btn.add_theme_font_size_override("font_size", FONT_SIZE_MD)


static func apply_input_theme(input: Control) -> void:
	input.add_theme_stylebox_override("normal", input_style())
	input.add_theme_stylebox_override("focus", input_style_focus())
	input.add_theme_color_override("font_color", TEXT)
	input.add_theme_color_override("font_placeholder_color", TEXT_DIM)
	input.add_theme_font_size_override("font_size", FONT_SIZE_MD)


static func apply_label_theme(label: Label, size := FONT_SIZE_MD, color := TEXT) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)


static func apply_panel_theme(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", panel_style())


static func make_header_label(text: String, size := FONT_SIZE_LG) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT_BRIGHT)
	return l


static func make_dim_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", FONT_SIZE_SM)
	l.add_theme_color_override("font_color", TEXT_DIM)
	return l


static func make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", separator_style())
	sep.add_theme_constant_override("separation", 8)
	return sep


static func make_spacer(height := 4) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


static func make_icon_button(text: String, icon_char: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = "%s  %s" % [icon_char, text]
	btn.pressed.connect(callback)
	apply_button_theme(btn)
	return btn

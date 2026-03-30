extends RefCounted

const DEFAULT_THEME := 0

const PALETTES := {
	0: {
		"tile_light": Color(0.16, 0.17, 0.22),
		"tile_dark": Color(0.12, 0.13, 0.18),
		"edge_inner": Color(0.15, 0.08, 0.05),
		"edge_outer": Color(0.22, 0.08, 0.04),
		"line_color": Color(0.22, 0.2, 0.15, 0.3),
		"line_edge": Color(0.5, 0.2, 0.15, 0.6),
		"void_color": Color(0.03, 0.03, 0.05),
		"accent": Color(0.8, 0.45, 0.15),
		"ambient_tint": Color(0.55, 0.5, 0.65),
		"light_color": Color(1.0, 0.9, 0.7),
	},
	1: {
		"tile_light": Color(0.14, 0.12, 0.16),
		"tile_dark": Color(0.10, 0.08, 0.12),
		"edge_inner": Color(0.30, 0.10, 0.04),
		"edge_outer": Color(0.45, 0.12, 0.02),
		"line_color": Color(0.35, 0.15, 0.08, 0.35),
		"line_edge": Color(0.7, 0.25, 0.08, 0.7),
		"void_color": Color(0.04, 0.02, 0.02),
		"accent": Color(1.0, 0.5, 0.1),
		"ambient_tint": Color(0.55, 0.42, 0.38),
		"light_color": Color(1.0, 0.75, 0.5),
	},
	2: {
		"tile_light": Color(0.14, 0.13, 0.20),
		"tile_dark": Color(0.10, 0.09, 0.16),
		"edge_inner": Color(0.18, 0.06, 0.18),
		"edge_outer": Color(0.25, 0.06, 0.22),
		"line_color": Color(0.22, 0.15, 0.25, 0.3),
		"line_edge": Color(0.5, 0.15, 0.5, 0.6),
		"void_color": Color(0.03, 0.02, 0.05),
		"accent": Color(0.7, 0.3, 0.9),
		"ambient_tint": Color(0.50, 0.42, 0.58),
		"light_color": Color(0.9, 0.75, 1.0),
	},
	3: {
		"tile_light": Color(0.12, 0.10, 0.10),
		"tile_dark": Color(0.08, 0.06, 0.06),
		"edge_inner": Color(0.50, 0.15, 0.03),
		"edge_outer": Color(0.70, 0.20, 0.03),
		"line_color": Color(0.40, 0.18, 0.08, 0.4),
		"line_edge": Color(0.8, 0.3, 0.1, 0.8),
		"void_color": Color(0.05, 0.02, 0.01),
		"accent": Color(1.0, 0.6, 0.15),
		"ambient_tint": Color(0.55, 0.35, 0.30),
		"light_color": Color(1.0, 0.8, 0.5),
	},
}

var _owner: Node2D

func _init(owner: Node2D) -> void:
	_owner = owner

func resolve_theme(current_floor_theme: int, theme_set_by_subclass: bool) -> int:
	if not theme_set_by_subclass and GameManager.current_room:
		match GameManager.current_room.room_type:
			RoomData.RoomType.ELITE:
				return 2
			RoomData.RoomType.BOSS:
				return 3
			_:
				if GameManager.current_room.tier >= 2:
					return 1
	return current_floor_theme

func get_palette(floor_theme: int) -> Dictionary:
	return PALETTES.get(floor_theme, PALETTES[DEFAULT_THEME])

func draw_floor(palette: Dictionary, floor_theme: int, grid_count: int, tile_w: int, tile_h: int) -> void:
	var active_palette: Dictionary = palette if not palette.is_empty() else PALETTES[DEFAULT_THEME]
	var void_col: Color = active_palette["void_color"]
	void_col.a = 1.0
	_owner.draw_rect(Rect2(-3000, -2000, 6000, 4000), void_col)

	_draw_edge_glow(active_palette, grid_count, tile_w)
	_draw_wall_silhouettes(active_palette, grid_count, floor_theme)

	for ix in range(-grid_count, grid_count + 1):
		for iy in range(-grid_count, grid_count + 1):
			var screen_x: float = float(ix - iy) * (tile_w * 0.5)
			var screen_y: float = float(ix + iy) * (tile_h * 0.5)
			if absi(ix) + absi(iy) > grid_count:
				continue

			var tile_hash: float = fmod(absf(sin(float(ix * 73 + iy * 137))), 1.0)
			var edge_dist := absi(ix) + absi(iy)
			var floor_color: Color = _resolve_tile_color(active_palette, ix, iy, edge_dist, grid_count, tile_hash)

			var hw: float = tile_w * 0.5
			var hh: float = tile_h * 0.5
			var points := PackedVector2Array([
				Vector2(screen_x, screen_y - hh),
				Vector2(screen_x + hw, screen_y),
				Vector2(screen_x, screen_y + hh),
				Vector2(screen_x - hw, screen_y),
			])
			_owner.draw_colored_polygon(points, floor_color)
			_draw_tile_thickness(points, floor_color)

			var line_col: Color = active_palette["line_color"] if edge_dist < grid_count - 1 else active_palette["line_edge"]
			_owner.draw_polyline(PackedVector2Array([
				points[0], points[1], points[2], points[3], points[0]
			]), line_col, 1.0)

			if tile_hash < 0.15:
				_draw_tile_cracks(points, floor_color, tile_hash)

	if floor_theme == 1 or floor_theme == 3:
		_draw_lava_veins(active_palette, grid_count, tile_w, tile_h)
	if floor_theme == 2 or floor_theme == 3:
		_draw_floor_runes(active_palette, floor_theme)

func _resolve_tile_color(palette: Dictionary, ix: int, iy: int, edge_dist: int, grid_count: int, tile_hash: float) -> Color:
	var is_light: bool = (ix + iy) % 2 == 0
	var floor_color: Color = palette["tile_light"] if is_light else palette["tile_dark"]
	floor_color = floor_color.lightened((tile_hash - 0.5) * 0.08)
	var depth_t: float = float(edge_dist) / float(grid_count)
	floor_color = floor_color.darkened(depth_t * 0.25)
	if edge_dist == grid_count:
		return palette["edge_outer"]
	if edge_dist == grid_count - 1:
		return floor_color.lerp(palette["edge_inner"], 0.3)
	return floor_color

func _draw_tile_thickness(points: PackedVector2Array, floor_color: Color) -> void:
	var edge_h: float = 5.0
	var side_color: Color = floor_color.darkened(0.4)
	var right_edge := PackedVector2Array([
		points[1], points[2],
		Vector2(points[2].x, points[2].y + edge_h),
		Vector2(points[1].x, points[1].y + edge_h),
	])
	_owner.draw_colored_polygon(right_edge, side_color)
	var left_edge := PackedVector2Array([
		points[2], points[3],
		Vector2(points[3].x, points[3].y + edge_h),
		Vector2(points[2].x, points[2].y + edge_h),
	])
	_owner.draw_colored_polygon(left_edge, side_color.darkened(0.15))

func _draw_tile_cracks(points: PackedVector2Array, base_color: Color, seed_val: float) -> void:
	var center := (points[0] + points[2]) * 0.5
	var crack_color := base_color.darkened(0.35)
	crack_color.a = 0.5
	var num_cracks: int = 2 + int(seed_val * 8.0) % 2
	for crack_index in range(num_cracks):
		var angle: float = seed_val * TAU * float(crack_index + 1) * 2.7
		var length: float = 8.0 + seed_val * 12.0
		var start := center + Vector2(cos(angle) * 3.0, sin(angle) * 1.5)
		var end := start + Vector2(cos(angle) * length, sin(angle) * length * 0.5)
		_owner.draw_line(start, end, crack_color, 1.0)

func _draw_lava_veins(palette: Dictionary, grid_count: int, tile_w: int, tile_h: int) -> void:
	var vein_color: Color = palette["edge_outer"]
	vein_color.a = 0.25
	var outer_start: int = int(grid_count * 0.65)
	for ix in range(-grid_count, grid_count + 1):
		for iy in range(-grid_count, grid_count + 1):
			var edge_dist := absi(ix) + absi(iy)
			if edge_dist < outer_start or edge_dist > grid_count:
				continue
			var hash_val: float = fmod(absf(sin(float(ix * 31 + iy * 97))), 1.0)
			if hash_val > 0.3:
				continue
			var sx: float = float(ix - iy) * (tile_w * 0.5)
			var sy: float = float(ix + iy) * (tile_h * 0.5)
			var hw: float = tile_w * 0.5
			var intensity: float = float(edge_dist - outer_start) / float(grid_count - outer_start)
			var segment_color: Color = vein_color
			segment_color.a = vein_color.a + intensity * 0.2
			_owner.draw_line(Vector2(sx, sy - tile_h * 0.5), Vector2(sx + hw, sy), segment_color, 1.5)

func _draw_floor_runes(palette: Dictionary, floor_theme: int) -> void:
	var accent: Color = palette["accent"]
	accent.a = 0.18
	var rune_radius: float = 180.0
	var segments: int = 24
	var circle_points := PackedVector2Array()
	for i in range(segments + 1):
		var angle: float = float(i) / float(segments) * TAU
		circle_points.append(Vector2(cos(angle) * rune_radius, sin(angle) * rune_radius * 0.5))
	_owner.draw_polyline(circle_points, accent, 1.5)

	if floor_theme == 2:
		var star_points: int = 6
		for i in range(star_points):
			var a1: float = float(i) / float(star_points) * TAU
			var a2: float = float(i + 2) / float(star_points) * TAU
			var radius: float = rune_radius * 0.7
			_owner.draw_line(
				Vector2(cos(a1) * radius, sin(a1) * radius * 0.5),
				Vector2(cos(a2) * radius, sin(a2) * radius * 0.5),
				accent, 1.0)
		return

	for ring in range(1, 3):
		var radius: float = rune_radius * (0.4 + ring * 0.15)
		var inner_points := PackedVector2Array()
		for i in range(segments + 1):
			var angle: float = float(i) / float(segments) * TAU
			inner_points.append(Vector2(cos(angle) * radius, sin(angle) * radius * 0.5))
		var ring_color := accent
		ring_color.a = 0.12
		_owner.draw_polyline(inner_points, ring_color, 1.0)

func _draw_edge_glow(palette: Dictionary, grid_count: int, tile_w: int) -> void:
	var glow_color: Color = palette["edge_outer"]
	glow_color.a = 0.10
	var base_radius: float = float(grid_count) * tile_w * 0.5
	var glow_extent: float = 120.0
	var seg_count: int = 28
	for i in range(seg_count):
		var a1: float = float(i) / float(seg_count) * TAU
		var a2: float = float(i + 1) / float(seg_count) * TAU
		var inner1 := Vector2(cos(a1) * base_radius, sin(a1) * base_radius * 0.5)
		var inner2 := Vector2(cos(a2) * base_radius, sin(a2) * base_radius * 0.5)
		var outer1 := Vector2(cos(a1) * (base_radius + glow_extent), sin(a1) * (base_radius + glow_extent) * 0.5)
		var outer2 := Vector2(cos(a2) * (base_radius + glow_extent), sin(a2) * (base_radius + glow_extent) * 0.5)
		var fade_color := Color(glow_color.r, glow_color.g, glow_color.b, 0.0)
		_owner.draw_polygon(PackedVector2Array([inner1, inner2, outer2]), PackedColorArray([glow_color, glow_color, fade_color]))
		_owner.draw_polygon(PackedVector2Array([inner1, outer2, outer1]), PackedColorArray([glow_color, fade_color, fade_color]))

func _draw_wall_silhouettes(palette: Dictionary, grid_count: int, floor_theme: int) -> void:
	var wall_color: Color = palette["void_color"].lightened(0.03)
	var seed_base: float = float(grid_count * 7 + floor_theme * 13)
	for i in range(7):
		var angle: float = fmod(seed_base + float(i) * 1.3, TAU)
		var dist: float = 1300.0 + fmod(absf(sin(seed_base + float(i) * 2.1)), 1.0) * 500.0
		var cx: float = cos(angle) * dist
		var cy: float = sin(angle) * dist * 0.5
		var width: float = 80.0 + fmod(absf(sin(float(i) * 3.7)), 1.0) * 200.0
		var height: float = 120.0 + fmod(absf(sin(float(i) * 5.3)), 1.0) * 180.0
		_owner.draw_rect(Rect2(cx - width * 0.5, cy - height, width, height), wall_color)

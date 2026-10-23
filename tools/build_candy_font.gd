extends SceneTree

# Coordinates are measured on the user's 2048-wide preview and scaled to source.
# Keep the supplied image untouched; only font metrics and UV regions are built.
func _initialize() -> void:
	var image := Image.load_from_file("res://assets/fonts/candy_v1/candy_sheet.png")
	var font := FontFile.new()
	font.font_name = "Kuih Empire Candy"
	font.fixed_size = 128
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_ENABLED
	font.modulate_color_glyphs = false
	font.fallbacks = [ThemeDB.fallback_font]
	font.set_texture_image(0, Vector2i(128, 0), 0, image)
	font.set_cache_ascent(0, 128, 112)
	font.set_cache_descent(0, 128, 20)
	var ratio := float(image.get_width()) / 2048.0
	var rows := [
		["ABCDEFGHIJKLM", 0, 130, [0,137,244,350,450,553,657,765,877,949,1060,1170,1273,1418]],
		["NOPQRSTUVWXYZ", 130, 254, [0,128,236,343,444,551,654,756,866,973,1090,1196,1305,1418]],
		["abcdefghijklm", 254, 388, [0,114,224,298,395,476,564,657,758,814,887,999,1069,1190]],
		["nopqrstuvwxyz", 388, 513, [0,114,215,309,399,475,566,648,745,846,972,1069,1168,1260]],
		["0123456789", 513, 660, [0,134,234,343,443,549,655,761,863,966,1090]],
		["!?.,:;", 0, 130, [1430,1509,1600,1656,1711,1768,1820]],
		["+-×÷=", 130, 223, [1448,1551,1632,1733,1827,1927]],
		["@#$%^&*", 223, 316, [1426,1531,1618,1698,1780,1842,1937,2025]],
		["()[]{}", 316, 430, [1430,1489,1569,1655,1743,1826,1908]],
		["<>/\\|~", 430, 516, [1424,1508,1577,1634,1707,1753,1847]],
	]
	for row in rows:
		var chars: String = row[0]
		for index in chars.length():
			var rect := Rect2i(roundi(row[3][index]*ratio), roundi(row[1]*ratio), roundi((row[3][index+1]-row[3][index])*ratio), roundi((row[2]-row[1])*ratio))
			var tight := Rect2i()
			var found := false
			for y in range(rect.position.y, mini(rect.end.y,image.get_height())):
				for x in range(rect.position.x, mini(rect.end.x,image.get_width())):
					if image.get_pixel(x,y).a > .25:
						if not found:
							tight = Rect2i(x,y,1,1)
							found = true
						else:
							tight = tight.expand(Vector2i(x,y))
			var code := chars.unicode_at(index)
			var scale_factor := 104.0 / (128.0*ratio)
			font.set_glyph_uv_rect(0, Vector2i(128,0), code, Rect2(tight))
			font.set_glyph_texture_idx(0, Vector2i(128,0), code, 0)
			font.set_glyph_size(0, Vector2i(128,0), code, Vector2(tight.size)*scale_factor)
			# Lowercase descenders extend below the common baseline.
			var descender := chars[index] in ["g","j","p","q","y"]
			var height := tight.size.y*scale_factor
			font.set_glyph_offset(0, Vector2i(128,0), code, Vector2(0,-height+(18 if descender else 0)))
			font.set_glyph_advance(0,128,code,Vector2(tight.size.x*scale_factor+5,0))
	font.set_glyph_advance(0,128,32,Vector2(36,0))
	var error := ResourceSaver.save(font,"res://assets/fonts/candy_v1/candy.tres")
	assert(error == OK)
	print("Candy font built: ", font.get_supported_chars())
	quit()

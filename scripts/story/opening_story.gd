class_name OpeningStory
extends RefCounted

static func pages() -> Array[StoryPage]:
	var headings_en := ["Kuching", "Family Stall", "The Recipe Book", "Aina Opens the Stall", "The Journey Begins"]
	var headings_ms := ["Kuching", "Gerai Keluarga", "Buku Resipi", "Aina Mula Berniaga", "Permulaan Perjalanan"]
	var bodies_en := [
		"Kuching, early morning.",
		"This family stall has served kuih for generations.",
		"Under the counter, Aina finds her grandmother’s old recipe book.",
		"With her family’s recipes and a heart full of hope, Aina starts selling kuih. One tray at a time, she brings the stall back to life.",
		"Family recipes. Our community. Sweeter together. This is where our Kuih Empire journey begins.",
	]
	var bodies_ms := [
		"Kuching, awal pagi.",
		"Gerai keluarga ini menyajikan kuih sejak turun-temurun.",
		"Di bawah kaunter, Aina menemui buku resipi lama milik neneknya.",
		"Berbekalkan resipi keluarga dan penuh harapan, Aina mula menjual kuih. Sedulang demi sedulang, dia menghidupkan semula gerai ini.",
		"Resipi keluarga. Komuniti kita. Lebih manis bersama. Di sinilah perjalanan Kuih Empire bermula.",
	]
	var crops := [Rect2(0, 0, 941, 1000), Rect2(74, 612, 793, 608), Rect2(86, 440, 770, 620), Rect2(76, 382, 792, 584), Rect2(0, 110, 941, 860)]
	var result: Array[StoryPage] = []
	for i in 5:
		var page := StoryPage.make(headings_en[i], StoryBeat.Speaker.AINA, [bodies_en[i]])
		page.heading_ms = headings_ms[i]
		page.lines_ms = PackedStringArray([bodies_ms[i]])
		page.illustration = load("res://assets/story/prologue_v1/story-%02d.png" % (i + 1))
		page.illustration_region = crops[i]
		if i == 0:
			page.illustration = load("res://assets/story/prologue_v1/kuching_dawn_v2.png")
			page.illustration_region = Rect2(Vector2.ZERO, page.illustration.get_size())
		page.greeting = i == 1
		if i == 3:
			page.quote = "One tray at a time, I’ll bring this stall back to life!"
			page.quote_ms = "Sedulang demi sedulang, gerai ini akan kembali meriah!"
			page.quote_rect = Rect2(.04, .025, .46, .29)
		elif i == 4:
			page.quote = "Let’s build our Kuih Empire!"
			page.quote_ms = "Jom bina Kuih Empire kita!"
			page.quote_rect = Rect2(.60, .31, .36, .23)
		result.append(page)
	return result

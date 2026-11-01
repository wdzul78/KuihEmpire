class_name OpeningStory
extends RefCounted

const SAD_MUSIC := "res://audio/music/story_opening_v1/sad.ogg"
const HOPE_MUSIC := "res://audio/music/story_opening_v1/hope.ogg"
const RECIPE_REVEAL_PANEL := 7
## Taller repainted panels, used per panel as soon as each one is imported.
const PANEL_ART := "res://assets/story/prologue_v3/panel_%02d.png"
## Sheet frames for the three opening panels until their paintings exist.
const OPENING_FALLBACK_FRAMES := [9, 1, 0]

static func music_for_panel(panel_index: int) -> String:
	return SAD_MUSIC if panel_index < RECIPE_REVEAL_PANEL else HOPE_MUSIC

## One illustration per phone screen. Dialogue stays in localized UI text.
const PANELS := [
	["The Village Stall", "Gerai di Hujung Kampung", "At the edge of a village stands a small kuih stall run by Aina's mother. Once, people queued here every morning.", "Di hujung sebuah kampung, ada gerai kuih kecil milik ibu Aina. Dulu, orang beratur di sini setiap pagi."],
	["Growing Quiet", "Semakin Sunyi", "Now there are fewer customers each day. Today, only a few people stopped by.", "Kini pelanggan semakin berkurang. Hari ini, hanya beberapa orang yang singgah."],
	["A Quiet Evening", "Petang yang Sunyi", "At dusk, Aina and her mother get ready to close the stall. They sit quietly, looking at trays still full of kuih.", "Menjelang senja, Aina dan ibu bersiap menutup gerai. Mereka duduk diam, memandang dulang kuih yang masih penuh."],
	["A Quiet Day", "Jualan Kurang", "Mother sighs as she counts the day's takings.\n\"We didn't sell much today…\"", "Ibu mengeluh sambil mengira hasil jualan.\n\"Tak banyak yang terjual hari ini…\""],
	["Mother Needs Rest", "Ibu Perlu Berehat", "Mother starts coughing. Aina gently supports her.\n\"Let's go home, Mum.\"", "Ibu mula batuk-batuk. Aina memapahnya perlahan.\n\"Ibu, mari kita balik.\""],
	["That Night", "Malam Itu", "Mother sleeps, unwell and exhausted. Aina watches over her.\n\"I want to help Mum…\"", "Ibu tidur dalam keadaan sakit dan keletihan. Aina menemaninya.\n\"Aina nak bantu ibu…\""],
	["An Unexpected Find", "Penemuan Tidak Disangka", "As Aina reaches for her mother's medicine, an old book tumbles from the shelf.", "Ketika Aina mengambil ubat untuk ibu, sebuah buku lama terjatuh dari rak."],
	["Grandmother's Recipes", "Resipi Nenek", "Aina opens the book, amazed by all the kuih recipes inside.\n\"Grandma's recipe book!\"", "Aina membuka buku itu, terkejut melihat pelbagai resipi kuih.\n\"Buku resipi nenek!\""],
	["For Mother", "Demi Ibu", "Aina clenches her fist, determined.\n\"I'll give it a try. For Mum!\"", "Aina menggenggam tangan dengan penuh tekad.\n\"Aina akan cuba. Demi ibu!\""],
	["Try Again", "Cuba Lagi", "The first batches don't turn out right. Aina studies the recipes and keeps trying through the night.", "Percubaan awal tidak menjadi. Aina meneliti resipi dan terus mencuba sepanjang malam."],
	["At Last!", "Akhirnya Menjadi!", "By dawn, trays of colourful kuih fill the counter. Tired but happy, Aina smiles at her work.", "Menjelang pagi, pelbagai kuih memenuhi dulang. Walaupun penat, Aina tersenyum puas melihat hasilnya."],
	["A New Morning", "Pagi Baharu", "Aina eagerly opens the stall. Pak Ya stops by.\n\"You're open early today, Aina!\"", "Aina bersemangat membuka gerai. Pak Ya datang menyapa.\n\"Awal Aina buka hari ini!\""],
	["Pak Ya's Order", "Pesanan Pak Ya", "\"Three onde-onde, please.\"\nAina happily serves Pak Ya her freshly made kuih.", "\"Bagi Pak Ya tiga onde-onde.\"\nAina gembira menghidangkan kuih yang baru dibuatnya."],
	["The First Smile", "Senyuman Pertama", "Pak Ya takes a bite, pleasantly surprised.\n\"Aina, these are delicious!\"\nAina beams. Her journey begins.", "Pak Ya merasa kuih itu, lalu tersenyum terkejut.\n\"Wah, sedapnya kuih Aina!\"\nAina tersenyum riang. Perjalanannya bermula."],
]

static func pages() -> Array[StoryPage]:
	var result: Array[StoryPage] = []
	for i in PANELS.size():
		var entry: Array = PANELS[i]
		var page := StoryPage.make(entry[0],StoryBeat.Speaker.NARRATOR,[entry[2]])
		page.heading_ms = entry[1]
		page.lines_ms = PackedStringArray([entry[3]])
		var painted := PANEL_ART % (i + 1)
		if ResourceLoader.exists(painted):
			page.illustration = load(painted)
			page.illustration_region = Rect2(Vector2.ZERO, page.illustration.get_size())
			result.append(page)
			continue
		var sheet_frame: int = OPENING_FALLBACK_FRAMES[i] if i < OPENING_FALLBACK_FRAMES.size() else i - OPENING_FALLBACK_FRAMES.size() + 1
		page.illustration = load("res://assets/story/prologue_v2/panels_%s.png" % ("a" if sheet_frame < 6 else "b"))
		var frame := sheet_frame%6
		var row := frame/2
		# Generated sheets have unequal row heights; crop the actual panel edges.
		var edges := [0.0,344.0,657.0,1024.0] if sheet_frame < 6 else [0.0,322.0,655.0,1024.0]
		page.illustration_region = Rect2(float(frame%2)*768.0+3.0,float(edges[row])+3.0,762.0,float(edges[row+1]-edges[row])-6.0)
		result.append(page)
	return result

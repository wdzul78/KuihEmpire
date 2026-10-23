class_name OpeningStory
extends RefCounted

const SAD_MUSIC := "res://audio/music/story_opening_v1/sad.ogg"
const HOPE_MUSIC := "res://audio/music/story_opening_v1/hope.ogg"
const RECIPE_REVEAL_PANEL := 5

static func music_for_panel(panel_index: int) -> String:
	return SAD_MUSIC if panel_index < RECIPE_REVEAL_PANEL else HOPE_MUSIC

## One illustration per phone screen. Dialogue stays in localized UI text.
const PANELS := [
	["A Quiet Evening", "Petang yang Sunyi", "At sunset, Aina and her mother close their quiet kuih stall. Many kuih are still unsold.", "Menjelang senja, Aina dan ibu menutup gerai yang sunyi. Banyak kuih masih belum terjual."],
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
		page.illustration = load("res://assets/story/prologue_v2/panels_%s.png" % ("a" if i < 6 else "b"))
		var frame := i%6
		var row := frame/2
		# Generated sheets have unequal row heights; crop the actual panel edges.
		var edges := [0.0,344.0,657.0,1024.0] if i < 6 else [0.0,322.0,655.0,1024.0]
		page.illustration_region = Rect2(float(frame%2)*768.0+3.0,float(edges[row])+3.0,762.0,float(edges[row+1]-edges[row])-6.0)
		result.append(page)
	return result

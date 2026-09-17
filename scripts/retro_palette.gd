extends RefCounted
## Shared cartridge-era colors for the 3D world. Keep alpha and near-neutral colors intact.
const COLORS := {
	"a8b4ae": "8296ab", "8dada8": "8296ab", "8fa3a0": "8296ab",
	"b5b7a0": "956448", "a9b6b1": "529b83", "c9b5a4": "d68b55",
	"bdc3b2": "88ad57", "c9c6ba": "e3b875", "d4c4ad": "bd8053",
	"d6c4a6": "dc9b63", "d6c7b7": "dc9b63", "d0bda3": "dc9b63",
	"d4bfa4": "dc9b63", "bfaa8b": "dc9b63", "b88759": "c58450",
	"ebc796": "f0c481", "f6e3bc": "ffe0a3", "344c59": "30354b",
	"239c96": "279c87", "df7661": "d95c49", "f6c75e": "ffd05a",
	"995f3d": "88482f", "b57d49": "b96638", "b77745": "b96638",
	"759daa": "329cc5", "668e9c": "329cc5", "788eae": "427fbd",
	"e99b9c": "e77a88", "d5a7b0": "d86c87", "67896b": "397945"
}

static func color(source: Color) -> Color:
	var result := source
	var key := source.to_html(false)
	if COLORS.has(key):
		result = Color(COLORS[key])
	elif source.s > 0.09 and source.s < 0.48:
		# Pull the remaining dusty pastels toward their own hue, preserving material identity.
		result = Color.from_hsv(source.h, minf(source.s * 1.3, 0.58), source.v)
	result.a = source.a
	return result

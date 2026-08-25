extends Interactable

@export var shop_id: String = ""

func _ready() -> void:
	match shop_id:
		"toserba":
			id = "kasir_toserba"
			prompt_text = "Kasir Toserba"
		"toko_buku":
			id = "kasir_toko_buku"
			prompt_text = "Kasir Toko Buku"
		"toko_furnitur":
			id = "kasir_toko_furnitur"
			prompt_text = "Kasir Toko Furnitur"
		_:
			id = "kasir_" + shop_id
			prompt_text = "Kasir"

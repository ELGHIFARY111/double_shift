extends Interactable

@export var npc_id: String = ""

func _ready():
	if npc_id != "":
		id = "npc_" + npc_id
		var npc_data = DataManager.get_npc(npc_id)
		prompt_text = npc_data.get("name", "NPC")
	else:
		id = "npc_unknown"
		prompt_text = "NPC"

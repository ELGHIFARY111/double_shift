extends Area2D

@export var object_name := "Object"

func interact(character):
	print(character.name + " berinteraksi dengan " + object_name)

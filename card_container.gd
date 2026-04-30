extends Control
@onready var texture_rect: TextureRect = $VBoxContainer/TextureRect
@onready var label: Label = $VBoxContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup(id: String, details: Dictionary) -> void:
	label.text = "ID: " + id
	label.text += "\nAttack: " + details.get("attack", 0)
	label.text += "\nDefense: " + details.get("deffence", 0)
	label.text += "\nSpeed: " + details.get("speed", 0)
	label.text += "\nStamina: " + details.get("stamina", 0)
	label.text += "\nMagic: " + details.get("magic", 0)

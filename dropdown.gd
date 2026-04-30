extends PanelContainer
class_name ChooseDropdown
@onready var label: Label = $VBoxContainer/Label
@onready var option_button: OptionButton = $VBoxContainer/OptionButton

signal OnSelected(value: String)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup(text: String, opts: Array):
	label.text = text
	option_button.clear()
	for acc in opts:
		option_button.add_item(acc)
	option_button.select(-1)
	option_button.item_selected.connect(on_selected)

func on_selected(index: int):
	OnSelected.emit(option_button.get_item_text(index))
	print(index)

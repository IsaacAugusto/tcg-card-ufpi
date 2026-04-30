extends Node2D

@onready var accounts_dropdown: OptionButton = $VBoxContainer/Accounts
@onready var tcg_contract: TCGContract = $TCGContract
const CARD_CONTAINER = preload("res://card_container.tscn")
@onready var card_scroll: HBoxContainer = $ScrollContainer/HBoxContainer

var accounts : Array[String] = [
	"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
	"0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
	"0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
	"0x90F79bf6EB2c4f870365E785982E1f101E93b906",
	"0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65"
]

var keys : Array[String] = [
	"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
	"0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
	"0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
	"0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6",
	"0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_dropdowns()

func setup_dropdowns():
	accounts_dropdown.clear()
	for acc in accounts:
		accounts_dropdown.add_item(acc)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func get_account_inventory():
	pass


func _on_get_cards_pressed() -> void:
	var addr = accounts_dropdown.get_item_text(accounts_dropdown.selected)
	var cards = tcg_contract.get_inventory(addr)[0]
	for card in cards:
		print("has value: " + card)
		var instance = CARD_CONTAINER.instantiate()
		card_scroll.add_child(instance)
		var stats = tcg_contract.get_card_stats(card.to_int())
		instance.setup(stats)

func _on_mint_card_pressed() -> void:
	var addr = accounts_dropdown.get_item_text(accounts_dropdown.selected)
	var key = keys[accounts_dropdown.selected]
	tcg_contract.mint_card(addr, "Teste", key)

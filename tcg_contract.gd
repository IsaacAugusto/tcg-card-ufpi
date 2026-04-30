extends Node
class_name TCGContract

var op: Optimism
var abi: ABIHelper
const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
const RPC_URL = "http://127.0.0.1:8545"

func _ready():
	op = Optimism.new()
	op.set_rpc_url(RPC_URL)
	
	abi = ABIHelper.new()
	var file = FileAccess.open("res://contract_abi.json", FileAccess.READ)
	abi.unmarshal_from_json(file.get_as_text())

func get_inventory(player_addr: String) -> Array:
	var packed = abi.pack("getPlayerCards", [player_addr])
	
	var call_msg = {
		"from": "0x0000000000000000000000000000000000000000",
		"to": CONTRACT_ADDRESS,
		"input": "0x" + packed.hex_encode(),
	}
	
	var rpc_response = op.call_contract(call_msg, "latest")
	
	if rpc_response.has("response_body"):
		var inner_json = JSON.parse_string(rpc_response["response_body"])
		if inner_json and inner_json.has("result"):
			var response_hex = inner_json["result"].replace("0x", "")
			
			var data_bytes = PackedByteArray()
			for i in range(0, response_hex.length(), 2):
				data_bytes.append(("0x" + response_hex.substr(i, 2)).hex_to_int())
			
			var inventory_list = []
			var err = abi.unpack_into_array("getPlayerCards", data_bytes, inventory_list)
			
			if err == OK:
				print("Player Inventory: ", inventory_list)
				return inventory_list
			else:
				print("Unpack Inventory Error: ", err)
	return []

func get_card_stats(token_id: int) -> Dictionary:
	var packed_data = abi.pack("getCardStats", [token_id])
	var call_msg = {
		"from": "0x0000000000000000000000000000000000000000",
		"to": CONTRACT_ADDRESS,
		"input": "0x" + packed_data.hex_encode()
	}

	var rpc_response = op.call_contract(call_msg, "latest")
	
	if rpc_response.has("response_body"):
		var inner_json = JSON.parse_string(rpc_response["response_body"])
		
		if inner_json and inner_json.has("result"):
			var response_hex = inner_json["result"].replace("0x", "")
			
			
			var data_bytes = PackedByteArray()
			for i in range(0, response_hex.length(), 2):
				data_bytes.append(("0x" + response_hex.substr(i, 2)).hex_to_int())
			
			var stats_result = {}
			
			var err = abi.unpack_into_dictionary("getCardStats", data_bytes, stats_result)
			
			if err == OK:
				print("--- CARD #%s STATS ---" % token_id)
				print("Attack: ", stats_result.get("attack", 0))
				print("Defense: ", stats_result.get("deffence", 0)) 
				print("Speed: ", stats_result.get("speed", 0))
				print("Stamina: ", stats_result.get("stamina", 0))
				print("Magic: ", stats_result.get("magic", 0))
				return stats_result
			else:
				print("Unpack Error code: ", err)
		else:
			print("RPC Error: No result in body.")
	else:
		print("Library Error: No response_body.")
	return {}

func mint_card(to_address: String, uri: String, private_key_hex: String):
	var clean_key = private_key_hex.replace("0x", "")
	var key_bytes = PackedByteArray()
	for i in range(0, clean_key.length(), 2):
		key_bytes.append(("0x" + clean_key.substr(i, 2)).hex_to_int())
	
	var account_manager = EthAccountManager.new()
	var account = account_manager.privateKeyToAccount(key_bytes)
	
	var block_tag = BigInt.new()
	block_tag.from_string("-2")
	
	var chain_id = BigInt.new()
	chain_id.from_string("31337")
	
	var val = BigInt.new()
	val.from_string("0")
	
	var tx = LegacyTx.new()
	tx.set_nonce(op.nonce_at(account.get_hex_address(), block_tag))
	tx.set_gas_price(op.suggest_gas_price())
	tx.set_gas_limit(500000) # Increased gas limit for safety
	tx.set_chain_id(chain_id)
	tx.set_value(val)
	tx.set_to_address(CONTRACT_ADDRESS)
	tx.set_data(abi.pack("safeMint", [to_address, uri]))
	
	tx.sign_tx_by_account(account)
	var tx_hash = op.send_transaction(tx.signedtx_marshal_binary())
	print("Transaction Sent! Hash: ", tx_hash)
	return tx_hash

func transfer_card(from_address: String, to_address: String, token_id: int, private_key_hex: String):
	var clean_key = private_key_hex.replace("0x", "")
	var key_bytes = PackedByteArray()
	for i in range(0, clean_key.length(), 2):
		key_bytes.append(("0x" + clean_key.substr(i, 2)).hex_to_int())
	
	var account_manager = EthAccountManager.new()
	var account = account_manager.privateKeyToAccount(key_bytes)
	
	var packed_data = abi.pack("safeTransferFrom", [from_address, to_address, token_id])
	
	var block_tag = BigInt.new()
	block_tag.from_string("-2")
	
	var chain_id = BigInt.new()
	chain_id.from_string("31337")
	
	var val = BigInt.new()
	val.from_string("0")
	
	var tx = LegacyTx.new()
	tx.set_nonce(op.nonce_at(account.get_hex_address(), block_tag))
	tx.set_gas_price(op.suggest_gas_price())
	tx.set_gas_limit(200000)
	tx.set_chain_id(chain_id)
	tx.set_value(val)
	tx.set_to_address(CONTRACT_ADDRESS)
	tx.set_data(packed_data)
	
	tx.sign_tx_by_account(account)
	var tx_hash = op.send_transaction(tx.signedtx_marshal_binary())
	
	print("Transferência enviada! Hash: ", tx_hash)
	return tx_hash

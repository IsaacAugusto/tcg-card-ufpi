extends Node
class_name TCGContract

var op: Optimism
var abi: ABIHelper
const CONTRACT_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3"
const RPC_URL = "http://127.0.0.1:8545"

func _ready():
	# 1. Instanciar e Configurar RPC
	op = Optimism.new()
	op.set_rpc_url(RPC_URL)
	
	# 2. Configurar ABI
	abi = ABIHelper.new()
	var file = FileAccess.open("res://contract_abi.json", FileAccess.READ)
	abi.unmarshal_from_json(file.get_as_text())
	#mint_card("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266", "Teste", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80")
	#get_inventory("0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266")
	#get_card_stats(1)

# --- GET INVENTORY (UPDATED WITH DOUBLE-PARSE) ---
func get_inventory(player_addr: String):
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
			
			# Convert hex result to PackedByteArray for unpacking
			var data_bytes = PackedByteArray()
			for i in range(0, response_hex.length(), 2):
				data_bytes.append(("0x" + response_hex.substr(i, 2)).hex_to_int())
			
			# Use unpack_into_array for functions returning lists (like uint256[])
			var inventory_list = []
			var err = abi.unpack_into_array("getPlayerCards", data_bytes, inventory_list)
			
			if err == OK:
				print("Player Inventory: ", inventory_list)
				return inventory_list
			else:
				print("Unpack Inventory Error: ", err)
	return []

func get_card_stats(token_id: int):
	# 1. Prepare the call message
	var packed_data = abi.pack("getCardStats", [token_id])
	var call_msg = {
		"from": "0x0000000000000000000000000000000000000000",
		"to": CONTRACT_ADDRESS,
		"input": "0x" + packed_data.hex_encode()
	}

	# 2. Call the contract
	var rpc_response = op.call_contract(call_msg, "latest")
	
	if rpc_response.has("response_body"):
		var inner_json = JSON.parse_string(rpc_response["response_body"])
		
		if inner_json and inner_json.has("result"):
			var response_hex = inner_json["result"].replace("0x", "")
			
			# --- THE FINAL FIX BASED ON YOUR API ---
			
			# A. Convert the hex result string back to a PackedByteArray
			var data_bytes = PackedByteArray()
			for i in range(0, response_hex.length(), 2):
				data_bytes.append(("0x" + response_hex.substr(i, 2)).hex_to_int())
			
			# B. Create an empty dictionary for the library to fill
			var stats_result = {}
			
			# C. Call the method (it returns an Error code, not the data)
			var err = abi.unpack_into_dictionary("getCardStats", data_bytes, stats_result)
			
			if err == OK:
				print("--- CARD #%s STATS ---" % token_id)
				# Ensure keys match your ABI (check for 'deffence' typo)
				print("Attack: ", stats_result.get("attack", 0))
				print("Defense: ", stats_result.get("deffence", 0)) 
				print("Speed: ", stats_result.get("speed", 0))
				print("Stamina: ", stats_result.get("stamina", 0))
				print("Magic: ", stats_result.get("magic", 0))
			else:
				print("Unpack Error code: ", err)
		else:
			print("RPC Error: No result in body.")
	else:
		print("Library Error: No response_body.")

# --- MINT CARD (CLEANED UP SIGNATURES) ---
func mint_card(to_address: String, uri: String, private_key_hex: String):
	# 1. Convert Key to Bytes
	var clean_key = private_key_hex.replace("0x", "")
	var key_bytes = PackedByteArray()
	for i in range(0, clean_key.length(), 2):
		key_bytes.append(("0x" + clean_key.substr(i, 2)).hex_to_int())
	
	var account_manager = EthAccountManager.new()
	var account = account_manager.privateKeyToAccount(key_bytes)
	
	# 2. Blockchain Params as BigInts
	var block_tag = BigInt.new()
	block_tag.from_string("-2") # "latest"
	
	var chain_id = BigInt.new()
	chain_id.from_string("31337") # Anvil/Hardhat default
	
	var val = BigInt.new()
	val.from_string("0") # 0 ETH
	
	# 3. Setup Transaction
	var tx = LegacyTx.new()
	tx.set_nonce(op.nonce_at(account.get_hex_address(), block_tag))
	tx.set_gas_price(op.suggest_gas_price())
	tx.set_gas_limit(500000) # Increased gas limit for safety
	tx.set_chain_id(chain_id)
	tx.set_value(val)
	tx.set_to_address(CONTRACT_ADDRESS)
	tx.set_data(abi.pack("safeMint", [to_address, uri]))
	
	# 4. Sign and Send
	tx.sign_tx_by_account(account)
	var tx_hash = op.send_transaction(tx.signedtx_marshal_binary())
	print("Transaction Sent! Hash: ", tx_hash)
	return tx_hash

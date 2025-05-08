extends Node3D

@onready var main_menu = $CanvasLayer/Menu
@onready var address_entry = $CanvasLayer/Menu/VBoxContainer/AddressEntry

const Player = preload("res://Scenes/character_body_3d.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_host_button_pressed():
	main_menu.hide()
	
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	
	add_player(multiplayer.get_unique_id())


	
func add_player(peer_id):
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)


func _on_join_button_pressed():
	main_menu.hide()
	
	enet_peer.create_client(address_entry.text, PORT)
	multiplayer.multiplayer_peer = enet_peer

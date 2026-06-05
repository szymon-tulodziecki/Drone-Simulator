extends Node

var udp := PacketPeerUDP.new()
@onready var drone = $"../Drone"

func _ready():
	udp.bind(8889)

func _process(_delta):
	if udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		var cmd = packet.get_string_from_utf8().strip_edges()
		print("CMD: ", cmd)
		
		if cmd == "command":
			_respond("ok")
			return
		
		drone.queue_command(cmd)
		_respond("ok")

func _respond(msg: String):
	udp.set_dest_address(udp.get_packet_ip(), udp.get_packet_port())
	udp.put_packet(msg.to_utf8_buffer())

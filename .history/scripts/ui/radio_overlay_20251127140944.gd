extends TextureButton

## Radio overlay that controls music pitch scaling and syncs throb animation with BPM

# Reference to the main script to access music player
var main_node: Node = null
var animation_player: AnimationPlayer = null

# Music pitch states
var pitch_enabled: bool = true
const NORMAL_PITCH: float = 1.5
const SLOW_PITCH: float = 1.0

# BPM-based animation speed
const BASE_BPM: float = 120.0  # Base BPM at normal pitch
const BASE_ANIMATION_SPEED: float = 1.0  # Animation speed at base BPM

func _ready() -> void:
	# Get reference to main node
	main_node = get_tree().current_scene
	
	# Get animation player
	animation_player = $AnimationPlayer
	
	# Connect button press signal
	pressed.connect(_on_radio_pressed)
	
	# Set initial animation speed based on current pitch
	_update_animation_speed()
	
	print("[RadioOverlay] Radio initialized with pitch_enabled=%s" % pitch_enabled)

func _on_radio_pressed() -> void:
	# Toggle pitch scaling
	pitch_enabled = not pitch_enabled
	
	# Get music player from main node
	if main_node and main_node.has_node("MusicPlayer"):
		var music_player = main_node.get_node("MusicPlayer")
		
		if pitch_enabled:
			music_player.pitch_scale = NORMAL_PITCH
			print("[RadioOverlay] Pitch scaling ENABLED (1.5x)")
		else:
			music_player.pitch_scale = SLOW_PITCH
			print("[RadioOverlay] Pitch scaling DISABLED (1.0x)")
		
		# Update animation speed to match new pitch
		_update_animation_speed()

func _update_animation_speed() -> void:
	if not animation_player:
		return
	
	# Calculate animation speed based on pitch
	# Higher pitch = faster BPM = faster throb
	var current_pitch = NORMAL_PITCH if pitch_enabled else SLOW_PITCH
	var speed_multiplier = current_pitch / SLOW_PITCH
	
	animation_player.speed_scale = BASE_ANIMATION_SPEED * speed_multiplier
	
	print("[RadioOverlay] Animation speed updated to: %.2f (pitch: %.1fx)" % [animation_player.speed_scale, current_pitch])

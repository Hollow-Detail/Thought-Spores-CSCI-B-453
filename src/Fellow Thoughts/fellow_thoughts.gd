# Class definition for FellowThoughts, which extends the CharacterBody2D class.
class_name FellowThoughts extends CharacterBody2D

# Exported variables allow for easy modification in the editor.
@export var speed := 300.0  # Speed at which the FellowThoughts moves.
@export var weight := 20.0  # Weight affects the smoothness of movement and scaling.
var direction: Vector2  # Direction the FellowThoughts is facing (for movement calculations).
var distance: float  # Distance to the target (Player).
var _player: Player = null  # Holds a reference to the Player object if the FellowThoughts is following the player.
var following: bool = false  # Boolean flag that checks if the FellowThoughts is following the player.

# This function is called every physics frame to update the FellowThoughts' movement.
func _physics_process(delta: float) -> void:
	# Clamps the scale of the character between 0.4 and 3.0 in both directions, ensuring it doesn't get too small or too large.
	global_scale = global_scale.clamp(Vector2(0.4, 0.4), Vector2(3, 3))
	
	# If no player is being followed, return the FellowThoughts to the origin position.
	if _player == null:
		$FellowSprite.core_position = lerp($FellowSprite.core_position, Vector2.ZERO, weight * delta)
		velocity = lerp(velocity, Vector2.ZERO, weight * delta)
	# Moves the FellowThoughts using the physics engine's move_and_slide method.
	move_and_slide()

# Triggered when a body enters the "follow" area.
func _on_follow_area_body_entered(body: Node2D) -> void:
	if body is Player:  # If the body entering the area is the Player...
		_player = body  # Store a reference to the player.
		$StateChart.send_event("body_entered")  # Send an event to the state machine.
	
	# If the merge area contains 5 or more bodies, trigger a merge event.
	if $MergeArea.get_overlapping_bodies().size() >= 5:
		$StateChart.send_event("merge")

# Triggered when a body exits the "follow" area.
func _on_follow_area_body_exited(body: Node2D) -> void:
	if body is Player:  # If the body exiting the area is the Player...
		_player = null  # Remove the reference to the player.
		$StateChart.send_event("body_exited")  # Send an event to the state machine.

# Called when the FellowThoughts enters the idle state.
func _on_idle_state_entered() -> void:
	$AnimationPlayer.play("idle")  # Play the "idle" animation.

# Called when the FellowThoughts enters the following state.
func _on_following_state_entered() -> void:
	following = true  # Set the "following" flag to true.

# This function is called during the physics process while in the following state.
func _on_following_state_physics_processing(delta: float) -> void:
	if not _player == null:  # If there is a player to follow...
		direction = global_position.direction_to(_player.global_position)  # Get the direction to the player.
		distance = global_position.distance_to(_player.global_position)  # Get the distance to the player.
		
		# Adjust the speed based on the distance to the player.
		speed = 300.0 if distance > 250.0 else 150.0
		
		# Move the FellowThoughts toward the player.
		$FellowSprite.core_position = lerp($FellowSprite.core_position, $FellowSprite.shift_core_position, weight * delta)
		rotation = lerp_angle(rotation, direction.orthogonal().angle(), weight * delta)  # Smoothly rotate to face the direction.
		velocity = lerp(velocity, speed * direction, weight * delta)  # Adjust the movement velocity.
		
	move_and_slide()  # Apply the movement.

# Called when the FellowThoughts enters the merging state.
func _on_merging_state_entered() -> void:
	
	# Wait for 1.4 seconds before starting the merging process.
	await get_tree().create_timer(1.4).timeout
	var BodiesArray: Array = $MergeArea.get_overlapping_bodies()  # Get all bodies in the merge area.
	var random_body = BodiesArray.pick_random()  # Pick a random body in the merge area.
	var body_freed := 0  # Counter to track the freed bodies during the merge.

	# Find a FellowThoughts object within the merge area.
	while random_body is not FellowThoughts:
		random_body = BodiesArray.pick_random()

	# Iterate through all the bodies in the merge area.
	for bodies in $MergeArea.get_overlapping_bodies():
		if bodies == random_body:  # If the body matches the random body...
			bodies.global_scale += Vector2(0.4, 0.4)  # Increase the body’s size.
			bodies.self_modulate += Color(0.2, 0.2, 0.2)  # Slightly modulate the color for effect.
		elif bodies is FellowThoughts and body_freed < 1:  # If it’s another FellowThoughts and one body has not been freed...
			#%SplitAudio.play()  # Uncomment this line if you want to play a sound when the body splits.
			body_freed += 1  # Increment the counter.
			bodies.queue_free()  # Remove the FellowThoughts from the scene.
	
	%MergeAuio.play()  # Play the merging sound/audio effect.
	$StateChart.send_event("to_idle")  # Transition to the idle state.

# Called when the FellowThoughts exits the following state.
func _on_following_state_exited() -> void:
	following = false  # Set the "following" flag to false.

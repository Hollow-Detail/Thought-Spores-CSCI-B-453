class_name Player extends CharacterBody2D

@export var speed := 500.0
@export var weight := 20.0
var direction: Vector2
var merge_allowed: bool = false

# slingshot-related variables
var slingshot_active := false
var slingshot_duration := 1.0  # Duration for slingshot effect (in seconds)
var slingshot_timer := 0.0


# Repel-related variables
var repel_active := false
var repel_range := 10.0
var repel_duration := 1.0  # Duration the repel effect lasts
var repel_timer := 0.0
var repel_force := 500.0  # Force applied to repelling FellowThoughts

# size reduction related variables
var size_decrease_rate := 0.05  
var min_size := 0.2  

const FELLOW_THOUGHTS = preload("res://Fellow Thoughts/fellow_thoughts.tscn")

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Handle slow time activation/deactivation
	if repel_active:
		global_scale = global_scale.lerp(Vector2(min_size, min_size), size_decrease_rate * delta)
		apply_repel_force()
		
	if slingshot_active:
		delta *= 0.5  # Slow down the game time (can adjust this value)
		slingshot_timer -= delta
		
		# Shrink player size gradually (can adjust the rate of shrinking)
		global_scale = global_scale.lerp(Vector2(min_size, min_size), size_decrease_rate * delta)
		
		# Check if the slingshot effect duration has ended
		if slingshot_timer <= 0.0:
			deactivate_slingshot()

	# Normal movement logic
	global_scale = global_scale.clamp(Vector2(0.2, 0.2), Vector2(4, 4))
	
	direction = Input.get_vector("left", "right", "up", "down").normalized()
	if direction.length() > 0.0:
		$PlayerSprite.core_position = lerp($PlayerSprite.core_position, $PlayerSprite.shift_core_position, weight * delta)
		rotation = lerp_angle(rotation, direction.orthogonal().angle(), weight * delta)
		velocity = lerp(velocity, velocity/2 + (speed * direction), weight * delta)
	elif direction.length() == 0.0:
		$PlayerSprite.core_position = lerp($PlayerSprite.core_position, Vector2(-4.0, 4.0), weight * delta)
		velocity = lerp(velocity, velocity * 2.4, weight * delta)
		velocity = lerp(velocity, Vector2.ZERO, weight * delta)
	move_and_slide()
	
	
	if Input.is_action_just_pressed("slingshot") and slingshot_timer <= 0.0:
		activate_slingshot()

	if Input.is_action_just_released("slingshot") && self.global_scale > Vector2(0.3, 0.3):
		$StateChart.send_event("to_split_dash")
		
	# Repel Button press logic
	if Input.is_action_pressed("repel") and repel_timer <= 10.0:
		activate_repel()

	if Input.is_action_just_released("repel") and self.global_scale > Vector2(0.3, 0.3):
		deactivate_repel()

#sling shot switches
func activate_slingshot() -> void:
	slingshot_active = true
	slingshot_timer = slingshot_duration  

func deactivate_slingshot() -> void:
	slingshot_active = false
	slingshot_timer = 0.0  

func activate_repel() -> void:

	repel_active = true
	repel_timer = repel_duration  

func deactivate_repel() -> void:
	repel_active = false
	repel_timer = 0.0  
	
	
#Apply repelling force to fellow thoughts 
# Puts the fellow thoughts 
func apply_repel_force() -> void:
	print(get_tree().get_nodes_in_group("fellow_thoughts").size())
	for body in get_tree().get_nodes_in_group("fellow_thoughts"): 
		if body is FellowThoughts:
			var distance_to_body = global_position.distance_to(body.global_position)
			if distance_to_body < repel_range > 0:
				var direction_to_body = (body.global_position - global_position).normalized()
				body.apply_force(direction_to_body * repel_force * -1)


func _on_idle_state_entered() -> void:
	$AnimationPlayer.play("Idle")

func _on_hit_box_area_body_entered(body: Node2D) -> void:
	%HitAudio.play()
	await get_tree().create_timer(0.4).timeout
	
	if is_instance_valid(body) && body is AttackingThoughts:
		for seperation in 2:
			var new_fellow_thoughts := FELLOW_THOUGHTS.instantiate()
			new_fellow_thoughts.global_scale = self.global_scale - Vector2(0.3, 0.3)
			new_fellow_thoughts.global_position = self.global_position
			get_parent().call_deferred("add_child", new_fellow_thoughts)
			%SplitAudio.play()
			body.global_scale += Vector2(0.1, 0.1)
		self.global_scale -= Vector2(0.3, 0.3)

func _on_merge_area_body_entered(body: Node2D) -> void:
	if body is AttackingThoughts:
		$AnimationPlayer.play("blue_jitter_in")
	elif body is FellowThoughts:
		$AnimationPlayer.play("white_jitter_out")

	if body is FellowThoughts and global_scale < Vector2(0.9, 0.9) and $MergeArea.get_overlapping_bodies().size() >= 3:
		$StateChart.send_event("merge")
	elif body is FellowThoughts and global_scale < Vector2(3.0, 3.0) and global_scale > Vector2(1.0, 1.0) and $MergeArea.get_overlapping_bodies().size() >= 4:
		$StateChart.send_event("merge")
	elif body is FellowThoughts and global_scale > Vector2(3.0, 3.0) and $MergeArea.get_overlapping_bodies().size() > 4:
		$StateChart.send_event("merge")

func _on_merge_area_body_exited(_body: Node2D) -> void:
		$AnimationPlayer.stop()
		$AnimationPlayer.play("Idle")

func _on_merging_state_entered() -> void:
	$AnimationPlayer.play("red_jitter_out")
	await get_tree().create_timer(0.5).timeout
	for bodies in $MergeArea.get_overlapping_bodies():
		if bodies is FellowThoughts:
			bodies.call_deferred("queue_free")
			bodies = null
			self.global_scale += Vector2(0.1, 0.1)
		%MergeAudio.play()
	$AnimationPlayer.stop()
	#idle_event
	$StateChart.send_event("to_idle")

func _on_split_dash_state_entered() -> void:
	var new_fellow_thoughts := FELLOW_THOUGHTS.instantiate()
	new_fellow_thoughts.global_scale = self.global_scale - Vector2(0.5, 0.5)
	new_fellow_thoughts.global_position = self.global_position
	self.global_scale -= Vector2(0.15, 0.15)
	get_parent().call_deferred("add_child", new_fellow_thoughts)

	%SplitAudio.play()

	var tween := create_tween()
	tween.set_parallel()
	tween.tween_property(self, "global_position", global_position + (Vector2(600.0, 600.0) * direction), 0.3)

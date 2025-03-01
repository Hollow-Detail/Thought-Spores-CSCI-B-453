# The following code is for a custom 2D Sprite node that draws circles representing a core and an outer area.
@tool
extends Sprite2D  # This script extends the Sprite2D class, allowing it to handle drawing operations and other sprite behaviors in 2D.

# Exported variables allow for easy editing in the Godot editor.
@export var outer_radius := 20.0  # The radius of the outer circle.
@export var core_radius := 4.0    # The radius of the core circle.
@export var width := 0.4          # The width of the outer circle's border.
@export var outer_color := Color.RED  # The color of the outer circle.
@export var core_color := Color.PURPLE  # The color of the core circle.
@export var overlay_color := Color.RED  # The color of the overlay for the outer circle (with transparency).
@export var core_position: Vector2 = Vector2.ZERO  # Position of the core circle relative to the Sprite2D node.
@export var shift_core_position: Vector2  # The shifted position used for some movement/offset logic.

# Called when the node enters the scene tree for the first time (e.g., when the scene is loaded).
func _ready() -> void:
	# Checks if the game is running in the editor (this prevents certain code from running in the editor, only in the game).
	if Engine.is_editor_hint():
		return
	
	# Sets the core's position shift when the node is ready (e.g., when the scene starts).
	shift_core_position = Vector2(0.0, outer_radius / 2.0)  # The core is positioned halfway up from the center of the outer circle.

# Called every frame. The 'delta' is the elapsed time since the previous frame, but it's not used here.
func _process(_delta: float) -> void:
	# Schedules a redraw of the sprite every frame to update its visual representation.
	queue_redraw()

# The _draw function is used to perform custom drawing for this sprite.
func _draw() -> void:
	# Draws the outer circle with transparency (overlay color), using the 'outer_radius' and a transparency value of 0.3.
	draw_circle(Vector2.ZERO, outer_radius, Color(overlay_color, 0.3), true, -1, true)
	
	# Draws the border of the outer circle with the defined color and width.
	draw_circle(Vector2.ZERO, outer_radius, outer_color, false, width, true)
	
	# Draws the core circle in the center, using the specified 'core_position' and 'core_radius'.
	draw_circle(core_position, core_radius, core_color, true, -1, true)

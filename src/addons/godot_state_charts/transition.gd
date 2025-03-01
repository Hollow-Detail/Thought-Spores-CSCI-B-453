@tool
@icon("transition.svg")
class_name Transition
extends Node

const ExpressionUtil = preload("expression_util.gd")
const DebugUtil = preload("debug_util.gd")

signal taken()

# Target state to which the transition will move
@export_node_path("StateChartState") var to: NodePath:
	set(value):
		to = value
		

# Event trigger
@export var event: StringName = "":
	set(value):
		event = value
		

# Guard condition that must evaluate as true for the transition to occur
@export var guard: Guard:
	set(value):
		guard = value
		

# Transition delay in seconds, can be set to zero for immediate transition
var delay_seconds: float = 0.0:
	set(value):
		delay_in_seconds = str(value)
	get:
		return float(delay_in_seconds) if delay_in_seconds.is_valid_float() else 0.0

# Expression-based delay for transition, evaluated at runtime. Returns 0 if invalid
var delay_in_seconds: String = "0.0":
	set(value):
		delay_in_seconds = value



var has_event: bool:
	get:
		return event.length() > 0

# Executes the transition, immediately or after delay (if specified)
func take(immediately: bool = true) -> void:
	var parent_state: Node = get_parent()
	if !parent_state or !(parent_state is StateChartState):
		push_error("Transition must be a child of a state.")
		return
	parent_state._run_transition(self, immediately)

# Evaluates whether the guard condition passes
func evaluate_guard() -> bool:
	if guard == null:
		return true
	
	var parent_state: Node = get_parent()
	if !parent_state or !(parent_state is StateChartState):
		push_error("Transition must be a child of a state.")
		return false
	
	return guard.is_satisfied(self, parent_state)

# Evaluates the delay expression for the transition
func evaluate_delay() -> float:
	var parent_state: Node = get_parent()
	if !parent_state or !(parent_state is StateChartState):
		push_error("Transition must be a child of a state.")
		return 0.0

	# Evaluate the delay expression dynamically
	var result = ExpressionUtil.evaluate_expression("delay of " + DebugUtil.path_of(self), parent_state._chart, delay_in_seconds, 0.0)
	if typeof(result) != TYPE_FLOAT:
		push_error("Invalid delay expression result: ", result, " Returning 0.0.")
		return 0.0

	return result

# Resolves and returns the target state if found, else returns null
func resolve_target() -> StateChartState:
	if to == null or to.is_empty():
		return null
	
	var target_state: Node = get_node_or_null(to)
	if target_state is StateChartState:
		return target_state
	
	return null

# Generates configuration warnings for missing or invalid properties



		

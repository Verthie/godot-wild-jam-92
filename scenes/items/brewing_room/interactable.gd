extends Node3D
class_name Interactable

@onready var object_area: Area3D = $ObjectArea

@export var tag: String = "seed"
@export var capacity: int = 0
@export var holder_node: Node3D = null
@export_enum("Ingredient", "Brewing Stand", "Lever", "Log", "Bowl", "Trash Can", "Sampler") var type: int = 0

var node_array: Array[Node3D] = []

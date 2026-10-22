extends Node
## Bootstraps FlowTest as a root sibling so scene changes don't delete it.

func _ready() -> void:
	var runner := Node.new()
	runner.name = "FlowRunner"
	runner.set_script(load("res://tests/FlowTest.gd"))
	get_tree().root.add_child.call_deferred(runner)

@tool
extends EditorPlugin

func _enter_tree():
	# 插件被启用时调用
	print("RotatableRigidBody plugin enabled")

func _exit_tree():
	# 插件被禁用时调用
	print("RotatableRigidBody plugin disabled")
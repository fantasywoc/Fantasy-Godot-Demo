extends Node
@onready var rotatable_rigid_body: RotatableRigidBody = $W1/RotatableRigidBody
@onready var gear_collision_polygon: GearCollisionPolygon = $RotatableRigidBody/GearCollisionPolygon

# 输入点数组
var points = [
	Vector2(1, 2), 
	Vector2(3, 4), 
	Vector2(5, 6)
]

func _ready() -> void:
	
	
	if ClassDB.class_exists("RotatableRigidBody"):
		print("RotatableRigidBody 插件已正确安装")

	
	else:
		print("RotatableRigidBodyv 未找到，请确保插件已正确安装")
	gear_collision_polygon.show()
		
		

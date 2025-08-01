
extends Node2D

@onready var rotatable_rigid_body: RotatableRigidBody = $RotatableRigidBody
@onready var collision_polygon_2d: CollisionPolygon2D = $RotatableRigidBody/CollisionPolygon2D


@export var GearScale:float = 1
@export var RotationSpeed:float = 1
@export var ClokWise:bool= false 
@export var AutoRoate = false

func _ready() -> void:
	collision_polygon_2d.scale =Vector2(1,1)* GearScale
	rotatable_rigid_body.auto_rotate = AutoRoate
	rotatable_rigid_body.clockwise = ClokWise
	rotatable_rigid_body.rotation_speed = RotationSpeed

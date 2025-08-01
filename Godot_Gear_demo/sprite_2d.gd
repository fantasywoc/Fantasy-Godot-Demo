extends Sprite2D

@export var border_color: Color = Color(1, 0, 0)       # 边框颜色（红色）
@export var border_width: float = 4.0                 # 边框宽度
@export var inner_color: Color = Color(0, 1, 0, 0.5)  # 内部线条颜色（半透明绿色）
@export var inner_line_width: float = 3.0             # 内部线条宽度
@export var inner_noise_scale: float = 0.1            # 内部线条紊乱程度
@export var inner_point_count: int = 150               # 内部线条点数
@export var inner_border_scale: float = 0.5           # 内边框缩放比例 (0-1)
@export var inner_border_color: Color = Color(0, 0, 1, 0.7) # 内边框颜色 (蓝色)
@export var inner_border_width: float = 100.0            # 内边框宽度

var polygon_points: PackedVector2Array = []
var border_line: Line2D
var inner_line: Line2D  # 用于内部紊乱线条
var inner_border_line: Line2D  # 内边框线条
var last_parent_transform: Transform2D = Transform2D.IDENTITY
var random_points: PackedVector2Array = []

func _ready():
	# 确保父节点是 CollisionPolygon2D
	if not get_parent() is CollisionPolygon2D:
		push_error("Parent node must be a CollisionPolygon2D")
		return
	
	# 创建外边框线条
	border_line = Line2D.new()
	border_line.width = border_width
	border_line.default_color = border_color
	border_line.closed = true
	add_child(border_line)
	
	# 创建内部紊乱线条
	inner_line = Line2D.new()
	inner_line.width = inner_line_width
	inner_line.default_color = inner_color
	inner_line.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(inner_line)
	
	# 创建内边框线条
	inner_border_line = Line2D.new()
	inner_border_line.width = inner_border_width
	inner_border_line.default_color = inner_border_color
	inner_border_line.closed = true
	add_child(inner_border_line)
	
	# 记录初始变换
	last_parent_transform = get_parent().transform
	
	# 获取多边形点
	update_polygon()
	
	# 生成内部随机点
	generate_inner_random_points()
	
	# 监听多边形变化
	if get_parent().has_signal("polygon_changed"):
		get_parent().connect("polygon_changed", Callable(self, "_on_polygon_changed"))

func _process(_delta):
	# 检查父节点变换是否变化
	if get_parent().transform != last_parent_transform:
		update_polygon()
		last_parent_transform = get_parent().transform
	
	# 更新内部随机线条的显示
	update_inner_line()

func _on_polygon_changed():
	update_polygon()
	generate_inner_random_points()

func update_polygon():
	# 获取父节点的多边形点
	var parent = get_parent() as CollisionPolygon2D
	polygon_points = parent.polygon
	
	# 如果没有点，使用默认矩形
	if polygon_points.size() == 0:
		polygon_points = PackedVector2Array([
			Vector2(-50, -50),
			Vector2(50, -50),
			Vector2(50, 50),
			Vector2(-50, 50)
		])
	
	# 应用父节点变换
	var transformed_points = apply_parent_transform(polygon_points)
	
	# 更新外边框线条的点
	border_line.points = transformed_points
	
	# 生成内边框点并更新显示
	var inner_border_points = generate_scaled_polygon(polygon_points, inner_border_scale)
	var transformed_inner_border_points = apply_parent_transform(inner_border_points)
	inner_border_line.points = transformed_inner_border_points
	
	# 重新生成内部随机点
	generate_inner_random_points()

# 在多边形内部生成随机点阵
func generate_inner_random_points():
	random_points.clear()
	
	if polygon_points.size() < 3:
		return
	
	# 在多边形内部生成随机点
	var random = RandomNumberGenerator.new()
	random.randomize()
	
	var center = calculate_centroid(polygon_points)
	var max_distance = 0.0
	
	# 找到距离中心最远的点作为半径上限
	for point in polygon_points:
		max_distance = max(max_distance, center.distance_to(point))
	
	# 生成内部随机点
	for i in range(inner_point_count):
		# 生成在中心附近的点
		var angle = random.randf_range(0, 2 * PI)
		var distance = random.randf_range(0, max_distance * 0.8)  # 避免太靠近边缘
		
		var point = center + Vector2(cos(angle), sin(angle)) * distance
		
		# 应用随机噪声偏移
		if inner_noise_scale > 0:
			var noise_offset = Vector2(
				random.randfn(0, inner_noise_scale),
				random.randfn(0, inner_noise_scale)
			) * max_distance
			
			point += noise_offset
		
		# 确保点位于多边形内部
		if is_point_in_polygon(point, polygon_points):
			random_points.append(point)

# 更新内部紊乱线条
func update_inner_line():
	if random_points.size() < 2:
		inner_line.points = PackedVector2Array()
		return
	
	# 应用父节点变换到随机点
	var transformed_points = apply_parent_transform(random_points)
	inner_line.points = transformed_points

# 计算多边形重心
func calculate_centroid(points: PackedVector2Array) -> Vector2:
	var centroid = Vector2(0, 0)
	var signed_area = 0.0
	
	for i in range(points.size()):
		var x1 = points[i].x
		var y1 = points[i].y
		var x2 = points[(i + 1) % points.size()].x
		var y2 = points[(i + 1) % points.size()].y
		
		var a = x1 * y2 - x2 * y1
		signed_area += a
		centroid.x += (x1 + x2) * a
		centroid.y += (y1 + y2) * a
	
	signed_area *= 0.5
	centroid.x /= (6.0 * signed_area)
	centroid.y /= (6.0 * signed_area)
	
	return centroid

# 判断点是否在多边形内部
func is_point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var count = 0
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		# 检查点是否在边的同一侧
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) and \
		   (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / \
		   (polygon[j].y - polygon[i].y) + polygon[i].x):
			count += 1
		j = i
	
	return count % 2 == 1

# 正确应用父节点变换，将点转换到当前节点的坐标空间
func apply_parent_transform(points: PackedVector2Array) -> PackedVector2Array:
	var transformed_points = PackedVector2Array()
	var parent = get_parent()
	
	for point in points:
		# 将点从父节点的本地坐标转换到当前节点的坐标空间
		transformed_points.append(to_local(parent.to_global(point)))
	
	return transformed_points

# ========== 新增功能: 生成缩放多边形 ========== #
func generate_scaled_polygon(original_points: PackedVector2Array, scale_factor: float) -> PackedVector2Array:
	# 如果缩放比例为1，直接返回原始点
	if abs(scale_factor - 1.0) < 0.001:
		return original_points.duplicate()
	
	var scaled_points = PackedVector2Array()
	var center = calculate_centroid(original_points)
	
	# 计算每个顶点相对于中心点的缩放
	for point in original_points:
		# 计算点到中心的向量
		var vector_from_center = point - center
		
		# 缩放该向量
		var scaled_vector = vector_from_center * scale_factor
		
		# 创建新点
		var scaled_point = center + scaled_vector
		scaled_points.append(scaled_point)
	
	return scaled_points

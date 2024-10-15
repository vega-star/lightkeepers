class_name OffensiveTower extends Tower

var firing_cooldown : float: set = _set_firing_cooldown

@onready var tower_gun_muzzle : Marker2D = $TowerGunSprite/TowerGunMuzzle
@onready var tower_aim : RayCast2D = $TowerGunSprite/TowerGunMuzzle/TowerAim
@onready var tower_sprite : Sprite2D = $TowerSprite
@onready var tower_gun_sprite : AnimatedSprite2D = $TowerGunSprite
@onready var firing_cooldown_timer : Timer = $StateMachine/Firing/FiringCooldown

func _set_firing_cooldown(new_cooldown : float): firing_cooldown = new_cooldown; firing_cooldown_timer.wait_time = new_cooldown

func _load_properties() -> void:
	light_shape.size = light_range
	tower_range_shape.shape.radius = DEFAULT_RANGE * tower_range
	tower_aim.target_position.x = DEFAULT_RANGE * tower_range
	tower_updated.emit()

func _load_default_values() -> void:
	tower_value = default_tower_cost
	target_priority = default_target_priority
	piercing = default_piercing
	burst = default_burst
	projectile_quantity = default_projectile_quantity
	firing_cooldown = default_firing_cooldown; firing_cooldown_timer.wait_time = firing_cooldown
	if tower_gun_sprite.visible: tower_sprite.visible = false
	tower_updated.emit()

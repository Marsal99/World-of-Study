extends Pawn


#warning-ignore:unused_class_variable
@export var combat_actor: PackedScene
#warning-ignore:unused_class_variable
var lost = false
var grid_size
var can_move := true

@onready var parent = get_parent()
@onready var animation_playback = $AnimationTree.get("parameters/playback")
@onready var walk_animation_time = $AnimationPlayer.get_animation("walk").length


func _ready():
    update_look_direction(Vector2.RIGHT)
    grid_size = parent.tile_set.tile_size.x


func _process(_delta):
    if not can_move:
        return
    var input_direction = get_input_direction()
    if input_direction.is_zero_approx():
        return
    update_look_direction(input_direction)

    var target_position = parent.request_move(self, input_direction)
    if target_position:
        move_to(target_position)
    elif active:
        bump()


func get_input_direction():
    return Vector2(
        Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
        Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
    )


func update_look_direction(direction):
    $Pivot/Sprite2D.rotation = direction.angle()


func move_to(target_position):
    set_process(false)
    var move_direction = (target_position - position).normalized()
    animation_playback.start("walk")

    var tween := create_tween()
    tween.set_ease(Tween.EASE_IN)
    var end = $Pivot.position + move_direction * grid_size
    tween.tween_property($Pivot, "position", end, walk_animation_time)

    await tween.finished
    $Pivot.position = Vector2.ZERO
    position = target_position
    animation_playback.start("idle")

    set_process(true)

func bump():
    set_process(false)
    animation_playback.start("bump")
    await $AnimationTree.animation_finished
    animation_playback.start("idle")
    set_process(true)

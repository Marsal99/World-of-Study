extends Node

signal dead
signal health_changed(life)

@export var life = 0
@export var max_life = 10
@export var base_armor = 0
var armor = 0


func _ready():
    armor = base_armor


func take_damage(damage):
    life = life - damage + armor
    if life <= 0:
        dead.emit()
    else:
        health_changed.emit(life)


func heal(amount):
    life += amount
    life = clamp(life, life, max_life)
    health_changed.emit(life)


func get_health_ratio():
    return life / max_life

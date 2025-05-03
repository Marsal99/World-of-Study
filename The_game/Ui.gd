extends Control


@export var combatants_node: Node
@export var info_scene: PackedScene


func initialize():
    for combatant in combatants_node.get_children():
        var health = combatant.get_node("Health")
        var info = info_scene.instantiate()
        var health_info = info.get_node("VBoxContainer/HealthContainer/Health")
        health_info.value = health.life
        health_info.max_value = health.max_life
        info.get_node("VBoxContainer/NameContainer/Name").text = combatant.name
        health.health_changed.connect(health_info.set_value)
        $Combatants.add_child(info)
    $Buttons/GridContainer/Attack.grab_focus()

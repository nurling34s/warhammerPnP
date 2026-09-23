## One pending point of damage flowing from a failed save into
## RulesetProvider.allocate_wounds(). `mortal` flags damage that bypasses
## saves entirely (e.g. a future "mortal wound" special rule) — unused for
## now, added so allocate_wounds' shape doesn't need to change later.
class_name DamageEvent
extends RefCounted

var source_weapon: WeaponProfile
var mortal: bool = false


func _init(weapon: WeaponProfile, is_mortal: bool = false) -> void:
	source_weapon = weapon
	mortal = is_mortal

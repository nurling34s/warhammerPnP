## Warhammer 40,000 11th-edition-specific unit fields on top of the shared
## UnitStats. Exact numeric conventions for a given codex should be checked
## against the current core rulebook before real army data is entered.
class_name FortyKUnitStats
extends UnitStats

@export var toughness: int = 4
@export var leadership: int = 6                  ## raw value (edition convention interprets as "X+" or bonus)
@export var weapon_skill: int = 3
@export var ballistic_skill: int = 3
@export var invulnerable_save: int = 0           ## 0 = none, else e.g. 5 means "5++"
@export var objective_control: int = 1
@export var faction_abilities: Array[StringName] = []

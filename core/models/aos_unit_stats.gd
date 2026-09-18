## Age of Sigmar 4th-edition-specific unit fields on top of the shared UnitStats.
class_name AoSUnitStats
extends UnitStats

@export var bravery: int = 6
@export var control_score: int = 1              ## objective control contribution (AoS4)
@export var rend_default: int = 0                ## baseline Rend if not carried per-weapon
@export var ward_save: int = 0                   ## 0 = no ward; else X means "X+ ward" (an ability, not guaranteed)
@export var battle_traits: Array[StringName] = []

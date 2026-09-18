## Immutable, shared unit definition (a Godot Resource, cached/shared by the
## engine). Fields here are common to both rulesets; AoSUnitStats/FortyKUnitStats
## add their own ruleset-specific fields on top.
##
## `health_per_model` is the shared name for "how much damage one model can
## take before it dies" — AoS4 calls this Health, 40k 11th ed calls it Wounds.
class_name UnitStats
extends Resource

@export var unit_id: StringName = &""          ## e.g. &"aos.stormcast.liberators"
@export var display_name: String = ""
@export var faction: StringName = &""
@export var keywords: Array[StringName] = []
@export var models_per_unit: int = 1
@export var move_inches: float = 5.0
@export var health_per_model: int = 1
@export var save: int = 4                        ## e.g. 4 means "4+"
@export var points_cost: int = 0
@export var weapons: Array[WeaponProfile] = []
@export var base_size_mm: float = 32.0
@export var sprite_texture: Texture2D            ## top-down token art placeholder

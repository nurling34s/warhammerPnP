## Shared weapon data shape for both rulesets. `strength_or_damage` and
## `ap_or_rend` intentionally hold different meanings per ruleset (40k:
## Strength/AP; AoS4: Damage/Rend) so .tres files stay structurally uniform —
## each ruleset's combat_math script interprets them. If this reuse turns out
## to be more confusing than useful once real army data lands, split into
## AoSWeaponProfile/FortyKWeaponProfile subclasses instead.
class_name WeaponProfile
extends Resource

@export var weapon_name: String = ""
@export var range_inches: float = 0.0            ## 0 = melee
@export var attacks: String = "1"                ## dice notation allowed: "1", "D3", "2D6"
@export var to_hit_stat: int = 4                 ## AoS4: flat hit target; 40k: WS/BS override if set
@export var strength_or_damage: String = "1"     ## 40k: Strength; AoS4: Damage (dice notation allowed)
@export var ap_or_rend: int = 0                  ## 40k: AP; AoS4: Rend — same slot, ruleset-specific meaning
@export var special_rules: Array[StringName] = []  ## e.g. &"sustained_hits_1", &"crit_mortal"

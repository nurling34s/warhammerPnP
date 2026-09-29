## AoS4 Movement Phase.
##
## Diverges from the shared base in one way now (warhammer_age_of_sigmar_4.md
## section 3.2): Falling Back inflicts D3 mortal-style damage on the
## retreating unit (see declare_fall_back()). The "can't approach within
## engagement range on a Normal Move" rule used to live here too, but it
## turned out to be identical in 40k 11th ed, so it was promoted to
## MovementPhaseBase.can_move_to() in Phase 5f — see that method's doc.
class_name AoSMovementPhase
extends MovementPhaseBase


## Rolls D3 damage against the retreating unit itself, applied like any
## other damage (no Ward check — a known simplification, consistent with
## the project's other minimal-consequence placeholders).
func declare_fall_back(unit: UnitInstance, dice: DiceRoller = null) -> void:
	super.declare_fall_back(unit)
	var roller: DiceRoller = dice if dice else DiceRoller.new()
	var self_damage: int = DiceNotation.roll("D3", roller)
	unit.apply_damage_to_next_model(self_damage)

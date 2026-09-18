## A rectangular deployment region for one player, in inches, matching a
## given scenario. Multiple zones (one per player, or more for asymmetric
## scenarios) make up a match's deployment setup.
class_name DeploymentZone
extends Resource

@export var owner_player: int = 0
@export var rect_inches: Rect2 = Rect2(0, 0, 20, 44)

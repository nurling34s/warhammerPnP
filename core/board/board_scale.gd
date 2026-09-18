## Shared inches<->pixels conversion and default table dimensions. A plain
## constant holder (not a Node/autoload) so core/ rules code — which stays
## scene-tree-agnostic — and scenes/ rendering code can agree on the same
## scale without core/ depending on the scene tree.
##
## All game logic (movement, charge distance, engagement range, coherency)
## works in inches, matching how the rulebooks themselves measure. Pixels
## only exist at the render edge.
class_name BoardScale
extends RefCounted

const PIXELS_PER_INCH: float = 10.0
const TABLE_WIDTH_INCHES: float = 60.0
const TABLE_HEIGHT_INCHES: float = 44.0


static func inches_to_px(inches: float) -> float:
	return inches * PIXELS_PER_INCH


static func px_to_inches(px: float) -> float:
	return px / PIXELS_PER_INCH

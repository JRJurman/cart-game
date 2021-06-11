package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

class Target extends FlxSprite
{
	static inline var SPEED:Float = 0;
	static inline var INITIAL_DRAG:Float = 1600;

	// constructor for a new target
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		// for now, always facing up, to fix later
		facing = FlxObject.UP;

		// use an animation instead of a simple graphic
		loadGraphic(AssetPaths.flower__png, true, 16, 16);

		drag.x = drag.y = INITIAL_DRAG;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

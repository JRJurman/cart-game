package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

class Player extends FlxSprite
{
	static inline var SPEED:Float = 200;
	static inline var INITIAL_DRAG:Float = 1600;

	// constructor for a new player
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		// use a simple graphic, instead of a sprite sheet
		// makeGraphic(16, 22, FlxColor.BLUE);

		// use an animation instead of a simple graphic
		loadGraphic(AssetPaths.link_ooa_cart_shooting__png, true, 17, 23);

		// set the animations for our player based on the sprite sheet
		var cartDirections:Array<String> = ["vertical", "horizontal"];
		var playerDirections:Array<String> = [
			"downleft",
			"down",
			"upright",
			"up",
			"downright",
			"upleft",
			"left",
			"unused",
			"right"
		];
		for (cartDirection in cartDirections)
		{
			for (playerDirection in playerDirections)
			{
				var frames:Array<Int> = getSpriteAnimationFrames(cartDirection, playerDirection);
				trace(cartDirection, playerDirection, frames);
				animation.add(cartDirection + "_cart_facing_" + playerDirection, frames, 6, true);
			}
		}

		drag.x = drag.y = INITIAL_DRAG;
	}

	override function update(elapsed:Float)
	{
		updateAcceleration(); // call our Acceleration helper function
		updateDirection(); // call our test function for direction pointing

		super.update(elapsed);
	}

	// helper function to parse which frames to load from the sprite
	function getSpriteAnimationFrames(cartDirection:String, playerDirection:String)
	{
		var firstFrame:Int = 0;

		// the second set of sprites are the horizontal cart frames
		if (cartDirection == "horizontal")
			firstFrame += 18;

		// make an array of all the different positions, and we'll just indexOf it to get which one we need
		var positionsInSheet:Array<String> = [
			"downleft",
			"down",
			"upright",
			"up",
			"downright",
			"upleft",
			"left",
			"unused",
			"right"
		];

		firstFrame += (positionsInSheet.indexOf(playerDirection) * 2);

		return [firstFrame, firstFrame + 1];
	}

	// helper function for Acceleration
	function updateAcceleration()
	{
		var accelerating:Bool = false;

		accelerating = FlxG.keys.anyPressed([SPACE]);

		// determine the new speed
		var newSpeed:Float = if (accelerating) SPEED else 0;
		var newAngle:Float = 0;

		// set the velocity, and what angle it should be at
		velocity.set(newSpeed, 0);
		velocity.rotate(FlxPoint.weak(0, 0), newAngle);
	}

	// helper function for testing facing directions
	function updateDirection()
	{
		// keys used to build the animation string
		var cartKey:String = "";
		var dirKey:String = "";

		// for now, always facing up, to fix later
		facing = FlxObject.UP;

		// check which keys are pressed
		if (FlxG.keys.anyPressed([UP, W]))
			dirKey += "up";
		if (FlxG.keys.anyPressed([DOWN, S]))
			dirKey += "down";
		if (FlxG.keys.anyPressed([LEFT, A]))
			dirKey += "left";
		if (FlxG.keys.anyPressed([RIGHT, D]))
			dirKey += "right";

		if (FlxG.keys.anyPressed([SHIFT]))
			cartKey = "horizontal"
		else
			cartKey = "vertical";

		var animationKey:String = cartKey + "_cart_facing_" + dirKey;
		trace("animationKey:", animationKey);
		animation.play(animationKey);
	}
}

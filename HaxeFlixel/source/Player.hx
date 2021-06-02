package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;

enum CartDirection
{
	HORIZONTAL;
	VERTICAL;
}

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
		loadGraphic(AssetPaths.link_ooa_cart__png, true, 16, 22);

		// set the animations for our player based on the sprite sheet
		animation.add("vertical_cart_facing_down", [0, 1], 6, true);
		animation.add("vertical_cart_facing_up", [2, 3], 6, true);
		animation.add("vertical_cart_facing_left", [4, 5], 6, true);
		animation.add("vertical_cart_facing_right", [6, 7], 6, true);
		animation.add("horizontal_cart_facing_down", [8, 9], 6, true);
		animation.add("horizontal_cart_facing_up", [10, 11], 6, true);
		animation.add("horizontal_cart_facing_left", [12, 13], 6, true);
		animation.add("horizontal_cart_facing_right", [14, 15], 6, true);

		drag.x = drag.y = INITIAL_DRAG;
	}

	override function update(elapsed:Float)
	{
		updateAcceleration(); // call our Acceleration helper function
		updateDirection(); // call our test function for direction pointing

		super.update(elapsed);
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

		// check which keys are pressed
		if (FlxG.keys.anyPressed([UP, W]))
		{
			facing = FlxObject.UP;
			dirKey = "facing_up";
		}
		if (FlxG.keys.anyPressed([DOWN, S]))
		{
			facing = FlxObject.DOWN;
			dirKey = "facing_down";
		}
		if (FlxG.keys.anyPressed([LEFT, A]))
		{
			facing = FlxObject.LEFT;
			dirKey = "facing_left";
		}
		if (FlxG.keys.anyPressed([RIGHT, D]))
		{
			facing = FlxObject.RIGHT;
			dirKey = "facing_right";
		}

		if (FlxG.keys.anyPressed([SHIFT]))
			cartKey = "horizontal_cart"
		else
			cartKey = "vertical_cart";

		animation.play(cartKey + "_" + dirKey);
	}
}

package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Player extends FlxSprite
{
	static inline var SPEED:Float = 50;
	static inline var ACCELERATION:Float = 1.8;
	static inline var MAX_SPEED:Float = 150;
	static inline var INITIAL_DRAG:Float = 1600;

	public var playerShootingDirection:String = "right";
	public var playerCartOrientation:Int = 0;
	public var playerIsTurning:Bool = false;
	public var playerHasTurned:Bool = false;
	public var playerCurrentTurningTile:Int = -1;
	public var uninterruptedElapsed:Float = 0;
	public var hitMaxSpeed:Bool = false;
	public var playerHasStopped:Bool = false;

	// while not required, we're saving all of these so we can verify
	// later (before failing to load it) if we have the animation key
	var possibleAnimationKeys:Array<String> = new Array<String>();

	// constructor for a new player
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		// for now, always facing up, to fix later
		facing = FlxObject.UP;

		// use an animation instead of a simple graphic
		loadGraphic(AssetPaths.link_ooa_cart_shooting__png, true, 17, 23);
		buildPlayerAnimations();

		drag.x = drag.y = INITIAL_DRAG;

		// set the character sprite so the cart aligns with the track
		setSize(16, 16);
		offset.set(0, 26 - 16);
	}

	override function update(elapsed:Float)
	{
		updateAcceleration(elapsed); // call our Acceleration helper function
		updatePlayerDirection(); // call our function for direction pointing
		updatePlayerAnimation(); // call our function to update the animation based on player props

		// cursor debugging
		// var sprite = new FlxSprite();
		// sprite.makeGraphic(15, 15, FlxColor.TRANSPARENT);
		// FlxG.mouse.load(sprite.pixels);
		// x = FlxG.mouse.x;
		// y = FlxG.mouse.y;

		super.update(elapsed);
	}

	public function cartDirection()
	{
		if ((playerCartOrientation % 180) == 0)
		{
			return "horizontal";
		}
		return "vertical";
	}

	// function to mark the player as turning
	// they shouldn't be able to do other actions here
	public function startTurning(tileId:Int)
	{
		playerIsTurning = true;
		playerHasTurned = false;
		playerCurrentTurningTile = tileId;
	}

	public function turn(rotation:String)
	{
		playerIsTurning = true;
		playerHasTurned = true;

		if (rotation == "clockwise")
			playerCartOrientation = (playerCartOrientation + 90) % 360;
		else if (rotation == "counterclockwise")
			playerCartOrientation = ((playerCartOrientation - 90) + 360) % 360;
	}

	public function finishTurning()
	{
		playerIsTurning = false;
		playerHasTurned = false;
	}

	public function stop()
	{
		playerHasStopped = true;
		uninterruptedElapsed = 0;
	}

	public function start()
	{
		playerHasStopped = false;
	}

	function updatePlayerDirection()
	{
		var previousShootingDirection = playerShootingDirection;
		// default to empty string
		playerShootingDirection = "";

		// check which keys are pressed (up or down)
		if (FlxG.keys.anyPressed([UP, W]))
			playerShootingDirection += "up";
		else if (FlxG.keys.anyPressed([DOWN, S]))
			playerShootingDirection += "down";

		// check which keys are pressed (left or right)
		if (FlxG.keys.anyPressed([LEFT, A]))
			playerShootingDirection += "left";
		else if (FlxG.keys.anyPressed([RIGHT, D]))
			playerShootingDirection += "right";

		// if it's still empty string, use whatever we had before
		if (playerShootingDirection == "")
			playerShootingDirection = previousShootingDirection;
	}

	// helper function to add all the animations that are possible with the sprite sheet
	function buildPlayerAnimations()
	{
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
				var animationKey = cartDirection + "_cart_facing_" + playerDirection;
				animation.add(animationKey, frames, 6, true);
				possibleAnimationKeys.push(animationKey);
			}
		}
	}

	// helper function to parse which frames to load from the sprite
	function getSpriteAnimationFrames(cartDirection:String, playerDirection:String)
	{
		var firstFrame:Int = 0;

		// the second set of sprites are the horizontal cart frames
		if (cartDirection == "horizontal")
			firstFrame += 18;

		// make an array of all the different positions, and we'll just indexOf it to get which one we need
		// this is based on the sprite sheet, this needs to change if "link_ooa_cart_shooting.png" changes.
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
	function updateAcceleration(elapsed:Float)
	{
		if (playerHasStopped)
		{
			velocity.set(0, 0);
			return;
		}

		// add the elapsed time to uninterrupted elapsed
		uninterruptedElapsed += elapsed;

		// determine the new speed
		var newSpeed:Float = Math.min(SPEED + Math.pow(uninterruptedElapsed, ACCELERATION), MAX_SPEED);

		if (newSpeed == MAX_SPEED && hitMaxSpeed == false)
		{
			// glow a color
			hitMaxSpeed = true;
			FlxTween.tween(this, {color: FlxColor.WHITE}, 0.5, {onComplete: brighten, type: ONESHOT});
			FlxTween.color(this, 0.3, FlxColor.fromRGB(200, 200, 200), FlxColor.fromRGB(255, 255, 255), {ease: FlxEase.sineInOut, type: PINGPONG});
		}

		// set the velocity
		velocity.set(newSpeed, 0);

		// point the velocity in the direction of the cart
		velocity.rotate(FlxPoint.weak(0, 0), playerCartOrientation);
	}

	function brighten(_)
	{
		setColorTransform(1, 1, 1, 1, 20, 20, 20, 0);
	}

	function interruptSpeed()
	{
		uninterruptedElapsed = 0;
		hitMaxSpeed = false;
		setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
		FlxTween.cancelTweensOf(this);
	}

	// helper function for testing facing directions
	function updatePlayerAnimation()
	{
		var animationKey = cartDirection() + "_cart_facing_" + playerShootingDirection;
		if (possibleAnimationKeys.contains(animationKey))
		{
			animation.play(animationKey);
		}
	}
}

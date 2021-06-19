package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class Player extends FlxSprite
{
	static var SPEED:Float = 50;
	static var ACCELERATION:Float = 1.8;
	static var MAX_SPEED:Float = 150;
	static var INITIAL_DRAG:Float = 1600;
	static var DIM_FACTOR:Float = 0.4;

	static var BULLET_SPEED:Float = 175;

	static var DIRECTION_TO_ANGLE = [
		"right" => 45 * 0,
		"upright" => 45 * 7,
		"up" => 45 * 6,
		"upleft" => 45 * 5,
		"left" => 45 * 4,
		"downleft" => 45 * 3,
		"down" => 45 * 2,
		"downright" => 45 * 1,
	];

	public var playerShootingDirection:String = "right";
	public var playerCartOrientation:Int = 0;
	public var playerIsTurning:Bool = false;
	public var playerHasTurned:Bool = false;
	public var playerCurrentTile:Int = -1;
	public var uninterruptedElapsed:Float = 0;
	public var hitMaxSpeed:Bool = false;
	public var playerHasStopped:Bool = false;
	public var playerIsReversing = false;
	public var playerBullets:FlxTypedGroup<FlxSprite>;
	public var playerShootingAngle:Int = 0;
	public var playerVelocity:Float = 0;

	// while not required, we're saving all of these so we can verify
	// later (before failing to load it) if we have the animation key
	var possibleAnimationKeys:Array<String> = new Array<String>();

	var gameState:FlxState;

	public function new(state:FlxState, x:Float = 0, y:Float = 0)
	{
		super(x, y);

		gameState = state;

		// for now, always facing up, to fix later
		facing = FlxObject.UP;

		// use an animation instead of a simple graphic
		loadGraphic(AssetPaths.link_ooa_cart_shooting__png, true, 17, 23);
		buildPlayerAnimations();
		scaffoldBullets();

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
		checkForReverse(); // call our function to check if we reversed
		checkForShooting(); // call our function to see if we shot

		// cursor debugging
		// var sprite = new FlxSprite();
		// sprite.makeGraphic(15, 15, FlxColor.TRANSPARENT);
		// FlxG.mouse.load(sprite.pixels);
		// x = FlxG.mouse.x;
		// y = FlxG.mouse.y;

		super.update(elapsed);
	}

	/**
	 * helper function to get which direction the cart is moving, "horizontal" or "vertical"
	 */
	public function getCartDirection()
	{
		if ((playerCartOrientation % 180) == 0)
		{
			return "horizontal";
		}
		return "vertical";
	}

	/**
	 * function to mark the player as turning
	 * they shouldn't be able to do other actions here
	 * @param tileId
	 */
	public function startTurning(tileId:Int)
	{
		playerIsTurning = true;
		playerHasTurned = false;
		playerCurrentTile = tileId;
	}

	/**
	 * Helper function to update player state and orientation when the player should turn
	 */
	public function turn(rotation:String)
	{
		playerIsTurning = true;
		playerHasTurned = true;

		if (rotation == "clockwise")
			playerCartOrientation = (playerCartOrientation + 90) % 360;
		else if (rotation == "counterclockwise")
			playerCartOrientation = ((playerCartOrientation - 90) + 360) % 360;
	}

	/**
	 * Helper function to update player state when the player leaves a turning tile
	 */
	public function finishTurning(tileId:Int)
	{
		playerIsTurning = false;
		playerHasTurned = false;
		playerCurrentTile = tileId;
	}

	/**
	 * Stop moving the cart.
	 */
	public function stop()
	{
		playerHasStopped = true;
		interruptSpeed();
	}

	/**
	 * Move the cart.
	 */
	public function start()
	{
		playerHasStopped = false;
	}

	/**
	 * Helper function to reverse the cart.
	 * Usually called by "checkForReverse()", can be called on it's own
	 */
	public function reverse()
	{
		interruptSpeed();
		playerCartOrientation = (playerCartOrientation + 180) % 360;
	}

	/**
	 * Helper function to reverse the cart
	 * (Does not happen if the player is turning)
	 */
	public function checkForReverse()
	{
		// make sure we are not turning
		if (playerIsTurning)
			return;

		if (FlxG.keys.anyJustPressed([K]))
		{
			reverse();
		}
	}

	/**
	 * Helper function to update the direction that the player is facing
	 */
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

		// update the playerShootingAngle based on the direction
		// this is used to control the bullets
		playerShootingAngle = DIRECTION_TO_ANGLE[playerShootingDirection];
	}

	/**
	 * helper function to add all the animations that are possible with the sprite sheet
	 */
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

	/**
	 * helper function for Acceleration
	 * @param elapsed
	 */
	function updateAcceleration(elapsed:Float)
	{
		if (playerHasStopped)
		{
			velocity.set(0, 0);
			playerVelocity = 0;
			return;
		}

		// add the elapsed time to uninterrupted elapsed
		uninterruptedElapsed += elapsed;

		// determine the new speed
		playerVelocity = Math.min(SPEED + Math.pow(uninterruptedElapsed, ACCELERATION), MAX_SPEED);

		if (playerVelocity == MAX_SPEED && hitMaxSpeed == false)
		{
			// we've hit max speed!
			hitMaxSpeed = true;

			// brighten the sprite, and then loop it darker
			brighten();
			FlxTween.color(this, 0.3, FlxColor.WHITE.getDarkened(DIM_FACTOR), FlxColor.WHITE, {ease: FlxEase.sineInOut, type: PINGPONG});
		}

		// set the velocity
		velocity.set(playerVelocity, 0);

		// point the velocity in the direction of the cart
		velocity.rotate(FlxPoint.weak(0, 0), playerCartOrientation);
	}

	/**
	 * Helper function to brighten the character sprite
	 */
	function brighten()
	{
		var brightnessOffset = Math.ceil(255 * (DIM_FACTOR / 3));
		setColorTransform(1, 1, 1, 1, brightnessOffset, brightnessOffset, brightnessOffset);
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
		var animationKey = getCartDirection() + "_cart_facing_" + playerShootingDirection;
		if (possibleAnimationKeys.contains(animationKey))
		{
			animation.play(animationKey);
		}
	}

	// https://github.com/HaxeFlixel/flixel-demos/blob/master/Arcade/FlxInvaders/source/PlayState.hx
	function scaffoldBullets()
	{
		// First we will instantiate the bullets you fire at targets.
		var numPlayerBullets:Int = 8;
		// Initializing the array is very important and easy to forget!
		playerBullets = new FlxTypedGroup(numPlayerBullets);
		var sprite:FlxSprite;

		// Create 8 bullets for the player to recycle
		for (i in 0...numPlayerBullets)
		{
			// Instantiate a new sprite offscreen
			sprite = new FlxSprite(-10, -10);
			// Create a 2x8 white box
			// sprite.makeGraphic(2, 8);
			sprite.loadGraphic(AssetPaths.bullet__png, false, 8, 8);
			sprite.exists = false;
			// Add it to the group of player bullets
			playerBullets.add(sprite);
		}
	}

	// helper function to shoot bullet
	function checkForShooting()
	{
		if (FlxG.keys.anyJustPressed([J]))
		{
			// recycle one of the bullets
			var bullet:FlxSprite = playerBullets.recycle();
			bullet.reset(x + width / 2 - bullet.width / 2, y);

			// set the bullet shooting in the direction we are pointing
			bullet.velocity.set(BULLET_SPEED, 0);
			bullet.velocity.rotate(FlxPoint.weak(0, 0), playerShootingAngle);
		}
	}
}

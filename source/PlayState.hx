package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxPoint;

class PlayState extends FlxState
{
	var BASE_LERP:Float = 0.05;
	var MAX_LERP:Float = 0.2;

	var lerpSlope:Float;
	var lerpConstant:Float;

	var player:Player;
	var level:GameLevel;
	var cameraPosition:FlxPoint;

	override public function create()
	{
		player = new Player(this, 20, 20);

		FlxG.camera.follow(player, SCREEN_BY_SCREEN, BASE_LERP);

		// save the camera position
		cameraPosition = new FlxPoint(FlxG.camera.scroll.x, FlxG.camera.scroll.y);

		// calculate the lerp properties for the object
		calculateCameraLerpProperties();

		level = new GameLevel(this, player);
		level.loadLevels();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		// check if the camera is moving (if it is, don't update anything)
		var cameraMoved = isCameraMoving();
		if (cameraMoved)
		{
			updateCameraPosition();
			return;
		}

		super.update(elapsed);
		updateCameraLerp();
		level.update(elapsed);
	}

	/**
	 * helper function to determine if the camera is moving
	 * (this happens during the screen-to-screen transition)
	 */
	function isCameraMoving()
	{
		var xMoved = Math.floor(cameraPosition.x) != Math.floor(FlxG.camera.scroll.x);
		var yMoved = Math.floor(cameraPosition.y) != Math.floor(FlxG.camera.scroll.y);
		return xMoved || yMoved;
	}

	/**
	 * sets the known camera position,
	 * so that we can tell if the camera is moving
	 */
	function updateCameraPosition()
	{
		cameraPosition.x = FlxG.camera.scroll.x;
		cameraPosition.y = FlxG.camera.scroll.y;
	}

	/**
	 * sets the camera transition speed between screens based on the players speed
	 */
	function updateCameraLerp()
	{
		// the variables here are based on the calculateCameraLerpProperties
		FlxG.camera.followLerp = lerpSlope * (player.playerVelocity) + lerpConstant;
	}

	/**
	 * determine the lerp (camera transition) function based on the player base and max speed
	 */
	function calculateCameraLerpProperties()
	{
		var diffOfSpeeds = Player.MAX_SPEED - Player.SPEED;
		var diffOfLerp = MAX_LERP - BASE_LERP;
		lerpSlope = diffOfLerp / diffOfSpeeds;
		lerpConstant = BASE_LERP - (lerpSlope * Player.SPEED);
	}
}

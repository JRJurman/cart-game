package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;

class GameLevel
{
	static var TILESET_CART_AND_MAP:Array<String> = [
		"wall", "wall", "door-left", "door-down", "wall", "wall", "wall", "wall", "door-right", "door-up", "wall", "wall", "wall", "ground", "track-stop",
		"switch", "track-turn-north-west", "track-turn-north-east", "wall", "wall", "wall", "wall", "track-turn-south-west", "track-turn-south-east",
		"track-vertical", "track-horizontal"
	];
	static var TILE_SIZE:Int = 16;

	var ldtkProject:LdtkLevels;
	var gameState:FlxState;
	var gamePlayer:Player;
	var targets:FlxTypedGroup<TargetSprite>;
	var levelsMap:WorldCoordMap<LdtkLevels.LdtkLevels_Level>;
	var levelContainers:FlxTypedGroup<flixel.group.FlxSpriteGroup>;
	var worldAutoTiles:WorldCoordMap<AutoTileWithOffset>;
	var levelPosX:Int;
	var levelPosY:Int;

	public function new(state:FlxState, player:Player)
	{
		ldtkProject = new LdtkLevels();
		gameState = state;
		gamePlayer = player;
		targets = new FlxTypedGroup<TargetSprite>();
		levelContainers = new FlxTypedGroup<flixel.group.FlxSpriteGroup>();
		worldAutoTiles = new WorldCoordMap<AutoTileWithOffset>();

		var levels = ldtkProject.all_levels;
		levelsMap = new WorldCoordMap<LdtkLevels.LdtkLevels_Level>();
		levelsMap.set(new WorldCoord(0, 0), levels.Ethans_test_1);
		levelsMap.set(new WorldCoord(256, 0), levels.Ethans_test_2);
		levelsMap.set(new WorldCoord(512, 0), levels.Ethans_test_3);
		levelsMap.set(new WorldCoord(0, 256), levels.Ethans_test_6);
		levelsMap.set(new WorldCoord(256, 256), levels.Ethans_test_5);
		levelsMap.set(new WorldCoord(512, 256), levels.Ethans_test_4);
		levelsMap.set(new WorldCoord(0, 512), levels.Ethans_test_7);
		levelsMap.set(new WorldCoord(256, 512), levels.Ethans_test_8);
		levelsMap.set(new WorldCoord(512, 512), levels.Ethans_test_9);

		levelPosX = 0;
		levelPosY = 0;
	}

	/**
	 * Function to load all the levels in levelsMap.
	 * Eventually this will randomly generate a map.
	 * This logic is based on https://github.com/deepnight/ldtk-haxe-api/blob/31ff2a75953e7f4ac93408d46cffe90de11313f4/samples/Flixel%20-%20Render%20tile%20layer/src/PlayState.hx
	 */
	public function loadLevels()
	{
		gameState.add(levelContainers);
		gameState.add(gamePlayer);
		gameState.add(targets);
		gameState.add(gamePlayer.playerBullets);

		for (coord in levelsMap.getCoords())
		{
			loadLevel(coord, levelsMap.get(coord).identifier);
		}
	}

	/**
	 * Function to load a level (based on the identifier) at a specific coordinate.
	 * This function will load all the entities for the level.
	 * If you just want to render over an existing level, use `renderOtherLevel`
	 */
	public function loadLevel(coord:WorldCoord, levelIdentifier:String)
	{
		var level = ldtkProject.getLevel(levelIdentifier);

		// create a new container to hold the level (we shouldn't need this later)
		var levelContainer = new flixel.group.FlxSpriteGroup();
		levelContainers.add(levelContainer);

		// add all the autotiles (updating the x and y based on the world coords)
		// these WILL be read to get what tile is under the player
		var offsetTiles = level.l_Map.autoTiles.map(AutoTileWithOffset.withOffset(coord));
		for (tile in offsetTiles)
		{
			var newCoord = new WorldCoord(tile.getX(), tile.getY());
			worldAutoTiles.set(newCoord, tile);
		}

		// set the x and y based on the coordinate
		levelContainer.x = coord.x;
		levelContainer.y = coord.y;

		// render the tiles on the game
		level.l_Map.render(levelContainer);

		// expand the world bounds based on the level rendered
		FlxG.worldBounds.setSize(coord.x + level.pxWid, coord.y + level.pxHei);

		for (player in level.l_Entities.all_Player)
		{
			gamePlayer.setPosition(player.pixelX + coord.x, player.pixelY + coord.y);
		}

		// process switches
		for (levelSwitch in level.l_Entities.all_Level_Switch)
		{
			var newSwitch = new Switch(levelSwitch.pixelX + coord.x, levelSwitch.pixelY + coord.y, levelContainer, level.identifier, levelSwitch.f_Level,
				this);
			targets.add(newSwitch);
		}

		// process targets
		for (target in level.l_Entities.all_Target)
		{
			var newTarget = new Target(target.pixelX + coord.x, target.pixelY + coord.y);
			targets.add(newTarget);
		}
	}

	/**
	 * Helper function to render over an existing levelContainer.
	 * This does not load any entities, and requires an existing container.
	 * If you want to load a new level with entities, use `loadLevel`.
	 */
	public function renderOtherLevel(levelContainer:FlxSpriteGroup, levelIdentifier:String)
	{
		var level = ldtkProject.getLevel(levelIdentifier);
		levelContainer.clear();
		var levelCoord = new WorldCoord(Math.floor(levelContainer.x), Math.floor(levelContainer.y));

		var offsetTiles = level.l_Map.autoTiles.map(AutoTileWithOffset.withOffset(levelCoord));
		for (tile in offsetTiles)
		{
			var newCoord = new WorldCoord(tile.getX(), tile.getY());
			worldAutoTiles.set(newCoord, tile);
		}

		// render the tiles on the game
		level.l_Map.render(levelContainer);
	}

	/**
	 * Helper function that is called by PlayState on every update.
	 */
	public function update(elapsed:Float)
	{
		// for debugging
		// var tilesetIdUnderMouse = getTilesetIdUnderPoint(FlxG.mouse.getPosition());
		// trace(tilesetIdUnderMouse);

		processPlayerTurn();

		// process any player bullets and the targets
		processPlayerBullets();
	}

	/**
	 * Function to call on update.
	 * Reads the players position, and determines based on the loaded map
	 * if the player needs to turn on the map.
	 */
	function processPlayerTurn()
	{
		// get the tileset id (the type of tile), under the player
		var tilesetIdUnderPlayer = getTilesetIdUnderPoint(gamePlayer.getMidpoint());

		// determine what kind of turn or direction the tile might be
		var trackDirection = getTileTrackDirection(tilesetIdUnderPlayer);

		// if trackDirection is null, we aren't on a track, don't change anything
		if (trackDirection == null)
			return;

		// determine if we are on a new tile
		var isOnNewTile = gamePlayer.playerCurrentTile != tilesetIdUnderPlayer;

		// determine if we are on a tile that is a stop track
		var isOnStoppingTrack = trackDirection == "stop";

		// determine if this tile is a turning track (otherwise it's a straight track)
		var isOnTurningTrack = trackDirection.indexOf("clockwise") > -1;

		// determine if we are past the midpoint of the tile (lots of things we don't want to do until we are in the center)
		var isPastTileCenter = isPastMidpoint(gamePlayer, gamePlayer.playerCartOrientation, TILE_SIZE);

		// if we are on a stop track, stop the player
		if (isOnStoppingTrack)
		{
			// only stop once we are in the middle of the tile
			var shouldStop = isPastTileCenter;

			if (shouldStop)
				gamePlayer.stop();

			return;
		}

		// if we are on a new tile we need to update state (usually either finish turning or start turning again)
		if (isOnNewTile)
		{
			if (!isOnTurningTrack)
				gamePlayer.finishTurning(tilesetIdUnderPlayer);
			else if (isOnTurningTrack)
				gamePlayer.startTurning(tilesetIdUnderPlayer);

			return;
		}

		// if we aren't already turning, we can start turning now
		if (isOnNewTile && isOnTurningTrack)
		{
			return;
		}

		// if we aren't turning, just end the function (we have nothing else to do)
		if (!isOnTurningTrack)
			return;

		// if we are turning, (and haven't turned yet)
		// wait until we are at the center of the tile, and then snap and turn
		if (gamePlayer.playerIsTurning && !gamePlayer.playerHasTurned)
		{
			var shouldTurn = isPastMidpoint(gamePlayer, gamePlayer.playerCartOrientation, TILE_SIZE);

			if (shouldTurn)
			{
				// rotate the player, and snap them to the midpoint (so that we don't get off track)
				gamePlayer.turn(trackDirection);
				snapSpriteToTile(gamePlayer, TILE_SIZE);
			}
		}

		return;
	}

	/**
	 * returns which direction the door is facing
	 * @param tilesetIdUnderPlayer
	 */
	function getTileNameFromId(tilesetIdUnderPoint:Int)
	{
		// if it is null, we probably fell off the map
		if (tilesetIdUnderPoint == null)
			return null;

		var tileUnderPoint = TILESET_CART_AND_MAP[tilesetIdUnderPoint];
		return tileUnderPoint;
	}

	/**
	 * returns "horizontal", "vertical", "clockwise", "counterclockwise" or null
	 * @param tilesetIdUnderPlayer
	 */
	function getTileTrackDirection(tilesetIdUnderPoint:Int)
	{
		var tileUnderPoint = getTileNameFromId(tilesetIdUnderPoint);

		// if it is null, we probably fell off the map
		if (tileUnderPoint == null)
			return null;

		// horizontal and vertical tracks
		// these can probably be ignored, we really only need to care about turning
		if (tileUnderPoint == "track-horizontal")
			return "horizontal";
		if (tileUnderPoint == "track-vertical")
			return "vertical";

		if (tileUnderPoint == "track-stop")
			return "stop";

		// turns, which we should turn halfway through
		if (tileUnderPoint.indexOf("track-turn") > -1)
		{
			// for these we actually need to read the player's current direction
			// this way we can determine which direction they are turning
			if (tileUnderPoint == "track-turn-north-west")
				if (gamePlayer.getCartDirection() == "horizontal")
					return "counterclockwise";
				else
					return "clockwise";

			if (tileUnderPoint == "track-turn-north-east")
				if (gamePlayer.getCartDirection() == "horizontal")
					return "clockwise";
				else
					return "counterclockwise";

			if (tileUnderPoint == "track-turn-south-west")
				if (gamePlayer.getCartDirection() == "horizontal")
					return "clockwise";
				else
					return "counterclockwise";

			if (tileUnderPoint == "track-turn-south-east")
				if (gamePlayer.getCartDirection() == "horizontal")
					return "counterclockwise";
				else
					return "clockwise";
		}

		return null;
	}

	/**
	 * get the tile under a point
	 * this is based on the map data that is loaded from LDtk
	 *
	 * DEBUGGING NOTE: you can call this with FlxG.mouse.getPosition to hover and get the tile
	 *
	 * @param pointOverTile
	 */
	function getTilesetIdUnderPoint(pointOverTile:FlxPoint)
	{
		// get the x and y - the "getInt" uses grid indexes, not pixels, so we have to divide by tile size
		var x = Math.floor((pointOverTile.x) / TILE_SIZE) * TILE_SIZE;
		var y = Math.floor((pointOverTile.y) / TILE_SIZE) * TILE_SIZE;

		var tileAtPoint = worldAutoTiles.get(new WorldCoord(x, y));
		if (tileAtPoint != null)
		{
			return tileAtPoint.autoTile.tileId;
		}

		return null;
	}

	/**
	 * helper function that returns a function to
	 * check if the tile is at this x-y coordinate
	 * @param x
	 * @param y
	 */
	function tileIsAtLocation(x:Int, y:Int)
	{
		return function withTile(tile:AutoTileWithOffset)
		{
			return tile.getX() == x && tile.getY() == y;
		}
	}

	/**
	 * helper function to determine how far the sprite is from the corner of the tile
	 * @param sprite
	 */
	function getSpriteOffsetFromTileCorner(sprite:FlxSprite)
	{
		return ["x" => sprite.x % TILE_SIZE, "y" => sprite.y % TILE_SIZE];
	}

	/**
	 * Helper function to determine if the sprite is at or beyond the midpoint of a tile
	 * @param sprite
	 * @param direction
	 */
	function isPastMidpoint(player:Player, direction:Int, tileSize:Int)
	{
		// determine how off we are from the middle of the tile
		var playerMiddleOffsetX = (player.getHitbox().x + (player.getHitbox().width / 2)) % tileSize;
		var playerMiddleOffsetY = (player.getHitbox().y + (player.getHitbox().height / 2)) % tileSize;

		var shouldRotatePlayer = false;

		// we need to wait until we pass some midpoint (based on where we are going)
		if (direction == 0)
		{
			// we're going right, check if our offset from the midpoint x is greater than the tile x
			shouldRotatePlayer = playerMiddleOffsetX >= (tileSize / 2);
		}
		else if (direction == 180)
		{
			// we're going left, check if our offset from the midpoint x is less than the tile x
			shouldRotatePlayer = playerMiddleOffsetX <= (tileSize / 2);
		}
		else if (direction == 270)
		{
			// we're going up, check if our offset from the midpoint y is less than the tile y
			shouldRotatePlayer = playerMiddleOffsetY <= (tileSize / 2);
		}
		else if (direction == 90)
		{
			// we're going down, check if our offset from the midpoint y is greater than the tile y
			shouldRotatePlayer = playerMiddleOffsetY >= (tileSize / 2);
		}

		return shouldRotatePlayer;
	}

	/**
	 * Function to snap sprite to the tile it is on
	 * (useful if we are worried that an entity or object could have fallen off a tile)
	 * @param sprite
	 * @param tileSize
	 */
	function snapSpriteToTile(sprite:FlxSprite, tileSize:Int)
	{
		sprite.x = Math.round(sprite.x / (tileSize / 2)) * (tileSize / 2);
		sprite.y = Math.round(sprite.y / (tileSize / 2)) * (tileSize / 2);
	}

	/**
	 * Function to process any collisions between the player's bullets and targets
	 */
	function processPlayerBullets()
	{
		FlxG.overlap(gamePlayer.playerBullets, targets, onTargetShot);
	}

	/**
	 * Generic function to call the bullet and target's onHit function.
	 * This is used in processPlayerBullets.
	 */
	function onTargetShot(bullet:PlayerBullet, target:TargetSprite)
	{
		bullet.onHit();
		target.onHit();
	}
}

package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import ldtk.Layer_AutoLayer.AutoTile;

class GameLevel
{
	static var TILESET_CART_AND_MAP:Array<String> = [
		"wall", "wall", "door", "door", "wall", "wall", "wall", "wall", "door", "door", "wall", "wall", "wall", "ground", "track-stop", "switch",
		"track-turn-north-west", "track-turn-north-east", "wall", "wall", "wall", "wall", "track-turn-south-west", "track-turn-south-east", "track-vertical",
		"track-horizontal"
	];
	static var TILE_SIZE:Int = 16;

	var ldtkProject:LdtkLevels;
	var levelContainer:FlxSpriteGroup;
	var levelLoadedLevel:LdtkLevels.LdtkLevels_Level;
	var gameState:FlxState;
	var gamePlayer:Player;
	var targets:FlxTypedGroup<Target>;

	public function new(state:FlxState, player:Player)
	{
		ldtkProject = new LdtkLevels();
		levelContainer = new FlxSpriteGroup();
		gameState = state;
		gamePlayer = player;
		targets = new FlxTypedGroup<Target>();
	}

	// https://github.com/deepnight/ldtk-haxe-api/blob/31ff2a75953e7f4ac93408d46cffe90de11313f4/samples/Flixel%20-%20Render%20tile%20layer/src/PlayState.hx
	public function loadLevel()
	{
		gameState.add(levelContainer);
		gameState.add(gamePlayer);
		gameState.add(targets);

		var levels = ldtkProject.all_levels;
		levelLoadedLevel = levels.Test_Level;

		// render the tiles on the game
		levelLoadedLevel.l_Map.render(levelContainer);

		for (player in levelLoadedLevel.l_Entities.all_Player)
		{
			gamePlayer.setPosition(player.pixelX, player.pixelY);
			snapSpriteToTile(gamePlayer, TILE_SIZE);
		}
		// process switches
		for (gameSwitch in levelLoadedLevel.l_Entities.all_Switch) {}
		// process targets
		for (target in levelLoadedLevel.l_Entities.all_Target)
		{
			var newTarget = new Target(target.pixelX, target.pixelY);
			snapSpriteToTile(newTarget, TILE_SIZE);
			targets.add(newTarget);
		}
	}

	public function update()
	{
		// for debugging
		// var tilesetIdUnderMouse = tilesetIdUnderPoint(FlxG.mouse.getPosition());

		processPlayerTurn();
	}

	/**
	 * Function to call on update.
	 * Reads the players position, and determines based on the loaded map
	 * if the player needs to turn on the map.
	 */
	function processPlayerTurn()
	{
		// get the tileset id (the type of tile), under the player
		var tilesetIdUnderPlayer = tilesetIdUnderPoint(gamePlayer.getMidpoint());

		// if we can't read what tile is under the player, chances are they've fallen off the map
		// TODO handle this better, for now, they just won't turn
		var isPlayerOverATile = tilesetIdUnderPlayer != null;
		if (!isPlayerOverATile)
			return null;

		// determine what kind of turn or direction the tile might be
		var trackDirection = getTileTrackTurn(tilesetIdUnderPlayer);

		// if trackDirection is null, we aren't on a track, don't change anything
		if (trackDirection == null)
			return null;

		if (trackDirection == "stop")
		{
			gamePlayer.stop();
			return null;
		}

		// if we are on a new tile, and we were turning, we must have finished turning
		var isOnNewTile = gamePlayer.playerCurrentTurningTile != tilesetIdUnderPlayer;
		if (gamePlayer.playerIsTurning && isOnNewTile)
		{
			gamePlayer.finishTurning();
			return null;
		}

		// determine if this tile is a turning track (otherwise it's a straight track)
		var isOnTurningTrack = trackDirection.indexOf("clockwise") > -1;

		// if we aren't turning, just end the function (we have nothing else to do)
		if (!isOnTurningTrack)
			return null;

		// if we aren't already turning, we can start turning now
		if (!gamePlayer.playerIsTurning)
		{
			gamePlayer.startTurning(tilesetIdUnderPlayer);
			return null;
		}

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

		return null;
	}

	/**
	 * returns "horizontal", "vertical", "turning", or null
	 * @param tilesetIdUnderPlayer
	 */
	function getTileTrackTurn(tilesetIdUnderPlayer:Int)
	{
		var tileUnderPlayer = TILESET_CART_AND_MAP[tilesetIdUnderPlayer];
		// horizontal and vertical tracks
		// these can probably be ignored, we really only need to care about turning
		if (tileUnderPlayer == "track-horizontal")
			return "horizontal";
		if (tileUnderPlayer == "track-vertical")
			return "vertical";

		if (tileUnderPlayer == "track-stop")
			return "stop";

		// turns, which we should turn halfway through
		if (tileUnderPlayer.indexOf("track-turn") > -1)
		{
			// for these we actually need to read the player's current direction
			// this way we can determine which direction they are turning
			if (tileUnderPlayer == "track-turn-north-west")
				if (gamePlayer.cartDirection() == "horizontal")
					return "counterclockwise";
				else
					return "clockwise";

			if (tileUnderPlayer == "track-turn-north-east")
				if (gamePlayer.cartDirection() == "horizontal")
					return "clockwise";
				else
					return "counterclockwise";

			if (tileUnderPlayer == "track-turn-south-west")
				if (gamePlayer.cartDirection() == "horizontal")
					return "clockwise";
				else
					return "counterclockwise";

			if (tileUnderPlayer == "track-turn-south-east")
				if (gamePlayer.cartDirection() == "horizontal")
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
	function tilesetIdUnderPoint(pointOverTile:FlxPoint)
	{
		// get the x and y - the "getInt" uses grid indexes, not pixels, so we have to divide by tile size
		var x = Math.floor((pointOverTile.x) / TILE_SIZE) * TILE_SIZE;
		var y = Math.floor((pointOverTile.y) / TILE_SIZE) * TILE_SIZE;

		var tilesAtPoint = levelLoadedLevel.l_Map.autoTiles.filter(tileIsAtLocation(x, y));
		if (tilesAtPoint.length > 0)
		{
			return tilesAtPoint[0].tileId;
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
		return function withTile(tile:AutoTile)
		{
			return tile.renderX == x && tile.renderY == y;
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
	 * @return }
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

	function snapSpriteToTile(sprite:FlxSprite, tileSize:Int)
	{
		sprite.x = Math.round(sprite.x / (tileSize / 2)) * (tileSize / 2);
		sprite.y = Math.round(sprite.y / (tileSize / 2)) * (tileSize / 2);
	}
}

package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
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

	public function new(state:FlxState, player:Player)
	{
		ldtkProject = new LdtkLevels();
		levelContainer = new FlxSpriteGroup();
		gameState = state;
		gamePlayer = player;
	}

	// https://github.com/deepnight/ldtk-haxe-api/blob/31ff2a75953e7f4ac93408d46cffe90de11313f4/samples/Flixel%20-%20Render%20tile%20layer/src/PlayState.hx
	public function loadLevel()
	{
		gameState.add(levelContainer);
		gameState.add(gamePlayer);

		var levels = ldtkProject.all_levels;
		levelLoadedLevel = levels.Test_Level;

		// render the tiles on the game
		levelLoadedLevel.l_Map.render(levelContainer);

		for (player in levelLoadedLevel.l_Entities.all_Player)
		{
			gamePlayer.setPosition(player.pixelX, player.pixelY);
		}
		// process switches
		for (gameSwitch in levelLoadedLevel.l_Entities.all_Switch) {}
		// process targets
		for (target in levelLoadedLevel.l_Entities.all_Target) {}
	}

	public function update()
	{
		// for debugging
		// var tilesetIdUnderMouse = tilesetIdUnderPoint(FlxG.mouse.getPosition());

		processPlayerTurn();
	}

	function processPlayerTurn()
	{
		var trackDirection = getTileTrackTurn();

		// if trackDirection is null, we aren't on a track, don't change anything
		if (trackDirection == null)
		{
			trace("we aren't on a track");
			return null;
		}

		// if trackDirection is something (but not turning), we can mark the player as not turning
		var isOnTurningTile = trackDirection.indexOf("clockwise") > -1;
		if (!isOnTurningTile)
		{
			if (gamePlayer.playerIsTurning)
			{
				trace("we finished turning");
				gamePlayer.finishTurning();
			}

			return null;
		}

		// if we are turning, tell the player they are turning, and that we have to finish
		// before you can turn again (this will also prevent other actions like reversing)
		if (!gamePlayer.playerIsTurning)
		{
			trace("we started turning");
			gamePlayer.startTurning();
			return null;
		}

		// if we are turning, (and haven't turned yet)
		// wait until we are at the center of the tile
		if (gamePlayer.playerIsTurning && !gamePlayer.playerHasTurned)
		{
			trace("we are processing a turn");
			var playerOffsetX = (gamePlayer.getHitbox().x + (gamePlayer.getHitbox().width / 2)) % TILE_SIZE;
			var playerOffsetY = (gamePlayer.getHitbox().y + (gamePlayer.getHitbox().height / 2)) % TILE_SIZE;
			trace(playerOffsetX, playerOffsetY);

			// determine which direction we were going
			// (to determine which midpoint we care about)
			var shouldRotatePlayer = false;
			if (gamePlayer.playerCartDirection == "horizontal")
			{
				// if the player is moving horizontally, we need to wait until our x matches the frame x
				// the limit for this is based on which direction we are going (rotation wise)
				if (gamePlayer.playerCartOrientation == 0)
				{
					// we're going right, check if our offset from the midpoint x is greater than the tile x
					shouldRotatePlayer = playerOffsetX >= (TILE_SIZE / 2);
				}
				else if (gamePlayer.playerCartOrientation == 180)
				{
					// we're going left, check if our offset from the midpoint x is less than the tile x
					shouldRotatePlayer = playerOffsetX <= (TILE_SIZE / 2);
				}
				if (shouldRotatePlayer)
				{
					trace("we are making the turn");
					// rotate the player, and snap them to the midpoint (so that we don't get off track)
					gamePlayer.rotatePlayer(trackDirection);
					gamePlayer.x = Math.round(gamePlayer.x / (TILE_SIZE / 2)) * (TILE_SIZE / 2);
					gamePlayer.turn();
				}
			}
			else if (gamePlayer.playerCartDirection == "vertical")
			{
				// if the player is moving vertically, we need to wait until our y matches the frame y
				// the limit for this is based on which direction we are going (rotation wise)
				if (gamePlayer.playerCartOrientation == 270)
				{
					// we're going up, check if our offset from the midpoint y is less than the tile y
					trace('moving up');
					shouldRotatePlayer = playerOffsetY <= (TILE_SIZE / 2);
				}
				else if (gamePlayer.playerCartOrientation == 90)
				{
					// we're going down, check if our offset from the midpoint y is greater than the tile y
					trace('moving down');
					shouldRotatePlayer = playerOffsetY >= (TILE_SIZE / 2);
				}
				if (shouldRotatePlayer)
				{
					trace("we are making the turn");
					// rotate the player, and snap them to the midpoint (so that we don't get off track)
					gamePlayer.rotatePlayer(trackDirection);
					gamePlayer.y = Math.round(gamePlayer.y / (TILE_SIZE / 2)) * (TILE_SIZE / 2);
					gamePlayer.turn();
				}
			}
		}

		return null;
	}

	// returns "horizontal", "vertical", "turning", or null
	function getTileTrackTurn()
	{
		var tilesetIdUnderPlayer = tilesetIdUnderPoint(gamePlayer.getMidpoint());
		if (tilesetIdUnderPlayer == null)
			return null;

		var tileUnderPlayer = TILESET_CART_AND_MAP[tilesetIdUnderPlayer];
		// horizontal and vertical tracks
		// these can probably be ignored, we really only need to care about turning
		if (tileUnderPlayer == "track-horizontal")
			return "horizontal";
		if (tileUnderPlayer == "track-vertical")
			return "vertical";

		// turns, which we should turn halfway through
		if (tileUnderPlayer.indexOf("track-turn") > -1)
		{
			// for these we actually need to read the player's current direction
			// this way we can determine which direction they are turning
			if (tileUnderPlayer == "track-turn-north-west")
				if (gamePlayer.playerCartDirection == "horizontal")
					return "counterclockwise";
				else
					return "clockwise";

			if (tileUnderPlayer == "track-turn-north-east")
				if (gamePlayer.playerCartDirection == "horizontal")
					return "clockwise";
				else
					return "counterclockwise";

			if (tileUnderPlayer == "track-turn-south-west")
				if (gamePlayer.playerCartDirection == "horizontal")
					return "clockwise";
				else
					return "counterclockwise";

			if (tileUnderPlayer == "track-turn-south-east")
				if (gamePlayer.playerCartDirection == "horizontal")
					return "counterclockwise";
				else
					return "clockwise";
		}

		return null;
	}

	// get the tile under a point
	// this is based on the map data that is loaded from LDtk
	// DEBUGGING NOTE: you can call this with FlxG.mouse.getPosition to hover and get the tile
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

	// helper function that returns a function to
	// check if the tile is at this x-y coordinate
	function tileIsAtLocation(x:Int, y:Int)
	{
		return function withTile(tile:AutoTile)
		{
			return tile.renderX == x && tile.renderY == y;
		}
	}

	// helper function to determine how far the sprite is from the corner of the tile
	function getSpriteOffsetFromTileCorner(sprite:FlxSprite)
	{
		return ["x" => sprite.x % TILE_SIZE, "y" => sprite.y % TILE_SIZE];
	}

	function snapSpriteToTileCorner(sprite:FlxSprite) {}
}

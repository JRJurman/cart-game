package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;

class GameLevel
{
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
		FlxG.overlap(levelContainer.group, gamePlayer, onPlayerOverlap);

		// debugging with mouse
		// var mousePosition = FlxG.mouse.getPosition();
		// trace(mousePosition.x / 16, mousePosition.y / 16, tileUnderPoint(mousePosition));

		// var tileUnderPlayer = tileUnderPoint(gamePlayer.getMidpoint());
		// var trackTile = 2;

		// if (tileUnderPlayer == trackTile) {}
	}

	function onPlayerOverlap(map:FlxSprite, player:Player)
	{
		// determine what tile we are overlapping with
		var frameX = Math.floor(map.frame.frame.x);
		var frameY = Math.floor(map.frame.frame.y);
		var trackDirection = getTileTrackTurn(frameX, frameY, player);

		trace(trackDirection, frameX, frameY);
		trace(map.getGraphicMidpoint(), player.getGraphicMidpoint());

		// if trackDirection is null, we aren't on a track, don't change anything
		if (trackDirection == null)
			return null;

		// if trackDirection is something (but not turning), we can mark the player as not turning
		var isOnTurningTile = trackDirection.indexOf("clockwise") > -1;
		if (!isOnTurningTile)
		{
			player.finishTurning();
			return null;
		}

		// if we are turning, tell the player they are turning, and that we have to finish
		// before you can turn again (this will also prevent other actions like reversing)
		if (!player.playerIsTurning)
		{
			player.startTurning();
		}

		// if we are turning, (and haven't turned yet)
		// wait until we are actually at the edge of the tile
		if (player.playerIsTurning && !player.playerHasTurned)
		{
			// determine which direction we were going
			// (to determine which midpoint we care about)
			if (player.playerCartDirection == "horizontal")
			{
				// if the player is moving horizontally, we need to wait until the midpoint x matches
				var mapAndPlayerXDiff = map.getGraphicMidpoint().x - player.getMidpoint().x;
				var mapAndPlayerXIsClose = Math.abs(mapAndPlayerXDiff) < 0.35;
				if (mapAndPlayerXIsClose)
				{
					// rotate the player, and snap them to the midpoint (so that we don't get off track)
					gamePlayer.rotatePlayer(trackDirection);
					player.x = player.x - (mapAndPlayerXDiff);
					player.turn();
				}
			}
			else if (player.playerCartDirection == "vertical")
			{
				// if the player is moving vertically, we need to wait until the midpoint y matches
				var mapAndPlayerYDiff = map.getGraphicMidpoint().y - player.getMidpoint().y;

				var mapAndPlayerYIsClose = Math.abs(mapAndPlayerYDiff) < 0.35;
				if (mapAndPlayerYIsClose)
				{
					// rotate the player, and snap them to the midpoint (so that we don't get off track)
					gamePlayer.rotatePlayer(trackDirection);
					player.y = player.y - (mapAndPlayerYDiff);
					player.turn();
				}
			}
		}

		return null;
	}

	// returns "horizontal", "vertical", "turning", or null
	// this is based on cart_and_map_cropped.png, and if that changes, this will break
	function getTileTrackTurn(frameX:Int, frameY:Int, player:Player)
	{
		// make map based on the positions
		var tileMap = [
			"0x0" => "flat wall", "0x16" => "flat wall", "0x32" => "door", "0x48" => "door", "0x64" => "corner wall", "0x80" => "corner wall",
			"16x0" => "flat wall", "16x16" => "flat wall", "16x32" => "door", "16x48" => "door", "16x64" => "corner wall", "16x80" => "corner wall",
			"32x0" => "wall", "32x16" => "ground", "32x32" => "stop", "32x48" => "switch", "32x64" => "turn", "32x80" => "turn", "48x0" => "crease",
			"48x16" => "crease", "48x32" => "crease", "48x48" => "crease", "48x64" => "turn", "48x80" => "turn", "64x0" => "track", "64x16" => "track",
		];

		trace(tileMap.get(frameY + "x" + frameX));

		// horizontal and vertical tracks
		// these can probably be ignored, we really only need to care about turning
		if (frameX == 16 && frameY == 64)
			return "horizontal";
		if (frameX == 0 && frameY == 64)
			return "vertical";

		// turns, which we should turn halfway through
		if (frameX >= 64 && frameY >= 32)
		{
			// for these we actually need to read the player's current direction
			// this way we can determine which direction they are turning
			if (frameX == 64 && frameY == 32)
				if (player.playerCartDirection == "horizontal")
					return "counterclockwise";
				else
					return "clockwise";

			if (frameX == 64 && frameY == 48)
				if (player.playerCartDirection == "horizontal")
					return "clockwise";
				else
					return "counterclockwise";

			if (frameX == 80 && frameY == 32)
				if (player.playerCartDirection == "horizontal")
					return "clockwise";
				else
					return "counterclockwise";

			if (frameX == 80 && frameY == 48)
				if (player.playerCartDirection == "horizontal")
					return "counterclockwise";
				else
					return "clockwise";
		}

		return null;
	}

	// get the tile under a point
	// DEBUGGING NOTE: you can call this with FlxG.mouse.getPosition to hover and get the tile
	function tileUnderPoint(pointOverTile:FlxPoint)
	{
		var pixelSize = 16; // this could probably be determined from the tile map...

		// get the x and y - the "getInt" uses grid indexes, not pixels, so we have to divide by pixelSize
		var x = Math.floor((pointOverTile.x) / pixelSize);
		var y = Math.floor((pointOverTile.y) / pixelSize);

		// return levelLoadedLevel.l_Map.autoTiles[];
	}
}

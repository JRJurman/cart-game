package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.tile.FlxTilemap;
import ldtk.Level;

class GameLevel
{
	var ldtkProject:LdtkLevels;
	var gameState:FlxState;
	var gamePlayer:Player;

	public function new(state:FlxState, player:Player)
	{
		ldtkProject = new LdtkLevels();
		gameState = state;
		gamePlayer = player;
	}

	// https://github.com/deepnight/ldtk-haxe-api/blob/31ff2a75953e7f4ac93408d46cffe90de11313f4/samples/Flixel%20-%20Render%20tile%20layer/src/PlayState.hx
	public function loadLevel()
	{
		var container = new flixel.group.FlxSpriteGroup();
		gameState.add(container);
		gameState.add(gamePlayer);

		var levels = ldtkProject.all_levels;
		var loadedLevel = levels.Test_Level;

		// render the tiles on the game
		loadedLevel.l_Map.render(container);

		// set the tile properties
		FlxG.collide(gamePlayer, container.group, onPlayerCollision);

		for (player in loadedLevel.l_Entities.all_Player)
		{
			gamePlayer.setPosition(player.pixelX, player.pixelY);
		}
		// process switches
		for (gameSwitch in loadedLevel.l_Entities.all_Switch)
		{
		}
		// process targets
		for (target in loadedLevel.l_Entities.all_Target)
		{
		}
	}

	function onPlayerCollision(player, map)
	{
		trace(player);
		trace(map);
	}
}

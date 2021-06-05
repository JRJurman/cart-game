package;

import flixel.FlxState;
import ldtk.Level;

class PlayState extends FlxState
{
	var player:Player;
	var ldtkProject:LdtkLevels;

	// var level:Level;

	override public function create()
	{
		player = new Player(20, 20);
		add(player);

		ldtkProject = new LdtkLevels();
		// loadLevel();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	// https://github.com/deepnight/ldtk-haxe-api/blob/31ff2a75953e7f4ac93408d46cffe90de11313f4/samples/Flixel%20-%20Render%20tile%20layer/src/PlayState.hx
	function loadLevel()
	{
		var container = new flixel.group.FlxSpriteGroup();
		add(container);

		// var level = ldtkProject.all_levels.Test_Level;
		// level.l_Map_Int_Layer.render(container);
	}
}

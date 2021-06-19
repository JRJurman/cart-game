package;

import flixel.FlxG;
import flixel.FlxState;

class PlayState extends FlxState
{
	var player:Player;
	var level:GameLevel;

	override public function create()
	{
		player = new Player(this, 20, 20);

		FlxG.camera.follow(player, SCREEN_BY_SCREEN, 1);

		level = new GameLevel(this, player);
		level.loadLevels();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		level.update(elapsed);
	}
}

package;

import flixel.FlxState;

class PlayState extends FlxState
{
	var player:Player;
	var level:GameLevel;

	override public function create()
	{
		player = new Player(20, 20);

		level = new GameLevel(this, player);
		level.loadLevel();

		super.create();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		level.update();
	}
}

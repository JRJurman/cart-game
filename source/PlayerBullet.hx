package;

import flixel.FlxSprite;

class PlayerBullet extends FlxSprite
{
	// constructor for a new target
	public function new()
	{
		super(-10, -10);

		loadGraphic(AssetPaths.bullet__png, true, 8, 8);
		exists = false;
	}

	public function onHit()
	{
		kill();
	}
}

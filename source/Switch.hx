package;

import flixel.group.FlxSpriteGroup;

class Switch extends TargetSprite
{
	var levelContainer:FlxSpriteGroup;
	var loadedLevel:String;
	var levelToLoad:String;
	var gameLevel:GameLevel;

	// constructor for a new target
	public function new(x:Float = 0, y:Float = 0, levelContainer:FlxSpriteGroup, loadedLevel:String, levelToLoad:String, gameLevel:GameLevel)
	{
		super(x, y);
		drag.x = drag.y = 0;

		loadGraphic(AssetPaths.switch__png, true, 16, 16);

		this.loadedLevel = loadedLevel;
		this.levelToLoad = levelToLoad;
		this.levelContainer = levelContainer;
		this.gameLevel = gameLevel;
	}

	override public function onHit()
	{
		flipX = !flipX;
		gameLevel.renderOtherLevel(levelContainer, levelToLoad);

		// swap the level loaded with the level to load, so we can switch back and forth
		var newLevelLoaded = levelToLoad;
		var newLevelToLoad = loadedLevel;
		this.levelToLoad = newLevelToLoad;
		this.loadedLevel = newLevelLoaded;
	}
}

package;

class Target extends TargetSprite
{
	// constructor for a new target
	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		loadGraphic(AssetPaths.flower__png, true, 16, 16);
	}

	override public function onHit()
	{
		kill();
	}
}

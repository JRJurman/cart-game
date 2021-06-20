package;

class WorldCoord
{
	public var x:Int = 0;
	public var y:Int = 0;

	public function new(x, y)
	{
		this.x = x;
		this.y = y;
	}

	/**
	 * Unique String value of the WorldCoord
	 */
	public function hash()
	{
		return x + "-" + y;
	}
}

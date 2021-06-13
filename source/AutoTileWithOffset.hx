package;

import ldtk.Layer_AutoLayer.AutoTile;

class AutoTileWithOffset
{
	public var autoTile:AutoTile;
	public var offset:WorldCoord;

	public static function withOffset(offset:WorldCoord)
	{
		return function autoTileWithOffset(autoTile:AutoTile)
		{
			return new AutoTileWithOffset(autoTile, offset);
		}
	}

	public function new(autoTile:AutoTile, offset:WorldCoord)
	{
		this.autoTile = autoTile;
		this.offset = offset;
	}

	public function getX()
	{
		return autoTile.renderX + offset.x;
	}

	public function getY()
	{
		return autoTile.renderY + offset.y;
	}
}

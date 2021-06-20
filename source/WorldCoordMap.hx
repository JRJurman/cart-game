package;

import js.lib.Map;

class WorldCoordMap<T>
{
	var internalMap:Map<String, T>;
	var worldCoords:Array<WorldCoord>;

	public function new()
	{
		internalMap = new Map<String, T>();
		worldCoords = new Array<WorldCoord>();
	}

	public function set(coord:WorldCoord, value:T)
	{
		internalMap.set(coord.hash(), value);
		worldCoords.push(coord);
	}

	public function get(coord:WorldCoord)
	{
		return internalMap.get(coord.hash());
	}

	public function getCoords()
	{
		return worldCoords;
	}

	public function getValues()
	{
		return internalMap.values();
	}
}

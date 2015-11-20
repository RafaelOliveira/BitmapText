package;

class Rect
{
	public var x:Int;
	public var y:Int;
	public var width:Int;
	public var height:Int;
	
	public function new(x:Int, y:Int, width:Int, height:Int) 
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	public function pointInside(x:Int, y:Int):Bool
	{
		if (x > this.x && x < (this.x + this.width)
			&& y > this.y && y < (this.y + this.height))
			return true;
		else
			return false;
	}
}
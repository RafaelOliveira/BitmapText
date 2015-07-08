package bitmapText;

import haxe.Utf8;
import kha.Blob;
import kha.Color;
import kha.Image;
import kha.Loader;
import kha.math.Vector2;

typedef Font = {
	var size:Int;
	var lineHeight:Int;
	var spaceWidth:Int;
	var image:Image;
	var letters:Map<Int, Letter>;
}

typedef Letter = {
	var id:Int;
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
	var xoffset:Int;
	var yoffset:Int;
	var xadvance:Int;
	var kernings:Map<Int, Int>;
}

typedef Line = {
	var text:String;
	var width:Int;
}

typedef BitmapTextOptions = {
	@:optional var size:Int;
	@:optional var lineHeight:Int;
	@:optional var color:Color;
	@:optional var bgColor:Color;
	@:optional var align:BitmapTextAlign;
}

class BitmapText
{	
	static var fontCache:Map<String, Font>;
	static var spaceCharCode:Int = " ".charCodeAt(0);
	
	var font:Font;
	
	/** Image where the text is rendered */
	public var image:Image;
	
	/** 
	 * The text to be rendered. Call update() 
	 * after change the text
	 */
	public var text:String;
	
	/** 
	 * The size of the text. The default value
	 * is the value from the font file. Changing
	 * this updates the scaling of the text
	 */
	public var size(default, set):Int;
	var _size:Int;
	
	public var lineHeight(get, set):Int;
	
	/** Color tint applied to the text */ 
	public var color:Color = Color.White;
	
	/** If should use a background color */
	public var useBgColor:Bool = false;
	
	/** Background Color */
	public var bgColor:Color = Color.Black;
	
	/** Align of the text inside the image */
	public var align = BitmapTextAlign.Left;
	
	/** 
	 * The cursor of the text. After the rendering it points
	 * to the position after the last letter
	 */
	public var cursor(default, null):Vector2;
	
	/** Factor in which the text increase or decrease in size */
	public var sizeFactor:Float = 0.01;
	
	/** Scale based in the actual size of the font */
	var scale:Float = 1;
	
	public function new(text:String, fontName:String, width:Int, height:Int, options:BitmapTextOptions = null)
	{
		if (fontCache != null && fontCache.exists(fontName))
		{
			this.text = text;
			font = fontCache.get(fontName);
			image = Image.createRenderTarget(width, height);
			cursor = new Vector2();
			
			if (options != null)
			{
				// calculates the scaling for the given size
				// or uses the default scale
				if (options.size != null)
					size = options.size;
				else
					_size = font.size;
					
				if (options.lineHeight != null)
					lineHeight = options.lineHeight;
					
				if (options.color != null)
					color = options.color;
					
				if (options.bgColor != null)
				{
					useBgColor = true;
					bgColor = options.bgColor;
				}
					
				if (options.align != null)	
				align = options.align;				
			}
			else
				_size = font.size;			
			
			update();
		}
		else
			trace('font $fontName not loaded');
	}
	
	/**
	 * Loads a font and stores its data on the font cache
	 */
	public static function loadFont(fontName:String) 
	{
		var image = Loader.the.getImage('${fontName}.png');
		var data = Loader.the.getBlob('${fontName}.fnt');
		
		processFont(fontName, image, data);
	}
	
	/**
	 * Reads the font data
	 */
	inline static function processFont(name:String, image:Image, data:Blob)
	{
		var letters = new Map<Int, Letter>();
		
		var xml = new haxe.xml.Fast(Xml.parse(data.toString()).firstElement());
		
		var spaceWidth = 8;
		
		var chars = xml.node.chars;
		for (char in chars.nodes.char)
		{
			var letter:Letter = {
				id: Std.parseInt(char.att.id),
				x: Std.parseInt(char.att.x),
				y: Std.parseInt(char.att.y),
				width: Std.parseInt(char.att.width),
				height: Std.parseInt(char.att.height),
				xoffset: Std.parseInt(char.att.xoffset),
				yoffset: Std.parseInt(char.att.yoffset),
				xadvance: Std.parseInt(char.att.xadvance),
				kernings: new Map<Int, Int>()
			};
			
			if (letter.id == spaceCharCode)
				spaceWidth = letter.xadvance;
			
			letters.set(letter.id, letter);
		}
		
		if (xml.hasNode.kernings)
		{
			var kernings = xml.node.kernings;		
			var letter:Letter;
			for (kerning in kernings.nodes.kerning)
			{
				letter = letters.get(Std.parseInt(kerning.att.first));
				letter.kernings.set(Std.parseInt(kerning.att.second), Std.parseInt(kerning.att.amount));
			}
		}
		
		if (fontCache == null)
			fontCache = new Map<String, Font>();
			
		var font:Font = { 
			size: Std.parseInt(xml.node.info.att.size),
			lineHeight: Std.parseInt(xml.node.common.att.lineHeight),
			spaceWidth: spaceWidth,
			image: image, 
			letters: letters
		};
		
		fontCache.set(name, font);
	}
	
	function set_size(value:Int):Int 
	{
		var diffScale = Math.abs(font.size - value) * sizeFactor;
		if (value > font.size)
			scale = 1 + diffScale;
		else
			scale = 1 - diffScale;
			
		_size = value;
		
		return _size;
	}
	
	function get_lineHeight():Int 
	{
		return font.lineHeight;
	}
	
	function set_lineHeight(value:Int):Int 
	{
		return font.lineHeight = value;
	}
	
	/**
	 * Draws the text on in the image
	 * Call this function after update the text parameters
	 */
	public function update()
	{
		var charCode:Int;
		var charCodeNext:Int;
		var letter:Letter;
		
		cursor.x = 0;
		cursor.y = 0;
		
		var lines = processText();
				
		if (useBgColor)
			image.g2.begin(true, bgColor);
		else
			image.g2.begin(true, Color.fromFloats(0, 0, 0, 0));		
		
		image.g2.color = color;
		
		for (line in lines)
		{
			switch(align)
			{
				case Left: cursor.x = 0;
				case Right: cursor.x = image.width - line.width;
				case Center: cursor.x = (image.width / 2) - (line.width / 2);
			}			
			
			for (i in 0...line.text.length)
			{
				charCode = Utf8.charCodeAt(line.text.charAt(i), 0);
				letter = font.letters.get(charCode);
				
				if (letter != null)
				{
					if (letter.id != spaceCharCode)
					{
						image.g2.drawScaledSubImage(
							font.image, 
							letter.x, 
							letter.y, 
							letter.width, 
							letter.height, 
							cursor.x + (letter.xoffset * scale), 
							cursor.y + (letter.yoffset * scale),
							letter.width * scale,
							letter.height * scale);
						
						// checking kerning	
						if (i != (line.text.length - 1))
						{
							charCodeNext = Utf8.charCodeAt(line.text.charAt(i + 1), 0);
							if (letter.kernings.exists(charCodeNext))
							{
								cursor.x += letter.kernings.get(charCodeNext) * scale;
								
								#if debug
								trace('kerning ${letter.id} ${charCodeNext}');
								#end
							}
						}
						
						cursor.x += letter.xadvance * scale;
					}
					else
						cursor.x += font.spaceWidth * scale;
				}
			}
			
			cursor.y += font.lineHeight * scale;
		}
		
		image.g2.end();
	}
	
	/**
	 * Split the text in lines, observing the width
	 * of the image, and how much text fits in each line
	 */
	function processText():Array<Line>
	{
		var lines = new Array<Line>();
		
		// split the text in words 
		// with spaces between the words
		var words = text.split(' ');
		var wordsLenght = words.length;
		var j = 1;
		for (i in 0...wordsLenght)
		{
			if (i != (wordsLenght - 1))
			{
				words.insert(i + j, ' ');
				j++;
			}
		}
		
		var char:String;
		var charCode:Int;
		var letter:Letter;
		
		var lineText = '';
		var widthLineText = 0;
		
		var tempWord = '';
		var widthTempWord = 0;
		
		var nextLine = false;
		var lastWord = false;
		
		for (word in words)
		{
			if (word == words[words.length - 1])
				lastWord = true;
			
			if (word != ' ')
			{
				for (i in 0...word.length)
				{
					char = word.charAt(i);
					charCode = Utf8.charCodeAt(char, 0);
					
					letter = font.letters.get(charCode);	
					if (letter != null)
					{
						tempWord += char;
						widthTempWord += letter.xadvance;
					}
				}
			}
			else
			{
				tempWord = ' ';
				widthTempWord = font.spaceWidth;
			}
			
			if ((widthLineText + widthTempWord) < image.width)
			{
				lineText += tempWord;
				widthLineText += widthTempWord;				
			}
			else
				nextLine = true;
			
			if (nextLine || lastWord)
			{
				lines.push({ text: lineText, width: widthLineText });
				
				if (!lastWord)
				{
					if (tempWord != ' ')
					{
						lineText = tempWord;
						widthLineText = widthTempWord;
						
						// checking if there is space in the end of the line
						removeSpaceLastLine(lines);
					}
					else
					{
						lineText = '';
						widthLineText = 0;
					}
					
					nextLine = false;
				}
				else if (nextLine)
				{
					// checking if there is space in the end of the line
					removeSpaceLastLine(lines);
					
					lines.push({ text: tempWord, width: widthTempWord });
				}
			}
			
			tempWord = '';
			widthTempWord = 0;
		}
		
		return lines;
	}
	
	function removeSpaceLastLine(lines:Array<Line>)
	{
		var lastLine = lines[lines.length - 1];
		if (lastLine.text.charAt(lastLine.text.length - 1) == ' ')
		{
			lastLine.text = lastLine.text.substr(0, lastLine.text.length - 1);
			lastLine.width -= font.spaceWidth;
		}
	}
}
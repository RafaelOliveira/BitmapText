package;

import kha.Color;
import kha.Framebuffer;
import kha.Game;
import kha.Image;
import kha.Loader;
import kha.Rectangle;
import kha.Scaler;
import kha.Sys;
import kha.LoadingScreen;
import kha.Configuration;
import kha.graphics2.Graphics;
import bitmapText.BitmapText;
import bitmapText.BitmapTextAlign;

class Example extends Game 
{
	var backbuffer:Image;
	var g:Graphics;
	
	// buttons
	var btText:Image;	
	var btColor:Image;
	var btAlignment:Image;
	
	// area for checking if a button was clicked
	var areaBtAlignment:Rectangle;
	var areaBtColor:Rectangle;
	var areaBtText:Rectangle;
	
	// text	
	var text1:BitmapText;
	var text2:BitmapText;
	var text3:BitmapText;
	
	var sampleText1:String;
	var sampleText2:String;
	
	var colors = [ Color.fromValue(0x104e8b), Color.Black, Color.Blue, Color.Cyan, Color.Green, 
				   Color.Magenta, Color.Orange, Color.Pink, Color.Purple, Color.Red, Color.White, Color.Yellow ];
	
	var indexColor:Int;
	var indexText:Int;
	
	var firstTime = true;
	
	public function new() 
	{
		super("Example", false);
	}
	
	override public function init():Void 
	{
		super.init();		
		
		backbuffer = Image.createRenderTarget(800, 600);
		g = backbuffer.g2;
		
		#if js
		// this isn't working. Needs to change manually in kha.graphics4.Graphics2.jx
		// https://github.com/KTXSoftware/Kha/issues/101
		cast(backbuffer.g2, kha.graphics4.Graphics2).setBilinearFiltering(true);
		#end
		
		sampleText1 = 'Kha is a low level SDK for building games and media ' +
		'applications in a portable way, based on Haxe and GLSL.';
		
		sampleText2 = 'With Kha you can build applications and games that ' +
		'run with native performance in different target devices.';
		
		indexColor = 0;
		indexText = -1;
		
		areaBtText = new Rectangle(15, 544, 121, 41);
		areaBtColor = new Rectangle(151, 544, 130, 41);
		areaBtAlignment = new Rectangle(296, 544, 171, 41);
		
		Configuration.setScreen(new LoadingScreen());
		Loader.the.loadRoom("base", roomLoaded);
	}
	
	function roomLoaded():Void
	{
		// loading the fonts to the cache
		
		BitmapText.loadFont('Bevan');
		BitmapText.loadFont('Oswald-Regular');
		BitmapText.loadFont('Pacifico');
		
		// creating some buttons
		
		btAlignment = Loader.the.getImage('btAlignment');
		btColor = Loader.the.getImage('btColor');
		btText = Loader.the.getImage('btText');
		
		// creating the bitmaptexts
		
		text1 = new BitmapText('The quick brown fox jumps over the lazy dog', 'Bevan', 550, 120, { lineHeight: 50 });
		
		text2 = new BitmapText('Some text to show a BitmapText with a background color', 'Oswald-Regular', 550, 100,
		{
			color: Color.Black,
			bgColor: Color.fromFloats(0.9, 0.9, 0.9), 
			align: BitmapTextAlign.Center,
			lineHeight: 45
		});
		
		text3 = new BitmapText(sampleText1, 'Pacifico', 710, 180, 
		{ 
			color: colors[indexColor],
			lineHeight: 55 			
		});
		
		Configuration.setScreen(this);
	}
	
	#if cpp
	// temporary fix for cpp
	// BitmapText render the text when is created
	// but in cpp it needs to render again (only one time) after the roomLoaded() function
	override public function update():Void 
	{
		if (firstTime)
		{
			text1.update();
			text2.update();
			text3.update();
			firstTime = false;
		}		
	}
	#end
	
	override public function render(frame:Framebuffer):Void 
	{
		g.begin(true, Color.fromValue(0x87cefa));
		
		g.drawImage(text1.image, 125, 30);
		g.drawImage(text2.image, 125, 175);
		g.drawImage(text3.image, 40, 320);
		
		g.drawImage(btText, areaBtText.x, areaBtText.y);
		g.drawImage(btColor, areaBtColor.x, areaBtColor.y);
		g.drawImage(btAlignment, areaBtAlignment.x, areaBtAlignment.y);
		
		g.end();
		
		startRender(frame);
		Scaler.scale(backbuffer, frame, Sys.screenRotation);
		endRender(frame);
	}
		
	override public function mouseDown(x:Int, y:Int):Void 
	{	
		// Check the buttons clicked
		
		if (checkButtonClicked(areaBtText, x, y))
		{
			indexText *= -1;
			
			if (indexText == -1)
				text3.text = sampleText1;
			else
				text3.text = sampleText2;
				
			text3.update();			
		}
		else if (checkButtonClicked(areaBtColor, x, y))
		{
			indexColor++;
			if (indexColor == colors.length)
				indexColor = 0;
				
			text3.color = colors[indexColor];
			text3.update();
		}
		else if (checkButtonClicked(areaBtAlignment, x, y))
		{
			switch(text3.align)
			{
				case Left: text3.align = BitmapTextAlign.Center;
				case Center: text3.align = BitmapTextAlign.Right;
				case Right: text3.align = BitmapTextAlign.Left;
			}
			
			text3.update();
		}
	}
	
	function checkButtonClicked(rect:Rectangle, x:Int, y:Int)
	{
		if (x > rect.x && x < (rect.x + rect.width)
			&& y > rect.y && y < (rect.y + rect.height))
			return true;
		else
			return false;
	}
}

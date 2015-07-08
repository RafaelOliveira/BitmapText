## BitmapText
A bitmap text render for Kha based on Angel Code format

## How to use
Load the fonts to the chache
```
BitmapText.loadFont('font-name');
```

BitmapText uses a image to render the text. This image can be used later
to render the text to the Framebuffer

Create the bitmaptext specifying the font name, text and size of the image
```
var text = new BitmapText('The quick brown fox jumps over the lazy dog', 'Bevan', 550, 120);
```

It's possible to pass some initial render parameters
````
var text2 = new BitmapText('The quick brown fox jumps over the lazy dog', 'Pacifico', 550, 100,  
{  
	color: Color.Black,  
	bgColor: Color.fromFloats(0.9, 0.9, 0.9),  
	align: BitmapTextAlign.Center,  
	lineHeight: 45  
});
```

If you change some parameters later, use
```
text.update();  
```
To render the text again on the image.

With this you can render the text using it's image. 
```
g.drawImage(text1.image, 125, 30);
```

package com.litl.tv.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	public class BitmapGrabber extends Sprite
	{
		
		
		public function BitmapGrabber() 
		{
		}
		
		public static function snapClip( clip:DisplayObject ):Bitmap
		{
			var bounds:Rectangle = clip.getBounds( clip );
			var bitmap:BitmapData = new BitmapData( int( bounds.width + 0.5 ), int( bounds.height + 0.5 ), true, 0 );
			bitmap.draw( clip, new Matrix(1,0,0,1,-bounds.x,-bounds.y) );
			var snappedImage:Bitmap = new Bitmap(bitmap);
			return snappedImage;
		}
	}
}
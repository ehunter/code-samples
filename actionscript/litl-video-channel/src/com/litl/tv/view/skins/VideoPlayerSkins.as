package com.litl.tv.view.skins
{
	import com.litl.tv.view.skins.*;
	
	/**
	 * <p>This is the default skin for litl controls. It embeds the defaultSkin.css file, and is automatically used in StyleManager.</p>
	 * @author litl
	 *
	 */
	public class VideoPlayerSkins
	{
		
		public static function getSkinCSS():Class {
			return DefaultSkinCSS;
		}
		
		/** This array ensures all the skin classes are compiled with the swf. */
		private var required:Array = [ ThumbnailListBackground ];
		
	}
	
}

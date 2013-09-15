package com.litl.tv.model.data
{
	import flash.utils.Dictionary;
	
	public class ShowData
	{
		
		
		public var _title:String = null;
		public var _thumbnailUrl:String = null;
		public var _description:String = null;
		public var _number:String = null;
		public var _videoUrl:String = null;
		
		//public var tagdict:Dictionary = new Dictionary();
		
		public function ShowData(title:String, description:String, number:String, videoUrl:String, thumbnailUrl:String )
		{
			
			this._title = title;
			this._thumbnailUrl = thumbnailUrl;
			this._description = description;
			this._number = number;
			this._videoUrl = videoUrl;
			
			
		}
		
	}
}

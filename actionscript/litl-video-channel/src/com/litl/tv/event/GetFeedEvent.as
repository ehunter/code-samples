package com.litl.tv.event
{
	import flash.events.Event;
	
	public class GetFeedEvent extends Event
	{
		public static const GET_FEED:String = "getFeed";
		
		public var feedType:String;
		
		public function GetFeedEvent(type:String, feedType:String) {
			super(type, true, true);
			
			this.feedType = feedType;
		}
		
		override public function clone():Event {
			return new GetFeedEvent(type, feedType);
		}
	}
}
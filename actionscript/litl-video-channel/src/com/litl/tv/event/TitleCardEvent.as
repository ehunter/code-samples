package com.litl.tv.event
{
	import flash.events.Event;
	
	public class TitleCardEvent extends Event
	{
		public static const IMAGE_READY:String = "imageReady";

		
		public function TitleCardEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type);
			//_requestId = requestId;
		}
		
		public override function clone():Event {
			return new TitleCardEvent( type, bubbles, cancelable );
		}
		
		public override function toString():String {
			return formatToString( "TitleCardEvent", "type", "_event", "bubbles", "cancelable" );
		}
		
	}
}

package com.litl.tv.event
{
    import flash.events.Event;

    public class ExternalAssetsFeedEvent extends Event
    {
        public static const IMAGE_DATA_RECEIVED:String = "imageDataReceived";
        public static const IMAGE_DATA_PARSED:String = "imageDataParsed";

        protected var _feed:Array;

        public function ExternalAssetsFeedEvent(type:String, feed:Array, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type);
            _feed = feed;
            //_requestId = requestId;
        }

        public override function clone():Event {
            return new ExternalAssetsFeedEvent(type, _feed, bubbles, cancelable);
        }

        public override function toString():String {
            return formatToString("LabelEvent", "type", "_event", "bubbles", "cancelable");
        }

        public function get feed():Array {
            return _feed;
        }

    }
}

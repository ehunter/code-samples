package com.litl.tv.event
{
    import flash.events.Event;

    public class FeedUpdateEvent extends Event
    {
        public static const FEED_UPDATE:String = "feedUpdate";
        public static const CURRENT_DATA_UPDATE:String = "episodeDataUpdate";

        protected var _feed:Array;

        public function FeedUpdateEvent(type:String, feed:Array, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type);
            _feed = feed;
        }

        override public function clone():Event {
            return new FeedUpdateEvent(type, _feed, bubbles, cancelable);
        }

        public function get feed():Array {
            return _feed;
        }
    }
}

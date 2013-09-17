package com.litl.weather.events
{
    import flash.events.Event;

    public class OpenUrlEvent extends Event
    {
        public static const OPEN_URL:String = "openUrl";
        protected var _url:String;

        public function OpenUrlEvent(type:String, url:String, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
            _url = url;
        }

        override public function clone():Event {
            return new OpenUrlEvent(type, _url, bubbles, cancelable);
        }

        public function get url():String {
            return _url;
        }
    }
}

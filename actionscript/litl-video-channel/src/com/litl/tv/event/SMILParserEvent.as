package com.litl.tv.event
{
    import flash.events.Event;

    public class SMILParserEvent extends Event
    {
        public static const PARSE_COMPLETE:String = "conversionComplete";
        public static const ERROR_LOADING_URL:String = "errorLoadingUrl";

        protected var _rtmpUrl:String;

        public function SMILParserEvent(type:String, rtmpUrl:String, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type);
            _rtmpUrl = rtmpUrl;
        }

        override public function clone():Event {
            return new SMILParserEvent(type, _rtmpUrl, bubbles, cancelable);
        }

        public function get rtmpUrl():String {
            return _rtmpUrl;
        }
    }
}

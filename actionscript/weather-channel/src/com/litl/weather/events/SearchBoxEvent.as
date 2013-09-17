package com.litl.weather.events
{
    import flash.events.Event;

    public class SearchBoxEvent extends Event
    {
        public static const LOCATION_SELECTED:String = "onLocationSelected";
        protected var _zip:String;
        protected var _city:String;
        protected var _searchCode:String;

        public function SearchBoxEvent(type:String, city:String, searchCode:String, zip:String, bubbles:Boolean = false, cancelable:Boolean = false) {

            super(type, bubbles, cancelable);
            _zip = zip;
            _city = city;
            _searchCode = searchCode;
        }

        public function get zip():String {
            return _zip;
        }

        public function get city():String {
            return _city;
        }

        public function get searchCode():String {
            return _searchCode;
        }

        override public function clone():Event {
            return new SearchBoxEvent(type, city, searchCode, zip, bubbles, cancelable);
        }
    }
}

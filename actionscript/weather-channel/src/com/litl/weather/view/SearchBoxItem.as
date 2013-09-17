package com.litl.weather.view
{
    import flash.display.MovieClip;
    import flash.text.TextField;

    /**
     * @author mkeefe
     */
    public class SearchBoxItem extends MovieClip
    {

        private var _id:String = null;
        private var _pos:int = 0;
        private var _loc:String = null;
        private var _searchCode:String;
        public var searchBoxItemRoot:SearchBoxItemRoot;

        public function SearchBoxItem() {
            searchBoxItemRoot = new SearchBoxItemRoot();
            addChild(searchBoxItemRoot);
        }

        public function get background():MovieClip {
            return searchBoxItemRoot.bg;
        }

        public function get searchCode():String {
            return _searchCode;
        }

        public function set searchCode(value:String):void {
            _searchCode = value;
        }

        public function get id():String {
            return _id;
        }

        public function set id(s:String):void {
            _id = s;
        }

        public function get pos():int {
            return _pos;
        }

        public function set pos(n:int):void {
            _pos = n;
        }

        public function get location():String {
            return _loc;
        }

        public function set location(s:String):void {
            _loc = s;
            searchBoxItemRoot.loc_txt.text = _loc;
        }

        override public function toString():String {
            super.toString();
            return "Location (" + id + ") : " + location;
        }
    }
}

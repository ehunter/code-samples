package com.litl.weather.view
{
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;

    /**
     * @author mkeefe
     */
    public class SearchBox extends MovieClip
    {
        public var items:Array = [];

        private var _selectedID:int = -1;
        private var _selectedItem:SearchBoxItem;
        public var searchBoxRoot:SearchBoxRoot;

        public function SearchBox() {
            searchBoxRoot = new SearchBoxRoot();
            addChild(searchBoxRoot);
        }

        public function init():void {

        }

        public function get selectedItem():SearchBoxItem {
            return _selectedItem;
        }

        public function selectItem(id:int):void {
            _selectedID = id;

            if (_selectedItem != null) {
                _selectedItem.background.visible = false;
            }

            _selectedItem = SearchBoxItem(items[_selectedID]);
            _selectedItem.background.visible = true;
        }

        public function prevItem():void {
            _selectedID++;

            if (_selectedID > (items.length - 1)) {
                _selectedID = 0;
            }

            selectItem(_selectedID);
        }

        public function nextItem():void {
            _selectedID--;

            if (_selectedID < 0) {
                _selectedID = (items.length - 1);
            }

            selectItem(_selectedID);
        }

        public function rollOver(evt:MouseEvent):void {
            selectItem(SearchBoxItem(evt.currentTarget).pos);
        }

        public function rollOut(evt:MouseEvent):void {
            selectItem(SearchBoxItem(evt.currentTarget).pos);
        }

        public function click(evt:MouseEvent):void {
            dispatchEvent(new Event("selectLocation"));
        }

    }
}

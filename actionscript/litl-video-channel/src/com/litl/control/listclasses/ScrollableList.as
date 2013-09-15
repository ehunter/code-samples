/* Copyright (c) 2010 litl, LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
package com.litl.control.listclasses
{
    import com.litl.control.ControlBase;
    import com.litl.event.ItemErrorEvent;
    import com.litl.event.ItemSelectEvent;
    import com.litl.sdk.util.Tween;

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.utils.Dictionary;

    /**
     * Dispatched when the currently selected item has changed.
     */
    [Event(name="select", type="flash.events.Event")]

    /**
     * Dispatched when an item renderer generates an io error. For example, when an image won't load.
     */
    [Event(name="ioError", type="com.litl.event.ItemErrorEvent")]

    [Event(name="scrollPositionSet", type="com.litl.event.ItemSelectEvent")]

    /**
     * Flexible, scrollable, horizontal or vertical list.
     * @author litl
     *
     */
    public class ScrollableList extends ControlBase
    {
        private static const ITEM_ENABLED:uint = 0;
        private static const ITEM_DISABLED:uint = 1;

        protected var _itemSize:Number = 100;
        protected var _itemRenderer:Class = TextItemRenderer;
        private var _itemRendererChanged:Boolean = false;
        private var _horizontal:Boolean = false;
        private var _horizontalChanged:Boolean = false;
        private var _transitionSpeed:Number = 0.3;
        private var _wrapAround:Boolean = false;
        private var _loadAhead:int = 0;
        private var _useCache:Boolean = true;
        private var _highlightCurrentItem:Boolean = false;
        private var _centerOnScrollPosition:Boolean = true;
        private var _roundScrollPosition:Boolean = true;

        private var ITEM_SPACING:Number = 4;
        private var PADDING_LEFT:Number = 8;

        protected var content:Sprite;
        protected var contentMask:Sprite;
        protected var background:Sprite;

        protected var _dataProvider:Array;
        public var _actualScrollPosition:Number = 0;
        private var _scrollPosition:Number = 0;
        private var _setScrollPosition:Number = 0;
        private var _scrollPositionChanged:Boolean = false;
        private var _selectedIndex:int = -1;
        protected var _last:Number;
        protected var _lastItems:Number;

        protected var visibleItems:Array;
        protected var imageCache:ImageCache;

        protected var itemStates:Array;
        protected var selectedData:Object;

        public function get roundScrollPosition():Boolean {
            return _roundScrollPosition;
        }

        public function set roundScrollPosition(value:Boolean):void {
            _roundScrollPosition = value;
        }

        public function get centerOnScrollPosition():Boolean {
            return _centerOnScrollPosition;
        }

        public function set centerOnScrollPosition(value:Boolean):void {
            _centerOnScrollPosition = value;
        }

        public function get highlightCurrentItem():Boolean {
            return _highlightCurrentItem;
        }

        public function set highlightCurrentItem(value:Boolean):void {
            _highlightCurrentItem = value;
        }

        public function get selectedIndex():int {
            return _selectedIndex;
        }

        public function set selectedIndex(value:int):void {
            _selectedIndex = Math.min(_dataProvider ? _dataProvider.length - 1 : 0, Math.max(0, value));
            selectedItem = (_dataProvider && dataProvider.length > 0) ? _dataProvider[value] : null;
        }

        public function set selectedItem(c:Object):void {
            var changed:Boolean = c && selectedData != c;
            selectedData = c;

            if (_dataProvider)
                _selectedIndex = _dataProvider.indexOf(c);

            if (changed) {
                updateItems(null, true);
            }

            if (_dataProvider && c != null)
                dispatchEvent(new Event(Event.SELECT));
        }

        public function get selectedItem():Object {
            return selectedData;
        }

        public function itemIsReady(index:int, initiateLoad:Boolean = false):Boolean {
            if (_dataProvider == null)
                return false;

            var wrappedIndex:int = index;

            if (index < 0)
                wrappedIndex = _dataProvider.length + index;
            var index2:int = _wrapAround ? wrappedIndex % _dataProvider.length : index;
            var item:Object = _dataProvider[index2];

            if (visibleItems)
                for (var i:int = 0; i < visibleItems.length; i++) {
                    if (visibleItems[i].data == item)
                        return visibleItems[i].isReady;
                }

            // At this point the item isn't loading, so we should initiate it if requested.
            if (initiateLoad && Math.abs(index2 - _actualScrollPosition) < _loadAhead) {
                var c:IItemRenderer = createItem();
                visibleItems.push(c);

                DisplayObject(c).visible = false;

                c.data = item;

                if ("validateNow" in c)
                    c["validateNow"]();

                return c.isReady;
            }

            return false;
        }

        public function get useCache():Boolean {
            return _useCache;
        }

        public function set useCache(value:Boolean):void {
            _useCache = value;

            if (!_useCache) {
                if (imageCache)
                    imageCache.clear();
            }

            if (visibleItems)
                for (var i:int = 0; i < visibleItems.length; i++) {
                    if ("cache" in visibleItems[i])
                        visibleItems[i]["cache"] = _useCache ? imageCache : null;
                }
        }

        private var _cacheSize:int = 20;

        public function set cacheSize(v:int):void {
            _cacheSize = v;

            if (imageCache)
                imageCache.imageLimit = v;
        }

        public function get cacheSize():int {
            return _cacheSize;
        }

        public function get wrapAround():Boolean {
            return _wrapAround;
        }

        public function set wrapAround(value:Boolean):void {
            _wrapAround = value;
        }

        public function get transitionSpeed():Number {
            return _transitionSpeed;
        }

        public function set transitionSpeed(value:Number):void {
            _transitionSpeed = value;
        }

        public function get loadAhead():int {
            return _loadAhead;
        }

        public function set loadAhead(value:int):void {
            _loadAhead = value;
            invalidateLayout();
        }

        public function get horizontal():Boolean {
            return _horizontal;
        }

        public function set horizontal(value:Boolean):void {
            _horizontalChanged = _horizontalChanged || (_horizontal != value);
            _horizontal = value;
            invalidateProperties();
        }

        public function get itemRenderer():Class {
            return _itemRenderer;
        }

        public function set itemRenderer(value:Class):void {
            _itemRendererChanged = _itemRendererChanged || (value != _itemRenderer);
            _itemRenderer = value;
            invalidateProperties();
        }

        public function get itemSize():Number {
            return _itemSize;
        }

        public function set itemSize(value:Number):void {
            _itemSize = value;
            refresh();
        }

        override public function setSize(w:Number, h:Number):void {
            _width = w;
            _height = h;
            // Force a refresh on the next layout.
            _last = Number.NaN;
            _lastItems = Number.NaN;
            invalidateLayout();
        }

        /**
         * Cause the list to recheck the dataProvider for changes and create/remove items
         * if necessary.
         *
         */
        public function refresh():void {
            // Force a refresh on the next layout.
            _last = Number.NaN;
            _lastItems = Number.NaN;

            invalidateLayout();
        }

        override protected function createChildren():void {
            content = new Sprite();
            addChild(content);
            contentMask = new Sprite();
            addChild(contentMask);
            content.mask = contentMask;

            imageCache = new ImageCache();
            imageCache.imageLimit = _cacheSize;
        }

        override protected function updateProperties():void {
            if (_itemRendererChanged) {
                _itemRendererChanged = false;

                while (visibleItems && visibleItems.length > 0) {
                    var pr:IItemRenderer = visibleItems.pop() as IItemRenderer;
                    var dr:DisplayObject = pr as DisplayObject;

                    if (dr && content.contains(dr))
                        content.removeChild(dr);

                    if (pr) {
                        pr.removeEventListener(IOErrorEvent.IO_ERROR, onItemIOErrorEvent);
                        pr.removeEventListener(Event.SELECT, onSelect);
                    }
                }

                invalidateLayout();
            }

            if (_horizontalChanged) {
                _horizontalChanged = false;
                invalidateLayout();
            }

            if (_scrollPositionChanged) {
                _scrollPositionChanged = false;
                var sp:Number = _setScrollPosition;
                var v:Number = Math.min(maxScroll, Math.max(0, _setScrollPosition));

                if (_transitionSpeed > 0) {
                    var len:int = _dataProvider ? _dataProvider.length : 0;

                    // Handle wrapAround case:
                    // moving forward from the last item should scroll forward to the first item
                    // and moving backward from the first item should scroll backward to the last item
                    if (sp < 0 && _wrapAround) {
                        _scrollPosition = len + sp;

                        // Wrap around the actual scrollpos, so we approach the new pos from above
                        if (_actualScrollPosition < len)
                            _actualScrollPosition += len;
                    }
                    else if (sp >= len && _wrapAround) {
                        _scrollPosition = sp - len;

                        // Wrap around the actual scrollpos, so we approach the new pos from below
                        if (_actualScrollPosition > -len)
                            _actualScrollPosition -= len;
                    }

                    // Set up a new tween
                    if (_actualScrollPosition != v) {
                        var tween:Tween = Tween.tweenTo(this, _transitionSpeed, { _actualScrollPosition: _scrollPosition }, quadraticEaseOut);
                        tween.addEventListener(Event.CHANGE, updateItems, false, 0, true);
                    }
                }
                else {
                    if (_actualScrollPosition != v) {
                        _actualScrollPosition = v;
                        updateItems();
                    }
                }
            }

        }

        override protected function layout():void {

            if (_width > 0 && _height > 0) {

                contentMask.graphics.clear();
                contentMask.graphics.beginFill(0, 1);
                contentMask.graphics.drawRect(0, 0, _width, _height);
                contentMask.graphics.endFill();

            }

            updateItems();
        }

        private var _lastSP:Number;
        private var visibleImages:Dictionary;

        protected function updateItems(e:Event = null, forceRefresh:Boolean = false):void {

            if (!(_width > 0 && _height > 0))
                return;

            if (visibleItems == null)
                visibleItems = [];

            if (visibleImages == null)
                visibleImages = new Dictionary(true);

            var tempImages:Dictionary = new Dictionary(true);

            var size:Number = itemSize;
            var gap:Number = getStyle("gap") == undefined ? ITEM_SPACING : getStyle("gap");
            var sidePadding:Number = getStyle("padding") == undefined ? PADDING_LEFT : getStyle("padding");

            var available:Number = _horizontal ? _width : _height;
            var items:int = Math.ceil((available) / (size + gap)) + 1; // Math.min(_dataProvider ? _dataProvider.length : 0, Math.ceil((available) / (size + ITEM_SPACING)) + 1);
            var firstIndex:Number = _centerOnScrollPosition ? Math.ceil(_actualScrollPosition) - Math.ceil(items / 2) :
                Math.floor(_actualScrollPosition);

            var offset:Number = (_centerOnScrollPosition ? (available - size) / 2 : 0) - (size + gap) * (_actualScrollPosition - firstIndex) - gap;
            var refresh:Boolean = forceRefresh;

            if (_last != firstIndex || _lastItems != items)
                refresh = true;
            _last = firstIndex;
            _lastItems = items;

            if (_dataProvider != null)
                for (var i:int = 0; i < items + _loadAhead; i++) {

                    var c:IItemRenderer = visibleItems[i];
                    var d:DisplayObject = c as DisplayObject;

                    var providerIndex:int = _wrapAround ? ((firstIndex + i) % _dataProvider.length) : firstIndex + i;

                    if (_wrapAround && providerIndex < 0)
                        providerIndex += _dataProvider.length;

                    if (providerIndex >= _dataProvider.length || providerIndex < 0) {
                        if (d && d.parent == content) {
                            content.removeChild(d);
                        }
                        continue;
                    }

                    if (refresh) {

                        if (c == null) {
                            c = visibleItems[i] = createItem();
                            d = c as DisplayObject;
                        }

                        var data:Object = _dataProvider[providerIndex] as Object;

                        if (data == null)
                            continue;

                        // See if we can reuse an item we already created rather than reset this item.

                        var found:Boolean = false;

                        // Dont rearrange items if visible items is less than 2
                        if (items - _loadAhead > 1) {
                            for (var j:int = 0; j < visibleItems.length && !found; j++) {
                                var c2:IItemRenderer = visibleItems[j];

                                if (c2 && c2 != c && c2.data == data) {
                                    visibleItems[i] = c2;
                                    visibleItems[j] = c;
                                    c = c2;
                                    d = c as DisplayObject;
                                    found = true;
                                }
                            }
                        }

                        if (d && d.parent == null)
                            content.addChild(d);

                        c.data = data;

                        if (data is String) {
                            delete visibleImages[data];
                            tempImages[data] = true;
                        }

                        /*
                           if (itemStates && itemStates[(firstIndex + i)] == ITEM_DISABLED)
                           c.enabled = false;
                           else
                           c.enabled = true;
                         */

                        if (selectedData && data == selectedData)
                            c.selected = true;
                        else
                            c.selected = false;
                    }

                    if (c) {
                        if (_highlightCurrentItem && providerIndex == Math.round(_actualScrollPosition))
                            c.selected = true;
                        else if (_highlightCurrentItem && !(selectedData && data == selectedData))
                            c.selected = false;

                        if (_horizontal) {
                            c.x = gap + offset + (gap + size) * i;
                            c.y = sidePadding;

                            if (refresh) {
                                c.width = size;
                                c.height = _height - sidePadding * 2;
                            }
                        }
                        else {
                            c.x = sidePadding;
                            c.y = gap + offset + (gap + size) * i;

                            if (refresh) {
                                c.width = _width - sidePadding * 2;
                                c.height = size;
                            }
                        }

                        if (refresh && "validateNow" in c)
                            c["validateNow"]();
                    }
                }

            // Remove unused images from cache
            if (refresh) {
                for (var key:String in visibleImages) {
                    if (visibleImages[key] == true && _useCache) {
                        //trace("Removing image: " + key);
                        imageCache.removeImage(key, true);
                    }
                }

                visibleImages = tempImages;
            }

            // Remove unused items if we resized:
            while (visibleItems.length - 1 > items) {
                var pr:IItemRenderer = visibleItems.pop() as IItemRenderer;

                pr.destroy();

                var dr:DisplayObject = pr as DisplayObject;

                if (dr && content.contains(dr))
                    content.removeChild(dr);

                if (pr) {
                    pr.removeEventListener(IOErrorEvent.IO_ERROR, onItemIOErrorEvent);
                    pr.removeEventListener(Event.SELECT, onSelect);
                }

            }

        }

        protected function createItem():IItemRenderer {
            var i:IItemRenderer = new _itemRenderer() as IItemRenderer;
            var c:DisplayObject = i as DisplayObject;

            if (c != null)
                content.addChild(c);

            if (_useCache && "cache" in i)
                i["cache"] = imageCache;

            if (i != null) {
                i.addEventListener(IOErrorEvent.IO_ERROR, onItemIOErrorEvent, false, 0, true);
                i.addEventListener(Event.SELECT, onSelect, false, 0, true);
            }

            //trace(++count);
            return i;
        }

        protected function onSelect(e:Event):void {
            selectedItem = IItemRenderer(e.target).data;
        }

        public function disableItem(c:Object):void {
            var index:int = getItemIndex(c);

            if (itemStates == null)
                itemStates = new Array();

            itemStates[index] = ITEM_DISABLED;

            updateItems();
        }

        public function enableItem(c:Object):void {
            var index:int = getItemIndex(c);

            if (itemStates == null)
                itemStates = new Array();

            itemStates[index] = ITEM_ENABLED;

            updateItems();
        }

        public function getItemIndex(c:Object):int {
            for (var i:int = 0; i < _dataProvider.length; i++) {
                if (_dataProvider[i] == c)
                    return i;
            }

            return -1;
        }

        public function get maxScroll():Number {

            var maxItem:Number = _dataProvider ? _dataProvider.length - (_centerOnScrollPosition ? 1 : pageSize) : 0;
            maxItem = Math.max(0, maxItem);
            return maxItem;
        }

        public function get pageSize():Number {
            var available:Number = _horizontal ? _width : _height;
            var gap:Number = getStyle("gap") == undefined ? ITEM_SPACING : getStyle("gap");
            return (available) / (itemSize + gap);
        }

        public function set scrollPosition(v:Number):void {
            _setScrollPosition = v;
            v = Math.min(maxScroll, Math.max(0, v));

            var rounded:Number = _roundScrollPosition ? Math.ceil(v) : v;
            _scrollPositionChanged = _scrollPositionChanged || (_scrollPosition != _setScrollPosition);
            _scrollPosition = rounded;

            if (_scrollPositionChanged)
                invalidateProperties();

            dispatchEvent(new ItemSelectEvent(ItemSelectEvent.SCROLL_POSITION_SET, 0));

        }

        private function cubicEaseOut(t:Number, b:Number,
                                      c:Number, d:Number):Number {
            return c * ((t = t / d - 1) * t * t + 1) + b;
        }

        private function quadraticEaseOut(t:Number, b:Number,
                                          c:Number, d:Number):Number {
            return -c * (t /= d) * (t - 2) + b;
        }

        public function get scrollPosition():Number {
            return _scrollPosition;
        }

        public function set dataProvider(a:Array):void {
            if (_dataProvider != null && itemStates != null) {
                var newStates:Array = new Array();

                for (var i:int = 0; i < a.length; i++) {
                    var oldindex:int = getItemIndex(a[i]);

                    if (oldindex >= 0) {
                        newStates[i] = itemStates[oldindex];
                    }
                }
                itemStates = newStates;
            }

            if (imageCache)
                imageCache.clear();
            _dataProvider = a;
            _scrollPosition = 0;
            _actualScrollPosition = 0;
            _selectedIndex = 0;
            selectedItem = null;
            _last = Number.NaN;
            _lastItems = Number.NaN;

            invalidateLayout();
        }

        public function get dataProvider():Array {
            return _dataProvider;
        }

        protected function onItemIOErrorEvent(e:IOErrorEvent):void {
            var item:IItemRenderer = e.target as IItemRenderer;

            var ev:ItemErrorEvent = new ItemErrorEvent(ItemErrorEvent.IO_ERROR, item.data, _dataProvider ? _dataProvider.indexOf(item.data) : -1);
            dispatchEvent(ev);
        }
    }
}

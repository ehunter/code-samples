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
    import com.litl.skin.LitlColors;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.events.ProgressEvent;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;

    /**
     * List item renderer that loads and scales an image URL.
     * @author litl
     *
     */
    public class ImageItemRenderer extends ControlBase implements IItemRenderer
    {

        public static const MAX_SCALE:Number = 1.5;
        public var unscaledWidth:Number = 0;
        public var unscaledHeight:Number = 0;

        protected var _data:Object;
        protected var _content:DisplayObject;
        protected var loader:Loader;
        protected var _url:String;
        protected var _urlChanged:Boolean = true;
        protected var _context:LoaderContext;
        protected var _scaleContent:Boolean = true;
        protected var _aspect:Boolean = true;
        protected var _center:Boolean = true;
        protected var _cache:ImageCache;

        protected var _selected:Boolean = false;
        protected var _used:Boolean = false;

        protected var background:Sprite;

        public function get isReady():Boolean {
            return (_content != null);
        }

        public function get cache():ImageCache {
            return _cache;
        }

        public function set cache(value:ImageCache):void {
            _cache = value;
        }

        public function get content():DisplayObject {
            return _content;
        }

        override protected function createChildren():void {
            mouseChildren = false;

            background = new Sprite();
            addChild(background);

            //filters = [new DropShadowFilter(4,45,0,0.3,8,8)];

            addEventListener(MouseEvent.ROLL_OVER, onRollOver);
            addEventListener(MouseEvent.ROLL_OUT, onRollOut);
            addEventListener(MouseEvent.CLICK, onClick);
        }

        override protected function updateProperties():void {
            if (_urlChanged) {
                _urlChanged = false;
                load(_url);
            }
        }

        override protected function layout():void {

            if (_width > 0 && _height > 0) {

                if (_content == null) {
                    var g:Graphics = background.graphics;
                    g.clear();

                    g.beginFill(LitlColors.DARK_GREY, 1);

                    g.drawRect(0, 0, _width, _height);
                    g.endFill();
                }
                else {
                    g = graphics;
                    g.clear();

                    if (_selected) {
                        g.lineStyle(3, 0xffffff, 1, true);
                        g.drawRect(-1.5, -1.5, _width + 3, _height + 3);
                    }
                }
            }

            if (_content != null) {
                doScale(_width, _height);
            }
        }

        protected function doScale(w:Number, h:Number):void {
            _content.scaleX = _content.scaleY = 1;
            unscaledWidth = _content.width;
            unscaledHeight = _content.height;

            if (_scaleContent) {
                if (w > 0 || h > 0) {
                    if (_aspect) {
                        if (w / _content.width < h / _content.height) {
                            _content.width = Math.min(w, unscaledWidth * MAX_SCALE);
                            _content.scaleY = _content.scaleX;
                        }
                        else {
                            _content.height = Math.min(h, unscaledHeight * MAX_SCALE);
                            _content.scaleX = _content.scaleY;
                        }

                        _content.x = _center ? (w - _content.width) / 2 : 0;
                        _content.y = _center ? (h - _content.height) / 2 : 0;
                    }
                    else {
                        _content.width = w;
                        _content.height = h;
                    }
                }
            }
            else {
                if (!(_width > 0))
                    _width = _content.width;

                if (!(_height > 0))
                    _height = _content.height;
                _content.x = _center ? (w - _content.width) / 2 : 0;
                _content.y = _center ? (h - _content.height) / 2 : 0;
            }
        }

        public function set data(c:Object):void {
            var cached:Boolean = cache ? cache.hasImage(c as String) : false;

            _data = c;
            _urlChanged = cached || _urlChanged || (_url != (c ? c.toString() : null));
            _url = c ? c.toString() : null;

            if (_urlChanged)
                invalidateProperties();
        }

        public function get data():Object {
            return _data;
        }

        public function set selected(b:Boolean):void {
            var last:Boolean = _selected;
            _selected = b;

            if (last != _selected)
                invalidateLayout();
        }

        public function get selected():Boolean {
            return _selected;
        }

        override public function destroy():void {
            if (loader) {
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageLoad);
                loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgress);
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
                loader.contentLoaderInfo.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
            }

            if (_content is Bitmap) {
                Bitmap(_content).bitmapData.dispose();
            }

            super.destroy();
        }

        protected function onClick(e:MouseEvent = null):void {
            dispatchEvent(new Event(Event.SELECT));
        }

        public function set enabled(b:Boolean):void {
            alpha = b ? 1 : 0.75;

            mouseEnabled = b;
        }

        protected function load(str:String):void {
            if (_content && contains(_content)) {
                removeChild(_content);
            }

            if (str == null || str.length == 0)
                return;

            var cached:DisplayObject = cache ? cache.getImage(str) : null;

            if (cached != null) {
                _content = cached;

                //trace("Getting image from cache: " + str);

                if (_content.parent)
                    _content.parent.removeChild(_content);

                addChild(_content);

                if (contains(background))
                    removeChild(background);

                layout();
                dispatchEvent(new Event(Event.COMPLETE));
                return;
            }

            if (loader) {
                loader.unload();
                loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageLoad, false);
                loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgress, false);
                loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError, false);
                loader.contentLoaderInfo.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus, false);
            }
            //{
            loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoad, false, 0, true);
            loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress, false, 0, true);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
            loader.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus, false, 0, true);
            //}

            _content = null;

            if (!contains(background))
                addChild(background);

            var c:LoaderContext = new LoaderContext(true);

            var req:URLRequest = new URLRequest(str);

            //trace("Loading image: " + str);
            loader.load(req, c);

        }

        /**
         * Called when a loader dispatches a complete event.
         * @private
         */
        protected function onImageLoad(e:Event):void {
            if (_content && contains(_content)) {
                removeChild(_content);
            }
            _content = loader.content;

            if (_content is Bitmap)
                Bitmap(_content).smoothing = true;

            //trace("Storing image: " + _url + " : " + e.target.url);

            if (cache != null && !cache.hasImage(_url))
                cache.storeImage(_url, _content);

            if (contains(background))
                removeChild(background);
            addChild(_content);

            layout();
            dispatchEvent(new Event(Event.COMPLETE));
        }

        /**
         * Called when a progress event is dispatched from a loading process.
         * @private
         */
        protected function onProgress(e:ProgressEvent):void {
            //dispatchEvent(e.clone());
        }

        /**
         * @private
         */
        protected function onIOError(e:IOErrorEvent):void {
            dispatchEvent(e.clone());
        }

        /**
         * @private
         */
        protected function onHttpStatus(e:HTTPStatusEvent):void {
            //dispatchEvent(e.clone());
        }

        protected function onRollOver(e:MouseEvent):void {

        }

        protected function onRollOut(e:MouseEvent):void {

        }

        override public function toString():String {
            return String(_data);
        }
    }
}

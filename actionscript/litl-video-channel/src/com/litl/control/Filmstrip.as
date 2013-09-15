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
package com.litl.control
{
    import com.litl.control.listclasses.ScrollableList;

    import flash.display.DisplayObject;
    import flash.events.Event;

    /**
     * Dispatched when the current scroll position changes.
     */
    [Event(name="select", type="flash.events.Event")]

    /**
     * A scrolling horizontal list with definable item renderer.
     * @author litl
     * @example
     * <listing version="3.0">
     *
     * package
     * {
     *     import com.litl.control.listclasses.ImageItemRenderer;
     *     import com.litl.control.Filmstrip;
     *     import flash.events.Event;
     *     import flash.display.Sprite;
     *
     *     public class FilmstripTest extends Sprite {
     *
     *     private var filmstrip:Filmstrip;
     *
     *         public function FilmstripTest() {
     *
     *         filmstrip = new Filmstrip();
     *         filmstrip.itemRenderer = ImageItemRenderer;
     *         filmstrip.setSize(1280, 124);
     *         filmstrip.move(0, 676);
     *         addChild(filmstrip);
     *         filmstrip.dataProvider = [ "image1.png", "image2.png", "image3.png" ];
     *
     *         filmstrip.addEventListener(Event.CHANGE, onFilmstripChange, false, 0, true);
     *     }
     *
     *     private function onFilmstripChange(e:Event):void {
     *         var selectedItem:Object = filmstrip.selectedItem;
     *         trace(selectedItem);
     *     }
     *     }
     * }
     * </listing>
     */
    public class Filmstrip extends ControlBase
    {
        /** @private */
        protected var background:DisplayObject;
        /** @private */
        protected var list:ScrollableList;
        /** @private */
        protected var _dataProvider:Array;
        /** @private */
        protected var _dataProviderChanged:Boolean = false;
        /** @private */
        protected var _itemRenderer:Class;
        /** @private */
        protected var _itemRendererChanged:Boolean = false;

        /** Constructor */
        public function Filmstrip() {

        }

        /**
         * Get the currently selected item in the filmstrip.
         * @return The currently selected tem in the dataProvider.
         *
         */
        public function get selectedItem():Object {
            return list ? list.selectedItem : null;
        }

        /**
         * Get/Set the current scroll position of the list.
         * @param value The new scroll position to move to.
         * @example
         * <listing version="3.0">
         * filmstrip.scrollPosition = 4;
         * filmstrip.scrollPosition++;
         * trace(filmstrip.scrollPosition);
         * </listing>
         */
        public function set scrollPosition(value:int):void {
            if (list) {
                list.scrollPosition = value;
                list.selectedIndex = value;
            }
        }

        /** @private */
        public function get scrollPosition():int {
            return list ? list.scrollPosition : -1;
        }

        /**
         * Get/Set the current data to display. Each item in the dataProvider will be pushed
         * into the corresponding item renderer's <i>data</i> property.
         * @param value An array of data to display.
         * @example
         * <listing version="3.0">
         * var myArray:Array = ["One", "Two", "Three"];
         * filmstrip.dataProvider = myArray;
         * </listing>
         */
        public function set dataProvider(value:Array):void {
            _dataProviderChanged = _dataProviderChanged || (_dataProvider != value);
            _dataProvider = value;

            if (_dataProviderChanged)
                invalidateProperties();
        }

        /** @private */
        public function get dataProvider():Array {
            return _dataProvider;
        }

        /**
         * Get/Set the current class definition to use as an item renderer.
         * This class will be instantiated for each item in the list.
         * The filmstrip list implementation will re-use each item as needed, so
         * the itemRenderer implementation will need to handle changes in its
         * <i>data</i> property.
         * @param klass The class definition to use.
         * @example
         * <listing version="3.0">
         * import com.litl.control.listclasses.ImageItemRenderer;
         *
         * filmstrip.itemRenderer = ImageItemRenderer;
         * </listing>
         */
        public function set itemRenderer(klass:Class):void {
            _itemRendererChanged = _itemRendererChanged || (_itemRenderer != klass);
            _itemRenderer = klass;

            if (_itemRendererChanged)
                invalidateProperties();
        }

        /** @private */
        public function get itemRenderer():Class {
            return _itemRenderer;
        }

        /**
         * Refresh the filmstrip's display with the current dataProvider.
         *
         */
        public function refresh():void {
            // if (list)
            //list.refresh();
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {
            background = createSkinElement("backgroundSkin");

            if (background)
                addChild(background);

            list = new ScrollableList();
            list.horizontal = true;
            list.transitionSpeed = 0.3;
            list.highlightCurrentItem = true;
            list.wrapAround = false;
            list.useCache = true;
            // Copy some styles to the list
            list.setStyle("backgroundColor", getStyle("backgroundColor"))
            list.setStyle("padding", getStyle("padding"));
            list.setStyle("gap", getStyle("gap"));

            list.addEventListener(Event.SELECT, onListChange, false, 0, true);

            addChild(list);

        }

        /** @inheritDoc
         * @private */
        override protected function updateProperties():void {
            if (_dataProviderChanged) {
                _dataProviderChanged = false;
                list.dataProvider = _dataProvider;
                list.validateNow();
            }

            if (_itemRendererChanged) {
                _itemRendererChanged = false;
                list.itemRenderer = _itemRenderer;
            }
        }

        /** @inheritDoc
         * @private */
        override protected function layout():void {
            if (background) {
                background.width = _width;
                background.height = _height;
            }
            list.itemSize = _height;
            list.setSize(_width, _height);
        }

        /**
         * Called when the list has changed its currently selected index.
         * @param e     The event that triggered the change.
         * @private
         */
        protected function onListChange(e:Event):void {
            list.scrollPosition = list.selectedIndex;
            dispatchEvent(e.clone());
        }
    }
}

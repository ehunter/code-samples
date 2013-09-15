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
    import com.litl.control.listclasses.ArrowButton;
    import com.litl.control.listclasses.ScrollableList;
    import com.litl.control.listclasses.SelectableItemRenderer;

    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.ColorMatrixFilter;

    /**
     * Dispatched when the currently selected item has changed.
     */
    [Event(name="change", type="flash.events.Event")]

    /**
     * A scrolling vertical list with definable item renderer, and up and down scroll buttons.
     * @author litl
     * @example
     * <listing version="3.0">
     *
     * package
     * {
     *     import com.litl.control.listclasses.TextItemRenderer;
     *     import com.litl.control.VerticalList;
     *     import flash.events.Event;
     *     import flash.display.Sprite;
     *
     *     public class VerticalListTest extends Sprite {
     *
     *     private var list:VerticalList;
     *
     *         public function VerticalListTest() {
     *         list = new VerticalList();
     *         list.itemRenderer = TextItemRenderer;
     *         list.setSize(500, 600);
     *         list.move(100, 100);
     *         addChild(list);
     *         list.dataProvider = [ "One", "Two", "Three" ];
     *
     *         list.addEventListener(Event.CHANGE, onListChange, false, 0, true);
     *     }
     *
     *     private function onListChange(e:Event):void {
     *         var selectedItem:Object = list.selectedItem;
     *         trace(selectedItem);
     *     }
     *     }
     * }
     * </listing>
     */
    public class VerticalList extends ControlBase
    {
        /** @private */
        protected var background:DisplayObject;
        /** @private */
        protected var list:ScrollableList;
        /** @private */
        protected var upArrow:ArrowButton;
        /** @private */
        protected var downArrow:ArrowButton;
        /** @private */
        protected var _dataProvider:Array;
        /** @private */
        protected var _dataProviderChanged:Boolean = false;
        /** @private */
        protected var _itemRenderer:Class;
        /** @private */
        protected var _itemRendererChanged:Boolean = false;
        /** @private */
        protected var _enabled:Boolean = true;
        /** @private */
        protected var _itemSize:Number;
        /** @private */
        protected var _itemSizeChanged:Boolean = false;

        private const rLum:Number = 0.1225;
        private const gLum:Number = 0.6169;
        private const bLum:Number = 0.0606;

        private var bwMatrix:Array = [ rLum, gLum, bLum, 0, 0,
                                       rLum, gLum, bLum, 0, 0,
                                       rLum, gLum, bLum, 0, 0,
                                       0, 0, 0, 1, 0 ];

        private var bwFilter:ColorMatrixFilter = new ColorMatrixFilter(bwMatrix);

        /** Constructor. */
        public function VerticalList() {

        }

        /**
         * Enable or disable this list.
         * @param b     A boolean indicating whether the list is currently enabled.
         *
         */
        public function set enabled(b:Boolean):void {
            _enabled = b;
            mouseChildren = b;

            if (list != null) {
                if (!b)
                    list.filters = [ bwFilter ];
                else
                    list.filters = [];
            }
        }

        /** @private */
        public function get enabled():Boolean {
            return _enabled;
        }

        /**
         * Get/Set the current scroll position of the list.
         * @param value The new scroll position to move to.
         * @example
         * <listing version="3.0">
         * list.scrollPosition = 4;
         * list.scrollPosition++;
         * trace(list.scrollPosition);
         * </listing>
         */
        public function set scrollPosition(value:int):void {
            if (list)
                list.scrollPosition = value;
        }

        /** @private */
        public function get scrollPosition():int {
            return list ? list.scrollPosition : -1;
        }

        /**
         * Get the currently selected item in the list.
         * @return The object in the dataProvider corresponding to the currently selected item.
         *
         */
        public function get selectedItem():Object {
            return list ? list.selectedItem : null;
        }

        /**
         * Get/Set the current data to display. Each item in the dataProvider will be pushed
         * into the corresponding item renderer's <i>data</i> property.
         * @param value An array of data to display.
         * @example
         * <listing version="3.0">
         * var myArray:Array = ["One", "Two", "Three"];
         * list.dataProvider = myArray;
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
         * The list implementation will re-use each item as needed, so
         * the itemRenderer implementation will need to handle changes in its
         * <i>data</i> property.
         * @param klass The class definition to use.
         * @example
         * <listing version="3.0">
         * import com.litl.control.listclasses.TextItemRenderer;
         *
         * list.itemRenderer = TextItemRenderer;
         * </listing>
         * @default com.litl.control.listclasses.TextItemRenderer
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

        public function set itemSize(val:Number):void {
            _itemSizeChanged = _itemSize != val;
            _itemSize = val;

            if (_itemSizeChanged)
                invalidateProperties();
        }

        public function get itemSize():Number {
            return _itemSize;
        }

        /**
         * Refresh the list's display with the current dataProvider.
         *
         */
        public function refresh():void {
            //if (list)
            //list.refresh();
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {
            background = createSkinElement("backgroundSkin");

            if (background)
                addChild(background);

            list = new ScrollableList();
            list.itemRenderer = SelectableItemRenderer;
            list.horizontal = false;
            list.transitionSpeed = 0.3;
            list.highlightCurrentItem = false;
            list.centerOnScrollPosition = false;
            list.wrapAround = false;
            list.useCache = true;
            // Copy some styles to the list
            list.setStyle("backgroundColor", getStyle("backgroundColor"))
            list.setStyle("padding", getStyle("padding"));
            list.setStyle("gap", getStyle("gap"));

            list.addEventListener(Event.SELECT, onListChange, false, 0, true);

            addChild(list);

            upArrow = new ArrowButton();
            upArrow.direction = "up";
            upArrow.addEventListener(MouseEvent.CLICK, onUpClick, false, 0, true);
            addChild(upArrow);
            downArrow = new ArrowButton();
            downArrow.direction = "down";
            downArrow.addEventListener(MouseEvent.CLICK, onDownClick, false, 0, true);
            addChild(downArrow);
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

            if (_itemSizeChanged) {
                _itemSizeChanged = false;
                list.itemSize = _itemSize;
            }

            checkArrows();
        }

        /** @inheritDoc
         * @private */
        override protected function layout():void {
            const arrowHeight:Number = 20;

            if (background) {
                background.y = arrowHeight;
                background.width = _width;
                background.height = _height - arrowHeight * 2;
            }
            list.move(2, arrowHeight + 2);
            list.setSize(_width - 4, _height - arrowHeight * 2 - 4);
            upArrow.move(0, 0);
            upArrow.setSize(_width, arrowHeight);
            downArrow.move(0, _height - arrowHeight);
            downArrow.setSize(_width, arrowHeight);

            checkArrows();
        }

        /** Check whether each arrow button should be displayed.
         *  @private */
        protected function checkArrows():void {
            upArrow.visible = list.scrollPosition > 0;
            downArrow.visible = list.scrollPosition < list.maxScroll && _dataProvider && _dataProvider.length > list.maxScroll;
        }

        /**
         * Called when the list changes its currently selected item.
         * @private
         */
        protected function onListChange(e:Event):void {
            //list.scrollPosition = list.selectedIndex;
            dispatchEvent(e.clone());
            checkArrows();
        }

        /** Called when the up button is clicked.
         * @private */
        protected function onUpClick(e:MouseEvent):void {
            list.scrollPosition -= 3;
            checkArrows();
        }

        /** Called when the down button is clicked.
         * @private */
        protected function onDownClick(e:MouseEvent):void {
            list.scrollPosition += 3;
            checkArrows();
        }
    }
}

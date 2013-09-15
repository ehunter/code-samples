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
package com.litl.tv.utils
{
    import com.litl.control.ControlBase;
    import com.litl.control.listclasses.ScrollableList;
    import com.litl.event.ItemSelectEvent;
    import com.litl.tv.event.ThumbnailListEvent;
    import com.litl.tv.renderer.ThumbnailListRenderer;
    import com.litl.tv.view.skins.ThumbnailListBackground;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;

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
    public class ThumbnailList extends ControlBase
    {
        /** @private */
        protected var background:ThumbnailListBackground;
        /** @private */
        public var list:ScrollableList;
        /** @private */
        protected var _dataProvider:Array;
        /** @private */
        protected var _dataProviderChanged:Boolean = false;
        /** @private */
        protected var _itemRenderer:Class;
        /** @private */
        protected var _itemRendererChanged:Boolean = false;

        private var leftArrow:ArrowListButton = null;
        private var rightArrow:ArrowListButton = null;
        private var nextPreviousCount:Number = 0;
        private var maxLeft:Number = 0;
        private var maxRight:Number = 0;

        private var listBg:Sprite;
        private var testCount:int = 0;
        /// Keyboard events
        private var left:uint = 37;
        private var right:uint = 39;
        private var atMaxScroll:Boolean = false;

        private static var THUMBNAIL_WIDTH:Number = 173;

        //private var maxMenuItems:Number = 0;

        /** Constructor */
        public function ThumbnailList() {

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
         * Get the currently selected item in the filmstrip.
         * @return The currently selected tem in the dataProvider.
         *
         */
        public function get selectedIndex():Number {
            return list ? list.selectedIndex : -1;
        }

        /**
         * Get the currently selected item in the filmstrip.
         * @return The currently selected tem in the dataProvider.
         *
         */
        public function set selectedIndex(id:Number):void {
            if (list) {
                list.selectedIndex = id;
            }
        }

        /**
         * Set the scroll position in the list.
         * @return void.
         *
         */
        public function set scrollPosition(id:Number):void {
            if (list) {
                list.scrollPosition = id;
            }
        }

		/**
		 * Set the scroll position in the list.
		 * @return void.
		 *
		 */
		public function get scrollPosition():Number {
			var pos:Number = 0;
			if (list) {
				pos = list.scrollPosition
			}
			return pos;
		}

		/**
		 * Get the currently selected item in the filmstrip.
		 * @return The currently selected tem in the dataProvider.
		 *
		 */
		public function get selectedItemOffScreen():Boolean {
			var offscreen:Boolean;

			if(selectedIndex > scrollPosition)
			{
				var rightDiff:Number = (scrollPosition + maxRight);
				if(rightDiff <= selectedIndex){
					offscreen = true
				}
			}
			else if(selectedIndex < scrollPosition)
			{
				offscreen = true;
			}
			else
			{
				offscreen = false;
			}

			return offscreen;
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
         * moves the list to the next item
         */
        public function moveNext():void {

			var dataProviderLength:Number = dataProvider.length - 1;
			var chosenIndex:Number = list.selectedIndex + 1;

			if (chosenIndex < dataProviderLength) {
				list.selectedIndex++;
			}
			else if (chosenIndex == dataProviderLength) {
				list.selectedIndex = dataProviderLength;
			}
			/// wrap around
			else
			{
				list.selectedIndex = 0;
			}
			// scrolling if necessary
			scrollNext();

        }

		/**
		 * moves the list to the previous item
		 */
		public function movePrevious():void {

			var chosenIndex:Number = list.selectedIndex - 1;
			var dataProviderLength:Number = dataProvider.length - 1;

			if (chosenIndex >= 0) {
				list.selectedIndex--;
			}
			/// wrap around
			else if (chosenIndex < 0)
			{
				list.selectedIndex = dataProviderLength;
			}
			// scrolling if necessary
			scrollPrevious();

		}


		private function scrollNext():void
		{
			/// if our item is offscreen and not at the end
			if((selectedItemOffScreen)&&(!atMaxScroll))
			{
				// next check to see if the selected item is one more than the previous
				// if so we're just going to increment
				var diff:Number = ((list.selectedIndex - scrollPosition) - maxRight);
				if (diff == 0) {
					list.scrollPosition++;
				}
				// we're not just moving up 1 to the next
				// so we need to slide the entire list to the selected items position
				else{
					list.scrollPosition = list.selectedIndex;
				}
			}

			checkMaxScroll();
		}

		private function scrollPrevious():void
		{

			/// if our item is offscreen and not at the end
			if((selectedItemOffScreen)&&(!atMaxScroll))
			{
				// next check to see if the selected item is one more than the previous
				// if so we're just going to increment
				var diff:Number = (scrollPosition - list.selectedIndex);
				if (diff == 1) {
					list.scrollPosition--;
				}
					// we're not just moving up 1 to the next
					// so we need to slide the entire list to the selected items position
				else{
					list.scrollPosition = list.selectedIndex;
				}
			}

			checkMaxScroll();

		}



        /**
         * checks to see if we're at the max scroll postion of the scrollable list
         */
        private function checkMaxScroll():void {

            if ((list.maxScroll - 1) == list.scrollPosition) {
                atMaxScroll = true;
            }
            else {
                atMaxScroll = false;
            }
        }


        /**
         * onKeyPress
         *
         */
        private function onKeyPress(evt:KeyboardEvent):void {

            if (evt.keyCode == left) {
                movePrevious();

            }
            else if (evt.keyCode == right) {
                moveNext();
            }

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
            //if (list)
            //list.refresh();
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {

            background = new ThumbnailListBackground();
            addChild(background);

            list = new ScrollableList();
            list.itemRenderer = ThumbnailListRenderer;
            //list.selectedIndex = 0;
            list.horizontal = true;
            list.transitionSpeed = 0.3;
            list.highlightCurrentItem = false;
            list.wrapAround = false;
            list.useCache = true;
            // Copy some styles to the list
            // the amount of space on top and bottom of each item
            list.setStyle("padding", 0);
            /// the amount of space between items
            list.setStyle("gap", 1);
            // start the list at the far left (not centered)
            list.centerOnScrollPosition = false;

            list.addEventListener(Event.SELECT, onListChange, false, 0, true);
            list.addEventListener(ItemSelectEvent.SCROLL_POSITION_SET, onScrollPositionSet);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);

            addChild(list);

            leftArrow = new ArrowListButton();
            leftArrow.mouseChildren = false;
            leftArrow.mouseEnabled = true;
            leftArrow.buttonMode = true;
            leftArrow.useHandCursor = true;
            leftArrow.addEventListener(ThumbnailListEvent.ARROW_BUTTON_PRESSED, onLeftArrowPress);
            addChild(leftArrow);

            rightArrow = new ArrowListButton();
            rightArrow.mouseChildren = false;
            rightArrow.mouseEnabled = true;
            rightArrow.buttonMode = true;
            rightArrow.useHandCursor = true;
            rightArrow.addEventListener(ThumbnailListEvent.ARROW_BUTTON_PRESSED, onRightArrowPress);
            addChild(rightArrow);

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
            // 31 is the width of the left and right arrows
            // change this somehow
            maxRight = Math.floor(((_width - (31 * 2)) / 173));

            list.itemSize = THUMBNAIL_WIDTH;
            // set the size of the list to the width of the stage minus the width of the two arrow Buttons and spacing
            list.setSize((maxRight * THUMBNAIL_WIDTH), (_height - 2));
            /// move the list down 2 pixels to make border at top
            list.move(((_width - list.width) / 2), 2);
            leftArrow.setBgSize(list.x, (_height - 2));
            rightArrow.setBgSize(list.x, (_height - 2));
            rightArrow.move((list.width + list.x + rightArrow.bgWidth), (_height));
            leftArrow.move(0, 2);
            //leftArrow.move(0, 2);
            rightArrow.rotation = 180;

            checkListPosition();
        }

        /**
         * Called when the list has changed its currently selected index.
         * @param e     The event that triggered the change.
         * @private
         */
        protected function onListChange(e:Event):void {

            dispatchEvent(e.clone());

        }

        /**
         * Scroll the list to the right when the left Arrow is pressed
         *
         */
        public function onLeftArrowPress(evt:ThumbnailListEvent):void {
            list.scrollPosition--;

        }

        /**
         * Scroll the list to the left when the right Arrow is pressed
         *
         */
        public function onRightArrowPress(evt:ThumbnailListEvent):void {
            list.scrollPosition++;
        }

        private function checkListPosition():void {

            var maxScroll:int = list.maxScroll;

            // if we're at the end of the list on the left
            if (list.scrollPosition <= 0) {
                leftArrow.disable();
                leftArrow.mouseEnabled = false;
            }
            else {
                if (leftArrow.buttonDisabled) {
                    leftArrow.enable();
                    leftArrow.mouseEnabled = true;
                }
            }

            // if we're at the end of the list on the right
            if (list.scrollPosition >= maxScroll) {
                rightArrow.disable();
                rightArrow.mouseEnabled = false;
            }
            else {
                if (rightArrow.buttonDisabled) {
                    rightArrow.enable();
                    rightArrow.mouseEnabled = true;
                }
            }

            checkMaxScroll();
        }

        private function onScrollPositionSet(evt:ItemSelectEvent):void {

            checkListPosition();

        }

    }
}

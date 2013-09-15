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
    import com.litl.control.listclasses.ImageItemRenderer;
    import com.litl.control.listclasses.ScrollableList;
    import com.litl.sdk.util.Tween;
    import com.litl.skin.parts.LoadingSpinner;

    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;

    /**
     * Class to display a horizontally scrolling slideshow with configurable item renderer.
     * The slideshow will show an indeterminate loading indicator when waiting for the next item to be ready.
     * @author litl
     * @example
     * <listing version="3.0">
     *
     * package
     * {
     *     import com.litl.control.Slideshow;
     *     import com.litl.control.listclasses.ImageItemRenderer;
     *     import flash.display.Sprite;
     *
     *     public class SlideshowTest extends Sprite {
     *
     *     private var slideshow:Slideshow;
     *
     *         public function SlideshowTest() {
     *                  slideshow = new Slideshow();
     *                  slideshow.itemRenderer = ImageItemRenderer;         // Set the item renderer class to use.
     *                  slideshow.delay = 2;    // Make the slideshow automatically advance every 2 seconds.
     *                  slideshow.setSize(500, 300);
     *                  addChild(slideshow);
     *                  slideshow.dataProvider = [ "image1.png", "image2.png", "image3.png", "image4.png" ];
     *     }
     *
     *     }
     * }
     * </listing>
     */
    public class Slideshow extends ControlBase
    {
        /** @private */
        protected var list:ScrollableList;
        /** @private */
        protected var _delay:Number = 5;
        /** @private */
        protected var _dataProvider:Array;
        /** @private */
        protected var _dataProviderChanged:Boolean = false;
        /** @private */
        protected var _itemRenderer:Class;
        /** @private */
        protected var _itemRendererChanged:Boolean = false;
        /** @private */
        protected var _transitionSpeed:Number = 0.5;
        /** @private */
        protected var _transitionSpeedChanged:Boolean = false;
        /** @private */
        protected var _nextDirection:int = 1;
        /** @private */
        protected var _moveOnce:Boolean = false;

        /** @private */
        protected var timer:Timer;

        /** @private */
        protected var spinner:LoadingSpinner;

        /** Constructor. */
        public function Slideshow() {
            initialize();
        }

        /**
         * Stop the slideshow from automatically advancing.
         *
         */
        public function pause():void {
            if (timer.running) {
                timer.stop();
            }
        }

        /**
         * Start the slideshow automatically advancing, if it is not already, and the delay property is greater than 0.
         *
         */
        public function play():void {
            if (!timer.running && timer.delay > 0) {
                timer.start();
            }
        }

        /**
         * Get/set the delay before moving to the next item, in seconds.
         * @param value The number of seconds to wait before advancing.
         *
         */
        public function set delay(value:Number):void {
            _delay = value;

            if (delay <= 0)
                timer.stop();
            else {
                timer.delay = _delay * 1000;
                timer.start();
            }
        }

        /** @private */
        public function get delay():Number {
            return _delay;
        }

        /**
         * Get/set the time it takes to transition between items, in seconds.
         * @param value The number of seconds to take while moving between items.
         *
         */
        public function set transitionSpeed(val:Number):void {
            _transitionSpeedChanged = _transitionSpeedChanged || (val != _transitionSpeed);
            _transitionSpeed = val;

            if (_transitionSpeedChanged)
                invalidateProperties();
        }

        /** @private */
        public function get transitionSpeed():Number {
            return _transitionSpeed;
        }

        /**
         * Get/Set the current data to display. Each item in the dataProvider will be pushed
         * into the corresponding item renderer's <i>data</i> property.
         * @param value An array of data to display.
         * @example
         * <listing version="3.0">
         * var myArray:Array = ["image1.png", "image2.png", "image3.png"];
         * slideshow.dataProvider = myArray;
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
         * The slideshow implementation will re-use each item as needed, so
         * the itemRenderer implementation will need to handle changes in its
         * <i>data</i> property.
         * @param klass The class definition to use.
         * @example
         * <listing version="3.0">
         * import com.litl.control.listclasses.ImageItemRenderer;
         *
         * slideshow.itemRenderer = ImageItemRenderer;
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
            return list.itemRenderer;
        }

        /**
         * Move to the next item in the slideshow.
         */
        public function moveNext():void {
            _nextDirection = 1;
            _moveOnce = !timer.running;

            if (timer.running) {
                timer.stop();
            }

            timer.delay = 100;
            timer.start();
        }

        /**
         * Move to the previous item in the slideshow.
         */
        public function movePrevious():void {
            _nextDirection = -1;
            _moveOnce = !timer.running;

            if (timer.running) {
                timer.stop();
            }
            timer.delay = 100;
            timer.start();
        }

        /**
         * Refresh the slideshow's display with the current dataProvider.
         *
         */
        public function refresh():void {
            if (list)
                list.refresh();
        }

        /**
         * Create the slideshow timer.
         * @private */
        protected function initialize():void {
            timer = new Timer(_delay);
            timer.addEventListener(TimerEvent.TIMER, onTick, false, 0, true);
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {
            list = new ScrollableList();
            list.itemRenderer = ImageItemRenderer; // Show images by default
            list.horizontal = true;
            list.transitionSpeed = _transitionSpeed;
            list.loadAhead = 1;
            list.wrapAround = true;
            list.useCache = true;
            // Copy some styles to the list
            list.setStyle("padding", getStyle("padding"));
            list.setStyle("gap", getStyle("gap"));
            addChild(list);
        }

        /** @inheritDoc
         * @private */
        override protected function updateProperties():void {
            if (_dataProviderChanged) {
                _dataProviderChanged = false;
                list.dataProvider = _dataProvider;
            }

            if (_itemRendererChanged) {
                _itemRendererChanged = false;
                list.itemRenderer = _itemRenderer;
            }

            if (_transitionSpeedChanged) {
                _transitionSpeedChanged = false;
                list.transitionSpeed = _transitionSpeed;
            }
        }

        /** @inheritDoc
         * @private */
        override protected function layout():void {
            list.itemSize = _width;
            list.setSize(_width, _height);

            if (spinner) {
                spinner.x = (_width - spinner.width) / 2;
                spinner.y = (_height - spinner.height) / 2;
            }
        }

        /**
         * Called every time the timer ticks.
         * Check if the next item is ready to display and advance.
         * If the item is not ready yet, display a loading indicator.
         * @private
         */
        protected function onTick(e:TimerEvent):void {
            var sp:int = list.scrollPosition;

            if (list.itemIsReady(sp + _nextDirection)) {
                hidePreloader();
                list.scrollPosition += _nextDirection;
                _nextDirection = 1;

                if (_moveOnce) {
                    timer.stop();
                    _moveOnce = false;
                }

                timer.delay = _delay * 1000;
            }
            else {
                showPreloader();
            }

        }

        /**
         * Hide the preloader, if currently shown.
         *
         */
        protected function hidePreloader():void {
            if (spinner) {
                var tween:Tween = Tween.tweenTo(spinner, 0.3, { alpha: 0 });
                tween.addEventListener(Event.COMPLETE, removeSpinner, false, 0, true);
            }
        }

        /**
         * Remove the spinner from the display list.
         */
        protected function removeSpinner(e:Event = null):void {
            removeChild(spinner);
            spinner = null;
        }

        /**
         * Show the preloader, if not currently shown.
         *
         */
        protected function showPreloader():void {
            if (spinner == null) {
                spinner = new LoadingSpinner();
                addChild(spinner);
                spinner.alpha = 0;
                invalidateLayout();
            }

            Tween.tweenTo(spinner, 0.3, { alpha: 1 });
        }
    }
}

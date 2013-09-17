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
package com.litl.weather.renderer
{
    import caurina.transitions.Tweener;

    import com.litl.control.Slideshow;
    import com.litl.control.listclasses.IItemRenderer;
    import com.litl.control.listclasses.ImageItemRenderer;
    import com.litl.control.listclasses.TextItemRenderer;
    import com.litl.helpers.slideshow.event.SlideFactoryEvent;
    import com.litl.weather.model.WeatherView;
    import com.litl.weather.model.twc.*;
    import com.litl.weather.model.twc.Weather;
    import com.litl.weather.service.WeatherService;
    import com.litl.weather.utils.StringUtils;
    import com.litl.weather.view.Animations;
    import com.litl.weather.view.CardView;
    import com.litl.weather.view.CardViewThreeDay;
    import com.litl.weather.view.ViewManager;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.Timer;

    public class CardItemRenderer extends ImageItemRenderer implements IItemRenderer
    {
        public var currentImage:String = null;
        public var imageLoader:Loader = new Loader();
        private static const UNKNOWN_TEMP_TEXT:String = "––°";
        private var cardViewRoot:CardViewRoot;
        private var temperatureFormat:TextFormat;
        private var weather:Weather;
        protected var weatherService:WeatherService;
        private var cardView:CardView;
        private var cardViewThreeDay:CardViewThreeDay;
        private var viewType:String;

        public function CardItemRenderer() {

            super();

        }

        override public function get isReady():Boolean {
            // 3 day will be ready immediately
            // regular card view will need to wait for the image to load
            return (viewType == WeatherView.VIEW_THREE_DAY);
        }

        override public function set data(obj:Object):void {
            var changed:Boolean = weather != obj;

            var weatherView:WeatherView = obj as WeatherView;

            weather = weatherView.weather;
            viewType = weatherView.viewType;

            invalidateProperties();
        }

        override protected function createChildren():void {
            super.createChildren();
            cardView = new CardView();
            cardView.addEventListener(Event.COMPLETE, onCardComplete, false, 0, true);
            cardViewThreeDay = new CardViewThreeDay();
        }

        protected function onCardComplete(event:Event):void {
            dispatchEvent(new Event(Event.COMPLETE));
        }

        override protected function updateProperties():void {

            switch (viewType) {
                default:
                case WeatherView.VIEW_NORMAL:

                    if (cardViewThreeDay.parent == this)
                        removeChild(cardViewThreeDay);
                    if (cardView.parent != this)
                        addChild(cardView);
                    cardView.updateView(weather);

                    break;

                case WeatherView.VIEW_THREE_DAY:
                    if (cardView.parent == this)
                        removeChild(cardView);
                    if (cardViewThreeDay.parent != this)
                        addChild(cardViewThreeDay);
                    cardViewThreeDay.updateView(weather);
                    break;
            }
        }

        override protected function layout():void {
        }

    }
}

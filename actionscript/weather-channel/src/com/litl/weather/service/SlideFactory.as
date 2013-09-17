package com.litl.weather.service
{

    import com.litl.control.listclasses.IItemRenderer;
    import com.litl.helpers.slideshow.ISlideFactory;
    import com.litl.helpers.slideshow.SlideshowManager;
    import com.litl.helpers.slideshow.event.SlideFactoryEvent;
    import com.litl.sdk.service.ILitlService;
    import com.litl.weather.renderer.CardItemRenderer;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;

    public class SlideFactory implements ISlideFactory
    {
        public static const CARD_WIDTH:int = 296;
        public static const CARD_HEIGHT:int = 152;

        private var _manager:SlideshowManager;

        private var renderer:CardItemRenderer;
        private var background:Sprite;
        protected var backgroundImage:Sprite;
        private var watermark:DisplayObject = null;
        private var selector:Bitmap;

        [Embed(source = "/../assets/images/weather-selector.png")]
        private static const selectorClass:Class;

        public function SlideFactory() {

            initialize();
        }

        public function get manager():SlideshowManager {
            return _manager;
        }

        public function set manager(value:SlideshowManager):void {
            _manager = value;
        }

        protected function initialize():void {
            internalDispatcher = new EventDispatcher();
        }

        public function prepareSlideGeneration():Boolean {

            if (selector == null)
                selector = new selectorClass() as Bitmap;

            manager.setSelector(selector, "selector");

            return true;
        }

        public function createSlide(data:Object):IItemRenderer {
            if (renderer == null) {
                renderer = new CardItemRenderer();
                renderer.setSize(CARD_WIDTH, CARD_HEIGHT);
            }

            renderer.data = data;
            renderer.validateNow();

            return renderer;
        }

        public function cleanupSlideGeneration():void {
            if (renderer) {
                renderer.destroy();
                renderer = null;
            }
        }

        /**
         *
         * @param event
         *
         */
        private function onIOError(event:Event):void {
            trace("error occured with " + event.target + ": " + event.type);
        }

        private var internalDispatcher:EventDispatcher;

        /** EventDispatcher proxy since we're extending Actor */
        public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
            return internalDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
        }

        public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
            return internalDispatcher.removeEventListener(type, listener, useCapture);
        }

        public function dispatchEvent(event:Event):Boolean {
            return internalDispatcher.dispatchEvent(event);
        }

        public function hasEventListener(type:String):Boolean {
            return internalDispatcher.hasEventListener(type);
        }

        public function willTrigger(type:String):Boolean {
            return internalDispatcher.willTrigger(type);
        }
    }
}

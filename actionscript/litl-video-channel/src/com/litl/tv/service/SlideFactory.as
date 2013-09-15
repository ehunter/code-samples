package com.litl.tv.service
{

    import com.litl.control.listclasses.IItemRenderer;
    import com.litl.helpers.slideshow.ISlideFactory;
    import com.litl.helpers.slideshow.SlideshowManager;
    import com.litl.helpers.slideshow.event.SlideFactoryEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.renderer.SlideRenderer;

    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.filters.GlowFilter;
    import flash.net.URLRequest;

    public class SlideFactory implements ISlideFactory
    {
        public static const CARD_WIDTH:int = 296;
        public static const CARD_HEIGHT:int = 152;
        public static const SLIDE_WIDTH:int = 200;
        public static const SLIDE_HEIGHT:int = 135;

        private var _manager:SlideshowManager;

        private var background:Sprite;
        private var foreground:Sprite;
        private var selectorImage:Sprite;
        private var renderer:SlideRenderer;
        protected var model:AppModel;
        protected var selectorBgLoader:Loader;
        protected var selectorLogoLoader:Loader;
        protected var cardLoader:Loader;
        protected var backgroundImage:DisplayObject;
        protected var networkLogo:DisplayObject;
        protected var selectorBackground:DisplayObject;
        private var watermark:DisplayObject = null;

        [Embed(source = "/../assets/pbs_general_watermark.png")]
        private static const pbsGeneralWatermark:Class;

        [Embed(source = "/../assets/pbs_kids_watermark.png")]
        private static const pbsKidsWatermark:Class;

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
            model = AppModel.getInstance();
        }

        public function prepareSlideGeneration():Boolean {

            if (background == null) {
                background = new Sprite();
            }

            if (selectorImage == null) {
                selectorImage = new Sprite();
            }

            loadCardBackgroundImage();

            return false;
        }

        /**
         * determines which pbs watermark to use (kids or general) and adds it the stage
         *
         */
        private function addPBSWatermark():void {

            switch (model.currentNetwork) {
                case "pbsKids":
                    watermark = new pbsKidsWatermark();
                    watermark.x = 250;
                    watermark.y = 110;
                    break;
                case "pbs":
                    watermark = new pbsGeneralWatermark();
                    watermark.x = 186;
                    watermark.y = 118;
                    break;
                default:
                    break;
            }

            background.addChild(watermark);

        }

        /**
         * tell the manager this factory is ready
         *
         */
        private function factoryReady():void {
            dispatchEvent(new SlideFactoryEvent(SlideFactoryEvent.READY));
        }

        public function createSlide(data:Object):IItemRenderer {
            if (renderer == null) {
                renderer = new SlideRenderer();
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
         * loads our background image
         *
         */
        private function loadCardBackgroundImage():void {

            var imageToLoad:String = model.currentImageData._cardUrl;
            cardLoader = new Loader();
            var request:URLRequest = new URLRequest();
            request.url = imageToLoad;
            cardLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCardBackgroundImageLoadComplete, false, 0, true);
            cardLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
            cardLoader.load(request);

        }

        /**
         * loads our background image
         *
         */
        private function loadNetworkLogo():void {

            var imageToLoad:String = model.currentImageData._networkLogoUrl;

            if (!selectorLogoLoader)
                selectorLogoLoader = new Loader();
            var request:URLRequest = new URLRequest();
            request.url = imageToLoad;
            selectorLogoLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLogoLoadComplete, false, 0, true);
            selectorLogoLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
            selectorLogoLoader.load(request);

        }

        /**
         * loads our background image
         *
         */
        private function loadSelectorBackground():void {

            var imageToLoad:String = model.currentImageData._backgroundUrl;

            if (!selectorBgLoader)
                selectorBgLoader = new Loader();
            var request:URLRequest = new URLRequest();
            request.url = imageToLoad;
            selectorBgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSelectorBackgroundLoadComplete, false, 0, true);
            selectorBgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError, false, 0, true);
            selectorBgLoader.load(request);

        }

        /**
         *
         * @param event
         * Add the loaded image to our background
         * check to see if we need to add a pbs watermark
         *
         */
        private function onCardBackgroundImageLoadComplete(event:Event):void {

            backgroundImage = cardLoader.content;
            background.addChild(backgroundImage);

            cardLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onCardBackgroundImageLoadComplete);
            cardLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
            manager.setBackground(background, "cardbackground");

            loadSelectorBackground();

        }

        /**
         *
         * @param event
         * Add the loaded image to our background
         * check to see if we need to add a pbs watermark
         *
         */
        private function onLogoLoadComplete(event:Event):void {

            networkLogo = selectorLogoLoader.content;
            selectorImage.addChild(selectorLogoLoader);

            networkLogo.filters = [ new GlowFilter(0xffffff, 1, 100, 100, 3, 2)];

            var selWidth:Number = 1280; //800;
            var selHeight:Number = 800; //500;

            if (selectorBackground) {
                selectorBackground.width = selWidth;
                selectorBackground.height = selHeight;
                networkLogo.x = (selWidth - networkLogo.width) / 2;
                networkLogo.y = (selHeight - networkLogo.height) / 2;
            }
            else {
                networkLogo.x = (selWidth - networkLogo.width) / 2;
                networkLogo.y = (selHeight - networkLogo.height) / 2;
            }

            if ((model.currentNetwork == "pbs") || (model.currentNetwork == "pbsKids")) {
                addPBSWatermark();
            }

            manager.setSelector(selectorImage, "selector");

            selectorLogoLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSelectorBackgroundLoadComplete);
            selectorLogoLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
            selectorLogoLoader = null;

            factoryReady();
        }

        /**
         *
         * @param event
         * Add the loaded image to our background
         * check to see if we need to add a pbs watermark
         *
         */
        private function onSelectorBackgroundLoadComplete(event:Event):void {

            selectorBackground = selectorBgLoader.content;
            selectorImage.addChild(selectorBgLoader);

            selectorBgLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onSelectorBackgroundLoadComplete);
            selectorBgLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
            selectorBgLoader = null;

            loadNetworkLogo();

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

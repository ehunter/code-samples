package com.litl.weather.view
{
    import caurina.transitions.Tweener;

    import com.litl.control.Slideshow;
    import com.litl.control.listclasses.ImageItemRenderer;
    import com.litl.weather.model.twc.*;
    import com.litl.weather.service.WeatherService;
    import com.litl.weather.utils.StringUtils;
    import com.litl.weather.view.ViewManager;

    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.TimerEvent;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.Timer;

    /**
     * @author mkeefe
     */
    public class CardView extends ViewManager
    {

        public var currentImage:String = null;
        public var imageLoader:Loader = new Loader();
        private static const UNKNOWN_TEMP_TEXT:String = "––°";
        private var cardViewRoot:CardViewRoot;
        private var temperatureFormat:TextFormat;

        public function CardView() {
            weatherService = WeatherService.instance;

            super();

            cardViewRoot = new CardViewRoot();
            addChild(cardViewRoot);

            temperatureFormat = new TextFormat();
            temperatureFormat.kerning = true;
            temperatureFormat.letterSpacing = -3;

            init();
        }

        override public function populateView():void {
            updateView(weatherService.getWeather());
        }

        override public function init():void {

            cardViewRoot.error_txt.visible = false;
        }

        override public function updateView(weather:Weather):void {
            if (weather == null) {
                cardViewRoot.error_txt.visible = true;
                return;
            }

            cardViewRoot.error_txt.visible = false;

            // Load Image
            var img:String = Animations.getImage(weatherService.getWeather().cc.icon, weatherService.isDay());

            if (currentImage != img) {
                if (currentImage != null)
                    cardViewRoot.container_mc.removeChild(imageLoader);

                currentImage = img;
                imageLoader = new Loader();
                imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageComplete, false, 0, true);
                imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onImageComplete, false, 0, true);
                imageLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onImageComplete, false, 0, true);
                imageLoader.load(new URLRequest(img));
                cardViewRoot.container_mc.addChild(imageLoader);

            }

            var textColor:uint = Animations.getTextColor(img.substring(4, img.length - 4));

            // Set colors
            cardViewRoot.description_txt.textColor = textColor;
            cardViewRoot.high_txt.textColor = textColor;
            cardViewRoot.low_txt.textColor = textColor;
            cardViewRoot.temp_txt.textColor = textColor;

            // clear default error
            cardViewRoot.error_txt.visible = false;

            cardViewRoot.description_txt.autoSize = TextFieldAutoSize.LEFT;
            cardViewRoot.temp_txt.defaultTextFormat = this.temperatureFormat;
            cardViewRoot.high_txt.autoSize = TextFieldAutoSize.LEFT;
            cardViewRoot.low_txt.autoSize = TextFieldAutoSize.LEFT;
            cardViewRoot.temp_txt.autoSize = TextFieldAutoSize.LEFT;

            // Set conditions
            cardViewRoot.description_txt.text = weather.dayf.day[0].partD.t;
            cardViewRoot.high_txt.text = ((Day(weather.dayf.day[0]).hi == "N/A") ? "High " + UNKNOWN_TEMP_TEXT : "High " + Day(weather.dayf.day[0]).hi + WeatherService.TEMP_SCALE);
            cardViewRoot.low_txt.text = ((Day(weather.dayf.day[0]).hi == "N/A") ? "Low " + UNKNOWN_TEMP_TEXT : "Low " + Day(weather.dayf.day[0]).low + WeatherService.TEMP_SCALE);
            cardViewRoot.temp_txt.text = weather.cc.tmp + WeatherService.TEMP_SCALE;

            cardViewRoot.low_txt.alpha = .5;

            layout();
        }

        protected function onImageComplete(event:Event):void {
            imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageComplete);
            imageLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onImageComplete);
            imageLoader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onImageComplete);
            dispatchEvent(new Event(Event.COMPLETE));
        }

        private function layout():void {
            cardViewRoot.temp_txt.y = 45;
            //cardViewRoot.temp_txt.border = true;
            cardViewRoot.description_txt.y = (cardViewRoot.temp_txt.y + 60);
            //cardViewRoot.description_txt.border = true;
            cardViewRoot.high_txt.y = cardViewRoot.low_txt.y = (cardViewRoot.description_txt.y + 19);
            cardViewRoot.low_txt.x = (cardViewRoot.high_txt.x + cardViewRoot.high_txt.width + 2);
        }
    }
}

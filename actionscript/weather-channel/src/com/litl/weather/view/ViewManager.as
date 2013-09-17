package com.litl.weather.view
{
    import com.litl.weather.model.twc.Weather;
    import com.litl.weather.service.WeatherService;

    import flash.display.MovieClip;

    public class ViewManager extends MovieClip
    {
        public var type:String;

        public var channelWidth:int = 0;
        public var channelHeight:int = 0;

        protected var weatherService:WeatherService;

        public function ViewManager() {
            weatherService = WeatherService.instance;
        }

        public function init():void {

        }

        public function populateView():void {

        }

        public function updateView(weather:Weather):void {
            trace("ViewManager::updateView()");
        }

        public function setLoading(loading:Boolean):void {

        }

        public function fadeOut():void {

        }

        public function fadeIn():void {

        }

    }
}

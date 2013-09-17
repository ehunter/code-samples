package com.litl.weather.view
{
    import com.litl.weather.model.twc.*;
    import com.litl.weather.service.WeatherService;
    import com.litl.weather.utils.StringUtils;
    import com.litl.weather.view.ViewManager;

    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.geom.ColorTransform;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;

    /**
     * @author mkeefe
     */
    public class CardViewThreeDay extends ViewManager
    {

        private static const UNKNOWN_TEMP_TEXT:String = "––°";
        private var cardViewThreeDayRoot:CardViewThreeDayRoot;

        public function CardViewThreeDay() {
            weatherService = WeatherService.instance;

            cardViewThreeDayRoot = new CardViewThreeDayRoot();
            addChild(cardViewThreeDayRoot);

            super();
        }

        override public function populateView():void {
            updateView(weatherService.getWeather());
        }

        override public function init():void {
            trace("Init cardViewThreeDay View");

        }

        override public function updateView(weather:Weather):void {
            if (weather == null) {
                trace("No valid weather data, don't update!");
                return; // no valid data, ignore!
            }

            for (var i:int = 1; i < 4; i++) {
                cardViewThreeDayRoot['forecastDay' + i].high_txt.text = ((Day(weather.dayf.day[i]).hi == "N/A") ? UNKNOWN_TEMP_TEXT : Day(weather.dayf.day[i]).hi + WeatherService.TEMP_SCALE);
                cardViewThreeDayRoot['forecastDay' + i].low_txt.text = ((Day(weather.dayf.day[i]).low == "N/A") ? UNKNOWN_TEMP_TEXT : Day(weather.dayf.day[i]).low + WeatherService.TEMP_SCALE);

                var weatherDescription:String;

                if (weather.dayf.day[i].partN.t == "Scattered T-Storms") {
                    weatherDescription = "Storms";
                }
                else {
                    weatherDescription = weather.dayf.day[i].partN.t;
                }
                cardViewThreeDayRoot['forecastDay' + i].description_txt.text = weatherDescription;
                cardViewThreeDayRoot['forecastDay' + i].description_txt.autoSize = TextFieldAutoSize.LEFT;

                cardViewThreeDayRoot['forecastDay' + i].low_txt.alpha = .5;

                var day:String = weather.dayf.day[i].t;
                var trimmedDay:String = day.substr(0, 3);
                cardViewThreeDayRoot['forecastDay' + i].day_txt.htmlText = "<b>" + trimmedDay.toUpperCase() + "</b>";
            }

        }
    }
}

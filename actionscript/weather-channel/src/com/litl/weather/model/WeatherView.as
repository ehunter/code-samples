package com.litl.weather.model
{
    import com.litl.helpers.slideshow.IHashable;
    import com.litl.weather.model.twc.Weather;

    public class WeatherView implements IHashable
    {
        public static const VIEW_NORMAL:String = "normal";
        public static const VIEW_THREE_DAY:String = "threeDay";

        public var weather:Weather;
        public var viewType:String;

        public function WeatherView(weather:Weather, viewType:String = "normal") {
            this.weather = weather;
            this.viewType = viewType;
        }

        public function hash():String {
            return weather.hash() + "-" + viewType;
        }
    }
}

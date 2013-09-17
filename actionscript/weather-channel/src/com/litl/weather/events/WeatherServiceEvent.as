package com.litl.weather.events
{
    import Boolean;
    import String;
    import flash.events.Event;

    /**
     * @author mkeefe
     */
    public class WeatherServiceEvent extends Event
    {
        public static const WEATHER_DATA_LOADING:String = "onWeatherDataLoading";
        public static const WEATHER_DATA_LOADED:String = "onWeatherDataLoaded";
        public static const SEARCH_DATA_LOADED:String = "onSearchDataLoaded";
        public static const ERROR_LOADING:String = "onErrorLoadingData";

        public function WeatherServiceEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
        }
    }
}

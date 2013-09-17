package com.litl.weather.service
{

    import com.litl.sdk.service.LitlService;
    import com.litl.weather.events.WeatherServiceEvent;
    import com.litl.weather.model.twc.CC;
    import com.litl.weather.model.twc.Day;
    import com.litl.weather.model.twc.DayF;
    import com.litl.weather.model.twc.Head;
    import com.litl.weather.model.twc.Link;
    import com.litl.weather.model.twc.Lnks;
    import com.litl.weather.model.twc.Loc;
    import com.litl.weather.model.twc.Part;
    import com.litl.weather.model.twc.Weather;
    import com.litl.weather.utils.StringUtils;

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.net.URLLoader;
    import flash.net.URLRequest;

    /**
     * @author mkeefe
     */
    public class WeatherService extends EventDispatcher
    {

        public var litl:LitlService;

        public var defaultLoc:String = "";
        public var currentLoc:String = null;

        public var weather:Weather = null;

        public var currentLocID:int = 0;
        public var defaultLocID:int = 0;

        public var locations:Array = [];
        public var locationsData:Array = [];

        public var searchResults:Array = [];
        public var savedLocations:Array = [];
        public var results:XML;

        public static var RADAR_URL:String = "";
        public static var TRAFFIC_URL:String = "";
        public static var API_CODE:String = "A3532191357";
        public static var SEARCH_URL:String = "http://" + API_CODE + ".api.wxbug.net/getLocationsXML.aspx?ACode=" + API_CODE + "&SearchString=%s";
        public static var CURRENT_CONDITIONS_URL:String = "http://" + API_CODE + ".api.wxbug.net/getLiveWeatherRSS.aspx?ACode=" + API_CODE + "&%s&OutputType=1";
        public static var FORECAST_URL:String = "http://" + API_CODE + ".api.wxbug.net/getForecastRSS.aspx?ACode=" + API_CODE + "&%s&OutputType=1";

        public static const TEMP_SCALE:String = "°";

        private var searchLoader:URLLoader;
        public var currentConditionsLoader:URLLoader;
        public var forecastLoader:URLLoader;

        private static var _instance:WeatherService = null;

        private var curResultsTmp:Boolean = false;
        private var curResultsTmpData:Weather = null;
        private var autoAddResult:Boolean = false;
        public var weatherChanged:Boolean = false;

        private var currentLocationCodeLoading:String;
        private var currentSearchCode:String;
        private var currentCityLoading:String;

        public function WeatherService() {

        }

        public static function get instance():WeatherService {
            if (_instance == null) {
                _instance = new WeatherService();
            }
            return _instance;
        }

        public function get location():String {
            return locations[currentLocID];
        }

        public function getWeather():Weather {
            var weather:Weather = Weather(locationsData[currentLocID]);

            if (weather == null) {
                return null;
            }
            else if (weather.loc.id == "") {
                return null;
            }

            return Weather(locationsData[currentLocID]);
        }

        public function removeCurrentLocation():void {
            locations.splice(currentLocID, 1);
            locationsData.splice(currentLocID, 1);

            saveLocations();

            currentLocID--;

            if (currentLocID < 0)
                currentLocID = 0;

            dispatchEvent(new WeatherServiceEvent(WeatherServiceEvent.WEATHER_DATA_LOADED));
        }

        public function removeLocationAt(locationId:int):void {
            locations.splice(locationId, 1);
            locationsData.splice(locationId, 1);

            saveLocations();

            currentLocID -= 1;

            if (currentLocID < 0)
                currentLocID = 0;
        }

        public function addCurrentLocation():void {
            locations.push(getWeather().loc.id);
            getWeather().tmpLocation = false;
            saveLocations();
        }

        public function saveLocations():void {

            var i:int = 1;

            for each (var weather:Weather in locationsData) {
                if (weather.tmpLocation || weather.loc.id == defaultLoc)
                    continue;

                litl.accountProperties['userLoc' + i] = weather.loc.id;
                i++;
            }

        }

        public function clearWeatherDataCache(locID:String = ""):void {
            for (var i:int = 0; i < locationsData.length; i++) {
                if (Weather(locationsData[i]).loc.id == locID)
                    continue;

                locationsData.splice(i, 1);
            }

            if (locationsData.length == 0) {
                locationsData = []; // reset keys
            }
        }

        public function isDay():Boolean {

            var strings:Array = [ locationsData[currentLocID].loc.sunr, locationsData[currentLocID].loc.suns, locationsData[currentLocID].loc.tm ];
            var times:Array = []; // an array to store UTC times

            for (var i:Number = 0; i < strings.length; i++) {
                // gets the next time string
                var time:String = strings[i].toLowerCase();

                // parses the time for hour, minute, am/pm
                var colon:Number = time.indexOf(":");
                var space:Number = time.indexOf(" ");

                var hour:Number = Number(time.substring(0, colon));
                var minute:Number = Number(time.substring(colon + 1, space));
                var isPM:Boolean = time.substring(space + 1, time.length) == "pm" ? true : false;

                if ((isPM) && (hour != 12)) {
                    hour += 12;
                }
                else if ((!isPM) && (hour == 12)) {
                    hour -= 12
                }

                // converts time to UTC for comparison purposes
                // using year=0, month=0, date=0 as filler
                var utc:Number = Date.UTC(0, 0, 0, hour - 1, minute);
                times.push(utc);
            }

            // if time is before sunrise or after sunset, it is night
            if (times[2] < times[0] || times[2] >= times[1]) {
                return false;
            }
            else { // otherwise it is day
                return true;
            }
        }

        public function getSearchByZipCode(loc:String, onComplete:Function):void {

            var url:String = SEARCH_URL.replace("%s", loc);

            searchLoader = new URLLoader();
            searchLoader.addEventListener(Event.COMPLETE, onComplete);
            searchLoader.load(new URLRequest(url));
        }

        public function processSearchByZipCodeResults(evt:Event):void {
            var data:XML = new XML(evt.currentTarget.data);
            var weatherBugNs:Namespace = new Namespace("aws", "http://www.aws.com/aws");
            var searchResults:XMLList = data.weatherBugNs::locations;

            var searchCode:String = (searchResults[0]..@citytype == 0) ? "zipcode" : "citycode";
            var city:String = searchResults[0]..@cityname;
            var stateName:String = searchResults[0]..@statename;
            currentCityLoading = (currentCityLoading == "") ? (city + ", " + stateName) : currentCityLoading;

            getCurrentConditions(currentLocationCodeLoading, searchCode, currentCityLoading);
        }

        public function getCurrentConditions(loc:String = null, searchCode:String = "", city:String = "", tmpSearch:Boolean = false, autoAdd:Boolean = false):void {
            currentLocationCodeLoading = (loc == null) ? currentLoc : StringUtils.between(loc, "(", ")");
            currentCityLoading = (StringUtils.beforeFirst(loc, " (") == loc) ? city : StringUtils.beforeFirst(loc, " (");
            currentSearchCode = (StringUtils.afterLast(loc, ") ") == loc) ? searchCode : StringUtils.afterLast(loc, ") ");

            dispatchEvent(new WeatherServiceEvent(WeatherServiceEvent.WEATHER_DATA_LOADING));

            if ((currentSearchCode == "") || (currentCityLoading == "")) {
                getSearchByZipCode(currentLocationCodeLoading, processSearchByZipCodeResults);
                return;
            }

            curResultsTmp = tmpSearch;
            autoAddResult = autoAdd;

            if (!curResultsTmp) {
                curResultsTmpData = null;
            }

            var url:String = CURRENT_CONDITIONS_URL.replace("%s", (currentSearchCode + "=" + currentLocationCodeLoading));
            currentConditionsLoader = new URLLoader();
            currentConditionsLoader.addEventListener(Event.COMPLETE, currentConditionsLoaded);
            currentConditionsLoader.load(new URLRequest(url));
        }

        public function getForecastConditions(loc:String = null, searchCode:String = ""):void {
            var url:String = FORECAST_URL.replace("%s", (searchCode + "=" + loc));
            forecastLoader = new URLLoader();
            forecastLoader.addEventListener(Event.COMPLETE, forecastConditionsLoaded);
            forecastLoader.load(new URLRequest(url));
        }

        public function doSearch(loc:String):void {
            if (loc == "" || loc == null)
                return;

            var finalLocation:String = loc.replace(",", "");
            var url:String = SEARCH_URL.replace("%s", finalLocation);

            searchLoader = new URLLoader();
            searchLoader.addEventListener(Event.COMPLETE, processSearchResults);
            searchLoader.load(new URLRequest(url));
        }

        private function currentConditionsLoaded(evt:Event):void {
            var response:XML = XML(evt.currentTarget.data);
            weather = new Weather();
            var weatherBugNs:Namespace = new Namespace("aws", "http://www.aws.com/aws");
            // <head> data
            var head:Head = new Head();

            var loc:Loc = new Loc();
            loc.dnam = currentCityLoading;

            if (response..weatherBugNs::country == "USA") {
                loc.id = loc.dnam + " (" + currentLocationCodeLoading + ") zipcode";
            }
            else {
                loc.id = loc.dnam + " (" + currentLocationCodeLoading + ") citycode";
            }

            //CURRENT TIME
            var currentHour:String = response..weatherBugNs::[ "ob-date" ].weatherBugNs::hour.@number;
            var currentMinute:String = response..weatherBugNs::[ "ob-date" ].weatherBugNs::minute.@number;
            var currentAmPm:String = response..weatherBugNs::[ "ob-date" ].weatherBugNs::[ "am-pm" ].@abbrv;
            loc.tm = currentHour + ":" + currentMinute + " " + currentAmPm;

            // LATITUDE AND LONGITUDE
            loc.lat = response..weatherBugNs::[ "latitude" ];
            loc.lat = response..weatherBugNs::[ "longitude" ];

            // SUNRISE
            var sunriseHour:String = response..weatherBugNs::sunrise.weatherBugNs::hour.@number;
            var sunriseMinute:String = response..weatherBugNs::sunrise.weatherBugNs::minute.@number;
            var sunriseAmPm:String = response..weatherBugNs::sunrise.weatherBugNs::[ "am-pm" ].@abbrv;
            loc.sunr = sunriseHour + ":" + sunriseMinute + " " + sunriseAmPm;

            // SUNSET
            var sunsetHour:String = response..weatherBugNs::sunset.weatherBugNs::hour.@number;
            var sunsetMinute:String = response..weatherBugNs::sunset.weatherBugNs::minute.@number;
            var sunsetAmPm:String = response..weatherBugNs::sunset.weatherBugNs::[ "am-pm" ].@abbrv;
            loc.suns = sunsetHour + ":" + sunsetMinute + " " + sunsetAmPm;

            loc.zone = response..weatherBugNs::sunset.weatherBugNs::[ "time-zone" ].@offset;
            loc.zipcode = loc.id;

            if (response..weatherBugNs::InputLocationURL) {
                loc.weatherBugLink = response..weatherBugNs::InputLocationURL;
            }
            else {
                loc.weatherBugLink = response..weatherBugNs::WebURL;
            }

            var cc:CC = new CC();
            cc.lsup = loc.tm;
            cc.obst = response..weatherBugNs::station;
            var roundedTemp:Number = new Number(Math.round(response..weatherBugNs::temp));
            cc.tmp = String(roundedTemp);

            if (response..weatherBugNs::[ "feels-like" ] != "") {
                var roundedFeelsLikeTemp:Number = new Number(Math.round(response..weatherBugNs::[ "feels-like" ]));
                cc.flik = String(roundedFeelsLikeTemp);
            }
            else {
                cc.flik = cc.tmp;
            }

            var conditionFromFeed:String = response..weatherBugNs::[ "current-condition" ];
            // remove any occurences of 'Chance of '  for conditions like 'Chance of Rain', '50% Chance of Rain', etc..
            var currentConditionTrimmed:String = StringUtils.afterLast(conditionFromFeed, "of ");

            cc.t = currentConditionTrimmed;
            cc.icon = cc.t;
            // Wind
            cc.wind.s = response..weatherBugNs::[ "gust-speed" ];
            cc.wind.gust = response..weatherBugNs::[ "gust-direction" ];
            cc.wind.d = response..weatherBugNs::[ "gust-direction" ];
            cc.wind.t = response..weatherBugNs::[ "gust-direction" ];

            // <lnks> data
            var links:Lnks = new Lnks();

            weather.head = head;
            weather.loc = loc;
            weather.lnks = links;
            weather.cc = cc;

            getForecastConditions(currentLocationCodeLoading, currentSearchCode);

        }

        private function forecastConditionsLoaded(evt:Event):void {
            var response:XML = XML(evt.currentTarget.data);

            var weatherBugNs:Namespace = new Namespace("aws", "http://www.aws.com/aws");
            var dayf:DayF = new DayF();
            dayf.lsup = response..weatherBugNs::forecasts.@date;

            for (var i:int = 0; i < 5; i++) {

                var d:XML = XML(response..weatherBugNs::forecasts.weatherBugNs::forecast[i]);
                var day:Day = new Day();
                //day.d = d.attribute('d');
                day.t = d.weatherBugNs::title;
                //day.dt = d.attribute('dt');
                day.hi = d.weatherBugNs::high;
                day.low = d.weatherBugNs::low;
                var conditionFromFeed:String = d.weatherBugNs::[ "short-prediction" ];
                var currentConditionTrimmed:String = "";

                if (StringUtils.contains(conditionFromFeed, "Chance of ")) {
                    currentConditionTrimmed = StringUtils.afterLast(conditionFromFeed, "Chance of ");
                }
                else if (StringUtils.contains(conditionFromFeed, "Chance ")) {
                    currentConditionTrimmed = StringUtils.afterLast(conditionFromFeed, "Chance ");
                }
                else {
                    currentConditionTrimmed = conditionFromFeed;
                }
                // remove any occurences of 'Chance of '  for conditions like 'Chance of Rain', '50% Chance of Rain', etc..

                day.icon = currentConditionTrimmed;

                var dayPart:Part = new Part();
                dayPart.icon = currentConditionTrimmed;
                dayPart.t = currentConditionTrimmed;
                dayPart.bt = conditionFromFeed;

                var nightPart:Part = new Part();
                nightPart.t = currentConditionTrimmed;
                nightPart.bt = conditionFromFeed;
                nightPart.ppcp = d.high;
                nightPart.hmid = d.low;

                day.partD = dayPart;
                day.partN = nightPart;

                dayf.day.push(day);
            }

            weather.dayf = dayf;

            setWeatherChanged(weather);

            dispatchEvent(new WeatherServiceEvent(WeatherServiceEvent.WEATHER_DATA_LOADED));

        }

        private function setWeatherChanged(newWeather:Weather):void {
            // this is a unique city so add it to our data list and change the current location
            if (isCityUnique(newWeather.loc.dnam)) {
                locationsData.push(newWeather);
                currentLocID = (locationsData.length - 1);

                if (autoAddResult)
                    addCurrentLocation();

                weatherChanged = true;

            }
            // this city's not unique, but it has updated weather
            else if (isWeatherUnique(newWeather)) {
                for (var i:int = 0; i < locationsData.length; i++) {
                    if (Weather(locationsData[i]).loc.dnam == newWeather.loc.dnam) {
                        locationsData.splice(i, 1);
                        locationsData.splice(i, 0, newWeather);
                        currentLocID = i;
                    }
                }
                weatherChanged = true;
            }
            // this city exists but it's not our current location and it's weather hasn't changed
            else if (isThisOurCurrentCity(newWeather.loc.dnam)) {
                for (var j:int = 0; j < locationsData.length; j++) {
                    if (Weather(locationsData[j]).loc.dnam == newWeather.loc.dnam) {
                        currentLocID = j;
                    }
                }
                weatherChanged = true;
            }
            // nothing changed
            else {
                weatherChanged = false;
            }

        }

        private function isThisOurCurrentCity(newCity:String):Boolean {
            var currentCity:Boolean = true;

            if (newCity == locationsData[currentLocID].loc.dnam) {
                currentCity = false;
            }

            return currentCity;
        }

        private function isCityUnique(newCity:String):Boolean {
            var unique:Boolean = true;

            for each (var locationWeather:Weather in locationsData) {
                var currentCity:String = locationWeather.loc.dnam

                if (currentCity == newCity) {
                    unique = false;
                }
            }

            return unique;
        }

        private function isWeatherUnique(newWeather:Weather):Boolean {
            var unique:Boolean = false;

            for each (var locationWeather:Weather in locationsData) {

                if (locationWeather.loc.dnam == weather.loc.dnam) {
                    if (newWeather.toString() != locationWeather.toString()) {
                        unique = true;
                    }
                }
            }

            return unique;
        }

        private function processSearchResults(evt:Event):void {
            try {
                results = XML(evt.currentTarget.data);
                dispatchEvent(new Event("searchHandler"));
            }
            catch (error:Error) {
                dispatchEvent(new Event("searchHandlerError"));
            }

        }

    }
}

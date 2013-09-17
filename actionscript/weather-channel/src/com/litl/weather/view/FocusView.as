package com.litl.weather.view
{
    import caurina.transitions.Tweener;
    import caurina.transitions.properties.ColorShortcuts;

    import com.litl.skin.LitlColors;
    import com.litl.skin.parts.DarkSpinner;
    import com.litl.util.DateUtils;
    import com.litl.weather.WeatherChannel;
    import com.litl.weather.events.OpenUrlEvent;
    import com.litl.weather.events.OptionsBubbleEvent;
    import com.litl.weather.events.SearchBoxEvent;
    import com.litl.weather.model.twc.Day;
    import com.litl.weather.model.twc.Weather;
    import com.litl.weather.service.WeatherService;
    import com.litl.weather.tests.WeatherDataTest;
    import com.litl.weather.utils.BitmapGrabber;
    import com.litl.weather.utils.StringUtils;
    import com.litl.weather.view.OptionsBubble;
    import com.litl.weather.view.ViewManager;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.FocusEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.ColorTransform;
    import flash.net.URLRequest;
    import flash.text.StyleSheet;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.ui.Keyboard;
    import flash.utils.setTimeout;

    /**
     * @author mkeefe
     */
    public class FocusView extends ViewManager
    {

        public var currentAni:String = null;
        public var currentAnimationLoader:Loader;
        public var nextAnimationLoader:Loader;
        private var nextAnimationSwf:DisplayObject;
        private var currentAnimationSwf:DisplayObject;

        public var searchBox:SearchBox = null;

        public var removeLocBtn:MovieClip;
        public var addLocBtn:MovieClip;

        private var style:StyleSheet = new StyleSheet();
        private var linkStyle:Object = new Object();
        private var hoverStyle:Object = new Object();

        private var focusViewRoot:FocusViewRoot;
        private var temperatureFormat:TextFormat;
        private static const UNKNOWN_TEMP_TEXT:String = "––°";
        private var optionsBubble:OptionsBubble;
        private var selectorLocations:Array;
        private var currentSelectorLocationText:LocationSelectorCity;
        private var previousSelectorLocationText:LocationSelectorCity;
        private var directionToAnimateSelector:String = "";
        private var locationSelectorMask:Sprite;
        private var selectorTextHolder:Sprite;
        private var currentWeather:Weather;
        private var newAnimationLoaded:Boolean = false;
        private var animationToLoad:String;
        private static var WEATHER_UPDATED_TEXT:String = "last updated";
        private var initiated:Boolean = false;
        public var currentAnimationTimeline:MovieClip;
        private var loadingSpinner:DarkSpinner;

        private static var UP_KEY_CODE:Number = 38;
        private static var DOWN_KEY_CODE:Number = 40;
        private static var WEATHER_BUG_URL:String = "http://www.weatherbug.com";

        public function FocusView() {
            weatherService = WeatherService.instance;

            ColorShortcuts.init();

            focusViewRoot = new FocusViewRoot();
            addChild(focusViewRoot);
            focusViewRoot.visible = false;
            focusViewRoot.weatherBugLogo_mc.addEventListener(MouseEvent.CLICK, onWeatherBugLogoClicked);
            focusViewRoot.weatherBugLogo_mc.buttonMode = true;
            focusViewRoot.weatherBugLogo_mc.useHandCursor = true;

            optionsBubble = new OptionsBubble();
            addChild(optionsBubble);
            optionsBubble.visible = false;
            optionsBubble.addEventListener(SearchBoxEvent.LOCATION_SELECTED, onNewLocationSelected);
            optionsBubble.addEventListener(OptionsBubbleEvent.CLOSE, onOptionsBubbleClosed);

            super();

            ////addLocBtn = focusViewRoot.locationBoxMC.addLocMC;
            ////addLocBtn.addEventListener(MouseEvent.CLICK, addLocationHandler);
            ////addLocBtn.buttonMode = true;
            ////addLocBtn.visible = false;

            updateLocationNav();
        }

        override public function init():void {

        }

        override public function updateView(weather:Weather):void {
            if (weather == null) {
                return; // no valid data, ignore!
            }

            if (weatherService.defaultLoc == weather.loc.id) {
                // hide both buttons, default location
                //addLocBtn.visible = false;
                ////removeLocBtn.visible = false;
            }
            else {
                //addLocBtn.visible = true;
                ////removeLocBtn.visible = false;

                for each (var loc:String in weatherService.locations) {
                    if (loc == weather.loc.id && loc != weatherService.defaultLoc) {
                        ////removeLocBtn.visible = true;
                        //addLocBtn.visible = false;
                        break;
                    }
                }

            }

            if ((!weatherService.weatherChanged) && (initiated)) {
                focusViewRoot.lastUpdated.text = currentWeather.lastUpdatedTime;
                return;
            }

            currentWeather = weather;

            animationToLoad = Animations.getSWF(weatherService.getWeather().cc.icon, weatherService.isDay());

            if (currentAni != animationToLoad) {
                newAnimationLoaded = true;
            }

            /* sequence of animations goes like this (in order to keep animation as smooth as possible)
            1. Selector animates to new text
            2. On complete of selector animation Weather animation loads
            3. On complete of weather animation load, weather animation fades in
            4. On complete of weather fade in, the text fades in
            */

            updateLocationSelector();
            updateLocationNav();

            focusViewRoot.footer.todaysWeather.alpha = 0;
            focusViewRoot.currentForecast.alpha = 0;
            focusViewRoot.todaysForecast.alpha = 0;
            focusViewRoot.tonightsForecast.alpha = 0;

            temperatureFormat = new TextFormat();
            temperatureFormat.kerning = true;
            temperatureFormat.letterSpacing = -6;

            //  Set Text and MovieClip Colors
            var textColor:uint = Animations.getTextColor(animationToLoad.substring(4, animationToLoad.length - 4));
            var textColorWhite:uint = 0xFFFFFF;
            var bgColor:ColorTransform = new ColorTransform();
            bgColor.color = Animations.getColor(animationToLoad.substring(4, animationToLoad.length - 4));
            var tColor:ColorTransform = new ColorTransform();
            tColor.color = textColor;

            var whiteColor:ColorTransform = new ColorTransform();
            whiteColor.color = 0xFFFFFF;

            focusViewRoot.footer.todaysWeather.temp_txt.defaultTextFormat = this.temperatureFormat;
            focusViewRoot.footer.todaysWeather.temp_txt.autoSize = TextFieldAutoSize.LEFT;
            focusViewRoot.footer.todaysWeather.high_txt.autoSize = TextFieldAutoSize.LEFT;
            focusViewRoot.footer.todaysWeather.low_txt.autoSize = TextFieldAutoSize.LEFT;
            focusViewRoot.footer.todaysWeather.description_txt.autoSize = TextFieldAutoSize.LEFT;
            focusViewRoot.lastUpdated.autoSize = TextFieldAutoSize.LEFT;

            focusViewRoot.footer.todaysWeather.temp_txt.textColor = textColor;
            focusViewRoot.footer.todaysWeather.high_txt.textColor = textColor;
            focusViewRoot.footer.todaysWeather.low_txt.textColor = textColor;
            focusViewRoot.footer.todaysWeather.description_txt.textColor = textColor;
            focusViewRoot.footer.todaysWeather.todayText.transform.colorTransform = tColor;
            focusViewRoot.footer.currentForecast = textColor;
            focusViewRoot.footer.todaysForecast = textColor;
            focusViewRoot.footer.tonightsForecast = textColor;
            focusViewRoot.currentForecast.textColor = textColor;
            focusViewRoot.todaysForecast.textColor = textColor;
            focusViewRoot.tonightsForecast.textColor = textColor;
            focusViewRoot.lastUpdated.textColor = textColor;
            focusViewRoot.lastUpdated.alpha = .75;

            trace("weather.cc.tmp " + weather.cc.tmp);
            focusViewRoot.footer.todaysWeather.temp_txt.text = weather.cc.tmp + WeatherService.TEMP_SCALE;

            // Hi/Low
            focusViewRoot.footer.todaysWeather.high_txt.text = ((Day(weather.dayf.day[0]).hi == "N/A") ? "High " + UNKNOWN_TEMP_TEXT : "High " + Day(weather.dayf.day[0]).hi + WeatherService.TEMP_SCALE);
            focusViewRoot.footer.todaysWeather.low_txt.text = ((Day(weather.dayf.day[0]).low == "N/A") ? "Low " + UNKNOWN_TEMP_TEXT : "Low " + Day(weather.dayf.day[0]).low + WeatherService.TEMP_SCALE);
            focusViewRoot.footer.todaysWeather.description_txt.text = weather.dayf.day[0].partD.t;
            focusViewRoot.footer.todaysWeather.low_txt.alpha = .5;

            // Forecast
            /*
            var currentWind:String = (weather.cc.wind.t == "with Calm winds") ? weather.cc.wind.s : "with winds from the " + weather.cc.wind.t + " at " + weather.cc.wind.s + " " + weather.head.us;
            var todayWind:String = (weather.dayf.day[0].partD.wind.t == "with Calm winds") ? weather.dayf.day[0].partD.wind.s : "and winds from the " + weather.dayf.day[0].partD.wind.t + " at " + weather.dayf.day[0].partD.wind.s + " " + weather.head.us;
            var tonightWind:String = (weather.dayf.day[0].partN.wind.t == "with Calm winds") ? weather.dayf.day[0].partN.wind.s : "and winds from the " + weather.dayf.day[0].partN.wind.t + " at " + weather.dayf.day[0].partN.wind.s + " " + weather.head.us;
            var tomorrowWind:String = (weather.dayf.day[1].partD.wind.t == "CALM") ? weather.dayf.day[1].partD.wind.s : "and winds from the " + weather.dayf.day[1].partD.wind.t + " at " + weather.dayf.day[1].partD.wind.s + " " + weather.head.us;
            */
            var todayForecast:String =
                "Today: " + weather.dayf.day[0].partD.t + ". " +
                "High " + weather.dayf.day[0].hi + weather.head.ut + ". " +
                "Winds " + /*todayWind + "." +*/
                "\n\n";
            var tonightForecast:String =
                "Tonight: " + weather.dayf.day[0].partN.t + ". " +
                "Low " + weather.dayf.day[0].low + weather.head.ut + ". " +
                "Winds " + /* tonightWind + "." + */
                "\n\n";
            var tomorrowForecast:String =
                "Tomorrow: " + weather.dayf.day[1].partD.t + ". " +
                "High " + weather.dayf.day[1].hi + weather.head.ut + ". " +
                "Winds " + /* tomorrowWind + "." + */
                "\n\n";

            var currentConditions:String = "<font face='CorpoS' color='#" + textColor.toString(16) + "'><b>CURRENTLY</b> " + weather.cc.t + " and feels like " + weather.cc.flik
                + WeatherService.TEMP_SCALE //+ "\n" + currentWind;

            var todaysConditions:String = "<font face='CorpoS' color='#" + textColor.toString(16) + "'><b>TODAY</b> " + weather.dayf.day[0].partD.bt + " with a high of " + weather.cc.flik
                + WeatherService.TEMP_SCALE //+ "\n" + todayWind;

            var tonightsConditions:String = "<font face='CorpoS' color='#" + textColor.toString(16) + "'><b>TONIGHT</b> " + weather.dayf.day[0].partN.bt + " with a low of " + weather.dayf.day[0].low
                + WeatherService.TEMP_SCALE // + "\n" + tonightWind;

            focusViewRoot.currentForecast.htmlText = currentConditions;
            focusViewRoot.todaysForecast.htmlText = todaysConditions;
            focusViewRoot.tonightsForecast.htmlText = tonightsConditions;

            focusViewRoot.lastUpdated.text = currentWeather.lastUpdatedTime;

            for (var i:Number = 1; i < 5; i++) {
                focusViewRoot.footer['forecastDay' + i].alpha = 0;

                if (i == 1) {
                    focusViewRoot.footer['forecastDay' + i].day.htmlText = "<b>TOMORROW</b>";
                }
                else {
                    focusViewRoot.footer['forecastDay' + i].day.htmlText = "<b>" + Day(weather.dayf.day[i]).t.toUpperCase() + "</b>";
                }

                focusViewRoot.footer['forecastDay' + i].high.text = Day(weather.dayf.day[i]).hi + WeatherService.TEMP_SCALE;
                focusViewRoot.footer['forecastDay' + i].low.text = Day(weather.dayf.day[i]).low + WeatherService.TEMP_SCALE;
                focusViewRoot.footer['forecastDay' + i].description.text = "";

                focusViewRoot.footer['forecastDay' + i].description.textColor = textColor;
                focusViewRoot.footer['forecastDay' + i].high.textColor = textColor;
                focusViewRoot.footer['forecastDay' + i].low.textColor = textColor;
                focusViewRoot.footer['forecastDay' + i].day.textColor = textColor;

                focusViewRoot.footer['forecastDay' + i].low.alpha = .5;

                var truncatedWeatherdescription_txt:String = StringUtils.truncate(Day(weather.dayf.day[i]).partN.t, 18)
                focusViewRoot.footer['forecastDay' + i].description.appendText(truncatedWeatherdescription_txt);

            }

            focusViewRoot.footer.todayBg.alpha = .75;
            focusViewRoot.footer.fiveDayBg.alpha = .75;

            focusViewRoot.visible = true;

            // if there's a new not a new weather animation we don't need to wait for the initial fade in to transition all the text in
            if (!newAnimationLoaded) {
                animateInWeatherInfo();
            }

            // 5 day
            layout();

            if (optionsBubble.visible) {
                optionsBubble.refresh(channelWidth, channelHeight);
            }

            initiated = true;

        }

        private function loadWeatherAnimation():void {

            if (currentAni != animationToLoad) {

                var tempLoader:Loader = new Loader();
                nextAnimationLoader = tempLoader;
                nextAnimationLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBgAnimationLoadComplete);
                nextAnimationLoader.load(new URLRequest(animationToLoad));

                currentAni = animationToLoad;

            }
            else {
                animateInWeatherInfo();
            }
        }

        private function layout():void {
            focusViewRoot.footer.y = (channelHeight - focusViewRoot.footer.fiveDayBg.height);
            focusViewRoot.weatherBugLogo_mc.x = (channelWidth - focusViewRoot.weatherBugLogo_mc.width - 20);
            focusViewRoot.weatherBugLogo_mc.y = 20;
            focusViewRoot.footer.todaysWeather.high_txt.x = focusViewRoot.footer.todaysWeather.low_txt.x = focusViewRoot.footer.todaysWeather.description_txt.x =
                (focusViewRoot.footer.todaysWeather.temp_txt.x + focusViewRoot.footer.todaysWeather.temp_txt.width + 20);

            focusViewRoot.footer.todayBg.width = (focusViewRoot.footer.todaysWeather.x + focusViewRoot.footer.todaysWeather.width + 50);
            focusViewRoot.footer.fiveDayBg.x = (focusViewRoot.footer.todayBg.x + focusViewRoot.footer.todayBg.width + 3);
            focusViewRoot.footer.fiveDayBg.width = (channelWidth - focusViewRoot.footer.fiveDayBg.x);

            for (var i:Number = 1; i < 5; i++) {
                focusViewRoot.footer['forecastDay' + i].x = Math.round(focusViewRoot.footer.fiveDayBg.x + 15 + ((i - 1) * 150));
            }

            focusViewRoot.locationSelector.x = (focusViewRoot.currentForecast.x - 34);

        }

        private function updateLocationSelector():void {

            var locationWithoutZip:String = StringUtils.removeZipInParenthesis(currentWeather.loc.dnam);
            var truncatedLocation:String = StringUtils.truncate(locationWithoutZip, 32)

            if (previousSelectorLocationText) {
                if (previousSelectorLocationText.city_text.text == truncatedLocation) {
                    loadWeatherAnimation();
                    return;
                }
            }

            if (selectorLocations == null) {
                selectorLocations = new Array();
            }

            if (currentSelectorLocationText == null) {
                var locationText:LocationSelectorCity = new LocationSelectorCity();
                currentSelectorLocationText = locationText;
            }

            if (selectorTextHolder == null) {
                selectorTextHolder = new Sprite();
                focusViewRoot.locationSelector.addChild(selectorTextHolder)
                selectorTextHolder.x = 15;
            }

            if (locationSelectorMask == null) {
                locationSelectorMask = new Sprite();
                locationSelectorMask.graphics.clear();
                locationSelectorMask.graphics.beginFill(LitlColors.BLACK, 1);
                locationSelectorMask.graphics.drawRect(0, 0, 173, currentSelectorLocationText.height);
                locationSelectorMask.graphics.endFill();
                locationSelectorMask.x = 15;
                //locationSelectorMask.y = focusViewRoot.locationSelector.y;
                selectorTextHolder.mask = locationSelectorMask;
                locationSelectorMask.mouseChildren = true;
                locationSelectorMask.mouseEnabled = false;
                focusViewRoot.locationSelector.addChild(locationSelectorMask);

            }

            currentSelectorLocationText.city_text.autoSize = TextFieldAutoSize.LEFT;
            currentSelectorLocationText.city_text.htmlText = "<b>" + truncatedLocation + "</b>";
            currentSelectorLocationText.x = 15;

            setLocationSelectorColor();

            selectorTextHolder.addChild(currentSelectorLocationText);
            locationSelectorMask.width = currentSelectorLocationText.width + currentSelectorLocationText.x;

            currentSelectorLocationText.addEventListener(MouseEvent.CLICK, onCurrentLocationClicked);
            currentSelectorLocationText.addEventListener(MouseEvent.MOUSE_OVER, onCurrentLocationOver);
            currentSelectorLocationText.addEventListener(MouseEvent.MOUSE_OUT, onCurrentLocationOut);
            currentSelectorLocationText.buttonMode = true;
            currentSelectorLocationText.useHandCursor = true;

            if (previousSelectorLocationText != null) {
                previousSelectorLocationText.removeEventListener(MouseEvent.CLICK, nextLocationHandler);
                previousSelectorLocationText.buttonMode = false;
                animateLocationSelector(directionToAnimateSelector);
            }
            else {
                previousSelectorLocationText = currentSelectorLocationText;
                currentSelectorLocationText = null;
                loadWeatherAnimation();
            }

        }

        private function onWeatherBugLogoClicked(evt:MouseEvent):void {
            dispatchEvent(new OpenUrlEvent(OpenUrlEvent.OPEN_URL, WEATHER_BUG_URL));
        }

        private function onCurrentLocationClicked(evt:MouseEvent):void {
            var request:URLRequest = new URLRequest(currentWeather.loc.weatherBugLink);
            dispatchEvent(new OpenUrlEvent(OpenUrlEvent.OPEN_URL, request.url));
        }

        private function onCurrentLocationOver(evt:MouseEvent):void {
            var oldText:String = evt.currentTarget.city_text.text;
            evt.currentTarget.city_text.htmlText = "<b><u>" + oldText + "</u></b>";

            var textColor:uint = Animations.getTextColor(animationToLoad.substring(4, animationToLoad.length - 4));
            var colorTransform:ColorTransform = new ColorTransform();
            colorTransform.color = textColor;
            evt.currentTarget.city_text.textColor = textColor;

        }

        private function onCurrentLocationOut(evt:MouseEvent):void {
            var oldText:String = evt.currentTarget.city_text.text;
            evt.currentTarget.city_text.htmlText = "<b>" + oldText + "</b>";

            var textColor:uint = Animations.getTextColor(animationToLoad.substring(4, animationToLoad.length - 4));
            var colorTransform:ColorTransform = new ColorTransform();
            colorTransform.color = textColor;
            evt.currentTarget.city_text.textColor = textColor;

        }

        private function animateLocationSelector(direction:String):void {

            if (direction == "up") {
                currentSelectorLocationText.y = 60;
                Tweener.addTween(previousSelectorLocationText, { y: -60, time: .35, transition: "easeInOutQuart", onComplete: removePreviousLocationText });
                Tweener.addTween(currentSelectorLocationText, { y: 0, time: .35, transition: "easeInOutQuart" });
            }
            else {
                currentSelectorLocationText.y = -60;
                Tweener.addTween(previousSelectorLocationText, { y: 60, time: .35, transition: "easeInOutQuart", onComplete: removePreviousLocationText });
                Tweener.addTween(currentSelectorLocationText, { y: 0, time: .35, transition: "easeInOutQuart" });
            }
        }

        private function removePreviousLocationText():void {
            selectorTextHolder.removeChild(previousSelectorLocationText);

            previousSelectorLocationText = currentSelectorLocationText;
            currentSelectorLocationText = null;

            loadWeatherAnimation();
        }

        private function setLocationSelectorColor():void {
            var textColor:uint = Animations.getTextColor(animationToLoad.substring(4, animationToLoad.length - 4));
            trace("textColor is " + textColor)

            var colorTransform:ColorTransform = new ColorTransform();
            colorTransform.color = textColor;
            focusViewRoot.locationSelector.up_btn.transform.colorTransform = colorTransform;
            focusViewRoot.locationSelector.down_btn.transform.colorTransform = colorTransform;
            currentSelectorLocationText.city_text.textColor = textColor;

        }

        private function onBgAnimationLoadComplete(evt:Event):void {

            nextAnimationLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onBgAnimationLoadComplete);
            var currentAnimationBgDepth:Number = 0;

            nextAnimationSwf = evt.currentTarget.content;
            nextAnimationSwf.alpha = 0;
            focusViewRoot.container_mc.addChild(nextAnimationSwf);

            if (currentAnimationLoader != null) {
                currentAnimationBgDepth = focusViewRoot.container_mc.getChildIndex(nextAnimationSwf);

                currentAnimationTimeline.stopAnimations();
                Tweener.addTween(nextAnimationSwf, { alpha: 1, time: .5, transition: "easeInQuad", onComplete: removeCurrentBgAnimation, onCompleteParams: [ currentAnimationSwf ]});

                    //Tweener.addTween(currentAnimationLoader, { alpha: 0, time: .5, delay: .25, transition: "easeInQuad", onComplete: removeCurrentBgAnimation, onCompleteParams: [ currentAnimationLoader ]});
            }
            else {
                Tweener.addTween(nextAnimationSwf, { alpha: 1, time: .5, transition: "easeInQuad", onComplete: animateInWeatherInfo });
            }

            var bgColor:ColorTransform = new ColorTransform();
            bgColor.color = Animations.getColor(animationToLoad.substring(4, animationToLoad.length - 4));

            Tweener.addTween(focusViewRoot.footer.todayBg, { _color: bgColor.color, time: .25, transition: "easeInQuart" });
            Tweener.addTween(focusViewRoot.footer.fiveDayBg, { _color: bgColor.color, time: .25, transition: "easeInQuart" });

            currentAnimationLoader = nextAnimationLoader;
            currentAnimationSwf = nextAnimationSwf;

            currentAnimationTimeline = currentAnimationLoader.content as MovieClip;
        }

        private function animateInWeatherInfo():void {

            Tweener.addTween(focusViewRoot.footer.todaysWeather, { alpha: 1, time: .35, transition: "easeInQuart", delay: .05 });
            Tweener.addTween(focusViewRoot.currentForecast, { alpha: 1, time: .35, transition: "easeInOutQuart" });
            Tweener.addTween(focusViewRoot.todaysForecast, { alpha: 1, time: .35, transition: "easeInOutQuart" });
            Tweener.addTween(focusViewRoot.tonightsForecast, { alpha: 1, time: .35, transition: "easeInOutQuart" });

            var initDelay:Number = .05;

            for (var i:Number = 1; i < 5; i++) {
                if (i == 4) {
                    Tweener.addTween(focusViewRoot.footer['forecastDay' + i], { alpha: 1, time: .35, transition: "easeInQuart", delay: initDelay + (.03 * i), onComplete: startBgAnimation });
                }
                else {
                    Tweener.addTween(focusViewRoot.footer['forecastDay' + i], { alpha: 1, time: .35, transition: "easeInQuart", delay: initDelay + (.03 * i)});
                }

            }

        }

        private function startBgAnimation():void {
            currentAnimationTimeline.startAnimations();
        }

        private function stopBgAnimation():void {
            currentAnimationTimeline.stopAnimations();
        }

        private function pauseBgAnimation():void {
            currentAnimationTimeline.pauseAnimations();
        }

        private function resumeBgAnimation():void {
            currentAnimationTimeline.resumeAnimations();
        }

        private function removeCurrentBgAnimation(currentLoader:DisplayObject):void {
            animateInWeatherInfo();
            focusViewRoot.container_mc.removeChild(currentLoader);
            currentLoader = null;
        }

        private function onNewLocationSelected(evt:SearchBoxEvent):void {
            dispatchEvent(evt.clone());
        }

        private function onOptionsBubbleClosed(evt:OptionsBubbleEvent):void {
            dispatchEvent(evt.clone());
        }

        public function toggleOptionsBubble(openOptions:Boolean):void {

            if (openOptions) {
                optionsBubble.refresh(this.channelWidth, this.channelHeight);
                optionsBubble.visible = true;
                disableKeyboardNavigation();
            }
            else {
                optionsBubble.visible = false;
                enableKeyboardNavigation();
            }

        }

        private function enableKeyboardNavigation():void {
            this.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        private function disableKeyboardNavigation():void {
            this.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
        }

        private function updateLocationNav():void {

            if (weatherService.locations.length <= 1) {
                disableLocationNav();
            }
            else {
                enableLocationNav();
            }
        }

        private function disableLocationNav():void {
            focusViewRoot.locationSelector.up_btn.removeEventListener(MouseEvent.CLICK, prevLocationHandler);
            focusViewRoot.locationSelector.up_btn.buttonMode = false;

            focusViewRoot.locationSelector.down_btn.removeEventListener(MouseEvent.CLICK, nextLocationHandler);
            focusViewRoot.locationSelector.down_btn.buttonMode = false;

            focusViewRoot.locationSelector.down_btn.alpha = .25;
            focusViewRoot.locationSelector.up_btn.alpha = .25;

            disableKeyboardNavigation();

        }

        private function enableLocationNav():void {
            focusViewRoot.locationSelector.up_btn.addEventListener(MouseEvent.CLICK, prevLocationHandler);
            focusViewRoot.locationSelector.up_btn.buttonMode = true;

            focusViewRoot.locationSelector.down_btn.addEventListener(MouseEvent.CLICK, nextLocationHandler);
            focusViewRoot.locationSelector.down_btn.buttonMode = true;

            focusViewRoot.locationSelector.down_btn.alpha = 1;
            focusViewRoot.locationSelector.up_btn.alpha = 1;

            if (!optionsBubble.visible) {
                enableKeyboardNavigation();
            }

        }

        private function onKeyDown(evt:KeyboardEvent):void {
            var keyCode:Number = evt.keyCode;

            switch (keyCode) {
                case UP_KEY_CODE:
                    prevLocationHandler(null);
                    break;
                case DOWN_KEY_CODE:
                    nextLocationHandler(null);
                    break;
                default:
                    break;
            }
        }

        private function selectLocationHandler(evt:Event):void {
            WeatherChannel(parent).doQuickSearch(searchBox.selectedItem.id, searchBox.selectedItem.searchCode, searchBox.selectedItem.location);

        }

        private function locationSelectHandler(evt:FocusEvent):void {
            setTimeout(evt.target.setSelection, 50, 0, evt.target.text.length);
        }

        private function removeLocationHandler(evt:MouseEvent):void {

            weatherService.removeCurrentLocation();

            updateLocationNav();
        }

        private function addLocationHandler(evt:MouseEvent):void {

            weatherService.addCurrentLocation();

            updateLocationNav();
        }

        private function prevLocationHandler(evt:MouseEvent):void {

            var nextLocation:int;
            focusViewRoot.locationSelector.up_btn.removeEventListener(MouseEvent.CLICK, prevLocationHandler);
            focusViewRoot.locationSelector.up_btn.buttonMode = false;

            focusViewRoot.locationSelector.down_btn.removeEventListener(MouseEvent.CLICK, nextLocationHandler);
            focusViewRoot.locationSelector.down_btn.buttonMode = false;

            if (weatherService.currentLocID == 0) {
                nextLocation = (weatherService.locations.length - 1);
            }
            else {
                nextLocation = weatherService.currentLocID - 1;
            }

            directionToAnimateSelector = "up";

            weatherService.getCurrentConditions(weatherService.locations[nextLocation]);

        }

        private function nextLocationHandler(evt:MouseEvent):void {

            var nextLocation:int;
            focusViewRoot.locationSelector.up_btn.removeEventListener(MouseEvent.CLICK, prevLocationHandler);
            focusViewRoot.locationSelector.up_btn.buttonMode = false;

            focusViewRoot.locationSelector.down_btn.removeEventListener(MouseEvent.CLICK, nextLocationHandler);
            focusViewRoot.locationSelector.down_btn.buttonMode = false;

            if (weatherService.currentLocID >= (weatherService.locations.length - 1)) {
                nextLocation = 0
            }
            else {
                nextLocation = (weatherService.currentLocID + 1);
            }

            directionToAnimateSelector = "down";

            weatherService.getCurrentConditions(weatherService.locations[nextLocation]);

        }

        public function duplicateCitySelected(city:String):void {

            optionsBubble.duplicateCitySelected(city);

        }

        override public function setLoading(loading:Boolean):void {
            if (loading) {
                if (!loadingSpinner) {
                    loadingSpinner = new DarkSpinner();
                    loadingSpinner.scaleX = loadingSpinner.scaleY = 1.5;
                    addChild(loadingSpinner);
                }

                loadingSpinner.x = focusViewRoot.locationSelector.width + focusViewRoot.locationSelector.x + 25;
                loadingSpinner.y = focusViewRoot.locationSelector.y + 15;

                if (currentAni) {
                    var bgColor:uint = Animations.getTextColor(currentAni.substring(4, currentAni.length - 4));
                    var spinnerColor:ColorTransform = new ColorTransform();
                    spinnerColor.color = bgColor;
                    loadingSpinner.transform.colorTransform = spinnerColor;
                }
            }
            else {
                if (loadingSpinner) {
                    removeChild(loadingSpinner);
                    loadingSpinner = null;
                }
            }
        }

    }

}

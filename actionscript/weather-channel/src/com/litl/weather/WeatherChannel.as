package com.litl.weather
{

    import caurina.transitions.Tweener;

    import com.litl.control.*;
    import com.litl.helpers.slideshow.SlideshowManager;
    import com.litl.sdk.enum.UpdateProfile;
    import com.litl.sdk.enum.View;
    import com.litl.sdk.message.*;
    import com.litl.sdk.service.LitlService;
    import com.litl.skin.StyleManager;
    import com.litl.weather.events.OpenUrlEvent;
    import com.litl.weather.events.OptionsBubbleEvent;
    import com.litl.weather.events.SearchBoxEvent;
    import com.litl.weather.events.WeatherServiceEvent;
    import com.litl.weather.model.WeatherView;
    import com.litl.weather.model.twc.*;
    import com.litl.weather.service.SlideFactory;
    import com.litl.weather.service.WeatherService;
    import com.litl.weather.utils.StringUtils;
    import com.litl.weather.view.CardSlideView;
    import com.litl.weather.view.ChannelView;
    import com.litl.weather.view.ContentMenuView;
    import com.litl.weather.view.FocusView;
    import com.litl.weather.view.ViewManager;

    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.net.URLLoader;
    import flash.utils.Timer;

    /**
     * @author mkeefe
     */
    [SWF(backgroundColor = "0", frameRate = "30", width = "1280", height = "800")]
    public class WeatherChannel extends MovieClip
    {
        //Managing modes/views of channel: init, card, focus, focusOptions, channel, channelMenu, channelSelector, ...
        private var _mode:String;

        protected var service:LitlService;
        protected var currentView:ViewManager;

        public var defaultLocation:String = "02108"; //"04441"; // Greenville, ME
        public var buildVersion:String = "251";

        public var fetchTimer:Timer;
        public var loader:URLLoader;
        public var currentAnimation:String;
        public var aniLoader:Loader = new Loader();
        public var locs:Array = [];

        private var weatherService:WeatherService;
        private var slideshow:Slideshow;

        private var slideshowManager:SlideshowManager;
        private var slideFactory:SlideFactory;

        private var initialLoad:Boolean = false;
        private var loadCount:int = 0;

        private static var DEFAULT_CHANNEL_TITLE:String = "Weather Channel";

        /**
         * Embed some styles in a css stylesheet. We can instantiate this and plug it into our StyleManager.
         * Note the mimeType is application/octet-stream.
         */
        [Embed(source = "/styles.css", mimeType = "application/octet-stream")]
        private static var skinCSS:Class;

        public function WeatherChannel() {
            weatherService = WeatherService.instance;

            service = new LitlService(this);
            weatherService.litl = service;

            service.addEventListener(InitializeMessage.INITIALIZE, handleInitialize);
            service.addEventListener(InitializeUpdateMessage.INITIALIZE_UPDATE, handleInitializeUpdate);
            service.addEventListener(PropertyMessage.PROPERTY_CHANGED, handlePropertyChanged);
            service.addEventListener(OptionsStatusMessage.OPTIONS_STATUS, handleOptionsStatus);
            service.addEventListener(UserInputMessage.GO_BUTTON_PRESSED, handleGoPressed);
            service.addEventListener(UserInputMessage.GO_BUTTON_HELD, handleGoHeld);
            service.addEventListener(UserInputMessage.GO_BUTTON_RELEASED, handleGoReleased);
            service.addEventListener(UserInputMessage.WHEEL_DOWN, handleWheelNext);
            service.addEventListener(UserInputMessage.WHEEL_UP, handleWheelPrevious);
            service.addEventListener(UserInputMessage.MOVE_NEXT_ITEM, handleMoveNext);
            service.addEventListener(UserInputMessage.MOVE_PREVIOUS_ITEM, handleMovePrevious);
            service.addEventListener(ViewChangeMessage.VIEW_CHANGE, handleViewChange);

            weatherService.addEventListener(WeatherServiceEvent.WEATHER_DATA_LOADED, weatherDataLoaded);
            weatherService.addEventListener(WeatherServiceEvent.WEATHER_DATA_LOADING, weatherDataLoading);

            slideshowManager = new SlideshowManager(service);
            slideFactory = new SlideFactory();

            slideFactory.manager = slideshowManager;
            slideshowManager.slideFactory = slideFactory;

            service.connect(LitlChannelMetadata.CHANNEL_ID, LitlChannelMetadata.CHANNEL_TITLE, LitlChannelMetadata.CHANNEL_VERSION, LitlChannelMetadata.HAS_OPTIONS);

            // Add our stylesheet.
            StyleManager.getInstance().addEmbeddedStylesheet(skinCSS);
        }

        private function onNewLocationSelected(evt:SearchBoxEvent):void {

            if (isCityUnique(evt.city)) {
                doQuickSearch(evt.zip, evt.searchCode, evt.city, true);
            }
            else {
                duplicateCityChosen(evt.city);
            }

        }

        private function duplicateCityChosen(city:String):void {
            if (currentView.type == View.FOCUS) {
                (currentView as FocusView).duplicateCitySelected(city);
            }
        }

        private function isCityUnique(city:String):Boolean {
            var unique:Boolean = true;

            var newCity:String = StringUtils.removeZipInParenthesis(city);

            for each (var locationWeather:Weather in weatherService.locationsData) {
                var currentCity:String = StringUtils.removeZipInParenthesis(locationWeather.loc.dnam);

                if (currentCity == newCity) {
                    unique = false;
                }
            }

            return unique;
        }

        public function doQuickSearch(zip:String, searchCode:String, city:String, autoAdd:Boolean = false):void {
            weatherService.getCurrentConditions(zip, searchCode, city, true, autoAdd);

            if (fetchTimer)
                fetchTimer.stop();
        }

        public function removeView():void {
            if (currentView != null) {
                removeChild(currentView);
                currentView = null;
            }
        }

        private function handleInitialize(e:InitializeMessage):void {

            service.channelItemCount = 2;

            // Set title
            service.channelTitle = DEFAULT_CHANNEL_TITLE; // - v" + buildVersion;

            // Push locations into their place
            weatherService.locations = [];

            if (weatherService.defaultLoc != "")
                weatherService.locations.push(weatherService.defaultLoc);

            for (var i:int = 0; i < locs.length; i++) {
                weatherService.locations.push(locs[i]);
            }

            // Test data - for use with new version of weatherBug API
            //weatherService.locations.push("Tokyo, Japan (800288) citycode");
            //weatherService.saveLocations();

            initialLoad = true;

            if (weatherService.locations.length <= 0) {
                currentView.updateView(null);
            }
            else {
                weatherService.getCurrentConditions(weatherService.locations[0]);
            }

            if (!fetchTimer) {
                // Refresh timer
                fetchTimer = new Timer(600000, 0);
                fetchTimer.addEventListener(TimerEvent.TIMER, weatherUpdateHandler);
                fetchTimer.start();
            }

            service.setUpdateProfile(UpdateProfile.HOURLY);
        }

        private function handleInitializeUpdate(e:InitializeUpdateMessage):void {

            if (weatherService.locations.length <= 0) {
                weatherService.getCurrentConditions(weatherService.defaultLoc);
            }
            else {
                weatherService.getCurrentConditions(weatherService.currentLoc);
            }

            setChannelTitle();

        }

        private function handlePropertyChanged(e:PropertyMessage):void {
            var properties:Array = e.parameters;

            for (var i:uint = 0; i < properties.length; i++) {

                if (properties[i].name == 'zipCode') {
                    if (String(properties[i].value).length > 3) {
                        weatherService.defaultLoc = properties[i].value;
                    }
                }

                if (properties[i].name.indexOf('userLoc') != -1) {
                    if (locs.indexOf(properties[i].value) < 0)
                        locs.push(properties[i].value);
                }
            }
        }

        private function handleOptionsStatus(e:OptionsStatusMessage):void {

            if (currentView.type == View.FOCUS) {
                (currentView as FocusView).toggleOptionsBubble(e.optionsOpen);
            }
        }

        private function handleGoPressed(e:UserInputMessage):void {
            trace(e.toString());
        }

        private function handleGoHeld(e:UserInputMessage):void {
            trace(e.toString());
        }

        private function handleMoveNext(e:UserInputMessage):void {
            if (weatherService.getWeather() == null)
                return;

            if (currentView is CardSlideView)
                CardSlideView(currentView).slideNext();
        }

        private function handleMovePrevious(e:UserInputMessage):void {
            if (weatherService.getWeather() == null)
                return;

            if (currentView is CardSlideView)
                CardSlideView(currentView).slidePrev();
        }

        private function handleGoReleased(e:UserInputMessage):void {

            if (currentView.type == View.CHANNEL) {
                trace("ChannelView(currentView).viewingFiveDay " + ChannelView(currentView).viewingFiveDay)

                if (!ChannelView(currentView).viewingFiveDay) {
                    service.enableWheel();

                    ChannelView(currentView).viewingFiveDay = true;

                    if (!contentMenu) {
                        var contentMenu:ContentMenuView = new ContentMenuView();
                        contentMenu.init();
                        ChannelView(currentView).addChild(contentMenu);
                    }

                    ChannelView(currentView).fiveDay = contentMenu;

                    contentMenu.channelHeight = ChannelView(currentView).channelHeight;
                    contentMenu.channelWidth = ChannelView(currentView).channelWidth;

                    currentView.fadeOut();
                    contentMenu.updateView(weatherService.getWeather());
                }
                else {
                    service.disableWheel();

                    ChannelView(currentView).viewingFiveDay = false;

                    if (contentMenu) {
                        ChannelView(currentView).removeChild(contentMenu);
                        contentMenu = null;
                    }

                    currentView.fadeIn();
                    currentView.updateView(weatherService.getWeather());
                }
            }
        }

        private function handleWheelPrevious(e:UserInputMessage):void {

            var previousLocation:int;

            if (weatherService.currentLocID == 0) {
                previousLocation = weatherService.locations.length - 1;
            }
            else {
                previousLocation = (weatherService.currentLocID - 1);
            }

            weatherService.getCurrentConditions(weatherService.locations[previousLocation]);

        }

        private function handleWheelNext(e:UserInputMessage):void {
            var nextLocation:int;

            if (weatherService.currentLocID >= (weatherService.locations.length - 1)) {
                nextLocation = 0
            }
            else {
                nextLocation = (weatherService.currentLocID + 1);
            }

            weatherService.getCurrentConditions(weatherService.locations[nextLocation]);
        }

        private function handleViewChange(e:ViewChangeMessage):void {
            var newView:String = e.view;
            var newDetails:String = e.details;
            var viewWidth:Number = e.width;
            var viewHeight:Number = e.height;

            var oldView:ViewManager;

            service.disableWheel(); // disable wheel, just in case

            // Remove the current view from the display list.
            if (currentView && contains(currentView)) {
                // check for duplicate view
                if (currentView.type != newView) {
                    if (currentView.type == View.FOCUS) {
                        (currentView as FocusView).currentAnimationTimeline.stopAnimations();
                    }
                    else if (currentView.type == View.CHANNEL) {
                        (currentView as ChannelView).currentAnimationTimeline.stopAnimations();
                    }
                    removeChild(currentView);
                    currentView = null;
                }
            }

            oldView = currentView;

            switch (newView) {
                default:
                    throw new Error("Unknown view state");
                    break;

                case View.CHANNEL:
                    if (currentView == null) {
                        _mode = "channel";
                        currentView = new ChannelView();
                        currentView.type = View.CHANNEL;
                    }
                    break;

                case View.FOCUS:
                    if (currentView == null) {
                        _mode = "focus";
                        currentView = new FocusView();
                        currentView.type = View.FOCUS;
                        currentView.addEventListener(SearchBoxEvent.LOCATION_SELECTED, onNewLocationSelected);
                        currentView.addEventListener(OptionsBubbleEvent.CLOSE, onOptionsBubbleClosed);
                        currentView.addEventListener(OpenUrlEvent.OPEN_URL, onOpenUrlEvent);

                            // no weather, pull in default
                        /*
                        if ((weatherService.getWeather() == null) && (!initialLoad)) {
                            doQuickSearch(defaultLocation);
                        }
                        */
                    }
                    break;

                case View.CARD:
                    if (currentView == null) {
                        _mode = "card";

                        currentView = new CardSlideView();
                        currentView.type = View.CARD;
                    }
                    break;
            }

            currentView.channelWidth = viewWidth;
            currentView.channelHeight = viewHeight;

            if (!contains(currentView)) {
                addChild(currentView);
            }

            //if(oldView == null || oldView.type != currentView.type)
            //{
            updateCard();
            //}
        }

        public function updateCard():void {

            currentView.init();

            if (weatherService.getWeather() != null) {
                currentView.updateView(weatherService.getWeather());
            }
        }

        private function onOptionsBubbleClosed(evt:OptionsBubbleEvent):void {
            service.closeOptions();
        }

        private function weatherUpdateHandler(evt:Event):void {

            weatherService.getCurrentConditions(weatherService.locations[weatherService.currentLocID]);
        }

        private function weatherDataLoading(evt:Event):void {
            currentView.setLoading(true);
        }

        private function weatherDataLoaded(evt:Event):void {

            if (initialLoad) {

                loadCount++;

                if (loadCount >= weatherService.locations.length) {

                    weatherService.currentLocID = weatherService.defaultLocID;
                    weatherService.currentLoc = weatherService.defaultLoc;
                    currentView.setLoading(false);
                    currentView.updateView(weatherService.getWeather());
                    addDataToSlideshowManager();
                    initialLoad = false;

                }
                else {
                    weatherService.getCurrentConditions(weatherService.locations[loadCount]);
                }
            }
            else {
                currentView.setLoading(false);
                currentView.updateView(weatherService.getWeather());
                addDataToSlideshowManager();
            }

            setChannelTitle();

            if ((fetchTimer) && (!fetchTimer.running)) {
                fetchTimer.start();
            }

        }

        private function setChannelTitle():void {
            var currentWeather:Weather = weatherService.getWeather();
            var currentCityName:String = "";

            if (currentWeather != null) {
                var indexOfComma:int = currentWeather.loc.dnam.indexOf(",");
                currentCityName = currentWeather.loc.dnam.substr(0, indexOfComma);
            }

            if (currentCityName != "") {
                service.channelTitle = currentCityName + " Weather";
            }
            else {
                service.channelTitle = DEFAULT_CHANNEL_TITLE;
            }
        }

        private function addDataToSlideshowManager():void {
            var data:Array = new Array();

            var currentWeather:Weather = weatherService.getWeather();

            data.push(new WeatherView(currentWeather, WeatherView.VIEW_NORMAL));
            data.push(new WeatherView(currentWeather, WeatherView.VIEW_THREE_DAY));
            slideshowManager.dataProvider = data;
        }

        private function onOpenUrlEvent(evt:OpenUrlEvent):void {
            service.openURL(evt.url);
        }

    }
}

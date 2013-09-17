package com.litl.weather.view
{
    import caurina.transitions.Tweener;

    import com.litl.weather.events.FiveDayItemEvent;
    import com.litl.weather.model.twc.*;
    import com.litl.weather.service.WeatherService;
    import com.litl.weather.utils.StringUtils;
    import com.litl.weather.view.ViewManager;
    import com.litl.skin.parts.LightSpinner;

    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;

    public class ContentMenuView extends ViewManager
    {

        public var currentImage:String = null;
        public var imageLoader:Loader = new Loader();
        private var itemsVisible:Boolean = false;
        private var weather:Weather;
        private var refreshView:Boolean = false;
        private var locationDots:Array;
        private var contentMenuViewRoot:ContentMenuViewRoot;
        private var fiveDayItems:Array;
        private var totalLocations:Number = 0;
        private var isDay:Boolean = true;
        private var loadingSpinner:LightSpinner;

        public function ContentMenuView() {
            weatherService = WeatherService.instance;

            super();
        }

        override public function init():void {
            contentMenuViewRoot = new ContentMenuViewRoot();
            addChild(contentMenuViewRoot);
        }

        override public function updateView(weather:Weather):void {
            if (weather == null)
                return;

            this.weather = weather;

            isDay = weatherService.isDay();

            totalLocations = weatherService.locations.length;

            if ((itemsVisible) && (totalLocations > 1)) {
                if (isCityNameDifferent()) {
                    hideFooterText();
                }
                hideFiveDayItems(true);

                return;
            }

            else if (!itemsVisible) {
                addFiveDayItems();

                // Load Images and set colors
                for (var i:int = 0; i < weather.dayf.day.length; i++) {
                    setFiveDayItemText(i);
                    setFiveDayItemImage(i);
                    setFiveDayItemTextColor(i);
                    showFiveDayItem(i);

                }

                setFooterText();
                showFooterText();
            }

            if (locationDots == null) {
                addLocationDots();
            }

            setCurrentLocationDot();

            layout();
        }

        private function isCityNameDifferent():Boolean {
            var isDifferent:Boolean = false
            var newLocationWithoutZip:String = StringUtils.removeZipInParenthesis(weather.loc.dnam);
            var newCity:String = StringUtils.truncate(newLocationWithoutZip, 32);

            if (newCity != contentMenuViewRoot.footer.location_txt.text) {
                isDifferent = true;
            }
            return isDifferent;

        }

        private function setFooterText():void {
            contentMenuViewRoot.footer.location_txt.autoSize = TextFieldAutoSize.LEFT;
            var locationWithoutZip:String = StringUtils.removeZipInParenthesis(weather.loc.dnam);
            contentMenuViewRoot.footer.location_txt.text = StringUtils.truncate(locationWithoutZip, 32);
            contentMenuViewRoot.footer.location_txt.x = 75;
        }

        /**
         *
         *
         */
        private function addFiveDayItems():void {
            if (fiveDayItems == null) {
                fiveDayItems = new Array();

            }

            var fiveDayItemWidth:int = Math.ceil(ChannelView(this.parent).channelWidth / weather.dayf.day.length);
            var nextX:int = 0;

            for (var i:int = 0; i < weather.dayf.day.length; i++) {

                if (fiveDayItems[i] == null) {
                    var fiveDayItem:FiveDayItem = new FiveDayItem();
                    contentMenuViewRoot.addChildAt(fiveDayItem, 0);

                    fiveDayItems.push(fiveDayItem);

                    fiveDayItems[i].setWidth(fiveDayItemWidth);
                    fiveDayItems[i].x = nextX;
                    fiveDayItems[i].id = i;
                    fiveDayItems[i].addEventListener(FiveDayItemEvent.HIDE_ANIMATION_COMPLETE, onItemHideComplete);

                    nextX += fiveDayItems[i].fiveDayItemRoot.maskMC.width;
                }
            }

        }

        /**
         *
         * @param id
         *
         */
        private function showFiveDayItem(id:int):void {
            if (id != 0)
                fiveDayItems[id].show((id * 0.08));
            else
                fiveDayItems[id].show(0);

            itemsVisible = true;
        }

        /**
         *
         * @param id
         *
         */
        private function setFiveDayItemText(id:int):void {

            if (id == 0) {
                isDay = weatherService.isDay();

                if (weather.dayf.day[id].partD.t == "N/A") {
                    fiveDayItems[id].fiveDayItemRoot.day_txt.text = "TONIGHT";
                    fiveDayItems[id].fiveDayItemRoot.cc_txt.text = weather.dayf.day[id].partN.bt;
                }
                else {
                    fiveDayItems[id].fiveDayItemRoot.day_txt.text = "TODAY";
                    fiveDayItems[id].fiveDayItemRoot.cc_txt.text = weather.dayf.day[id].partD.bt;
                }
            }
            else if (id == 1) {
                fiveDayItems[id].fiveDayItemRoot.day_txt.text = "TOMORROW";
                fiveDayItems[id].fiveDayItemRoot.cc_txt.text = weather.dayf.day[id].partD.bt;
            }
            else {
                fiveDayItems[id].fiveDayItemRoot.day_txt.text = weather.dayf.day[id].t.toUpperCase();
                fiveDayItems[id].fiveDayItemRoot.cc_txt.text = weather.dayf.day[id].partD.bt;
            }

            fiveDayItems[id].fiveDayItemRoot.hi_txt.text = ((Day(weather.dayf.day[id]).hi == "N/A") ? "—" : Day(weather.dayf.day[id]).hi + WeatherService.TEMP_SCALE);
            fiveDayItems[id].fiveDayItemRoot.low_txt.text = weather.dayf.day[id].low + WeatherService.TEMP_SCALE;
            fiveDayItems[id].fiveDayItemRoot.low_txt.alpha = 0.5;
        }

        /**
         *
         * @param id
         *
         */
        private function setFiveDayItemImage(id:int):void {
            var day:Day = weather.dayf.day[id];
            // Load image/swf
            var img:String = Animations.getImage(day.icon, true, true);

            if (id > 0) {
                fiveDayItems[id].loadContent(img);

            }
        }

        /**
         *
         * @param id
         *
         */
        private function setFiveDayItemTextColor(id:int):void {
            var textColor:uint;
            var day:Day = weather.dayf.day[id];

            var imgTxt:String = Animations.getImage(day.icon, true, false);

            if (id > 0) {
                textColor = Animations.getTextColor(imgTxt.substring(4, imgTxt.length - 4));

            }
            else {
                var ani:String = Animations.getSWF(weatherService.getWeather().cc.icon, true);
                textColor = Animations.getTextColor(ani.substring(4, ani.length - 4));
            }

            fiveDayItems[id].setColor(textColor);
        }

        /**
         *
         *
         */
        private function addLocationDots():void {

            locationDots = new Array();

            for (var i:int = 0; i < totalLocations; i++) {
                var locationDot:LocationDot = new LocationDot();
                contentMenuViewRoot.footer.addChild(locationDot);
                locationDots.push(locationDot);
            }
        }

        /**
         *
         *
         */
        private function setCurrentLocationDot():void {
            var selectedLocation:int = weatherService.currentLocID;

            for (var i:int = 0; i < totalLocations; i++) {
                if (i == selectedLocation) {
                    locationDots[i].alpha = .25;
                }
                else {
                    locationDots[i].alpha = 1;
                }
            }
        }

        private function layout():void {
            contentMenuViewRoot.footer.bg.width = channelWidth;
            contentMenuViewRoot.footer.y = (channelHeight - contentMenuViewRoot.footer.height);
            contentMenuViewRoot.footer.x = 0;

            var gap:Number = 24;
            var initX:Number = contentMenuViewRoot.footer.location_txt.x + 7;
            var totalDots:Number = locationDots.length;

            for (var i:int = 0; i < totalDots; i++) {
                locationDots[i].x = initX + (i * gap);
                locationDots[i].y = 107;
            }

        }

        /**
         *
         * @param refresh
         *
         */
        public function hideFiveDayItems(refresh:Boolean):void {
            itemsVisible = false;
            this.refreshView = refresh;

            for (var i:int = 0; i < WeatherService.instance.weather.dayf.day.length; i++) {
                fiveDayItems[i].hide((i * 0.08));
            }
        }

        public function stopAllTweens():void {
            Tweener.removeTweens(contentMenuViewRoot);
        }

        /**
         *
         * @param evt
         *
         */
        private function onItemHideComplete(evt:FiveDayItemEvent):void {
            if ((evt.currentTarget.id >= 4) && (refreshView)) {
                updateView(weather);
            }

        }

        private function hideFooterText():void {
            Tweener.addTween(contentMenuViewRoot.footer.location_txt, { alpha: 0, y: -30, time: .35, transition: "easeOutQuart", onComplete: resetFooterTextPosition });
        }

        private function showFooterText():void {
            Tweener.addTween(contentMenuViewRoot.footer.location_txt, { alpha: 1, y: 12, time: .5, delay: .4, transition: "easeOutQuart" });
        }

        private function resetFooterTextPosition():void {
            contentMenuViewRoot.footer.location_txt.y = 50;
        }

        override public function setLoading(loading:Boolean):void {

            if (loading) {
                if (!loadingSpinner) {
                    loadingSpinner = new LightSpinner();
                    loadingSpinner.scaleX = loadingSpinner.scaleY = 1.5;
                    addChild(loadingSpinner);
                }

                loadingSpinner.x = 25;
                loadingSpinner.y = contentMenuViewRoot.footer.y + 45;

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

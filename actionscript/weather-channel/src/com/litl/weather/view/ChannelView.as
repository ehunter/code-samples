package com.litl.weather.view
{
    import caurina.transitions.Tweener;

    import com.litl.weather.model.twc.*;
    import com.litl.weather.service.WeatherService;
    import com.litl.weather.utils.StringUtils;

    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.geom.ColorTransform;
    import flash.net.URLRequest;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.Timer;

    /**
     * @author mkeefe
     */
    public class ChannelView extends ViewManager
    {

        public var fiveDay:ContentMenuView;

        public var currentAni:String = null;
        public var currentLoader:Loader;

        public var viewingFiveDay:Boolean = false;
        private var weather:Weather;

        private var channelViewRoot:ChannelViewRoot;
        private var temperatureFormat:TextFormat;

        private static const UNKNOWN_TEMP_TEXT:String = "––°";
        private var initiated:Boolean = false;

        public var currentAnimationTimeline:MovieClip;

        private var startAnimationsTimer:Timer;

        public function ChannelView() {
            weatherService = WeatherService.instance;

            channelViewRoot = new ChannelViewRoot();
            addChild(channelViewRoot);

            temperatureFormat = new TextFormat();
            temperatureFormat.kerning = true;
            temperatureFormat.letterSpacing = -20;

            super();
        }

        override public function fadeOut():void {

            currentAnimationTimeline.stopAnimations();
            Tweener.addTween(channelViewRoot.location_txt, { alpha: 0, time: 0.8 });
            Tweener.addTween(channelViewRoot.high_txt, { alpha: 0, time: 0.8 });
            Tweener.addTween(channelViewRoot.low_txt, { alpha: 0, time: 0.8 });
            Tweener.addTween(channelViewRoot.temp_txt, { alpha: 0, time: 0.8 });
            Tweener.addTween(channelViewRoot.description_txt, { alpha: 0, time: 0.8 });
            Tweener.addTween(channelViewRoot.ruler, { alpha: 0, time: 0.8 });
            Tweener.addTween(channelViewRoot.twcLogo_mc, { alpha: 0, time: 0.8 });
            Tweener.addTween(channelViewRoot.lastUpdatedTextField, { alpha: 0, time: .8 });

        }

        override public function fadeIn():void {
            fiveDay.hideFiveDayItems(false);

            Tweener.removeTweens(fiveDay, fiveDay);

            startInitialAnimationTimeout();

            Tweener.addTween(channelViewRoot.location_txt, { alpha: 1.0, time: 1.2, delay: 0.35 });
            Tweener.addTween(channelViewRoot.high_txt, { alpha: 1.0, time: 1.2, delay: 0.35 });
            Tweener.addTween(channelViewRoot.low_txt, { alpha: .5, time: 1.2, delay: 0.35 });
            Tweener.addTween(channelViewRoot.temp_txt, { alpha: 1.0, time: 1.2, delay: 0.35 });
            Tweener.addTween(channelViewRoot.description_txt, { alpha: 1.0, time: 1.2, delay: 0.35 });
            Tweener.addTween(channelViewRoot.ruler, { alpha: 1.0, time: 1.2, delay: 0.35 });
            Tweener.addTween(channelViewRoot.twcLogo_mc, { alpha: 1.0, time: 1.2, delay: 0.35 });
            Tweener.addTween(channelViewRoot.lastUpdatedTextField, { alpha: 1.0, time: 1.2, delay: 0.35 });

            removeFiveDay();

        }

        override public function updateView(weather:Weather):void {
            if (weather == null) {
                trace("No valid weather data, don't update!");
                return; // no valid data, ignore!
            }

            else {
                this.weather = weather
            }

            if ((!weatherService.weatherChanged) && (initiated)) {
                channelViewRoot.lastUpdatedTextField.text = weather.lastUpdatedTime;
                return;
            }

            // Load Animation
            var ani:String = Animations.getSWF(weatherService.getWeather().cc.icon, weatherService.isDay());

            if (currentAni != ani) {
                currentAni = ani;
                var tempCurrentLoader:Loader = new Loader();
                tempCurrentLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBgAnimationLoaded);
                tempCurrentLoader.load(new URLRequest(ani));

            }
            else {

                updateFiveDayView();
            }

            if (!viewingFiveDay) {
                // Set colors

                var textColor:uint = Animations.getTextColor(ani.substring(4, ani.length - 4));

                var bgColor:ColorTransform = new ColorTransform();
                bgColor.color = textColor;

                channelViewRoot.location_txt.textColor = textColor;
                channelViewRoot.low_txt.textColor = textColor;
                channelViewRoot.high_txt.textColor = textColor;
                channelViewRoot.temp_txt.textColor = textColor;
                channelViewRoot.description_txt.textColor = textColor;
                channelViewRoot.lastUpdatedTextField.textColor = textColor;
                channelViewRoot.ruler.transform.colorTransform = bgColor;
                channelViewRoot.description_txt.autoSize = TextFieldAutoSize.LEFT;
                channelViewRoot.lastUpdatedTextField.autoSize = TextFieldAutoSize.LEFT;

                channelViewRoot.temp_txt.defaultTextFormat = this.temperatureFormat;

                // Set conditions
                channelViewRoot.location_txt.text = weather.loc.dnam;
                channelViewRoot.high_txt.text = ((Day(weather.dayf.day[0]).hi == "N/A") ? "High " + UNKNOWN_TEMP_TEXT : "High " + Day(weather.dayf.day[0]).hi + WeatherService.TEMP_SCALE);
                channelViewRoot.low_txt.text = ((Day(weather.dayf.day[0]).low == "N/A") ? "Low " + UNKNOWN_TEMP_TEXT : "Low " + Day(weather.dayf.day[0]).low + WeatherService.TEMP_SCALE);
                channelViewRoot.temp_txt.text = weather.cc.tmp + WeatherService.TEMP_SCALE;
                channelViewRoot.description_txt.text = Day(weather.dayf.day[0]).partN.t;
                channelViewRoot.lastUpdatedTextField.text = weather.lastUpdatedTime;

                layout();

                initiated = true;

            }

        }

        /**
         *
         * @return
         *
         */
        private function layout():void {
            channelViewRoot.temp_txt.autoSize = TextFieldAutoSize.LEFT;
            //channelViewRoot.temp_txt).border = true;
            channelViewRoot.location_txt.autoSize = TextFieldAutoSize.LEFT;
            channelViewRoot.low_txt.autoSize = TextFieldAutoSize.LEFT;
            channelViewRoot.high_txt.autoSize = TextFieldAutoSize.LEFT;
            channelViewRoot.ruler.width = channelViewRoot.temp_txt.width;

            channelViewRoot.high_txt.y = channelViewRoot.ruler.y + 22;
            channelViewRoot.low_txt.y = (channelViewRoot.high_txt.y + 50);
            channelViewRoot.description_txt.y = (channelViewRoot.low_txt.y + 50);
            channelViewRoot.lastUpdatedTextField.y = channelViewRoot.description_txt.y + channelViewRoot.description_txt.height + 5;

            channelViewRoot.location_txt.y = (channelHeight - channelViewRoot.location_txt.height - 50);
            //channelViewRoot.location_txt.border = true;

            channelViewRoot.twcLogo_mc.y = channelViewRoot.location_txt.y + channelViewRoot.location_txt.height - channelViewRoot.twcLogo_mc.height;
            channelViewRoot.twcLogo_mc.x = (channelWidth - channelViewRoot.twcLogo_mc.width - 50);
            channelViewRoot.location_txt.width = (channelViewRoot.twcLogo_mc.x - channelViewRoot.location_txt.x - 50);
        }

        private function startInitialAnimationTimeout():void {
            if (!startAnimationsTimer) {
                startAnimationsTimer = new Timer(200, 1);
                startAnimationsTimer.addEventListener(TimerEvent.TIMER, startAnimations);
            }

            if (!startAnimationsTimer.running) {
                startAnimationsTimer.start();
            }
        }

        private function onBgAnimationLoaded(evt:Event):void {

            var target_mc:Loader = evt.currentTarget.loader as Loader;
            target_mc.removeEventListener(Event.COMPLETE, onBgAnimationLoaded);

            // remove the previous animation
            if (currentLoader != null) {
                channelViewRoot.container_mc.removeChild(currentLoader);
                currentLoader = null;
            }

            // set the current animation to our currentLoader
            currentLoader = target_mc;
            currentAnimationTimeline = currentLoader.content as MovieClip;

            // add the newly loaded animation
            channelViewRoot.container_mc.addChild(currentLoader);

            updateFiveDayView();

            if (!viewingFiveDay) {
                currentAnimationTimeline.startAnimations();
            }

        }

        private function startAnimations(evt:TimerEvent):void {
            startAnimationsTimer.stop();
            currentAnimationTimeline.startAnimations();
        }

        private function updateFiveDayView():void {
            if (viewingFiveDay) {
                fiveDay.updateView(weather);
            }
        }

        private function removeFiveDay():void {

            if (this.contains(fiveDay))
                removeChild(fiveDay);
        }

        override public function setLoading(loading:Boolean):void {
            if (viewingFiveDay) {
                fiveDay.setLoading(loading);
            }
        }
    }

}

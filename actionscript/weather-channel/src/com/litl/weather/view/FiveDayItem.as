package com.litl.weather.view
{
    import caurina.transitions.Tweener;

    import com.litl.weather.events.FiveDayItemEvent;

    import flash.display.Loader;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    /**
     * @author mkeefe
     */
    public class FiveDayItem extends MovieClip
    {
        public var loader:Loader = new Loader();
        public var loadDelay:int = 0;

        private var y1_start:Number;
        private var y2_start:Number;
        private var y3_start:Number;
        private var y4_start:Number;
        private var y5_start:Number;

        private var y1_end:Number;
        private var y2_end:Number;
        private var y3_end:Number;
        private var y4_end:Number;
        private var y5_end:Number;

        private var delayTime:Number;
        public var id:Number;

        public var fiveDayItemRoot:FiveDayItemRoot;
        private var temperatureFormat:TextFormat;

        public function FiveDayItem() {
            //alpha = 0;
            if (fiveDayItemRoot == null) {
                fiveDayItemRoot = new FiveDayItemRoot();
                addChild(fiveDayItemRoot);
            }

            /*
            y1_start = fiveDayItemRoot.day_txt.y + 60;
            y2_start = fiveDayItemRoot.cc_txt.y + 60;
            y3_start = fiveDayItemRoot.hi_txt.y + 60;
            y4_start = fiveDayItemRoot.low_txt.y + 60;

            y1_end = fiveDayItemRoot.day_txt.y;
            y2_end = fiveDayItemRoot.cc_txt.y;
            y3_end = fiveDayItemRoot.hi_txt.y;
            y4_end = fiveDayItemRoot.low_txt.y;


            fiveDayItemRoot.day_txt.y = y1_start;
            fiveDayItemRoot.cc_txt.y = y2_start;
            fiveDayItemRoot.hi_txt.y = y3_start;
            fiveDayItemRoot.low_txt.y = y4_start;
*/
            fiveDayItemRoot.alpha = 0;
            /*
            fiveDayItemRoot.cc_txt.alpha = 0;
            fiveDayItemRoot.hi_txt.alpha = 0;
            fiveDayItemRoot.low_txt.alpha = 0;
            */

            temperatureFormat = new TextFormat();
            temperatureFormat.kerning = true;
            temperatureFormat.letterSpacing = -5;

            fiveDayItemRoot.cc_txt.autoSize = TextFieldAutoSize.LEFT;
            fiveDayItemRoot.hi_txt.autoSize = TextFieldAutoSize.LEFT;
            fiveDayItemRoot.low_txt.autoSize = TextFieldAutoSize.LEFT;

            fiveDayItemRoot.hi_txt.defaultTextFormat = temperatureFormat;
            fiveDayItemRoot.low_txt..defaultTextFormat = temperatureFormat;
        }

        public function show(delayTime:Number = 0):void {
            loadDelay = delayTime;
            Tweener.addTween(fiveDayItemRoot, { alpha: 1.0, time: .5, transition: "easeOutQuart", delay: delayTime });

        }

        public function hide(delayTime:Number = 0):void {
            loadDelay = delayTime;
            Tweener.addTween(fiveDayItemRoot, { alpha: 0, time: .2, transition: "easeOutQuart", delay: delayTime, onComplete: onHideComplete });

            Tweener.addTween(loader, { alpha: 0, time: .5, transition: "easeOutQuart", delay: delayTime });
        }

        private function onHideComplete():void {
            resetPositions();
            dispatchEvent(new FiveDayItemEvent(FiveDayItemEvent.HIDE_ANIMATION_COMPLETE));
        }

        private function resetPositions():void {

            /*
            fiveDayItemRoot.day_txt.y = y1_start;
            fiveDayItemRoot.cc_txt.y = y2_start;
            fiveDayItemRoot.hi_txt.y = y3_start;
            fiveDayItemRoot.low_txt.y = y4_start;

            fiveDayItemRoot.day_txt.alpha = 0;
            fiveDayItemRoot.cc_txt.alpha = 0;
            fiveDayItemRoot.hi_txt.alpha = 0;
            fiveDayItemRoot.low_txt.alpha = 0;
            */
            fiveDayItemRoot.alpha = 0;

        }

        public function get container():MovieClip {
            return fiveDayItemRoot.container_mc;
        }

        public function setColor(color:uint):void {
            fiveDayItemRoot.day_txt.textColor = color;
            fiveDayItemRoot.cc_txt.textColor = color;
            fiveDayItemRoot.hi_txt.textColor = color;
            fiveDayItemRoot.low_txt.textColor = color;
        }

        public function setWidth(width:int):void {
            fiveDayItemRoot.maskMC.width = width;
        }

        public function updateView():void {

        }

        public function loadContent(url:String):void {
            //trace("loadContent(" + url + ")");

            if (container.numChildren > 0) {
                container.removeChild(loader);
            }

            loader = new Loader();
            loader.alpha = 0;
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, contentLoaded);
            loader.load(new URLRequest(url));

            container.addChild(loader);
        }

        //public function loadBlank():void
        //{
        //	Tweener.addTween(this, {alpha:1.0, y:0, time:1.2, delay:loadDelay});
        //}

        private function contentLoaded(evt:Event):void {
            Tweener.addTween(loader, { alpha: 1.0, y: 0, time: 1.5 });
        }

    }
}

package com.litl.weather.model.twc
{

    import com.adobe.crypto.MD5;
    import com.litl.helpers.slideshow.IHashable;
    import com.litl.weather.model.twc.CC;
    import com.litl.weather.model.twc.DayF;
    import com.litl.weather.model.twc.Head;
    import com.litl.weather.model.twc.Lnks;
    import com.litl.weather.model.twc.Loc;
    import com.litl.util.DateUtils;

    public class Weather implements IHashable
    {

        // Public Properties:
        public var tmpLocation:Boolean = false;

        // Private Properties:
        private var _head:Head;
        private var _loc:Loc;
        private var _lnks:Lnks;
        private var _cc:CC;
        private var _dayf:DayF;
        private var _lastUpdatedTime:String;

        // Initialization:
        public function Weather() {
            _head = new Head();
            _loc = new Loc();
            _lnks = new Lnks();
            _cc = new CC();
            _dayf = new DayF();
        }

        // Public Methods:
        public function get head():Head {
            return _head;
        }

        public function set head(head:Head):void {
            _head = head;
        }

        public function get loc():Loc {
            return _loc;
        }

        public function set loc(loc:Loc):void {
            _loc = loc;
        }

        public function get lnks():Lnks {
            return _lnks;
        }

        public function set lnks(lnks:Lnks):void {
            _lnks = lnks;
        }

        public function get cc():CC {
            return _cc;
        }

        public function set cc(cc:CC):void {
            _cc = cc;
        }

        public function get dayf():DayF {
            return _dayf;
        }

        public function set dayf(dayf:DayF):void {
            _dayf = dayf;
        }

        public function get lastUpdatedTime():String {

            var lastUpdated:String = String(cc.lsup);

            if (lastUpdated.indexOf("PM") != -1) {
                lastUpdated = lastUpdated.substr(0, lastUpdated.indexOf("PM") + 2);
            }
            else if (lastUpdated.indexOf("AM") != -1) {
                lastUpdated = lastUpdated.substr(0, lastUpdated.indexOf("AM") + 2);
            }

            var lastUpdatedDate:Date = new Date(lastUpdated);
            lastUpdatedDate.setFullYear(new Date().getFullYear());

            var lastUpdatedDateIndex:int = lastUpdated.indexOf(" ");
            var currentCityTime:String = (lastUpdated.substr(0, lastUpdatedDateIndex) + " " + loc.tm);
            var currentCityDate:Date = new Date(currentCityTime);
            currentCityDate.setFullYear(new Date().getFullYear());

            var elapsedTime:String = DateUtils.getElapsedTime(lastUpdatedDate, currentCityDate);
            _lastUpdatedTime = "last updated " + elapsedTime.toLowerCase();

            return _lastUpdatedTime

        }

        public function toString():String {
            return "WEATHER\n" + String(head) + String(loc) + String(lnks) + String(cc) + String(dayf);
        }

        public function hash():String {
            // hash the location and the weather date/time
            return MD5.hash(loc.id + cc.lsup);
        }

    }
}

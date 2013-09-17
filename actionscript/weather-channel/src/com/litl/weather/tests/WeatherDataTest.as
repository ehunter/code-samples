package com.litl.weather.tests
{
    import com.litl.weather.model.twc.*;

    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.net.URLLoader;

    /**
     * @author mkeefe
     */
    public class WeatherDataTest
    {

        public var zip:String = "02330";
        //public var url:String = "http://xoap.weather.com/weather/local/02330?cc=*&dayf=5&link=xoap&prod=xoap&par=1086368400&key=1efa010c2e437650";
        public var url:String = "xml/02330.xml";

        public static var fakeSearch:XML = <search ver="3.0">
                <loc id="USMA0046" type="1">Boston, MA</loc>
                <loc id="UKXX1701" type="1">Boston, United Kingdom</loc>
                <loc id="USGA0062" type="1">Boston, GA</loc>
                <loc id="USIN0052" type="1">Boston, IN</loc>
                <loc id="USKY0719" type="1">Boston, KY</loc>
                <loc id="USNY0145" type="1">Boston, NY</loc>
                <loc id="USVA0081" type="1">Boston, VA</loc>
                <loc id="USIL0841" type="1">New Boston, IL</loc>
                <loc id="USMI0595" type="1">New Boston, MI</loc>
                <loc id="USMO0630" type="1">New Boston, MO</loc>
            </search>;

        public function WeatherDataTest():void {
            trace("Run weather test...");
            trace(" - url: " + url);

            var loader:URLLoader = new URLLoader();
            loader.addEventListener(Event.COMPLETE, weatherDataLoaded);
            loader.load(new URLRequest(url));
        }

        private function weatherDataLoaded(evt:Event):void {
            //trace("Response: " + XML(evt.currentTarget.data));

            var response:XML = XML(evt.currentTarget.data);

            var weather:Weather = new Weather();

            // <head> data
            var head:Head = new Head();
            head.locale = response..head..locale;
            head.form = response..head..form;
            head.ut = response..head..ut;
            head.ud = response..head..ud;
            head.us = response..head..us;
            head.up = response..head..up;
            head.ur = response..head..ur;

            // <loc> data
            var loc:Loc = new Loc();
            loc.id = XMLList(response..loc).attribute('id');
            loc.dnam = response..loc..dnam;
            loc.tm = response..loc..tm;
            loc.lat = response..loc..lat;
            loc.lon = response..loc..lon;
            loc.sunr = response..loc..sunr;
            loc.suns = response..loc..suns;
            loc.zone = response..loc..zone;

            // <lnks> data
            var links:Lnks = new Lnks();
            links.type = XMLList(response..lnks).attribute('type');
            links.link = [];

            for each (var lnk:XML in response..lnks..link) {
                var link:Link = new Link();
                link.l = lnk..l;
                link.t = lnk..t;
                link.pos = lnk.attribute('pos');

                links.link.push(link);
            }

            // <cc> data
            var cc:CC = new CC();
            cc.lsup = response..cc..lsup;
            cc.obst = response..cc..obst;
            cc.tmp = response..cc..tmp;
            cc.flik = response..cc..flik;
            cc.t = response..cc..t[0];
            cc.icon = response..cc..icon[0];

            // Bar
            cc.bar.r = response..cc..bar..r;
            cc.bar.d = response..cc..bar..d;

            // Wind
            cc.wind.s = response..cc..wind..s;
            cc.wind.gust = response..cc..wind..gust;
            cc.wind.d = response..cc..wind..d;
            cc.wind.t = response..cc..wind..t;

            cc.hmid = response..cc..hmid;
            cc.vis = response..cc..vis;

            // UV
            cc.uv.i = response..cc..uv..i;
            cc.uv.t = response..cc..uv..t;

            cc.dewp = response..cc..dewp;

            // Moon
            cc.moon.icon = response..cc..moon..icon;
            cc.moon.t = response..cc..moon..t;

            // <dayf> data
            var dayf:DayF = new DayF();
            dayf.lsup = response..dayf..lsup;

            for each (var d:XML in response..dayf..day) {
                var day:Day = new Day();
                day.d = d.attribute('d');
                day.t = d.attribute('t');
                day.dt = d.attribute('dt');
                day.hi = d..hi;
                day.low = d..low;
                day.sunr = d..sunr;
                day.suns = d..suns;

                var dayPart:Part = new Part();
                dayPart.icon = d..part[0]..icon;
                dayPart.t = d..part[0]..t[0];
                dayPart.wind.s = d..part[0]..wind..s;
                dayPart.wind.gust = d..part[0]..wind..gust;
                dayPart.wind.d = d..part[0]..wind..d[0];
                dayPart.wind.t = d..part[0]..wind..t[0];
                dayPart.bt = d..part[0]..bt;
                dayPart.ppcp = d..part[0]..ppcp;
                dayPart.hmid = d..part[0]..hmid;

                var nightPart:Part = new Part();
                nightPart.icon = d..part[1]..icon;
                nightPart.t = d..part[1]..t[0];
                nightPart.wind.s = d..part[1]..wind..s;
                nightPart.wind.gust = d..part[1]..wind..gust;
                nightPart.wind.d = d..part[1]..wind..d[0];
                nightPart.wind.t = d..part[1]..wind..t[0];
                nightPart.bt = d..part[1]..bt;
                nightPart.ppcp = d..part[1]..ppcp;
                nightPart.hmid = d..part[1]..hmid;

                day.partD = dayPart;
                day.partN = nightPart;

                dayf.day.push(day);
            }

            weather.head = head;
            weather.loc = loc;
            weather.lnks = links;
            weather.cc = cc;
            weather.dayf = dayf;

            trace(weather.toString());
        }

    }
}

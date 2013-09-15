package com.litl.tv.model.webservice
{

    import com.adobe.serialization.json.JSON;
    import com.litl.tv.event.FeedUpdateEvent;
    import com.litl.tv.event.StandardFeedEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.utils.TimeCodeConverter;

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.NetStatusEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.TimerEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.system.Security;
    import flash.utils.Dictionary;
    import flash.utils.Timer;

    public class DiscoveryFeedClient extends EventDispatcher
    {
        protected var _requestQueue:Array;
        protected var _requestId:Number = 0;
        protected var _sessionId:String;

        public var ioError:Boolean = false;
        public var errMsg:String = "";
        public var errCount:int = 0; // number of errors received w/o good data

        public static var IOERROR:String = "IOERROR";

        private var staleCount:int = 0; // number of reads that returned stale data
        private var lastTick:int = 0; // volatile xml counter to verify realtime
        private var dataChanged:Boolean = false;

        private var request:URLRequest = null;
        private var model:AppModel;
        private var url:String = null;
        private var unorganizedData:Array = new Array();

        private var currentFeedData:Object = null;
        private var dataFreshnessTimer:Timer = null;

        private static var _instance:DiscoveryFeedClient;

        /// check every day
        private static const DATA_FRESHNESS_TIMEOUT:int = 86400000;

        /**
         * Get access to the unique Discovery instance (singleton)
         *
         * @return the unique DiscoveryFeedClient instance
         */

        public static function getInstance():DiscoveryFeedClient {
            if (_instance == null)
                _instance = new DiscoveryFeedClient();

            return _instance;
        }

        /**
         * Constructor, never to be used outside
         */
        public function DiscoveryFeedClient() {
            // Allow the player to communicate with our sandbox.
            Security.allowDomain("http://netstorage.discovery.com/feeds/litl/");
            Security.allowDomain("https://s3.amazonaws.com/litl-channel-data/discovery/");

            _requestQueue = [];

            model = AppModel.getInstance();

            setUpDataFreshnessTimer();

            dataFreshnessTimer.start();
        }

        /**
         * setup a timer that checks to see if there is fresh feed data
         */
        private function setUpDataFreshnessTimer():void {
            dataFreshnessTimer = new Timer(DATA_FRESHNESS_TIMEOUT);
            dataFreshnessTimer.addEventListener(TimerEvent.TIMER, onDataFreshnessTimeout);
        }

        private function onDataFreshnessTimeout(evt:TimerEvent):void {
            getVideoFeed(model.showName);
        }

        public function getVideoFeed(showName:String):void {
            var showId:String = model.showFeedId;
            var showUrl:String = "http://netstorage.discovery.com/feeds/litl/" + showId + "-mrss-video-feed.xml";
            fetchXml(showUrl);
        }

        /**
         * Function which executes the call to fetch the xml feed
         *
         * @param	url string location of the xml file
         */

        protected function fetchXml(url:String):void {

            try {
                var httpHeader:URLRequestHeader = new URLRequestHeader("Cache-Control", "no-store");
                var request:URLRequest = new URLRequest(url);
                request.requestHeaders.push(httpHeader);
                request.method = URLRequestMethod.GET;

                var loader:URLLoader = new URLLoader();
                loader.addEventListener(Event.COMPLETE, onFeedLoadComplete);
                loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
                loader.load(request);
            }
            catch (e:Error) {
                onError(null);
            }
        }

        /**
         * onComplete
         * When the XML data has been retrieved
         */
        public function onFeedLoadComplete(event:Event):void {

            event.target.removeEventListener(Event.COMPLETE, onFeedLoadComplete);
            event.target.removeEventListener(IOErrorEvent.IO_ERROR, onError);

            var newLoader:URLLoader = URLLoader(event.target);
            var newFeedData:Object = newLoader.data;

            if (currentFeedData) {
                if (currentFeedData != newFeedData) {
                    model.clearModel();
                    unorganizedData = [];
                    dataChanged = true;
                }
                else {
                    dataChanged = false;
                }

                if (dataChanged) {
                    try {
                        parseXML(event.target);
                        // successful
                        errCount = 0;
                        currentFeedData = newFeedData;
                    }
                    catch (e:Error) {
                        handleException(e);
                    }
                }

            }

            else {
                try {
                    parseXML(event.target);
                    // successful
                    errCount = 0;
                    currentFeedData = newFeedData;
                }
                catch (e:Error) {
                    handleException(e);
                }
            }

        }

        /**
         * parseXML
         * define the namespace and loop through each item node
         */
        private function parseXML(target:Object):void {

            var xmlLoader:URLLoader = URLLoader(target);

            var feedData:XML = new XML(xmlLoader.data);
            var defaultNs:Namespace = new Namespace("http://search.yahoo.com/mrss/");

            // write each Feed item to the screen
            // looping through the XMLList with for each
            var items:XMLList = feedData..item;

            //trace(items + " items ");
            for each (var item:XML in items) {
                renderFeedItem(item);
            }

            // now sort the eisodes by episode number as provided in the feed
            unorganizedData.sort(sortByEpisodeNumber);
            // now reverse that array so the last episode is first in the array
            unorganizedData.reverse();

            /// now add the sorted data to the model
            for each (var episodeData:EpisodeData in unorganizedData) {
                AppModel.addEpisodeData(episodeData);
            }

            var feed:Array = model.episodes;

            if (dataChanged) {

                dispatchEvent(new FeedUpdateEvent(FeedUpdateEvent.FEED_UPDATE, feed));
            }
            else {
                dispatchEvent(new StandardFeedEvent(StandardFeedEvent.VIDEO_DATA_PARSED, feed));
            }

        }

        private function sortByEpisodeNumber(a:EpisodeData, b:EpisodeData):Number {
            var aEpisode:Number = a.getEpisodeNumber();
            var bEpisode:Number = b.getEpisodeNumber();

            if (aEpisode > bEpisode) {
                return 1;
            }
            else if (aEpisode < bEpisode) {
                return -1;
            }
            else {

                return 0;
            }
        }

        /**
         * renderFeedItem
         * define the namespace and loop through each item node
         * @param item is the section of XML
         */
        private function renderFeedItem(item:XML):void {
            // namespaces
            var mediaNs:Namespace = new Namespace("media", "http://search.yahoo.com/mrss/");
            // episode title
            var episodeTitle:String = item.mediaNs::group.mediaNs::category.episode_title;
            var episodeDescription:String = item.description;
            var initialEpisodeNumber:String = item.mediaNs::group.mediaNs::category.episode_number;
            // convert the episode number to a number to remove any leading zeros
            var newEpisodeNumber:Number = new Number(initialEpisodeNumber);
            /// convert it back to a string
            var episodeNumber:String = newEpisodeNumber.toString();
            var videoUrl:String = item.mediaNs::group.mediaNs::content.@url;
            var thumbnailUrl:String = item.mediaNs::group.mediaNs::thumbnail.@url;
            var videoRunTime:Number = new Number(item.mediaNs::group.mediaNs::content.@duration);
            var videoRunTimeFormatted:String = TimeCodeConverter.formatTime(videoRunTime);
            // the feed has width and height reversed
            // TODO - ASK DISCOVERY TO FIX THIS IN THEIR FEED
            var videoWidth:Number = item.mediaNs::group.mediaNs::content.@height;
            var videoHeight:Number = item.mediaNs::group.mediaNs::content.@width;

            unorganizedData.push(new EpisodeData(episodeTitle, episodeDescription, "", episodeNumber, videoUrl, thumbnailUrl, videoWidth, videoHeight, videoRunTimeFormatted, null));
        }

        /**
         * onError
         * Called when there was a communication error with the XML service
         */
        public function onError(event:Event):void {

            ioError = true;
            // we need to degrade here
            dispatchEvent(new Event(IOERROR));
        }

        /**
         * handleException
         * Handles an exception loading or processing the XML data
         *
         */
        public function handleException(e:Error):void {
            // handle data services exceptions: typically they will be xml
            // parsing errors if someone has tweaked the xml
            errMsg = "handleException " + e.name + "," + e.message;
            dispatchEvent(new Event(IOERROR));

            if (errCount == 0) {
                //fetchXml();		// refretch on the first error
            }
            errCount++;
        }
    }

}

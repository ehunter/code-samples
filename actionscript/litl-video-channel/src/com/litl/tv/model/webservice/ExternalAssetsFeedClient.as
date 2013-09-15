package com.litl.tv.model.webservice
{

    import com.adobe.serialization.json.JSON;
    import com.litl.tv.event.ExternalAssetsFeedEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.ImageData;

    import flash.display.*;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.NetStatusEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.system.Security;
    import flash.text.*;

    public class ExternalAssetsFeedClient extends Sprite
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

        public var feedData:XML;
        private var loader:URLLoader = new URLLoader();
        private var request:URLRequest = null;
        private var model:AppModel;
        private var url:String = null;
        private var showName:String;
        private var debugText:TextField;

        // is a Singleton
        private static var _instance:ExternalAssetsFeedClient;
        /// DISCOVERY
        public static const DISCOVERY_FEED_URL:String = "https://s3.amazonaws.com/litl-channel-data/discovery/Discovery_ShowAssets.xml";

        /// PBS
        // for local testing
        //public static const PBS_FEED_URL:String = "../xml/pbs/pbs_ShowAssets_v2.xml";
        public static const PBS_FEED_URL:String = "https://s3.amazonaws.com/litl-channel-data/pbs/pbs_ShowAssets.xml";

        /**
         * Get access to the unique Discovery instance (singleton)
         *
         * @return the unique DiscoveryFeedClient instance
         */

        public static function getInstance():ExternalAssetsFeedClient {
            if (_instance == null)
                _instance = new ExternalAssetsFeedClient();

            return _instance;
        }

        /**
         * Constructor, never to be used outside
         */
        public function ExternalAssetsFeedClient() {
            _requestQueue = [];
        }

        public function getFeed(networkName:String):void {

            Security.allowDomain("https://s3.amazonaws.com/litl-channel-data/");
            /*
                        debugText = new TextField();
                        var tfm:TextFormat = new TextFormat("CorpoS", 14, 0xFFFFFF, false);
                        tfm.align = TextFormatAlign.LEFT;
                        debugText.defaultTextFormat = tfm;
                        debugText.width = 275;
                        debugText.multiline = true;
                        debugText.wordWrap = true;
                        debugText.autoSize = TextFieldAutoSize.LEFT;
                        debugText.text = " Debug Text Added to Stage";
                        addChild(debugText);
                        */
            var feedUrl:String = "";

            switch (networkName) {
                case "pbs":
                    feedUrl = PBS_FEED_URL;
                    break;
                case "pbsKids":
                    feedUrl = PBS_FEED_URL;
                    break;
                case "discovery":
                    feedUrl = DISCOVERY_FEED_URL;
                    break;
                default:
                    break;

            }

            fetchXml(feedUrl);

        }

        /**
         * Function which executes the call to fetch the xml feed
         *
         * @param	url string location of the xml file
         */

        protected function fetchXml(url:String):void {

            try {
                var httpHeader:URLRequestHeader = new URLRequestHeader("Cache-Control", "no-store");
                var currentDate:Date = new Date();
                var timestamp:Object = Math.round((currentDate.time / 10000));
                request = new URLRequest(url + "?" + timestamp);
                request.requestHeaders.push(httpHeader);
                trace("new request is " + request.url);

                if (request != null) {
                    loader.addEventListener(Event.COMPLETE, onFeedLoadComplete);
                    loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
                    loader.load(request);
                }
            }
            catch (e:Error) {
                trace("fetchxml error: " + e);
                onError(null);
            }
        }

        /**
         * onComplete
         * When the XML data has been retrieved
         */
        public function onFeedLoadComplete(event:Event):void {

            try {
                parseXML(event.target);
                // successful
                errCount = 0;
            }
            catch (e:Error) {
                handleException(e);
            }

        }

        /**
         * parseXML
         * define the namespace and loop through each item node
         */
        private function parseXML(target:Object):void {

            var loader:URLLoader = URLLoader(target);
            model = AppModel.getInstance();

            feedData = new XML(loader.data);

            // write each Feed item to the screen
            // looping through the XMLList with for each
            var items:XMLList = feedData..show;

            for each (var item:XML in items) {
                if (item.name == model.showName) {
                    renderFeedItem(item);
                }
            }

            var feed:Array = model.episodes;
            dispatchEvent(new ExternalAssetsFeedEvent(ExternalAssetsFeedEvent.IMAGE_DATA_PARSED, feed));

        }

        /**
         * renderFeedItem
         * define the namespace and loop through each item node
         * @param item is the section of XML
         */
        private function renderFeedItem(item:XML):void {

            // episode title
            var cardUrl:String = item.cardImage;
            var backgroundUrl:String = item.backgroundImage;
            var networkLogoUrl:String = item.networkLogo;
            var showId:String = item.id;

            //EpisodeData(title:String, description:String, number:String, videoUrl:String, thumbnailUrl:String )
            model.addImageData(new ImageData(backgroundUrl, cardUrl, networkLogoUrl));
            model.showFeedId = showId;
            //var feed:VideoFeed = new VideoFeed(evt.target.data as String);
        }

        /**
         * onError
         * Called when there was a communication error with the XML service
         */
        public function onError(event:Event):void {
            trace("there was an ioerror communicating with the xml service.");

            if (errCount == 0) {
                //fetchXml();		refrech on the first error
            }
            errCount++;
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
            trace(errMsg);
            dispatchEvent(new Event(IOERROR));

            if (errCount == 0) {
                //fetchXml();		// refretch on the first error
            }
            errCount++;
        }
    }

}

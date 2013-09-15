package com.litl.tv.model.webservice
{

    import com.adobe.crypto.HMAC;
    import com.adobe.crypto.SHA1;
    import com.adobe.serialization.json.JSON;
    import com.adobe.utils.NumberFormatter;
    import com.litl.tv.event.FeedUpdateEvent;
    import com.litl.tv.event.StandardFeedEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ImageData;
    import com.litl.tv.utils.DateUtilities;
    import com.litl.tv.utils.StringUtils;
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

    public class PBSFeedClient extends EventDispatcher
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

        private var loader:URLLoader = new URLLoader();
        private var request:URLRequest = null;
        private var model:AppModel;
        private var url:String = null;
        private var videoData:Array = new Array();
        private var imageData:Array = new Array();

        public var showNames:Dictionary;
        private var currentVideoFeedData:Object = null;
        private var currentImageFeedData:Object = null;
        private var dataFreshnessTimer:Timer = null;

        private var unorganizedData:Array = new Array();
        private var programsList:String = null;
        private var program_uri:String = null;
        private var program_type:String = null;

        // is a Singleton
        private static var _instance:PBSFeedClient;
        /// for pbs and litl tracking purposes
        private static var LITL_TRACKING_CODE:String = "&player=litl";
        /// maximum number of items we want returned from the feed
        private static var MAX_FEED_ITEMS:Number = 100;

        private static var defaultVideoHeight:Number = 288;
        private static var defaultVideoWidth:Number = 512;

        private static const DATA_FRESHNESS_TIMEOUT:int = 86400000;

        private static const API_ID:String = "Litl-ec085078-65fd-4cd2-8b43-ad733242a7be";
        //private static const API_ID:String = "Public-Destination-07c5773f-344f-4dd4-a3d1-e1e85157f821";
        private static const API_PASSWORD:String = "21c10359-2cc7-437b-8c20-9318afbcfe7f";
        //private static const API_PASSWORD:String = "f650d902-5657-4881-a305-ed96ccae551d";

        private static var kidsShowId:String = "PBS DP KidsGo";
        private static var litlKidsImageType:String = "LittleVideoThumbnail";
        private static var defaultKidsImageType:String = "ThumbnailKidsGoDefault"
        private static var generalImageType:String = "ThumbnailCOVEDefault";
        private static var image_type:String;

        /**
         * Get access to the unique PBS instance (singleton)
         *
         * @return the unique PBSFeedClient instance
         */

        public static function getInstance():PBSFeedClient {
            if (_instance == null)
                _instance = new PBSFeedClient();

            return _instance;
        }

        /**
         * Constructor, never to be used outside
         */
        public function PBSFeedClient() {
            // Allow the player to communicate with our sandbox.
            Security.allowDomain("http://api.pbs.org/cove/");

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

        /**
         * handles the authentication and querying of the pbs programs url
         * this url will return all of the pbs programs Litl has access to
         */
        private function onDataFreshnessTimeout(evt:TimerEvent):void {
            getVideoFeed(model.showName);
        }

        /**
         * handles the authentication and querying of the pbs programs url
         * this url will return all of the pbs programs Litl has access to
         */
        public function getProgramsListFeed():void {

            var currentDate:Date = new Date();
            // get the amount of time since Jan 1, 1970 00:00:00
            var timestamp:Object = Math.round((currentDate.time / 1000));
            // random number - can be anything
            var randomNonce:Number = Math.round(Math.random() * 1000);
            var pbsProgramsUrl:String = "http://api.pbs.org/cove/v1/programs/?consumer_key=" + API_ID + "&nonce=" + randomNonce + "&timestamp=" + timestamp;
            var queryToSign:String = "GET" + pbsProgramsUrl + timestamp + API_ID + randomNonce;
            // and now hash it to create your signature - using the SHA1 algorithm
            var signature:String = HMAC.hash(API_PASSWORD, queryToSign, SHA1);
            // now you have your final feed url to try and load
            var programsFeedUrl:String = pbsProgramsUrl + "&signature=" + signature;
            fetchJSON(programsFeedUrl, onProgramsFeedLoadComplete);

        }

        /**
         *	gets the pbs video feed
         */
        public function getVideoFeed(showName:String):void {

            if (!programsList) {
                getProgramsListFeed();
            }
            else {
                getProgramVideoFeed();
            }

        }

        /**
         * handles the authentication and querying of the final pbs video url
         */
        private function getProgramVideoFeed():void {

            var currentDate:Date = new Date();
            // get the amount of time since Jan 1, 1970 00:00:00
            var timestamp:Object = Math.round((currentDate.time / 1000));
            // random number - can be anything
            var randomNonce:Number = Math.round(Math.random() * 1000);

            var videoQuery:String = getVideoQuery(timestamp, randomNonce);

            var queryToSign:String = "GET" + videoQuery + timestamp + API_ID + randomNonce;
            // and now hash it to create your signature - using the SHA1 algorithm
            var signature:String = HMAC.hash(API_PASSWORD, queryToSign, SHA1);
            // now you have your final feed url to try and load
            var videoFeedUrl:String = videoQuery + "&signature=" + signature;
            fetchJSON(videoFeedUrl, onVideoFeedLoadComplete);
        }

        private function getVideoQuery(timestamp:Object, randomNonce:Number):String {

            var programId:String = determineProgramId(program_uri);
            /*
            12-9-10 currently the PBS feed is broken in a few places
            &filter_type=Episode is not functioning properly
            Edgar from PBS gave us this to fix temporarily - &filter_segment_parent__isnull=true
            UPDATE:
            PBS will soon support WebM (VP8) video formats. they will let us know then that support gets added to their API
            2-14-11 - Currently the 'associated_images' field has a bug. This is why we're seeing a lot of
            default card view images in the filmstrip. Edgar is working on a fix for this.
            */

            var generalVideoQuery:String = "http://api.pbs.org/cove/v1/videos/?consumer_key=" + API_ID + "&fields=associated_images%2Cmediafiles&filter_availability_status=Available&filter_mediafile_set__video_encoding__mime_type=video%2Fmp4&filter_program=" + programId + "&filter_segment_parent__isnull=true&format=json&limit_start=0&limit_stop=" + MAX_FEED_ITEMS + "&nonce=" + randomNonce + "&order_by=-airdate&timestamp=" + timestamp;
            // the query to authenticate
            var kidsVideoQuery:String = "http://api.pbs.org/cove/v1/videos/?consumer_key=" + API_ID + "&fields=associated_images%2Cmediafiles&filter_availability_status=Available&filter_program=" + programId + "&format=json&limit_start=0&limit_stop=" + MAX_FEED_ITEMS + "&nonce=" + randomNonce + "&order_by=-airdate&timestamp=" + timestamp;

            if (program_type == kidsShowId) {
                return kidsVideoQuery;
            }
            else {
                return generalVideoQuery;
            }
        }

        private function getTodaysDateFormatted():String {
            var currentDate:Date = new Date();
            var month:Number = currentDate.getMonth() + 1;
            var day:Number = currentDate.getDate();
            var formattedMonth:String = NumberFormatter.addLeadingZero(month);
            var formattedDate:String = NumberFormatter.addLeadingZero(day);
            var todaysDate:String = currentDate.fullYearUTC + "-" + formattedMonth + "-" + formattedDate;

            return todaysDate;
        }

        /**
         * strips the program id from the program_uri string
         * @param value the uri string
         */
        private function determineProgramId(value:String):String {

            var id:String = StringUtils.between(value, "programs/", "/");
            return id;
        }

        private function getFeedImageType():String {
            if (program_type == kidsShowId) {
                return litlKidsImageType;
            }
            else {
                return generalImageType;
            }

        }

        public function getImageFeed(showName:String):void {

            var currentDate:Date = new Date();
            var showId:String = model.showFeedId;
            // get the amount of time since Jan 1, 1970 00:00:00
            var timestamp:Object = Math.round((currentDate.time / 1000));
            var randomNonce:Number = Math.round(Math.random() * 1000);
            var imageQuery:String = "http://api.pbs.org/cove/v1/programs/?consumer_key=" + API_ID + "&fields=associated_images&filter_nola_root=" + showId + "&format=json&nonce=" + randomNonce + "&timestamp=" + timestamp;
            var queryToSign:String = "GET" + imageQuery + timestamp + API_ID + randomNonce;
            var signature:String = HMAC.hash(API_PASSWORD, queryToSign, SHA1);
            var imageFeedUrl:String = imageQuery + "&signature=" + signature;
            fetchJSON(imageFeedUrl, onImageFeedLoadComplete);

        }

        /**
         * gets a JSON data set
         * @param url is the url to the json data
         * @param onComplete the function to execute when the data has been loaded
         */
        private function fetchJSON(url:String, onComplete:Function):void {

            trace(url)

            try {
                var httpHeader:URLRequestHeader = new URLRequestHeader("Cache-Control", "no-store");
                request = new URLRequest(url);
                request.requestHeaders.push(httpHeader);
                //request.data = new URLVariables("time="+Number(new Date().getTime()));
                request.method = URLRequestMethod.GET;

                if (request != null) {
                    var loader:URLLoader = new URLLoader();
                    loader.dataFormat = URLLoaderDataFormat.TEXT;
                    loader.addEventListener(Event.COMPLETE, onComplete);
                    loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
                    //loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, doHttpStatus);
                    //loader.addEventListener(IOErrorEvent.IO_ERROR, doIOError);
                    //loader.addEventListener(ProgressEvent.PROGRESS, handleProgress);
                    //loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, doSecurityError);
                    loader.load(request);
                }

            }
            catch (e:Error) {
                //trace("fetchJSON error: " + e);
                onError(null);
            }

        }

        /**
         * when the programs list has completed loading
         * find the program in the list that matches this channel
         */
        protected function onProgramsFeedLoadComplete(evt:Event):void {
            loader.removeEventListener(Event.COMPLETE, onProgramsFeedLoadComplete);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);

            var programFeedData:Object = JSON.decode(evt.target.data as String).results;
            var showId:String = model.showFeedId;

            for each (var item:Object in programFeedData) {

                var programTitle:String = item.title as String;

                if (showId == programTitle) {
                    program_uri = item.resource_uri;
                    program_type = item.tp_account;
                    model.programType = program_type;
                    image_type = getFeedImageType();
                    programsList = programFeedData as String;
                    getProgramVideoFeed();
                    return;
                }

            }
        }

        /**
         * check to see if the new data is different from the old data
         * if necessary execute parsing of the video feed
         */
        protected function onVideoFeedLoadComplete(evt:Event):void {

            loader.removeEventListener(Event.COMPLETE, onVideoFeedLoadComplete);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);

            //var newLoader:URLLoader = URLLoader(evt.target);
            var newFeedData:Object = JSON.decode(evt.target.data as String).results;

            if (currentVideoFeedData) {
                if (currentVideoFeedData != newFeedData) {
                    model.clearModel();
                    videoData = [];
                    unorganizedData = [];
                    dataChanged = true;
                }
                else {
                    dataChanged = false;
                }

                if (dataChanged) {
                    try {
                        parseVideoFeed(newFeedData);
                        // successful
                        errCount = 0;
                        currentVideoFeedData = newFeedData;
                    }
                    catch (e:Error) {
                        handleException(e);
                    }
                }

            }

            else {
                try {
                    parseVideoFeed(newFeedData);
                    // successful
                    errCount = 0;
                    currentVideoFeedData = newFeedData;
                }
                catch (e:Error) {
                    handleException(e);
                }
            }
        }

        protected function onImageFeedLoadComplete(evt:Event):void {

            loader.removeEventListener(Event.COMPLETE, onImageFeedLoadComplete);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);

            //var newLoader:URLLoader = URLLoader(evt.target);
            var newFeedData:Object = JSON.decode(evt.target.data as String).results;

            try {
                parseImageFeed(newFeedData);
                // successful
                errCount = 0;
                currentImageFeedData = newFeedData;
            }
            catch (e:Error) {
                handleException(e);
            }
        }

        /**
         * parseVideoFeed
         * loop through each item in the data
         */
        private function parseVideoFeed(target:Object):void {

            for each (var item:Object in target) {
                // filter out the 30 second previews

                if (item.type != "Promotion")
                    renderVideoFeedItem(item);
            }

            // now sort the eisodes by episode number as provided in the feed
            //unorganizedData.sort(sortByAirDateNumber);

            /// now add the data to the model
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

        /**
         * parseVideoFeed
         * loop through each item in the data
         */
        private function parseImageFeed(target:Object):void {

            for each (var item:Object in target) {

                renderImageFeedItem(item);
            }

        }

        /**
         * renderFeedItem
         * define the namespace and loop through each item node
         * @param item is the section of XML
         */
        private function renderVideoFeedItem(item:Object):void {

            var episodeTitle:String = item.title as String;
            var episodeShortDescription:String = item.short_description as String;
            var episodeLongDescription:String = item.long_description as String;
            var initialEpisodeNumber:String = item.nola_episode as String;

            var initialAirDate:String = item.airdate as String;
            var formattedAirDate:String = initialAirDate.slice(0, 10);

            var year:String = formattedAirDate.slice(0, 4);
            var monthFromFeed:Number = new Number(formattedAirDate.slice(5, 7));
            var month:Number = (monthFromFeed - 1);
            var day:String = formattedAirDate.slice(8, 11);
            var airedOnDate:Date = new Date(year, month, day);

            // convert the episode number to a number to remove any leading zeros
            var newEpisodeNumber:Number = new Number(initialEpisodeNumber);

            var episodeNumber:String = "";

            if (newEpisodeNumber) {
                /// convert it back to a string
                episodeNumber = newEpisodeNumber.toString();
            }
            else {
                episodeNumber = "";
            }

            var videoUrl:String = "";
            var videoRunTime:String = "";
            var videoHeight:Number = defaultVideoHeight;
            var videoWidth:Number = defaultVideoWidth;

            for each (var mediaItem:Object in item.mediafiles) {

                // find the media file with the name 'mpeg-4 500kbps', this is the
                // video we want, not the mobile version
                if ((mediaItem.video_encoding.name == "MPEG-4 500kbps") || (mediaItem.video_encoding.name == "Flash 400kbps")) {
                    videoUrl = mediaItem.video_data_url as String;
                    // append &player=litl for tracking to videoUrl
                    videoUrl = videoUrl + LITL_TRACKING_CODE + "&format=SMIL";

                    trace(videoUrl);

                    var useHourConversion:Boolean;

                    if (mediaItem.length_mseconds as Number >= 3600000) {
                        useHourConversion = true;
                    }
                    else {
                        useHourConversion = false;
                    }
                    videoRunTime = TimeCodeConverter.formatTime((mediaItem.length_mseconds / 1000));

                    // feed has height mispelled as 'heigh'
                    if (mediaItem.video_encoding.heigh)
                        videoHeight = mediaItem.video_encoding.heigh;

                    if (mediaItem.video_encoding.width)
                        videoWidth = mediaItem.video_encoding.width;
                }

            }
            var thumbnailUrl:String = "";

            for each (var imageItem:Object in item.associated_images) {

                if (imageItem.type.usage_type == image_type) {
                    thumbnailUrl = imageItem.url as String;
                }
                // fixes temporary bug in PBS Kids feeds. Some shows don't have the new high res image
                // so if they don't have the imageType 'LittleVideoThumbnail' we need to fallback to defaultType
                else if ((imageItem.type.usage_type == defaultKidsImageType) && (program_type == kidsShowId)) {
                    thumbnailUrl = imageItem.url as String;
                }
            }

            unorganizedData.push(new EpisodeData(episodeTitle, episodeShortDescription, episodeLongDescription, episodeNumber, videoUrl, thumbnailUrl, videoWidth, videoHeight, videoRunTime, airedOnDate));
        }

        private function doHttpStatus(evt:HTTPStatusEvent):void {
            //trace("httpstatus : " + evt.toString())
        }

        /**
         * renderFeedItem
         * define the namespace and loop through each item node
         * @param item is the section of XML
         */
        private function renderImageFeedItem(item:Object):void {

            var backgroundUrl:String = "";
            var cardViewUrl:String = "";
            var showLogoUrl:String = "";

            for each (var imageItem:Object in item.associated_images) {

                switch (imageItem.type.usage_type) {
                    case "Litl-Program-Background":
                        backgroundUrl = imageItem.url;
                        break;
                    case "Litl-Program-Cardview":
                        cardViewUrl = imageItem.url;
                        break;
                    //case "Litl-Program-Logo":
                    //showLogoUrl = imageItem.url;
                    default:
                        //throw new Error("MainView: Unknown view state");
                        break;
                }
                    // }

            }

            model.addImageData(new ImageData(backgroundUrl, cardViewUrl, showLogoUrl));
        }

        private function sortByAirDateNumber(a:EpisodeData, b:EpisodeData):Number {
            var aDate:Number = a.getAirDateTime();
            var bDate:Number = b.getAirDateTime();

            if (aDate > bDate) {
                return -1;
            }
            else if (aDate < bDate) {
                return 1;
            }
            else {
                //aPrice == bPrice
                return 0;
            }
        }

        /**
         * onError
         * Called when there was a communication error with the XML service
         */
        public function onError(event:IOErrorEvent):void {

            //ioError = true;
            // we need to degrade here
            //dispatchEvent(new Event(IOERROR));
            //trace("Load failed: IO error: " + event.text);
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
            // trace(errMsg);
            dispatchEvent(new Event(IOERROR));

            if (errCount == 0) {
                //fetchXml();		// refretch on the first error
            }
            errCount++;
        }
    }

}

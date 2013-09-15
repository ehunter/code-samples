package com.litl.tv.model
{
    import com.litl.tv.event.FeedUpdateEvent;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ImageData;
    import com.litl.tv.model.webservice.DiscoveryFeedClient;

    import flash.events.EventDispatcher;

    public class AppModel extends EventDispatcher
    {

        public var currentFeedType:String;

        private var _showName:String;

        private var feeds:Object;
        private var feedTitles:Object;

        public static var _episodes:Array = new Array();
        public static var _showImages:Array = new Array();
        private var _currentFeed:Array;
        public var _currentEpisodeData:EpisodeData;
        private var _currentImageData:ImageData;
        private var currentVideoID:Number = 0;
        private var _initialVideoLoaded:Boolean = false;
        private var currentFeedLength:Number = 0;
        private var _currentFeedChanged:Boolean = false;
        private var _currentNetwork:String = "";
        private var _showId:String = "";
        private var _savedVideoTime:Number = 0;
        private var _useSavedVideoTime:Boolean = false;
        private var _programType:String = "";
        private var pbsKidsProgramId:String = "PBS DP KidsGo"

        private static var instance:AppModel;

        public function AppModel(singletonEnforcer:SingletonEnforcer) {
            if (singletonEnforcer == null)
                throw new Error("Use AppModel.getInstance()");
        }

        public function get programType():String
        {
            return _programType;
        }

        public function set programType(value:String):void
        {
            if(value == pbsKidsProgramId){
                _programType = "kids";
            }
            else{
                _programType = "general";
            }
        }

        public function get useSavedVideoTime():Boolean {
            return _useSavedVideoTime;
        }

        public function set useSavedVideoTime(value:Boolean):void {
            _useSavedVideoTime = value;
        }

        public function get savedVideoTime():Number {
            return _savedVideoTime;
        }

        public function set savedVideoTime(value:Number):void {
            _savedVideoTime = value;
        }

        public function get showFeedId():String {
            return _showId;
        }

        public function set showFeedId(value:String):void {
            _showId = value;
        }

        public function get currentNetwork():String {
            return _currentNetwork;
        }

        public function set currentNetwork(value:String):void {
            _currentNetwork = value;
        }

        public function get currentFeedChanged():Boolean {
            return _currentFeedChanged;
        }

        public function set currentFeedChanged(value:Boolean):void {
            _currentFeedChanged = value;
        }

        public function get initialVideoLoaded():Boolean {
            return _initialVideoLoaded;
        }

        public function set initialVideoLoaded(value:Boolean):void {
            _initialVideoLoaded = value;
        }

        public static function getInstance():AppModel {
            if (instance == null)
                instance = new AppModel(new SingletonEnforcer());
            return instance;
        }

        /**
         * retrun array of videos
         *
         * @return _videos	an array of the videos
         *
         */
        public function get episodes():Array {
            return _episodes
        }

        public function set episodes(episodes:Array):void {
            _episodes = episodes;
        }

        public function clearModel():void {
            _episodes = [];
            _showImages = [];
        }

        /**
         * return the name of the current show
         *
         * @return _showName
         *
         */
        public function get showName():String {
            return _showName
        }

        public function set showName(name:String):void {
            _showName = name;
        }

        /**
         * return count of videos
         *
         * @return _videos.length	the length of the _videos array
         *
         */
        public function get numVideos():int {
            return _episodes.length
        }

        /**
         * add VideoData instance
         *
         * @param	videoData
         *
         */
        public static function addEpisodeData(episodeData:EpisodeData):void {
            _episodes.push(episodeData);
        }

        /**
         * add getEpisodeAt instance
         *
         * @param	videoData
         *
         */
        public function getEpisodeAt(i:int):EpisodeData {

            return _episodes[i];

        }

        public static function getEpisodeById(id:int):EpisodeData {
            var chosenVideo:EpisodeData;
            var length:int = _episodes.length;

            for (var i:int = 0; i < length; i++) {

                if (_episodes[i].id == id) {
                    chosenVideo = _episodes[i];
                }
            }
            return chosenVideo;
        }

        public function getNewestEpisode():EpisodeData {

            var length:int = _episodes.length - 1;
            return _episodes[0];

        }

        public function getEpisodeByUrl(url:String):EpisodeData {
            var chosenVideo:EpisodeData;
            var length:int = _episodes.length;

            for (var i:int = 0; i < length; i++) {

                if (_episodes[i]._videoUrl == url) {
                    chosenVideo = _episodes[i];
                }
            }
            return chosenVideo;
        }

        public function getItemPositionByUrl(url:String):Number {
            var position:Number;
            var length:int = _episodes.length;

            for (var i:Number = 0; i < length; i++) {

                if (_episodes[i]._videoUrl == url) {
                    position = i;
                }
            }
            return position;
        }


        public static function getAllThumbnails():Array {
            var thumbnails:Array = new Array();
            var length:int = _episodes.length;

            for (var i:int = 0; i < length; i++) {

                thumbnails.push(_episodes[i]._thumbnailUrl);
            }
            return thumbnails;
        }

        public function get currentFeed():Array {
            if (currentFeedType != null)
                return this[feeds[currentFeedType]];
            else
                return [];
        }

        public function set currentFeed(value:Array):void {

            _currentFeed = value;
            dispatchEvent(new FeedUpdateEvent(FeedUpdateEvent.FEED_UPDATE, _currentFeed));
            currentFeedChanged = true;

        }

        public function get currentFeedTitle():String {
            return feedTitles[currentFeedType];
        }

        public function set currentEpisodeData(value:EpisodeData):void {
            var changed:Boolean = _currentEpisodeData != value;
            _currentEpisodeData = value;

            if (changed)
                dispatchEvent(new FeedUpdateEvent(FeedUpdateEvent.CURRENT_DATA_UPDATE, null));
        }

        public function get currentEpisodeData():EpisodeData {
            return _currentEpisodeData;
        }

        /**
         * add VideoData instance
         *
         * @param	videoData
         *
         */
        public function addImageData(imageData:ImageData):void {

            _showImages.push(imageData);
        }

        public function getImageDataAt(id:Number):ImageData {
            return _showImages[id];
        }

        public function get currentImageData():ImageData {
            return _currentImageData;
        }

        public function set currentImageData(value:ImageData):void {
            _currentImageData = value;
        }

        public function get currentlySelectedVideoId():Number {
            return currentVideoID;
        }

        public function set currentlySelectedVideoId(id:Number):void {

            currentVideoID = id;

        }

    }
}

internal class SingletonEnforcer
{
}

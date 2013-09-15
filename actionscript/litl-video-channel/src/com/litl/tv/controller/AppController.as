package com.litl.tv.controller
{

    import com.litl.helpers.slideshow.SlideshowManager;
    import com.litl.sdk.enum.View;
    import com.litl.sdk.enum.ViewDetails;
    import com.litl.sdk.message.*;
    import com.litl.sdk.service.LitlService;
    import com.litl.tv.event.ExternalAssetsFeedEvent;
    import com.litl.tv.event.FeedUpdateEvent;
    import com.litl.tv.event.GetFeedEvent;
    import com.litl.tv.event.StandardFeedEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ImageData;
    import com.litl.tv.model.webservice.DiscoveryFeedClient;
    import com.litl.tv.model.webservice.ExternalAssetsFeedClient;
    import com.litl.tv.model.webservice.PBSFeedClient;
    import com.litl.tv.service.SlideFactory;
    import com.litl.tv.view.MainView;

    import flash.display.*;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;

    /**
     * Our main application controller.
     * This class will create the LitlService, pass data between the app and the device, manage the youtube data api.
     * @author litl
     */
    public class AppController extends Sprite
    {

        /**
         * The ID to use when communicating with the device.
         * Must be hard coded and must match the id you assign the channel in the card catalog
         */
        public var CHANNEL_ID:String = "discovery-channel";

        /**
         * The title of the channel.
         * this is a shared parameter assigned in the card catalog and passed to the channel at first install.
         */
        public var CHANNEL_TITLE:String;

        /**
         * The name of the discovery show for the player
         * this is a shared parameter assigned in the card catalog and passed to the channel at first install.
         *
         */
        public var SHOW_ID:String;

        /**
         * The current network this video player is being used for
         * this variable defines the feed we should use
         */
        public var NETWORK:String;

        /**
         * Saved device property
         * The  playhead time of the last watched video
         */
        public var PLAYHEAD_TIME:String;

        /**
         * Saved device property
         * The current id of the last watched video
         */
        public var SAVED_VIDEO_URL:String;

        /**
         * The channel version string.
         */
        public static const CHANNEL_VERSION:String = "1.0";

        /**
         * The location of the favicon for this channel.
         */
        public var CHANNEL_ICON:String = "";

        private var mainView:MainView;

        private var service:LitlService;

        private var currentVideoFeed:Object;

        private var discoveryFeed:DiscoveryFeedClient;

        private var pbsVideoFeed:PBSFeedClient;

        private var externalAssetsFeed:ExternalAssetsFeedClient;

        private var model:AppModel;

        private var currentView:String = "";
        private var currentDetails:String;
        private var currentWidth:Number = 0;
        private var currentHeight:Number = 0;
        private var currentImageData:ImageData;

        private var slideshowManager:SlideshowManager;
        private var slideFactory:SlideFactory;

        /**
         * Constructor
         * @param mainView The MainView instance.
         */
        public function AppController(mainView:MainView) {
            this.mainView = mainView;
            initialize();
        }

        /**
         * Initialize the services and create the main AppModel.
         * @private
         */
        protected function initialize():void {

            initializeService();
        }

        /**
         * Create the LitlService, connect the channel to the device, and listen for device messages.
         * @private
         */
        protected function initializeService():void {
            service = new LitlService(mainView);
            service.connect(CHANNEL_ID, CHANNEL_TITLE, CHANNEL_VERSION, false);
            service.addEventListener(InitializeMessage.INITIALIZE, handleInitialize);
            service.addEventListener(PropertyMessage.PROPERTY_CHANGED, handlePropertyChanged);
            service.addEventListener(OptionsStatusMessage.OPTIONS_STATUS, handleOptionsStatus);
            service.addEventListener(UserInputMessage.MOVE_PREVIOUS_ITEM, handleMove);
            service.addEventListener(UserInputMessage.MOVE_NEXT_ITEM, handleMove);
            service.addEventListener(ViewChangeMessage.VIEW_CHANGE, handleViewChange);
            service.addEventListener(NetworkStatusMessage.NETWORK_STATUS, onNetworkStatus);
            service.addEventListener(InitializeUpdateMessage.INITIALIZE_UPDATE, handleInitializeUpdateCommand);
            service.addEventListener(ForceSaveStateMessage.FORCE_SAVE_STATE, onForceSaveState);

            mainView.service = service;

            slideshowManager = new SlideshowManager(service);
            slideFactory = new SlideFactory();

            slideFactory.manager = slideshowManager;
            slideshowManager.slideFactory = slideFactory;

        }

        /**
         * Called when the device has initialized (sent any parameters and then the initialize message).
         * @param e	The InitializeMessage instance.
         *
         */
        private function handleInitialize(e:InitializeMessage):void {

            model = AppModel.getInstance();
            model.showName = SHOW_ID;
            var playHeadTime:Number = new Number(PLAYHEAD_TIME);
            model.savedVideoTime = playHeadTime;
            //model.savedVideoId = this.CURRENT_VIDEO_ID;

            setCurrentNetworkOnModel();
            setCurrentVideoFeed();
            setChannelIcon();

            externalAssetsFeed = ExternalAssetsFeedClient.getInstance();
            externalAssetsFeed.addEventListener(ExternalAssetsFeedEvent.IMAGE_DATA_PARSED, onExternalAssetsFeedReceived);

            externalAssetsFeed.getFeed(model.currentNetwork);

            service.channelTitle = CHANNEL_TITLE;
            service.channelIcon = CHANNEL_ICON;
            service.channelItemCount = 1;

        }

        /**
         * Called when the device has initialized (sent any parameters and then the initialize message).
         * @param e	The InitializeMessage instance.
         *
         */
        private function handleInitializeUpdateCommand(e:InitializeUpdateMessage):void {

            model = AppModel.getInstance();
            model.showName = SHOW_ID;

            setCurrentNetworkOnModel();
            setCurrentVideoFeed();

            externalAssetsFeed = ExternalAssetsFeedClient.getInstance();
            externalAssetsFeed.addEventListener(ExternalAssetsFeedEvent.IMAGE_DATA_PARSED, onExternalAssetsFeedReceived);

            externalAssetsFeed.getFeed(model.currentNetwork);

            service.channelTitle = CHANNEL_TITLE;
            service.channelIcon = CHANNEL_ICON;

        }

        /**
         * sets the currentVideoFeed to use depending on the network passed in from the shared params
         *
         */
        private function setCurrentVideoFeed():void {
            switch (NETWORK) {
                default:
                    throw new Error("AppController: Unknown network");
                    break;
                case "pbs":
                    if (currentVideoFeed == null)
                        currentVideoFeed = PBSFeedClient.getInstance();
                    break;
                case "pbsKids":
                    if (currentVideoFeed == null)
                        currentVideoFeed = PBSFeedClient.getInstance();
                    break;
                case "discovery":
                    if (currentVideoFeed == null)
                        currentVideoFeed = DiscoveryFeedClient.getInstance();
                    break;
            }

        }

        private function setCurrentNetworkOnModel():void {
            if (NETWORK) {
                model.currentNetwork = NETWORK;
            }
        }

        /**
         *
         *
         */
        private function setChannelIcon():void {
            switch (NETWORK) {
                default:
                    throw new Error("AppController: Unknown network");
                    break;
                case "pbs":
                    CHANNEL_ICON = "https://s3.amazonaws.com/litl-channel-data/pbs/favicons/pbsIcon/favicon.ico";
                    break;
                case "pbsKids":
                    CHANNEL_ICON = "https://s3.amazonaws.com/litl-channel-data/pbs/favicons/pbsKidsIcon/favicon.ico";
                    break;
                case "discovery":
                    break;
            }

        }

        /**
         * Called when a new feed is received from the Network api.
         * @param e	A StandardVideoFeedEvent containing the feed.
         *
         */
        private function onExternalAssetsFeedReceived(e:ExternalAssetsFeedEvent):void {

            externalAssetsFeed.removeEventListener(ExternalAssetsFeedEvent.IMAGE_DATA_PARSED, onExternalAssetsFeedReceived);

            currentImageData = model.getImageDataAt(0);
            model.currentImageData = currentImageData;

            if (currentVideoFeed != null) {

                currentVideoFeed.addEventListener(StandardFeedEvent.VIDEO_DATA_PARSED, onStandardFeedReceived);
                currentVideoFeed.addEventListener(FeedUpdateEvent.FEED_UPDATE, onFeedUpdate);
                // get the video feed
                currentVideoFeed.getVideoFeed(model.showName);
            }
            else {
                mainView.setState(currentView, currentDetails, currentWidth, currentHeight);
            }

        }

        /**
         * Called when a new feed is received from the Network api.
         * @param e	A StandardVideoFeedEvent containing the feed.
         *
         */
        private function onStandardFeedReceived(e:StandardFeedEvent):void {

            currentVideoFeed.removeEventListener(StandardFeedEvent.VIDEO_DATA_PARSED, onStandardFeedReceived);

            var allEpisodes:Array = AppModel.getAllThumbnails();
            var episodeCount:int = allEpisodes.length;

            // give the service the number of thumbnail images from our feed
            service.channelItemCount = episodeCount;

            /// give the model the current feed IMPORTANT !!!!! This will bubble an event to the View
            model.currentFeed = e.feed;

            if (SAVED_VIDEO_URL != "") {
                if ((model.getEpisodeByUrl(SAVED_VIDEO_URL) != null) && (model.getItemPositionByUrl(SAVED_VIDEO_URL) != -1)) {
                    model.currentEpisodeData = model.getEpisodeByUrl(SAVED_VIDEO_URL);
                    model.currentlySelectedVideoId = model.getItemPositionByUrl(SAVED_VIDEO_URL);
                }
                else {
                    model.currentEpisodeData = model.getEpisodeAt(0);
                    model.currentlySelectedVideoId = 0;
                }
            }
            else {
                model.currentEpisodeData = model.getEpisodeAt(0);
            }

            if (currentView != "") {
                mainView.loadBackgroundImage();
                mainView.loadNetworkLogo();
                mainView.setState(currentView, currentDetails, currentWidth, currentHeight);
            }

            addDataToSlideshowManager();

        }

        /**
         *
         * Saves the current video time and url to the device
         *
         */
        private function onForceSaveState(evt:ForceSaveStateMessage):void {
            service.deviceProperties.savedVideoTime = mainView.currentPlayheadTime;
            service.deviceProperties.savedVideoUrl = model.currentEpisodeData._videoUrl;
        }

        private function onFeedUpdate(evt:FeedUpdateEvent):void {
            model.currentFeed = evt.feed;

            addDataToSlideshowManager();
        }

        private function addDataToSlideshowManager():void {
            var data:Array = new Array();

            var tempDate:Date = new Date();
            var blankEpisodeData:EpisodeData = new EpisodeData("blank", "blank", "blank", "blank", "blank", "blank", 0, 0, "", tempDate);
            data.push(model.getNewestEpisode(), blankEpisodeData);
            slideshowManager.dataProvider = data;
        }

        private function handleViewChange(e:ViewChangeMessage):void {

            // Ignore offscreen messages
            if (e.details == ViewDetails.OFFSCREEN)
                return;

            currentWidth = e.width;
            currentHeight = e.height;

            // Get the new view type:
            currentView = e.view;
            currentDetails = e.details;

            mainView.setState(currentView, currentDetails, currentWidth, currentHeight);

        }

        public function handlePropertyChanged(e:PropertyMessage):void {

            for each (var item:Object in e.parameters) {
                switch (item.name) {
                    case "showId":
                        SHOW_ID = item.value;
                        break;
                    case "showTitle":
                        CHANNEL_TITLE = item.value;
                        break;
                    case "network":
                        NETWORK = item.value;
                        break;
                    case "savedVideoTime":
                        PLAYHEAD_TIME = item.value;
                        trace("savedVideoTime is " + PLAYHEAD_TIME)
                        break;
                    case "savedVideoUrl":
                        SAVED_VIDEO_URL = item.value;
                        break;
                    default:
                        //throw new Error("MainView: Unknown view state");
                        break;
                }
            }

        }

        private function handleOptionsStatus(e:OptionsStatusMessage):void {

        }

        private function handleMove(e:UserInputMessage):void {
            if (e.type == UserInputMessage.MOVE_PREVIOUS_ITEM) {
                mainView.previousItem();
            }
            else {
                mainView.nextItem();
            }
        }

        private function onNetworkStatus(evt:NetworkStatusMessage):void {
            mainView.networkConnected = evt.connected;
        }
    }
}

package com.litl.tv.view
{
    import com.greensock.TweenLite;
    import com.greensock.easing.*;
    import com.greensock.events.LoaderEvent;
    import com.greensock.loading.*;
    import com.greensock.loading.display.*;
    import com.litl.control.VideoPlayer;
    import com.litl.event.FullscreenEvent;
    import com.litl.event.MetaDataEvent;
    import com.litl.event.VideoPlayerEvent;
    import com.litl.sdk.enum.View;
    import com.litl.sdk.enum.ViewDetails;
    import com.litl.sdk.service.ILitlService;
    import com.litl.skin.LitlColors;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ImageData;
    import com.litl.tv.view.CardView;
    import com.litl.tv.view.TitleCard;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.display.StageDisplayState;
    import flash.errors.IOError;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.utils.Dictionary;

    import org.osmf.events.BufferEvent;
    import org.osmf.events.DisplayObjectEvent;
    import org.osmf.events.MediaPlayerStateChangeEvent;
    import org.osmf.events.PlayEvent;
    import org.osmf.events.SeekEvent;

    /**
     * The main view class. Will switch between the three main views of our application, and direct messages.
     * @author litl
     *
     */
    public class MainView extends Sprite
    {
        private var player:VideoPlayer;
        private var bgImage:Sprite = new Sprite();
        private var networkLogo:Sprite = new Sprite();

        private var currentView:DisplayObject;
        private var views:Dictionary;
        private var debug:TextField;
        public var service:ILitlService;
        public var feedReady:Boolean = false;
        private var debugText:TextField;
        private var model:AppModel = null;
        private var currentEpisodeData:EpisodeData;
        private var _width:Number = 0;
        private var _height:Number = 0;
        private var _networkConnected:Boolean;
        private var currentViewState:String;
        private var alertPanel:AlertPanel = null;
        private var _networkStatus:Boolean = true;
        private var bgImageLoader:LoaderMax = null;
        private var logoLoader:LoaderMax = null;
        private var currentVideoTime:Number = 0;
        private var allErrorText:Array = new Array();

        /**
         * Constructor.
         */
        public function MainView() {
            super();

            initialize();
        }

        public function get networkConnected():Boolean {
            return _networkConnected;
        }

        public function set networkConnected(value:Boolean):void {
            _networkConnected = value;
            handleNetworkStatus(value);
        }

        public function get currentPlayheadTime():Number {
            return player.internalMediaPlayer.currentTime;
        }

        /**
         * shows or hides the network alert panel
         */
        private function handleNetworkStatus(value:Boolean):void {
            _networkStatus = value;

            if (!value) {
                setStageFrameRate(30);

                if (alertPanel) {
                    removeAlertPanel();
                }

                alertPanel = new AlertPanel();
                var highestIndex:int = this.numChildren;
                this.addChildAt(alertPanel, highestIndex);
                alertPanel.alpha = 0;
                alertPanel.scaleX = .25;
                alertPanel.scaleY = .25;
                alertPanel.bg.alpha = .9;

                positionAlertPanel();

                TweenLite.to(alertPanel, .35, { alpha: 1, scaleX: 1, scaleY: 1, ease: Back.easeOut, onComplete: setStageFrameRate, onCompleteParams: [ 12 ]});
            }
            else if (value) {
                if (alertPanel) {
                    TweenLite.to(alertPanel, .35, { alpha: 0, ease: Quart.easeOut, onComplete: removeAlertPanel });

                }
            }

        }

        /**
         * centers the alert panel according to the currentView
         */
        private function positionAlertPanel():void {
            switch (currentViewState) {

                case "FOCUS":
                    alertPanel.x = (_width - alertPanel.width - 120);
                    alertPanel.y = 60;
                    break;
                case "CHANNEL":
                    alertPanel.x = (_width - alertPanel.width - 120);
                    alertPanel.y = 60;
                    break;
                case "CARD":
                    alertPanel.x = ((_width - alertPanel.bg.width) / 2) + (alertPanel.bg.width / 2);
                    alertPanel.y = ((_height - alertPanel.bg.height) / 2) + (alertPanel.bg.height / 2);
                    break;
                default:
                    break;
            }
        }

        /**
         * removes the alert panel from the stage and sets the appropriate frame for the currentView
         */
        private function removeAlertPanel():void {
            switch (currentViewState) {

                case "FOCUS":
                    setStageFrameRate(12);
                    break;
                case "CHANNEL":
                    setStageFrameRate(12);
                    break;
                case "CARD":
                    setStageFrameRate(30);
                    break;
                default:
                    break;
            }

            removeChild(alertPanel);
            alertPanel = null;
        }

        /**
         * sets the frame rate of this swf
         */
        private function setStageFrameRate(rate:Number):void {

            if (stage) {
                stage.frameRate = rate;
            }
        }

        /**
         * Move to the next item in card view.
         */
        public function nextItem():void {
            if (currentView is CardView) {
                (currentView as CardView).nextItem();
            }
        }

        /**
         * Move to the previous item in card view.
         */
        public function previousItem():void {
            if (currentView is CardView) {
                (currentView as CardView).previousItem();
            }
        }

        /**
         * loadBackgroundImage
         *
         *
         */
        public function loadBackgroundImage():void {

            var currentImageData:ImageData = model.currentImageData;
            //create a LoaderMax named "mainQueue" and set up onProgress, onComplete and onError listeners
            var imageToLoad:String = currentImageData._backgroundUrl;
            bgImageLoader = new LoaderMax({ name: "backgroundImageQueue", onProgress: progressHandler, onComplete: bgImageLoadComplete, onError: errorHandler });
            bgImageLoader.append(new ImageLoader(imageToLoad, { name: "backgroundImage", estimatedBytes: 60000, alpha: 1 }));
            //start loading
            bgImageLoader.load();

        }

        /**
         * loadNetworkLogo
         *
         *
         */
        public function loadNetworkLogo():void {
            var currentImageData:ImageData = model.currentImageData;
            //create a LoaderMax named "mainQueue" and set up onProgress, onComplete and onError listeners
            var imageToLoad:String = currentImageData._networkLogoUrl;
            logoLoader = new LoaderMax({ name: "backgroundImageQueue", onComplete: networkLogoLoadComplete, onError: errorHandler });
            logoLoader.append(new ImageLoader(imageToLoad, { name: "networkLogo", estimatedBytes: 6000, alpha: 1 }));
            //start loading
            logoLoader.load();
        }

        /**
         * progressHandler
         *
         *
         */
        private function progressHandler(event:LoaderEvent):void {
            //trace("progress: " + event.target.progress);
            //showError("progress: " + event.target.progress + "\n")
        }

        /**
         * completeHandler
         *
         *
         */
        private function bgImageLoadComplete(event:LoaderEvent):void {

            bgImageLoader.removeEventListener(LoaderEvent.COMPLETE, bgImageLoadComplete);
            bgImageLoader.removeEventListener(LoaderEvent.ERROR, errorHandler);

            var image:ContentDisplay = LoaderMax.getContent("backgroundImage");
            bgImage.addChild(image);

            /// we need to give the loaded background image to the focus view if we're currently in it
            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView;
                    focusView.backgroundImage = bgImage;
                    break;
                default:
                    break;
            }

            //showError("bgImageLoadComplete \n")

        }

        /**
         * completeHandler
         *
         *
         */
        private function networkLogoLoadComplete(event:LoaderEvent):void {

            logoLoader.removeEventListener(LoaderEvent.COMPLETE, networkLogoLoadComplete);
            logoLoader.removeEventListener(LoaderEvent.ERROR, errorHandler);

            var image:ContentDisplay = LoaderMax.getContent("networkLogo");
            networkLogo.addChild(image);

            //showError("networkLogoLoadComplete \n")

        }

        /**
         * errorHandler
         *
         *
         */
        private function errorHandler(event:LoaderEvent):void {
            trace("error occured with " + event.target + ": " + event.text);
        }

        /**
         *  Create the video player.
         */
        protected function initialize():void {

            views = new Dictionary(false);

            player = new VideoPlayer();

            model = AppModel.getInstance();

        }

        /**
         * Set the current view. Create the view if it doesn't exist, and switch to it.
         * We will pass the single VideoPlayer instance between views.
         * @param viewState	The view constant.
         * @see com.litl.sdk.enum.View
         */
        public function setState(viewState:String, viewDetails:String, width:Number, height:Number):void {

            var cardView:CardView = null;
            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            this._height = height;
            this._width = width;

            if (currentView) {

                removeVideoPlayerListeners();

                if ("videoPlayer" in currentView) {
                    Object(currentView).videoPlayer = null;
                }

                removeChild(currentView);
                currentView = null;

            }
            currentView = views[viewState] as DisplayObject;
            currentViewState = viewState;

            switch (viewState) {
                default:
                    throw new Error("MainView: Unknown view state");
                    break;

                case View.CHANNEL:

                    if (currentView == null) {
                        currentView = new FullScreenVideoView();
                    }
                    channelView = currentView as FullScreenVideoView;
                    addVideoPlayerListeners();
                    if (viewDetails == ViewDetails.NORMAL)
                        channelView.videoPlayer = player;
                    channelView.setSize(width, height);
                    channelView.service = service;
                    channelView.selectorMode = (viewDetails != ViewDetails.NORMAL);

                    break;

                case View.FOCUS:

                    if (currentView == null)
                        currentView = new FocusView();
                    focusView = currentView as FocusView;
                    player.visible = true;
                    player.autoPlay = false;
                    bgImage.visible = true;
                    addVideoPlayerListeners();
                    focusView.videoPlayer = player;
                    focusView.backgroundImage = bgImage;
                    focusView.setSize(width, height);

                    break;

                case View.CARD:

                    if (currentView == null)
                        currentView = new CardView();
                    bgImage.visible = false;
                    cardView = currentView as CardView;
                    cardView.setSize(width, height);
                    /// fixes bug in OS where CARD parameter is passed when we're going from ChannelView to FocusView
                    if (viewDetails != ViewDetails.OFFSCREEN) {
                        closeVideoPlayerConnection();
                    }

                    break;
            }

            // If the channel is in screensaver mode, or in the selector..
            if ((viewDetails == ViewDetails.SCREENSAVER) || ((viewDetails == ViewDetails.SELECTOR))) {
                player.pause();
                player.visible = false;
            }

            views[viewState] = currentView;

            if (!contains(currentView)) {
                addChildAt(currentView, 0);
            }

            if (player.parent == this) {
                setChildIndex(player, numChildren - 1);
            }

            if (!_networkStatus) {
                handleNetworkStatus(_networkStatus);
            }

        }

        /**
         *  closes the video players current connection and saves the currentTime of the video
         */
        private function closeVideoPlayerConnection():void {

            if (player.internalMediaPlayer) {
                if (player.internalMediaPlayer.currentTime >= 10) {
                    model.savedVideoTime = player.internalMediaPlayer.currentTime;
                }

                player.closeConnection();
            }
        }

        /**
         *  adds listeners to the video player
         */
        private function addVideoPlayerListeners():void {

            player.addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onStateChange);
            player.addEventListener(PlayEvent.PLAY_STATE_CHANGE, onPlayChange);
            player.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            player.addEventListener(MetaDataEvent.ON_METADATA, onMetadata);
            player.addEventListener(VideoPlayerEvent.READY, onVideoReady);
            player.addEventListener(SeekEvent.SEEKING_CHANGE, onSeekChange);
            player.addEventListener(VideoPlayerEvent.COMPLETE, onVideoComplete);
            player.addEventListener(BufferEvent.BUFFERING_CHANGE, onBufferChange);
            player.addEventListener(FullscreenEvent.FULLSCREEN, onFullScreen);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);

        }

        /**
         *  removes listeners from the video player
         */
        private function removeVideoPlayerListeners():void {
            player.removeEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onStateChange);
            player.removeEventListener(PlayEvent.PLAY_STATE_CHANGE, onPlayChange);
            player.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
            player.removeEventListener(MetaDataEvent.ON_METADATA, onMetadata);
            player.removeEventListener(VideoPlayerEvent.READY, onVideoReady);
            player.removeEventListener(VideoPlayerEvent.COMPLETE, onVideoComplete);
            player.removeEventListener(SeekEvent.SEEKING_CHANGE, onSeekChange);
            player.removeEventListener(BufferEvent.BUFFERING_CHANGE, onBufferChange);
            player.removeEventListener(FullscreenEvent.FULLSCREEN, onFullScreen);
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
        }

        /**
         *  handles the state change events from the VideoPlayer instance and passes those events on to the current view
         */
        private function onStateChange(evt:MediaPlayerStateChangeEvent):void {
            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onStateChange(evt.state);
                    break;
                case "CHANNEL":
                    channelView = currentView as FullScreenVideoView;
                    channelView.onStateChange(evt.state);
                    break;
                default:
                    break;
            }

            //showError(evt.state)
        }

        /**
         * onKeyPress
         *
         */
        private function onKeyPress(evt:KeyboardEvent):void {
            var focusView:FocusView = null;

            // only give the keyboard events to FocusView
            switch (currentViewState) {
                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onKeyPress(evt.keyCode);
                default:
                    break;
            }

        }

        /**
         *  handles the state change events from the VideoPlayer instance and passes those events on to the current view
         */
        private function onFullScreen(evt:FullscreenEvent):void {
            var focusView:FocusView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onFullScreen(evt.fullscreen);
                    break;
                default:
                    break;
            }
        }

        /**
         *  handles the onMetadata events from the VideoPlayer instance and passes those events on to the current view
         */
        private function onMetadata(evt:MetaDataEvent):void {

            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            var info:Object = evt.metadata;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onMetadata(info);
                    break;
                default:
                    break;
            }

        }

        /**
         * IO error error from the videoPlayer
         *
         * @param	Event
         */
        public function onIOError(evt:IOErrorEvent):void {

            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onIOError();
                    break;
                case "CHANNEL":
                    channelView = currentView as FullScreenVideoView;
                    channelView.onIOError();
                    break;
                default:
                    break;
            }
        }

        /**
         *  handles the play/pause events from the VideoPlayer instance and passes those events on to the current view
         */
        private function onBufferChange(evt:BufferEvent):void {

            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onBufferChange(evt.buffering);
                    break;
                case "CHANNEL":
                    channelView = currentView as FullScreenVideoView;
                    channelView.onBufferChange(evt.buffering);
                    break;
                default:
                    break;
            }
        }

        /**
         *  handles the play/pause events from the VideoPlayer instance and passes those events on to the current view
         * also sets the screensaverEnabled property according the playState of videoPlayer
         */
        private function onPlayChange(evt:PlayEvent):void {

            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onPlayChange(evt.playState);
                    break;
                default:
                    break;
            }

            switch (evt.playState) {

                case "playing":
                    service.screensaverEnabled = false;
                    break;
                case "paused":
                    service.screensaverEnabled = true;
                    break;
                default:
                    service.screensaverEnabled = true;
            }
        }

        /**
         *  handles the video ready events from the VideoPlayer instance and passes those events on to the current view
         */
        private function onVideoReady(evt:VideoPlayerEvent):void {
            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onVideoReady();
                    break;
                case "CHANNEL":
                    channelView = currentView as FullScreenVideoView;
                    channelView.onVideoReady();
                    break;
                default:
                    break;
            }
        }

        /**
         *  handles the seek events from the VideoPlayer instance and passes those events on to the current view
         */
        private function onSeekChange(evt:SeekEvent):void {

            var focusView:FocusView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onSeekChange(evt.seeking);
                    break;
                default:
                    break;
            }
        }

        /**
         *  handles the complete events from the VideoPlayer instance and passes those events on to the current view
         */
        private function onVideoComplete(evt:VideoPlayerEvent):void {

            var focusView:FocusView = null;
            var channelView:FullScreenVideoView = null;

            switch (currentViewState) {

                case "FOCUS":
                    focusView = currentView as FocusView
                    focusView.onVideoComplete();
                    break;
                case "CHANNEL":
                    channelView = currentView as FullScreenVideoView;
                    channelView.onVideoComplete();
                    break;
                default:
                    break;
            }

        }

        public function showError(txt:String):void {
            if (debugText)
                removeChild(debugText);

            debugText = new TextField();

            allErrorText.push(txt);

            var titleFormat:TextFormat = new TextFormat("CorpoS", 16, LitlColors.WHITE);
            titleFormat.align = TextFormatAlign.LEFT;
            debugText.defaultTextFormat = titleFormat;
            debugText.height = 1280;

            debugText.multiline = true;

            debugText.width = 600;
            addChild(debugText);
            debugText.text = allErrorText.toString();

            debugText.y = 30;

        }

    }
}

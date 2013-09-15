package com.litl.tv.view
{

    import com.greensock.TweenLite;
    import com.greensock.easing.*;
    import com.greensock.events.LoaderEvent;
    import com.greensock.loading.*;
    import com.greensock.loading.display.*;
    import com.greensock.plugins.AutoAlphaPlugin;
    import com.greensock.plugins.TweenPlugin;
    import com.litl.control.ControlBase;
    import com.litl.control.Filmstrip;
    import com.litl.control.Label;
    import com.litl.control.TextButton;
    import com.litl.control.VerticalList;
    import com.litl.control.VideoPlayer;
    import com.litl.control.playerclasses.YouTubeResource;
    import com.litl.event.MetaDataEvent;
    import com.litl.event.VideoPlayerEvent;
    import com.litl.sdk.util.Tween;
    import com.litl.skin.LitlColors;
    import com.litl.skin.parts.LoadingSpinner;
    import com.litl.tv.event.FeedUpdateEvent;
    import com.litl.tv.event.GetFeedEvent;
    import com.litl.tv.event.TitleCardEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ImageData;
    import com.litl.tv.renderer.FilmstripFocusViewDataRenderer;
    import com.litl.tv.renderer.SlideshowDataRenderer;
    import com.litl.tv.utils.BufferingSpinner;
    import com.litl.tv.utils.ThumbnailList;
    import com.litl.tv.view.TitleCard;

    import flash.display.Bitmap;
    import flash.display.BlendMode;
    import flash.display.GradientType;
    import flash.display.Graphics;
    import flash.display.SpreadMethod;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.display.StageDisplayState;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.FullScreenEvent;
    import flash.events.IOErrorEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.TimerEvent;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    import flash.system.Capabilities;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.utils.Timer;

    import org.osmf.events.DisplayObjectEvent;

    public class FocusView extends ControlBase
    {

        protected var background:Sprite;
        private var vignette:Sprite;
        protected var listTitle:Label;
        protected var featuredButton:TextButton;
        protected var favoriteButton:TextButton;
        protected var viewedButton:TextButton;
        protected var ratedButton:TextButton;
        protected var content:Sprite;
        private var currentEpisodeData:EpisodeData;
        private var currentImageData:ImageData;
        private var overlayPlayButton:OverlayPlayButton = null;
        private var errorText:TextField = null;
        private var debugText:TextField;

        protected var player:VideoPlayer;
        protected var videoList:VerticalList;
        protected var model:AppModel;
        protected var spinner:LoadingSpinner;
        private var filmstrip:Filmstrip;
        public var thumbnailList:ThumbnailList;
        protected var playerHolder:Sprite = null;
        private var playerBg:Sprite = null;
        private var focusViewPlayerUrl:String = "";
        private var savedSeekComplete:Boolean = false;
        public var videoWidth:Number = 0;
        public var videoHeight:Number = 0;
        private const fullScreenRect:Rectangle = new Rectangle(0, 0, videoWidth, videoHeight);
        private var origvideox:Number = 0;
        private var origvideoy:Number = 0;
        private var origvideowidth:Number = 0;
        private var origvideoheight:Number = 0;
        private var _backgroundImage:Sprite = null;
        private var initialHasPlayed:Boolean = false;
        private var updateThumbnailListOnly:Boolean = false;
        private var hardCodedHeight:Number = 720;
        private var spaceBarKeyCode:uint = 32;
        private var escapeKeyCode:uint = 27;
        public static const VIDEO_CONTROLS_TIMEOUT:int = 5000;
        public static const FILMSTRIP_TIMEOUT:int = 500;
        public static const ERROR_TIMEOUT:int = 5000;
        public static const MIN_WATCHED_TIME:int = 10;

        private static const VIDEO_UNAVAILABLE_TEXT:String = "Oops! The video you've chosen is currently unavailable.";
        private static const AUTO_PLAY_TEXT:String = "\n \n The next video will begin in 5 seconds. ";
        private static const NETWORK_ERROR_TEXT:String = "Cannot connect to network"
        private var mouseOverControlBar:Boolean = false;
        private var _networkConnected:Boolean;
        public var _currentVideoTime:Number = 0;

        private static const VIDEO_PLAYER_PADDING:int = 15;
        private var maxVideoHeight:Number = 0;
        private static const THUMBNAIL_LIST_HEIGHT:int = 200;
        public static const MAX_SCALE:Number = 1.5;
        public static const SCRUB_BAR_HEIGHT:Number = 26;
        public static const TIME_BUBBLE_HEIGHT:Number = 35;

        /** Our timer that hides the controlBar after user inactivity
        /** @private */
        private var hideVideoControlsTimer:Timer = null;
        private var filmstripChangeTimer:Timer = null;
        private var errorTimer:Timer = null;

        public function FocusView() {
            super();

            content = new Sprite();
            addChild(content);

            TweenPlugin.activate([ AutoAlphaPlugin ]);
        }

        public function get networkConnected():Boolean {
            return _networkConnected;
        }

        public function get backgroundImage():Sprite {
            return _backgroundImage;
        }

        public function set backgroundImage(value:Sprite):void {
            _backgroundImage = value;

            if (background) {
                if (!background.contains(_backgroundImage)) {
                    background.addChild(_backgroundImage);
                    background.setChildIndex(_backgroundImage, 0);
                }
                setBackgroundSize();
            }
        }

        /**
         * returns the videoPlayer instance
         *
         * @return	VideoPlayer
         */
        public function get videoPlayer():VideoPlayer {
            return player;
        }

        /**
         * creates the videoPlayer instance for this view
         *
         * @param	VideoPlayer
         */
        public function set videoPlayer(value:VideoPlayer):void {
            player = value;

            if (player) {

                if (player.parent) {
                    player.parent.removeChild(player);

                    if (playerHolder) {
                        removeChild(playerHolder);
                    }

                    if (overlayPlayButton) {
                        removeChild(overlayPlayButton);
                    }

                }
                playerHolder = new Sprite();
                addChild(playerHolder);

                player.move(0, 0);
                player.features = VideoPlayer.FEATURES_PLAY_BUTTON | VideoPlayer.FEATURES_SCRUB_BAR | VideoPlayer.FEATURES_FULLSCREEN_BUTTON;
                player.CONTROL_BAR_HEIGHT = SCRUB_BAR_HEIGHT;
                player.TIME_BUBBLE_HEIGHT = TIME_BUBBLE_HEIGHT;

                playerHolder.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverPlayer);
                playerHolder.addEventListener(MouseEvent.MOUSE_MOVE, onMouseOverPlayer);

                if (player.controlBar) {
                    player.seeking = false;
                    player.controlBar.visible = true;
                    player.controlBar.alpha = 1;
                    player.hideTimeBubble();

                }

                if (currentEpisodeData) {
                    currentEpisodeData = model.currentEpisodeData;

                    if (!player.url)
                        player.url = currentEpisodeData._videoUrl;
                }

                if (background)
                    background.visible = true;

                if (focusViewPlayerUrl != player.url) {
                    focusViewPlayerUrl = player.url;
                }

                playerBg = new Sprite();
                playerBg.graphics.clear()
                playerBg.graphics.beginFill(0x000000);
                playerBg.graphics.drawRect(player.x, player.y, 200, 200);
                playerBg.graphics.endFill();
                showPlayerBg();

                overlayPlayButton = new OverlayPlayButton();
                overlayPlayButton.addEventListener(MouseEvent.MOUSE_DOWN, onOverlayPlayButtonPress);
                overlayPlayButton.addEventListener(MouseEvent.MOUSE_OVER, onOverlayPlayButtonOver);
                overlayPlayButton.addEventListener(MouseEvent.MOUSE_OUT, onOverlayPlayButtonOut);

                addChild(overlayPlayButton);
                overlayPlayButton.visible = false;

                playerHolder.addChild(player);
                playerHolder.addChildAt(playerBg, 0);
                player.fullScreen = false;
                player.smoothing = false;

                if (thumbnailList) {
                    thumbnailList.visible = true;
                    checkDataFreshness();
                }
            }
        }

        /**
         * creates an instance of the model and adds listeners
         */
        private function accessModel():void {
            model = AppModel.getInstance();
            model.addEventListener(FeedUpdateEvent.FEED_UPDATE, onFeedUpdate, false, 0, true);
            model.addEventListener(FeedUpdateEvent.CURRENT_DATA_UPDATE, onEpisodeDataUpdate, false, 0, true);
            currentEpisodeData = model.currentEpisodeData;
            currentImageData = model.currentImageData;
        }

        /**
         * when metadata is received we extract the width and height
         *
         * @param	MetaDataEvent
         */
        public function onMetadata(data:Object):void {

            var info:Object = data;

            for (var value:Object in info) {
                switch (value) {
                    case "width":
                        var newWidth:Number = info[value] as Number;
                        break;
                    case "height":
                        var newHeight:Number = info[value] as Number;
                        break;
                }

            }

            validatePlayerSize(newWidth, newHeight);

        }

        public function onSeekChange(seeking:Boolean):void {

            if (!seeking) {
                if (model.useSavedVideoTime) {
                    model.useSavedVideoTime = false;
                    player.visible = true;
                    player.internalMediaContainer.visible = true;
                    savedSeekComplete = true;
                }
            }
        }

        /**
         * checks the current width/height of the player againstt the metadata width/height
         * and adjusts accordingly
         *
         */
        private function validatePlayerSize(newWidth:Number, newHeight:Number):void {

            if ((newWidth) && (newHeight)) {
                currentEpisodeData._videoWidth = newWidth;
                currentEpisodeData._videoHeight = newHeight;

                if ((player) && (!player.fullScreen)) {
                    if (newWidth != player.width) {
                        invalidateLayout();
                    }
                    else if (newHeight != player.height) {
                        invalidateLayout();
                    }
                }
            }

        }

        /**
         * state changes from the video player such as pause, play etc.
         *
         * @param	MediaPlayerStateChangeEvent
         */
        public function onStateChange(state:String):void {

            switch (state) {

                case "paused":
                    setStageFrameRate(30);
                case "stopped":
                    showPlayerBg();
                    setStageFrameRate(30);
                    break;
                case "buffering":
                    setStageFrameRate(12);
                    break;
                case "ready":
                    clearVideoError();
                    setLoading(false);
                    break;
                case "playbackError":
                    handleVideoError();
                    showPlayerBg();
                case "loading":
                    if (errorText)
                        setLoading(true);
                    break;
                case "playing":
                    setStageFrameRate(12);
                    setLoading(false);
                    if (player) {
                        if (model) {
                            if (model.useSavedVideoTime) {
                                player.seek(model.savedVideoTime);
                            }
                            else if (savedSeekComplete) {
                                savedSeekComplete = false;
                                player.internalMediaPlayer.pause();
                                player.internalMediaContainer.visible = true;
                                showOverlayPlayButton();
                                model.savedVideoTime = 0;
                            }

                        }
                    }
                    clearVideoError();
                    restartHideVideoControlsTimer();
                    break;
                case "uninitialized":
                    setLoading(true);
                    break;
                default:
                    //trace(evt.state + " = evt.MediaPlayerStateChangeEvent")
            }

        }

        /**
         * IO error error from the videoPlayer
         *
         * @param	Event
         */
        public function onIOError():void {
            handleVideoError();
        }

        /**
         * creates a text field on stage and displays error text
         *
         */
        private function handleVideoError():void {

            if (player) {
                if (player.internalMediaContainer)
                    player.internalMediaContainer.visible = false;
                player.pause();
            }

            if (!errorText)
                createErrorText();

            if (player.autoPlay) {
                errorTimer.start();
                errorText.text = VIDEO_UNAVAILABLE_TEXT + AUTO_PLAY_TEXT;
            }
            else {
                errorText.text = VIDEO_UNAVAILABLE_TEXT;
            }
            positionErrorText();
            errorText.visible = true;

            setLoading(false);
            hideOverlayPlayButton();

        }

        /**
         * clears the error text field and hides it
         *
         */
        private function clearVideoError():void {
            if (errorText)
                removeErrorText();
        }

        /**
         * centers the error text field within the video player area
         *
         * @param	Event
         */
        private function positionErrorText():void {
            errorText.x = ((_width - errorText.width) / 2);
            errorText.y = (((_height - THUMBNAIL_LIST_HEIGHT) - errorText.height) / 2);
        }

        /**
         * changes the stage's frame rate
         *
         * @param	Number
         */
        private function setStageFrameRate(rate:Number):void {
            if (stage) {
                stage.frameRate = rate;
            }
        }

        /**
         * togglePausePlayState
         *
         */
        private function togglePausePlayState():void {
            if (player.playing) {
                player.pause();
                stopHideVideoControlsTimer();
                player.showVideoControls();

            }
            else {
                initialHasPlayed = true;
                player.play();
            }
        }

        private function onMouseOverPlayer(evt:MouseEvent):void {
            if (player) {
                player.showVideoControls();
                stopHideVideoControlsTimer();
                hideVideoControlsTimer.start();

                player.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOverPlayer);
            }
        }

        /**
         * onPlayChange
         * checks the current play state and either hides or shows the videoTitleCard
         * @param PlayEvent
         *
         */
        public function onPlayChange(state:String):void {

            if (player) {
                switch (state) {
                    case "playing":
                        hideOverlayPlayButton();
                        break;
                    case "paused":
                        showOverlayPlayButton();
                        break;
                    default:
                        //trace(evt.playState + " = evt.playState")
                }
            }
        }

        /**
         * onBufferChange
         * checks the current buffering state and either hides or shows the videoControls
         * @param PlayEvent
         *
         */
        public function onBufferChange(buffering:Boolean):void {

            if (player) {

                if (buffering) {
                    player.showVideoControls();
                }
                else {
                    if (!hideVideoControlsTimer.running)
                        player.hideVideoControls();
                }
            }
        }

        /**
         * plays the next video in the filmstrip
         *
         */
        public function onVideoComplete():void {

            thumbnailList.moveNext();

            if (player) {
                player.pause();
            }

        }

        /**
         * hideOverlayPlayButton
         * tells the videoTitleCard to fade out
         * @param VideoPlayerEvent
         *
         */
        private function hideOverlayPlayButton():void {

            overlayPlayButton.visible = false;

        }

        /**
         * showOverlayPlayButton
         * turns the videoTitleCard visibility on and fades it in
         * @param VideoPlayerEvent
         *
         */
        private function showOverlayPlayButton():void {

            setOverlayPlayButtonPostion();
            overlayPlayButton.visible = true;

        }

        /**
         * onFullScreen
         * checks to see the current fullscreen state
         * @param VideoPlayerEvent
         *
         */
        public function onFullScreen(goFullscreen:Boolean):void {

            try {

                if (goFullscreen) {
                    enterFullScreen();
                }
                else {
                    exitFullScreen();
                }
            }
            catch (e:Error) {
                handleError(e);
            }

        }

        private function handleError(e:Error):void {

        }

        /**
         * goFullScreen
         * toggles full screen state
         * @param event
         *
         */
        private function enterFullScreen():void {

            origvideox = player.x;
            origvideoy = player.y;
            origvideowidth = player.width;
            origvideoheight = player.height;

            thumbnailList.visible = false;
            background.visible = false;

            player.setSize(_width, _height);
            player.fullScreen = true;
            player.smoothing = true;

            player.move(0, 0);

            setOverlayPlayButtonPostion();
        }

        /**
         * exitFullScreen
         * exits the full screen state
         * @param event
         *
         */
        public function exitFullScreen():void {

            player.move(origvideox, origvideoy);
            player.setSize(origvideowidth, origvideoheight);
            player.fullScreen = false;
            player.smoothing = false;
            background.visible = true;
            thumbnailList.visible = true;
            playerBg.x = player.x;
            playerBg.y = player.y;
            setOverlayPlayButtonPostion();
        }

        /**
         * onVideoReady
         *
         * @param VideoPlayerEvent
         *
         */

        public function onVideoReady():void {

            if (player) {

                playerBg.x = player.x;
                playerBg.y = player.y;

                focusViewPlayerUrl = player.url;

                if (player) {
                    if ((model.savedVideoTime > MIN_WATCHED_TIME) && (player.videoType == VideoPlayer.STREAMING)) {
                        model.useSavedVideoTime = true;
                        // in order to seek the player we first need to tell it to play. No idea why seeking
                        // won't work if paused in this case
                        player.play();
                    }
                    else {
                        showOverlayPlayButton();
                    }
                }

                if (player.autoPlay) {
                    player.internalMediaContainer.visible = true;
                    player.visible = true;
                    hideOverlayPlayButton();
                }

                player.controlBar.addEventListener(MouseEvent.MOUSE_OVER, onControlBarOver, false, 0, true);

            }
        }

        /**
         * sets the position of the large play button above the video
         *
         */
        private function setOverlayPlayButtonPostion():void {
            if (player) {

                if (player.fullScreen) {
                    overlayPlayButton.scaleX = overlayPlayButton.scaleY = 1.75;
                }
                else {
                    overlayPlayButton.scaleX = overlayPlayButton.scaleY = 1;
                }
                overlayPlayButton.x = (player.x + (player.width - overlayPlayButton.width) / 2);
                overlayPlayButton.y = (player.y + (player.height - overlayPlayButton.height) / 2);
            }
        }

        /**
         * onKeyPress
         *
         */
        public function onKeyPress(keyCode:uint):void {
            if (player) {
                switch (keyCode) {
                    case spaceBarKeyCode:
                        togglePausePlayState();
                        break;
                    case escapeKeyCode:
                        if (player.fullScreen) {
                            exitFullScreen();
                        }

                    default:
                        //trace(evt.keyCode + " = evt.keyCode");
                }
            }

        }

        /**
         * createChildren
         *
         *
         */
        override protected function createChildren():void {
            super.createChildren();
            accessModel();

            if (player) {
                stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
            }

            background = new Sprite();
            addChild(background);

            vignette = new Sprite();

            var g:Graphics = vignette.graphics;
            var m:Matrix = new Matrix();
            m.createGradientBox(_width, _height);

            g.beginGradientFill(GradientType.RADIAL, [ 0x000000, 0x000000 ], [ .15, .7 ], [ 80, 255 ], m);
            g.drawRect(0, 0, _width, _height);
            g.endFill();
            background.addChild(backgroundImage);
            addChild(vignette);

            setChildIndex(background, 0);
            setChildIndex(vignette, 1);

            thumbnailList = new ThumbnailList();
            thumbnailList.setSize(_width, THUMBNAIL_LIST_HEIGHT);
            thumbnailList.move(0, Math.round((_height - thumbnailList.height)));

            thumbnailList.dataProvider = model.episodes;
            thumbnailList.addEventListener(Event.SELECT, onFilmstripChange, false, 0, true);
            thumbnailList.visible = false;
            addChild(thumbnailList);
            thumbnailList = thumbnailList;

            focusViewPlayerUrl = player.url;

            createErrorText();

            setUpHideVideoControlsTimer();
            setUpFilmstripChangeTimer();
            setUpErrorTimer();

            if ((currentEpisodeData) && (!player.url)) {
                player.url = currentEpisodeData._videoUrl;
            }

        }

        public function createErrorText():void {
            errorText = new TextField();
            errorText.autoSize = TextFieldAutoSize.LEFT;
            var tfm:TextFormat = new TextFormat("CorpoS", 22, 0xFFFFFF, false);
            tfm.align = TextFormatAlign.CENTER;
            errorText.defaultTextFormat = tfm;
            addChild(errorText);
        }

        public function removeErrorText():void {
            if (errorText) {
                removeChild(errorText);
                errorText = null;
            }
        }

        /**
         * onPlayerBgPress
         *
         *
         */
        private function onPlayerBgPress(evt:MouseEvent):void {
            togglePausePlayState();
        }

        /**
         * onOverlayPlayButtonPress
         */
        private function onOverlayPlayButtonPress(evt:MouseEvent):void {
            togglePausePlayState();
        }

        /**
         * onOverlayPlayButtonOver
         */
        private function onOverlayPlayButtonOver(evt:MouseEvent):void {

            TweenLite.to(overlayPlayButton.playIcon, .35, { tint: "0x99D7DB" });
            TweenLite.to(overlayPlayButton.outline, .2, { tint: "0x99D7DB", scaleX: 1.15, scaleY: 1.15, ease: Back.easeOut });

        }

        /**
         * onOverlayPlayButtonOut
         */
        private function onOverlayPlayButtonOut(evt:MouseEvent):void {

            TweenLite.to(overlayPlayButton.playIcon, .35, { tint: null });
            TweenLite.to(overlayPlayButton.outline, .2, { tint: null, scaleX: .95, scaleY: .95, ease: Quart.easeOut });
        }

        /**
         * when a filmstrip item is first selected
         * we hide and pause the video then set a timer
         * that waits until the user has selected a video.
         *
         */
        private function onFilmstripChange(e:Event):void {

            if (model.currentlySelectedVideoId != thumbnailList.selectedIndex) {
                if (player) {
                    if (!filmstripChangeTimer.running) {
                        player.hideControlBar(null);
                        player.pause();
                        hideOverlayPlayButton();
                        player.internalMediaContainer.visible = false;
                    }
                }
                filmstripChangeTimer.stop();
                filmstripChangeTimer.start();
            }
            else {
                if ((!player.playing) && (!filmstripChangeTimer.running)) {
                    player.play();
                }
            }

            if (errorTimer.running) {
                errorTimer.stop();
            }
        }

        /**
         * setup a timer that waits a bit before loading the selected video.
         *this slight pause will ensure we don't crash the channel by loading and unloading too many videos at once
         *
         */
        private function setUpFilmstripChangeTimer():void {
            filmstripChangeTimer = new Timer(FILMSTRIP_TIMEOUT);
            filmstripChangeTimer.addEventListener(TimerEvent.TIMER, onFilmstripChangeTimeOut);
        }

        /**
        * loads the next video
        *
        *
        */
        private function onFilmstripChangeTimeOut(evt:TimerEvent):void {

            filmstripChangeTimer.stop();

            if (!updateThumbnailListOnly) {

                if (model.currentlySelectedVideoId != thumbnailList.selectedIndex) {
                    loadSelectedVideo();
                }
                else if (model.currentlySelectedVideoId == thumbnailList.selectedIndex) {
                    player.showVideoControls();
                    player.play();
                    player.internalMediaContainer.visible = true;
                }
            }

            updateThumbnailListOnly = false;

        }

        /**
         * setup a timer that waits before selecting the next video if there was a video Error
         *
         */
        private function setUpErrorTimer():void {
            errorTimer = new Timer(ERROR_TIMEOUT);
            errorTimer.addEventListener(TimerEvent.TIMER, onErrorTimeOut);
        }

        /**
         * onErrorTimeOut
         *
         *
         */
        private function onErrorTimeOut(evt:TimerEvent):void {
            errorTimer.stop();
            onVideoComplete();
        }

        /**
         * positions all display objects on stage
         *
         *
         */
        override protected function layout():void {

            thumbnailList.move(0, Math.round((_height - thumbnailList.height)));
            thumbnailList.setSize(_width, THUMBNAIL_LIST_HEIGHT);

            if ((player) && (currentEpisodeData)) {

                thumbnailList.visible = true;

                maxVideoHeight = currentEpisodeData._videoHeight;

                if (!player.fullScreen) {
                    var availableHeight:Number = Math.round((thumbnailList.y - (VIDEO_PLAYER_PADDING * 2)));
                    var aspectRatio:Number = getAspectRatio(currentEpisodeData._videoWidth, currentEpisodeData._videoHeight);

                    if (availableHeight >= maxVideoHeight) {
                        player.setSize(currentEpisodeData._videoWidth, currentEpisodeData._videoHeight);
                    }
                    else {
                        var newVideoWidth:Number = Math.round(availableHeight * aspectRatio);
                    }

                    var horizCenter:int = ((_width - player.width) / 2);
                    var vertCenter:int = ((thumbnailList.y - player.height) / 2);

                    player.move(horizCenter, vertCenter);
                    playerBg.width = player.width;
                    playerBg.height = player.height;
                    playerBg.x = horizCenter;
                    playerBg.y = vertCenter;
                    setOverlayPlayButtonPostion();

                }

                thumbnailList.scrollPosition = model.currentlySelectedVideoId;

                if (thumbnailList.selectedIndex != model.currentlySelectedVideoId)
                    thumbnailList.selectedIndex = model.currentlySelectedVideoId;

            }

            if (spinner) {
                spinner.x = player.x + (player.width - spinner.width) / 2;
                spinner.y = player.y + (player.height - spinner.height) / 2
            }

            if (content.scrollRect == null) {
                content.scrollRect = new Rectangle(0, 0, _width, _height);
            }

            if (background) {
                setBackgroundSize();
                vignette.width = _width;
                vignette.height = _height;
            }

        }

        private function setBackgroundSize():void {
            backgroundImage.x = -((backgroundImage.width - _width) / 2);
            backgroundImage.y = -((backgroundImage.height - _height) / 2);
        }

        protected function doScale(clip:Sprite, w:Number, h:Number):void {
            clip.scaleX = clip.scaleY = 1;
            var unscaledWidth:Number = clip.width;
            var unscaledHeight:Number = clip.height;

            if (w > 0 || h > 0) {

                if (w / clip.width < h / clip.height) {
                    clip.width = Math.min(w, unscaledWidth * MAX_SCALE);
                    clip.scaleY = clip.scaleX;
                }
                else {
                    clip.height = Math.min(h, unscaledHeight * MAX_SCALE);
                    clip.scaleX = clip.scaleY;
                }
            }
            clip.x = (_width - clip.width) / 2;
            clip.y = (_height - clip.height) / 2;

        }

        private function getAspectRatio(width:Number, height:Number):Number {
            if (width > height) {
                return (width / height);
            }
            else {
                return (height / width);
            }
        }

        /**
         * set scrollX
         *
         *
         */
        public function set scrollX(value:Number):void {
            content.scrollRect = new Rectangle(value, 0, _width, _height);
        }

        /**
         * get scrollX
         *
         *
         */
        public function get scrollX():Number {
            return content.scrollRect.x;
        }

        /**
         * when the feed updates give the thumbnail list a new data provider and change the
         * models current episode data
         *
         *
         */
        protected function onFeedUpdate(e:FeedUpdateEvent):void {
            layout();
        }

        /**
         * onEpisodeDataUpdate
         *
         *
         */
        protected function onEpisodeDataUpdate(e:FeedUpdateEvent):void {
            if (player) {
                currentEpisodeData = model.currentEpisodeData;
            }
        }

        /**
         * onVideoViewTweenComplete
         *
         *
         */
        protected function onVideoViewTweenComplete(e:Event):void {
            loadSelectedVideo();
        }

        /**
         * loads the currently selected video into the player
         *
         *
         */
        protected function loadSelectedVideo():void {

            if (debugText) {
                removeChild(debugText);
                debugText = null;
            }

            model.currentEpisodeData = model.getEpisodeAt(thumbnailList.selectedIndex);
            currentEpisodeData = model.currentEpisodeData;
            model.currentlySelectedVideoId = thumbnailList.selectedIndex;

            stopHideVideoControlsTimer();
            filmstripChangeTimer.stop();

            if (player) {
                player.showVideoControls();
                player.url = currentEpisodeData._videoUrl;
                player.autoPlay = true;
                focusViewPlayerUrl = player.url;
                model.savedVideoTime = 0;
                model.useSavedVideoTime = false;
            }

        }

        /**
         * shows the playerBg and sets it's alpha
         *
         */
        private function showPlayerBg():void {
            playerBg.alpha = .5;
            playerBg.visible = true;
        }

        /**
         * shows the playerBg and sets it's alpha
         *
         */
        private function hidePlayerBg():void {
            playerBg.alpha = 0;
            playerBg.visible = false;
        }

        /**
         * add or remove a loading spinner to the stage
         *
         *
         */
        public function setLoading(b:Boolean):void {

            if (content == null)
                return;

            if (b) {
                if (spinner == null) {
                    spinner = new LoadingSpinner();
                    addChild(spinner);
                }

                if (player) {
                    if (player.fullScreen) {
                        spinner.scaleX = spinner.scaleY = 2;
                    }
                    else {
                        spinner.scaleX = spinner.scaleY = 1;
                    }

                    setLoaderPosition();
                    TweenLite.to(spinner, 0.2, { alpha: 1 });
                }
            }
            else {
                if (spinner) {

                    TweenLite.to(spinner, 0.2, { alpha: 0, onComplete: removeSpinner });
                }
                else
                    return;
            }

            if (videoList) {
                videoList.enabled = !b;
            }
        }

        /**
         * set the loading spinners position based on the videos width and height and the visibility of the overlayPlayButton
         *
         */
        private function setLoaderPosition():void {
            if (overlayPlayButton.visible) {
                spinner.y = overlayPlayButton.y + overlayPlayButton.height + 25;
            }
            else {
                spinner.y = player.y + (player.height - spinner.height) / 2;
            }
            spinner.x = player.x + (player.width - spinner.width) / 2;
        }

        /**
         * remove the loading spinner from the stage
         *
         */
        private function removeSpinner():void {
            if (spinner) {
                removeChild(spinner);
                spinner = null;
            }

        }

        /**
         * creates the timer that hides the video controls after no user interaction
         *
         */
        private function setUpHideVideoControlsTimer():void {
            hideVideoControlsTimer = new Timer(VIDEO_CONTROLS_TIMEOUT);
            hideVideoControlsTimer.addEventListener(TimerEvent.TIMER, onHideVideoControlsTimeOut);
        }

        /**
         * hides the video controls
         *
         *
         */
        private function onHideVideoControlsTimeOut(evt:TimerEvent):void {

            if (player) {
                if ((!mouseOverControlBar) && (!player.internalMediaPlayer.seeking) && (!player.internalMediaPlayer.buffering)) {
                    player.hideVideoControls();
                    hideVideoControlsTimer.stop();
                }
            }

        }

        /**
         * set mouseOverControlBar to true, so we don't hide the controlBar if the user is over it
         *
         *
         */
        private function onControlBarOver(evt:MouseEvent):void {
            mouseOverControlBar = true;

            if (player) {
                player.controlBar.addEventListener(MouseEvent.MOUSE_OUT, onControlBarOut);
                player.controlBar.removeEventListener(MouseEvent.MOUSE_OVER, onControlBarOver);
            }

        }

        /**
         * set mouseOverControlBar to false, so we know its ok to hide the controlBar on timeOut
         *
         *
         */
        private function onControlBarOut(evt:MouseEvent):void {
            mouseOverControlBar = false;

            if (player) {
                player.controlBar.removeEventListener(MouseEvent.MOUSE_OUT, onControlBarOut);
                player.controlBar.addEventListener(MouseEvent.MOUSE_OVER, onControlBarOver);
            }

        }

        /**
         * stop the timer controlling the hide/show of the controlBar
         *
         *
         */
        private function stopHideVideoControlsTimer():void {
            if (player) {

                hideVideoControlsTimer.stop();
            }

        }

        /**
         * start the timer controlling the hide/show of the controlBar
         *
         *
         */
        private function startHideVideoControlsTimer():void {
            if (player) {
                player.addEventListener(MouseEvent.MOUSE_MOVE, onMouseOverPlayer);
                player.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverPlayer);
                hideVideoControlsTimer.start();
            }
        }

        /**
         * restart the timer controlling the hide/show of the controlBar
         *
         *
         */
        private function restartHideVideoControlsTimer():void {
            if (player) {
                player.addEventListener(MouseEvent.MOUSE_MOVE, onMouseOverPlayer);
                player.addEventListener(MouseEvent.MOUSE_OVER, onMouseOverPlayer);

                if (hideVideoControlsTimer) {
                    hideVideoControlsTimer.stop();
                    hideVideoControlsTimer.start();
                }
            }

        }

        /**
         * checks to see if there is any new data from the feed
         *
         *
         */
        private function checkDataFreshness():void {

            if (thumbnailList.dataProvider != model.episodes) {
                thumbnailList.dataProvider = model.episodes;
                thumbnailList.refresh();
                thumbnailList.selectedIndex = model.currentlySelectedVideoId;

                model.currentEpisodeData = model.getEpisodeAt(thumbnailList.selectedIndex);
                model.currentlySelectedVideoId = thumbnailList.selectedIndex;

                currentEpisodeData = model.currentEpisodeData;
            }
        }

    }
}

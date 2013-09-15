package com.litl.tv.view
{

    import com.greensock.TweenLite;
    import com.greensock.easing.*;
    import com.greensock.plugins.AutoAlphaPlugin;
    import com.greensock.plugins.TweenPlugin;
    import com.litl.control.ControlBase;
    import com.litl.control.Filmstrip;
    import com.litl.control.ModalMenu;
    import com.litl.control.VideoPlayer;
    import com.litl.event.VideoPlayerEvent;
    import com.litl.sdk.message.UserInputMessage;
    import com.litl.sdk.message.WheelStatusMessage;
    import com.litl.sdk.service.ILitlService;
    import com.litl.sdk.util.Tween;
    import com.litl.skin.LitlColors;
    import com.litl.skin.parts.LoadingSpinner;
    import com.litl.tv.event.FeedUpdateEvent;
    import com.litl.tv.event.TitleCardEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.renderer.FilmstripFocusViewDataRenderer;
    import com.litl.tv.renderer.SlideshowDataRenderer;
    import com.litl.tv.utils.BufferingSpinner;
    import com.litl.tv.view.TitleCard;

    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.display.StageDisplayState;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.filters.GlowFilter;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.utils.Timer;

    import org.osmf.events.BufferEvent;
    import org.osmf.events.DisplayObjectEvent;
    import org.osmf.events.MediaPlayerStateChangeEvent;
    import org.osmf.events.PlayEvent;
    import org.osmf.events.SeekEvent;
    import org.osmf.events.TimeEvent;
    import org.osmf.media.MediaElement;
    import org.osmf.traits.MediaTraitType;
    import org.osmf.traits.SeekTrait;
    import org.osmf.traits.TimeTrait;

    public class FullScreenVideoView extends ControlBase
    {
        private var FILMSTRIP_HIDDEN_Y:Number = 0;
        private var FILMSTRIP_SHOWN_Y:Number = 0;

        public static const ERROR_TIMEOUT:int = 5000;

        private static const FILMSTRIP_HEIGHT:Number = 124;

        private static var FAST_FORWARD_INTERVAL:Number = 10;
        private static var DEFAULT_FORWARD_INTERVAL:Number = 10;
        private static var REWIND_INTERVAL:Number = 10;
        private static var DEFAULT_REWIND_INTERVAL:Number = 10;

        private static const MENU_ITEM_1:String = "Rewind/Fast-forward";
        private static const MENU_ITEM_2:String = "Resume Playback";
        private static const MENU_ITEM_2A:String = "Play Video";
        private static const MENU_ITEM_3:String = "Select Episode";

        private static const VIDEO_UNAVAILABLE_TEXT:String = "Oops! The video you've chosen is currently unavailable.";
        private static const AUTO_PLAY_TEXT:String = "\n \n The next video will begin in 5 seconds. ";

        protected var seeking:Boolean = false;
        protected var menu:ModalMenu;
        protected var menuOpen:Boolean = false;
        protected var filmstripOpen:Boolean = false;
        protected var filmstrip:Filmstrip;
        protected var player:VideoPlayer;
        protected var model:AppModel;
        protected var _service:ILitlService;
        private var currentEpisodeData:EpisodeData;
        private var currentPlayerTime:Number = 0;
        private var initSeek:Boolean = true;
        protected var spinner:BufferingSpinner;
        private var hardCodedHeight:Number = 720;
        private var titleCards:Array = null;
        private var currentTitleCard:TitleCard = null;
        private var previousTitleCard:TitleCard = null;
        public var titleCardBg:Sprite = null;
        private var previousFilmstripScrollPosition:int = -1;
        private var errorText:TextField = null;
        private var errorTimer:Timer = null;
        private var nearestKeyFrameIncrement:Number = 0;
        private var _seekTrait:SeekTrait;
        private var previousPlayerPosition:Number = 0;
        public static const MAX_SCALE:Number = 1.5;
        private var _networkConnected:Boolean;
        private var fastForwardTimer:Timer;
        private var rewindTimer:Timer;
        private var fastForwardRate:Number = 0;
        private var rewindRate:Number = 0;
        private var currentFastForwardRate:Number = 0;
        private var SCRUBBING_RATE_TIMEOUT:Number = 500;
        public static const SCRUB_BAR_HEIGHT:Number = 50;
        public static const TIME_BUBBLE_HEIGHT:Number = 46;
        public static const MIN_WATCHED_TIME:int = 10;
        public var inScreenSaver:Boolean = false;
        private var debugText:TextField;
        private var allErrorText:Array = new Array();

        public function FullScreenVideoView() {
            super();

        }

        public function get networkConnected():Boolean {
            return _networkConnected;
        }

        public function set networkConnected(value:Boolean):void {
            _networkConnected = value;
        }

        public function set selectorMode(value:Boolean):void {

            if (player) {
                player.visible = !value;
                this.setChildIndex(player, 0);
            }

            if (errorText) {
                errorText.visible = !value;
            }

            if (value) {
                if (player)
                    player.autoPlay = false;
                setLoading(false);
            }
            else {
                player.play();
                player.autoPlay = true;
            }

            if (spinner) {
                spinner.visible = false;
            }

        }

        /** @private */
        public function get videoPlayer():VideoPlayer {
            return player;
        }

        /**
         * Pass the VideoPlayer instance into this view. We will reparent it so that it moves in relation to this DisplayObject.
         * @param value	The app's VideoPlayer instance.
         */
        public function set videoPlayer(value:VideoPlayer):void {

            player = value;

            if (player) {
                if (player.parent) {
                    player.parent.removeChild(player);
                }
                this.addChildAt(player, 0);

                if (!filmstrip) {
                    createChildren();
                }

                player.setSize(_width, _height);
                player.move(0, 0);
                player.features = VideoPlayer.FEATURES_SCRUB_BAR;
                player.smoothing = true;
                player.CONTROL_BAR_HEIGHT = SCRUB_BAR_HEIGHT;
                player.TIME_BUBBLE_HEIGHT = TIME_BUBBLE_HEIGHT;

                // if we have any data to work with set the video player to the currently selected episode
                // only if we don't have a player.url
                if (currentEpisodeData) {
                    // make sure our views data is in sync with the models
                    currentEpisodeData = model.currentEpisodeData;

                    if (!player.url) {
                        player.url = currentEpisodeData._videoUrl;
                    }
                }

                if (player.controlBar) {
                    player.controlBar.visible = false;
                    // by default set the players seek ability to false
                    player.seeking = false;
                }

                if (filmstrip) {
                    FILMSTRIP_SHOWN_Y = (_height - filmstrip.height);
                    FILMSTRIP_HIDDEN_Y = (_height + filmstrip.height);
                    filmstrip.setSize(_width, FILMSTRIP_HEIGHT);
                    filmstrip.scrollPosition = model.currentlySelectedVideoId;
                    checkDataFreshness();

                    if (filmstripOpen) {
                        hideFilmstrip();
                    }

                    if (menuOpen) {
                        hideMenu();
                    }
                }

                if (errorText) {
                    positionErrorText();
                }

            }

        }

        public function onVideoReady():void {

            if (player) {
                if ((model.savedVideoTime > MIN_WATCHED_TIME) && (player.videoType == VideoPlayer.STREAMING)) {
                    model.useSavedVideoTime = true;
                        //player.play();
                        //player.autoPlay = true;
                }

            }

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

        /**
         * layout
         *
         *
         */
        override protected function layout():void {

            FILMSTRIP_SHOWN_Y = (_height - filmstrip.height);
            FILMSTRIP_HIDDEN_Y = (_height + filmstrip.height);
            filmstrip.setSize(_width, FILMSTRIP_HEIGHT);

            if (player) {
                player.setSize(_width, _height);

                if (player.controlBar)
                    player.controlBar.visible = false;
            }

            positionErrorText();

        }

        /**
         * checks to see if there is any new data from the feed
         *
         *
         */
        private function checkDataFreshness():void {

            // if there's new data to work with, update the filmstrip
            if (filmstrip.dataProvider != model.episodes) {
                filmstrip.dataProvider = model.episodes;
                filmstrip.refresh();
                filmstrip.scrollPosition = model.currentlySelectedVideoId;

                model.currentEpisodeData = model.getEpisodeAt(filmstrip.scrollPosition);
                model.currentlySelectedVideoId = filmstrip.scrollPosition;

                currentEpisodeData = model.currentEpisodeData;
            }
        }

        private function accessModel():void {
            model = AppModel.getInstance();
            model.addEventListener(FeedUpdateEvent.FEED_UPDATE, onFeedUpdate, false, 0, true);
            model.addEventListener(FeedUpdateEvent.CURRENT_DATA_UPDATE, onEpisodeDataUpdate, false, 0, true);

            currentEpisodeData = model.currentEpisodeData;

        }

        public function set service(svc:ILitlService):void {
            if (_service == null) {
                _service = svc;

                _service.addEventListener(UserInputMessage.GO_BUTTON_PRESSED, handleGoPressed);
                _service.addEventListener(UserInputMessage.WHEEL_DOWN, handleWheel);
                _service.addEventListener(UserInputMessage.WHEEL_UP, handleWheel);
                _service.addEventListener(WheelStatusMessage.WHEEL_STATUS, handleWheelStatus);
            }
        }

        public function get service():ILitlService {
            return _service;
        }

        public function onStateChange(state:String):void {

            switch (state) {
                case "playing":
                    setStageFrameRate(12);
                    setLoading(false);

                    if (player) {
                        player.internalMediaContainer.visible = true;

                        if (model) {
                            if (model.useSavedVideoTime) {
                                player.seek(model.savedVideoTime);
                                model.useSavedVideoTime = false;
                            }
                        }
                    }
                    clearVideoError();
                    break;
                case "loading":
                    setLoading(true);
                    break;
                case "paused":
                    setLoading(false);
                    setStageFrameRate(30);
                    break;
                case "stopped":
                    //showOverlayPlayButton();
                    // showPlayerBg();
                    setStageFrameRate(30);
                    break;
                case "ready":

                    if (model)
                        model.initialVideoLoaded = true;
                    setLoading(false);
                    break;

                case "playbackError":
                    handleVideoError();
                    setLoading(false);
                    break;
                default:
                    trace(state + " = evt.MediaPlayerStateChangeEvent");
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

        private function handleVideoError():void {

            if (player.autoPlay) {
                errorTimer.start();
                errorText.text = VIDEO_UNAVAILABLE_TEXT + AUTO_PLAY_TEXT;
            }
            else {
                errorText.text = VIDEO_UNAVAILABLE_TEXT;
            }

            if (errorText.visible) {
                TweenLite.to(errorText, .35, { alpha: 0, ease: Quart.easeOut, onComplete: fadeInErrorText });
            }
            positionErrorText();
            errorText.visible = true;
        }

        private function fadeInErrorText():void {
            TweenLite.to(errorText, .35, { alpha: 1, ease: Quart.easeOut });
        }

        private function clearVideoError():void {
            if (errorText) {
                errorText.text = "";
                errorText.visible = false;
            }
        }

        private function positionErrorText():void {
            if (player) {
                errorText.x = ((player.width - errorText.width) / 2) + player.x;
                errorText.y = ((player.height - errorText.height) / 2) + player.y;
            }
        }

        /**
         *
         *
         */
        private function setStageFrameRate(rate:Number):void {
            if (stage) {
                stage.frameRate = rate;
            }
        }

        /**
         * Called when the go button is pressed on the device.
         * This event will usually be followed by an optional GO_BUTTON_HELD event, and then a GO_BUTTON_RELEASED event.
         * @param e	The UserInputMessage instance.
         *
         */
        private function handleGoPressed(e:UserInputMessage):void {

            // When the go button is pressed, request to enable or disable the wheel.
            // This will result in a WheelStatusMessage, which we listen for
            // and call handleWheelStatus.
            if (menuOpen) {
                selectCurrentMenuItem();

            }
            else if (filmstripOpen) {
                if (model.currentlySelectedVideoId != filmstrip.scrollPosition) {
                    model.currentEpisodeData = model.getEpisodeAt(filmstrip.scrollPosition);
                }
                // if the user selected the current video don't load another video but resume playing the current one
                else {

                    player.play();
                }

                hideFilmstrip();

                service.disableWheel();
            }
            else if (service.wheelEnabled) {
                service.disableWheel();
            }
            else {
                service.enableWheel();
            }

        }

        /**
         *
         */
        private function addNewTitleCard():void {

            var titleCard:TitleCard = new TitleCard();
            titleCards.push(titleCard);
            addChild(titleCard);

            var currentCardData:EpisodeData = model.getEpisodeAt(filmstrip.scrollPosition);

            var episodeTitle:String = currentCardData._title;
            var episodeDescription:String

            if (currentCardData._longDescription) {
                episodeDescription = currentCardData._longDescription;
            }
            else {
                episodeDescription = currentCardData._shortDescription;
            }
            var episodeNumber:String = currentCardData._number;
            var runTime:String = currentCardData._runTime;
            var airDate:Date = currentCardData._airDate;

            titleCard.setSize(_width, _height);
            titleCard.setText(episodeTitle, episodeDescription, episodeNumber, runTime, airDate);

            var centerY:int = (((_height - FILMSTRIP_HEIGHT) - titleCard.height) / 2);
            var centerX:int = ((_width - titleCard.width) / 2);

            titleCard.y = Math.round(centerY - 30);

            if (previousFilmstripScrollPosition > filmstrip.scrollPosition) {
                titleCard.x = -1 * _width;

                if (previousTitleCard != null) {
                    TweenLite.to(previousTitleCard, .75, { x: (_width + 300), ease: Quart.easeOut, onComplete: removeTitleCard, onCompleteParams: [ previousTitleCard ]});
                }
            }
            else if (previousFilmstripScrollPosition < filmstrip.scrollPosition) {

                titleCard.x = _width;

                if (previousTitleCard != null) {
                    TweenLite.to(previousTitleCard, .75, { x: (previousTitleCard.width + 300) * -1, ease: Quart.easeOut, onComplete: removeTitleCard, onCompleteParams: [ previousTitleCard ]});
                }
            }

            currentTitleCard = titleCard;
            //currentTitleCard.setSize(player.width, player.height);
            TweenLite.to(currentTitleCard, .75, { x: Math.round(centerX), ease: Quart.easeOut });
            previousTitleCard = currentTitleCard;

        }

        private function removeTitleCard(titleCard:TitleCard):void {
            removeChild(titleCard);
        }

        /**
         * Called when the wheel has been disabled or enabled. In our case, we will use this to show
         * the filmstrip in channel mode.
         * @param e	The WheelStatusMessage instance.
         *
         */
        private function handleWheelStatus(e:WheelStatusMessage):void {

            if (e.wheelEnabled)
                showMenu();
            else {
                hideMenu();
                hideFilmstrip();

                if (seeking) {
                    seeking = false;
                    currentPlayerTime = player.position;
                    player.play();
                    player.hideVideoControls();
                }
            }
        }

        /**
         * Called when the wheel is turned.
         * We will only receive this event when the wheel is currently enabled.
         * In our case, we are going to move the filmstrip in channel mode forwards and backwards.
         * @param e	The UserInputMessage instance.
         *
         */
        private function handleWheel(e:UserInputMessage):void {

            if (e.type == "wheelUp") {
                wheelUp();
            }
            else {
                wheelDown();
            }
        }

        /**
         * Fade the menu into view, if it isn't already.
         */
        public function showMenu():void {

            if (menu == null) {
                menu = new ModalMenu();
                menu.dataProvider = [ MENU_ITEM_1, player.playing ? MENU_ITEM_2 : MENU_ITEM_2A, MENU_ITEM_3 ];

                menu.alpha = 0;
                addChild(menu);
            }
            menu.setSize(_width, _height);
            Tween.tweenTo(menu, 0.2, { alpha: 1 });
            menuOpen = true;

            // Automatically select the middle item.
            menu.selectedIndex = 1;

            player.pause();
        }

        /**
         * Fade the menu out of view, if it isn't already.
         */
        public function hideMenu():void {
            if (menu) {

                var tween:Tween = Tween.tweenTo(menu, 0.2, { alpha: 0 });
                tween.addEventListener(Event.COMPLETE, removeMenu, false, 0, true);
            }
            menuOpen = false;
        }

        /**
         * removes the Modal menu from the display list
         */
        private function removeMenu(e:Event = null):void {
            if (menu)
                removeChild(menu);

            menu = null;

            // if we aren't seeking then we're selecting a new episode from the thumbnail list
            if (!seeking) {

            }

        }

        /**
         * creates the titleCardBg
         *
         */
        private function createTitleCardBg():void {

            if (titleCardBg == null) {
                titleCardBg = new Sprite();
                titleCardBg.graphics.beginFill(0x000000);
                titleCardBg.graphics.drawRect(0, 0, _width, _height);
                titleCardBg.graphics.endFill();
                var playerIndex:int = this.getChildIndex(filmstrip)
                addChildAt(titleCardBg, 1);
            }
            titleCardBg.alpha = .75;
            titleCardBg.visible = true;

        }

        /**
         * Slide the filmstrip into view, if it isn't already.
         */
        public function showFilmstrip():void {

            filmstripOpen = true;

            setStageFrameRate(30);

            createTitleCardBg();

            filmstrip.scrollPosition = model.currentlySelectedVideoId;
            Tween.tweenTo(filmstrip, 0.4, { y: FILMSTRIP_SHOWN_Y });

        }

        /**
         * Slide the filmstrip out of view, if it isn't already.
         * If the user chose a new video, send it to the player.
         */
        public function hideFilmstrip():void {
            hideTitleCard();
            Tween.tweenTo(filmstrip, 0.4, { y: FILMSTRIP_HIDDEN_Y });
            filmstripOpen = false;

            setStageFrameRate(12);
        }

        private function hideTitleCard():void {
            if (titleCardBg) {
                titleCardBg.visible = false;
                currentTitleCard.visible = false;
            }
            //removeChild(currentTitleCard);

        }

        /**
         * Scroll the filmstrip forward (right) one item.
         */
        public function wheelDown():void {

            if (seeking) {
                fastForward();
            }
            else if (menuOpen)
                menu.selectedIndex++;
            else if (filmstripOpen)
                filmstrip.scrollPosition++;

        }

        /**
         * Scroll the filmstrip backwards (left) one item.
         */
        public function wheelUp():void {

            if (seeking) {
                rewind();
            }
            else if (menuOpen)
                menu.selectedIndex--;
            else if (filmstripOpen)
                filmstrip.scrollPosition--;

        }

        /**
         * fastForward
         */
        private function fastForward():void {

            fastForwardRate++;

            if (fastForwardRate > DEFAULT_FORWARD_INTERVAL) {
                FAST_FORWARD_INTERVAL = (fastForwardRate * 2)
            }

            player.fastForward(FAST_FORWARD_INTERVAL);

            fastForwardTimer.stop();
            fastForwardTimer.start();
        }

        private function rewind():void {

            rewindRate++;

            if (rewindRate > DEFAULT_REWIND_INTERVAL) {
                REWIND_INTERVAL = (rewindRate * 2)
            }

            player.rewind(REWIND_INTERVAL);

            rewindTimer.stop();
            rewindTimer.start();
        }

        private function onSeekChange(evt:SeekEvent):void {

            if (player) {
                var timeTrait:TimeTrait = player.internailMediaElement.getTrait(MediaTraitType.TIME) as TimeTrait;

                if (timeTrait.currentTime < evt.time) {

                }
                else if (timeTrait.currentTime >= evt.time) {
                    nearestKeyFrameIncrement = 0;
                }
            }

        }

        /**
         * selectCurrentMenuItem
         */
        public function selectCurrentMenuItem():void {

            if (menuOpen) {
                var si:int = menu.selectedIndex;

                if (si == 0) {
                    hideMenu();
                    player.seeking = true;
                    player.showVideoControls();
                    seeking = true;
                }
                else if (si == 1) {
                    service.disableWheel();
                    player.play();
                    hideMenu();
                }
                else if (si == 2) {
                    hideMenu();
                    showFilmstrip();
                }
            }
        }

        /**
         * Create the components for this view.
         * @private
         */
        override protected function createChildren():void {

            accessModel();
            titleCards = new Array();

            if (player)
                player.setSize(_width, _height);
            // Create the filmstrip.
            filmstrip = new Filmstrip();
            addChild(filmstrip);
            filmstrip.itemRenderer = SlideshowDataRenderer;
            filmstrip.setSize(_width, FILMSTRIP_HEIGHT);
            FILMSTRIP_SHOWN_Y = (_height - filmstrip.height);
            FILMSTRIP_HIDDEN_Y = (_height + filmstrip.height);
            filmstrip.move(0, 2000);
            filmstrip.setStyle("padding", 10);
            filmstrip.addEventListener(Event.SELECT, onFilmstripChange, false, 0, true);

            filmstrip.dataProvider = model.episodes;

            if (player)
                setChildIndex(player, 0);
            setChildIndex(filmstrip, 1);

            errorText = new TextField();
            errorText.autoSize = TextFieldAutoSize.LEFT;
            var tfm:TextFormat = new TextFormat("CorpoS", 28, 0xFFFFFF, false);
            tfm.align = TextFormatAlign.CENTER;
            errorText.defaultTextFormat = tfm;
            addChild(errorText);
            // create the timer for the error text to go away
            setUpErrorTimer();

            // if the player url hasn't been set by focus view yet
            if ((player) && (!player.url) && (currentEpisodeData)) {

                player.url = currentEpisodeData._videoUrl;
                model.initialVideoLoaded = true;
            }
            setUpTimers();
            layout();

            filmstrip.scrollPosition = model.currentlySelectedVideoId;
        }

        private function setUpTimers():void {
            fastForwardTimer = new Timer(SCRUBBING_RATE_TIMEOUT);
            fastForwardTimer.addEventListener(TimerEvent.TIMER, onFastForwardTimeout);

            rewindTimer = new Timer(SCRUBBING_RATE_TIMEOUT);
            rewindTimer.addEventListener(TimerEvent.TIMER, onRewindTimeout);
        }

        private function onFastForwardTimeout(evt:TimerEvent):void {

            FAST_FORWARD_INTERVAL = DEFAULT_FORWARD_INTERVAL;
            fastForwardRate = 0;
            fastForwardTimer.stop();

        }

        private function onRewindTimeout(evt:TimerEvent):void {

            REWIND_INTERVAL = DEFAULT_REWIND_INTERVAL;
            rewindRate = 0;
            rewindTimer.stop();

        }

        /**
         * onEpisodeDataUpdate
         *
         *
         */
        protected function onEpisodeDataUpdate(e:FeedUpdateEvent):void {
            if (player) {
                trace("onEpisodeDataUpdate FullScreenVideoView :: currentEpisodeData is " + model.currentEpisodeData._title)
                currentEpisodeData = model.currentEpisodeData;
                player.url = currentEpisodeData._videoUrl;
                model.savedVideoTime = 0;
                model.useSavedVideoTime = false;
                model.currentlySelectedVideoId = filmstrip.scrollPosition;
            }
        }

        /**
         * when a video has completed we load the next one
         *
         */
        public function onVideoComplete():void {

            loadNextVideo();

        }

        /**
         * sets the currentlySelectedVideoId in our model to the next video
         * then sets the models currentEpisodeData which bubbles an event
         */
        private function loadNextVideo():void {

            if (model.currentlySelectedVideoId < (filmstrip.dataProvider.length - 1)) {
                model.currentlySelectedVideoId += 1;
            }
            else {
                model.currentlySelectedVideoId = 0;
            }
            var nextVideoId:Number = model.currentlySelectedVideoId;
            filmstrip.scrollPosition = model.currentlySelectedVideoId;
            model.currentEpisodeData = model.getEpisodeAt(model.currentlySelectedVideoId);

        }

        /**
         * Called when the current feed is updated in the model
         * @param e	A FeedUpdateEvent instance.
         * @private
         */
        protected function onFeedUpdate(e:FeedUpdateEvent):void {

            if (filmstrip) {
                filmstrip.dataProvider = model.episodes;
            }

        }

        /**
         * Called when a new item is selected in the filmstrip.
         * @param e A SELECT event.
         */
        protected function onFilmstripChange(e:Event):void {

            if (filmstripOpen) {
                addNewTitleCard();
            }
            previousFilmstripScrollPosition = filmstrip.scrollPosition;
        }

        /**
         * setLoading
         *
         *
         */
        public function setLoading(b:Boolean):void {
            if (player == null)
                return;

            if (b) {
                if (spinner == null) {
                    spinner = new BufferingSpinner();
                    addChild(spinner);

                    if (player) {
                        spinner.scaleX = spinner.scaleY = 1.5;
                        spinner.x = player.x + (player.width - spinner.width) / 2;
                        spinner.y = player.y + (player.height - spinner.height) / 2;
                    }
                }

                TweenLite.to(spinner, 0.2, { alpha: 1 });

            }
            else {
                if (spinner) {

                    TweenLite.to(spinner, 0.2, { alpha: 0, onComplete: removeSpinner });

                }
                else
                    return;
            }

        }

        /**
         * removeSpinner
         *
         *
         */
        private function removeSpinner():void {
            if (spinner) {
                removeChild(spinner);
                spinner = null;
            }
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
         *
         *
         *
         */
        private function onErrorTimeOut(evt:TimerEvent):void {

            errorTimer.stop();
            onVideoComplete();
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
            debugText.x = 350;

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
                    setLoading(true);
                }
                else {
                    setLoading(false);
                }
            }
        }

    }
}

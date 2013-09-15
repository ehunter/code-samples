/* Copyright (c) 2010 litl, LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */
package com.litl.control
{
    import com.litl.control.playerclasses.LitlMediaFactory;
    import com.litl.control.playerclasses.VideoPlayerControlBar;
    import com.litl.event.FullscreenEvent;
    import com.litl.event.MetaDataEvent;
    import com.litl.event.VideoPlayerEvent;
    import com.litl.sdk.util.Tween;
    import com.litl.skin.parts.LightSpinner;
    import com.litl.tv.event.SMILParserEvent;
    import com.litl.tv.utils.SMILParser;
    import com.litl.tv.utils.StringUtils;

    import flash.display.Sprite;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.net.NetStream;
    import flash.utils.Dictionary;

    import org.osmf.containers.MediaContainer;
    import org.osmf.elements.VideoElement;
    import org.osmf.events.BufferEvent;
    import org.osmf.events.DisplayObjectEvent;
    import org.osmf.events.LoadEvent;
    import org.osmf.events.MediaErrorEvent;
    import org.osmf.events.MediaPlayerStateChangeEvent;
    import org.osmf.events.PlayEvent;
    import org.osmf.events.SeekEvent;
    import org.osmf.events.TimeEvent;
    import org.osmf.layout.HorizontalAlign;
    import org.osmf.layout.LayoutMetadata;
    import org.osmf.layout.LayoutRenderer;
    import org.osmf.layout.ScaleMode;
    import org.osmf.layout.VerticalAlign;
    import org.osmf.media.MediaElement;
    import org.osmf.media.MediaFactory;
    import org.osmf.media.MediaPlayer;
    import org.osmf.media.MediaResourceBase;
    import org.osmf.media.MediaType;
    import org.osmf.media.URLResource;
    import org.osmf.net.NetStreamCodes;
    import org.osmf.net.StreamingURLResource;
    import org.osmf.traits.LoadState;
    import org.osmf.traits.MediaTraitType;
    import org.osmf.traits.SeekTrait;

    /**
     * Dispatched when a video has completed playback.
     */
    [Event(name="complete", type="com.litl.event.VideoPlayerEvent")]

    /**
     * Dispatched when a video is loaded and ready to play.
     */
    [Event(name="ready", type="com.litl.event.VideoPlayerEvent")]
    /**
     * Dispatched when the scrubBar is shown
     */
    [Event(name="showScrubBar", type="com.litl.event.VideoPlayerEvent")]
    /**
     * Dispatched when the scrubBar is hidden
     */
    [Event(name="hideScrubBar", type="com.litl.event.VideoPlayerEvent")]

    /**
     * Dispatched when the fullscreen button is clicked. You should implement a new view that resizes the video
     * player to the stage size.
     */
    [Event(name="fullscreen", type="com.litl.event.VideoPlayerEvent")]

    /**
     * Dispatched when an error occurs in the player.
     */
    [Event(name="error", type="flash.events.ErrorEvent")]
    /**
     * Dispatched when the metadata for a video is received
     */
    [Event(name="onMetaData", type="com.litl.event.MetaDataEvent")]

    /**
     * <p>Class for a generic media player.</p>
     * <p>This player uses the Open Source Media Framework, and so can handle the same media types. It has also been extended
     * to handle YouTube videos using the official YouTube player.</p>
     * @author litl
     * @example
     * <listing version="3.0">
     *
     * package
     * {
     *     import com.litl.control.VideoPlayer;
     *     import flash.display.Sprite;
     *
     *     public class VideoPlayerTest extends Sprite {
     *
     *     private var player:VideoPlayer;
     *
     *         public function VideoPlayerTest() {
     *                  player = new VideoPlayer();
     *                  addChild(player);
     *                  player.setSize(1280, 674);
     *                  player.move(0, 0);
     *                  //player.url = "http://dl.dropbox.com/u/2980264/OSMF/logo_animated.flv";
     *                  player.url = "http://www.youtube.com/watch?v=qybUFnY7Y8w";
     *     }
     *     }
     * }
     * </listing>
     */
    public class VideoPlayer extends ControlBase
    {
        public static const FEATURES_NONE:int = 0;
        public static const FEATURES_SCRUB_BAR:int = 1;
        public static const FEATURES_PLAY_BUTTON:int = 6;
        public static const FEATURES_VOLUME_BAR:int = 32;
        public static const FEATURES_FULLSCREEN_BUTTON:int = 64;
        public static const FEATURES_FULLSCREEN_LINK:int = 128;

        public var initialWidth:Number = 0;
        public var initialHeight:Number = 0;

        /** Constant to define how high the control bar should be. */
        public var CONTROL_BAR_HEIGHT:Number = 26;
        /** Constant to define the height of the timeBubble. */
        public var TIME_BUBBLE_HEIGHT:Number = 85;

        /** The current OSMF media factory
         * @private */
        protected var mediaFactory:MediaFactory;
        /** The current OSMF media player. This controls playback, seeking, etc.
         * @private */
        protected var mediaPlayer:MediaPlayer;

        /** The current OSMF media element being loaded/played.
         * @private */
        protected var mediaElement:MediaElement;
        /** The container in which the current media element sits.
         * @private */
        protected var mediaContainer:MediaContainer;
        /** The OSMF layout renderer
         * @private */
        protected var layoutRenderer:LayoutRenderer;
        /** Our control bar implementation.
         * @private */
        public var controlBar:VideoPlayerControlBar;
        /** Mask for control bar so we can animate it in and out
         * @private */
        private var controlBarMask:Sprite;

        protected var spinner:LightSpinner;

        private var tween:Tween;

        /** The current URL being loaded/played.
         * @private */
        protected var _url:String;
        /** @private */
        protected var _urlChanged:Boolean = false;
        private var _smoothing:Boolean;

        private var _isReady:Boolean = false;

        protected var _metadataChanged:Boolean = false;

        protected var _autoPlay:Boolean = false;
        /** @private */
        protected var _autoPlayChanged:Boolean = false;

        /** @private */
        protected var _resource:MediaResourceBase;
        /** @private */
        protected var _resourceChanged:Boolean = false;
        /** @private */
        protected var _features:int = FEATURES_SCRUB_BAR | FEATURES_PLAY_BUTTON;
        /** @private */
        protected var _featuresChanged:Boolean = false;
        /** @private */
        private var _fullScreen:Boolean = false;
        public var videoType:String = "";
        private var currentMetadata:Object = null;
        public var seeking:Boolean = false;

        public static var STREAMING:String = "streaming";
        public static var PROGRESSIVE:String = "progressive";

        public static var MP4_TYPE:String = "mp4";
        public static var FLV_TYPE:String = "flv";
        public static var F4V_TYPE:String = "f4v";
        public static var SMIL_TYPE:String = "SMIL";

        public static var HTTP_URL:String = "http";
        public static var RTMP_URL:String = "rtmp";
        public var urlIsValid:Boolean;
        private var validVideoTypes:Dictionary;
        private var currentResource:URLResource = null;

        private var CONTROL_BAR_HIDDEN_Y:Number;
        private var CONTROL_BAR_SHOWN_Y:Number;

        private var initSeek:Boolean = true;
        private var previousPlayerPosition:Number = 0;

        private var currentPlayerTime:Number = 0;
        private var previousPlayerTime:Number = 0;
        private var stream:NetStream;
        private var amountToSeek:Number = 0;
        private var fastForwarding:Boolean = false;

        /** Constructor. */
        public function VideoPlayer() {

        }

        public function get isReady():Boolean {
            return _isReady;
        }

        public function set isReady(value:Boolean):void {
            _isReady = value;
        }

        /** The current smoothing state of the player.
         * @private */
        public function get smoothing():Boolean {
            return _smoothing;
        }

        /**
         * @private
         */
        public function set smoothing(value:Boolean):void {
            var videoElement:VideoElement = VideoElement(mediaElement);

            if (videoElement)
                videoElement.smoothing = value;
            _smoothing = value;
        }

        /** @private */
        public function get fullScreen():Boolean {
            return _fullScreen;
        }

        /**
         * @private
         */
        public function set fullScreen(value:Boolean):void {
            _fullScreen = value;

            if (controlBar)
                controlBar.fullScreen = value;
        }

        /** @private */
        public function get autoPlay():Boolean {
            return _autoPlay;
        }

        /**
         * Get/Set whether to automatically play a video once loaded.
         */
        public function set autoPlay(value:Boolean):void {
            _autoPlayChanged = _autoPlayChanged || (value != _autoPlay);
            _autoPlay = value;

            if (_autoPlayChanged)
                invalidateProperties();
        }

        /**
         * Get/Set the current OSMF resource for the video player.
         * If you are simply streaming from a URL, use the url property instead.
         * @param value A resource extending from MediaResourceBase.
         * @see #url
         * @example
         * <listing version="3.0">
         * import com.litl.control.playerclasses.YouTubeResource;
         * var resource:YouTubeResource = new YouTubeResource();
         * resource.id = "qybUFnY7Y8w";
         * player.resource = resource;
         * </listing>
         */
        public function set resource(value:MediaResourceBase):void {
            _resourceChanged = _resourceChanged || (value != _resource);

            if (_resourceChanged)
                invalidateProperties();
        }

        /** @private */
        public function get resource():MediaResourceBase {
            return _resource;
        }

        /**
         * Set the URL of the source for this video player.
         * The URL can point to any of the supported media types.
         * You can also pass an OSMF media resource directly with the resource parameter.
         * @param value The URL to load.
         * @see #resource
         * @example
         * <listing version="3.0">
         * player.url = "http://dl.dropbox.com/u/2980264/OSMF/logo_animated.flv";
         * </listing>
         */
        public function set url(value:String):void {

            var lowerCaseUrl:String = value.toLowerCase();

            determineUrlType(value);
        }

        private function determineUrlType(value:String):void {

            switch (true) {
                case StringUtils.contains(value, HTTP_URL):
                    determineVideoType(value, HTTP_URL);
                    break;
                case StringUtils.contains(value, RTMP_URL):
                    determineVideoType(value, RTMP_URL);
                    break;
                default:
                    dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
                    break;
            }

        }

        private function determineVideoType(videoUrl:String, urlType:String):void {

            switch (urlType) {
                case HTTP_URL:

                    switch (true) {
                        case StringUtils.contains(videoUrl, MP4_TYPE):
                            videoType = PROGRESSIVE;
                            _urlChanged = _urlChanged || (_url != videoUrl);
                            _url = videoUrl;
                            break;
                        case StringUtils.contains(videoUrl, FLV_TYPE):
                            videoType = PROGRESSIVE;
                            _urlChanged = _urlChanged || (_url != videoUrl);
                            _url = videoUrl;
                            break;
                        case StringUtils.contains(videoUrl, F4V_TYPE):
                            videoType = PROGRESSIVE;
                            _urlChanged = _urlChanged || (_url != videoUrl);
                            _url = videoUrl;
                            break;
                        // does this url contain valid smil data?
                        case StringUtils.contains(videoUrl, SMIL_TYPE):
                            var smilParser:SMILParser = new SMILParser();
                            smilParser.addEventListener(SMILParserEvent.PARSE_COMPLETE, onSMILParsed);
                            smilParser.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
                            smilParser.retrieveSMIL(videoUrl);
                            _urlChanged = false;
                            break;
                        default:
                            throw new Error("VideoPlayer: Unknown HTTP VideoType");
                            break;

                    }
                    break;
                case RTMP_URL:
                    videoType = STREAMING;
                    _urlChanged = _urlChanged || (_url != videoUrl);
                    _url = videoUrl;
                    break;
                default:
                    throw new Error("VideoPlayer: Unknown VideoType");
                    break;

            }

            if (_urlChanged) {
                invalidateProperties();

            }
            // if the url did not change then we're trying to load the same video as the current one playing
            // and we're not parsing an smil data
            // unload the current video and reload it
            else if ((!_urlChanged) && (!StringUtils.contains(videoUrl, SMIL_TYPE))) {
                _urlChanged = true;
                _resourceChanged = false;
                invalidateProperties();

            }

        }

        /**
         * onError
         * Called when there was a communication error with the SMIL parser
         */
        public function onIOError(event:IOErrorEvent):void {
            dispatchEvent(event.clone());
        }

        /**
         * when we've received the proper rtmp url from the smil file set the player url.
         *
         */
        private function onSMILParsed(evt:SMILParserEvent):void {

            _urlChanged = _urlChanged || (_url != evt.rtmpUrl);

            _url = evt.rtmpUrl;

            determineUrlType(evt.rtmpUrl);

            videoType = STREAMING;

            if (_urlChanged) {

                invalidateProperties();
            }
            /// a new video has been selected but the videoUrl for the new video is the same
            else if (!_urlChanged) {
                _urlChanged = true;
                _resourceChanged = false;
                invalidateProperties();

            }

        }

        /** @private */
        public function get url():String {
            return _url;
        }

        /**
         * Pause the video player if not paused already.
         *
         */
        public function pause():void {
            if (mediaPlayer && mediaPlayer.canPause)
                mediaPlayer.pause();

        }

        /**
         * Play the current video if possible and not playing already.
         *
         */
        public function play():void {
            if (mediaPlayer && mediaPlayer.canPlay) {
                mediaPlayer.play();

            }
        }

        public function rewind(timeInterval:Number):void {

            if (mediaPlayer.duration > 0) {

                fastForwarding = false;

                currentPlayerTime = Math.round(mediaPlayer.currentTime);

                if (previousPlayerPosition != previousPlayerPosition) {
                    currentPlayerTime -= timeInterval;
                }
                else {
                    currentPlayerTime = (mediaPlayer.currentTime - timeInterval);
                }

                if (currentPlayerTime >= timeInterval) {

                    seek(currentPlayerTime);

                }
                else {
                    currentPlayerTime = 0;
                    seek(currentPlayerTime);
                }

                previousPlayerPosition = mediaPlayer.currentTime;

            }

        }

        /**
         * fastForward
         */
        public function fastForward(timeInterval:Number):void {

            previousPlayerTime = mediaPlayer.currentTime;

            fastForwarding = true;

            var percentLoaded:Number = ((mediaPlayer.bytesLoaded / mediaPlayer.bytesTotal) * 100);

            var percentAtPlayerPosition:Number = (((mediaPlayer.currentTime + timeInterval) / mediaPlayer.duration) * 100);

            if (mediaPlayer.duration > 0) {

                currentPlayerTime = Math.round(mediaPlayer.currentTime);

                switch (videoType) {
                    case PROGRESSIVE:

                        // if we have enough video loaded to seek to
                        if (percentAtPlayerPosition < percentLoaded) {
                            currentPlayerTime += timeInterval;
                            // increase until we get past the percent loaded, if we get past set it back to the player position
                            var percentOfCurrentTime:Number = ((currentPlayerTime / mediaPlayer.duration) * 100);

                            if (percentOfCurrentTime > percentLoaded) {
                                currentPlayerTime = mediaPlayer.currentTime;
                            }
                        }

                        else {
                            currentPlayerTime = mediaPlayer.currentTime;
                        }

                        break;
                    case STREAMING:
                        currentPlayerTime += timeInterval;
                        break;
                    default:
                        trace("Error VideoPlayer: FastForward not met");
                        break;
                }

                if (currentPlayerTime < mediaPlayer.duration) {
                    seek(currentPlayerTime);
                }
                else {
                    currentPlayerTime = (mediaPlayer.currentTime);
                    seek(currentPlayerTime);
                }

                previousPlayerPosition = mediaPlayer.currentTime;

            }

        }

        /**
         * Seek to a specified time in the current video if there is one,
         * and the media supports seeking.
         * @param time The time to seek to, in seconds.
         *
         */
        public function seek(time:Number):void {

            if (mediaPlayer && mediaPlayer.canSeek) {
                var seekTrait:SeekTrait = mediaElement ? mediaElement.getTrait(MediaTraitType.SEEK) as SeekTrait : null;

                if (mediaPlayer.canSeekTo(time))
                    mediaPlayer.seek(time);
            }
        }

        /**
         * Define which features the control bar of this video player should show.
         * You can combine the static constants prefixed with "FEATURES_" defined on this class to choose the features.
         * See the example for more information.
         * @param value A value indicating which features to include.
         * @example
         * <listing version="3.0">
         * player.features = VideoPlayer.FEATURES_PLAY_BUTTON | VideoPlayer.FEATURES_SCRUB_BAR | VideoPlayer.FEATURES_FULLSCREEN_BUTTON;
         * </listing>
         */
        public function set features(value:int):void {
            _featuresChanged = _featuresChanged || (_features != value);
            _features = value;

            if (_featuresChanged)
                invalidateProperties();
        }

        /** @private */
        public function get features():int {
            return _features;
        }

        /**
         * Get the duration of the current media. This value will generally not be populated until the video
         * has started playing.
         * @return The duration of the media in seconds.
         *
         */
        public function get duration():Number {
            return mediaPlayer ? mediaPlayer.duration : 0;
        }

        /**
         * Get the current playhead position in the loaded media.
         * @return The position of the playhead in seconds.
         *
         */
        public function get position():Number {
            return mediaPlayer ? mediaPlayer.currentTime : 0;
        }

        /**
         * Get whether the media is currently playing, or is stopped.
         * @return A boolean indicating whether the media is currently playing.
         *
         */
        public function get playing():Boolean {
            return mediaPlayer ? mediaPlayer.playing : false;
        }

        /**
         * Get the internal OSMF MediaPlayer instance, for advanced usage.
         * @return A MediaPlayer instance.
         */
        public function get internalMediaPlayer():MediaPlayer {

            return mediaPlayer;
        }

        /**
         * Get the internal OSMF MediaPlayer instance, for advanced usage.
         * @return A MediaPlayer instance.
         */
        public function get internailMediaElement():MediaElement {

            return mediaElement;
        }

        /**
         * Get the internal OSMF MediaContainer instance, for advanced usage.
         * @return A MediaContainer instance.
         */
        public function get internalMediaContainer():MediaContainer {
            return mediaContainer;
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {
            mediaFactory = new LitlMediaFactory();

            mediaPlayer = new MediaPlayer();

            mediaPlayer.autoPlay = _autoPlay;
            mediaPlayer.addEventListener(LoadEvent.LOAD_STATE_CHANGE, onVideoLoadState, false, 0, true);
            mediaPlayer.addEventListener(LoadEvent.BYTES_LOADED_CHANGE, onBytesLoadedChange, false, 0, true);
            mediaPlayer.addEventListener(TimeEvent.COMPLETE, onVideoComplete, false, 0, true);
            mediaPlayer.addEventListener(MediaErrorEvent.MEDIA_ERROR, onVideoError, false, 0, true);
            mediaPlayer.addEventListener(MediaErrorEvent.MEDIA_ERROR, onVideoError, false, 0, true);
            mediaPlayer.addEventListener(DisplayObjectEvent.MEDIA_SIZE_CHANGE, onVideoSizeChange);
            mediaPlayer.addEventListener(PlayEvent.PLAY_STATE_CHANGE, onPlayChange, false, 0, true);
            mediaPlayer.addEventListener(MediaPlayerStateChangeEvent.MEDIA_PLAYER_STATE_CHANGE, onStateChange);
            mediaPlayer.addEventListener(SeekEvent.SEEKING_CHANGE, onSeekChange);
            mediaPlayer.addEventListener(BufferEvent.BUFFERING_CHANGE, onBufferingChange);
            mediaPlayer.bufferTime = 5;

            layoutRenderer = new LayoutRenderer();
            mediaContainer = new MediaContainer(layoutRenderer);
            addChild(mediaContainer);
            //mediaContainer.doubleClickEnabled = true;
            mediaContainer.addEventListener(MouseEvent.CLICK, onMediaContainerClick);
            //mediaContainer.addEventListener(MouseEvent.DOUBLE_CLICK, onMediaContainerDoubleClick);

            controlBar = new VideoPlayerControlBar();
            controlBar.addEventListener(FullscreenEvent.FULLSCREEN, onFullscreen, false, 0, true);
            addChild(controlBar);

            controlBarMask = new Sprite();
            addChild(controlBarMask);

            controlBar.mask = controlBarMask;

        }

        private function onMetaData(info:Object):void {

            _metadataChanged = currentMetadata || (currentMetadata != info);

            /*
               tried grabbing all the 'seekpoints' from the metadata so we can accurately seek but this doesn't seem to be working
               for (var value:Object in info) {
               //trace(info[value]);
               //trace(value.toString());

               switch (value) {
               case "seekpoints":

               //trace(info[value]);

               for each (var seekpoint:Object in info[value]) {
               trace(seekpoint.toString());

               for each (var seekObject:Object in seekpoint) {
               trace(seekObject.toString());
               }
               }
               break;

               }
               }
             */

            if (_metadataChanged) {
                dispatchEvent(new MetaDataEvent(MetaDataEvent.ON_METADATA, info));
                currentMetadata = info;
            }

        }

        private function onSeekChange(evt:SeekEvent):void {
            // the seek was not met, meaning the we're trying to seek to wasn't a keyframe
            // in the video. so seek ahead to the next keyframe until we get a valid seek
            if (mediaPlayer.currentTime == previousPlayerTime) {
                if (videoType != STREAMING)
                    this.addEventListener(Event.ENTER_FRAME, enhancedSeek);
            }
            // the seek was sucessful
            else if (mediaPlayer.currentTime != previousPlayerTime) {
                this.removeEventListener(Event.ENTER_FRAME, enhancedSeek);
                amountToSeek = 0;
            }

            dispatchEvent(evt.clone());

        }

        private function onBufferingChange(evt:BufferEvent):void {

            dispatchEvent(evt.clone());

        }

        private function enhancedSeek(evt:Event):void {
            if (mediaPlayer.currentTime == previousPlayerTime) {
                if (fastForwarding) {
                    amountToSeek++;
                }
                else if (!fastForwarding) {
                    amountToSeek--;
                }
                seek(mediaPlayer.currentTime + amountToSeek);
            }
            else {
                this.removeEventListener(Event.ENTER_FRAME, enhancedSeek);
                amountToSeek = 0;
            }
        }

        /** toggle the play and pause state of the Media Container
         * @private */
        private function onMediaContainerClick(evt:MouseEvent):void {
            if (mediaPlayer.playing) {
                mediaPlayer.pause();
            }
            else if (mediaPlayer.paused) {
                mediaPlayer.play();
            }
        }

        /** @inheritDoc
         * @private */
        override protected function updateProperties():void {

            if (_featuresChanged) {
                _featuresChanged = false;

                if (controlBar)
                    controlBar.features = _features;
            }

            if (_autoPlayChanged) {
                _autoPlayChanged = false;

                if (mediaPlayer)
                    mediaPlayer.autoPlay = _autoPlay;

            }

            if (_urlChanged || _resourceChanged) {
                if (mediaElement) {
                    mediaContainer.removeMediaElement(mediaElement);

                }

                if (!_resourceChanged) {

                    switch (videoType) {
                        case STREAMING:
                            var streamingResource:StreamingURLResource = new StreamingURLResource(_url);
                            streamingResource.urlIncludesFMSApplicationInstance = true;
                            streamingResource.mediaType = MediaType.VIDEO;
                            currentResource = streamingResource;
                            break;
                        case PROGRESSIVE:
                            var progressiveResource:URLResource = new URLResource(_url);
                            progressiveResource.mediaType = MediaType.VIDEO;
                            currentResource = progressiveResource;
                            break;
                    }

                    mediaElement = mediaFactory.createMediaElement(currentResource);

                }
                else {
                    mediaElement = mediaFactory.createMediaElement(_resource);
                }

                if (mediaElement) {
                    var lmd:LayoutMetadata = new LayoutMetadata();

                    mediaElement.addMetadata(LayoutMetadata.LAYOUT_NAMESPACE, lmd);

                }
                mediaPlayer.media = mediaElement;
                controlBar.media = mediaElement;

                mediaContainer.addMediaElement(mediaElement);

                invalidateLayout();

                _urlChanged = false;
                _resourceChanged = false;
            }

        }

        /** @inheritDoc
         * @private */
        override protected function layout():void {

            var lmd:LayoutMetadata;

            if (mediaElement) {

                lmd = mediaElement.getMetadata(LayoutMetadata.LAYOUT_NAMESPACE) as LayoutMetadata;
                lmd.scaleMode = ScaleMode.LETTERBOX;
                lmd.percentWidth = 100;
                lmd.percentHeight = 100;
                lmd.verticalAlign = VerticalAlign.MIDDLE;
                lmd.horizontalAlign = HorizontalAlign.CENTER;

            }

            CONTROL_BAR_HIDDEN_Y = (_height + 5);
            CONTROL_BAR_SHOWN_Y = (_height - CONTROL_BAR_HEIGHT);

            controlBar.setSize(_width, CONTROL_BAR_HEIGHT);
            controlBar.move(0, (CONTROL_BAR_SHOWN_Y));

            mediaContainer.width = _width;
            mediaContainer.height = _height;

            controlBarMask.graphics.clear();
            controlBarMask.graphics.beginFill(0x000000, 1);
            controlBarMask.graphics.drawRect(controlBar.x, (_height - (CONTROL_BAR_HEIGHT * 2)), _width, CONTROL_BAR_HEIGHT * 2)
            controlBarMask.graphics.endFill();
            controlBarMask.alpha = .6;

            if (spinner) {
                spinner.x = (_width - spinner.width) / 2;
                spinner.y = (_height - spinner.height) / 2;
            }

        }

        /** Called when the current video has completed playback.
         * @private */
        protected function onVideoComplete(e:TimeEvent):void {
            dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.COMPLETE));
        }

        /** Called when the current video cannot play for some reason.
         * @private */
        protected function onVideoError(e:MediaErrorEvent):void {
            var ev:ErrorEvent = new ErrorEvent(ErrorEvent.ERROR, false, false, e.error.message);
            dispatchEvent(ev);
        }

        protected function onVideoLoadState(e:LoadEvent):void {
            if (e.loadState == LoadState.READY) {
                var videoElement:VideoElement = VideoElement(mediaElement);
                videoElement.client.addHandler(NetStreamCodes.ON_META_DATA, onMetaData);
                dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.READY));
                _isReady = true;
            }
            else if (e.loadState == LoadState.LOADING) {
                dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.LOADING));
                _isReady = false;
            }
            else if (e.loadState == LoadState.LOAD_ERROR) {
                dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Video load error"));
                _isReady = false;
            }

        }

        private function onPlayChange(evt:PlayEvent):void {
            dispatchEvent(evt.clone());
        }

        private function onStateChange(evt:MediaPlayerStateChangeEvent):void {
            dispatchEvent(evt.clone());
        }

        private function onVideoSizeChange(evt:DisplayObjectEvent):void {

            dispatchEvent(new VideoPlayerEvent(VideoPlayerEvent.SIZE_CHANGE));
            controlBar.refreshControls();

        }

        public function setLoading(b:Boolean):void {

            if (b) {
                if (spinner == null)
                    spinner = new LightSpinner();

                if (!contains(spinner))
                    addChildAt(spinner, numChildren);

                if (spinner.alpha == 1)
                    spinner.alpha = 0;
                Tween.tweenTo(spinner, 0.2, { alpha: 1 });

            }
            else {
                if (spinner) {

                    var tween:Tween = Tween.tweenTo(spinner, 0.2, { alpha: 0 });
                    tween.addEventListener(Event.COMPLETE, removeSpinner, false, 0, true);

                }
                else
                    return;
            }

            spinner.x = (_width - spinner.width) / 2;
            spinner.y = (_height - spinner.height) / 2;

        }

        private function removeSpinner(e:Event = null):void {
            if (spinner) {
                removeChild(spinner);

            }

            spinner = null;
        }

        private function onFullscreen(e:FullscreenEvent):void {
            dispatchEvent(e.clone());
        }

        private function onBytesLoadedChange(e:LoadEvent):void {
            dispatchEvent(e.clone());
        }

        /**
         * shows the video controls
         */
        public function showVideoControls():void {

            if (controlBar) {
                controlBar.visible = true;
                controlBarMask.visible = true;

                if (seeking) {
                    controlBar.showTimeBubble();
                }

                // if the control bar is currently tweening don't tween it again
                if (!Tween.getTweens(controlBar)) {
                    Tween.tweenTo(controlBar, 0.5, { alpha: 1, y: CONTROL_BAR_SHOWN_Y });
                    controlBar.refreshControls();
                }
            }
        }

        public function hideTimeBubble():void {
            controlBar.hideTimeBubble();
            seeking = false;
        }

        /**
         * hides the video controls
         */
        public function hideVideoControls():void {

            seeking = false;

            if (controlBar) {

                var tween:Tween = Tween.tweenTo(controlBar, 0.5, { alpha: 0, y: CONTROL_BAR_HIDDEN_Y });
                tween.addEventListener(Event.COMPLETE, hideControlBar);
            }
        }

        public function hideControlBar(evt:Event):void {
            controlBar.visible = false;
            controlBarMask.visible = false;
            controlBar.refreshControls();
        }

        public function closeConnection():void {

            if (mediaPlayer) {
                mediaPlayer.media = null;
                this._url = "";
            }

        }

    }
}

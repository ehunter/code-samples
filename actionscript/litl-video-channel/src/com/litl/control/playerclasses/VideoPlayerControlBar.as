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
package com.litl.control.playerclasses
{
    import com.litl.control.ControlBase;
    import com.litl.control.playerclasses.controls.IVideoPlayerControl;
    import com.litl.control.playerclasses.controls.LitlFullscreenButton;
    import com.litl.control.playerclasses.controls.LitlFullscreenLink;
    import com.litl.control.playerclasses.controls.LitlPauseButton;
    import com.litl.control.playerclasses.controls.LitlPausePlayButton;
    import com.litl.control.playerclasses.controls.LitlScrubBar;
    import com.litl.control.playerclasses.controls.LitlVolumeBar;
    import com.litl.event.VideoPlayerEvent;
    import com.litl.event.FullscreenEvent;
    import com.litl.sdk.service.LitlService;
    import com.litl.skin.LitlColors;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.SpreadMethod;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    import org.osmf.layout.LayoutMetadata;
    import org.osmf.media.MediaElement;

    /**
     * Dispatched when the fullscreen button is clicked.
     */
    [Event(name="fullscreen", type="com.litl.event.FullscreenEvent")]

    public class VideoPlayerControlBar extends ControlBase
    {
        public static const NONE:int = 0;
        public static const SCRUB_BAR:int = 1;
        public static const PAUSE_BUTTON:int = 2;
        public static const PLAY_BUTTON:int = 4;
        public static const SOUND_LESS:int = 8;
        public static const SOUND_MORE:int = 16;
        public static const VOLUME_BAR:int = 32;
        public static const FULLSCREEN_BUTTON:int = 64;
        public static const FULLSCREEN_LINK:int = 128;

        private static const BUTTONS_VERTICAL_OFFSET:Number = 0;
        private static const SCRUBBAR_VERTICAL_OFFSET:Number = 0;
        private static const BORDER_SPACE:Number = 0;
        private static const VOLUME_BAR_WIDTH:Number = 60;
        private static const VOLUME_BAR_HEIGHT:Number = 16;
        public static const PAUSE_PLAY_BUTTON_WIDTH:Number = 40;
        public static const PADDING:Number = 2;

        protected var widgets:Array;
        protected var _media:MediaElement;
        protected var _mediaChanged:Boolean = false;
        protected var _layoutMetadata:LayoutMetadata;
        protected var _features:int = SCRUB_BAR | PLAY_BUTTON | PAUSE_BUTTON;
        protected var _featuresChanged:Boolean = false;

        protected var scrubBar:IVideoPlayerControl;
        protected var pausePlayButton:IVideoPlayerControl;
        //protected var pauseButton:IVideoPlayerControl;
        protected var volumeBar:IVideoPlayerControl;
        protected var fullscreenButton:LitlFullscreenButton;
        protected var fullscreenLink:IVideoPlayerControl;
        protected var _fullScreen:Boolean = false;
        protected var init:Boolean = true;
        protected var controlBarBg:Sprite = null;

        public function VideoPlayerControlBar() {

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

            if (fullscreenButton)
                fullscreenButton.fullScreen = value;

        }

        public function get features():int {
            return _features;
        }

        public function set features(value:int):void {
            _featuresChanged = _featuresChanged || (_features != value);
            _features = value;

            if (_featuresChanged)
                invalidateProperties();
        }

        public function set media(mediaElement:MediaElement):void {
            _mediaChanged = _mediaChanged || (_media != mediaElement);
            _media = mediaElement;

            if (_mediaChanged)
                invalidateProperties();
        }

        public function get media():MediaElement {
            return _media;
        }

        private function addWidget(widget:Class, existing:IVideoPlayerControl = null):IVideoPlayerControl {
            var newWidget:IVideoPlayerControl;

            newWidget = existing ? existing : new widget() as IVideoPlayerControl;

            if (newWidget is DisplayObject)
                addChild(newWidget as DisplayObject);
            widgets.push(newWidget);

            newWidget.element = media;
            return newWidget;
        }

        private function removeWidget(widget:IVideoPlayerControl):void {
            if (widget is DisplayObject) {
                if (DisplayObject(widget).parent == this)
                    removeChild(widget as DisplayObject);

                var wi:int = widgets.indexOf(widget);

                if (wi >= 0)
                    widgets.splice(wi, 1);
            }
        }

        private function updateWidget(widget:IVideoPlayerControl):void {
            if (widget is DisplayObject) {
                if (DisplayObject(widget).parent == this)
                    removeChild(widget as DisplayObject);

                var wi:int = widgets.indexOf(widget);

                if (wi >= 0)
                    widgets.splice(wi, 1);
            }
        }

        override protected function createChildren():void {
            updateWidgets();
        }

        protected function updateWidgets():void {
            if (widgets != null)
                for each (var widget:IVideoPlayerControl in widgets)
                    removeWidget(widget);

            widgets = [];

            if (_features) {
                controlBarBg = new Sprite();
                addChildAt(controlBarBg, 0);

            }

            if (_features & PLAY_BUTTON)
                pausePlayButton = addWidget(LitlPausePlayButton, pausePlayButton);

            //if (_features & PAUSE_BUTTON)
            //pauseButton = addWidget(LitlPauseButton, pauseButton);

            if (_features & VOLUME_BAR)
                volumeBar = addWidget(LitlVolumeBar, volumeBar);

            if (_features & FULLSCREEN_BUTTON) {
                // fullscreenButton = addWidget(LitlFullscreenButton, fullscreenButton);
                if (!fullscreenButton) {
                    fullscreenButton = new LitlFullscreenButton();
                    addChild(fullscreenButton);
                }

                //if ("validateNow" in fullscreenButton)
                //fullscreenButton["validateNow"]();

                if (!fullscreenButton.hasEventListener(MouseEvent.CLICK)) {
                    fullscreenButton.addEventListener(MouseEvent.CLICK, onFullscreenClick, false, 0, true);
                }

            }

            if (_features & SCRUB_BAR) {
                scrubBar = addWidget(LitlScrubBar, scrubBar);

            }

            /*
               if (_features & FULLSCREEN_LINK) {
               fullscreenLink = addWidget(LitlFullscreenLink, fullscreenLink);

               if (!fullscreenLink.hasEventListener(MouseEvent.CLICK))
               fullscreenLink.addEventListener(MouseEvent.CLICK, onFullscreenClick, false, 0, true);
               }
             */
            invalidateLayout();
        }

        override protected function updateProperties():void {
            if (_featuresChanged) {
                _featuresChanged = false;
                updateWidgets();
            }

            if (_mediaChanged) {
                _mediaChanged = false;

                for (var i:int = 0; i < widgets.length; i++) {
                    widgets[i].element = media;

                }
                invalidateLayout();
            }

        }

        override protected function layout():void {
            /*
               var g:Graphics = graphics;
               g.clear();

               if (_width > 0 && _height > 0) {
               g.beginFill(LitlColors.W);
               g.drawRect(0, 0, _width, _height);
               g.endFill();
               }
             */

            var d:DisplayObject;
            var leftX:Number = BORDER_SPACE;
            var rightX:Number = _width - BORDER_SPACE;
            var yy:Number = BUTTONS_VERTICAL_OFFSET;

            if ((_features) && controlBarBg) {
                controlBarBg.graphics.clear();
                controlBarBg.graphics.beginFill(0x333333, 1);
                controlBarBg.graphics.drawRect(0, 0, _width, _height);
                controlBarBg.graphics.endFill();
            }

            if ((_features & PLAY_BUTTON) && pausePlayButton is DisplayObject) {
                d = pausePlayButton as DisplayObject;
                d.x = BORDER_SPACE;
                d.y = yy;
                d.width = PAUSE_PLAY_BUTTON_WIDTH;
                d.height = _height;

                leftX = Math.max(leftX, d.x + d.width + PADDING);
            }

            /*
               if ((_features & PAUSE_BUTTON) && pauseButton is DisplayObject) {
               d = pauseButton as DisplayObject;
               d.x = BORDER_SPACE;
               d.y = yy;
               leftX = Math.max(leftX, d.x + d.width);
               }
             */

            if ((_features & VOLUME_BAR) && volumeBar is DisplayObject) {
                d = volumeBar as DisplayObject;
                d.width = VOLUME_BAR_WIDTH;
                d.height = VOLUME_BAR_HEIGHT;
                d.x = rightX - d.width;
                d.y = yy + 4;
                rightX -= d.width + BORDER_SPACE;
            }

            if ((_features & FULLSCREEN_BUTTON) && fullscreenButton is LitlFullscreenButton) {
                // hack, on init fullscreenButton.width returns 0, wasn't sure how else to handle this?
                if (init) {
                    fullscreenButton.width = 26;
                    init = false;
                }

                fullscreenButton.x = rightX - fullscreenButton.width;

                fullscreenButton.y = yy;
                rightX -= fullscreenButton.width + BORDER_SPACE;
            }

            if ((_features & SCRUB_BAR) && scrubBar is DisplayObject) {
                d = scrubBar as DisplayObject;
                d.x = leftX;
                d.y = yy;
                d.width = rightX - leftX;
                d.height = _height;

            }

        }

        protected function onFullscreenClick(e:MouseEvent):void {

            if (!this._fullScreen) {
                this._fullScreen = true;
            }
            else {
                this._fullScreen = false;
            }

            dispatchEvent(new FullscreenEvent(FullscreenEvent.FULLSCREEN, this._fullScreen, false, false));

        }

        public function showTimeBubble():void {
            var s:LitlScrubBar;
            s = scrubBar as LitlScrubBar;
            s.seeking = true;
            s.showTimeBubble();
        }

        public function hideTimeBubble():void {
            var s:LitlScrubBar;
            s = scrubBar as LitlScrubBar;
            s.seeking = false;
            s.hideTimeBubble(null);
        }

        public function refreshControls():void {

            layout();

        }

        public function reset():void {
            var s:LitlScrubBar;
            s = scrubBar as LitlScrubBar;
            s.reset();
        }

    }
}

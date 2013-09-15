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
package com.litl.control.playerclasses.controls
{
    import com.litl.control.Label;
    import com.litl.control.VideoPlayer;
    import com.litl.control.playerclasses.controls.LitlBufferIndicator;
    import com.litl.control.playerclasses.controls.LitlTimeBubble;
    import com.litl.control.playerclasses.traits.YouTubeBufferTrait;
    import com.litl.event.VideoPlayerEvent;
    import com.litl.sdk.util.Tween;
    import com.litl.skin.LitlColors;

    import flash.display.BlendMode;
    import flash.display.DisplayObject;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.geom.ColorTransform;
    import flash.geom.Rectangle;
    import flash.utils.Timer;

    import org.osmf.elements.loaderClasses.LoaderLoadTrait;
    import org.osmf.events.BufferEvent;
    import org.osmf.events.LoadEvent;
    import org.osmf.events.MediaElementEvent;
    import org.osmf.events.SeekEvent;
    import org.osmf.events.TimeEvent;
    import org.osmf.media.LoadableElementBase;
    import org.osmf.media.MediaElement;
    import org.osmf.media.MediaPlayer;
    import org.osmf.traits.BufferTrait;
    import org.osmf.traits.LoadTrait;
    import org.osmf.traits.LoaderBase;
    import org.osmf.traits.MediaTraitType;
    import org.osmf.traits.SeekTrait;
    import org.osmf.traits.TimeTrait;

    public class LitlScrubBar extends VideoPlayerControlBase
    {
        protected var _seekTrait:SeekTrait;
        protected var _timeTrait:TimeTrait;
        protected var _bufferTrait:BufferTrait;
        protected var _loadTrait:LoadTrait;
        protected var timeBubble:LitlTimeBubble;

        private var timer:Timer;

        protected var loader:Loader;
        protected var track:DisplayObject;
        protected var buffer:DisplayObject;
        protected var bufferRollOverArea:Sprite;
        protected var bar:Sprite;
        protected var seekToAreaBar:Sprite;
        protected var durationBackground:DisplayObject;
        protected var timeLabel:Label;
        protected var durationLabel:Label;
        protected var duration:Number = 0;
        protected var currentTime:Number = 0;
        protected var bufferIndicator:LitlBufferIndicator;
        private var tween:Tween;
        public var seeking:Boolean = false;
        private var mouseOverBar:Boolean = false;
        private var colorTransformLightBlue:ColorTransform;
        private var colorTransformLitlBlue:ColorTransform;

        public function LitlScrubBar() {
            super();
        }

        /**
         * creates all display objects and adds them to the stage
         *
         */
        override protected function createChildren():void {

            colorTransformLightBlue = new ColorTransform();
            colorTransformLightBlue.color = 0x689699;

            colorTransformLitlBlue = new ColorTransform();
            colorTransformLitlBlue.color = LitlColors.BLUE;

            track = createSkinElement("trackSkin");

            if (track)
                addChild(track);

            bufferIndicator = new LitlBufferIndicator();

            if (bufferIndicator)
                addChild(bufferIndicator)

            buffer = createSkinElement("bufferBarSkin");

            if (buffer)
                addChild(buffer);

            seekToAreaBar = new Sprite();
            addChild(seekToAreaBar);
            seekToAreaBar.visible = false;

            bar = createSkinElement("barSkin") as Sprite;

            if (bar) {
                addChild(bar);
                bar.transform.colorTransform = colorTransformLitlBlue;
            }

            durationLabel = new Label();
            durationLabel.useFTE = false;
            durationLabel.setStyle("size", 18);
            addChild(durationLabel);
            durationLabel.blendMode = BlendMode.INVERT;

            timeBubble = new LitlTimeBubble();

            if (timeBubble) {
                addChild(timeBubble);
                timeBubble.visible = false;
                timeBubble.mouseEnabled = false;
                timeBubble.mouseChildren = false;
            }

            bufferRollOverArea = createSkinElement("bufferBarSkin") as Sprite;
            addChild(bufferRollOverArea);
            bufferRollOverArea.alpha = 0;
            bufferRollOverArea.addEventListener(MouseEvent.MOUSE_OVER, onBufferBarOver);

            mouseChildren = true;
            mouseEnabled = true;
            buttonMode = true;
            useHandCursor = true;

            this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);

            onTimerTick();
        }

        /**
         * mouseOver BufferBar
         *
         */
        private function onBufferBarOver(evt:MouseEvent):void {
            openTimeBubble();
            mouseOverBar = true;
        }

        /**
         * mouseOut BufferBar
         *
         */
        private function onBufferBarOut(evt:MouseEvent):void {
            closeTimeBubble();
            mouseOverBar = false;
        }

        /**
         * fades in the timeBubble and adds listeners
         *
         */
        private function openTimeBubble():void {
            timeBubble.centerPointer();
            timeBubble.visible = true;
            //var tween:Tween = Tween.tweenTo(timeBubble, 0.2, { alpha: 1 });
            bufferRollOverArea.removeEventListener(MouseEvent.MOUSE_OVER, onBufferBarOver);
            bufferRollOverArea.addEventListener(MouseEvent.MOUSE_OUT, onBufferBarOut);
            initBubbleDrag();
        }

        /**
         * fades out the timeBubble and returns the progress bar to it's original color
         *
         */
        private function closeTimeBubble():void {
            //var tween:Tween = Tween.tweenTo(timeBubble, 0.2, { alpha: 0 });
            //tween.addEventListener(Event.COMPLETE, hideTimeBubble, false, 0, true);
            timeBubble.visible = false;
            bufferRollOverArea.addEventListener(MouseEvent.MOUSE_OVER, onBufferBarOver);
            bufferRollOverArea.removeEventListener(MouseEvent.MOUSE_OUT, onBufferBarOut);
            stopBubbleDrag();
            seekToAreaBar.visible = false;

            var colorTransformLitlBlue:ColorTransform = bar.transform.colorTransform;
            colorTransformLitlBlue.color = LitlColors.BLUE;
            bar.transform.colorTransform = colorTransformLitlBlue;
        }

        /**
         * initBubbleDrag starts the time bubble following the mouse. adds listeners
         *
         */
        private function initBubbleDrag():void {

            timeBubble.x = this.mouseX;
            var rect2:Rectangle = new Rectangle(buffer.x, (_height / 2), _width, 0);
            timeBubble.startDrag(true, rect2);
            timeBubble.visible = true;

        }

        /**
         * stopBubbleDrag stops the time bubble from following the mouse
         * removes listeners
         *
         */
        private function stopBubbleDrag():void {
            timeBubble.stopDrag();
        }

        /**
         *
         */
        private function updateHoverState():void {
            var time:TimeTrait = element ? element.getTrait(MediaTraitType.TIME) as TimeTrait : null;

            if (time) {

                var p:Number = ((timeBubble.x - track.x) / track.width);
                var t:Number = (p * time.duration);

                if (!time.duration) {
                    timeBubble.updateTime(time.duration);
                }

                else if (!t) {
                    timeBubble.updateTime(0);
                }
                else {
                    timeBubble.updateTime(t);

                }

                var avail:Number = _width - (durationBackground ? durationBackground.width + 3 : 0);
                seekToAreaBar.width = Math.round(timeBubble.x);

                var indexOfSeekBar:int = this.getChildIndex(seekToAreaBar);
                var indexOfBar:int = this.getChildIndex(bar);

                if (seekToAreaBar.width <= bar.width) {

                    if (indexOfSeekBar < indexOfBar) {
                        this.swapChildren(seekToAreaBar, bar);
                    }

                    if (seekToAreaBar.transform.colorTransform != colorTransformLitlBlue) {
                        seekToAreaBar.transform.colorTransform = colorTransformLitlBlue;
                        bar.transform.colorTransform = colorTransformLightBlue;
                    }

                }
                else if (seekToAreaBar.width >= bar.width) {

                    if (indexOfSeekBar > indexOfBar) {

                        seekToAreaBar.transform.colorTransform = colorTransformLightBlue;
                        bar.transform.colorTransform = colorTransformLitlBlue;
                        this.swapChildren(seekToAreaBar, bar);
                    }

                }

                seekToAreaBar.visible = true;

            }
        }

        /**
         * 'seeks' the timeBubble to the current time of the player.
         * this function is only used in passive mode when there are no mouse events and the user fast forwards/rewinds
         *
         */
        private function seekTimeBubble():void {
            var time:TimeTrait = element ? element.getTrait(MediaTraitType.TIME) as TimeTrait : null;

            if (time) {
                var p:Number = ((timeBubble.x - track.x) / track.width);
                var t:Number = time.currentTime;

                if (!t) {
                    timeBubble.updateTime(0);
                }
                else {
                    timeBubble.updateTime(t);
                }
                updateTimeBubblePosition();
            }

        }

        /**
         * moves the time bubble and adjusts the point within the bubble if necessary
         *
         */
        private function updateTimeBubblePosition():void {

            var amountToMove:Number;

            // we've run out of room on the left side of the stage just move the pointer in the time bubble
            if ((bar.x + bar.width) <= (timeBubble.timeBubble.bubble.width / 2)) {
                amountToMove = ((timeBubble.timeBubble.bubble.width / 2) - (bar.x + bar.width));
                timeBubble.x = ((timeBubble.timeBubble.bubble.width / 2));
                timeBubble.movePointer(amountToMove);
            }
            // we've run out of room on the right side of the stage
            else if ((bar.x + bar.width) >= (_width - (timeBubble.timeBubble.bubble.width / 2))) {
                amountToMove = (_width - (bar.x + bar.width) - (timeBubble.timeBubble.bubble.width / 2));
                timeBubble.x = ((_width) - (timeBubble.timeBubble.bubble.width / 2));
                timeBubble.movePointer(amountToMove);
            }
            else {
                timeBubble.centerPointer();
                timeBubble.x = (bar.x + bar.width);
            }

        }

        /**
         * moves the time bubble and adjusts the point within the bubble if necessary
         * @param evt
         *
         */
        public function hideTimeBubble(evt:Event):void {
            timeBubble.visible = false;
        }

        private function onHideScrubBar():void {
            timer.stop();
        }

        override protected function updateProperties():void {

        }

        override protected function layout():void {
            if (track) {

                track.height = _height;
                track.width = _width;

            }

            if (bar) {
                bar.height = _height;
            }

            if (bufferIndicator) {
                bufferIndicator.angle = -1; // 1 : moves left to right. -1 : moves right to left.
                bufferIndicator.speed = 1.5;
                bufferIndicator.baseColor = 0x4D4D4D;
                bufferIndicator.bandColor = 0x333333;
                bufferIndicator.borderColor = 0xFF9999;
                bufferIndicator.borderThickness = 0; //thickness of border
                bufferIndicator.bandWidth = 4; //width of individual band
                bufferIndicator.setSize(_width, _height); //size
                bufferIndicator.showBorder(false);
            }

            if (timeLabel) {
                timeLabel.y = ((_height - timeLabel.height) / 2) - 1;
                timeLabel.x = 5;
            }

            if (timeBubble) {
                timeBubble.height = (_height);
                timeBubble.width = (_height * 2);
                timeBubble.y = ((_height) / 2);

            }

            if (durationLabel) {
                durationLabel.setStyle("size", Math.round(_height - 8));
                durationLabel.y = ((_height - durationLabel.height) / 2);
                durationLabel.x = _width - durationLabel.width - 6;
            }

            if (durationBackground) {
                durationBackground.width = durationLabel.width + 12;
                durationBackground.height = _height;
                durationBackground.x = _width - durationBackground.width;
            }

            if (buffer) {
                buffer.height = bufferRollOverArea.height = track.height;

            }

            if (seekToAreaBar) {
                seekToAreaBar.graphics.clear();
                seekToAreaBar.graphics.beginFill(0x689699, 1);
                seekToAreaBar.graphics.drawRect(0, 0, _width, _height);
                seekToAreaBar.graphics.endFill();
            }

            startTimer();
        }

        override public function set element(e:MediaElement):void {
            super.element = e;
            reset();
        }

        override protected function updateTraits(e:MediaElementEvent):void {
            var seekTrait:SeekTrait = element.getTrait(MediaTraitType.SEEK) as SeekTrait;

            if (_seekTrait != seekTrait) {
                if (_seekTrait) {
                    _seekTrait.removeEventListener(SeekEvent.SEEKING_CHANGE, updateState);
                    _seekTrait = null;
                }

                if (seekTrait) {
                    _seekTrait = seekTrait;
                    _seekTrait.addEventListener(SeekEvent.SEEKING_CHANGE, onSeekChange, false, 0, true);
                }
            }

            var timeTrait:TimeTrait = element.getTrait(MediaTraitType.TIME) as TimeTrait;

            if (_timeTrait != timeTrait) {
                if (_timeTrait) {
                    _timeTrait.removeEventListener(TimeEvent.DURATION_CHANGE, onDurationChange);
                    _timeTrait = null;
                    reset();
                }

                if (timeTrait) {
                    _timeTrait = timeTrait;
                    _timeTrait.addEventListener(TimeEvent.DURATION_CHANGE, onDurationChange, false, 0, true);
                }
            }

            var loadTrait:LoadTrait = element.getTrait(MediaTraitType.LOAD) as LoadTrait;

            if (_loadTrait != loadTrait) {
                if (_loadTrait) {
                    _loadTrait.removeEventListener(LoadEvent.BYTES_LOADED_CHANGE, updateLoadBar);
                    _loadTrait = null;
                }

                if (loadTrait) {
                    _loadTrait = loadTrait;
                    _loadTrait.addEventListener(LoadEvent.BYTES_LOADED_CHANGE, updateLoadBar, false, 0, true);
                    _loadTrait.addEventListener(LoadEvent.LOAD_STATE_CHANGE, onLoadStateChange, false, 0, true);
                }
            }

            var bufferTrait:BufferTrait = element.getTrait(MediaTraitType.BUFFER) as BufferTrait;

            if (_bufferTrait != bufferTrait) {
                if (_bufferTrait) {
                    _bufferTrait.removeEventListener(BufferEvent.BUFFERING_CHANGE, onBufferChange);
                    _bufferTrait = null;
                }

                if (bufferTrait) {
                    _bufferTrait = bufferTrait;
                    _bufferTrait.addEventListener(BufferEvent.BUFFERING_CHANGE, onBufferChange);
                }
            }

            super.updateTraits(e);
        }

        private function onLoadStateChange(evt:LoadEvent):void {
            switch (evt.loadState) {
                case "uninitialized":
                    showBufferIndicator();
                case "unloading":
                    showBufferIndicator();
                default:
                    //trace("onLoadStateChange: " + evt.loadState);
                    break;
            }
        }

        private function onBufferChange(evt:BufferEvent):void {

            if (evt.buffering) {
                showBufferIndicator();
            }
            else if (!evt.buffering) {
                hideBufferIndicator();
            }

        }

        private function showBufferIndicator():void {
            if (bufferIndicator) {

                bufferIndicator.animate();
            }
            else if (!bufferIndicator) {
                bufferIndicator = new LitlBufferIndicator();
                addChildAt(bufferIndicator, 2);

                layout();
                bufferIndicator.animate();
            }

        }

        public function showTimeBubble():void {
            updateTimeBubblePosition();
            timeBubble.visible = true;
            var tween:Tween = Tween.tweenTo(timeBubble, 0.2, { alpha: 1 });
        }

        private function hideBufferIndicator():void {
            if (bufferIndicator) {
                removeChild(bufferIndicator)
                bufferIndicator = null;
            }
        }

        private function updateLoadBar(evt:LoadEvent):void {

            var timeTrait:TimeTrait = element.getTrait(MediaTraitType.TIME) as TimeTrait;
            var loaded:LoadTrait = element ? element.getTrait(MediaTraitType.LOAD) as LoadTrait : null;

            if (buffer) {

                if ("validateNow" in buffer)
                    Object(buffer).validateNow();

            }
        }

        override protected function updateState(e:Event = null):void {
            visible = element != null;
            enabled = element ? element.hasTrait(MediaTraitType.SEEK) : false;

            var hasTimeTrait:Boolean = element ? element.hasTrait(MediaTraitType.TIME) : false;

            if (hasTimeTrait) {
                this.removeEventListener(Event.ENTER_FRAME, onTimerTick);
                this.addEventListener(Event.ENTER_FRAME, onTimerTick);
            }

            bar.visible = hasTimeTrait;
            buffer.visible = hasTimeTrait;

            if (!hasTimeTrait) {
                durationLabel.text = "--:--";
            }

        }

        private function onDurationChange(evt:TimeEvent):void {

        }

        private function onSeekChange(evt:SeekEvent):void {
            var time:TimeTrait = element ? element.getTrait(MediaTraitType.TIME) as TimeTrait : null;

        }

        public function reset():void {
            stopTimer();

            if (bar)
                bar.width = 0;

            if (buffer)
                buffer.width = bufferRollOverArea.width = 0;

        }

        protected function startTimer():void {
            this.removeEventListener(Event.ENTER_FRAME, onTimerTick);
            this.addEventListener(Event.ENTER_FRAME, onTimerTick);
        }

        protected function stopTimer():void {
            this.removeEventListener(Event.ENTER_FRAME, onTimerTick);
        }

        protected function onTimerTick(e:Event = null):void {

            var time:TimeTrait = element ? element.getTrait(MediaTraitType.TIME) as TimeTrait : null;
            var loaded:LoadTrait = element ? element.getTrait(MediaTraitType.LOAD) as LoadTrait : null;

            if (time != null) {
                duration = time.duration;
                currentTime = time.currentTime;
            }

            if (loaded != null) {

                var percentLoaded:Number = ((loaded.bytesLoaded / loaded.bytesTotal) * 100);

            }

            if (durationLabel) {

                durationLabel.text = formatTime(duration);
                durationLabel.y = (_height - durationLabel.height) / 2;
                durationLabel.x = _width - durationLabel.width - 6;
                durationLabel.validateNow();
            }

            if (durationBackground) {
                if (durationBackground.width != durationLabel.width + 12) {
                    durationBackground.width = durationLabel.width + 12;
                    durationBackground.height = _height;
                    durationBackground.x = _width - durationBackground.width;
                }
            }

            if (mouseOverBar) {
                updateHoverState();
            }

            if (bar) {
                var tw:Number = 0;

                var avail:Number = _width - (durationBackground ? durationBackground.width + 3 : 0);

                if ((currentTime) && (duration)) {
                    bar.width = Math.round((avail * (currentTime / duration)));
                }
                else {
                    bar.width = 0;
                }

                if ("validateNow" in bar)
                    Object(bar).validateNow();
            }

            if (timeLabel) {

                if (timeLabel.text != formatTime(currentTime)) {
                    timeLabel.text = formatTime(currentTime);
                    timeLabel.validateNow();
                }

                if (timeLabel.x != (bar.width - timeLabel.width - 6))
                    timeLabel.x = bar.width - timeLabel.width - 6;
            }

            if (buffer) {
                if (percentLoaded <= 99) {

                    buffer.width = bufferRollOverArea.width = ((percentLoaded * (_width)) / 100);

                }
                else if (buffer.width != (_width)) {
                    buffer.width = bufferRollOverArea.width = (_width);

                }

                if ("validateNow" in buffer)
                    Object(buffer).validateNow();

            }

            if (timeBubble) {
                // for fast forward rewind functionality in passive mode
                if (seeking) {
                    seekTimeBubble();
                }
            }

            if (parent) {
                if (parent.alpha == 0) {
                    this.removeEventListener(Event.ENTER_FRAME, onTimerTick);
                    //timeBubble.removeEventListener(Event.ENTER_FRAME, updateBubbleTime);
                    parent.visible = false;
                    this.seeking = false;
                }

                if (!parent.parent.visible) {
                    this.removeEventListener(Event.ENTER_FRAME, onTimerTick);
                    //timeBubble.removeEventListener(Event.ENTER_FRAME, updateBubbleTime);
                    this.seeking = false;
                }
            }

        }

        protected function onMouseDown(e:MouseEvent):void {
            stage.addEventListener(Event.REMOVED_FROM_STAGE, removeMouseListeners, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);

            onMouseMove();

        }

        protected function onMouseOver(e:MouseEvent):void {
            //trace("mouseOver")

        }

        protected function onMouseMove(e:MouseEvent = null):void {

            var seekTrait:SeekTrait = element ? element.getTrait(MediaTraitType.SEEK) as SeekTrait : null;

            if (seekTrait) {
                var timeTrait:TimeTrait = element.getTrait(MediaTraitType.TIME) as TimeTrait;

                if (timeTrait) {
                    var tw:Number = 0;
                    var dest:Number = ((mouseX) / (_width)) * timeTrait.duration;

                    if (seekTrait.canSeekTo(dest)) {
                        // don't scrub past the entire duration
                        if (dest < timeTrait.duration) {

                            seekTrait.seek(dest);
                        }
                    }

                }
            }

        }

        protected function onMouseUp(e:MouseEvent):void {
            //onMouseMove();
            removeMouseListeners();
        }

        protected function removeMouseListeners(e:Event = null):void {
            if (stage) {
                stage.removeEventListener(Event.REMOVED_FROM_STAGE, removeMouseListeners);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            }
        }

        protected function formatTime(seconds:Number):String {
            seconds = Math.round(isNaN(seconds) ? 0 : seconds);
            var hours:Number = Math.floor(seconds / 3600);
            return (hours > 0 ? hours + ":" : "")
                + (seconds % 3600 < 600 ? "0" : "") + Math.floor(seconds % 3600 / 60)
                + ":" + (seconds % 60 < 10 ? "0" : "") + seconds % 60;
        }
    }
}

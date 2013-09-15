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
    import flash.events.Event;
    import flash.events.MouseEvent;

    import org.osmf.events.MediaElementEvent;
    import com.litl.skin.LitlColors;
    import org.osmf.events.PlayEvent;
    import org.osmf.traits.MediaTraitType;
    import org.osmf.traits.PlayState;
    import org.osmf.traits.PlayTrait;
    import flash.geom.ColorTransform;

    public class LitlPausePlayButton extends VideoPlayerControlBase
    {
        //protected var button:SimpleButton;
        protected var _playTrait:PlayTrait;
        private var button:PausePlayButton;

        public function LitlPausePlayButton() {
            super();
        }

        override protected function createChildren():void {
            button = new PausePlayButton();
            addChild(button);
            button.mouseEnabled = true;
            button.mouseChildren = false;
            button.pauseIcon.visible = false;
            button.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
            button.addEventListener(MouseEvent.MOUSE_OVER, onOver, false, 0, true);
            layout();

        }

        protected function onOver(e:MouseEvent):void {

            var bgColorTransform:ColorTransform = new ColorTransform();
            bgColorTransform.color = LitlColors.BLUE;
            button.bg.transform.colorTransform = bgColorTransform;

            var iconTransform:ColorTransform = new ColorTransform();
            iconTransform.color = 0x333333;
            button.playIcon.transform.colorTransform = iconTransform;
            button.pauseIcon.transform.colorTransform = iconTransform;

            button.removeEventListener(MouseEvent.MOUSE_OVER, onOver);
            button.addEventListener(MouseEvent.MOUSE_OUT, onOut, false, 0, true);
        }

        protected function onOut(e:MouseEvent):void {

            var bgColorTransform:ColorTransform = new ColorTransform();
            bgColorTransform.color = 0x333333;
            button.bg.transform.colorTransform = bgColorTransform;

            var iconTransform:ColorTransform = new ColorTransform();
            iconTransform.color = LitlColors.WHITE;
            button.playIcon.transform.colorTransform = iconTransform;
            button.pauseIcon.transform.colorTransform = iconTransform;

            button.addEventListener(MouseEvent.MOUSE_OVER, onOver, false, 0, true);
            button.removeEventListener(MouseEvent.MOUSE_OUT, onOut);
        }

        protected function onClick(e:MouseEvent):void {
            if (_element) {
                var playTrait:PlayTrait = _element.getTrait(MediaTraitType.PLAY) as PlayTrait;

                if (playTrait && playTrait.playState != PlayState.PLAYING) {
                    playTrait.play();

                }
                else if (playTrait && playTrait.playState != PlayState.PAUSED) {
                    playTrait.pause();
                }

            }
        }

        override protected function updateTraits(e:MediaElementEvent):void {
            var playTrait:PlayTrait = element.getTrait(MediaTraitType.PLAY) as PlayTrait;

            if (_playTrait != playTrait) {
                if (_playTrait) {
                    _playTrait.removeEventListener(PlayEvent.CAN_PAUSE_CHANGE, updateState);
                    _playTrait.removeEventListener(PlayEvent.PLAY_STATE_CHANGE, updateState);
                    _playTrait = null;
                }

                if (playTrait) {
                    _playTrait = playTrait;
                    _playTrait.addEventListener(PlayEvent.CAN_PAUSE_CHANGE, updateState, false, 0, true);
                    _playTrait.addEventListener(PlayEvent.PLAY_STATE_CHANGE, updateState, false, 0, true);
                }
            }

            super.updateTraits(e);
        }

        override protected function updateState(e:Event = null):void {

            button.pauseIcon.visible = _playTrait && _playTrait.playState == PlayState.PLAYING;
            button.playIcon.visible = _playTrait && _playTrait.playState != PlayState.PLAYING;
        }

        override protected function layout():void {

            button.bg.width = _width;
            button.bg.height = _height;

            button.playIcon.x = Math.round((button.bg.width - button.playIcon.width) / 2);
            button.playIcon.y = Math.round((button.bg.height - button.playIcon.height) / 2);

            button.pauseIcon.x = Math.round((button.bg.width - button.pauseIcon.width) / 2);
            button.pauseIcon.y = Math.round((button.bg.height - button.pauseIcon.height) / 2);
        }
    }
}

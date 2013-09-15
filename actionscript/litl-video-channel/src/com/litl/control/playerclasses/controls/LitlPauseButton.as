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
    import flash.display.SimpleButton;
    import flash.events.Event;
    import flash.events.MouseEvent;

    import org.osmf.events.MediaElementEvent;
    import org.osmf.events.PlayEvent;
    import org.osmf.traits.MediaTraitType;
    import org.osmf.traits.PlayState;
    import org.osmf.traits.PlayTrait;

    public class LitlPauseButton extends VideoPlayerControlBase
    {
        protected var button:SimpleButton;
        protected var _playTrait:PlayTrait;

        public function LitlPauseButton() {
            super();
        }

        override protected function createChildren():void {
            var upSkin:Class = getSkinClass("upSkin");
            var overSkin:Class = getSkinClass("overSkin");
            var downSkin:Class = getSkinClass("downSkin");
            button = new SimpleButton(upSkin ? new upSkin() : null, overSkin ? new overSkin() : null, downSkin ? new downSkin() : null, upSkin ? new upSkin() : null);
            addChild(button);
            button.addEventListener(MouseEvent.CLICK, onClick, false, 0, true);
            layout();
        }

        protected function onClick(e:MouseEvent):void {
            if (_element) {
                var playTrait:PlayTrait = _element.getTrait(MediaTraitType.PLAY) as PlayTrait;

                if (playTrait && playTrait.playState != PlayState.PAUSED)
                    playTrait.pause();
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
            visible = _playTrait && _playTrait.playState == PlayState.PLAYING;
        }

        override protected function layout():void {
            _width = button.width;
            _height = button.height;
        }
    }
}

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
    import com.litl.skin.LitlColors;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;

    import org.osmf.events.AudioEvent;
    import org.osmf.events.MediaElementEvent;
    import org.osmf.traits.AudioTrait;
    import org.osmf.traits.MediaTraitType;

    public class LitlVolumeBar extends VideoPlayerControlBase
    {
        protected var background:Sprite;
        protected var bar:DisplayObject;
        protected var barMask:Sprite;
        protected var _audioTrait:AudioTrait;

        public function LitlVolumeBar() {
            super();
        }

        override protected function createChildren():void {
            background = new Sprite();
            addChild(background);

            var color:uint = myStyles.color == undefined ? 0xffd67e : myStyles.color;
            background.filters = [ new DropShadowFilter(4, 135, color, 0.5, 8, 8, 1, 2, true)];

            bar = createSkinElement("barSkin");

            if (bar)
                addChild(bar);

            barMask = new Sprite();
            addChild(barMask);

            if (bar)
                bar.mask = barMask;

            mouseChildren = false;
            mouseEnabled = true;

            addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
        }

        override protected function layout():void {
            var g:Graphics = graphics;

            g.clear();

            if (_width > 0 && _height > 0) {
                g.beginFill(0, 0);
                g.drawRect(0, 0, _width, _height);
            }
            g = barMask.graphics;
            g.clear();

            if (_width > 0 && _height > 0) {
                g.beginFill(0, 1);
                g.moveTo(0, _height);
                g.lineTo(_width, 0);
                g.lineTo(_width, _height);
                g.endFill();
            }

            g = background.graphics;
            g.clear();

            if (_width > 0 && _height > 0) {

                var backgroundColor:uint = myStyles.backgroundColor == undefined ? 0 : myStyles.backgroundColor;

                g.beginFill(backgroundColor, 1);
                g.moveTo(0, _height);
                g.lineTo(_width, 0);
                g.lineTo(_width, _height);
                g.endFill();
            }

            if (bar)
                bar.height = _height;

            var color:uint = myStyles.color == undefined ? 0xffd67e : myStyles.color;
            background.filters = [ new DropShadowFilter(4, 135, color, 0.5, 8, 8, 1, 2, true)];
        }

        override protected function updateTraits(e:MediaElementEvent):void {
            var audioTrait:AudioTrait = element.getTrait(MediaTraitType.AUDIO) as AudioTrait;

            if (_audioTrait != audioTrait) {
                if (_audioTrait) {
                    _audioTrait.removeEventListener(AudioEvent.VOLUME_CHANGE, updateState);
                    //_audioTrait.removeEventListener(AudioEvent.MUTED_CHANGE, updateState);
                    _audioTrait = null;
                }

                if (audioTrait) {
                    _audioTrait = audioTrait;
                    _audioTrait.addEventListener(AudioEvent.VOLUME_CHANGE, updateState, false, 0, true);
                        //_audioTrait.addEventListener(AudioEvent.MUTED_CHANGE, updateState, false, 0, true);
                }
            }

            super.updateTraits(e);
        }

        override protected function updateState(e:Event = null):void {
            visible = (_audioTrait != null);

            if (_audioTrait && bar) {
                bar.width = _width * _audioTrait.volume;
            }
        }

        protected function onMouseDown(e:MouseEvent):void {
            stage.addEventListener(Event.REMOVED_FROM_STAGE, removeMouseListeners, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);

            onMouseMove();
        }

        protected function onMouseMove(e:MouseEvent = null):void {
            if (_audioTrait) {
                _audioTrait.volume = mouseX / _width;
            }
        }

        protected function onMouseUp(e:MouseEvent):void {
            onMouseMove();
            removeMouseListeners();
        }

        protected function removeMouseListeners(e:Event = null):void {
            if (stage) {
                stage.removeEventListener(Event.REMOVED_FROM_STAGE, removeMouseListeners);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            }

        }
    }
}

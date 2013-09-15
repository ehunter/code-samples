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
    import com.litl.control.ControlBase;

    import flash.events.Event;

    import org.osmf.events.MediaElementEvent;
    import org.osmf.media.MediaElement;
    import org.osmf.media.MediaPlayer;

    public class VideoPlayerControlBase extends ControlBase implements IVideoPlayerControl
    {
        protected var _element:MediaElement;
        private var _player:MediaPlayer;
        private var _enabled:Boolean = true;

        public function get player():MediaPlayer {
            return _player;
        }

        public function set player(value:MediaPlayer):void {
            _player = value;
        }

        public function set enabled(b:Boolean):void {
            _enabled = b;
        }

        public function get enabled():Boolean {
            return _enabled;
        }

        public function VideoPlayerControlBase() {
            super();
        }

        public function set element(e:MediaElement):void {
            if (e != _element) {
                if (_element) {
                    _element.removeEventListener(MediaElementEvent.TRAIT_ADD, updateTraits);
                    _element.removeEventListener(MediaElementEvent.TRAIT_REMOVE, updateTraits);
                }

                _element = e;

                if (_element) {
                    _element.addEventListener(MediaElementEvent.TRAIT_ADD, updateTraits);
                    _element.addEventListener(MediaElementEvent.TRAIT_REMOVE, updateTraits);
                }

                updateTraits(null);
            }
        }

        public function get element():MediaElement {
            return _element;
        }

        protected function updateTraits(e:MediaElementEvent):void {
            updateState();
        }

        /**
         * Update this control's state depending on whether the element has certain traits.
         *
         */
        protected function updateState(e:Event = null):void {
            // Override me
        }
    }
}

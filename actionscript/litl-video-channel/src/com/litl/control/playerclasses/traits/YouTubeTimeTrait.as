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
package com.litl.control.playerclasses.traits
{
    import flash.display.Loader;
    import flash.events.Event;

    import org.osmf.traits.TimeTrait;

    public class YouTubeTimeTrait extends TimeTrait
    {
        private var loader:Loader;
        private var _duration:Number;

        public function YouTubeTimeTrait(loader:Loader, duration:Number = 0) {
            super();
            this.loader = loader;
            _duration = duration;
            setDuration(_duration);

            var player:Object = loader.content;

            if (player != null) {
                player.addEventListener("onStateChange", onStateChange, false, 0, true);
            }
        }

        protected function get playerValid():Boolean {
            return (loader.content && Object(loader.content).playVideo != null);
        }

        protected function onStateChange(e:Event):void {
            if (Object(e).data == 0) {
                signalComplete();
            }
        }

        override public function get currentTime():Number {
            var player:Object = loader.content;

            return playerValid ? player.getCurrentTime() : -1;
        }

        override public function get duration():Number {
            var player:Object = loader.content;
            var dur:Number = playerValid ? player.getDuration() : _duration;
            return dur == 0 ? _duration : dur;
        }

        override protected function signalComplete():void {
            super.signalComplete();
        }
    }
}
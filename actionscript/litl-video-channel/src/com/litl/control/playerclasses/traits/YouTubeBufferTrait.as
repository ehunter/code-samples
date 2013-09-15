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

    import org.osmf.traits.BufferTrait;
    import org.osmf.traits.TimeTrait;

    public class YouTubeBufferTrait extends BufferTrait
    {
        protected var loader:Loader;
        protected var timeTrait:TimeTrait;

        public function YouTubeBufferTrait(loader:Loader, timeTrait:TimeTrait) {
            super();
            this.loader = loader;
            this.timeTrait = timeTrait;
        }

        override public function get bufferTime():Number {
            var player:Object = loader.content;

            if (player) {
                return timeTrait.duration * ((player.getVideoBytesLoaded() + player.getVideoStartBytes()) / player.getVideoBytesTotal());
                    //trace(player.getVideoBytesLoaded() + " player.getVideoBytesLoaded() ")
            }

            return timeTrait.duration;
        }

        override public function get buffering():Boolean {
            var player:Object = loader.content;

            if (player) {
                return player.getPlayerState() == 3;
            }

            return false;
        }
    }
}

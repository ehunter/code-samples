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

    import org.osmf.traits.AudioTrait;

    public class YouTubeAudioTrait extends AudioTrait
    {
        private var loader:Loader;

        public function YouTubeAudioTrait(loader:Loader) {
            super();
            this.loader = loader;
        }

        protected function get playerValid():Boolean {
            return (loader.content && Object(loader.content).playVideo != null);
        }

        /** @inheritDoc */
        override public function get volume():Number {
            var player:Object = loader.content;

            if (playerValid) {
                return player.getVolume() / 100;
            }

            return 1;
        }

        /** @inheritDoc */
        override public function get muted():Boolean {
            var player:Object = loader.content;

            if (playerValid) {
                return player.isMuted();
            }

            return false;
        }

        /** @inheritDoc */
        override protected function volumeChangeStart(newVolume:Number):void {
            var player:Object = loader.content;

            if (playerValid) {
                player.setVolume(newVolume * 100);
            }
        }

        /** @inheritDoc */
        override protected function mutedChangeStart(newMuted:Boolean):void {
            var player:Object = loader.content;

            if (playerValid) {
                if (newMuted) {
                    player.mute();
                }
                else {
                    player.unMute();
                }
            }
        }
    }
}
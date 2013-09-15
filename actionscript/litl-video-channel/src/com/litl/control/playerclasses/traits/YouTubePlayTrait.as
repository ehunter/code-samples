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
    import com.litl.control.playerclasses.YouTubeResource;

    import flash.display.Loader;

    import org.osmf.traits.PlayState;
    import org.osmf.traits.PlayTrait;

    public class YouTubePlayTrait extends PlayTrait
    {
        private var loader:Loader;
        private var resource:YouTubeResource;

        public function YouTubePlayTrait(loader:Loader, resource:YouTubeResource) {
            super();
            this.loader = loader;
            this.resource = resource;
        }

        protected function get playerValid():Boolean {
            return (loader.content && Object(loader.content).playVideo != null);
        }

        override protected function playStateChangeStart(newPlayState:String):void {
            var player:Object = loader.content;

            if (playerValid) {
                if (newPlayState == PlayState.PLAYING) {
                    if (player.getPlayerState() >= 0 && player.getPlayerState() < 5)
                        player.playVideo();
                    else
                        player.loadVideoById(resource.id, 0, resource.suggestedQuality);
                }
                else if (newPlayState == PlayState.STOPPED) {
                    // Don't do anything.
                }
                else {
                    player.pauseVideo();
                }
            }
        }
    }
}
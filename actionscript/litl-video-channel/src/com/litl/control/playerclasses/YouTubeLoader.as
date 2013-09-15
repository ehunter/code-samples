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
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;

    import org.osmf.elements.loaderClasses.LoaderLoadTrait;
    import org.osmf.media.MediaResourceBase;
    import org.osmf.traits.LoadState;
    import org.osmf.traits.LoadTrait;
    import org.osmf.traits.LoaderBase;

    public class YouTubeLoader extends LoaderBase
    {
        private static const YOUTUBE_PLAYER_URL:String = "http://www.youtube.com/apiplayer?version=3";

        private var loader:Loader;
        private var loadTrait:LoadTrait;

        public function YouTubeLoader() {
            super();
        }

        override public function canHandleResource(resource:MediaResourceBase):Boolean {
            return (resource is YouTubeResource);
        }

        override protected function executeLoad(loadTrait:LoadTrait):void {
            this.loadTrait = loadTrait;
            updateLoadTrait(loadTrait, LoadState.LOADING);

            if (loader == null) {

                loader = new Loader();
                loader.contentLoaderInfo.addEventListener(Event.INIT, onLoaderInit, false, 0, true);
                loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderIOError, false, 0, true);

            }
            LoaderLoadTrait(loadTrait).loader = loader;
            var ctx:LoaderContext = new LoaderContext(false, new ApplicationDomain());
            loader.load(new URLRequest(YOUTUBE_PLAYER_URL), ctx);
        }

        protected function onLoaderInit(e:Event):void {
            loader.content.addEventListener("onReady", onPlayerReady, false, 0, true);
            loader.content.addEventListener("onStateChange", onPlayerCued, false, 0, true);
        }

        protected function onLoaderIOError(e:IOErrorEvent):void {
            //TODO: complete function
        }

        protected function onPlayerReady(e:Event):void {
            Object(loader.content).cueVideoById(YouTubeResource(loadTrait.resource).id, 0, YouTubeResource(loadTrait.resource).suggestedQuality);
        }

        protected function onPlayerCued(e:Event):void {
            var player:Object = loader.content;

            if (player) {
                var state:Number = player.getPlayerState();

                if (state == 5) // 5 is "video cued" in youtube player api
                {
                    updateLoadTrait(loadTrait, LoadState.READY);
                }
            }
        }

        override protected function executeUnload(loadTrait:LoadTrait):void {
            updateLoadTrait(loadTrait, LoadState.UNLOADING);

            //netLoadTrait.netStream.close();

            //netLoadTrait.connection.close();

            if (loader) {
                try {
                    loader.content.removeEventListener("onReady", onPlayerReady);
                    loader.content.removeEventListener("onStateChange", onPlayerCued);
                    Object(loader.content).destroy(); // Youtube player api
                    loader.unloadAndStop(true);
                    loader = null;
                }
                catch (err:Error) {
                }
            }

            updateLoadTrait(loadTrait, LoadState.UNINITIALIZED);
        }
    }
}
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
    import com.litl.control.playerclasses.traits.*;

    import flash.events.Event;

    import org.osmf.elements.loaderClasses.LoaderLoadTrait;
    import org.osmf.media.LoadableElementBase;
    import org.osmf.media.MediaResourceBase;
    import org.osmf.traits.LoadTrait;
    import org.osmf.traits.LoaderBase;
    import org.osmf.traits.MediaTraitBase;
    import org.osmf.traits.MediaTraitType;
    import org.osmf.traits.TimeTrait;

    public class YouTubeElement extends LoadableElementBase
    {
        public function YouTubeElement(resource:MediaResourceBase = null, loader:LoaderBase = null) {
            //super(resource, loader, [ YouTubeLoader ]);
            super(resource, loader);
        }

        override protected function createLoadTrait(resource:MediaResourceBase, loader:LoaderBase):LoadTrait {
            return new LoaderLoadTrait(loader, resource);
        }

        override protected function processReadyState():void {
            var loadTrait:LoaderLoadTrait = getTrait(MediaTraitType.LOAD) as LoaderLoadTrait;
            var res:YouTubeResource = resource as YouTubeResource;

            var playerSprite:YouTubeSpriteProxy = new YouTubeSpriteProxy();
            playerSprite.player = loadTrait.loader.content;

            var displayTrait:YouTubeDisplayObjectTrait = new YouTubeDisplayObjectTrait(playerSprite, 320, 180);
            addTrait(MediaTraitType.DISPLAY_OBJECT, displayTrait);

            var trait:MediaTraitBase;

            addTrait(MediaTraitType.AUDIO, new YouTubeAudioTrait(loadTrait.loader));

            //addTrait(MediaTraitType.BUFFER, trait || new NetStreamBufferTrait(stream));
            var timeTrait:TimeTrait = new YouTubeTimeTrait(loadTrait.loader);
            addTrait(MediaTraitType.TIME, timeTrait);
            addTrait(MediaTraitType.PLAY, new YouTubePlayTrait(loadTrait.loader, resource as YouTubeResource));
            addTrait(MediaTraitType.SEEK, new YouTubeSeekTrait(loadTrait.loader, timeTrait));
            addTrait(MediaTraitType.BUFFER, new YouTubeBufferTrait(loadTrait.loader, timeTrait));
            loadTrait.loader.content.addEventListener("onStateChange", onPlayerState, false, 0, true);

            //displayTrait.setSize(loadTrait.loader.content.width, loadTrait.loader.content.height);
        }

        protected function onPlayerState(e:Event):void {
            var loadTrait:LoaderLoadTrait = getTrait(MediaTraitType.LOAD) as LoaderLoadTrait;
            var playTrait:YouTubePlayTrait = getTrait(MediaTraitType.PLAY) as YouTubePlayTrait;
            var player:Object = loadTrait.loader.content;

            if (player) {
                var state:Number = player.getPlayerState();

                // Possible values are unstarted (-1), ended (0), playing (1), paused (2), buffering (3), video cued (5).
                switch (state) {
                    default:
                    case 0:
                    case -1:
                    case 5:
                        playTrait.stop();
                        break;
                    case 1:
                    case 3:
                        playTrait.play();
                        break;
                    case 2:
                        playTrait.pause();
                        break;
                }
            }

            //var displayTrait:YouTubeDisplayObjectTrait = getTrait(MediaTraitType.DISPLAY_OBJECT) as YouTubeDisplayObjectTrait;
            //displayTrait.setSize(displayTrait.mediaWidth, displayTrait.mediaHeight);
        }
    }
}
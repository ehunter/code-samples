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
    import flash.display.DisplayObject;

    import org.osmf.traits.DisplayObjectTrait;

    public class YouTubeDisplayObjectTrait extends DisplayObjectTrait
    {
        public function YouTubeDisplayObjectTrait(displayObject:DisplayObject, mediaWidth:Number = 0, mediaHeight:Number = 0) {
            super(displayObject, mediaWidth, mediaHeight);
        }

        override protected function mediaSizeChangeStart(newMediaWidth:Number, newMediaHeight:Number):void {
            //Object(displayObject).setSize(newMediaWidth, newMediaHeight);
            //trace(">>>>>>" + newMediaWidth + "x" + newMediaHeight);
        }

        public function setSize(w:Number, h:Number):void {
            setMediaSize(w, h);
        }

        override public function get mediaWidth():Number {
            return 320; //displayObject.width;
        }

        override public function get mediaHeight():Number {
            return 180; //displayObject.height;
        }

        override protected function mediaSizeChangeEnd(oldMediaWidth:Number, oldMediaHeight:Number):void {
            super.mediaSizeChangeEnd(oldMediaWidth, oldMediaHeight);
        }
    }
}
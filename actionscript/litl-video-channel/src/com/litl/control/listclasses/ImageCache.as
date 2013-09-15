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
package com.litl.control.listclasses
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.utils.Dictionary;

    /**
     * Utility class to cache display objects, used by the ScrollableList class.
     * @author litl
     *
     */
    public class ImageCache
    {
        protected var dictionary:Dictionary;
        protected var keys:Array;

        private var _imageLimit:int = 20;

        public function ImageCache() {
            initialize();
        }

        public function get imageLimit():int {
            return _imageLimit;
        }

        public function set imageLimit(value:int):void {
            _imageLimit = value;
            limitCache();
        }

        protected function initialize():void {
            dictionary = new Dictionary(false);
            keys = [];
        }

        public function hasImage(key:String):Boolean {
            return (dictionary[key] != undefined);
        }

        public function storeImage(key:String, clip:DisplayObject):void {

            var replace:Boolean = hasImage(key);

            if (clip is Bitmap) {
                dictionary[key] = Bitmap(clip).bitmapData;
            }
            else
                dictionary[key] = clip;

            if (!replace) {
                keys.push(key);
                limitCache();
            }
            else {
                keys.push(keys.splice(keys.indexOf(key), 1));
            }
        }

        private function limitCache():void {
            while (keys.length > imageLimit) {
                removeImage(keys.shift(), true);
            }
        }

        public function getImage(key:String):DisplayObject {
            if (key == null)
                return null;

            var image:* = dictionary[key];

            if (image is BitmapData) {
                return new Bitmap(BitmapData(image), "auto", true);

            }

            return dictionary[key] as DisplayObject;
        }

        public function removeImage(key:String, dispose:Boolean = false):void {
            //if (dispose && dictionary[key] != undefined && dictionary[key] is BitmapData)
            //   dictionary[key].dispose();
            delete dictionary[key];
        }

        public function clear():void {
            initialize();
        }
    }
}

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
package com.litl.skin.parts
{
    import com.litl.control.Label;

    import flash.events.MouseEvent;
    import flash.text.TextField;

    public class FullscreenButtonSkin extends RectangleSkin
    {
        public static const FULLSCREEN:String = "fullscreen";
        public static const EXIT_FULLSCREEN:String = "exit fullscreen";
        protected var label:Label;

        public function FullscreenButtonSkin() {
        }

        override protected function createChildren():void {
            super.createChildren();

            label = new Label();
            label.useFTE = false;
            label.setStyle("size", 15);
            label.setStyle("color", myStyles.color);
            label.text = getLabelText();
            addChild(label);

            invalidateLayout();
        }

        override protected function layout():void {
            _width = Math.max(label.width, 66);
            _height = 16;

            super.layout();

            label.x = (_width - label.width) / 2;
            label.y = (_height - label.height) / 2;
            trace(" layout called FULLSCREEN BUTTON")
        }

        override protected function updateProperties():void {
            trace(" updateProperties called FULLSCREEN BUTTON")
        }

        protected function getLabelText():String {
            return FULLSCREEN;
        }

    }
}

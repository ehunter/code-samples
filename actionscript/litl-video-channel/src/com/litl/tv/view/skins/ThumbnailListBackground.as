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
package com.litl.tv.view.skins
{
    import com.litl.control.ControlBase;
    import com.litl.skin.LitlColors;

    import flash.display.Graphics;

    public class ThumbnailListBackground extends ControlBase
    {
        protected var borderColor:uint = LitlColors.MEDIUM_DARK_GREY;
        protected var borderThickness:int = 2;
        protected var backgroundColor:uint = 0x333333;

        public function ThumbnailListBackground() {

        }

        override protected function createChildren():void {
            //borderColor = myStyles.borderColor;
            //borderThickness = myStyles.borderThickness;
            //backgroundColor = myStyles.backgroundColor;
        }

        override protected function layout():void {
            if (_width > 0 && _height > 0) {
                var g:Graphics = graphics;
                g.clear();

                g.beginFill(backgroundColor, 1);
                g.drawRect(0, 0, _width, _height);
                g.endFill();

                //g.lineStyle(1, 0x000000, 1, true);
                g.moveTo(0, 0);
                    // g.lineTo(_width, 0);
                    //g.beginFill(0x000000, 1);
                    //g.moveTo(_width / 2 - 11, 0);
                    //g.lineTo(_width / 2, 11);
                    //g.lineTo(_width / 2 + 11, 0);
                    // g.endFill();
            }

        }
    }
}

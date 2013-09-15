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
    import com.litl.control.ControlBase;
    import com.litl.skin.LitlColors;

    import flash.display.Graphics;

    public class RectangleSkin extends ControlBase
    {
        protected var borderColor:uint = LitlColors.GREY;
        protected var borderThickness:int = 1;
        protected var backgroundColor:uint = LitlColors.BLACK;
        protected var cornerRadius:int = 0;

        public function RectangleSkin() {

        }

        override protected function createChildren():void {
            borderColor = myStyles.borderColor == undefined ? borderColor : myStyles.borderColor;
            borderThickness = myStyles.borderThickness == undefined ? borderThickness : myStyles.borderThickness;
            backgroundColor = myStyles.backgroundColor == undefined ? backgroundColor : myStyles.backgroundColor;
            cornerRadius = myStyles.cornerRadius == undefined ? cornerRadius : ((myStyles.cornerRadius is String && myStyles.cornerRadius.toLowerCase() == "auto") ? -1 : myStyles.cornerRadius);
        }

        override protected function layout():void {
            var g:Graphics = graphics;
            g.clear();

            if (_width > 0 && _height > 0) {
                borderColor = myStyles.borderColor == undefined ? borderColor : myStyles.borderColor;
                borderThickness = myStyles.borderThickness == undefined ? borderThickness : myStyles.borderThickness;
                backgroundColor = myStyles.backgroundColor == undefined ? backgroundColor : myStyles.backgroundColor;
                cornerRadius = myStyles.cornerRadius == undefined ? cornerRadius : ((myStyles.cornerRadius is String && myStyles.cornerRadius.toLowerCase() == "auto") ? -1 : myStyles.cornerRadius);

                if (cornerRadius < 0) {
                    var v:Number = _width < _height ? _width : _height;
                    cornerRadius = Math.min(v / 2, Math.max(8, v * 4 / 15));
                }

                var pt:Number = myStyles.paddingTop == undefined ? 0 : myStyles.paddingTop;
                var pb:Number = myStyles.paddingBottom == undefined ? 0 : myStyles.paddingBottom;
                var pl:Number = myStyles.paddingLeft == undefined ? 0 : myStyles.paddingLeft;
                var pr:Number = myStyles.paddingRight == undefined ? 0 : myStyles.paddingRight;

                if (borderThickness > 0)
                    g.lineStyle(borderThickness, borderColor, 1, true);
                g.beginFill(backgroundColor, 1);

                if (cornerRadius > 0)
                    g.drawRoundRect(pl, pt, _width - pl - pr, _height - pt - pb, cornerRadius, cornerRadius);
                else
                    g.drawRect(pl, pt, _width - pl - pr, _height - pt - pb);
                g.endFill();
            }

        }
    }
}

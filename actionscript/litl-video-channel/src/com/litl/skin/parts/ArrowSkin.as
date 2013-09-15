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

    import flash.display.Graphics;

    public class ArrowSkin extends ControlBase
    {
        public function ArrowSkin() {
            super();
        }

        override protected function layout():void {
            var direction:String = myStyles.direction == undefined ? "right" : myStyles.direction.toLowerCase();
            var side:Number = myStyles.padding == undefined ? 4 : myStyles.padding;
            var color:uint = myStyles.color == undefined ? 0xffffff : myStyles.color;
            var arrowWidth:Number = (direction == "right" || direction == "left") ?
                Math.min((_width - side) * 2, (_height - side * 2)) :
                Math.min((_height - side) * 2, (_width - side * 2));
            var arrowHeight:Number = arrowWidth / 2;
            var g:Graphics = graphics;
            g.clear();

            g.beginFill(0, 0);
            g.drawRect(0, 0, _width, _height);
            g.endFill();
            g.beginFill(color, 1);

            if (_width > 0 && _height > 0) {
                switch (direction) {
                    default:
                    case "right":
                        g.moveTo((_width - arrowHeight) / 2, (_height - arrowWidth) / 2);
                        g.lineTo((_width + arrowHeight) / 2, _height / 2);
                        g.lineTo((_width - arrowHeight) / 2, (_height + arrowWidth) / 2);
                        break;

                    case "left":
                        g.moveTo((_width + arrowHeight) / 2, (_height - arrowWidth) / 2);
                        g.lineTo((_width - arrowHeight) / 2, _height / 2);
                        g.lineTo((_width + arrowHeight) / 2, (_height + arrowWidth) / 2);
                        break;

                    case "up":
                        g.moveTo((_width - arrowWidth) / 2, (_height + arrowHeight) / 2);
                        g.lineTo(_width / 2, (_height - arrowHeight) / 2);
                        g.lineTo((_width + arrowWidth) / 2, (_height + arrowHeight) / 2);
                        break;

                    case "down":
                        g.moveTo((_width - arrowWidth) / 2, (_height - arrowHeight) / 2);
                        g.lineTo(_width / 2, (_height + arrowHeight) / 2);
                        g.lineTo((_width + arrowWidth) / 2, (_height - arrowHeight) / 2);
                        break;
                }
            }

            g.endFill();
        }
    }
}
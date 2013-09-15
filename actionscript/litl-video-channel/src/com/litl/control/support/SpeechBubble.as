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
package com.litl.control.support
{
    import com.litl.control.ControlBase;
    import com.litl.skin.LitlColors;

    import flash.display.Graphics;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    /**
     * Utility class to draw a speech bubble.
     */
    public class SpeechBubble extends ControlBase
    {
        public static const POINT_TOP_LEFT:String = "topLeft";
        public static const POINT_TOP_MIDDLE:String = "topMiddle";
        public static const POINT_TOP_RIGHT:String = "topRight";
        public static const POINT_RIGHT_TOP:String = "rightTop";
        public static const POINT_RIGHT_MIDDLE:String = "rightMiddle";
        public static const POINT_RIGHT_BOTTOM:String = "rightBottom";
        public static const POINT_BOTTOM_LEFT:String = "bottomLeft";
        public static const POINT_BOTTOM_MIDDLE:String = "bottomMiddle";
        public static const POINT_BOTTOM_RIGHT:String = "bottomRight";
        public static const POINT_LEFT_TOP:String = "leftTop";
        public static const POINT_LEFT_MIDDLE:String = "leftMiddle";
        public static const POINT_LEFT_BOTTOM:String = "leftBottom";

        protected var borderColor:uint = LitlColors.WHITE;
        protected var borderThickness:int = 2;
        protected var backgroundColor:uint = 0xffd67e;
        protected var cornerRadius:int = 16;
        protected var pointSize:Number = 20;
        protected var _pointPosition:String = POINT_TOP_LEFT;
        protected var _pointOffset:Number = 0;

        public function get pointOffset():Number {
            return _pointOffset;
        }

        public function set pointOffset(value:Number):void {
            _pointOffset = value;
        }

        public function get pointPosition():String {
            return _pointPosition;
        }

        public function set pointPosition(value:String):void {
            _pointPosition = value;
        }

        override protected function layout():void {
            graphics.clear();

            if (_width > 0 && _height > 0) {
                borderColor = myStyles.borderColor == undefined ? borderColor : myStyles.borderColor;
                borderThickness = myStyles.borderThickness == undefined ? borderThickness : myStyles.borderThickness;
                backgroundColor = myStyles.backgroundColor == undefined ? backgroundColor : myStyles.backgroundColor;
                cornerRadius = myStyles.cornerRadius == undefined ? cornerRadius : myStyles.cornerRadius;
                graphics.lineStyle(borderThickness, borderColor, 1, false);
                graphics.beginFill(backgroundColor, 1);

                drawSpeechBubble(new Rectangle(0, 0, _width, _height), cornerRadius, calculatePoint());

                graphics.endFill();
            }
        }

        protected function calculatePoint():Point {
            var p:Point = new Point();
            var off:Number = _pointOffset;
            var size:Number = pointSize;
            var w:Number = _width;
            var h:Number = _height;

            switch (_pointPosition) {
                default:
                case POINT_TOP_LEFT:
                case POINT_TOP_MIDDLE:
                case POINT_TOP_RIGHT:
                    p.y = -size;
                    break;

                case POINT_BOTTOM_LEFT:
                case POINT_BOTTOM_MIDDLE:
                case POINT_BOTTOM_RIGHT:
                    p.y = h + size;
                    break;

                case POINT_LEFT_TOP:
                case POINT_RIGHT_TOP:
                    p.y = off;
                    break;

                case POINT_LEFT_BOTTOM:
                case POINT_RIGHT_BOTTOM:
                    p.y = h + off;
                    break;

                case POINT_LEFT_MIDDLE:
                case POINT_RIGHT_MIDDLE:
                    p.y = h / 2 + off;
                    break;
            }

            switch (_pointPosition) {
                default:
                case POINT_LEFT_TOP:
                case POINT_LEFT_MIDDLE:
                case POINT_LEFT_BOTTOM:
                    p.x = -size;
                    break;

                case POINT_RIGHT_TOP:
                case POINT_RIGHT_MIDDLE:
                case POINT_RIGHT_BOTTOM:
                    p.x = w + size;
                    break;

                case POINT_TOP_LEFT:
                case POINT_BOTTOM_LEFT:
                    p.x = off;
                    break;

                case POINT_TOP_RIGHT:
                case POINT_BOTTOM_RIGHT:
                    p.x = w + off;
                    break;

                case POINT_TOP_MIDDLE:
                case POINT_BOTTOM_MIDDLE:
                    p.x = w / 2 + off;
                    break;
            }
            return p;
        }

        /**
         * Draw a speech bubble with the drawing API
         * @param	target	The sprite in which to draw
         * @param	rect	A Rectangle instance defining the position and size of the bubble
         * @param	cornerRadius	The radius of the corners of the bubble (in px)
         * @param	point	A Point instance defining the position of the point of the speech bubble.
         */
        protected function drawSpeechBubble(rect:Rectangle, cornerRadius:Number, point:Point):void {
            var g:Graphics = graphics;
            var r:Number = cornerRadius;
            var M:Function = g.moveTo;
            var L:Function = g.lineTo;
            var C:Function = g.curveTo;

            var x:Number = rect.x;
            var y:Number = rect.y;
            var w:Number = rect.width;
            var h:Number = rect.height;
            var px:Number = point.x;
            var py:Number = point.y;
            var min_gap:Number = 20;
            var hgap:Number = Math.min(w - r - r, Math.max(min_gap, w / 5));
            var left:Number = Math.min(x + w - r - hgap, px - hgap / 2);
            var right:Number = Math.max(x + r + hgap, px + hgap / 2);
            var vgap:Number = Math.min(h - r - r, Math.max(min_gap, h / 5));
            var top:Number = Math.min(y + h - r - vgap, py - vgap / 2);
            var bottom:Number = Math.max(y + r + vgap, py + vgap / 2);

            //bottom right corner
            var a:Number = r - (r * 0.707106781186547);
            var s:Number = r - (r * 0.414213562373095);

            M(x + w, y + h - r);

            if (r > 0) {
                if (px >= x + w - r && py >= y + h - r) {
                    L(px, py);
                    L(x + w - r, y + h);
                }
                else {
                    C(x + w, y + h - s, x + w - a, y + h - a);
                    C(x + w - s, y + h, x + w - r, y + h);
                }
            }

            if (py > y + h && px > x + r && px < x + w - r) {
                // bottom edge
                L(right, y + h);
                L(px, py);
                L(left, y + h);
            }

            L(x + r, y + h);

            //bottom left corner
            if (r > 0) {
                if (px <= x + r && py >= y + h - r) {
                    L(px, py);
                    L(x, y + h - r);
                }
                else {
                    C(x + s, y + h, x + a, y + h - a);
                    C(x, y + h - s, x, y + h - r);
                }
            }

            if (px < x && py > y + r && py < y + h - r) {
                // left edge
                L(x, bottom);
                L(px, py);
                L(x, top);
            }

            L(x, y + r);

            //top left corner
            if (r > 0) {
                if (px <= x + r && py <= y + r) {
                    L(px, py);
                    L(x + r, y);
                }
                else {
                    C(x, y + s, x + a, y + a);
                    C(x + s, y, x + r, y);
                }
            }

            if (py < y && px > x + r && px < x + w - r) {
                //top edge
                L(left, y);
                L(px, py);
                L(right, y);
            }

            L(x + w - r, y);

            //top right corner
            if (r > 0) {
                if (px >= x + w - r && py <= y + r) {
                    L(px, py);
                    L(x + w, y + r);
                }
                else {
                    C(x + w - s, y, x + w - a, y + a);
                    C(x + w, y + s, x + w, y + r);
                }
            }

            if (px > x + w && py > y + r && py < y + h - r) {
                // right edge
                L(x + w, top);
                L(px, py);
                L(x + w, bottom);
            }

            L(x + w, y + h - r);

        }
    }
}

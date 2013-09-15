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
package com.litl.tv.utils
{
    import com.greensock.TweenLite;
    import com.greensock.easing.*;
	import com.greensock.plugins.TintPlugin;
	import com.greensock.plugins.TweenPlugin;
    import com.litl.control.ControlBase;
    import com.litl.sdk.util.Tween;
    import com.litl.skin.LitlColors;
    import com.litl.tv.event.ThumbnailListEvent;

    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.EventDispatcher;
    import flash.events.MouseEvent;

    public class ArrowListButton extends ControlBase
    {
        protected var borderColor:uint = LitlColors.MEDIUM_DARK_GREY;
        protected var borderThickness:int = 2;
        protected var backgroundColor:uint = LitlColors.BLACK;
        protected var buttonOverColor:uint = 0x9AD7DB;
        protected var arrowDisabledColor:uint = LitlColors.DISABLED_BLACK;
        protected var arrowOverColor:uint = LitlColors.DARK_GREY;
        private var disabled:Boolean = false;

        private var arrow:Arrow;
        public var arrowBg:Sprite = null;

        public function ArrowListButton() {

			TweenPlugin.activate([ TintPlugin ]);

        }

        override protected function createChildren():void {
            //borderColor = myStyles.borderColor;
            //borderThickness = myStyles.borderThickness;
            //backgroundColor = myStyles.backgroundColor;

            //if (_width > 0 && _height > 0) {
            arrowBg = new Sprite();
            //addChild(arrow)

            arrow = new Arrow();
            // addChild(arrow);

            // }

        }

        override protected function layout():void {

            arrowBg = new Sprite();
            this.addEventListener(MouseEvent.MOUSE_OVER, onRollOver);
            this.addEventListener(MouseEvent.MOUSE_OUT, onRollOut);
            this.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
            addChild(arrowBg);

            arrowBg.graphics.clear();
            // var g:Graphics = graphics;
            //g.clear();

            arrowBg.graphics.beginFill(backgroundColor, 1);
            arrowBg.graphics.drawRect(0, 0, 200, 200);
            arrowBg.graphics.endFill();

            addChild(arrow);

        }

        public function setBgSize(w:Number, h:Number):void {
            arrowBg.width = w;
            arrowBg.height = h;

            arrow.x = ((arrowBg.width - arrow.width) / 2);
            arrow.y = ((arrowBg.height - arrow.height) / 2);

        }

        public function get bgWidth():Number {
            return arrowBg.width;

        }

        private function onRollOver(evt:MouseEvent):void {
            TweenLite.to(arrowBg, .35, { tint: buttonOverColor });
            TweenLite.to(arrow, .35, { tint: arrowOverColor });
        }

        private function onRollOut(evt:MouseEvent):void {
            TweenLite.to(arrowBg, .35, { tint: null });
            TweenLite.to(arrow, .35, { tint: null });
        }

        private function onPress(evt:MouseEvent):void {
            // dispatchEvent(ThumbnailListEvent.ARROW_BUTTON_PRESSED);
            dispatchEvent(new ThumbnailListEvent(ThumbnailListEvent.ARROW_BUTTON_PRESSED));
        }

        public function disable():void {
            removeMouseEvents();
            if(arrow)
                TweenLite.to(arrow, .35, { tint: arrowDisabledColor });
            if(arrowBg)
                TweenLite.to(arrowBg, .35, { tint: null });
            disabled = true;
        }

        public function enable():void {
            addMouseEvents();
			if(arrow)
            	TweenLite.to(arrow, .35, { tint: null });
            disabled = false;
        }

        public function get buttonDisabled():Boolean {
            return disabled;
        }

        private function addMouseEvents():void {
            this.addEventListener(MouseEvent.MOUSE_OVER, onRollOver);
            this.addEventListener(MouseEvent.MOUSE_OUT, onRollOut);
            this.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
        }

        private function removeMouseEvents():void {
            this.removeEventListener(MouseEvent.MOUSE_OVER, onRollOver);
            this.removeEventListener(MouseEvent.MOUSE_OUT, onRollOut);
            this.removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
        }

    }
}

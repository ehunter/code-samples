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
package com.litl.control.playerclasses.controls
{

    import com.litl.sdk.util.Tween;
    import com.litl.skin.LitlColors;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.FullScreenEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.ColorTransform;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    import org.osmf.events.ContainerChangeEvent;
    import org.osmf.events.DisplayObjectEvent;
    import org.osmf.events.MediaElementEvent;

    public class LitlFullscreenButton extends VideoPlayerControlBase
    {
        private var fullscreenText:TextField;
        private var fullscreenButton:FullScreenButton;
        public var _fullScreen:Boolean;

        public function LitlFullscreenButton() {
            super();
        }

        override protected function createChildren():void {

            fullscreenButton = new FullScreenButton();
            addChild(fullscreenButton);

            fullscreenButton.addEventListener(MouseEvent.MOUSE_OVER, onOver);
            fullscreenButton.addEventListener(MouseEvent.MOUSE_OUT, onOut);

            fullscreenButton.mouseChildren = false;
            fullscreenButton.mouseEnabled = true;
            fullscreenButton.buttonMode = true;
            fullscreenButton.useHandCursor = true;

            _width = fullscreenButton.width;
            _height = fullscreenButton.height;

            invalidateLayout();
        }

        override protected function layout():void {

            if (fullscreenButton) {

                _width = fullscreenButton.width;
                _height = fullscreenButton.height;

                if (_fullScreen) {
                    fullscreenButton.topArrow.rotation = 180;
                    fullscreenButton.topArrow.x = 20;
                    fullscreenButton.topArrow.y = 12;
                    fullscreenButton.bottomArrow.rotation = 0;
                    fullscreenButton.bottomArrow.x = 6;
                    fullscreenButton.bottomArrow.y = 14;
                }
                else {
                    fullscreenButton.topArrow.rotation = 0;
                    fullscreenButton.topArrow.x = 15;
                    fullscreenButton.topArrow.y = 5;
                    fullscreenButton.bottomArrow.rotation = 180;
                    fullscreenButton.bottomArrow.x = 11;
                    fullscreenButton.bottomArrow.y = 21;
                }
            }
        }

        private function onOver(evt:MouseEvent):void {

            var bgColorTransform:ColorTransform = new ColorTransform();
            bgColorTransform.color = LitlColors.DARK_BLUE;
            fullscreenButton.bg.transform.colorTransform = bgColorTransform;

            var arrowColorTransform:ColorTransform = new ColorTransform();
            arrowColorTransform.color = LitlColors.BLACK;

            fullscreenButton.topArrow.transform.colorTransform = arrowColorTransform;
            fullscreenButton.bottomArrow.transform.colorTransform = arrowColorTransform;

            if (!_fullScreen) {

                Tween.tweenTo(fullscreenButton.topArrow, 0.25, { x: 18, y: 2 });
                Tween.tweenTo(fullscreenButton.bottomArrow, 0.25, { x: 8, y: 24 });
            }
            else {

                Tween.tweenTo(fullscreenButton.topArrow, 0.35, { x: 19, y: 13 });
                Tween.tweenTo(fullscreenButton.bottomArrow, 0.35, { x: 7, y: 13 });

            }
        }

        private function onOut(evt:MouseEvent):void {

            var bgColorTransform:ColorTransform = new ColorTransform();

            bgColorTransform.color = 0x333333;
            fullscreenButton.bg.transform.colorTransform = bgColorTransform;

            var arrowColorTransform:ColorTransform = new ColorTransform();
            arrowColorTransform.color = LitlColors.WHITE;

            fullscreenButton.topArrow.transform.colorTransform = arrowColorTransform;
            fullscreenButton.bottomArrow.transform.colorTransform = arrowColorTransform;

            if (!_fullScreen) {
                Tween.tweenTo(fullscreenButton.topArrow, 0.3, { x: 14, y: 6 });
                Tween.tweenTo(fullscreenButton.bottomArrow, 0.3, { x: 12, y: 20 });

            }
            else {
                Tween.tweenTo(fullscreenButton.topArrow, 0.35, { x: 21, y: 11 });
                Tween.tweenTo(fullscreenButton.bottomArrow, 0.35, { x: 5, y: 15 });
            }
        }

        public function get fullScreen():Boolean {
            return _fullScreen
        }

        public function set fullScreen(value:Boolean):void {
            _fullScreen = value;
            layout();

        }

        override protected function updateTraits(e:MediaElementEvent):void {

            super.updateTraits(e);
            layout();
        }

        override protected function updateState(e:Event = null):void {

            layout();
        }

    }
}

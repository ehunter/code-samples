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
package com.litl.control
{
    import com.litl.control.support.SpeechBubble;

    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Rectangle;

    /**
     * <p>Component for an options bubble that automatically resizes to its children.</p>
     * <p>The dialog has a point that extends about 20 pixels outside of its border.</p>
     * <p>You can specify which side the point appears with the "pointPosition" style and the
     * following constants: (topLeft, topMiddle, topRight, rightTop, rightMiddle,
     * rightBottom, bottomLeft, bottomMiddle, bottomRight, leftTop, leftMiddle, leftBottom).</p>
     * @author litl
     * @example
     * <listing version="3.0">
     * var options:OptionsDialog = new OptionsDialog();
     * options.alwaysOnTop = true;
     * options.setStyle("pointPosition", "topRight");
     *
     * stage.addChild(options); // Add the options to the stage to make sure it is always on top.
     *
     * // Add your components. You will also need to size and position these yourself.
     * options.addChild(myLabel);
     * options.addChild(myButton);
     *
     * // .. layout components here.
     *
     * // Tell the dialog to resize in order to get the correct width below.
     * options.refresh();
     *
     * options.move(stage.stageWidth - options.width - 10, 40);
     * </listing>
     */
    public class OptionsDialog extends ControlBase
    {
        private static const PADDING:Number = 20;

        protected var bubble:SpeechBubble;
        protected var content:Sprite;
        protected var _alwaysOnTop:Boolean = false;
        protected var _alwaysOnTopChanged:Boolean = false;

        /** Constructor. */
        public function OptionsDialog() {
            content = new Sprite();

            super();

            super.addChild(content);
        }

        /**
         * Get/Set whether this options dialog should position itself above all the children
         * in the same DisplayObjectContainer.
         * @param b A boolean indicating whether the options dialog should attempt to stay on top.
         *
         */
        public function set alwaysOnTop(b:Boolean):void {
            _alwaysOnTopChanged = _alwaysOnTopChanged || (_alwaysOnTop != b);
            _alwaysOnTop = b;

            if (_alwaysOnTopChanged)
                invalidateProperties();
        }

        /** @private */
        public function get alwaysOnTop():Boolean {
            return _alwaysOnTop;
        }

        /**
         * Measure and redraw the options bubble now.
         */
        public function refresh():void {
            invalidateLayout();
            validateNow();
        }

        /** @inheritDoc */
        override public function addChild(child:DisplayObject):DisplayObject {
            var c:DisplayObject = content.addChild(child);
            invalidateLayout();
            return c;
        }

        /** @inheritDoc */
        override public function removeChild(child:DisplayObject):DisplayObject {
            var c:DisplayObject = content.removeChild(child);
            invalidateLayout();
            return c;
        }

        /** @inheritDoc */
        override public function addChildAt(child:DisplayObject, index:int):DisplayObject {
            var c:DisplayObject = content.addChildAt(child, index);
            invalidateLayout();
            return c;
        }

        /** @inheritDoc */
        override public function removeChildAt(index:int):DisplayObject {
            var c:DisplayObject = content.removeChildAt(index);
            invalidateLayout();
            return c;
        }

        /** @inheritDoc */
        override public function get numChildren():int {
            return content.numChildren;
        }

        /** @inheritDoc */
        override public function getChildAt(index:int):DisplayObject {
            return content.getChildAt(index);
        }

        /** @inheritDoc */
        override public function getChildByName(name:String):DisplayObject {
            return content.getChildByName(name);
        }

        /** @inheritDoc */
        override public function setChildIndex(child:DisplayObject, index:int):void {
            content.setChildIndex(child, index);
        }

        /** @inheritDoc */
        override protected function createChildren():void {
            bubble = new SpeechBubble();
            bubble.pointPosition = SpeechBubble.POINT_TOP_RIGHT;
            bubble.pointOffset = 0;
            super.addChild(bubble);

            super.setChildIndex(content, super.numChildren - 1);
        }

        /** @inheritDoc */
        override protected function updateProperties():void {
            if (_alwaysOnTopChanged) {
                _alwaysOnTopChanged = false;

                if (_alwaysOnTop) {
                    if (parent) {
                        parent.addEventListener(Event.ADDED, positionOnTop, false, 0, true);
                        onAdded(null);
                    }
                    else {
                        addEventListener(Event.ADDED, onAdded);
                    }
                }
                else {
                    if (parent) {
                        parent.removeEventListener(Event.ADDED, positionOnTop);
                    }
                }
            }
        }

        /** @inheritDoc */
        override protected function layout():void {
            bubble.setStyle("borderColor", getStyle("borderColor"));
            bubble.setStyle("borderThickness", getStyle("borderThickness"));
            bubble.setStyle("backgroundColor", getStyle("backgroundColor"));
            bubble.setStyle("cornerRadius", getStyle("cornerRadius"));

            if (myStyles.pointPosition != undefined)
                bubble.pointPosition = myStyles.pointPosition;

            var r:Rectangle = content.getBounds(content);
            r.left -= myStyles.paddingLeft == undefined ? PADDING : myStyles.paddingLeft;
            r.right += myStyles.paddingRight == undefined ? PADDING : myStyles.paddingRight;
            r.top -= myStyles.paddingTop == undefined ? PADDING : myStyles.paddingTop;
            r.bottom += myStyles.paddingBottom == undefined ? PADDING : myStyles.paddingBottom;
            bubble.move(r.x, r.y);
            bubble.setSize(r.width, r.height);
            _width = r.width;
            _height = r.height;
        }

        /** @private */
        protected function positionOnTop(e:Event):void {
            if (parent && e.target.parent == parent) {
                parent.setChildIndex(this, parent.numChildren - 1);
            }
        }

        /** @private */
        protected function onAdded(e:Event):void {
            addEventListener(Event.REMOVED, onRemoved);
        }

        /** @private */
        protected function onRemoved(e:Event):void {
            if (e.target == this) {
                if (parent) {
                    parent.removeEventListener(Event.ADDED, positionOnTop);
                }

                removeEventListener(Event.REMOVED, onRemoved);
            }
        }
    }
}

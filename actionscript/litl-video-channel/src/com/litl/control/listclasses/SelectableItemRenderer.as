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

    import com.litl.control.ControlBase;
    import com.litl.skin.LitlColors;

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    /**
     * Clickable list item renderer that displays a simple label using the data property's toString() method.
     * @author litl
     *
     */
    public class SelectableItemRenderer extends ControlBase implements IItemRenderer
    {
        protected var _data:Object;
        protected var textField:TextField;
        protected var _selected:Boolean = false;
        protected var _highlighted:Boolean = false;

        protected var background:Sprite;

        override protected function createChildren():void {
            mouseChildren = false;

            background = new Sprite();
            addChild(background);

            textField = new TextField();
            var tfm:TextFormat = new TextFormat("CorpoS", 14, 0xffffff, false);
            tfm.align = TextFormatAlign.LEFT;
            textField.defaultTextFormat = tfm;
            textField.wordWrap = true;
            //textField.embedFonts = true;
            textField.multiline = true;
            textField.selectable = false;
            textField.antiAliasType = "advanced";
            textField.gridFitType = "pixel";
            textField.autoSize = TextFieldAutoSize.CENTER;
            addChild(textField);

            addEventListener(MouseEvent.ROLL_OVER, onRollOver);
            addEventListener(MouseEvent.ROLL_OUT, onRollOut);
            addEventListener(MouseEvent.CLICK, onClick);
        }

        override protected function updateProperties():void {
            if (textField != null)
                textField.text = _data == null ? "" : _data.toString();
        }

        override protected function layout():void {

            if (_width > 0 && _height > 0) {
                graphics.clear();

                var backgroundColor:uint = myStyles.backgroundColor == undefined ? 0 : myStyles.backgroundColor;
                var selectedColor:uint = myStyles.selectedColor == undefined ? 0 : myStyles.selectedColor;
                var highlightedColor:uint = myStyles.highlightedColor == undefined ? 0 : myStyles.highlightedColor;
                graphics.beginFill(_highlighted ? highlightedColor : (_selected ? selectedColor : backgroundColor), 1);
                graphics.drawRect(0, 0, _width, _height);
                graphics.endFill();
            }

            var fontColor:uint = myStyles.color == undefined ? 0xffffff : myStyles.color;
            var tfm:TextFormat = textField.defaultTextFormat;
            tfm.color = fontColor;
            textField.defaultTextFormat = tfm;
            textField.width = _width - 10;
            textField.y = Math.floor((_height - textField.height) / 2);
            textField.x = 8;
        }

        public function get isReady():Boolean {
            return true;
        }

        public function set data(c:Object):void {
            _data = c;

            invalidateProperties();
        }

        public function get data():Object {
            return _data;
        }

        public function set selected(b:Boolean):void {
            var last:Boolean = _selected;
            _selected = b;

            invalidateLayout();
        }

        public function get selected():Boolean {
            return _selected;
        }

        override public function destroy():void {

            super.destroy();
        }

        protected function onClick(e:MouseEvent):void {
            dispatchEvent(new Event(Event.SELECT));
        }

        public function set enabled(b:Boolean):void {
            alpha = b ? 1 : 0.75;

            mouseEnabled = b;
        }

        protected function onRollOver(e:MouseEvent):void {
            _highlighted = true;
            layout();
        }

        protected function onRollOut(e:MouseEvent):void {
            _highlighted = false;
            layout();
        }
    }
}

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

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    /**
     * List item renderer that displays a simple label using the data property's toString() method.
     * @author litl
     *
     */
    public class TextItemRenderer extends ControlBase implements IItemRenderer
    {
        protected var _data:Object;
        protected var textField:TextField;
        protected var _selected:Boolean = false;

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
        }

        override protected function updateProperties():void {
            if (textField != null)
                textField.text = _data == null ? "" : _data.toString();
        }

        override protected function layout():void {

            if (_width > 0 && _height > 0) {
                graphics.clear();
                graphics.beginFill(0x0, 1);
                graphics.lineStyle(_selected ? 3 : 1, 0xffffff, 1, true);
                graphics.drawRect(0, 0, _width, _height);
                graphics.endFill();
            }

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
            //if (last != b)
            //background.sourceClass = b ? bg_selected_img : bg_img;
            invalidateLayout();
        }

        public function get selected():Boolean {
            return _selected;
        }

        override public function destroy():void {

            super.destroy();
        }

        protected function _onRelease():void {
            dispatchEvent(new Event(Event.SELECT));
        }

        public function set enabled(b:Boolean):void {
            alpha = b ? 1 : 0.75;

            mouseEnabled = b;
        }

    }
}
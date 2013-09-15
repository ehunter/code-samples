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
    import flash.events.Event;
    import flash.text.AntiAliasType;
    import flash.text.GridFitType;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.engine.*;

    /**
     * Very basic label component that uses StyleManager styles to look up the font, size, color, etc.
     *
     * @author litl
     * @example
     * <listing version="3.0">
     *
     * package
     * {
     *     import com.litl.control.Label;
     *     import flash.events.Event;
     *     import flash.display.Sprite;
     *
     *     public class LabelTest extends Sprite {
     *
     *     private var label:Label;
     *
     *         public function LabelTest() {
     *                  label = new Label();
     *                  label.styleName = ".standardText";
     *                  label.text = "Test text";
     *                  label.setSize(200,20);
     *                  label.move(10,10);
     *                  addChild(label);
     *     }
     *     }
     * }
     * </listing>
     */
    public class Label extends ControlBase
    {
        private var fontDescription:FontDescription;
        private var textFormat:TextFormat = new TextFormat("CorpoS", 18, 0xffffff);
        private var textBlock:TextBlock;
        private var textLines:Array;

        private var textField:TextField;

        private var _text:String;
        private var textChanged:Boolean = false;
        private var layoutChanged:Boolean = false;
        private var _multiline:Boolean = false;
        private var _useFTE:Boolean = true;
        private var _embedFonts:Boolean = false;
        private var _autoSize:String = TextFieldAutoSize.LEFT;

        private var oldWidth:Number;
        private var oldHeight:Number;

        /** Constructor */
        public function Label() {
            super();
        }

        /**
         * Get/Set whether to autosize the text field.
         * Use the constants in the flash.text.TextFieldAutoSize class to determine
         * the autosize behavior. If the useFTE setting is true, the Label component
         * only supports LEFT or NONE.
         * @param str   The autoSize setting to use.
         *
         */
        public function set autoSize(str:String):void {
            _autoSize = str;
            invalidateProperties();
        }

        /** @private */
        public function get autoSize():String {
            return _autoSize;
        }

        /**
         * Get/Set whether to use the Flash Text Engine to render fonts.
         * FTE fonts are better quality but likely slower.
         * @param value A boolean indicating whether to use the FTE.
         * @default true
         */
        public function set useFTE(value:Boolean):void {
            var last:Boolean = _useFTE;
            _useFTE = value;
            textChanged = textChanged || (last != _useFTE);
            invalidateProperties();
        }

        /** @private */
        public function get useFTE():Boolean {
            return _useFTE;
        }

        /**
         * Get/Set whether this label is multiline.
         * @param value A boolean indicating whether this label is multiline.
         *
         */
        public function set multiline(value:Boolean):void {
            var last:Boolean = _multiline;
            _multiline = value;
            textChanged = textChanged || (last != _multiline);
            invalidateProperties();
        }

        /** @private */
        public function get multiline():Boolean {
            return _multiline;
        }

        /**
         * Set the current text for this label.
         * @param value A string representing the new text.
         *
         */
        public function set text(value:String):void {
            var last:String = _text;
            _text = value;

            textChanged = textChanged || (last != _text);
            invalidateProperties();
        }

        /** @private */
        public function get text():String {
            return _text;
        }

        /**
         * Specify whether to use embedded fonts when rendering text.
         * @param value A boolean indicating whether to use embedded fonts.
         *
         */
        public function set embedFonts(value:Boolean):void {
            _embedFonts = value;
            invalidateProperties();
        }

        /** @private */
        public function get embedFonts():Boolean {
            return _embedFonts;
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {
            textField = new TextField();
            textField.embedFonts = true;
            textField.selectable = false;
            textField.defaultTextFormat = textFormat;
            textField.autoSize = TextFieldAutoSize.LEFT;
            textField.antiAliasType = AntiAliasType.ADVANCED;
            textField.gridFitType = GridFitType.PIXEL;
            textField.sharpness = 200;

            mouseChildren = false;
            mouseEnabled = false;
        }

        /** @inheritDoc
         * @private */
        override protected function updateProperties():void {
            //if (textChanged) {
            textChanged = false;

            var font:String = myStyles.fontName || myStyles.fontFamily || "CorpoS";
            var weight:String = myStyles.fontWeight || "normal";
            var style:String = myStyles.fontStyle || "normal";
            var size:Number = myStyles.size || 18;
            var color:uint = myStyles.color == undefined ? 0xffffff : (myStyles.color);
            var embed:Boolean = myStyles.embedFonts == undefined ? _embedFonts : (myStyles.embedFonts is String ? myStyles.embedFonts.toLowerCase().indexOf("true") >= 0 : myStyles.embedFonts);

            if (_useFTE) {
                if (contains(textField))
                    removeChild(textField);
                textBlock = new TextBlock();

                fontDescription = new FontDescription(font, weight, style, embed ? FontLookup.EMBEDDED_CFF : FontLookup.DEVICE, RenderingMode.CFF, CFFHinting.HORIZONTAL_STEM);
                var element:TextElement = new TextElement(_text, new ElementFormat(fontDescription, size, color));
                textBlock.content = element;
                textBlock.applyNonLinearFontScaling = true;
            }
            else {
                if (!contains(textField))
                    addChild(textField);

                var fmt:TextFormat = new TextFormat(font, size, color, (weight == "bold"), (style == "italic"));
                textField.defaultTextFormat = fmt;
                textField.setTextFormat(textField.defaultTextFormat);
                textField.embedFonts = embed;
                textField.multiline = _multiline;
                textField.wordWrap = _multiline;
                textField.autoSize = _autoSize;

                if (_text && _text.indexOf("<") >= 0 && _text.indexOf(">") > 0)
                    textField.htmlText = _text;
                else
                    textField.text = _text ? _text : "";
            }
            layoutChanged = true;
            invalidateLayout();
            //}
        }

        /** @inheritDoc
         * @private */
        override protected function layout():void {

            if (textLines != null)
                for each (var line:TextLine in textLines)
                    removeChild(line);

            textLines = new Array();

            if (_useFTE) {
                createLines();
            }
            else {
                var a:String = textField.autoSize;

                if (a == null || a == TextFieldAutoSize.NONE || a == TextFieldAutoSize.CENTER) {
                    textField.width = _width;

                    if (_multiline)
                        _height = textField.height;
                    else
                        textField.height = _height;
                }
                else // autoSize is left or right
                {
                    _width = textField.width;
                    _height = textField.height;
                }
                textField.x = 0;
                textField.y = 0;
            }

            if (layoutChanged && (oldWidth != width || oldHeight != height))
                dispatchEvent(new Event(Event.RESIZE, true, true));
            layoutChanged = false;
            oldWidth = width;
            oldHeight = height;
        }

        private function createLines():void {
            if (textBlock == null)
                return;

            var maxHeight:Number = (height > 0 && !_autoSize) ? height : Number.MAX_VALUE;
            var lineWidth:Number = (width > 0 && !_autoSize) ? width : 1000000;
            var xPos:Number = 0;
            var yPos:Number = 0;

            var textLine:TextLine = textBlock.createTextLine(null, lineWidth);

            while (textLine != null) {
                yPos += textLine.height + 2;
                textLine.x = xPos;
                textLine.y = yPos;

                addChild(textLine);
                _width = Math.max(_width, textLine.width);
                _height = Math.max(_height, yPos + textLine.descent);
                textLines.push(textLine);
                textLine = yPos < height && _multiline ? textBlock.createTextLine(textLine, lineWidth) : null;
            }
        }

    }
}

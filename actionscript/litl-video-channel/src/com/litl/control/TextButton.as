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
    import com.litl.control.support.StylableButton;

    import flash.events.Event;

    /**
     * Dispatched when the button is selected.
     */
    [Event(name="select", type="flash.events.Event")]

    /**
     * <p>Class for a skinnable button with a label.</p>
     * <p>The implementation checks the styles: { <i>upSkin overSkin downSkin disabledSkin</i> } to create the various skin backgrounds.
     * It also checks the following styles: <i>.textButtonUpLabel .textButtonDownLabel .textButtonOverLabel .textButtonDisabledLabel</i>,
     * for the label styles.</p>
     * @author litl
     * @example
     * <listing version="3.0">
     *
     * package
     * {
     *     import com.litl.control.TextButton;
     *     import flash.events.Event;
     *     import flash.display.Sprite;
     *
     *     public class TextButtonTest extends Sprite {
     *
     *     private var textButton:TextButton;
     *
     *         public function TextButtonTest() {
     *                  textButton = new TextButton();
     *                  addChild(textButton);
     *                  textButton.text = "Hello!";
     *                  textButton.setSize(200, 100);
     *                  textButton.move(50, 50);
     *                  textButton.addEventListener(Event.SELECT, onButtonSelect, false, 0, true);
     *     }
     *
     *              private function onButtonSelect(e:Event):void {
     *                  trace("Button selected: "+e.target);
     *              }
     *     }
     * }
     * </listing>
     */
    public class TextButton extends StylableButton
    {
        /**
         * Constant for the up phase of this button.
         */
        public static const UP:String = "up";
        /**
         * Constant for the down phase of this button.
         */
        public static const DOWN:String = "down";
        /**
         * Constant for the over phase of this button.
         */
        public static const OVER:String = "over";
        /**
         * Constant for the disabled phase of this button.
         */
        public static const DISABLED:String = "disabled";

        /** The Label instance used to display text. */
        protected var label:Label;

        protected var _text:String;

        /** Constructor. */
        public function TextButton() {
            super();
        }

        /**
         * Get/Set the current label for this button.
         * @param value A string to use as the label.
         *
         */
        public function set text(value:String):void {
            _text = value;
            invalidateProperties();
        }

        /** @private */
        public function get text():String {
            return _text;
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {

            super.createChildren();

            label = new Label();
            addChild(label);

            if (_phase == null)
                setPhase(UP);

        }

        /** @inheritDoc
         * @private */
        override protected function updateProperties():void {
            super.updateProperties();

            if (label) {
                label.styleName = styleName ? styleName : ".textButton" + _phase.charAt(0).toUpperCase() + _phase.substr(1) + "Label";
                label.text = _text;
                label.validateNow();
            }

            invalidateLayout();
        }

        /** @inheritDoc
         * @private */
        override protected function layout():void {

            super.layout();

            if (label)
                label.move((_width - label.width) / 2, (_height - label.height) / 2);

        }

    }
}

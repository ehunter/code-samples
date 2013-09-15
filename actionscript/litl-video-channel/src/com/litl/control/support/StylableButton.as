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

    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.utils.Dictionary;

    /**
     * Dispatched when the button is selected.
     */
    [Event(name="select", type="flash.events.Event")]

    /**
     * <p>Base class for a clickable button with StyleManager managed styles.</p>
     * <p>You normally wouldn't instantiate this class directly, but create a subclass
     * and define skins in CSS.</p>
     * <p>The style properties used to create skins are "upSkin", "downSkin", "overSkin" and "disabledSkin", for each button state respectively.</p>
     * @author litl
     * @see com.litl.control.TextButton
     */
    public class StylableButton extends ControlBase
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

        /**
         * A dictionary containing the display objects created for each phase.
         */
        protected var backgrounds:Dictionary;

        /**
         * The display object used for the current phase.
         */
        protected var background:DisplayObject;

        protected var _phase:String;
        protected var _phaseChanged:Boolean = false;

        protected var _enabled:Boolean = true;

        /** Constructor. */
        public function StylableButton() {
            super();
        }

        /**
         * Get/Set whether this button is currently enabled and clickable.
         * @param value A boolean indicating whether this button is enabled.
         *
         */
        public function set enabled(value:Boolean):void {
            _enabled = value;
            mouseEnabled = value;
            setPhase(value ? UP : DISABLED);
        }

        /** @private */
        public function get enabled():Boolean {
            return _enabled;
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {
            backgrounds = new Dictionary();

            buttonMode = true;
            useHandCursor = true;
            mouseChildren = false;

            addEventListener(MouseEvent.MOUSE_DOWN, onPress, false, 1);
            addEventListener(MouseEvent.ROLL_OUT, onRollOut, false, 1);
            addEventListener(MouseEvent.ROLL_OVER, onRollOver, false, 1);
            addEventListener(MouseEvent.MOUSE_UP, onRelease, false, 1);
            addEventListener(MouseEvent.CLICK, onClick, false, 1);

            if (_phase == null)
                setPhase(UP);

        }

        override protected function updateProperties():void {
            if (_phaseChanged) {
                _phaseChanged = false;

                if (background && contains(background)) {
                    removeChild(background);
                }

                if (backgrounds == null)
                    return;

                var newBackground:DisplayObject;

                if (backgrounds[_phase] == undefined) {
                    var clip:DisplayObject = createSkinElement(_phase + "Skin");

                    if (clip)
                        newBackground = backgrounds[_phase] = clip;

                }
                else
                    newBackground = backgrounds[_phase] as DisplayObject;

                if (newBackground != null) {
                    addChildAt(newBackground, 0);
                    background = newBackground;
                }

                layout();

                if (background && "validateNow" in background)
                    background["validateNow"]();
            }
        }

        /** @inheritDoc
         * @private */
        override protected function layout():void {
            if (background) {
                background.width = _width;
                background.height = _height;
            }
        }

        /**
         * Set the current phase of this button, either "up", "down", "over", or "disabled".
         * @param phase The current phase to display.
         *
         */
        public function setPhase(phase:String):void {
            _phaseChanged = _phaseChanged || (phase != _phase);
            _phase = phase;

            if (_phaseChanged) {
                invalidateProperties();
            }
        }

        private function onPress(e:MouseEvent):void {
            setPhase(DOWN);
        }

        private function onRollOver(e:MouseEvent):void {
            setPhase(OVER);
        }

        private function onRollOut(e:MouseEvent):void {
            setPhase(UP);
        }

        private function onRelease(e:MouseEvent):void {
            setPhase(OVER);
        }

        private function onClick(e:MouseEvent = null):void {
            dispatchEvent(new Event(Event.SELECT));
        }
    }
}

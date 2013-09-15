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
    import com.litl.control.support.StylableButton;

    import flash.display.DisplayObject;

    /**
     * Simple button with directional arrow.
     * @author litl
     *
     */
    public class ArrowButton extends StylableButton
    {
        private var _direction:String = "up";

        /** Constructor. */
        public function ArrowButton() {
            super();
        }

        /**
         * Get/Set the direction of this button.
         * The direction string directly corresponds to the skin property that is instantiated from the styles.
         * For example, setting the direction to "up", will change the current skin to "upSkin".
         */
        public function set direction(dir:String):void {
            _direction = dir;
        }

        /** @private */
        public function get direction():String {
            return _direction;
        }

        /** @inheritDoc */
        override public function setPhase(phase:String):void {
            if (background && contains(background)) {
                removeChild(background);
            }

            if (backgrounds == null)
                return;

            var newBackground:DisplayObject;

            if (backgrounds[phase] == undefined) {
                var clip:DisplayObject = createSkinElement(phase + "Skin");

                if (clip)
                    newBackground = backgrounds[phase] = clip;

            }
            else
                newBackground = backgrounds[phase] as DisplayObject;

            if (newBackground != null) {
                addChildAt(newBackground, 0);
                background = newBackground;
            }

            if (background && "setStyle" in background)
                Object(background).setStyle("direction", _direction);

            layout();

            if (background && "validateNow" in background)
                background["validateNow"]();
        }
    }
}

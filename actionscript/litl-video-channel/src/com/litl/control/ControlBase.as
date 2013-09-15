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
    import com.litl.skin.Style;
    import com.litl.skin.StyleManager;

    import flash.display.DisplayObject;
    import flash.display.SimpleButton;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;

    /**
     * <p>ControlBase is a base class for controls provided with the litl SDK.
     * It has utility methods for invalidation/validation of properties and layout.
     * It also has an internal representation of size (width, height, setSize).
     * It also contains a protected styles property (myStyles) for styles to be inserted
     * by the StyleManager singleton.</p>
     * <p>You would generally extend this class, and override createChildren, updateProperties, and layout.</p>
     *
     * @author litl
     *
     */
    public class ControlBase extends Sprite
    {
        include "../../../../Version.as";

        private var children:Array;

        /** Internal representation of the width of this control. */
        protected var _width:Number;
        /** Internal representation of the height of this control. */
        protected var _height:Number;
        /** <p>A Style instance containing style properties for this control.</p>
         * <p>These styles are normally set before initialization by StyleManager. The StyleManager
         * checks its loaded CSS for rules that match the class name first.. ie. "TextButton",
         * and then adds any rules that match the styleName property. ie. ".myTextButton"</p>
         */
        protected var myStyles:Style;

        private var singleStyles:Style;

        private var _styleName:String;
        private var _invalidated:Boolean = false;
        private var _initialized:Boolean = false;
        private var _layoutInvalidated:Boolean = false;
        private var _propertiesInvalidated:Boolean = false;

        /**
         * Constructor.
         */
        public function ControlBase() {
            super();
            children = [];
            singleStyles = new Style();
            invalidate();

            preInitialize();
        }

        /** @inheritDoc */
        override public function addChild(child:DisplayObject):DisplayObject {
            children.push(child);
            return super.addChild(child);
        }

        /** @inheritDoc */
        override public function removeChild(child:DisplayObject):DisplayObject {
            children.splice(children.indexOf(child), 1);
            return super.removeChild(child);
        }

        /** Used to initialize this component if used within the Flash authoring environment.
         * Sets the width and height, and removes any component avatar we have.
         */
        private function preInitialize():void {
            // Flash related stuff:
            var r:Number = rotation;
            rotation = 0;
            var w:Number = super.width;
            var h:Number = super.height;
            super.scaleX = super.scaleY = 1;
            setSize(w, h);
            move(super.x, super.y);
            rotation = r;

            // Remove the component avatar.
            if (numChildren > 0) {
                removeChildAt(0);
            }

            resetStyles();

        }

        private function initialize():void {
            _initialized = true;

            addEventListener(Event.RESIZE, onResize, false, 0, true);

            createChildren();
        }

        /**
         * Get our style properties from the StyleManager singleton.
         */
        private function resetStyles():void {
            var className:String = getQualifiedClassName(this).split("::")[1];
            myStyles = StyleManager.getInstance().getStyle(className);

            if (styleName != null && styleName.length > 0)
                myStyles.combineStyle(styleName);

            for (var key:String in singleStyles)
                myStyles[key] = singleStyles[key];
        }

        /**
         * Override this method to create any children of this control.
         * This method will be called once during component initialization,
         * usually on the following frame.
         */
        protected function createChildren():void {

        }

        /**
         * Override this method to commit any changes made by setting properties
         * on this control. This allows you to change multiple properties before
         * the component is redrawn. You can trigger this method on the next validation by
         * calling invalidateProperties()
         * @see #invalidateProperties
         */
        protected function updateProperties():void {

        }

        /**
         * Override this method to lay out the children of this control.
         * You can trigger this method on the next validation by calling invalidateLayout()
         * @see #invalidateLayout
         */
        protected function layout():void {

        }

        /**
         * Call this method when ready to remove this control.
         * This will remove any hooks into other components.
         * Subclasses may override this method to provide additional functionality.
         *
         */
        public function destroy():void {
            if (stage) {
                stage.removeEventListener(Event.RENDER, validate, false);
                stage.removeEventListener(Event.ENTER_FRAME, validate, false);
            }
        }

        /**
         * Move this component to a new position in its parent container.
         * @param x     The x-position to move to.
         * @param y The y-position to move to.
         *
         */
        public function move(x:Number, y:Number):void {
            this.x = x;
            this.y = y;
        }

        /**
         * Set a new width and height for this control. This will trigger a layout on the
         * next validation.
         * @param w     The new width in pixels.
         * @param h     The new height in pixels.
         *
         */
        public function setSize(w:Number, h:Number):void {
            _width = w;
            _height = h;
            invalidateLayout();
        }

        /**
         * Get/Set the width for this control.
         * @param w     The new width in pixels.
         *
         */
        override public function set width(w:Number):void {
            setSize(w, _height);
        }

        /** @private */
        override public function get width():Number {
            return _width;
        }

        /**
         * Get/Set the height for this control.
         * @param h     The new height in pixels.
         *
         */
        override public function set height(h:Number):void {
            setSize(_width, h);
        }

        /** @private */
        override public function get height():Number {
            return _height;
        }

        /**
         * Set a new styleName for this control. The StyleManager will look up
         * the rule in the loaded stylesheets and combine it with the style for this
         * class of control.
         * @param value The style name to look up in the stylesheets.
         *
         */
        public function set styleName(value:String):void {
            _styleName = value;
            resetStyles();
            invalidateProperties();
            invalidateLayout();
        }

        /** @private */
        public function get styleName():String {
            return _styleName;
        }

        /**
         * Trigger the layout() method on the next validation.
         * @see #layout
         */
        protected function invalidateLayout():void {
            _layoutInvalidated = true;
            invalidate();
        }

        /**
         * Trigger the updateProperties() method on the next validation.
         * @see #updateProperties
         */
        protected function invalidateProperties():void {
            _propertiesInvalidated = true;
            invalidate();
        }

        /**
         * Called when an Event.RESIZE event is dispatched by a child of this component.
         * When this happens, we re-layout. If you use this functionality, you should be
         * careful not to trigger a loop.
         */
        protected function onResize(e:Event):void {
            if (e.target != this) {
                e.stopPropagation();
                layout();
            }
        }

        /**
         * Trigger a validation on the next ENTER_FRAME event, unless this
         * control is already invalidated.
         *
         */
        protected function invalidate():void {
            if (_invalidated)
                return;

            if (stage != null) {
                addEventListener(Event.ENTER_FRAME, validate, false, 0, true);
                    //stage.invalidate();
            }
            else {
                addEventListener(Event.ADDED_TO_STAGE, validate, false, 0, true);
            }
            _invalidated = true;
        }

        /**
         * Instruct this control to update and redraw immediately.
         */
        public function validateNow():void {
            validate(null);
        }

        /**
         * Call the createChildren, updateProperties, and layout methods, if
         * requested.
         * @param event The event that triggered the validation phase.
         *
         */
        private function validate(event:Event = null):void {

            if (event && event.type == Event.ADDED_TO_STAGE) {
                removeEventListener(Event.ADDED_TO_STAGE, validate, false);

                addEventListener(Event.ENTER_FRAME, validate, false, 0, true);

                return;
            }
            else {
                //removeEventListener(Event.RENDER, validate);
                removeEventListener(Event.ENTER_FRAME, validate);
            }

            _invalidated = false;

            if (!_initialized)
                initialize();

            // Validate children first:
            var i:int = numChildren;
            var d:DisplayObject;

            while (--i >= 0) {
                d = getChildAt(i);
                var c:ControlBase = d as ControlBase;

                if (c != null) {
                    c.validateNow();
                }

                var s:SimpleButton = d as SimpleButton;

                if (s != null) {
                    if (s.upState is ControlBase)
                        (s.upState as ControlBase).validateNow();

                    if (s.overState is ControlBase)
                        (s.overState as ControlBase).validateNow();

                    if (s.downState is ControlBase)
                        (s.downState as ControlBase).validateNow();

                    if (s.hitTestState is ControlBase)
                        (s.hitTestState as ControlBase).validateNow();
                }
            }

            if (_propertiesInvalidated) {
                _propertiesInvalidated = false;
                updateProperties();
            }

            if (_layoutInvalidated) {
                _layoutInvalidated = false;
                layout();
            }

        }

        /**
         * Set a single style property on this control.
         * @example
         * <listing version="3.0">
         * myControl.setStyle("padding", 10);
         * </listing>
         * @param styleName     The style property to set.
         * @param value The new value of the style property.
         *
         */
        public function setStyle(styleName:String, value:*):void {
            singleStyles[styleName] = value;
            myStyles[styleName] = value;
            invalidateLayout();
        }

        /**
         * Get a single style property that was previously set, or read from the stylesheets.
         * @example
         * <listing version="3.0">
         * var padding:Number = myControl.getStyle("padding");
         * </listing>
         * @param styleName     The style property to retrieve.
         * @return The untyped value of the style property.
         *
         */
        public function getStyle(styleName:String):* {
            return myStyles[styleName];
        }

        /**
         * Utility method to get the class definition of a skin defined in the stylesheets.
         * <p>For instance, you can define the property "backgroundSkin" in your CSS, and then
         * use this method to retrieve the class by calling getSkinClass("backgroundSkin").</p>
         * <p><b>IMPORTANT</b>: You must ensure that the skin class is compiled with your swf.</p>
         * @param name  The name of the style property to retrieve.
         * @return A class definition.
         *
         */
        protected function getSkinClass(name:String):Class {
            var klass:Class;
            try {
                var className:String = myStyles[name];
                klass = getDefinitionByName(className) as Class;
            }
            catch (err:Error) {
                trace("Couldn't create a skin element: " + getQualifiedClassName(this).split("::")[1] + " " + name + "\n    -- Make sure it is compiled with your swf and defined in the styles css.");
                return null;
            }

            return klass;
        }

        /**
         * Utility method to create an instance of a class defined in the stylesheets.
         * <p>For instance, you can define the property "backgroundSkin" in your CSS, and then
         * use this method to create the skin by calling <b>var background:DisplayObject = createSkinElement("backgroundSkin")</b>.</p>
         * <p><b>IMPORTANT</b>: You must ensure that the skin class is compiled with your swf.</p>
         * @param name  The name of the style property to use to create the skin.
         * @return The skin element as a DisplayObject.
         *
         */
        protected function createSkinElement(name:String):DisplayObject {
            var klass:Class = getSkinClass(name);

            var d:DisplayObject = null;

            if (klass != null)
                d = new klass() as DisplayObject;

            return d;
        }
    }
}

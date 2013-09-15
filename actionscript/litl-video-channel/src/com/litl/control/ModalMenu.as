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
    import com.litl.control.support.ModalMenuButton;
    import com.litl.control.support.StylableButton;
    import com.litl.event.ItemSelectEvent;
    import com.litl.sdk.message.UserInputMessage;
    import com.litl.sdk.service.ILitlService;

    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Point;
    import flash.geom.Rectangle;

    /**
     * Dispatched when a menu item is selected in the modal menu.
     */
    [Event(name="select", type="com.litl.event.ItemSelectEvent")]

    /**
     * Class to display a full screen menu with a number of selectable buttons.
     * @author litl
     * @example
     * <listing version="3.0">
     *
     * package
     * {
     *     import com.litl.control.ModalMenu;
     *     import com.litl.event.ItemSelectEvent;
     *     import flash.display.Sprite;
     *
     *     public class ModalMenuTest extends Sprite {
     *
     *     private var menu:ModalMenu;
     *
     *         public function ModalMenuTest() {
     *                  menu = new ModalMenu();
     *                  addChild(menu);
     *                  menu.dataProvider = [ "One", "Two", "Three", "Four", "Five" ];
     *                  menu.addEventListener(ItemSelectEvent.SELECT, onMenuSelect, false, 0, true);
     *     }
     *
     *         private function onMenuSelect(e:ItemSelectEvent):void {
     *          trace(e.selectedIndex);
     *     }
     *     }
     * }
     * </listing>
     */
    public class ModalMenu extends ControlBase
    {
        /**
         * A constant defining the alpha of the background when displaying the menu.
         */
        public static const BACKGROUND_ALPHA:Number = 0.75;

        /** @private */
        protected var background:Sprite;
        /** @private */
        protected var menuButtons:Array;
        /** @private */
        protected var _dataProvider:Array;
        /** @private */
        protected var _dataProviderChanged:Boolean = false;
        /** @private */
        protected var _selectedIndex:int = -1;
        /** @private */
        protected var _selectedIndexChanged:Boolean = false;

        /** @private */
        protected var _service:ILitlService;

        /** Constructor. */
        public function ModalMenu() {
            super();
        }

        /**
         * Get/Set the current dataProvider for this menu. The control will automatically create and layout buttons
         * with the labels in the supplied Array.
         * @param value An array of strings to use as button labels.
         *
         */
        public function set dataProvider(value:Array):void {
            _dataProviderChanged = _dataProviderChanged || (_dataProvider != value);
            _dataProvider = value;

            if (_dataProviderChanged)
                invalidateProperties();
        }

        /** @private */
        public function get dataProvider():Array {
            return _dataProvider;
        }

        /**
         * Get/Set the currently selected index. This allows you to control the menu externally; for example,
         * with wheel events from the LitlService.
         * @param value The index of the menu to highlight.
         * @see #listenForWheelEvents
         */
        public function set selectedIndex(value:int):void {
            var newValue:int = Math.min(Math.max(0, value), _dataProvider ? _dataProvider.length - 1 : -1);
            _selectedIndexChanged = _selectedIndexChanged || (_selectedIndex != newValue);
            _selectedIndex = newValue;

            if (_selectedIndexChanged)
                invalidateProperties();
        }

        /** @private */
        public function get selectedIndex():int {
            return _selectedIndex;
        }

        /**
         * Move the currently selected menu item to the next position. The selection does not wrap.
         * @param e     An optional event that triggered the method.
         *
         */
        public function moveNext(e:Event = null):void {
            selectedIndex = (menuButtons && menuButtons.length > 0) ? Math.min(menuButtons.length - 1, _selectedIndex + 1) : -1;
        }

        /**
         * Move the currently selected menu item to the previous position. The selection does not wrap.
         * @param e     An optional event that triggered the method.
         *
         */
        public function movePrevious(e:Event = null):void {
            selectedIndex = (menuButtons && menuButtons.length > 0) ? Math.max(0, _selectedIndex - 1) : -1;
        }

        /**
         * Instruct the menu to dispatch a "select" event for the currently highlighted item.
         * This allows you to externally control the selection with the go button from the LitlService, for example.
         * @param e     An optional event that triggered the method.
         * @see #listenForWheelEvents
         */
        public function selectCurrent(e:Event = null):void {
            if (_selectedIndex >= 0)
                dispatchEvent(new ItemSelectEvent(ItemSelectEvent.SELECT, _selectedIndex));
        }

        /**
         * <p>Pass in an ILitlService instance to automatically listen for wheel events to control this menu.</p>
         * <p>Remember to call <b>destroy()</b> when removing this menu to automatically remove these listeners.</p>
         * @param service       An ILitlService implementation instance.
         *
         */
        public function listenForWheelEvents(service:ILitlService):void {
            _service = service;
            service.addEventListener(UserInputMessage.WHEEL_DOWN, moveNext, false, 0, true);
            service.addEventListener(UserInputMessage.WHEEL_UP, movePrevious, false, 0, true);
            service.addEventListener(UserInputMessage.GO_BUTTON_PRESSED, selectCurrent, false, 0, true);
        }

        /** @inheritDoc */
        override public function set x(value:Number):void {
            super.x = value;
            invalidateLayout(); // redraw the background in the correct position.
        }

        /** @inheritDoc */
        override public function set y(value:Number):void {
            super.y = value;
            invalidateLayout(); // redraw the background in the correct position.
        }

        /** @inheritDoc
         * @private */
        override protected function createChildren():void {
            background = new Sprite();
            background.mouseChildren = true;
            background.useHandCursor = false;
            background.buttonMode = true;
            background.addEventListener(MouseEvent.MOUSE_DOWN, onBackgroundMouseDown, false, 0, true);
            addChild(background);

            if (stage == null)
                addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
            else
                onAddedToStage(null);
            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage, false, 0, true);
        }

        /** @inheritDoc
         * @private */
        override protected function updateProperties():void {
            if (_dataProviderChanged) {
                _dataProviderChanged = false;

                if (menuButtons != null)
                    for each (var button:ModalMenuButton in menuButtons) {
                        removeChild(button);
                        button.removeEventListener(Event.SELECT, onButtonSelected);
                        button.destroy();
                    }

                menuButtons = new Array();

                if (_dataProvider != null)
                    for (var i:int = 0; i < _dataProvider.length; i++) {
                        var item:String = _dataProvider[i].toString();
                        var newButton:ModalMenuButton = new ModalMenuButton();
                        addChild(newButton);
                        newButton.text = item;
                        menuButtons.push(newButton);
                        newButton.addEventListener(Event.SELECT, onButtonSelected, false, 0, true);
                    }

                invalidateLayout();
            }

            if (_selectedIndexChanged) {
                _selectedIndexChanged = false;

                deselectAll();

                if (_selectedIndex >= 0) {
                    if (menuButtons && menuButtons[_selectedIndex])
                        menuButtons[_selectedIndex].setPhase(StylableButton.OVER);
                }
            }

            super.updateProperties();
        }

        /** @inheritDoc
         * @private */
        override protected function layout():void {
            var g:Graphics = background.graphics;
            g.clear();

            if (stage != null) {
                g.beginFill(0, BACKGROUND_ALPHA);
                var tl:Point = new Point();
                var br:Point = new Point(stage.stageWidth, stage.stageHeight);
                tl = globalToLocal(stage.localToGlobal(tl));
                br = globalToLocal(stage.localToGlobal(br));
                var r:Rectangle = new Rectangle(tl.x, tl.y, br.x - tl.x, br.y - tl.y);
                r.inflate(5, 5);
                g.drawRect(r.x, r.y, r.width, r.height);
                g.endFill();
            }

            if (menuButtons != null && menuButtons.length > 0) {

                var ww:Number = _width > 0 ? _width : (stage ? stage.stageWidth : 1280);
                var hh:Number = _height > 0 ? _height : (stage ? stage.stageHeight : 800);
                var buttonWidth:Number = 639;
                var buttonHeight:Number = menuButtons.length < 5 ? 114 : (700 / menuButtons.length) * 114 / 160;
                var buttonSpacing:Number = menuButtons.length < 5 ? 46 : (700 / menuButtons.length) * 46 / 160;

                var xx:Number = (ww - buttonWidth) / 2;
                var yy:Number = (hh - (buttonHeight + buttonSpacing) * menuButtons.length) / 2;

                for (var i:int = 0; i < menuButtons.length; i++) {
                    var button:ModalMenuButton = menuButtons[i] as ModalMenuButton;
                    button.move(xx, yy);
                    button.setSize(buttonWidth, buttonHeight);

                    yy += buttonSpacing + buttonHeight;
                }
            }
        }

        /** @inheritDoc */
        override public function destroy():void {
            if (_service) {
                _service.removeEventListener(UserInputMessage.WHEEL_DOWN, moveNext, false);
                _service.removeEventListener(UserInputMessage.WHEEL_UP, movePrevious, false);
                _service.removeEventListener(UserInputMessage.GO_BUTTON_PRESSED, selectCurrent, false);
                _service = null;
            }

            super.destroy();
        }

        /** @private */
        protected function onButtonSelected(e:Event):void {
            for (var i:int = 0; i < menuButtons.length; i++) {
                if (menuButtons[i] == e.target) {
                    dispatchEvent(new ItemSelectEvent(ItemSelectEvent.SELECT, i));
                }
            }
        }

        /** @private */
        protected function onBackgroundMouseDown(e:MouseEvent):void {
            e.stopPropagation();
        }

        /** @private */
        protected function onAddedToStage(e:Event):void {
            stage.addEventListener(KeyboardEvent.KEY_DOWN, blockKey, true, 1);
            stage.addEventListener(KeyboardEvent.KEY_UP, blockKey, true, 1);
        }

        /** @private */
        protected function onRemovedFromStage(e:Event):void {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, blockKey, true);
            stage.removeEventListener(KeyboardEvent.KEY_UP, blockKey, true);
        }

        private function blockKey(e:KeyboardEvent):void {
            e.stopImmediatePropagation();
        }

        private function deselectAll():void {
            if (menuButtons != null)
                for each (var menuButton:ModalMenuButton in menuButtons) {
                    menuButton.setPhase(StylableButton.UP);
                }
        }
    }
}

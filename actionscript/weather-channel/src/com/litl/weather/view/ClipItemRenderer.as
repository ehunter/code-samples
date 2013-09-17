package com.litl.weather.view
{
    import flash.display.DisplayObject;

    import com.litl.control.ControlBase;
    import com.litl.control.listclasses.IItemRenderer;

    public class ClipItemRenderer extends ControlBase implements IItemRenderer
    {
        private var _data:Object;
        private var _dataChanged:Boolean;
        private var content:DisplayObject;

        public function ClipItemRenderer() {
            super();
        }

        override protected function createChildren():void {
            // Dont need to create anything until we have data
        }

        override protected function updateProperties():void {
            if (_dataChanged) {
                _dataChanged = false;

                if (content != null) {
                    if (content.parent == this) {
                        removeChild(content);
                    }
                }

                if (_data != null) {

                    content = _data as DisplayObject;

                    if (content != null) {
                        addChild(content);
                        ViewManager(content).populateView(); // custom call
                    }
                }
            }
        }

        override protected function layout():void {
            // No layout, assume the clip will take care of itself.
        }

        public function get data():Object {
            return _data;
        }

        public function set data(obj:Object):void {
            _dataChanged = _dataChanged || (_data != obj);
            _data = obj;

            if (_dataChanged)
                invalidateProperties();
        }

        public function set enabled(b:Boolean):void {

        }

        public function set selected(b:Boolean):void {

        }

        public function get selected():Boolean {
            return false;
        }

        public function get isReady():Boolean {
            return true;
        }
    }
}

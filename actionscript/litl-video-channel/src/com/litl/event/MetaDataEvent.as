package com.litl.event
{
    import flash.events.Event;

    public class MetaDataEvent extends Event
    {

        public static const ON_METADATA:String = "onMetaData";
        private var _metadata:Object;

        public function MetaDataEvent(type:String, metadata:Object, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
            this._metadata = metadata;
        }

        public function get metadata():Object {
            return _metadata;
        }

        override public function clone():Event {
            return new MetaDataEvent(type, bubbles, cancelable, _metadata);
        }

    }
}

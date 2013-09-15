package com.litl.event
{
    import flash.events.Event;

    public class ItemErrorEvent extends Event
    {
        public static const IO_ERROR:String = "ioError";

        public var message:String;
        public var item:Object;
        public var index:int;

        public function ItemErrorEvent(type:String, item:Object = null, index:int = -1) {
            super(type, false, false);
            this.item = item;
            this.index = index;
        }

        override public function clone():Event {
            return new ItemErrorEvent(type, item, index);
        }
    }
}

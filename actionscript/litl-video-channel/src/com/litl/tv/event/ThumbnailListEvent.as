package com.litl.tv.event
{
    import flash.events.Event;

    public class ThumbnailListEvent extends Event
    {
        public static const ARROW_BUTTON_PRESSED:String = "arrowButtonPressed";

        public function ThumbnailListEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type);

        }

        public override function clone():Event {
            return new ThumbnailListEvent(type, bubbles, cancelable);
        }

        public override function toString():String {
            return formatToString("ThumbnailListEvent", "type", "bubbles", "cancelable");
        }
    }
}

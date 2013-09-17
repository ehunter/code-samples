package com.litl.weather.events
{
    import Boolean;
    import String;
    import flash.events.Event;

    /**
     * @author mkeefe
     */
    public class OptionsBubbleEvent extends Event
    {
        public static const CLOSE:String = "close";

        public function OptionsBubbleEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
        }

        override public function clone():Event {
            return new OptionsBubbleEvent(type, bubbles, cancelable);
        }
    }
}

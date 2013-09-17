package com.litl.weather.events
{
    import Boolean;
    import String;
    import flash.events.Event;

    /**
     * @author mkeefe
     */
    public class FiveDayItemEvent extends Event
    {
        public static const HIDE_ANIMATION_COMPLETE:String = "hideAnimationComplete";

        public function FiveDayItemEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false) {
            super(type, bubbles, cancelable);
        }

        override public function clone():Event {
            return new FiveDayItemEvent(type, bubbles, cancelable);
        }
    }
}

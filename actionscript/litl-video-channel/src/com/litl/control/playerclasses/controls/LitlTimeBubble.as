package com.litl.control.playerclasses.controls
{
    import com.greensock.*;
    import com.greensock.easing.*;
    import com.greensock.plugins.*;
    import com.litl.sdk.util.Tween;
    import com.litl.skin.LitlColors;
    import com.litl.tv.utils.TimeCodeConverter;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.FullScreenEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    import org.osmf.events.ContainerChangeEvent;
    import org.osmf.events.DisplayObjectEvent;
    import org.osmf.events.MediaElementEvent;

    public class LitlTimeBubble extends VideoPlayerControlBase
    {

        public var timeBubble:TimeBubble;
        private var time:TextField;
        private static var TIME_SPACING:Number = 12;
        private var leftBubbleEdge:Number = 0;
        private var rightBubbleEdge:Number = 0;

        public function LitlTimeBubble() {
        }

        override protected function createChildren():void {

            timeBubble = new TimeBubble();
            addChild(timeBubble);
            timeBubble.endPoint.visible = false;

            time = new TextField();
            var timeFormat:TextFormat = new TextFormat("CorpoS", 18, LitlColors.BLACK);
            time.defaultTextFormat = timeFormat;
            time.width = 150;
            time.selectable = false;
            time.autoSize = TextFieldAutoSize.LEFT;

            addChild(time);

            invalidateLayout();
        }

        public function updateTime(value:Number):void {

            var timeToConvert:String = TimeCodeConverter.formatTime(value);

            if (value >= 0) {
                time.text = timeToConvert;
                time.autoSize = TextFieldAutoSize.LEFT;
                layout();
            }
            else {
                time.text = "--:--";
                time.autoSize = TextFieldAutoSize.LEFT;
                layout();
            }
        }

        override protected function layout():void {

            if (time.width > 0) {
                var timeFormat:TextFormat = new TextFormat("CorpoS", Math.round((_height - 8)), LitlColors.BLACK);
                time.defaultTextFormat = timeFormat;
                timeBubble.bubble.width = (time.width + TIME_SPACING);
                timeBubble.bubble.height = _height;
                time.x = (timeBubble.bubble.x - ((time.width) / 2));
                time.y = (timeBubble.bubble.y - ((timeBubble.bubble.height)));

                leftBubbleEdge = (timeBubble.bubble.x - (timeBubble.bubble.width / 2) + 4);
                rightBubbleEdge = ((timeBubble.bubble.width / 2) - (timeBubble.point.width) - 3);

            }

        }

        public function movePointer(xPos:Number):void {
            var centerPoint:Number = -(timeBubble.point.width / 2);
            var moveTo:Number = centerPoint - xPos;

            if (moveTo <= leftBubbleEdge) {
                timeBubble.point.x = leftBubbleEdge;
            }
            else if (moveTo >= rightBubbleEdge) {
                timeBubble.point.x = rightBubbleEdge;
            }
            else {
                timeBubble.point.x = moveTo;
            }

        }

        public function centerPointer():void {
            var centerPoint:Number = -(timeBubble.point.width / 2);
            timeBubble.point.x = centerPoint;

            timeBubble.point.visible = true;
            timeBubble.endPoint.visible = false;
        }
    }
}

package com.litl.control.playerclasses.controls
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.*;

    public class LitlBufferIndicator extends VideoPlayerControlBase
    {

        private var __base:BitmapData = null;
        private var __output:Sprite;

        private var __bar:Bitmap;
        private var __border:Sprite;
        private var __showBorder:Boolean = true;

        private var __matrix:Matrix;
        private var __firstBand:Rectangle;
        private var __secondBand:Rectangle;
        private var __scrollPos:int = 0;
        private var __scrollLimit:int;
        private var __speed:int = 2;
        private var __angle:int = 1;

        private var __bandWidth:int = 10;
        private var __baseColor:uint = 0xFFFFFEEE;
        private var __bandColor:uint = 0xFF6BC9FF;
        private var __borderColor:uint = 0xFF999999;
        private var __borderThickness:int = 1;

        public function LitlBufferIndicator() {
            super();
        }

        override protected function createChildren():void {
            __border = new Sprite();
            this.addChildAt(__border, 0);

            __output = new Sprite();
            addChild(__output);

            addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
            animate();
        }

        override protected function layout():void {
            if (!(_width > 0 && _height > 0))
                return;

            var adjacent:Number = _height / Math.tan(30 * Math.PI / 180);
            var hypot:Number = Math.sqrt(_height * _height + adjacent * adjacent);
            var amt:int = Math.ceil(adjacent / __bandWidth);
            var cutoff:int = (__bandWidth * 2);
            var extra:int = (__bandWidth * amt) + cutoff;
            var srcWidth:int = _width + extra;
            var px:int = (__speed > 0) ? 0 : _width;
            var len:int = srcWidth / __bandWidth;
            var i:int;

            // tranform matrix to apply to output
            __matrix = new Matrix();
            __matrix.c = __angle;
            __matrix.tx = -extra + ((__angle > 0) ? 0 : adjacent);

            // base BitmapData
            if (__base)
                __base.dispose();

            __base = new BitmapData(srcWidth, _height, false, __baseColor);

            for (i = 0; i < len; i++) {
                __base.fillRect(new Rectangle((i * __bandWidth) * 2, 0, __bandWidth, _height), __bandColor);
            }

            // output

            if (__output) {
                while (__output.numChildren > 0)
                    __output.removeChildAt(0);

                var outputBitmap:BitmapData = new BitmapData(srcWidth, _height, true, 0xFF);
                outputBitmap.draw(__base, __matrix);
                __output.addChild(new Bitmap(outputBitmap));
            }

            //limit
            var limit:int = Math.floor((__bandWidth * 2) / __speed);
            __scrollLimit = (__speed * (limit));

            setBorder();
        }

        protected function scroll(evt:Event):void {
            if (__output) {
                __scrollPos += __speed;

                if (__scrollPos > __scrollLimit) {
                    __scrollPos = __scrollPos % __scrollLimit;
                }
                __output.scrollRect = new Rectangle(__scrollPos, 0, _width, _height);
            }
        }

        private function setBorder():void {
            if (__border) {
                __border.graphics.clear();

                if (!__showBorder)
                    return;

                var inset:int = __borderThickness / 2;
                var wLimit:int = _width - inset;
                var hLimit:int = _height - inset;
                __border.graphics.lineStyle(__borderThickness, __borderColor, 100, false, "normal", "none", "miter");
                __border.graphics.moveTo(inset, inset);
                __border.graphics.lineTo(wLimit, inset);
                __border.graphics.lineTo(wLimit, hLimit);
                __border.graphics.lineTo(inset, hLimit);
                __border.graphics.lineTo(inset, inset);
            }
        }

        override public function destroy():void {
            removeEventListener(Event.ENTER_FRAME, scroll);
            __base.dispose();
            removeChild(__border);

            super.destroy();
        }

        public function animate():void {
            if (!this.hasEventListener(Event.ENTER_FRAME))
                addEventListener(Event.ENTER_FRAME, scroll);
        }

        public function showBorder(b:Boolean):void {
            __showBorder = b;
            setBorder();
        }

        public function set baseColor(col:uint):void {
            __baseColor = col;
            layout();
        }

        public function get baseColor():uint {
            return __baseColor;
        }

        public function set bandColor(col:uint):void {
            __bandColor = col;
            layout();
        }

        public function get bandColor():uint {
            return __bandColor;
        }

        public function set borderColor(col:uint):void {
            __borderColor = col;
            setBorder();
        }

        public function get borderColor():uint {
            return __borderColor;
        }

        public function set borderThickness(num:int):void {
            __borderThickness = num;
            setBorder();
        }

        public function get borderThickness():int {
            return __borderThickness;
        }

        public function set bandWidth(num:int):void {
            __bandWidth = num;
            layout();
        }

        public function get bandWidth():int {
            return __bandWidth;
        }

        public function set speed(amt:int):void {
            __speed = amt;
            layout();
        }

        public function get speed():int {
            return __speed;
        }

        public function set angle(num:int):void {
            __angle = (num > 0) ? 1 : -1;
            layout();
        }

        public function get angle():int {
            return __angle;
        }

        protected function onRemovedFromStage(event:Event):void {
            removeEventListener(Event.ENTER_FRAME, scroll);
        }
    }

}

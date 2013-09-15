package com.litl.tv.view
{
    import com.litl.control.ControlBase;
    import com.litl.skin.LitlColors;

    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.MouseEvent;

    public class ThumbnailItemOverlay extends ControlBase
    {

        protected var borderColor:uint = LitlColors.MEDIUM_DARK_GREY;
        protected var borderThickness:int = 2;
        protected var backgroundColor:uint = LitlColors.BLACK;
        protected var bg:Sprite = null;

        public function ThumbnailItemOverlay() {

        }

        override protected function createChildren():void {
            //borderColor = myStyles.borderColor;
            //borderThickness = myStyles.borderThickness;
            //backgroundColor = myStyles.backgroundColor;
            bg = new Sprite();
            bg.addEventListener(MouseEvent.MOUSE_OVER, onItemOver);
            // a//ddChild(bg);

            //var g:Graphics = graphics;
            bg.graphics.clear();

            bg.graphics.beginFill(backgroundColor, .75);
            bg.graphics.drawRect(0, 0, 500, 20);
            bg.graphics.endFill();
            addChild(bg);
        }

        override protected function layout():void {

        }

        public function setBgSize(w:Number, h:Number):void {
            bg.width = w;
            bg.height = h;
        }

        private function onItemOver(evt:MouseEvent):void {
            //trace("OVER");
        }

    }
}

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
package com.litl.tv.renderer
{
    import com.litl.control.listclasses.IItemRenderer;
    import com.litl.control.listclasses.TextItemRenderer;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.utils.StringUtils;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.*;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    public class SlideRenderer extends TextItemRenderer implements IItemRenderer
    {
        private static const THUMB_WIDTH_THRESHOLD:Number = 280;
        protected var model:AppModel;
        private var _episodeData:EpisodeData;
        private var newestEpisodeCard:Sprite = null;
        private var slideshowImages:Array = new Array();
        private var descriptionOn:Boolean = false;
        private var episodeCardBg:Sprite = null;
        private var episodeText:TextField;
        private var episodeNumberText:TextField;
        private static const ELLIPSIS:String = "...";
        private var cardViewImageHolder:Sprite = null;
        private var _networkConnected:Boolean;
        private var _dataChanged:Boolean;

        public function SlideRenderer() {

            super();
        }

        override public function get isReady():Boolean {
            return true;
        }

        override public function set data(obj:Object):void {
            _dataChanged = _episodeData != obj;

            _episodeData = obj as EpisodeData;

            if (_dataChanged)
                invalidateProperties();
        }

        override protected function createChildren():void {
            super.createChildren();

            if (_episodeData._title != "blank") {

                model = AppModel.getInstance();

                episodeCardBg = new Sprite();
                episodeCardBg.graphics.beginFill(0x000000);
                episodeCardBg.graphics.drawRect(0, 0, this._width, this._height);
                episodeCardBg.graphics.endFill();
                episodeCardBg.alpha = .8;
                episodeCardBg.visible = true;
                addChild(episodeCardBg);

                episodeText = new TextField();
                var tfm:TextFormat = new TextFormat("CorpoS", 22, 0xFFFFFF, false);
                tfm.align = TextFormatAlign.CENTER;
                episodeText.defaultTextFormat = tfm;
                episodeText.width = 275;
                episodeText.multiline = true;
                episodeText.wordWrap = true;
                episodeText.selectable = false;
                episodeText.autoSize = TextFieldAutoSize.NONE;
                episodeText.visible = true;

                episodeNumberText = new TextField();
                var epNumberFormat:TextFormat = new TextFormat("CorpoS", 18, 0x888888, false);
                epNumberFormat.align = TextFormatAlign.CENTER;
                episodeNumberText.multiline = true;
                episodeNumberText.wordWrap = true;
                episodeNumberText.width = 275;
                episodeNumberText.selectable = false;
                episodeNumberText.autoSize = TextFieldAutoSize.NONE;
                episodeNumberText.defaultTextFormat = epNumberFormat;
                episodeNumberText.visible = true;

                newestEpisodeCard = new Sprite();
                addChild(newestEpisodeCard);
                newestEpisodeCard.addChild(episodeText);
                newestEpisodeCard.addChild(episodeNumberText);
            }

        }

        override protected function updateProperties():void {

            if (_episodeData._title == "blank") {
                var emptySprite:Sprite = new Sprite();
                addChild(emptySprite);
                hideText();
            }
            else {
                setEpisodeText();
            }

        }

        private function hideText():void {
            if (episodeCardBg)
                episodeCardBg.visible = false;

            if (newestEpisodeCard)
                newestEpisodeCard.visible = false;
        }

        /**
         * setEpisodeText
         *
         *
         *
         */
        private function setEpisodeText():void {
            if (_episodeData._title != "") {
                var label:String = StringUtils.truncate(_episodeData._title, 55);
                episodeText.text = "Newest Episode: " + label;
                episodeText.autoSize = TextFieldAutoSize.LEFT;

                if (_episodeData._number) {
                    episodeNumberText.text = "Episode " + _episodeData._number;
                    episodeNumberText.autoSize = TextFieldAutoSize.LEFT;
                }

                positionEpisodeText();

            }

        }

        private function positionEpisodeText():void {
            var center:int = ((_width - newestEpisodeCard.width) / 2);

            episodeNumberText.y = (episodeText.height + 5);

            newestEpisodeCard.x = center;

            if (episodeNumberText.text != "") {
                newestEpisodeCard.y = ((_height - newestEpisodeCard.height) / 2) + 8;
            }
            else {
                newestEpisodeCard.y = ((_height - episodeText.height) / 2);
            }

        }

        override protected function layout():void {

            updateProperties();
        }

    }
}

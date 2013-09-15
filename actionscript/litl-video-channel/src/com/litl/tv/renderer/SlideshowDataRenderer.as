package com.litl.tv.renderer
{

    import com.litl.control.ControlBase;
    import com.litl.control.listclasses.IItemRenderer;
    import com.litl.control.listclasses.ImageItemRenderer;
    import com.litl.skin.LitlColors;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ImageData;
    import com.litl.tv.model.data.ThumbnailData;
    import com.greensock.*;
    import com.greensock.easing.*;
    import com.greensock.plugins.*;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    public class SlideshowDataRenderer extends ImageItemRenderer implements IItemRenderer
    {

        protected var _episodeData:EpisodeData;
        protected var label:TextField;
        protected var ratingIcon:DisplayObject;
        protected var thumbUrl:String = "";
        protected var thumbCount:int = -1;
        protected var model:AppModel;

        public function SlideshowDataRenderer() {

            super();
            TweenPlugin.activate([ TintPlugin ]);
        }

        override public function set data(obj:Object):void {
            var changed:Boolean = _episodeData != obj;

            _episodeData = obj as EpisodeData;
            super.data = obj;

            if (changed)
                invalidateProperties();
        }

        override protected function createChildren():void {
            super.createChildren();
            model = AppModel.getInstance();

            label = new TextField();
            var tfm:TextFormat = new TextFormat("CorpoS", 10, LitlColors.LIGHT_GREY);

            tfm.align = TextFormatAlign.LEFT;
            tfm.leading = -2;
            label.defaultTextFormat = tfm;
            label.wordWrap = true;
            //textField.embedFonts = true;
            label.multiline = true;
            label.selectable = false;
            label.antiAliasType = "advanced";
            label.gridFitType = "pixel";
            label.autoSize = TextFieldAutoSize.NONE;
            addChild(label);
        }

        override protected function updateProperties():void {

            if (_episodeData) {

                try {
                    var episodes:Array = model.episodes;

                    if (_url != thumbUrl) {
                        var episodesLength:int = episodes.length;

                        if (thumbCount < episodesLength) {
                            thumbCount++;
                        }
                        else {
                            thumbCount = 0;
                        }

                        if (_episodeData._thumbnailUrl != "") {
                            thumbUrl = _episodeData._thumbnailUrl;
                        }
                        else {
                            var currentImageData:ImageData = model.currentImageData;
                            thumbUrl = currentImageData._cardUrl;
                        }
                        _url = thumbUrl;
                        load(_url);
                    }

                }
                catch (err:Error) {

                }

            }

        }

        override protected function layout():void {

            if (_width > 0 && _height > 0) {
                //var g:Graphics = graphics;
                //g.clear();
                //g.beginFill(LitlColors.DARK_GREY, 1);

                if (_selected) {
                    //TweenLite.to(itemBg, .25, {alpha:1, ease:Quart.easeOut});
                    //itemBg.visible = false;
                    //TweenLite.to(description, .25, { tint: LitlColors.LIGHT_GREY, ease: Quart.easeOut });
                    TweenMax.killTweensOf(this, true);
                    TweenMax.to(this, .2, { colorTransform: { tint: LitlColors.DARK_GREY, tintAmount: 0 }});

                }
                else if (!_selected) {

                    //TweenLite.to(itemBg, .25, {alpha:0, ease:Quart.easeOut});
                    //itemBg.visible = true;
                    //TweenLite.to(description, .25, { tint: null, ease: Quart.easeOut });
                    // TweenLite.to(_content, .2, { tint: LitlColors.DARK_GREY, ease: Quart.easeOut });
                    TweenMax.killTweensOf(this, true);
                    TweenMax.to(this, .2, { colorTransform: { tint: LitlColors.DARK_GREY, tintAmount: 0.75 }});

                }
                    // g.drawRect(0, 0, _width, _height);
                    //g.endFill();
            }

            if (_content != null) {

                doScale(_width, _height);

                _content.x = (_width - _content.width) / 2;
                _content.y = (_height - _content.height) / 2;
            }

        }

        private static const ELLIPSIS:String = "...";

        protected function truncateLabel(label:TextField, lines:int = -1, toNearestWord:Boolean = false):void {

            if (label.maxScrollV < lines || label.bottomScrollV == 1)
                return;

            var initial:String = label.text;
            var lastLine:String = label.getLineText(label.bottomScrollV - 1);
            var visibleLength:uint = label.getLineOffset(label.bottomScrollV - 1);
            var newText:String;

            if (toNearestWord) {
                lastLine = lastLine.replace(/[\s]*$/, "");

                var lastLineWords:Array = lastLine.split(" ");

                var lastChar:String = lastLineWords[lastLineWords.length - 1].substr(-1, 1);
                var punctuation:String = ".,!?;:\"%*)-\n\r";

                if (punctuation.indexOf(lastChar) < 0) // if lastChar is not any of the punctuation chars
                {
                    lastLineWords[lastLineWords.length - 1] = ELLIPSIS;
                }

                newText = initial.substr(0, visibleLength) + lastLineWords.join(" ");
            }
            else {
                newText = initial.substr(0, visibleLength + lastLine.length - 4) + " " + ELLIPSIS;
            }

            label.text = newText + " "; // SPACE ADDED AT END SO TEXT DOESN'T WRAP UNNECESARILLY.
        }

    }
}

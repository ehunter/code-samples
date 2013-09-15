package com.litl.tv.renderer
{

    import com.greensock.*;
    import com.greensock.easing.*;
    import com.greensock.plugins.*;
    import com.litl.control.ControlBase;
    import com.litl.control.listclasses.IItemRenderer;
    import com.litl.control.listclasses.ImageItemRenderer;
    import com.litl.skin.LitlColors;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ThumbnailData;

    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    public class FilmstripFocusViewDataRenderer extends ImageItemRenderer implements IItemRenderer
    {

        protected var _episodeData:EpisodeData;
        protected var title:TextField;
        protected var description:TextField;
        protected var ratingIcon:DisplayObject;
        protected var thumb:String = "";
        protected var thumbCount:int = -1;
        private var model:AppModel;
        private var itemBg:Sprite = null;

        public function FilmstripFocusViewDataRenderer() {

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

            title = new TextField();
            var tfm:TextFormat = new TextFormat("CorpoS", 10, LitlColors.LIGHT_GREY);
            tfm.align = TextFormatAlign.LEFT;
            tfm.leading = -2;
            title.defaultTextFormat = tfm;
            title.wordWrap = true;
            //title.embedFonts = true;
            title.multiline = true;
            title.selectable = false;
            title.antiAliasType = "advanced";
            title.gridFitType = "pixel";
            title.autoSize = TextFieldAutoSize.NONE;
            addChild(title);

            description = new TextField();
            description.defaultTextFormat = tfm;
            description.wordWrap = true;
            //title.embedFonts = true;
            description.multiline = true;
            description.selectable = false;
            description.antiAliasType = "advanced";
            description.gridFitType = "pixel";
            description.autoSize = TextFieldAutoSize.NONE;
            addChild(description);

        }

        override protected function updateProperties():void {

            /// if we have any episodeData to work with
            if (_episodeData) {
                if (title != null) {
                    title.text = _episodeData._title;
                }

                if (description != null) {
                    description.text = _episodeData._description;
                }

                try {
                    var episodes:Array = model.episodes;

                    if (_url != thumb) {
                        var episodesLength:int = episodes.length;

                        if (thumbCount < episodesLength) {
                            thumbCount++;
                        }
                        else {
                            thumbCount = 0;
                        }
                        //thumb = episodes[thumbCount]._thumbnailUrl;
                        thumb = _episodeData._thumbnailUrl;
                        _url = thumb;
                        load(_url);
                    }

                }
                catch (err:Error) {

                }

            }
        }

        override protected function layout():void {
            //trace(itemBg + " _width of the FilmstripFocusViewDataRenderer")
            if (_width > 0 && _height > 0) {

                if (itemBg == null) {
                    itemBg = new Sprite();
                    // add it to the bottom layer
                    this.addChildAt(itemBg, 0);
                    itemBg.graphics.clear();
                    itemBg.graphics.beginFill(LitlColors.DARK_GREY, 1);
                    itemBg.graphics.drawRect(0, 0, 174, 200);
                    itemBg.graphics.endFill();

                    title.width = _width - 20;
                    title.height = 28;
                    title.y = _height + 5;

                    description.y = _height + 25
                }
                else {
                    if (_selected) {
                        TweenLite.to(itemBg, .25, { tint: 0x4D4D4D, ease: Quart.easeOut });
                    }
                    else {
                        TweenLite.to(itemBg, .25, { tint: null, ease: Quart.easeOut });
                    }

                }
            }

            if (_content != null) {

                //doScale(_width, _height);

                _content.x = (_width - _content.width) / 2;
                _content.y = (_height - _content.height) / 2;
            }

            //updateProperties();
            //truncatetitle(title, 2);
        }

    }
}

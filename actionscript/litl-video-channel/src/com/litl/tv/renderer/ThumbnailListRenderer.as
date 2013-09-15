package com.litl.tv.renderer
{
    import com.greensock.*;
    import com.greensock.easing.*;
    import com.greensock.plugins.*;
    import com.litl.control.ControlBase;
    import com.litl.control.Label;
    import com.litl.control.listclasses.IItemRenderer;
    import com.litl.control.listclasses.ImageItemRenderer;
    import com.litl.skin.LitlColors;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ImageData;
    import com.litl.tv.model.data.ThumbnailData;
    import com.litl.tv.utils.StringUtils;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Graphics;
    import flash.display.SpreadMethod;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    import mx.utils.NameUtil;

    public class ThumbnailListRenderer extends ImageItemRenderer implements IItemRenderer
    {

        protected var _episodeData:EpisodeData;
        protected var title:TextField;
        protected var episodeNumber:Label;
        protected var videoRunTime:Label;
        protected var thumbUrl:String = "";
        protected var thumbCount:int = -1;
        private var model:AppModel;
        private var itemBg:Sprite;
        private var thumbnail:Sprite;
        private var imageHolder:Sprite;
        private var itemSelected:Boolean = false;
        private var defaultTintAmount:Number = .7;
        private var imageLoaded:Boolean = false;
        private static var THUMBNAIL_WIDTH:Number = 160;
        private static var THUMBNAIL_HEIGHT:Number = 90;

        public function ThumbnailListRenderer() {

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

            thumbnail = new Sprite();
            addChild(thumbnail);

            title = new TextField();
            var titleFormat:TextFormat = new TextFormat("CorpoS", 16, LitlColors.BLUE);
            //titleFormat.align = TextFormatAlign.NONE;
            titleFormat.leading = -2;
            title.defaultTextFormat = titleFormat;
            title.wordWrap = true;
            title.width = 150;
            //title.border = true;
            //title.borderColor = 0xFFFFFF;
            //title.embedFonts = true;
            title.multiline = true;
            title.selectable = false;
            //title.antiAliasType = "advanced";
            //title.gridFitType = "pixel";
            //title.autoSize = TextFieldAutoSize.NONE;
            addChild(title);

            /*
               title = new Label();
               title.setStyle("size", 16);
               title.width = 150;
               //title.multiline = true;
               //title.antiAliasType = "advanced";
               //title.gridFitType = "pixel";
               //title.autoSize = TextFieldAutoSize.NONE;
               addChild(title);
             */

            episodeNumber = new Label();
            episodeNumber.setStyle("size", 14);
            episodeNumber.width = 200;
            addChild(episodeNumber);
            episodeNumber.y = 143;

            videoRunTime = new Label();
            videoRunTime.width = 200;
            videoRunTime.setStyle("size", 14);
            //episodeNumber.embedFonts = true;
            videoRunTime.autoSize = TextFieldAutoSize.NONE;
            addChild(videoRunTime);
            videoRunTime.y = (episodeNumber.y + 17);

            mouseChildren = false;
            mouseEnabled = true;
            buttonMode = true;
            useHandCursor = true;

            imageHolder = new Sprite();
            addChild(imageHolder);

        }

        override protected function updateProperties():void {

            /// if we have any episodeData to work with
            if (_episodeData) {
                if (title != null) {
                    var titleLabel:String = StringUtils.truncate(_episodeData._title, 34);
                    title.autoSize = TextFieldAutoSize.LEFT;
                    title.text = titleLabel;

                    // by adding 2 pixels to the height and then setting AutoSize to none
                    /// it seems to fix the cropping off of descenders
                    title.height += 2;
                    title.autoSize = TextFieldAutoSize.NONE;

                }

                if (_episodeData) {
                    if (_episodeData._airDate) {
                        var airDate:Date = _episodeData._airDate;
                        var formattedAirDate:String = (airDate.getMonth() + 1) + "-" + airDate.getDate() + "-" + airDate.getFullYear();
                        episodeNumber.text = "Aired On " + formattedAirDate;
                    }
                    else {

                        if ((episodeNumber != null) && (_episodeData._number != "")) {
                            episodeNumber.text = "Episode " + _episodeData._number;
                        }
                        else {
                            episodeNumber.text = "";
                        }
                    }
                }

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

                if (videoRunTime != null) {
                    videoRunTime.text = _episodeData._runTime;
                }
            }

        }

        override protected function layout():void {

            if (_width > 0 && _height > 0) {

                if (!itemBg) {
                    itemBg = new Sprite();
                    // add it to the bottom layer

                    itemBg.graphics.clear();
                    itemBg.graphics.beginFill(LitlColors.BLACK, 1);
                    itemBg.graphics.drawRect(0, 0, 173, _height);
                    itemBg.graphics.endFill();
                    addChildAt(itemBg, 0);

                    title.width = _width - 20;
                    title.height = 28;

                    episodeNumber.y = 143;
                    videoRunTime.y = (episodeNumber.y + 17);

                }

                if (_selected) {
                    TweenLite.killTweensOf(itemBg, true)

                    episodeNumber.setStyle("color", LitlColors.BLUE);

                    var titleFormat:TextFormat = new TextFormat("CorpoS", 16, LitlColors.BLUE);
                    title.defaultTextFormat = titleFormat;
                    videoRunTime.setStyle("color", LitlColors.BLUE);
					if(itemBg)
                    	TweenLite.to(itemBg, .25, { tint: 0x333333 });
                    TweenMax.killTweensOf(this, true);
                    TweenMax.to(this, .25, { colorTransform: { tint: LitlColors.DARK_GREY, tintAmount: 0 }});
                    this.removeEventListener(MouseEvent.MOUSE_OVER, onItemOver);
                    this.removeEventListener(MouseEvent.MOUSE_OUT, onItemOut);

                }
                else if (!_selected) {

                    TweenLite.killTweensOf(itemBg, true);

                    episodeNumber.setStyle("color", LitlColors.GREY);
                    var titleFormatOff:TextFormat = new TextFormat("CorpoS", 16, LitlColors.GREY);
                    title.defaultTextFormat = titleFormatOff;
                    videoRunTime.setStyle("color", LitlColors.GREY);

                    TweenLite.to(itemBg, .25, { tint: LitlColors.BLACK });
                    TweenMax.killTweensOf(this, true);
                    TweenMax.to(this, .25, { colorTransform: { tint: LitlColors.BLACK, tintAmount: defaultTintAmount }});
                    this.addEventListener(MouseEvent.MOUSE_OVER, onItemOver);
                    this.addEventListener(MouseEvent.MOUSE_OUT, onItemOut);

                }

            }

            if (_content != null) {

                doScale(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT);

                _content.x = (_width - _content.width) / 2;
                _content.y = 5;

                title.y = 102;
                title.x = 8;
				episodeNumber.x = videoRunTime.x = (title.x + 3);
                episodeNumber.y = 143;
                videoRunTime.y = (episodeNumber.y + 17);
            }

            updateProperties();
            //truncatetitle(title, 2);
        }

        /**
         * Called when theres an error loading an image
         * by default if there's an error we try to load the cardView image once
         * @private
         */
        override protected function onIOError(e:IOErrorEvent):void
        {
            var currentImageData:ImageData = model.currentImageData;
            var defaultImageUrl:String = currentImageData._cardUrl;

            if(thumbUrl != defaultImageUrl){
                thumbUrl = defaultImageUrl;
                load(thumbUrl);
            }

        }

        /**
         * Called when a loader dispatches a complete event.
         * @private
         */
        override protected function onImageLoad(e:Event):void {

            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onImageLoad, false);

            if (_content && contains(_content))
                removeChild(_content);
            _content = loader.content;
            _content.alpha = 0;
            TweenLite.to(_content, .35, { alpha: 1, ease: Quart.easeOut });
            Bitmap(_content).smoothing = true;

            if (cache != null && !cache.hasImage(_url))
                cache.storeImage(_url, _content);

            if (contains(background))
                removeChild(background);
            addChild(_content);
            layout();
            imageLoaded = true;
            dispatchEvent(new Event(Event.COMPLETE));
        }

        private function onItemOver(evt:MouseEvent):void {
            TweenMax.to(this, .2, { colorTransform: { tint: LitlColors.DARK_GREY, tintAmount: 0 }});
        }

        private function onItemOut(evt:MouseEvent):void {
            TweenMax.to(this, .2, { colorTransform: { tint: LitlColors.BLACK, tintAmount: defaultTintAmount }});
        }

        private function onItemPress(evt:MouseEvent):void {
            itemSelected = true;
            this.removeEventListener(MouseEvent.MOUSE_OVER, onItemOver);
            this.removeEventListener(MouseEvent.MOUSE_OUT, onItemOut);
        }

    }
}

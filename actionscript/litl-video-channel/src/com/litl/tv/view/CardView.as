package com.litl.tv.view
{
    import com.greensock.TweenLite;
    import com.greensock.easing.*;
    import com.greensock.events.LoaderEvent;
    import com.greensock.loading.*;
    import com.greensock.loading.display.*;
    import com.greensock.plugins.AutoAlphaPlugin;
    import com.greensock.plugins.TweenPlugin;
    import com.litl.control.ControlBase;
    import com.litl.control.Slideshow;
    import com.litl.control.listclasses.ImageItemRenderer;
    import com.litl.event.ItemSelectEvent;
    import com.litl.sdk.util.Tween;
    import com.litl.skin.parts.LoadingSpinner;
    import com.litl.tv.event.FeedUpdateEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.model.data.ImageData;
    import com.litl.tv.renderer.SlideshowDataRenderer;
    import com.litl.tv.utils.StringUtils;

    import flash.display.Bitmap;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;

    import mx.core.SpriteAsset;



    public class CardView extends ControlBase
    {

        protected var icon:CardIcon;
        //protected var slideshow:Slideshow;
        protected var model:AppModel;
        private var newestEpisodeCard:Sprite = null;
        private var slideshowImages:Array = new Array();
        private var descriptionOn:Boolean = false;
        private var episodeCardBg:Sprite = null;
        private var newestEpisodeData:EpisodeData;
        private var currentImageData:ImageData;
        private var episodeText:TextField;
        private var episodeNumberText:TextField;
        private var endX:Number = 0;
        private static const ELLIPSIS:String = "...";
        private var cardViewImageHolder:Sprite = null;
		private var watermarkHolder:Sprite = null;
        private var spinner:LoadingSpinner;
        private var cardLoaded:Boolean = false;
        private var _networkConnected:Boolean;

		[Embed(source="/../assets/pbs_general_watermark.png")]
		private static const pbsGeneralWatermark:Class;

		[Embed(source="/../assets/pbs_kids_watermark.png")]
		private static const pbsKidsWatermark:Class;

		private var watermark:DisplayObject;


        public function CardView() {
            super();
            TweenPlugin.activate([ AutoAlphaPlugin ]);

        }

        public function get networkConnected():Boolean {
            return _networkConnected;
        }

        public function set networkConnected(value:Boolean):void {
            _networkConnected = value;

            if (!_networkConnected) {
                showNetworkError();
            }
        }

        public function pause():void {
            //if (slideshow) {
            //slideshow.pause();
            //}
        }

        public function play():void {
            //if (slideshow) {
            //slideshow.play();
            //}

        }

        public function nextItem():void {
            toggleEpisodeCard();

        }

        public function previousItem():void {
            toggleEpisodeCard();
        }

        /**
         * toggleEpisodeCard
         *
         *
         */
        private function toggleEpisodeCard():void {
            checkDataFreshness();

            if (episodeText.text != newestEpisodeData._title) {
                setEpisodeText();
            }

            if (!episodeCardBg.visible) {
                episodeCardBg.visible = true;
                episodeCardBg.alpha = 0;
                episodeText.visible = episodeNumberText.visible = true;

                episodeText.x = episodeNumberText.x = 320;

                TweenLite.to(episodeCardBg, 0.35, { alpha: .8 });

                TweenLite.to(episodeText, 0.85, { x: endX, ease: Quart.easeOut, delay: .1 });
                TweenLite.to(episodeNumberText, 0.85, { x: endX, ease: Quart.easeOut, delay: .1 });
            }
            else {
                TweenLite.to(episodeCardBg, 0.5, { alpha: 0, delay: .15 });
                TweenLite.to(episodeText, 0.75, { x: -280, ease: Quart.easeOut });
                TweenLite.to(episodeNumberText, 0.75, { x: -280, ease: Quart.easeOut, onComplete: hideBg });
            }

        }

        /**
         * hideBg
         *
         */
        private function hideBg():void {
            episodeCardBg.visible = false;
            episodeText.visible = episodeNumberText.visible = false;
            episodeText.x = episodeNumberText.x = 320;
        }

        /**
         * createChildren
         *
         *
         */
        override protected function createChildren():void {

            model = AppModel.getInstance();
            model.addEventListener(FeedUpdateEvent.FEED_UPDATE, onFeedUpdate, false, 0, true);

            setLoading(true);

            cardViewImageHolder = new Sprite();
            addChild(cardViewImageHolder);
            //cardViewImageHolder.alpha = 0;

			watermarkHolder = new Sprite();
			addChild(watermarkHolder);

			trace("model.currentNetwork is " + model.currentNetwork)

			if((model.currentNetwork == "pbs") || (model.currentNetwork == "pbsKids")){
				addPBSWatermark();
			}

            episodeCardBg = new Sprite();
            episodeCardBg.graphics.beginFill(0x000000);
            episodeCardBg.graphics.drawRect(0, 0, this._width, this._height);
            episodeCardBg.graphics.endFill();
            episodeCardBg.alpha = .8;
            episodeCardBg.visible = false;
            addChild(episodeCardBg);




            episodeText = new TextField();
            var tfm:TextFormat = new TextFormat("CorpoS", 22, 0xFFFFFF, false);
            tfm.align = TextFormatAlign.CENTER;
            episodeText.defaultTextFormat = tfm;
            episodeText.width = 275;
            episodeText.multiline = true;
            episodeText.wordWrap = true;
            episodeText.selectable = false;
            //episodeText.antiAliasType = "advanced";
            //episodeText.gridFitType = "pixel";
            episodeText.autoSize = TextFieldAutoSize.NONE;
            episodeText.visible = false;

            episodeNumberText = new TextField();
            var epNumberFormat:TextFormat = new TextFormat("CorpoS", 18, 0x888888, false);
            epNumberFormat.align = TextFormatAlign.CENTER;
            episodeNumberText.multiline = true;
            episodeNumberText.wordWrap = true;
            episodeNumberText.width = 275;
            episodeNumberText.selectable = false;
            //episodeNumberText.antiAliasType = "advanced";
            //episodeNumberText.gridFitType = "pixel";
            episodeNumberText.autoSize = TextFieldAutoSize.NONE;
            episodeNumberText.defaultTextFormat = epNumberFormat;
            episodeNumberText.visible = false;

            newestEpisodeCard = new Sprite();
            addChild(newestEpisodeCard);
            newestEpisodeCard.addChild(episodeText);
            newestEpisodeCard.addChild(episodeNumberText);

        }

		/**
		 * determines which pbs watermark to use (kids or general) and adds it the stage
		 *
		 */
		private function addPBSWatermark():void{


				switch(model.currentNetwork){
					case "pbsKids":
						watermark = new pbsKidsWatermark();
						watermark.x = 250;
						watermark.y = 110;
						break;
					case "pbs":
						watermark = new pbsGeneralWatermark();
						watermark.x = 186;
						watermark.y = 118;
						break;
					default:
						break;
				}

				watermark.visible = false;
				watermarkHolder.addChild(watermark);


		}

        private function loadCardViewImage():void {

            //create a LoaderMax named "mainQueue" and set up onProgress, onComplete and onError listeners
            var imageToLoad:String = currentImageData._cardUrl;
            var queue:LoaderMax = new LoaderMax({ name: "mainQueue", onProgress: progressHandler, onComplete: completeHandler, onError: errorHandler });
            queue.append(new ImageLoader(imageToLoad, { name: "cardviewImage", estimatedBytes: 3000, container: cardViewImageHolder, alpha: 1 }));
            //start loading
            queue.load();

        }

        private function progressHandler(event:LoaderEvent):void {

        }

        private function completeHandler(event:LoaderEvent):void {

            var image:ContentDisplay = LoaderMax.getContent("cardViewImage");
            //TweenLite.to(cardViewImageHolder, 1, { alpha: 1 });
            setLoading(false);
            cardLoaded = true;
			if(watermark)
				watermark.visible = true;
        }

        private function errorHandler(event:LoaderEvent):void {
            trace("error occured with " + event.target + ": " + event.text);
        }

        /**
         * layout
         *
         *
         */
        override protected function layout():void {

            // if the card has not been loaded
            if ((!cardLoaded) && (currentImageData != null)) {
                loadCardViewImage();
            }

        }

        /**
         * onFeedUpdate
         *
         *
         */
        protected function onFeedUpdate(e:FeedUpdateEvent):void {
            newestEpisodeData = model.getNewestEpisode();
            currentImageData = model.currentImageData;
        }

        /**
         * setEpisodeText
         *
         *
         *
         */
        private function setEpisodeText():void {
            if (newestEpisodeData) {
                var label:String = StringUtils.truncate(newestEpisodeData._title, 55);
                episodeText.text = "Newest Episode: " + label;
                episodeText.autoSize = TextFieldAutoSize.LEFT;

                if (newestEpisodeData._number) {
                    episodeNumberText.text = "Episode " + newestEpisodeData._number;
                    episodeNumberText.autoSize = TextFieldAutoSize.LEFT;
                }

                positionEpisodeText();

            }

        }

        private function positionEpisodeText():void {
            var center:int = ((_width - episodeText.width) / 2);

            episodeNumberText.y = (episodeText.height + 5);
            episodeNumberText.x = episodeText.x;

            if (episodeNumberText.text != "") {
                newestEpisodeCard.y = ((_height - newestEpisodeCard.height) / 2) + 8;
            }
            else {
                newestEpisodeCard.y = ((_height - episodeText.height) / 2);
            }

            endX = center;
        }

        /**
         * setLoading
         *
         *
         */
        public function setLoading(b:Boolean):void {

            if (b) {
                if (spinner == null) {
                    spinner = new LoadingSpinner();
                    addChild(spinner);
                }
				spinner.visible = true;
				spinner.alpha = 1;
            }
            else {
                if (spinner) {
					spinner.visible = false;
					spinner.alpha = 0;
					removeSpinner();
                }
                else
                    return;
            }
			if(spinner){
				spinner.x = (_width - spinner.width) / 2;
				spinner.y = (_height - spinner.height) / 2;
			}


        }

        private function removeSpinner():void {
            if (spinner) {
                removeChild(spinner);
				spinner = null;
            }
        }

        /**
         * checks to see if there is any new data from the feed
         *
         *
         */
        private function checkDataFreshness():void {

            if (newestEpisodeData != model.getNewestEpisode()) {

                newestEpisodeData = model.getNewestEpisode();
                currentImageData = model.currentImageData;
            }
        }

        private function showNetworkError():void {

            episodeText.text = "Unable to connect to network";
            episodeText.autoSize = TextFieldAutoSize.LEFT;
            episodeNumberText.text = "";
            positionEpisodeText();
        }

    }
}

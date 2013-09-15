package com.litl.tv.view
{
    import com.greensock.TweenLite;
    import com.greensock.easing.*;
    import com.greensock.plugins.AutoAlphaPlugin;
    import com.greensock.plugins.TweenPlugin;
    import com.litl.control.VideoPlayer;
    import com.litl.sdk.enum.View;
    import com.litl.sdk.service.ILitlService;
    import com.litl.skin.LitlColors;
    import com.litl.tv.event.TitleCardEvent;
    import com.litl.tv.model.AppModel;
    import com.litl.tv.model.data.EpisodeData;
    import com.litl.tv.utils.BitmapGrabber;
    import com.litl.tv.utils.StringUtils;
    import com.litl.tv.view.CardView;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.utils.Dictionary;

    public class TitleCard extends Sprite
    {
        public var titleCardBg:Sprite = null;

        public var episodeTitle:String = "";
        public var episodeSeason:String = "";
        public var episodeNumber:String = "";
        public var episodeLength:String = "";
        public var episodeDescription:String = "";

        private var title:TextField = null;
        private var season:TextField = null;
        private var epNumber:TextField = null;
        private var length:TextField = null;
        private var description:TextField = null;
        private var pausedImage:Bitmap = null;
        private var _height:Number;
        private var _width:Number;
        private var runTimeText:TextField = null;

        private static const ELLIPSIS:String = "...";

        private var context:Sprite;
        private var textHolder:Sprite;
        private var currentEpisodeData:EpisodeData;
        protected var model:AppModel;

        public function TitleCard() {
            init();
        }

        /**
         * creates the textFormats
         * creates the textFields
         *
         */
        private function init():void {
            model = AppModel.getInstance();
            TweenPlugin.activate([ AutoAlphaPlugin ]);

            var titleFormat:TextFormat = new TextFormat("CorpoS", 76, LitlColors.BLUE, false);
            var descriptionFormat:TextFormat = new TextFormat("CorpoS", 22, 0xFFFFFF, false);
            var infoFormat:TextFormat = new TextFormat("CorpoS", 24, 0xFFFFFF, false);

            textHolder = new Sprite();
            addChild(textHolder);

            title = new TextField();
            setUpTextField(title, titleFormat, true);

            //season = new TextField();
            //setUpTextField(season, infoFormat);

            epNumber = new TextField();
            setUpTextField(epNumber, infoFormat, false);

            //length = new TextField();
            //setUpTextField(length, infoFormat);

            description = new TextField();
            setUpTextField(description, descriptionFormat, true);

            runTimeText = new TextField();
            setUpTextField(runTimeText, descriptionFormat, true);

        }

        /**
         * creates the titleCardBg
         *
         */
        private function createBg():void {
            titleCardBg = new Sprite();
            titleCardBg.graphics.beginFill(0x000000);
            titleCardBg.graphics.drawRect(0, 0, 768, 432);
            titleCardBg.graphics.endFill();
            titleCardBg.alpha = .75;
            //titleCardBg.visible = false;
            addChild(titleCardBg);
        }

        /**
         * convenience function for setting textFormat properties and adding a textfield to the stage
         *
         */
        private function setUpTextField(textField:TextField, format:TextFormat, wordWrap:Boolean):void {
            textField.multiline = true;
            textField.wordWrap = wordWrap;
            textField.selectable = false;
            //textField.border = true;
            //textField.borderColor = 0xFFFFFF;
            textField.antiAliasType = "advanced";
            textField.gridFitType = "pixel";
            textField.autoSize = TextFieldAutoSize.LEFT;
            textField.defaultTextFormat = format;
            textHolder.addChild(textField);
        }

        /**
         * puts the episode text strings into the appropriate textFields
         *
         */
        public function setText(episodeTitle:String, episodeDescription:String, episodeNumber:String, runTime:String, airDate:Date):void {
            ///currentEpisodeData = model.currentEpisodeData;

            title.width = epNumber.width = description.width = (_width - 320);
            var titleLabel:String = StringUtils.truncate(episodeTitle, 50);
            title.autoSize = TextFieldAutoSize.LEFT;
            title.text = titleLabel;

            // check to see if word wrap is necessary, if not turn off b/c it's causing the text box to resize improperly
            if (title.numLines <= 1) {
                title.wordWrap = false;
            }

            var descriptionLabel:String = StringUtils.truncate(episodeDescription, 250);

            description.autoSize = epNumber.autoSize = TextFieldAutoSize.LEFT;
            description.text = descriptionLabel;

            // check to see if word wrap is necessary, if not turn off b/c it's causing the text box to resize improperly
            if (description.numLines <= 1) {
                description.wordWrap = false;
            }

            var formattedAirDate:String;

            if (airDate) {
                formattedAirDate = airDate.month + "-" + airDate.date + "-" + airDate.fullYear;
            }

            // if there's any runTime text available
            if (formattedAirDate) {
                epNumber.appendText("Aired On " + formattedAirDate);
            }
            else {
                epNumber.appendText("Episode Number " + episodeNumber);
            }

            if ((runTime) && (runTime != "")) {
                epNumber.appendText("  |  " + runTime);
            }

            positionText();

        }

        /**
         * positions the text boxes according to the size of the titleCardBg
         *
         */
        private function positionText():void {
            epNumber.y = Math.round(title.height + 24);
            description.y = Math.round((epNumber.y + epNumber.height) + 20);

        }

        /**
         * resizes the bg and positions the text boxes accordingly
         *
         */
        public function setSize(w:Number, h:Number):void {
            _width = w;
            _height = h;

            if (pausedImage) {
                pausedImage.width = titleCardBg.width;
                pausedImage.height = titleCardBg.height;
            }

        }

        /**
         * sets the x and y position of the this container
         *
         */
        public function move(x:Number, y:Number):void {
            this.x = Math.round(x);
            this.y = Math.round(y);

        }

        /**
         * creates the bitmap image we will use for the title Card
         *
         */
        public function setImage(clip:Sprite):void {

            var capturedImage:Bitmap = BitmapGrabber.snapClip(clip);
            pausedImage = new Bitmap();
            pausedImage = capturedImage;
            this.addChild(pausedImage);
            dispatchEvent(new TitleCardEvent(TitleCardEvent.IMAGE_READY));

        }

        /**
         * animates in the title Card elements
         *
         */
        public function intro():void {

            textHolder.alpha = 0;
            show();
            TweenLite.to(textHolder, 0.65, { autoAlpha: 1, ease: Quart.easeOut });

        }

        /**
         * animates out the title Card elements
         *
         */
        public function outro():void {
            if (pausedImage) {
                this.removeChild(pausedImage);
                pausedImage = null;
            }

            TweenLite.to(textHolder, 0.65, { autoAlpha: 0, ease: Quart.easeOut });

        }

        /**
         * turns off visibility for everything
         *
         */
        public function hide():void {

            titleCardBg.visible = false;
            textHolder.visible = false;

        }

        /**
         * turns on visibility for everything
         *
         */
        public function show():void {

            titleCardBg.visible = true;
            textHolder.visible = true;

        }

    }
}

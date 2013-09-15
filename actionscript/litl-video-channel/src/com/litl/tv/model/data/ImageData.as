package com.litl.tv.model.data
{

    public class ImageData
    {

        public var _cardUrl:String = null;
        public var _backgroundUrl:String = null;
        public var _networkLogoUrl:String = null;

        public function ImageData(backgroundUrl:String, cardUrl:String, networkLogoUrl:String) {

            this._backgroundUrl = backgroundUrl;
            this._cardUrl = cardUrl;
            this._networkLogoUrl = networkLogoUrl;
        }

    }
}

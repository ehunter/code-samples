package com.litl.tv.model.data
{
    import com.adobe.crypto.MD5;
    import com.litl.helpers.slideshow.IHashable;
    import com.litl.tv.utils.StringUtils;

    import flash.utils.Dictionary;

    public class EpisodeData implements IHashable
    {

        public var _title:String = "";
        public var _thumbnailUrl:String = "";
        public var _shortDescription:String = "";
        public var _longDescription:String = "";
        public var _number:String = "";
        public var _videoUrl:String = "";
        public var _videoWidth:Number = 0;
        public var _videoHeight:Number = 0;
        public var _runTime:String = "";
        public var _airDate:Date = null;
        public var id:String;

        public function EpisodeData(title:String, shortDescription:String, longDescription:String, number:String, videoUrl:String, thumbnailUrl:String, videoWidth:Number, videoHeight:Number, runTime:String, airDate:Date) {

            this._title = title;
            this._thumbnailUrl = thumbnailUrl;
            this._shortDescription = shortDescription;
            this._number = number;
            this._videoUrl = videoUrl;
            this._videoWidth = videoWidth;
            this._videoHeight = videoHeight;
            this._longDescription = longDescription;
            this._runTime = runTime;
            this._airDate = airDate;

        }

        public function getEpisodeNumber():Number {
            var episodeNumber:Number = new Number(this._number);
            return episodeNumber;
        }

        public function getAirDateTime():Number {

            var airDate:Number = new Number(_airDate.time);
            return airDate;
        }

        public function hash():String {
            return (_videoUrl && _videoUrl.length > 0) ? MD5.hash(_videoUrl) : MD5.hash(_airDate ? (_airDate.toString() + _title) : _title);
        }

    }
}

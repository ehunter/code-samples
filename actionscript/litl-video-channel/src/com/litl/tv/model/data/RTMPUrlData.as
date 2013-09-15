package com.litl.tv.model.data
{

	import com.litl.tv.utils.StringUtils;
    public class RTMPUrlData
    {
        private var _baseUrl:String = "";
        private var _videoUrl:String = "";
        private var _validRTMPUrl:String = "";
        private static var MP4_HASH:String = "mp4:"

        public function RTMPUrlData() {
        }

        public function get validRTMPUrl():String {
            return _validRTMPUrl;
        }

        /**
         *  Converts two seperate urls to an rtmp url by adding an 'mp4:' between them
         *
         *  @param baseUrl	the base url of the fms server
         *  @return			the url of the video on the fms server
         *  @langversion	ActionScript 3.0
         *  @playerversion	9.0
         */
        public function setValidRTMPUrl(baseUrl:String, videoUrl:String):void {

			var lowerCaseVideoUrl:String = videoUrl.toLowerCase();

			switch (true) {
				case StringUtils.contains(lowerCaseVideoUrl, "flv"):
					// for streaming flv files we need to remove the .flv extension
					_validRTMPUrl = baseUrl + StringUtils.remove(videoUrl, ".flv");
					break;
				case StringUtils.contains(lowerCaseVideoUrl, "mp4"):
					// for streaming mp4 files we need to add an mp4: hash and keep the .mp4 extension
					_validRTMPUrl = baseUrl + MP4_HASH + videoUrl;
					break;
				default:
					//throw new Error("RTMPUrlData: Unknown format");
					break;

			}

        }

        public function get videoUrl():String {
            return _videoUrl;
        }

        public function set videoUrl(value:String):void {
            _videoUrl = value;
        }

        public function get baseUrl():String {
            return _baseUrl;
        }

        public function set baseUrl(value:String):void {
            _baseUrl = value;
        }

    }
}

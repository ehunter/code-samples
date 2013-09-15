package com.litl.tv.utils
{
    import com.litl.tv.event.SMILParserEvent;
    import com.litl.tv.model.data.RTMPUrlData;

    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;

    public class SMILParser extends Sprite
    {

        private var baseUrl:String = "";
        private var videoUrl:String = "";
        private var loader:URLLoader = new URLLoader();

        public function SMILParser() {
        }

        public function retrieveSMIL(url:String):void {

            var request:URLRequest = new URLRequest(url);

            if (request != null) {
                var loader:URLLoader = new URLLoader();
                //loader.dataFormat = URLLoaderDataFormat.VARIABLES;
                loader.addEventListener(Event.COMPLETE, onLoadComplete);
                loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
                //loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, doHttpStatus);
                //loader.addEventListener(ProgressEvent.PROGRESS, handleProgress);
                //loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, doSecurityError);
                loader.load(request);
            }

        }

        private function onLoadComplete(evt:Event):void {
            loader.removeEventListener(Event.COMPLETE, onLoadComplete);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
            var xmlLoader:URLLoader = URLLoader(evt.target);
            var feedData:XML = new XML(xmlLoader.data);

            parseHead(feedData);
            parseBody(feedData);

            if (!StringUtils.contains(videoUrl, "NoAccess.rm")) {
                trace("videoUrl " + videoUrl)
                constructValidUrl();
            }
            else {
                dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
            }

        }

        /**
         *  parses the head node of the smil file
         */
        private function parseHead(xml:XML):void {
            var ns:Namespace = xml.namespace();
            var head:XMLList = xml..ns::head;

            if (head.length() > 0) {
                baseUrl = head.ns::meta.@base;
            }
        }

        /**
         *  parses the body node of the smil file
         */
        private function parseBody(xml:XML):void {
            var ns:Namespace = xml.namespace();
            var body:XMLList = xml..ns::body;
            var children:XMLList = body.children();

            // The <body> tag is required
            if (body.length() <= 0) {

            }
            else {

                for (var i:uint = 0; i < children.length(); i++) {

                    switch (children.nodeKind()) {
                        case "element":

                            switch (children.localName()) {
                                case "par":
                                    videoUrl = body.ns::par.ns::ref.@src;
                                    break;
                                case "ref":
                                    videoUrl = body.ns::ref.@src;
                                    break;
                            }
                    }

                }
            }
        }

        /**
         *
         */
        private function constructValidUrl():void {
            var rtmpUrlData:RTMPUrlData = new RTMPUrlData();

            var validVideoUrl:String;

            if ((videoUrl != "") || (baseUrl != "")) {
                if (StringUtils.contains(videoUrl, "http")) {
                    validVideoUrl = baseUrl + videoUrl;
                }
                else {
                    rtmpUrlData.setValidRTMPUrl(baseUrl, videoUrl);
                    validVideoUrl = rtmpUrlData.validRTMPUrl;

                }

                dispatchEvent(new SMILParserEvent(SMILParserEvent.PARSE_COMPLETE, validVideoUrl));
            }
            else {
                dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR));
            }
        }

        /**
         * onError
         * Called when there was a communication error with the XML service
         */
        public function onIOError(event:IOErrorEvent):void {
            //ioError = true;
            // we need to degrade here
            dispatchEvent(event.clone());
        }

    }
}

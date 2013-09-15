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
package com.litl.skin
{
    import com.litl.event.StyleSheetLoadEvent;

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.text.StyleSheet;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;

    /**
     * Dispatched when a css file has completed loading after a call to loadStylesheet().
     */
    [Event(name="complete", type="com.litl.event.StyleSheetLoadEvent")]

    /**
     * <p>Singleton StyleManager instance that all litl controls use.
     * Each class that extends ControlBase will ask StyleManager to look up styles corresponding
     * to its class name, and any styles corresponding to its <i>styleName</i> property.</p>
     * <p>You can add CSS files to the StyleManager with the <i>loadStylesheet</i> method, or you can
     * add css files embedded with the Embed tag with the <i>addEmbeddedStyleSheet</i> method.
     * Alternatively, you can add css diretly as a string with the <i>addCSS</i> method.</p>
     * <p>Note that if you are loading a css file externally, you should wait for it to complete before
     * creating any litl controls. The class will dispatch a StyleSheetLoadEvent when loading is complete.</p>
     * <p>Any skin classes that you define in your CSS must be compiled into your swf.</p>
     * @author litl
     * @see com.litl.skin.DefaultSkin
     * @example
     * <listing version="3.0">
     * // myStyles.css
     * MyControl
     * {
     *     padding: 30;
     * }
     *
     * .myStyleName
     * {
     *     color: #ffffff;
     * }
     *
     * // Any instances of 'MyControl' will have their padding style set to 30.
     * // You can retrieve this value inside 'MyControl' with 'myStyles.padding', or 'getStyle("padding")'
     * // Any instances of 'MyControl' that have their styleName property set to ".myStyleName"
     * // will also have their color style set to 0xffffff.
     * </listing>
     *
     */
    public class StyleManager extends EventDispatcher
    {
        private static var _instance:StyleManager;

        private var stylesheets:Array;
        private var loaders:Dictionary;

        /** Constructor. */
        public function StyleManager(singleton:SingletonEnforcer = null) {
            if (singleton == null) {
                throw new Error("Use StyleManager.getInstance() instead of new StyleManager()");
            }

            stylesheets = new Array();
            loaders = new Dictionary();
        }

        /** Get the global instance of StyleManager. */
        public static function getInstance():StyleManager {
            if (_instance == null) {
                _instance = new StyleManager(new SingletonEnforcer());
                _instance.addEmbeddedStylesheet(DefaultSkin.getSkinCSS());
            }

            return _instance;
        }

        /**
         * <p>Load a css file from a url and add it to the global styles.
         * You should wait for the stylesheet to finish loading before continuing with initialization.</p>
         * <p>Note: Embed directives inside the css will not work.</p>
         * @param url   The url of the css file to load.
         * @example
         * <listing version="3.0">
         * StyleManager.getInstance().addEventListener(StyleSheetLoadEvent.COMPLETE, onCSSLoaded, false, 0, true);
         * StyleManager.getInstance().loadStylesheet("myStyles.css");
         *
         * // Elsewhere in your class:
         * private function onCSSLoaded(e:StyleSheetLoadEvent):void {
         *          StyleManager.getInstance().removeEventListener(StyleSheetLoadEvent.COMPLETE, onCSSLoaded);
         *          // Continue with initialization..
         * }
         * </listing>
         */
        public function loadStylesheet(url:String):void {

            var urlLoader:URLLoader;
            urlLoader.dataFormat = URLLoaderDataFormat.TEXT;

            loaders[urlLoader] = url;

            urlLoader.addEventListener(Event.COMPLETE, onStylesheetLoaded, false, 0, true);
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onStylesheetIOError, false, 0, true);
            urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onStylesheetSecurityError, false, 0, true);
            urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStylesheetHTTPStatus, false, 0, true);
            urlLoader.load(new URLRequest(url));
        }

        /**
         * <p>Add a css file that was embedded in the swf with the Embed tag.
         * This allows you to compile css with your swf, without having to load it externally.</p>
         * <p>Note: Embed directives inside the css will not work.</p>
         * @param embeddedCSSClass      The class of a css file embedded in the swf.
         * @example
         * <listing version="3.0">
         *
         * // Embed the css file in your swf.
         * Embed(source="myStyles.css", mimeType="application/octet-stream")]
         * private var stylesCSS:Class;
         *
         * // Then in your application initialization:
         * StyleManager.getInstance().addEmbeddedStylesheet(stylesCSS);
         *
         * </listing>
         */
        public function addEmbeddedStylesheet(embeddedCSSClass:Class):void {
            try {
                var cssba:ByteArray = new embeddedCSSClass() as ByteArray;
                var css:String = cssba.readUTFBytes(cssba.length);
                var ss:StyleSheet = new LitlStyleSheet();
                ss.parseCSS(css);
            }
            catch (err:Error) {
                throw new Error("Error adding embedded CSS: " + err.message);
            }
            addStylesheet(ss);
        }

        /**
         * Add a css string to the styles.
         * @param cssString     A string representation of some CSS styles.
         * @example
         * <listing version="3.0">
         * StyleManager.getInstance().addCSS(".myStyle { color: #ffffff }");
         * </listing>
         */
        public function addCSS(cssString:String):void {
            var ss:StyleSheet = new LitlStyleSheet();
            ss.parseCSS(cssString);

            addStylesheet(ss);
        }

        /**
         * Add a StyleSheet to use when performing style lookups.
         * @param stylesheet A StyleSheet instance to add.
         */
        public function addStylesheet(stylesheet:StyleSheet):void {
			if (!(stylesheet in stylesheets))
                stylesheets.push(stylesheet);
        }

        /**
         * Remove a StyleSheet from the list of StyleSheets that the StyleManager uses to lookup styles.
         * @param stylesheet    The StyleSheet instance to remove.
         *
         */
        public function removeStylesheet(stylesheet:StyleSheet):void {
            var i:int = stylesheets.length;

            while (--i >= 0)
                if (stylesheets[i] == stylesheet)
                    stylesheets.splice(i, 1);
        }

        /**
         * Lookup a particular style from the list of StyleSheets.
         * The most recently added style will be used before previously added styles.
         * @param name  The name of the style to lookup.
         * @return A Style instance containing the style properties, or an empty Style if none was found.
         *
         */
        public function getStyle(name:String):Style {
            var i:int = stylesheets.length;

            // Work backwards through the list of stylesheets.
            while (--i >= 0) {
                var o:Object = StyleSheet(stylesheets[i]).getStyle(name);

                if (o != null) {
                    if (o is Style)
                        return (o as Style).clone();
                    else
                        return convertStyle(o);
                }

            }

            return new Style();
        }

        /** @private */
        protected function convertStyle(o:Object):Style {
            var oo:Style = new Style();

            for (var key:String in o) {
                oo[key] = o[key];

                if (String(oo[key]).indexOf("#") == 0)
                    oo[key] = parseInt(String(oo[key]).substr(1), 16);
                else if (String(oo[key]).indexOf("0x") == 0)
                    oo[key] = parseInt(String(oo[key]).substr(2), 16);
            }

            return oo;
        }

        /** @private */
        protected function onStylesheetLoaded(e:Event):void {
            var str:String = URLLoader(e.target).data as String;
            var sheet:StyleSheet = new LitlStyleSheet();

            try {
                sheet.parseCSS(str);
            }
            catch (err:Error) {
                sheet = null;
            }

            if (sheet)
                addStylesheet(sheet);

            var url:String = loaders[e.target] as String;

            removeLoader(e.target as URLLoader);

            dispatchEvent(new StyleSheetLoadEvent(StyleSheetLoadEvent.COMPLETE, url));
        }

        /** @private */
        protected function onStylesheetIOError(e:IOErrorEvent):void {
            removeLoader(e.target as URLLoader);
        }

        /** @private */
        protected function onStylesheetSecurityError(e:SecurityErrorEvent):void {
            removeLoader(e.target as URLLoader);
        }

        /** @private */
        protected function onStylesheetHTTPStatus(e:HTTPStatusEvent):void {
            if (e.status >= 400) {
                removeLoader(e.target as URLLoader);
            }
        }

        /** @private */
        protected function removeLoader(loader:URLLoader):void {
            loader.removeEventListener(Event.COMPLETE, onStylesheetLoaded, false);
            loader.removeEventListener(IOErrorEvent.IO_ERROR, onStylesheetIOError, false);
            loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onStylesheetSecurityError, false);
            loader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, onStylesheetHTTPStatus, false);
            delete loaders[loader];
        }
    }
}

/**
 * Internal class to prevent external initialization of StyleManager.
 * @author litl
 * @private
 */
internal class SingletonEnforcer
{
}
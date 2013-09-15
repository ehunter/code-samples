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
    import flash.text.StyleSheet;
    import flash.utils.Dictionary;

    /**
     * Slightly different css parser than flash.text.StyleSheet
     * TODO: Doesn't handle Embed, probably other stuff too..
     * @author litl
     */
    public class LitlStyleSheet extends StyleSheet
    {
        protected var litlStyles:Dictionary = new Dictionary();

        override public function setStyle(styleName:String, styleObject:Object):void {
            litlStyles[styleName] = styleObject;
        }

        override public function getStyle(styleName:String):Object {
            return litlStyles[styleName];
        }

        override public function parseCSS(str:String):void {

            var css:String = str;
            // Remove comments..
            css = css.replace(/\/\*.*?\*\//gms, "");
            css = css.replace(/\/\/.*$/gm, "");
            // Grab the rules by matching the brackets
            var arr:Array = css.match(/(.*?{.*?})/gms);

            var finalRules:Array = [];

            for (var i:int = 0; i < arr.length; i++) {
                var oo:Style = new Style();
                var parts:Array = arr[i].split("{");
                // Grab the selector, and the rules.
                var sel:String = parts[0];
                // Trim surrounding whitespace
                sel = sel.replace(/^\s+|\s+$/g, "");
                // Condense internal whitespace
                sel = sel.replace(/(\S\s)\s+/, "$1");

                var styles:String = String(parts[1]);
                // Match name:value pairs
                var b:Array = styles.match(/[\w-]+\s*?:\s*?.*?[\r\n;}]$/gms);

                for (var j:int = 0; j < b.length; j++) {
                    // Trim spaces, closing brackets, and semi colons, then split at the colon:
                    var styleArr:Array = (b[j].replace(/^\s+|\s+$|[};]/gms, "")).split(":");
                    // Trim out all spaces from the name.
                    var styleName:String = String(styleArr[0]).replace(/\s/, "");
                    // Trim spaces from the value.
                    var styleValue:String = String(styleArr[1]).replace(/^\s+|\s+$/g, "");
                    // TODO: split multiple values into an array

                    oo[styleName] = convertType(styleValue);
                }
                finalRules.push({ name: sel, styles: oo });
            }

            for (var k:int = 0; k < finalRules.length; k++) {
                setStyle(finalRules[k].name, finalRules[k].styles);
            }

        }

        private static function convertType(str:String):* {
            // Remove px/pt/em from any numbers:
            str = str.replace(/(\d+?)\s*?(px|pt|em)/, "$1");
            // Convert #color values to a hex number
            str = str.replace(/#([\dabcdefABCDEF]+?)/g, "0x$1");

            if (!isNaN(Number(str)))
                return Number(str);
            else {
                if (str == "true")
                    return true;
                else if (str == "false")
                    return false;
                else
                    return str.replace(/^"+|"+$/gms, ""); // remove start and end quotes from strings
            }
        }
    }
}
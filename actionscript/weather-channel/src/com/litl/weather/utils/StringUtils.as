package com.litl.weather.utils
{

    /**
     * @author mkeefe
     */
    public class StringUtils
    {

        public static function extractZip(s:String):String {
            // Look for paren
            if (s.indexOf('(') != -1) {
                return s.substring(s.indexOf('(') + 1, (s.length - 1));
            }
            return s;
        }

        public static function removeZipInParenthesis(s:String):String {
            // Look for paren
            if (s.indexOf('(') != -1) {
                s = s.substr(0, s.indexOf('('));

                // Remove trailing space
                if (s.substring(s.length - 1) == " ") {
                    s = s.substring(0, s.length - 1);
                }

            }

            return s;
        }

        /**
         *	Returns a string truncated to a specified length with optional suffix
         *	@param p_string The string.
         *	@param p_len The length the string should be shortend to
         *	@param p_suffix (optional, default=...) The string to append to the end of the truncated string.
         *	@returns String
         */
        public static function truncate(p_string:String, p_len:uint, p_suffix:String = "..."):String {
            if (p_string == null) {
                return '';
            }
            p_len -= p_suffix.length;
            var trunc:String = p_string;

            if (trunc.length > p_len) {
                trunc = trunc.substr(0, p_len);

                if (/[^\s]/.test(p_string.charAt(p_len))) {
                    trunc = trimRight(trunc.replace(/\w+$|\s+$/, ''));
                }
                trunc += p_suffix;
            }

            return trunc;
        }

        /**
         *	Removes whitespace from the end (right-side) of the specified string.
         *	@param p_string The String whose ending whitespace will be removed.
         *	@returns String
         *
         */
        public static function trimRight(p_string:String):String {
            if (p_string == null) {
                return '';
            }
            return p_string.replace(/\s+$/, '');
        }

        /**
         *	Returns everything after the last occurence of the provided character in p_string.
         *
         *	@param p_string The string.
         *
         *	@param p_char The character or sub-string.
         *
         *	@returns String
         *
         * 	@langversion ActionScript 3.0
         *	@playerversion Flash 9.0
         *	@tiptext
         */
        public static function afterLast(p_string:String, p_char:String):String {
            if (p_string == null) {
                return '';
            }
            var idx:int = p_string.lastIndexOf(p_char);

            if (idx == -1) {
                return p_string;
            }
            idx += p_char.length;
            return p_string.substr(idx);
        }

        /**
         *	Returns everything before the first occurrence of the provided character in the string.
         *
         *	@param p_string The string.
         *
         *	@param p_begin The character or sub-string.
         *
         *	@returns String
         *
         * 	@langversion ActionScript 3.0
         *	@playerversion Flash 9.0
         *	@tiptext
         */
        public static function beforeFirst(p_string:String, p_char:String):String {
            if (p_string == null) {
                return '';
            }
            var idx:int = p_string.indexOf(p_char);

            if (idx == -1) {
                return p_string;
            }
            return p_string.substr(0, idx);
        }

        /**
         *	Returns everything after the first occurance of p_start and before
         *	the first occurrence of p_end in p_string.
         *
         *	@param p_string The string.
         *
         *	@param p_start The character or sub-string to use as the start index.
         *
         *	@param p_end The character or sub-string to use as the end index.
         *
         *	@returns String
         *
         * 	@langversion ActionScript 3.0
         *	@playerversion Flash 9.0
         *	@tiptext
         */
        public static function between(p_string:String, p_start:String, p_end:String):String {
            var str:String = '';

            if (p_string == null) {
                return str;
            }
            var startIdx:int = p_string.indexOf(p_start);

            if (startIdx != -1) {
                startIdx += p_start.length; // RM: should we support multiple chars? (or ++startIdx);
                var endIdx:int = p_string.indexOf(p_end, startIdx);

                if (endIdx != -1) {
                    str = p_string.substr(startIdx, endIdx - startIdx);
                }
            }

            if (str != '') {
                return str;
            }
            else {
                return p_string;
            }
        }

        /**
         *	Determines whether the specified string contains any instances of p_char.
         *
         *	@param p_string The string.
         *
         *	@param p_char The character or sub-string we are looking for.
         *
         *	@returns Boolean
         *
         * 	@langversion ActionScript 3.0
         *	@playerversion Flash 9.0
         *	@tiptext
         */
        public static function contains(p_string:String, p_char:String):Boolean {
            if (p_string == null) {
                return false;
            }
            return p_string.indexOf(p_char) != -1;
        }

    }
}

package com.litl.util
{

    /**
     * ISO8601 conversion code based on code by Brooks Andrus.
     */
    public final class DateUtils
    {
        public static const MILLISECOND:Number = 1;
        public static const SECOND:Number = MILLISECOND * 1000;
        public static const MINUTE:Number = SECOND * 60;
        public static const HOUR:Number = MINUTE * 60;
        public static const DAY:Number = HOUR * 24;
        public static const WEEK:Number = DAY * 7;
        private static const numberWords:Array = [ "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten" ];
        private static const months:Array = [ "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec" ];
        private static const timezoneOffsets:Object =
            { UT: 0, UTC: 0, GMT: 0, EST: -5, EDT: -4, CST: -6, CDT: -5, MST: -7, MDT: -6, PST: -8, PDT: -7, Z: 0, A: -1, M: -12, N: 1, Y: 12 };

        public static function parseISO8601(str:String):Date {
            //first strip all non-numerals from the String ( convert all extended dates to basic)
            str = str.replace(/-|:|T|Z/g, "");

            var date:Date = parseBasicDate(str.substr(0, 8));
            date = parseBasicTime(str.substr(8, 6), date);

            return date;
        }

        public static function parseRFC822(str:String):Date {
            var arr:Array = str.split(" ");
            var timezone:String = arr[arr.length - 1];

            if (timezone.search(/\d/) < 0) {
                var offsetHours:Number = timezoneOffsets[timezone];

                if (!isNaN(offsetHours)) {
                    var offsetStr:String = offsetHours.toString();

                    if (offsetHours < 0 && offsetStr.length == 2)
                        offsetStr = offsetStr.substr(0, 1) + "0" + offsetStr.substr(1);
                    else if (offsetHours >= 0 && offsetStr.length == 1)
                        offsetStr = "+0" + offsetStr;

                    str = str.replace(new RegExp(timezone), "GMT" + offsetStr + "00");

                }
            }
            var date:Date = new Date(str);

            return date;
        }

        public static function getElapsedTime(firstDate:Date, secondDate:Date = null):String {
            if (secondDate == null)
                secondDate = new Date();

            var relativeTimeString:String;

            var years:Number = elapsedYears(firstDate, secondDate);
            var months:Number = elapsedMonths(firstDate, secondDate);
            var days:Number = elapsedDays(firstDate, secondDate);
            var hours:Number = elapsedHours(firstDate, secondDate);
            var minutes:Number = elapsedMinutes(firstDate, secondDate);
            var seconds:Number = elapsedSeconds(firstDate, secondDate);

            if (years < 1) {
                if (months < 1) {
                    if (days < 1) {
                        if (hours < 1) {
                            if (minutes < 1) {
                                relativeTimeString = "A few seconds ago";
                            }
                            else {
                                relativeTimeString = numberToWord(minutes) + " minute" + (minutes > 1 ? "s" : "") + " ago";
                            }
                        }
                        else {
                            relativeTimeString = numberToWord(hours) + " hour" + (hours > 1 ? "s" : "") + " ago";
                        }
                    }
                    else if (days == 1) {
                        relativeTimeString = "Yesterday";
                    }
                    else if (days % 7 == 0) {
                        relativeTimeString = numberToWord(days / 7) + " week" + (days / 7 > 1 ? "s" : "") + " ago";
                    }
                    else {
                        relativeTimeString = numberToWord(days) + " days ago";
                    }
                }
                else {
                    relativeTimeString = numberToWord(months) + " month" + (months > 1 ? "s" : "") + " ago";
                }
            }
            else {
                relativeTimeString = numberToWord(years) + " year" + (years > 1 ? "s" : "") + " ago";
            }

            // Flake out if there was some error, probably because the input date was invalid.
            if (relativeTimeString.search(/NaN/) >= 0)
                relativeTimeString = "";

            return relativeTimeString;
        }

        private static function parseBasicDate(val:String, date:Date = null):Date {
            if (date == null) {
                date = new Date();
            }

            date.setUTCFullYear(convertYear(val), convertMonth(val), convertDate(val));

            return date;
        }

        private static function parseBasicTime(val:String, date:Date = null):Date {
            if (date == null) {
                date = new Date();
            }

            date.setUTCHours(convertHours(val), convertMinutes(val), convertSeconds(val));

            return date;
        }

        private static function convertYear(val:String):int {
            val = val.substr(0, 4);
            return parseInt(val);
        }

        /**
         * assumes an 8601 basic date string (8 characters YYYYMMDD)
         */
        private static function convertMonth(val:String):int {
            val = val.substr(4, 2);
            var y:int = parseInt(val) - 1; // months are zero indexed in Date objects so we need to decrement
            return y;
        }

        /**
         * assumes an 8601 basic date string (8 characters YYYYMMDD)
         */
        private static function convertDate(val:String):int {
            val = val.substr(6, 2);

            return parseInt(val);
        }

        /**
         * assumes a 8601 basic UTC time string (6 characters HHMMSS)
         */
        private static function convertHours(val:String):int {
            val = val.substr(0, 2);

            return parseInt(val);
        }

        /**
         * assumes a 8601 basic UTC time string (6 characters HHMMSS)
         */
        private static function convertMinutes(val:String):int {
            val = val.substr(2, 2);

            return parseInt(val);
        }

        /**
         * assumes a 8601 basic UTC time string (6 characters HHMMSS)
         */
        private static function convertSeconds(val:String):int {
            val = val.substr(4, 2);

            return parseInt(val);
        }

        public static function addToDate(originalDate:Date, yearsToAdd:Number = 0, monthsToAdd:Number = 0, daysToAdd:Number = 0, hoursToAdd:Number = 0, minutesToAdd:Number = 0, secondsToAdd:Number = 0, millisecondsToAdd:Number = 0):Date {
            var newDate:Date = new Date(originalDate.getTime());
            newDate.fullYear += yearsToAdd;
            newDate.month += monthsToAdd;
            newDate.date += daysToAdd;
            newDate.hours += hoursToAdd;
            newDate.minutes += minutesToAdd;
            newDate.seconds += secondsToAdd;
            newDate.milliseconds += millisecondsToAdd;
            return newDate;
        }

        private static function calculateElapsedDate(firstDate:Date, secondDate:Date = null):Date {
            if (secondDate == null) {
                secondDate = new Date();
            }
            return new Date(secondDate.getTime() - firstDate.getTime());
        }

        private static function elapsedMilliseconds(firstDate:Date, secondDate:Date = null, isRelative:Boolean = false):Number {
            if (isRelative) {
                return calculateElapsedDate(firstDate, secondDate).getUTCMilliseconds();
            }
            else {
                return (secondDate.getTime() - firstDate.getTime());
            }
        }

        private static function elapsedSeconds(firstDate:Date, secondDate:Date = null, isRelative:Boolean = false):Number {
            if (isRelative) {
                return (calculateElapsedDate(firstDate, secondDate).getUTCSeconds());
            }
            else {
                return Math.floor(elapsedMilliseconds(firstDate, secondDate) / SECOND);
            }
        }

        private static function elapsedMinutes(firstDate:Date, secondDate:Date = null, isRelative:Boolean = false):Number {
            if (isRelative) {
                return (calculateElapsedDate(firstDate, secondDate).getUTCMinutes());
            }
            else {
                return Math.floor(elapsedMilliseconds(firstDate, secondDate) / MINUTE);
            }
        }

        private static function elapsedHours(firstDate:Date, secondDate:Date = null, isRelative:Boolean = false):Number {
            if (isRelative) {
                return (calculateElapsedDate(firstDate, secondDate).getUTCHours());
            }
            else {
                return Math.floor(elapsedMilliseconds(firstDate, secondDate) / HOUR);
            }
        }

        private static function elapsedDays(firstDate:Date, secondDate:Date = null, isRelative:Boolean = false):Number {
            if (isRelative) {
                return (calculateElapsedDate(firstDate, secondDate).getUTCDate());
            }
            else {
                return Math.floor(elapsedMilliseconds(firstDate, secondDate) / DAY);
            }
        }

        private static function elapsedMonths(firstDate:Date, secondDate:Date = null, isRelative:Boolean = false):Number {
            if (isRelative) {
                return (calculateElapsedDate(firstDate, secondDate).getUTCMonth());
            }
            else {
                return (calculateElapsedDate(firstDate, secondDate).getUTCMonth() + elapsedYears(firstDate, secondDate) * 12);
            }
        }

        private static function elapsedYears(firstDate:Date, secondDate:Date = null):Number {
            return (calculateElapsedDate(firstDate, secondDate).getUTCFullYear() - 1970);
        }

        private static function numberToWord(val:Number, capitalize:Boolean = true):String {
            if (val < 11 && val >= 0) {
                var str:String = numberWords[val];
                return capitalize ? (str.substr(0, 1).toLocaleUpperCase() + str.substr(1)) : str;
            }
            else
                return val.toString();
        }

    }
}


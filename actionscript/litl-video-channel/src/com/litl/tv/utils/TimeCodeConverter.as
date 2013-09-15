package com.litl.tv.utils
{
    public class TimeCodeConverter
    {
        public function TimeCodeConverter()
        {
        }

        /**
         * Converts the amount of milliseconds into a string based time code.
         * @param	milliseconds
         * @param	delimiter
         * @param 	withHours
         * @return	The time code as a string.
         */
        public static function millisecondsToTimeCode( milliseconds:Number, delimeter:String = ":", withHours:Boolean = false ):String
        {
                var posHours:Number = Math.floor( milliseconds / 1000 / 60 / 60 );
                var posMins:Number = Math.floor( milliseconds / 1000 / 60 );
                var posSecs:Number = Math.round( milliseconds / 1000 % 60 );
                
                if( posSecs >= 60 )
                {
                        posSecs = 0;
                        posMins++;
                }
                
                if( posMins >= 60 )
                {
                        posMins = 0;
                        posHours++;
                }
                
                var timeHours:String = ( posHours < 10 ) ? "0" + posHours.toString() : posHours.toString();
                var timeMins:String = ( posMins < 10 ) ? "0" + posMins.toString() : posMins.toString();
                var timeSecs:String = ( posSecs < 10 ) ? "0" + posSecs.toString() : posSecs.toString();
                var result:String = timeMins + delimeter + timeSecs;
                
                if( withHours )
                {
                        result = timeHours + delimeter + result;
                }
                
                return result;
        }

        public static function formatTime(seconds:Number):String {
            seconds = Math.round(isNaN(seconds) ? 0 : seconds);
            var hours:Number = Math.floor(seconds / 3600);
            return (hours > 0 ? hours + ":" : "")
            + (seconds % 3600 < 600 ? "0" : "") + Math.floor(seconds % 3600 / 60)
                + ":" + (seconds % 60 < 10 ? "0" : "") + seconds % 60;
        }

    }
}

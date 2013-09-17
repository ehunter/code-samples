package com.litl.weather.view
{
    import flash.display.MovieClip;

    /**
     * @author mkeefe
     */
    public class Animations extends MovieClip
    {

        public static var BLIZZARD:String = "Blizzard";
        public static var FOG:String = "Fog";
        public static var LIGHT_FOG:String = "Fog_Light";
        public static var RAIN_AND_HAIL:String = "Hail_Rain";
        public static var HAIL:String = "Hail";
        public static var HAZY:String = "Haze";
        public static var CLOUDY:String = "Heavy_Cloud";
        public static var LIGHTNING:String = "Lightning";
        public static var CLEAR_NIGHT:String = "Night_Clear";
        public static var PARTLY_CLOUDY_NIGHT:String = "Night_Cloudy";
        public static var CLOUDY_NIGHT:String = "Night_Heavy_Cloud";
        public static var RAIN_NIGHT:String = "Night_Rain";
        public static var SNOW_NIGHT:String = "Night_Snow";
        public static var SNOW_RAIN_AND_HAIL:String = "Rain_Hail_Snow";
        public static var HEAVY_RAIN:String = "Rain_Heavy";
        public static var FREEZING_RAIN:String = "Rain_Ice";
        public static var LIGHT_RAIN:String = "Rain_Light";
        public static var WINTRY_MIX:String = "Rain_Snow";
        public static var RAIN:String = "Rain";
        public static var HEAVY_SNOW:String = "Snow_Heavy";
        public static var WINDY_SNOW:String = "Snow_Wind";
        public static var SNOW:String = "Snow";
        public static var SUNNY_AND_CLEAR:String = "Sunny_Clear";
        public static var PARTLY_CLOUDY:String = "Sunny_Cloudy";
        public static var WINDY:String = "Windy";

        public function Animations() {
        }

        public static function getColor(animation:String):Number {

            switch (animation) {

                case RAIN:
                case HEAVY_RAIN:
                case FREEZING_RAIN:
                case HAIL:
                case RAIN_AND_HAIL:
                case SNOW_RAIN_AND_HAIL:
                case LIGHTNING:
                case WINTRY_MIX:
                case CLEAR_NIGHT:
                case PARTLY_CLOUDY_NIGHT:
                case CLOUDY_NIGHT:
                case RAIN_NIGHT:
                case SNOW_NIGHT:
                    return 0x000000; // night

                case SNOW:
                case BLIZZARD:
                case HEAVY_SNOW:
                case WINDY_SNOW:
                case HAZY:
                case FOG:
                case LIGHT_FOG:
                    return 0xA2AAA8; // foggy

                case LIGHT_RAIN:
                    return 0x343C49; // overcast

                case WINDY:
                case CLOUDY:
                case PARTLY_CLOUDY:
                case SUNNY_AND_CLEAR:
                default:
                    return 0x729BC4; // sky blue

            }
        }

        public static function getTextColor(animation:String):uint {

            switch (animation) {

                case RAIN:
                case HEAVY_RAIN:
                case FREEZING_RAIN:
                case HAIL:
                case RAIN_AND_HAIL:
                case SNOW_RAIN_AND_HAIL:
                case LIGHTNING:
                case WINTRY_MIX:
                case CLEAR_NIGHT:
                case PARTLY_CLOUDY_NIGHT:
                case CLOUDY_NIGHT:
                case RAIN_NIGHT:
                case SNOW_NIGHT:

                case LIGHT_RAIN:
                    return 0xFFFFFF;

                // foggy
                case SNOW:
                case BLIZZARD:
                case HEAVY_SNOW:
                case WINDY_SNOW:
                case HAZY:
                case FOG:
                case LIGHT_FOG:

                // sky blue
                case WINDY:
                case CLOUDY:
                case PARTLY_CLOUDY:
                case SUNNY_AND_CLEAR:
                default:
                    return 0x000000;

            }
        }

        public static function getSWF(weatherDescription:String, isDay:Boolean):String {
            return (getFile("swf/", weatherDescription, ".swf", isDay));
        }

        public static function getImage(weatherDescription:String, isDay:Boolean, isFiveDay:Boolean = false):String {
            var path:String = (isFiveDay) ? "jpg/5day_slices/" : "jpg/";
            var ext:String = (isFiveDay) ? ".png" : ".jpg";
            return (getFile(path, weatherDescription, ext, isDay));
        }

        public static function getFile(path:String, weatherDescription:String, ext:String, isDay:Boolean):String {

            switch (weatherDescription) {
                case "Thunderstorms":
                case "Storms":
                case "Moderate Thunderstorm":
                    return path + LIGHTNING + ext;
                case "Frozen Mix":
                    return path + WINTRY_MIX + ext;
                case "Freezing Rain":
                    return path + RAIN_AND_HAIL + ext;
                case "Freezing Rain":
                    return path + FREEZING_RAIN + ext;
                case "Drizzle":
                case "Light Rain":
                    return path + LIGHT_RAIN + ext;
                case "Rain":
                case "Showers":
                case "Rain Shower":
                    return path + RAIN + ext;
                case "Snow":
                case "Flurries":
                case "Light Snow":
                case "Snow Shower":
                    return path + SNOW + ext;
                case "Heavy Snow":
                    return path + HEAVY_SNOW + ext;
                case "Sleet":
                    return path + HAIL + ext;
                case "Hazy":
                    return path + HAZY + ext;
                case "Fog":
                case "Foggy":
                    return path + FOG + ext;
                case "Windy":
                    return path + WINDY + ext;
                case "Cloudy":
                case "Mostly Cloudy":
                case "Increasing Clouds":
                    if (isDay) {
                        return path + CLOUDY + ext;
                    }
                    else {
                        return path + PARTLY_CLOUDY_NIGHT + ext;
                    }
                case "Partly Cloudy":
                case "Fair":
                case "Partly Sunny":
                case "Clearing":
                    if (isDay) {
                        return path + PARTLY_CLOUDY + ext;
                    }
                    else {
                        return path + PARTLY_CLOUDY_NIGHT + ext;
                    }

                case "Heavy Rain":
                    return path + HEAVY_RAIN + ext;
                case "Clear":
                case "Hot and Humid":
                case "Very Hot":
                case "Sunny":
                case "Mostly Sunny":
                default:
                    if (isDay) {
                        return path + SUNNY_AND_CLEAR + ext;
                    }
                    else {
                        return path + CLEAR_NIGHT + ext;
                    }
            }
        }
    }
}

package com.litl.weather.view
{

    import com.litl.control.OptionsDialog;
    import com.litl.control.TextButton;
    import com.litl.skin.LitlColors;
    import com.litl.weather.WeatherChannel;
    import com.litl.weather.events.OptionsBubbleEvent;
    import com.litl.weather.events.SearchBoxEvent;
    import com.litl.weather.model.twc.Day;
    import com.litl.weather.model.twc.Loc;
    import com.litl.weather.model.twc.Weather;
    import com.litl.weather.service.WeatherService;
    import com.litl.weather.utils.StringUtils;

    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.events.FocusEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.ColorTransform;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.ui.Keyboard;
    import flash.utils.setTimeout;

    public class OptionsBubble extends Sprite
    {
        private var optionsDialog:OptionsDialog;
        private var optionsHeader:OptionsHeader;
        private var locationListItems:Array;
        private var weatherService:WeatherService;
        private var channelWidth:Number;
        private var channelHeight:Number;
        private var locationsHeader:LocationsHeader;
        private var locationSearchBox:LocationSearchBox;
        public var searchBox:SearchBox = null;
        private var doneButton:TextButton;
        private var errorTextField:TextField;

        private static var MAX_LOCATIONS:Number = 10;
        private static var TYPE_US_CITY:Number = 0;
        private static var TYPE_INTERNATIONAL_CITY:Number = 1;

        public function OptionsBubble() {

            weatherService = WeatherService.instance;

            createChildren();

        }

        private function createChildren():void {
            optionsDialog = new OptionsDialog();
            optionsDialog.alwaysOnTop = true;
            optionsDialog.setStyle("pointPosition", "topRight");
            optionsDialog.setStyle("backgroundColor", LitlColors.BLUE);
            optionsDialog.setStyle("borderColor", LitlColors.BLACK);
            addChild(optionsDialog);

            optionsHeader = new OptionsHeader();
            optionsDialog.addChild(optionsHeader);

            locationsHeader = new LocationsHeader();
            optionsDialog.addChild(locationsHeader);

            locationSearchBox = new LocationSearchBox();
            optionsDialog.addChild(locationSearchBox);

            locationSearchBox.location_txt.addEventListener(Event.CHANGE, locationChangeHandler);
            locationSearchBox.location_txt.addEventListener(FocusEvent.FOCUS_IN, locationSelectHandler);
            locationSearchBox.addLocMC.addEventListener(MouseEvent.CLICK, onAddButtonClick);
            locationSearchBox.addLocMC.addEventListener(MouseEvent.MOUSE_OVER, onAddButtonOver);
            locationSearchBox.addLocMC.addEventListener(MouseEvent.MOUSE_OUT, onAddButtonOut);
            locationSearchBox.addLocMC.mouseEnabled = true;
            locationSearchBox.addLocMC.hit.alpha = 0;

            doneButton = new TextButton();
            doneButton.text = "Done";
            doneButton.setSize(80, 30);
            doneButton.addEventListener(MouseEvent.CLICK, onDoneClick);
            optionsDialog.addChild(doneButton);

            errorTextField = new TextField();
            var errorFormat:TextFormat = new TextFormat("CorpoS", 14, LitlColors.BLUE);
            errorFormat.leading = -2;
            errorTextField.defaultTextFormat = errorFormat;
            errorTextField.wordWrap = true;
            errorTextField.width = locationSearchBox.width;
            errorTextField.textColor = 0xCC0000;
            errorTextField.embedFonts = true;
            errorTextField.multiline = true;
            errorTextField.selectable = false;
            errorTextField.autoSize = TextFieldAutoSize.LEFT;
            optionsDialog.addChild(errorTextField);
            errorTextField.visible = false;

            addSavedLocations();

            layout();
        }

        private function onAddButtonClick(evt:MouseEvent):void {
            if (searchBox != null) {
                locationSearchBox.location_txt.text = searchBox.selectedItem.location;
                dispatchEvent(new SearchBoxEvent(SearchBoxEvent.LOCATION_SELECTED, searchBox.selectedItem.location, searchBox.selectedItem.searchCode, searchBox.selectedItem.id));
            }
        }

        private function onAddButtonOver(evt:MouseEvent):void {

            optionsDialog.removeEventListener(MouseEvent.CLICK, onOptionsDialogBgClick);
            var white:ColorTransform = new ColorTransform();
            white.color = 0xFFFFFF;
            locationSearchBox.addLocMC.transform.colorTransform = white;

        }

        private function onAddButtonOut(evt:MouseEvent):void {

            optionsDialog.addEventListener(MouseEvent.CLICK, onOptionsDialogBgClick);
            var black:ColorTransform = new ColorTransform();
            black.color = 0x000000;
            locationSearchBox.addLocMC.transform.colorTransform = black;
        }

        private function onOptionsDialogBgClick(evt:MouseEvent):void {

            showPlaceholderText();
            clearSearch();
            removeSearchBox();
        }

        private function onDoneClick(evt:MouseEvent):void {
            dispatchEvent(new OptionsBubbleEvent(OptionsBubbleEvent.CLOSE));
        }

        private function showPlaceholderText():void {
            locationSearchBox.placeholderText.visible = true;
        }

        private function hidePlaceholderText():void {
            locationSearchBox.placeholderText.visible = false;
        }

        private function locationSelectHandler(evt:FocusEvent):void {
            setTimeout(evt.target.setSelection, 50, 0, evt.target.text.length);
            locationSearchBox.location_txt.removeEventListener(FocusEvent.FOCUS_IN, locationSelectHandler);
            locationSearchBox.location_txt.addEventListener(FocusEvent.FOCUS_OUT, onLocationSearchFocusOut);
            optionsDialog.addEventListener(MouseEvent.CLICK, onOptionsDialogBgClick);
            hidePlaceholderText();
            hideErrorTextField();
        }

        private function onLocationSearchFocusOut(evt:FocusEvent):void {
            //optionsDialog.removeEventListener(MouseEvent.CLICK, onOptionsDialogBgClick);
        }

        public function refresh(channelWidth:Number, channelHeight:Number):void {

            this.channelHeight = channelHeight;
            this.channelWidth = channelWidth;

            for each (var item:LocationListItem in locationListItems) {
                optionsDialog.removeChild(item);
            }
            addSavedLocations();
            hideErrorTextField();

            if (!searchBox) {
                clearSearch();
                removeSearchBox();
                showPlaceholderText();
            }

            layout();

        }

        private function addSavedLocations():void {
            if (locationListItems == null) {
                locationListItems = new Array();
            }

            var locations:Array = [];
            locationListItems = [];

            for (var i:int = 0; i < weatherService.locationsData.length; i++) {

                var locationWeather:Weather = weatherService.locationsData[i];
                addLocationToList(locationWeather, i);

            }

            checkTotalLocations();

        }

        private function checkTotalLocations():void {
            if (weatherService.locations.length >= MAX_LOCATIONS) {
                hideSearchBox();
            }
            else {
                showSearchBox();
            }
        }

        private function layout():void {

            locationsHeader.y = optionsHeader.height + optionsHeader.x + 20;

            var nextY:int = locationsHeader.height + locationsHeader.y + 10;

            for each (var item:LocationListItem in locationListItems) {
                item.y = nextY;
                item.x = 10;
                nextY += item.height + 3;
                item.selected.x = item.location_txt.width + 10;
            }

            if (locationSearchBox.visible) {

                locationSearchBox.y = nextY + 3;
                locationSearchBox.x = errorTextField.x = 10;

                errorTextField.y = (locationSearchBox.y + locationSearchBox.height + 5);

                doneButton.move((215), (nextY + locationSearchBox.height + 40));
            }
            else {
                doneButton.move((215), (nextY + 25));
            }

            optionsDialog.move(channelWidth - 475, 40);

            optionsDialog.refresh();

        }

        public function addLocationToList(weather:Weather, id:int):void {
            var locationWithoutZip:String = StringUtils.removeZipInParenthesis(weather.loc.dnam);
            var locationListItem:LocationListItem = new LocationListItem();
            locationListItem.location_txt.autoSize = TextFieldAutoSize.LEFT;
            locationListItem.location_txt.text = StringUtils.truncate(locationWithoutZip, 32);

            optionsDialog.addChild(locationListItem);
            locationListItems.push(locationListItem);
            locationListItem.id = id;

            if (id == weatherService.currentLocID) {
                locationListItem.selected.visible = true;
                locationListItem.delete_btn.removeEventListener(MouseEvent.CLICK, onDeleteLocationClick);
                locationListItem.delete_btn.visible = false;
            }
            else {
                locationListItem.selected.visible = false;
                locationListItem.delete_btn.addEventListener(MouseEvent.CLICK, onDeleteLocationClick);
                locationListItem.delete_btn.visible = true;
            }

        }

        private function removeLocationFromList(id:int):void {
            optionsDialog.removeChild(locationListItems[id]);
            locationListItems.splice(id, 1);
            weatherService.removeLocationAt(id);
            refresh(channelWidth, channelHeight);
        }

        private function onDeleteLocationClick(evt:MouseEvent):void {
            removeLocationFromList(evt.currentTarget.parent.id);
        }

        public function initSearchBox():void {

            var locations:Array = [];
            var tempLocations:Array = [];

            var weatherBugNs:Namespace = new Namespace("aws", "http://www.aws.com/aws");
            var results:XMLList = weatherService.results.weatherBugNs::locations.weatherBugNs::location;
            var locationsLength:Number = results.length();
            var maxListLength:Number = 18;

            for (var j:Number = 0; j < locationsLength; j++) {
                var cityName:String = results[j].@cityname;
                var stateName:String = results[j].@statename;
                var countryName:String = results[j].@countryname;
                var cityType:Number = new Number(results[j].@citytype);
                var cityCode:String = (results[j].@zipcode != "") ? results[j].@zipcode : results[j].@citycode;
                var searchCode:String = (results[j].@citytype == 0) ? "zipcode" : "citycode";

                tempLocations.push({ country: countryName, city: cityName, state: stateName, cityCode: cityCode, searchCode: searchCode, type: cityType });
            }

            tempLocations.splice(18);
            locations = tempLocations;

            removeSearchBox();

            if (weatherService.results == "") {
                return;
            }

            searchBox = new SearchBox();
            searchBox.addEventListener("selectLocation", selectLocationHandler);
            searchBox.addEventListener("itemSelected", onItemSelected);

            var optionsDialogDepth:int = this.getChildIndex(optionsDialog);
            this.addChild(searchBox);
            this.swapChildren(optionsDialog, searchBox);

            var nextY:int = 10;

            for (var i:int = 0; i < locations.length; i++) {
                var loc:* = locations[i];

                var searchItem:SearchBoxItem = new SearchBoxItem();
                searchItem.searchBoxItemRoot.bg.visible = false;

                if (loc.type == TYPE_US_CITY) {
                    searchItem.location = loc.city + ", " + loc.state;
                }
                else if ((loc.type == TYPE_INTERNATIONAL_CITY) && (loc.state != "")) {
                    searchItem.location = loc.city + ", " + loc.state + ", " + loc.country;
                }
                else {
                    searchItem.location = loc.city + ", " + loc.country;
                }

                searchItem.id = loc.cityCode;
                searchItem.searchCode = loc.searchCode;
                searchItem.pos = i;

                searchItem.y = nextY;

                nextY += searchItem.searchBoxItemRoot.height + 5;

                searchItem.addEventListener(MouseEvent.MOUSE_OVER, searchBox.rollOver);
                searchItem.addEventListener(MouseEvent.MOUSE_OUT, searchBox.rollOut);
                searchItem.addEventListener(MouseEvent.CLICK, searchBox.click);

                searchBox.items.push(searchItem);
                searchBox.addChild(searchItem);
            }

            searchBox.searchBoxRoot.bg.height = searchBox.height + 10;
            searchBox.selectItem(0);

            searchBox.x = (optionsDialog.x + 10);

            searchBox.y = (locationSearchBox.y + locationSearchBox.height + optionsDialog.y);

        }

        private function addLocationHandler(evt:MouseEvent):void {
            weatherService.addCurrentLocation();

        }

        private function onItemSelected(evt:Event):void {
            locationSearchBox.location_txt.text = searchBox.selectedItem.location;
        }

        private function searchHandler(evt:Event):void {
            initSearchBox();
        }

        private function searchHandlerError(evt:Event):void {
            removeSearchBox();
        }

        private function selectLocationHandler(evt:Event):void {
            trace("selectLocationHandler " + searchBox.selectedItem.searchCode);
            dispatchEvent(new SearchBoxEvent(SearchBoxEvent.LOCATION_SELECTED, searchBox.selectedItem.location, searchBox.selectedItem.searchCode, searchBox.selectedItem.id));
            removeSearchBox();
        }

        private function locationChangeHandler(evt:Event):void {

            if (locationSearchBox.location_txt.text != "") {
                WeatherService.instance.addEventListener("searchHandler", searchHandler);
                WeatherService.instance.addEventListener("searchHandlerError", searchHandlerError);
                addEventListener(KeyboardEvent.KEY_DOWN, keyHandlerfunction);
                WeatherService.instance.doSearch(locationSearchBox.location_txt.text);

            }
            else {
                WeatherService.instance.removeEventListener("searchHandler", searchHandler);
                WeatherService.instance.removeEventListener("searchHandlerError", searchHandlerError);
                removeEventListener(KeyboardEvent.KEY_DOWN, keyHandlerfunction);
                this.removeSearchBox();

            }
            hidePlaceholderText();
            hideErrorTextField();
        }

        private function keyHandlerfunction(evt:KeyboardEvent):void {

            if (locationSearchBox.location_txt.selectedText.length == 0) {
                //var caretPos:int = focusViewRoot.locationBoxMC.location_txt.length;
                //focusViewRoot.locationBoxMC.location_txt.setSelection(caretPos, caretPos);
            }

            if (evt.keyCode == Keyboard.DOWN) {
                searchBox.prevItem();
            }
            else if (evt.keyCode == Keyboard.UP) {
                searchBox.nextItem();
            }
            else if (evt.keyCode == Keyboard.ENTER) {
                evt.preventDefault();

                if (searchBox != null) {
                    trace("selectLocationHandler " + searchBox.selectedItem.searchCode);
                    dispatchEvent(new SearchBoxEvent(SearchBoxEvent.LOCATION_SELECTED, searchBox.selectedItem.location, searchBox.selectedItem.searchCode, searchBox.selectedItem.id));
                }
                removeSearchBox();
            }
            else if (evt.keyCode == Keyboard.ESCAPE) {
                removeSearchBox();
            }
        }

        public function clearSearch():void {
            locationSearchBox.location_txt.text = "";
        }

        public function removeSearchBox():void {
            if (searchBox == null)
                return;

            searchBox.removeEventListener("selectLocation", selectLocationHandler);
            removeChild(searchBox);
            searchBox = null;

            removeEventListener(KeyboardEvent.KEY_DOWN, keyHandlerfunction);
        }

        public function duplicateCitySelected(city:String):void {
            clearSearch();
            removeSearchBox();
            showPlaceholderText();
            layout();
            showDuplicateCityError(city);
        }

        private function setErrorTextField(txt:String):void {
            errorTextField.text = txt;
        }

        private function showErrorTextField():void {
            errorTextField.visible = true;
        }

        private function hideErrorTextField():void {
            errorTextField.visible = false;
        }

        private function hideSearchBox():void {
            locationSearchBox.visible = false;
            layout();
        }

        private function showSearchBox():void {
            locationSearchBox.visible = true;
            layout();
        }

        private function showDuplicateCityError(city:String):void {

            setErrorTextField(city + " is already a saved city");
            showErrorTextField();
            layout();

        }

    }
}

﻿package com.litl.weather.model.twc{    public class SearchLoc extends Object    {        private var _loc:String;        private var _type:String;        private var _id:String;        public function SearchLoc(id:String, type:String, loc:String) {            this.id = id;            this.type = type;            this.loc = loc;        }        public function get loc():String {            return _loc;        }        public function set loc(loc:String):void {            _loc = loc;        }        public function get id():String {            return _id;        }        public function set id(id:String):void {            _id = id;        }        public function get type():String {            return _type;        }        public function set type(type:String):void {            _type = type;        }        public function toString():String {            return this.id + " (" + this.type + "): " + this.loc;        }    }}
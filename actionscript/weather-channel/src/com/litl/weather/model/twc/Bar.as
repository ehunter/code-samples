﻿package com.litl.weather.model.twc{    public class Bar    {        // Public Properties:        // Private Properties:        private var _r:String; // barometric pressure        private var _d:String; // barometric trend        // Initialization:        public function Bar() {        }        // Public Methods:        public function get r():String {            return _r;        }        public function set r(r:String):void {            _r = r;        }        public function get d():String {            return _d;        }        public function set d(d:String):void {            _d = d;        }        public function toString():String {            return "Bar: " +                "\n r: " + r +                "\n d: " + d +                "\n";        }        // Private Methods:    }}
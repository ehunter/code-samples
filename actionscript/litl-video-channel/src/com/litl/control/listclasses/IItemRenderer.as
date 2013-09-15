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
package com.litl.control.listclasses
{
    import flash.events.IEventDispatcher;

    /**
     * Interface for a list item renderer.
     * @author litl
     *
     */
    public interface IItemRenderer extends IEventDispatcher
    {
        /** @private */
        function get data():Object;
        /** Set the data for this item renderer. */
        function set data(obj:Object):void;
        /** Cleanly destroy this item renderer instance. */
        function destroy():void;
        /** Enable or disable this item renderer. */
        function set enabled(b:Boolean):void;
        /** Specify whether this item renderer is currently selected. Selected renderers can highlight themselves if they need to. */
        function set selected(b:Boolean):void;
        /** @private */
        function get selected():Boolean;
        /** Get/Set the x position of this renderer. */
        function set x(v:Number):void;
        /** @private */
        function get x():Number;
        /** Get/Set the y position of this renderer. */
        function set y(v:Number):void;
        /** @private */
        function get y():Number;
        /** Get/Set the width of this renderer. */
        function set width(v:Number):void;
        /** @private */
        function get width():Number;
        /** Get/Set the height of this renderer. */
        function set height(v:Number):void;
        /** @private */
        function get height():Number;
        /** Indicate whether this item is ready to display (ie. it has loaded). The Slideshow class waits for items to complete, before displaying them. */
        function get isReady():Boolean;
    }
}
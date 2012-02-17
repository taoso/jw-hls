package com.longtailvideo.adaptive {


    import com.longtailvideo.adaptive.*;
    import com.longtailvideo.adaptive.streaming.*;
    import com.longtailvideo.adaptive.utils.*;
    import flash.display.Sprite;
    import flash.events.*;
    import flash.media.*;


    /** Class that manages the streaming process. **/
    public class Adaptive extends EventDispatcher {


        /** The playback buffer. **/
        private var _buffer:Buffer;
        /** The quality monitor. **/
        private var _loader:Loader;
        /** The manifest parser. **/
        private var _getter:Getter;
        /** The video object that displays the stream. **/
        private var _video:Object;


        /** Create and connect all components. **/
        public function Adaptive(video:Object):void {
            _video = video;
            _getter = new Getter(this);
            _loader = new Loader(this);
            _buffer = new Buffer(this,_loader,_video);
        };


        /** Forward internal errors. **/
        override public function dispatchEvent(event:Event):Boolean {
            if(event.type == AdaptiveEvent.ERROR) {
                Log.txt(AdaptiveEvent(event).message);
                stop();
            }
            return super.dispatchEvent(event);
        };


        /** Return the current quality level. **/
        public function getLevel():Number {
            return _loader.getLevel();
        };


        /** Return the list with bitrate levels. **/
        public function getLevels():Array {
            return _getter.getLevels();
        };


        /** Return the list with switching metrics. **/
        public function getMetrics():Object {
            return _loader.getMetrics();
        };


        /** Return the current playback position. **/
        public function getPosition():Number {
            return _buffer.getPosition();
        };


        /** Return the current playback position. **/
        public function getState():String {
            return _buffer.getState();
        };


        /** Return the type of stream. **/
        public function getType():String {
            return _getter.getType();
        };


        /** Start playing an new adaptive stream. **/
        public function play(url:String,start:Number=0):void {
            _buffer.stop();
            _buffer.startPosition = start;
            _getter.load(url);
        };


        /** Toggle the pause state. **/
        public function pause():void {
            _buffer.pause();
        };


        /** Seek to another position in the stream. **/
        public function seek(position:Number):void {
            _buffer.seek(position);
        };


        /** Stop streaming altogether. **/
        public function stop():void {
            _buffer.stop();
        };


        /** Change the audio volume of the stream. **/
        public function volume(percent:Number):void {
            _buffer.volume(percent);
        };


        /** Update the screen width. **/
        public function setWidth(width:Number):void {
            _loader.setWidth(width);
        };


    }


}
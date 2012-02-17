package com.longtailvideo.adaptive.streaming {


    import com.longtailvideo.adaptive.*;
    import com.longtailvideo.adaptive.parsing.*;
    import com.longtailvideo.adaptive.utils.*;
    import flash.events.*;
    import flash.net.*;
    import flash.utils.*;


    /** Loader for adaptive streaming manifests. **/
    public class Getter {


        /** Reference to the adaptive framework controller. **/
        private var _adaptive:Adaptive;
        /** Array with levels. **/
        private var _levels:Array = [];
        /** The audio levels. **/
        private var _audios:Array = [];
        /** Object that fetches the manifest. **/
        private var _loader:URLLoader;
        /** Link to the M3U8 file. **/
        private var _url:String;
        /** Amount of playlists still need loading. **/
        private var _toLoad:Number;
        /** Streaming system (apple, smooth, zeri). **/
        private var _system:String;
        /** Timeout ID for reloading live playlists. **/
        private var _timeout:Number;
        /** Streaming type (live, ondemand). **/
        private var _type:String;


        /** Setup the loader. **/
        public function Getter(adaptive:Adaptive) {
            _adaptive = adaptive;
            _adaptive.addEventListener(AdaptiveEvent.STATE,_stateHandler);
            _levels = [];
            _loader = new URLLoader();
            _loader.addEventListener(Event.COMPLETE,_loaderHandler);
            _loader.addEventListener(IOErrorEvent.IO_ERROR,_errorHandler);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,_errorHandler);
        };


        /** Loading has been completed. **/
        private function _completeHandler():void {
            _levels.sortOn('bitrate',Array.NUMERIC);
            _adaptive.dispatchEvent(new AdaptiveEvent(AdaptiveEvent.MANIFEST,_levels));
            if(_type == AdaptiveTypes.LIVE) {
                _timeout = setTimeout(_reloadManifest,_levels[0].fragments[0].duration*1000);
            }
        };


        /** Loading failed; return errors. **/
        private function _errorHandler(event:ErrorEvent):void {
            var txt:String = "Cannot load M3U8: "+event.text;
            if(event is SecurityErrorEvent) {
                txt = "Cannot load M3U8: to crossdomain restrictions.";
            } else if (event is IOErrorEvent) {
                txt = "Cannot load M3U8: 404 not found.";
            }
            _adaptive.dispatchEvent(new AdaptiveEvent(AdaptiveEvent.ERROR,txt));
        };


        /** Return the current manifest. **/
        public function getLevels():Array {
            return _levels;
        };


        /** Return the stream type. **/
        public function getType():String {
            return _type;
        };


        /** Load the manifest file. **/
        public function load(url:String):void {
            _url = url;
            _toLoad = 1;
            _levels = [];
            _loader.load(new URLRequest(_url));
        };


        /** URL loaded; check and parse the appropriate type. **/
        private function _loaderHandler(event:Event):void {
            var string:String = String(event.target.data);
            // Check for M3U8 playlist or manifest.
            if(string.indexOf(Manifest.HEADER) == 0) {
                if(string.indexOf(Manifest.FRAGMENT) > 0) {
                    var level:Level = new Level();
                    level.url = _url;
                    _levels.push(level);
                    _parsePlaylist(string,_url,0);
                } else if(string.indexOf(Manifest.LEVEL) > 0) {
                    _parseManifest(string);
                }
            } else {
                var message:String = "Manifest is not a valid M3U8 file" + _url;
                _adaptive.dispatchEvent(new AdaptiveEvent(AdaptiveEvent.ERROR,message));
            }
        };


        /** Parse an M3U8 manifest. **/
        private function _parseManifest(string:String):void {
            _levels = Manifest.getLevels(string,_url);
            _toLoad = _levels.length;
            for(var i:Number = 0; i < _levels.length; i++) {
                new Manifest().loadPlaylist(_levels[i].url,_parsePlaylist,_errorHandler,i);
            }
        };


        /** Parse an M3U8 playlist. **/
        private function _parsePlaylist(string:String,url:String,index:Number):void {
            var frags:Array = Manifest.getFragments(string,url);
            for(var i:Number = 0; i<frags.length; i++) {
                _levels[index].push(frags[i]);
            }
            // Check whether the stream is live.
            if(Manifest.hasEndlist(string)) {
                _type = AdaptiveTypes.VOD;
            } else {
                _type = AdaptiveTypes.LIVE;
            }
            _toLoad--;
            if(_toLoad == 0) {
                _completeHandler();
            }
        };


        /** Reload all M3U8 playlists (for live). **/
        private function _reloadManifest():void {
            _toLoad = _levels.length;
            for(var i:Number = 0; i < _levels.length; i++) {
                new Manifest().loadPlaylist(_levels[i].url,_reloadPlaylist,_errorHandler,i);
            }
        };


        /** Compare a reloaded playlist to the original. **/
        private function _reloadPlaylist(string:String,url:String,index:Number):void {
            var frags:Array = Manifest.getFragments(string,url);
            var toAdd:Number = 0;
            for(var i:Number = 0; i < _levels[index].fragments.length; i++) {
                if(_levels[index].fragments[i].url == frags[0].url) {
                    toAdd = _levels[index].fragments.length - i;
                    break;
                }
            }
            for(var j:Number = toAdd; j < frags.length; j++) {
                _levels[index].push(frags[j]);
            }
            _toLoad--;
            if(_toLoad == 0 && !Manifest.hasEndlist(string)) {
                _timeout = setTimeout(_reloadManifest,_levels[0].fragments[0].duration*1000);
            }
        };


        /** When the framework idles out, reloading is cancelled. **/
        public function _stateHandler(event:AdaptiveEvent):void {
            if(event.state == AdaptiveStates.IDLE) {
                clearTimeout(_timeout);
            }
        };


    }


}
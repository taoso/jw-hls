package com.longtailvideo.adaptive.parsing {


    import flash.events.*;
    import flash.net.*;


    /** Helpers for parsing M3U8 files. **/
    public class Manifest {


        /** Starttag for a fragment. **/
        public static const FRAGMENT:String = '#EXTINF:';
        /** Header tag that must be at the first line. **/
        public static const HEADER:String = '#EXTM3U';
        /** Starttag for a level. **/
        public static const LEVEL:String = '#EXT-X-STREAM-INF:';
        /** Tag that delimits the end of a playlist. **/
        public static const ENDLIST:String = '#EXT-X-ENDLIST';


        /** Index in the array with levels. **/
        private var _index:Number;
        /** URLLoader instance. **/
        private var _loader:URLLoader;
        /** Function to callback loading to. **/
        private var _success:Function;
        /** URL of an M3U8 playlist. **/
        private var _url:String;


        /** Load a playlist M3U8 file. **/
        public function loadPlaylist(url:String,success:Function,error:Function,index:Number):void {
            _url = url;
            _success = success;
            _index = index;
            _loader = new URLLoader();
            _loader.addEventListener(Event.COMPLETE,_loaderHandler);
            _loader.addEventListener(IOErrorEvent.IO_ERROR,error);
            _loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,error);
            _loader.load(new URLRequest(url));
        };


        /** The M3U8 playlist was loaded. **/
        private function _loaderHandler(event:Event):void {
            _success(String(event.target.data),_url,_index);
        };


        /** Extract fragments from playlist data. **/
        public static function getFragments(data:String,base:String=''):Array {
            var fragments:Array = [];
            var lines:Array = data.split("\n");
            var i:Number = 0;
            while (i < lines.length) {
                if(lines[i].indexOf(Manifest.FRAGMENT) == 0) {
                    var duration:Number = lines[i].substr(8,lines[i].indexOf(',') - 8);
                    var url:String = Manifest.getURL(lines[i+1],base);
                    fragments.push(new Fragment(url,duration));
                    i++;
                }
                i++;
            }
            if(fragments.length == 0) {
                throw new Error("No TS fragments found in Playlist: " + base);
            }
            return fragments;
        };


        /** Extract levels from manifest data. **/
        public static function getLevels(data:String,base:String=''):Array {
            var levels:Array = [];
            var lines:Array = data.split("\n");
            var i:Number = 0;
            while (i<lines.length) {
                if(lines[i].indexOf(Manifest.LEVEL) == 0) {
                    var level:Level = new Level();
                    var params:Array = lines[i].substr(Manifest.LEVEL.length).split(',');
                    for(var j:Number = 0; j<params.length; j++) { 
                        if(params[j].indexOf('BANDWIDTH') > -1) {
                            level.bitrate = params[j].split('=')[1];
                            if(level.bitrate < 150000) {
                                level.audio = true;
                            }
                        } else if (params[j].indexOf('RESOLUTION') > -1) {
                            level.height  = params[j].split('=')[1].split('x')[1];
                            level.width = params[j].split('=')[1].split('x')[0];
                        } else if (params[j].indexOf('CODECS') > -1 && lines[i].indexOf('avc1') == -1) {
                            level.audio = true;
                        }
                    }
                    i++;
                    level.url = Manifest.getURL(lines[i],base);
                    levels.push(level);
                }
                i++;
            }
            if(levels.length == 0) {
                throw new Error("No playlists found in Manifest: " + base);
            }
            return levels;
        };


        /** Extract whether the stream is live or ondemand. **/
        public static function hasEndlist(data:String):Boolean {
            if(data.indexOf(Manifest.ENDLIST) > 0) {
                return true;
            } else {
                return false;
            }
        };


        /** Extract URL (check if absolute or not). **/
        private static function getURL(path:String,base:String):String {
            if(path.substr(0,7) == 'http://' || path.substr(0,1) == '/') {
                return path;
            } else {
                // Remove querystring
                if(base.indexOf('?') > -1) {
                    base = base.substr(0,base.indexOf('?')); 
                }
                return base.substr(0,base.lastIndexOf('/') + 1) + path;
            }
        };


    }


}
package com.longtailvideo.adaptive.parsing {


    /** Adaptive streaming bitrate chunk. **/
    public class Fragment {


        /** Duration of this chunk. **/
        public var duration:Number;
        /** Starttime of this chunk. **/
        public var start:Number;
        /** URL to this chunk. **/
        public var url:String;


        /** Create the bitrate fragment. **/
        public function Fragment(url:String, duration:Number, start:Number=0):void {
            this.duration = duration;
            this.url = url;
            this.start = start;
        };


    }


}
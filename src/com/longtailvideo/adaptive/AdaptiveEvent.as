package com.longtailvideo.adaptive {


    import com.longtailvideo.adaptive.muxing.TS;
    import com.longtailvideo.adaptive.muxing.Tag;
    import flash.events.Event;


    /** Event fired when an error prevents playback. **/
    public class AdaptiveEvent extends Event {


        /** Identifier for a playback complete event. **/
        public static const COMPLETE:String = "adaptiveEventComplete";
        /** Identifier for a playback error event. **/
        public static const ERROR:String = "adaptiveEventError";
        /** Identifier for a fragment load event. **/
        public static const FRAGMENT:String = "adaptiveEventFragment";
        /** Identifier for a manifest (re)load event. **/
        public static const MANIFEST:String = "adaptiveEventManifest";
        /** Identifier for a playback position change event. **/
        public static const POSITION:String = "adaptiveEventPosition";
        /** Identifier for a playback state switch event. **/
        public static const STATE:String = "adaptiveEventState";
        /** Identifier for a quality level switch event. **/
        public static const SWITCH:String = "adaptiveEventLevel";
        /**
         * Loader异步加载_parseTS方法事件，触发时传送tags参数
         */
        public static const LOADER_PARSETS:String = "loader_parsets";
        /**
         * Loader异步加载TS对象，通过TS_TS方法传递TS，回调_parseTS方法
         */
        public static const TS_TS:String = "ts_ts";
        public static const TS_PKG:String = "ts_pkg";

        /** The current quality level. **/
        public var level:Number;
        /** The list with quality levels. **/
        public var levels:Array;
        /** The error message. **/
        public var message:String;
        /** The current QOS metrics. **/
        public var metrics:Object;
        /** The time position. **/
        public var position:Number;
        /** The new playback state. **/
        public var state:String;

        public var tags:Vector.<Tag>;
        public var ts:TS;

        /** Assign event parameter and dispatch. **/
        public function AdaptiveEvent(type:String, parameter:*=null) {
            switch(type) {
                case AdaptiveEvent.ERROR:
                    message = parameter as String;
                    break;
                case AdaptiveEvent.FRAGMENT:
                    metrics = parameter as Object;
                    break;
                case AdaptiveEvent.MANIFEST:
                    levels = parameter as Array;
                    break;
                case AdaptiveEvent.POSITION:
                    position = parameter as Number;
                    break;
                case AdaptiveEvent.STATE:
                    state = parameter as String;
                    break;
                case AdaptiveEvent.SWITCH:
                    level = parameter as Number;
                    break;
                case AdaptiveEvent.LOADER_PARSETS:
                    tags = parameter as Vector.<Tag>;
                    break;
                case AdaptiveEvent.TS_TS:
                    ts = parameter as TS;
                    break;
            }
            super(type, false, false);
        };


    }


}

package com.longtailvideo.adaptive {


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
            }
            super(type, false, false);
        };


    }


}
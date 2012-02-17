package com.longtailvideo.adaptive.utils {


    import flash.external.ExternalInterface;


    /** Class that sends log messages to browser console. **/
    public class Log {


        public static var LOGGING:Boolean = true;


        /** Log a message to the console. **/
        public static function txt(message:*):void {
            if(LOGGING && ExternalInterface.available) {
                ExternalInterface.call('console.log',String(message));
            }
        };


    }


}
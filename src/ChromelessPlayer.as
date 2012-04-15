package {


    import flash.ui.Keyboard;
    import flash.automation.KeyboardAutomationAction;
    import flash.system.Security;
    import com.longtailvideo.adaptive.utils.Log;
    import flash.media.Video;
    import com.longtailvideo.adaptive.*;
    import flash.display.*;
    import flash.events.*;
    import flash.external.ExternalInterface;
    import flash.geom.Rectangle;


    public class ChromelessPlayer extends Sprite {


        /** reference to the framework. **/
        private var _adaptive:Adaptive;
        /** Sheet to place on top of the video. **/
        private var _sheet:Sprite;
        /** Reference to the video element. **/
        //private var _video:StageVideo;
        private var _video:Video;
        /** Javascript callbacks. **/
        private var _callbacks:Object = {};


        /** Initialization. **/
        public function ChromelessPlayer():void {
            // Set stage properties
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            //stage.fullScreenSourceRect = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
            //stage.addEventListener(StageVideoAvailabilityEvent.STAGE_VIDEO_AVAILABILITY, _onStageVideoState);
            // Draw sheet for catching clicks
            stage.color = 0x000000;
            stage.addEventListener(FullScreenEvent.FULL_SCREEN, _fullScreenHandler);
            _sheet = new Sprite();
            _sheet.graphics.beginFill(0xFFFFFF,0);
            _sheet.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
            _sheet.addEventListener(MouseEvent.CLICK,_clickHandler);
            _sheet.buttonMode = true;

            addChild(_sheet);
            Security.allowDomain('*');
            // Connect getters to JS.
            ExternalInterface.addCallback("getLevel",_getLevel);
            ExternalInterface.addCallback("getLevels",_getLevels);
            ExternalInterface.addCallback("getMetrics",_getMetrics);
            ExternalInterface.addCallback("getPosition",_getPosition);
            ExternalInterface.addCallback("getState",_getState);
            ExternalInterface.addCallback("getType",_getType);
            // Connect calls to JS.
            ExternalInterface.addCallback("pause",_pause);
            ExternalInterface.addCallback("seek",_seek);
            ExternalInterface.addCallback("stop",_stop);
            ExternalInterface.addCallback("volume",_volume);
            ExternalInterface.addCallback("play", _play);
            ExternalInterface.addCallback("hello", _hello);
            // Connect callbacks to JS.
            ExternalInterface.addCallback("onComplete",_onComplete);
            ExternalInterface.addCallback("onError",_onError);
            ExternalInterface.addCallback("onFragment",_onFragment);
            ExternalInterface.addCallback("onManifest",_onManifest);
            ExternalInterface.addCallback("onPosition",_onPosition);
            ExternalInterface.addCallback("onState",_onState);
            ExternalInterface.addCallback("onSwitch",_onSwitch);
            //setTimeout(_pingJavascript,50);

            _initVideo();
        };

        private function _hello():void {
            Log.txt(_video.scaleX);
            Log.txt(_video.scaleY);
        }


        /** Notify javascript the framework is ready. **/
        private function _pingJavascript():void {
            ExternalInterface.call("onAdaptiveReady",ExternalInterface.objectID);
        };


        /** Forward events from the framework. **/
        private function _completeHandler(event:AdaptiveEvent):void {
            if(_callbacks.oncomplete) {
                ExternalInterface.call(_callbacks.oncomplete);
            }
        };
        private function _errorHandler(event:AdaptiveEvent):void {
            if(_callbacks.onerror) {
                ExternalInterface.call(_callbacks.onerror,event.message);
            }
        };
        private var _mediaWidth:Number = -1;
        private var _mediaHeight:Number = -1;
        private function _fragmentHandler(event:AdaptiveEvent):void {
            if(_callbacks.onfragment) {
                ExternalInterface.call(_callbacks.onfragment,event.metrics);
            }
            var _level:Number = _adaptive.getLevel();
            var _levels:Array = _adaptive.getLevels();

            _mediaWidth = _levels[_level].width;
            _mediaHeight = _levels[_level].height;

            _resizeVideo(
                stage.stageWidth,
                stage.stageHeight,
                _levels[_level].width,
                _levels[_level].height
            );

        };
        private function _manifestHandler(event:AdaptiveEvent):void {
            if(_callbacks.onmanifest) {
                ExternalInterface.call(_callbacks.onmanifest,event.levels);
            }
        };
        private function _positionHandler(event:AdaptiveEvent):void {
            if(_callbacks.onposition) {
                ExternalInterface.call(_callbacks.onposition,event.position);
            }
        };
        private function _stateHandler(event:AdaptiveEvent):void {
            if(_callbacks.onstate) {
                ExternalInterface.call(_callbacks.onstate,event.state);
            }
        };
        private function _switchHandler(event:AdaptiveEvent):void {
            if(_callbacks.onswitch) {
                ExternalInterface.call(_callbacks.onswitch,event.level);
            }
        };


        /** Javascript getters. **/
        private function _getLevel():Number { return _adaptive.getLevel(); };
        private function _getLevels():Array { return _adaptive.getLevels(); };
        private function _getMetrics():Object { return _adaptive.getMetrics(); };
        private function _getPosition():Number { return _adaptive.getPosition(); };
        private function _getState():String { return _adaptive.getState(); };
        private function _getType():String { return _adaptive.getType(); };


        /** Javascript calls. **/
        private function _play(url:String,start:Number=0):void {
            Log.txt(url);
            try {
                _adaptive.play(url,start);
            } catch(error:Error) {
                Log.txt(error.message);
            }
        };
        private function _pause():void { _adaptive.pause(); };
        private function _seek(position:Number):void { _adaptive.seek(position); };
        private function _stop():void { _adaptive.stop(); };
        private function _volume(percent:Number):void { _adaptive.volume(percent); };


        /** Javascript event subscriptions. **/
        private function _onComplete(name:String):void { _callbacks.oncomplete = name; };
        private function _onError(name:String):void { _callbacks.onerror = name; };
        private function _onFragment(name:String):void { _callbacks.onfragment = name; };
        private function _onManifest(name:String):void { _callbacks.onmanifest = name; };
        private function _onPosition(name:String):void { _callbacks.onposition = name; };
        private function _onState(name:String):void { _callbacks.onstate = name; };
        private function _onSwitch(name:String):void { _callbacks.onswitch = name; };


        /** Mouse click handler. **/
        private function _clickHandler(event:MouseEvent):void {
            // new FileReference().save(_adaptive.getFile(),'video.flv');
            Log.txt('media revolution is ' + _mediaWidth + 'x' + _mediaHeight);

            if(stage.displayState == StageDisplayState.FULL_SCREEN) {
                stage.displayState = StageDisplayState.NORMAL;
                /*Log.txt('stage revolution is '
                    + stage.stageWidth
                    + 'x'
                    + stage.stageHeight);
                _resizeVideo(
                    stage.stageWidth,
                    stage.stageHeight,
                    _mediaWidth,
                    _mediaHeight
                );*/
            } else {
                stage.displayState = StageDisplayState.FULL_SCREEN;
                /*Log.txt('stage fullscreen revolution is ' + stage.fullScreenWidth + 'x' + stage.fullScreenHeight);
                _resizeVideo(
                    stage.stageWidth,
                    stage.stageHeight,
                    _mediaWidth,
                    _mediaHeight
                );*/
            }
            _adaptive.setWidth(stage.stageWidth);
        };

        private function _fullScreenHandler(event:FullScreenEvent):void {
            _resizeVideo(
                stage.stageWidth,
                stage.stageHeight,
                _mediaWidth,
                _mediaHeight
            );
        }


        /** StageVideo detector. **/
        /**
        private function _onStageVideoState(event:StageVideoAvailabilityEvent):void {
            _video = stage.stageVideos[0];
            _video.viewPort = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
            _adaptive = new Adaptive(_video);
            _adaptive.setWidth(stage.stageWidth);
            _adaptive.addEventListener(AdaptiveEvent.COMPLETE,_completeHandler);
            _adaptive.addEventListener(AdaptiveEvent.ERROR,_errorHandler);
            _adaptive.addEventListener(AdaptiveEvent.FRAGMENT,_fragmentHandler);
            _adaptive.addEventListener(AdaptiveEvent.MANIFEST,_manifestHandler);
            _adaptive.addEventListener(AdaptiveEvent.POSITION,_positionHandler);
            _adaptive.addEventListener(AdaptiveEvent.STATE,_stateHandler);
            _adaptive.addEventListener(AdaptiveEvent.SWITCH,_switchHandler);
            _pingJavascript();
        };**/
        /**
         * Init the video object.
         */
        private function _initVideo():void {
            _video = new Video();
            _video.width = stage.stageWidth;
            _video.height = stage.stageHeight;

            _video.smoothing = true;

            addChild(_video);

            _adaptive = new Adaptive(_video);
            _adaptive.setWidth(stage.stageWidth);
            _adaptive.addEventListener(AdaptiveEvent.COMPLETE,_completeHandler);
            _adaptive.addEventListener(AdaptiveEvent.ERROR,_errorHandler);
            _adaptive.addEventListener(AdaptiveEvent.FRAGMENT,_fragmentHandler);
            _adaptive.addEventListener(AdaptiveEvent.MANIFEST,_manifestHandler);
            _adaptive.addEventListener(AdaptiveEvent.POSITION,_positionHandler);
            _adaptive.addEventListener(AdaptiveEvent.STATE,_stateHandler);
            _adaptive.addEventListener(AdaptiveEvent.SWITCH,_switchHandler);

            _pingJavascript();
            Log.txt('_initVideo');
        };

        private function _resizeVideo(
            sw:Number,
            sh:Number,
            mw:Number,
            mh:Number):void {
            var r:Number = Math.min(sw/mw, sh/mh);
            _video.width = mw * r;
            _video.height = mh * r;

            if (sw == _video.width) {
                _video.x = 0;
                _video.y = (sh - _video.height) / 2;
            } else {
                _video.x = (sw - _video.width) / 2;
                _video.y = 0;
            }
            _sheet.height = sh;
            _sheet.width = sw;
        }
    }
}

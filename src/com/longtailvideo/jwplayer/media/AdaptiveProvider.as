package com.longtailvideo.jwplayer.media {


    import com.longtailvideo.adaptive.*;

    import com.longtailvideo.jwplayer.events.MediaEvent;
    import com.longtailvideo.jwplayer.model.PlayerConfig;
    import com.longtailvideo.jwplayer.model.PlaylistItem;
	import com.longtailvideo.jwplayer.player.PlayerState;
	import com.longtailvideo.jwplayer.utils.Stretcher;

    import flash.display.DisplayObject;
    import flash.media.Video;


    /** JW Player provider for adaptive streaming. **/
    public class AdaptiveProvider extends MediaProvider {


        /** Reference to the framework. **/
        private var _adaptive:Adaptive;
        /** Current quality level. **/
        private var _level:Number;
        /** Reference to the quality levels. **/
        private var _levels:Array;
        /** Reference to the video object. **/
        private var _video:Video;


        public function AdaptiveProvider() {
            super('adaptive');
        };


        /** Forward completes from the framework. **/
        private function _completeHandler(event:AdaptiveEvent):void {
            complete();
        };


        /** Forward playback errors from the framework. **/
        private function _errorHandler(event:AdaptiveEvent):void {
            super.error(event.message);
        };


        /** Forward QOS metrics on fragment load. **/
        private function _fragmentHandler(event:AdaptiveEvent):void {
            _level = event.metrics.level;
            resize(_width,_height);
            sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_META, { metadata: {
                bandwidth: Math.round(event.metrics.bandwidth/1024),
                droppedFrames: 0,
                currentLevel: (_level+1) +' of ' + _levels.length + ' (' + 
                    Math.round(_levels[_level].bitrate/1024) + 'kbps, ' + _levels[_level].width + 'px)',
                width: event.metrics.screenwidth
            }});
        };


        /** Update video A/R on manifest lod. **/
        private function _manifestHandler(event:AdaptiveEvent):void {
            _levels = event.levels;
            if(_adaptive.getType() == AdaptiveTypes.LIVE) {
                sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {position: 0,duration: -1});
            } else {
                item.duration = _levels[_levels.length-1].duration;
                _adaptive.addEventListener(AdaptiveEvent.POSITION,_positionHandler);
            }
        };


        /** Update playback position. **/
        private function _positionHandler(event:AdaptiveEvent):void {
            sendMediaEvent(MediaEvent.JWPLAYER_MEDIA_TIME, {
                position: event.position, 
                duration: item.duration
            });
        };


        /** Forward state changes from the framework. **/
        private function _stateHandler(event:AdaptiveEvent):void {
            switch(event.state) {
                case AdaptiveStates.IDLE:
                    setState(PlayerState.IDLE);
                    break;
                case AdaptiveStates.BUFFERING:
                    setState(PlayerState.BUFFERING);
                    break;
                case AdaptiveStates.PLAYING:
                    _video.visible = true;
                    setState(PlayerState.PLAYING);
                    break;
                case AdaptiveStates.PAUSED:
                    setState(PlayerState.PAUSED);
                    break;
            }
        };


        /** Set the volume on init. **/
        override public function initializeMediaProvider(cfg:PlayerConfig):void {
            super.initializeMediaProvider(cfg);
            _video = new Video(320,180);
            _video.smoothing = true;
            _adaptive = new Adaptive(_video);
            _adaptive.volume(cfg.volume);
            _adaptive.addEventListener(AdaptiveEvent.COMPLETE,_completeHandler);
            _adaptive.addEventListener(AdaptiveEvent.ERROR,_errorHandler);
            _adaptive.addEventListener(AdaptiveEvent.FRAGMENT,_fragmentHandler);
            _adaptive.addEventListener(AdaptiveEvent.MANIFEST,_manifestHandler);
            _adaptive.addEventListener(AdaptiveEvent.STATE,_stateHandler);
            _level = 0;
        };


        /** Load a new playlist item **/
        override public function load(itm:PlaylistItem):void {
            super.load(itm);
            play();
        };


        /** Get the video object. **/
        override public function get display():DisplayObject {
            return _video;
        };


        /** Resume playback of a paused item. **/
        override public function play():void {
            if(state == PlayerState.PAUSED) {
                _adaptive.pause();
            } else {
                setState(PlayerState.BUFFERING);
                _adaptive.play(item.file,item.start);
            }
        };


        /** Pause a playing item. **/
        override public function pause():void {
            _adaptive.pause();
        };


        /** Do a resize on the video. **/
        override public function resize(width:Number,height:Number):void {
            _adaptive.setWidth(width);
            _height = height;
            _width = width;
            if(_levels && _levels[_level] && _levels[_level].width) {
                var ratio:Number = _levels[_level].width / _levels[_level].height;
                _video.height = Math.round(_video.width / ratio);
            }
            Stretcher.stretch(_video, width, height, config.stretching);
        };


        /** Seek to a certain position in the item. **/
        override public function seek(pos:Number):void {
            if(_adaptive.getType() == AdaptiveTypes.VOD) {
                _adaptive.seek(pos);
            }
        };


        /** Change the playback volume of the item. **/
        override public function setVolume(vol:Number):void {
            _adaptive.volume(vol);
            super.setVolume(vol);
        };


        /** Stop playback. **/
        override public function stop():void {
            _adaptive.stop();
            super.stop();
            _adaptive.removeEventListener(AdaptiveEvent.POSITION,_positionHandler);
            _level = 0;
        };


    }
}
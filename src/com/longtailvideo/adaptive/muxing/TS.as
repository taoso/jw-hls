package com.longtailvideo.adaptive.muxing {


    import com.longtailvideo.adaptive.AdaptiveEvent;
    import com.longtailvideo.adaptive.streaming.Loader;
    import com.longtailvideo.adaptive.muxing.*;
    import com.longtailvideo.adaptive.utils.Log;
    import flash.utils.ByteArray;


    /** Representation of an MPEG transport stream. **/
    public class TS {


        /** TS Sync byte. **/
        public static const SYNCBYTE:uint = 0x47;
        /** TS Packet size in byte. **/
        public static const PACKETSIZE:uint = 188;


        /** Packet ID of the AAC audio stream. **/
        private var _aacId:Number = -1;
        /** List with audio frames. **/
        public var audioTags:Vector.<Tag> = new Vector.<Tag>();
        /** List of packetized elementary streams with AAC. **/
        private var _audioPES:Vector.<PES> = new Vector.<PES>();
        /** Packet ID of the video stream. **/
        private var _avcId:Number = -1;
        /** PES packet that contains the first keyframe. **/
        private var _firstKey:Number = -1;
        /** Packet ID of the MP3 audio stream. **/
        private var _mp3Id:Number = -1;
        /** Packet ID of the PAT (is always 0). **/
        private var _patId:Number = 0;
        /** Packet ID of the Program Map Table. **/
        private var _pmtId:Number = -1;
        /** List with video frames. **/
        public var videoTags:Vector.<Tag> = new Vector.<Tag>();
        /** List of packetized elementary streams with AVC. **/
        private var _videoPES:Vector.<PES> = new Vector.<PES>();
        private var _data:ByteArray = null;
        private var _loader:Loader;


        /** Transmux the M2TS file into an FLV file. **/
        public function TS(data:ByteArray, loader:Loader) {
            _data = data;
            _loader = loader;
            // Extract the elementary streams.
            while(data.bytesAvailable) {
                _readPacket();
            }
            if (_videoPES.length == 0 || _audioPES.length == 0 ) {
                throw new Error("No AAC audio or AVC video stream found.");
            }
            // Extract the ADTS or MPEG audio frames.
            if(_aacId > 0) {
                _readADTS();
            } else {
                _readMPEG();
            }
            // Extract the NALU video frames.
            _readNALU();
            _loader.dispatchEvent(new AdaptiveEvent(AdaptiveEvent.TS_TS, this));

        };


        /** Get audio configuration data. **/
        public function getADIF():ByteArray {
            if(_aacId > 0) {
                return AAC.getADIF(_audioPES[0].data,_audioPES[0].payload);
            } else {
                return new ByteArray();
            }
        };


        /** Get video configuration data. **/
        public function getAVCC():ByteArray {
            if(_firstKey == -1) {
                throw new Error("Cannot parse stream: no keyframe found in TS fragment.");
            }
            return AVC.getAVCC(_videoPES[_firstKey].data,_videoPES[_firstKey].payload);
        };


        /** Read ADTS frames from audio PES streams. **/
        private function _readADTS():void {
            var frames:Array;
            var overflow:Number = 0;
            var tag:Tag;
            var stamp:Number;
            for(var i:Number=0; i<_audioPES.length; i++) {
                // Parse the PES headers.
                _audioPES[i].parse();
                // Correct for Segmenter's "optimize", which cuts frames in half.
                if(overflow > 0) {
                    _audioPES[i-1].data.position = _audioPES[i-1].data.length;
                    _audioPES[i-1].data.writeBytes(_audioPES[i].data,_audioPES[i].payload,overflow);
                    _audioPES[i].payload += overflow;
                }
                // Store ADTS frames in array.
                frames = AAC.getFrames(_audioPES[i].data,_audioPES[i].payload);
                for(var j:Number=0; j< frames.length; j++) {
                    // Increment the timestamp of subsequent frames.
                    stamp = Math.round(_audioPES[i].stamp + j * 1024 * 1000 / frames[j].rate);
                    tag = new Tag(Tag.AAC_RAW, stamp,false);
                    if(i == _audioPES.length-1 && j == frames.length - 1) {
                        tag.push(_audioPES[i].data, frames[j].start, _audioPES[i].data.length - frames[j].start);
                    } else {
                        tag.push(_audioPES[i].data, frames[j].start, frames[j].length);
                    }
                    audioTags.push(tag);
                }
                // Correct for Segmenter's "optimize", which cuts frames in half.
                overflow = frames[frames.length-1].start +
                    frames[frames.length-1].length - _audioPES[i].data.length;
            }
        };


        /** Read MPEG data from audio PES streams. **/
        private function _readMPEG():void {
            var frames:Array;
            var overflow:Number = 0;
            var tag:Tag;
            var stamp:Number;
            for(var i:Number=0; i<_audioPES.length; i++) {
                _audioPES[i].parse();
                tag = new Tag(Tag.MP3_RAW, _audioPES[i].stamp,false);
                tag.push(_audioPES[i].data, _audioPES[i].payload, _audioPES[i].data.length-_audioPES[i].payload);
                audioTags.push(tag);
            }
        };


        /** Read NALU frames from video PES streams. **/
        private function _readNALU():void {
            var overflow:Number;
            var units:Array;
            var last:Number;
            for(var i:Number=0; i<_videoPES.length; i++) {
                // Parse the PES headers and NAL units.
                try {
                    _videoPES[i].parse();
                } catch (error:Error) {
                    Log.txt(error.message);
                    continue;
                }
                units = AVC.getNALU(_videoPES[i].data,_videoPES[i].payload);
                // If there's no NAL unit, push all data in the previous tag.
                if(!units.length) {
                    videoTags[videoTags.length-1].push(_videoPES[i].data, _videoPES[i].payload,
                        _videoPES[i].data.length - _videoPES[i].payload);
                    continue;
                }
                // If NAL units are offset, push preceding data into the previous tag.
                overflow = units[0].start - units[0].header - _videoPES[i].payload;
                if(overflow) {
                    videoTags[videoTags.length-1].push(_videoPES[i].data,_videoPES[i].payload,overflow);
                }
                videoTags.push(new Tag(Tag.AVC_NALU,_videoPES[i].stamp,false,_videoPES[i].composition));
                // Only push NAL units 1 to 6 into tag.
                for(var j:Number = 0; j < units.length; j++) {
                    if (units[j].type < 6) {
                        videoTags[videoTags.length-1].push(_videoPES[i].data,units[j].start,units[j].length);
                        // Unit type 5 indicate a keyframe slice.
                        if(units[j].type == 5) {
                            videoTags[videoTags.length-1].keyframe = true;
                            if(_firstKey == -1) {
                                _firstKey = i;
                            }
                        }
                    }
                }
            }
        };


        /** Read TS packet. **/
        private function _readPacket():void {
            // Each packet is 188 bytes.
            var todo:uint = TS.PACKETSIZE;
            // Sync byte.
            if(_data.readByte() != TS.SYNCBYTE) {
                throw new Error("Could not parse TS file: sync byte not found.");
            }
            todo--;
            // Payload unit start indicator.
            var stt:uint = (_data.readUnsignedByte() & 64) >> 6;
            _data.position--;
            // Packet ID (last 13 bits of UI16).
            var pid:uint = _data.readUnsignedShort() & 8191;
            // Check for adaptation field.
            todo -=2;
            var atf:uint = (_data.readByte() & 48) >> 4;
            todo --;
            // Read adaptation field if available.
            if(atf > 1) {
                // Length of adaptation field.
                var len:uint = _data.readUnsignedByte();
                todo--;
                // Random access indicator (keyframe).
                var rai:uint = _data.readUnsignedByte() & 64;
                _data.position += len - 1;
                todo -= len;
                // Return if there's only adaptation field.
                if(atf == 2 || len == 183) {
                    _data.position += todo;
                    return;
                }
            }

            var pes:ByteArray = new ByteArray();
            // Parse the PES, split by Packet ID.
            switch (pid) {
                case _patId:
                    todo -= _readPAT();
                    break;
                case _pmtId:
                    todo -= _readPMT();
                    break;
                case _aacId:
                case _mp3Id:
                    pes.writeBytes(_data,_data.position,todo);
                    if(stt) {
                        _audioPES.push(new PES(pes,true));
                    } else if (_audioPES.length) {
                        _audioPES[_audioPES.length-1].append(pes);
                    } else {
                        Log.txt("Discarding TS audio packet without PES header.");
                    }
                    break;
                case _avcId:
                    pes.writeBytes(_data,_data.position,todo);
                    if(stt) {
                        _videoPES.push(new PES(pes,false));
                    } else if (_videoPES.length) {
                        _videoPES[_videoPES.length-1].append(pes);
                    } else {
                        Log.txt("Discarding TS video packet without PES header.");
                    }
                    break;
                default:
                    // Ignored other packet IDs
                    break;
            }
            // Jump to the next packet.
            _data.position += todo;
        };


        /** Read the Program Association Table. **/
        private function _readPAT():Number {
            // Check the section length for a single PMT.
            _data.position += 3;
            if(_data.readUnsignedByte() > 13) {
                throw new Error("Multiple PMT/NIT entries are not supported.");
            }
            // Grab the PMT ID.
            _data.position += 7;
            _pmtId = _data.readUnsignedShort() & 8191;
            return 13;
        };


        /** Read the Program Map Table. **/
        private function _readPMT():Number {
            // Check the section length for a single PMT.
            _data.position += 3;
            var len:uint = _data.readByte();
            var read:uint = 13;
            _data.position += 8;
            var pil:Number = _data.readByte();
            _data.position += pil;
            read += pil;
            // Loop through the streams in the PMT.
            while(read < len) {
                var typ:uint = _data.readByte();
                var sid:uint = _data.readUnsignedShort() & 8191;
                if(typ == 0x0F) {
                    _aacId = sid;
                } else if (typ == 0x1B) {
                    _avcId = sid;
                } else if (typ == 0x03) {
                    _mp3Id = sid;
                }
                // Possible section length.
                _data.position++;
                var sel:uint = _data.readByte() & 0x0F;
                _data.position += sel;
                read += sel + 5;
            }
            return len;
        };


    }


}

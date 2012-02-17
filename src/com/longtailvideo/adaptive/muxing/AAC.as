package com.longtailvideo.adaptive.muxing {


    import com.longtailvideo.adaptive.utils.*;
    import flash.utils.ByteArray;


    /** Constants and utilities for the AAC audio format. **/
    public class AAC {


        /** ADTS Syncword (111111111111), ID (MPEG4), layer (00) and protection_absent (1).**/
        public static const SYNCWORD:uint =  0xFFF1;
        /** ADTS Syncword with MPEG2 stream type (used by e.g. Squeeze 7). **/
        public static const SYNCWORD_2:uint =  0xFFF9;
        /** ADTS/ADIF sample rates index. **/
        public static const RATES:Array = 
            [96000,88200,64000,48000,44100,32000,24000,22050,16000,12000,11025,8000,7350];
        /** ADIF profile index (ADTS doesn't have Null). **/
        public static const PROFILES:Array = ['Null','AAC Main','AAC LC','AAC SSR','AAC LTP'];


        /** Build ADIF header from scratch. **/
        public static function buildADIF(samplerate:Number, channels:Number=2, profile:String='AAC LC'):ByteArray {
            var adif:ByteArray = new ByteArray();
            for(var i:Number=0; i<RATES.length; i++) {
                if(RATES[i] == samplerate) {
                    break;
                }
            }
            for(var j:Number=0; j<PROFILES.length; j++) {
                if(PROFILES[j] == profile) {
                    break;
                }
            }
            // 5 bits profile + 4 bits samplerate + 4 bits channels.
            adif.writeByte((j << 3) + (i >> 1));
            adif.writeByte((i << 7) + (channels << 3));
            // Reset position and return adif.
            adif.position = 0;
            return adif;
        };


        /** Get ADIF header from ADTS stream. **/
        public static function getADIF(adts:ByteArray,position:Number=0):ByteArray {
            adts.position = position;
            var short:uint = adts.readUnsignedShort();
            if(short == SYNCWORD || short == SYNCWORD_2) {
                // ADIF zero index is 'Null'; ADTS not (hence the +1).
                var profile:String = PROFILES[(adts.readByte() >> 6) + 1];
                adts.position--;
                var samplerate:uint = RATES[(adts.readByte() & 0x3C) >> 2];
                adts.position--;
                var channels:uint = (adts.readShort() & 0x01C0) >> 6;
            } else {
                throw new Error("Stream did not start with ADTS header.");
            }
            // Reset position and return adif.
            adts.position -= 4;
            // Log.txt('AAC: '+profile + ', '+samplerate+' Hz '+ channels +' channel(s)');
            return AAC.buildADIF(samplerate,channels,profile);
        };


        /** Get a list with AAC frames from ADTS stream. **/
        public static function getFrames(adts:ByteArray,position:Number=0):Array {
            var frames:Array = [];
            var frame_start:uint;
            var frame_length:uint;
            // Get raw AAC frames from audio stream.
            adts.position = position;
            var samplerate:uint;
            while(adts.bytesAvailable > 1) {
                // Check for ADTS header
                var short:uint = adts.readUnsignedShort();
                if(short == SYNCWORD || short == SYNCWORD_2) {
                    // Store samplerate for ofsetting timestamps.
                    if(!samplerate) {
                        samplerate = RATES[(adts.readByte() & 0x3C) >> 2];
                        adts.position--;
                    }
                    // Store raw AAC preceding this header.
                    if(frame_start) {
                        frames.push({
                            start: frame_start,
                            length: frame_length,
                            rate: samplerate
                        });
                    }
                    // ADTS header is 7 bytes.
                    frame_length = ((adts.readUnsignedInt() & 0x0003FFE0) >> 5) - 7;
                    frame_start = adts.position + 1;
                    adts.position += frame_length + 1;
                } else {
                    throw new Error("ADTS frame length incorrect.");
                }
            }
            // Write raw AAC after last header.
            if(frame_start) {
                frames.push({
                    start:frame_start,
                    length:frame_length,
                    rate:samplerate
                });
            } else {
                throw new Error("No ADTS headers found in this stream.");
            }
            adts.position = position;
            return frames;
        };


    }


}
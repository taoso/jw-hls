package com.longtailvideo.adaptive.muxing {


    import com.longtailvideo.adaptive.utils.*;
    import flash.utils.ByteArray;


    /** Constants and utilities for the H264 video format. **/
    public class AVC {


        /** H264 NAL unit names. **/
        public static const NAMES:Array = [
            'Unspecified',
            'NDR',
            'Partition A',
            'Partition B',
            'Partition C',
            'IDR',
            'SEI',
            'SPS',
            'PPS',
            'AUD',
            'End of Sequence',
            'End of Stream',
            'Filler Data'
        ];
        /** H264 profiles. **/
        public static const PROFILES:Object = {
            '66': 'H264 Baseline',
            '77': 'H264 Main',
            '100': 'H264 High'
        };


        /** Get Avcc header from AVC stream. **/
        public static function getAVCC(nalu:ByteArray,position:Number=0):ByteArray {
            // Find SPS and PPS units in AVC stream.
            var units:Array = AVC.getNALU(nalu,position,false);
            var sps:Number = -1;
            var pps:Number = -1;
            for(var i:Number = 0; i< units.length; i++) {
                if(units[i].type == 7 && sps == -1) {
                    sps = i;
                } else if (units[i].type == 8 && pps == -1) {
                    pps = i;
                }
            }
            // Throw errors if units not found.
            if(sps == -1) {
                throw new Error("No SPS NAL unit found in this stream.");
            } else if (pps == -1) {
                throw new Error("No PPS NAL unit found in this stream.");
            }
            // Write startbyte, profile, compatibility and level.
            var avcc:ByteArray = new ByteArray();
            avcc.writeByte(0x01);
            avcc.writeBytes(nalu,units[sps].start+1, 3);
            // 111111 + NALU bytesize length (4?)
            avcc.writeByte(0xFF);
            // Number of SPS, Bytesize and data.
            avcc.writeByte(0xE1);
            avcc.writeShort(units[sps].length);
            avcc.writeBytes(nalu,units[sps].start,units[sps].length);
            // Number of PPS, Bytesize and data.
            avcc.writeByte(0x01);
            avcc.writeShort(units[pps].length);
            avcc.writeBytes(nalu,units[pps].start,units[pps].length);
            // Grab profile/level
            avcc.position = 1;
            var prf:Number = avcc.readByte();
            avcc.position = 3;
            var lvl:Number = avcc.readByte();
            avcc.position = 0;
            // Log.txt("AVC: "+PROFILES[prf]+' level '+lvl);
            return avcc;
        };


        /** Return an array with NAL delimiter indexes. **/
        public static function getNALU(nalu:ByteArray,position:Number=0,log:Boolean=true):Array {
            var units:Array = [];
            var unit_start:Number;
            var unit_type:Number;
            var unit_header:Number;
            // Loop through data to find NAL startcodes.
            var window:uint = 0;
            nalu.position = position;
            while(nalu.bytesAvailable > 4) {
                window = nalu.readUnsignedInt();
                // Match four-byte startcodes
                if((window & 0xFFFFFFFF) == 0x01) {
                    if(unit_start) {
                        units.push({
                            length: nalu.position - 4 - unit_start,
                            start: unit_start,
                            type: unit_type
                        });
                    }
                    unit_header = 4;
                    unit_start = nalu.position;
                    unit_type = nalu.readByte() & 0x1F;
                    if(unit_type == 1 || unit_type == 5) { break; }
                // Match three-byte startcodes
                } else if((window & 0xFFFFFF00) == 0x100) {
                    if(unit_start) {
                        units.push({
                            header: unit_header,
                            length: nalu.position - 4 - unit_start,
                            start: unit_start,
                            type: unit_type
                        });
                    }
                    nalu.position--;
                    unit_header = 3;
                    unit_start = nalu.position;
                    unit_type = nalu.readByte() & 0x1F;
                    if(unit_type == 1 || unit_type == 5) { break; }
                } else {
                    nalu.position -= 3;
                }
            }
            // Append the last NAL to the array.
            if(unit_start) {
                units.push({
                    header: unit_header,
                    length: nalu.length - unit_start,
                    start: unit_start,
                    type: unit_type
                });
            }
            // Reset position and return results.
            if(log) {
                if(units.length) {
                    var txt:String = "AVC: ";
                    for(var i:Number=0; i<units.length; i++) { 
                        txt += NAMES[units[i].type] + ", ";
                    }
                    // Log.txt(txt.substr(0,txt.length-2) + " slices");
                } else {
                    // Log.txt('AVC: no NALU slices found');
                }
            }
            nalu.position = position;
            return units;
        };


    }


}
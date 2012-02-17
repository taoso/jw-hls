package com.longtailvideo.adaptive.muxing {


    import flash.utils.ByteArray;
    import com.longtailvideo.adaptive.muxing.*;


    /** Metadata needed to build an FLV tag. **/
    public class Tag {


        /** AAC Header Type ID. **/
        public static const AAC_HEADER:String = 'AAC HEADER';
        /** AAC Data Type ID. **/
        public static const AAC_RAW:String = 'AAC RAW';
        /** AVC Header Type ID. **/
        public static const AVC_HEADER:String = 'AVC HEADER';
        /** AVC Data Type ID. **/
        public static const AVC_NALU:String = 'AVC NALU';
        /** MP3 Data Type ID. **/
        public static const MP3_RAW:String = 'MP3 RAW';


        /** Composition time of this tag. **/
        public var composition:Number;
        /** Fragment number the tag belongs to. **/
        public var fragment:Number;
        /** Is this an AVC keyframe. **/
        public var keyframe:Boolean;
        /** Quality level the tag belongs to. **/
        public var level:Number;
        /** Array with data pointers. **/
        private var pointers:Array = [];
        /** Timestamp of this frame. **/
        public var stamp:Number;
        /** Type of FLV tag.**/
        public var type:String;
        

        /** Save the frame data and parameters. **/
        public function Tag(typ:String, stp:Number, key:Boolean, cmp:Number=0, lvl:Number=0, frg:Number=0) {
            type = typ;
            stamp = stp;
            keyframe = key;
            composition = cmp;
            level = lvl;
            fragment = frg;
        };


        /** Returns the tag data. **/
        public function get data():ByteArray {
            var array:ByteArray;

            // Render header data
            if(type == Tag.MP3_RAW) {
                array = FLV.getTagHeader(true, length + 1, stamp);
                // Presume MP3 is 44.1 stereo.
                array.writeByte(0x2F);
            } else if(type == Tag.AVC_HEADER || type == Tag.AVC_NALU) {
                array = FLV.getTagHeader(false, length + 5, stamp);
                // Keyframe switch, Header/Nalu switch and  CompositionTime
                keyframe ? array.writeByte(0x17): array.writeByte(0x27);
                type == Tag.AVC_HEADER ?  array.writeByte(0x00): array.writeByte(0x01);
                array.writeByte(composition >> 16);
                array.writeByte(composition >> 8);
                array.writeByte(composition);
            } else {
                array = FLV.getTagHeader(true, length + 2, stamp);
                // SoundFormat, -Rate, -Size, Type and Header/Raw switch.
                array.writeByte(0xAF);
                type == Tag.AAC_HEADER ? array.writeByte(0x00): array.writeByte(0x01);
            }

            // Write tag data, accounting for NAL startcodes
            if (type == Tag.AVC_NALU) {
                array.writeUnsignedInt(length - 4);
            }
            for(var i:Number=0; i < pointers.length; i++) {
                array.writeBytes(pointers[i].array,pointers[i].start,pointers[i].length);
            }

            // Write previousTagSize and return data.
            array.writeUnsignedInt(array.length);
            return array;
        };


        /** Returns the bytesize of the frame. **/
        private function get length():Number {
            var length:Number = 0;
            for (var i:Number=0; i<pointers.length; i++) {
                length += pointers[i].length;
            }
            // Account for NAL startcodes.
            if(type == Tag.AVC_NALU) {
                length += 4;
            }
            return length;
        };


        /** push a data pointer into the frame. **/
        public function push(array:ByteArray,start:Number,length:Number):void {
            pointers.push({
                array: array,
                start: start,
                length: length
            });
        };


        /** Trace the contents of this tag. **/
        public function toString():String {
            return "TAG (type: "+type+", stamp:"+stamp+", length:"+length+")";
        };


    }


}
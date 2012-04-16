.. _encoding:

Encoding an Adaptive Stream
===========================

This guide explains how to build an Apple HTTP Live Stream (HLS) using the *HandBrake* and *mediafilesegmenter* tools.

* `HandBrake <http://handbrake.rf>`_ is a free desktop tool for transcoding video files to MP4. It uses the excellent *x264* encoder for H264 video encoding.
* `mediafilesegmenter <http://developer.apple.com/resources/http-streaming/>`_ is a commandline tool (available only to official iOS developers) for segmenting (chopping up) an MP4 file into small TS fragments.

Streams encoded according to this guide will be compatible with iOS 3.0 (iPhone/iPad) and the framework.



Transcoding
-----------

In theory, any transcoding tool with support for H264/AAC in MP4 can be used. This guide uses Handbrake because it is free and easy to use, while at the same time capable of setting advanced encoding parameters. 



General
^^^^^^^

When transcoding to HLS (or another adaptive streaming format), there's a couple of deviations from regular transcoding *best practices*:

.. describe:: Keyframe intervals

   Because every fragment of a stream should be playeable by itself, it needs to start with a keyframe. Therefore, a fixed keyframe interval is needed. A keyframe interval of 2 seconds is recommended.

.. describe:: Profiles and levels 

   Since HLS streams should be playeable on mobile phones, not all bells and whizzles from the H264 format can be used. The iPhone 3GS supports H264 Baseline level 3.1. 

.. describe:: Variable bitrates

   Variable bitrates are possible, but the variation should be small (i.e. within a 20% range).  Apple's *streamvalidator* tool will flag fragments that deviate more than 10% from the bitrate set in the manifest.

These constraints seem suboptimal. Do realize the advantages of adaptive streaming over other streaming systems are so vast these constrains are of no concern in the big picture.


Levels
^^^^^^

Additionally, adaptive streaming implies you transcode your videos multiple times, into multiple quality levels. Generally, 4 to 8 quality levels, from 100 kbps to ~2mbps, are used. Here's a minimal example with four quality levels:

* H264 Baseline video @ 96 kbps, 10 fps, 160x90px. AAC HE audio @ 32 kbps, 22.05 kHz, stereo.
* H264 Baseline video @ 256 kbps, 30 fps, 320x180px. AAC HE audio @ 64 kbps, 44.1 kHz, stereo.
* H264 Baseline video @ 768 kbps, 30 fps, 640x360px. AAC HE audio @ 64 kbps, 44.1 kHz, stereo.
* H264 Baseline video @ 1536 kbps, 30 fps, 960x540px. AAC HE audio @ 64 kbps, 44.1 kHz, stereo.

.. note::

   The first quality level will look bad, but it is intended for cellular (2G/3G) playback. 

When adding quality levels, think about inserting a 512 kbps in between the 256 and 768 ones, and a 1024 kbps one in between the 768 and 1536 ones. An additional 720p quality level (1280x720px, ~2mbps) could be amended to the list. 

There's no real need to go beyond 64kbps audio; 5.1 surround isn't supported in HLS - yet.



HandBrake
^^^^^^^^^

Since handbrake only supports one output video per queue entry, you have to create an entry for each quality level:

 * Use the *Picture settings* to scale down your video to the desired resolution.
 * In the *Video* panel, use x264 for encoding with the *average bitrate* set to your target bitrate.
 * In the *Audio* panel, use CoreAudio AAC with your target mixdown (stereo), bitrate and samplerate.
 * In the *Advanced* panel, use the following x264 encoding settings. They will disable settings that are Main-profile only (such as CABAC and B-frames), as well as keyframe insertion on scene changes:


.. code-block:: text

   ref=2:bframes=0:subq=6:mixed-refs=0:8x8dct=0:cabac=0:scenecut=0:min-keyint=60:keyint=60

Note the *keyint* settings in this line is the keyframe interval: 2 seconds for a video with 30 fps. Change the settings if your video has a different framerate.



Segmenting
----------

Next step is segmentation of the stream. This is the process of chopping up the MP4 video into small (e.g. 2-second) fragments. In the case of Apple HLS, these segments have to be transmuxed from the MP4 format into the TS (transport stream) format as well.

The *mediafilesegmenter* tool from Apple will both do the segmenting, the transmuxing into TS and the creating of an M3U8 playlist. After installing the tool (MAC and only available to iOS developers), run the following command:

.. code-block:: text

   mediafilesegmenter -t 2 -f 300/ bunny-300.mp4

This command will fragment the video *bunny-300.mp4* into two-second chunks, placing those chunks and the resulting M3U8 playlist into the folder *300*. Repeat the process for each stream you have.

.. note:: 

   Next to Apple's *mediafilesegmenter*, an open-source *Segmenter* tool is available. We haven't tested it yet.



Creating the manifest
---------------------

The final step is creating an overall manifest to bind together the different quality streams. Such a manifest is a straightforward text document that can be built using any text editor. Here's an example:

.. code-block:: text

    #EXTM3U
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=1600000,RESOLUTION=960x540
    960/prog_index.m3u8
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=832000,RESOLUTION=640x360
    640/prog_index.m3u8
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=320000,RESOLUTION=320x180
    320/prog_index.m3u8
    #EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=128000,RESOLUTION=160x90
    160/prog_index.m3u8

This file (e.g. *manifest.m3u8*) tells the player which quality levels are available and where the indexes for these levels can be found.

Always start with preferred level (highest quality) first, since players generally go down the list until they find a stream they can play (although the framework does a re-sort on bitrate).

The *RESOLUTION* setting is very useful for the Adaptive provider. When set, the provider will take the resolution of each quality level into account for switching heuristics. If, for example, a client has plenty of bandwidth but only a videoplayer size of 300px wide, the 320x180 stream will be used. When the client resizes the viewport (e.g. when switching to fullscreen), the player automatically detects the change and moves to a higher quality level. In short, this setting will help constrain bandwidth usage without affecting perceived quality.

The HLS format defines another stream info parameter called *CODECS*. It can be used to list the audio/video codecs used, e.g. in case one or more quality levels are audio-only, or H264 Main or High profile.

.. note::

   Both iDevices and the Adaptive framework can play HLS with a single quality level. In such case, the additional manifest file is not needed.
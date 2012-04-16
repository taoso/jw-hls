.. _systems:

Manifest & Fragment Support
===========================

This guide elaborates on the framework's support for the various adaptive streaming solutions.


Apple HTTP Live Streaming
-------------------------

* Both single playlists and a manifest + playlists are supported. Both live *sliding window* and on-demand streaming are supported.

* AES decryption is not supported.

* In the case of a live event, viewers are allowed to pause/seek within the time range of the playlist at any given time. So if, for example, a live playlist contains three 10-second segments and the live head is at 04:45, the user can seek back to 04:15, or pause for 30 seconds. When seeking back beyond, or pausing longer than that timeframe, the framework will resume playback from *live head - 30*.

* The *RESOLUTION* parameter is required in order for the framework to constrain level selection to screen dimensions. If omitted, the framework might load a huge video into a small window if bandwidth allows so.

* Audio-only quality levels are not supported, but filtered if available. The framework filters based upon the value of the *CODECS* parameter. Alternatively, the framework filters out the audio levels by looking at fragment extensions; *.aac* is ignored.

* The framework follows the TS conventions as laid out by the HLS IETF draft: one PMT per TS, containing one H264 (Baseline, Main) and one AAC (Main, HE, LC) elementary stream.

* TS fragments should each start with a PES packet header for both the audio and video stream. The stream will die if this isn't the case.

* TS fragments should each start with a PES containing SPS/PPS data and a keyframe slice (NAL unit 5). Fragments starting without SPS/PPS and/or with an interframe (NAL unit 1) will work for continous playback, but will break the player if the fragment is the first fragment after a seek or quality level switch.

* The framework supports the *optimize* option of Apple's *mediafilesegmenter*. This option slices up ADTS frames or NAL units into multiple PES packets in order to keep overhead low (removing adaptation field filler data). As stated above though, this is **not** supported across TS fragments.

* B-frames should be supported (the player respects composition times), but haven't been tested yet. Likewise, H264 High profile should also be supported (not tested yet).



Microsoft Smooth Streaming
--------------------------

Some early info on Smooth Streaming support:

* AVCC and ADIF data are constructed from the manifest. This means the manifest must contain *CodecPrivateData* for video and *Channels* and *SamplingRate* for audio.

* Only one audio track (the first one in the manifest) is currently supported. Text tracks are currently not supported.



Adobe Zeri
----------

Adobe Zeri (HTTP Dynamic Streaming) is currently not supported.



MPEG DASH
---------

MPEG DASH is currently not supported.



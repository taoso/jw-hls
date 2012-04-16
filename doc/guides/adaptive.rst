.. _adaptive:

About Adaptive Streaming
========================

This guide offers an introduction to adaptive streaming in general, as well as to currently existing solutions.



Current streaming methods
-------------------------

At present, online video is mostly delivered using one of the following two methods:

* *Progressive download*; video is delivered to the player as one big download. Used by e.g. Vimeo.
* *Stateful streaming*; video is delivered to the player over a persistent connection. Used by e.g. Hulu.

Both methods have a number of cons that prevent them from overtaking the other for online video streaming:

* Progressive download inherently wastes a lot of bandwidth. For example, a user might start to watch a 10-minute video, but stop after 1 minute. Usually, the entire video is downloaded at that point.
* Progressive download cannot adapt to changing network (e.g. a drop in bandwidth) or client conditions (e.g. a jump to fullscreen).
* Progressive download does not support live streaming.

* Stateful streaming requires specialized streaming servers (like Flash Media Server) and fast, dedicated hardware.
* Stateful streaming needs dedicated protocols (i.e. not TCP/HTTP/80)  and a dedicated CDN / caching infrastructure.
* Stateful streaming is very fragile. One hickup in the connection and playback is interrupted.



Enter adaptive streaming
------------------------

Adaptive streaming is a third video delivery method, addressing these shortcomings. An adaptive stream consists of hundreds of small video *fragments*, each a few seconds long, seamlessly glued together to one video in the streaming client.

* Adaptive streaming leverages existing HTTP webservers, networking and caching infrastructure.
* At the same time, it can still adapt to network and client changes, simply by loading successive fragments in a higher or lower quality.
* It can be leveraged for live streaming, with the next fragment made available *just in time*.
* Since the client is in full control of all networking operations, it can quickly anticipate and recover from errors 

In order to keep track of all available quality levels and fragments, adaptive streams always include a small text or XML file that contains basic information of all available quality levels and fragments. This so-called *manifest* is the URL and single entry point for an adaptive stream.

Adaptive streaming clients load the manifest first. Next, they start loading video fragments, generally in the best possible quality that is available at that point in time.



Adaptive streaming solutions
----------------------------

Currently, three adaptive streaming solutions are available to publishers. They follow the same premises, but there's small differences in implementation:

* Apple's `HTTP Live Streaming <http://developer.apple.com/resources/http-streaming/>`_ is probably the most widely used solution today, simply because it is the only way to stream video to the iPad and iPhone. It uses an M3U8 (like Winamp) manifest format and MPEG TS fragments with H264 video and AAC audio. Each fragment is a separate file on the webserver, which makes this solution both easy to use and difficult to scale.
* Microsoft's `Smooth Streaming <http://alexzambelli.com/blog/2009/02/10/smooth-streaming-architecture/>`_ is the most mature adaptive streaming solution, with support for separate audio and text tracks. It uses an XML manifest format and fragmented MP4 files with H264 video and AAC audio. Video streams are stored as a single file on the server, but require specific server support (e.g. in IIS) for playback.
* Adobe's `Dynamic HTTP Streaming <http://adobe.com/>`_ is very similar to Smooth Streaming. It supports XML manifests and fragmented MP4 using H264 video and AAC audio. Video streams are stored as a single file on the server; regular Apache with Adobe's HTTP streaming module installed.

Since these three adaptive streaming solutions are so similar, third-party software exists to simultaneously stream to all three formats. Examples are the `Wowza Media Server <http://www.wowzamedia.com/forums/>`_ and the `Unified Streaming Platform <http://www.unified-streaming.com/>`_. 

Even more promising are the standardization efforts around MPEG's DASH (Dynamic Adaptive Streaming for HTTP) and W3C's HTML5 <video>. DASH aims to become the single umbrella solution for HTTP adaptive streaming.

Sadly, none of these solutions can work with regular MP4 files. At the very least, your existing MP4 files need to be transmuxed from regular MP4 (1 metadata box, 1 sample box) into either fragmented MP4 (lots of metadata/sample pairs) or TS (transport stream) fragments. Apple, Microsoft and Adobe each supply a tool for this, but support for these formats in regular video editors and transcoding tools hasn't landed yet.
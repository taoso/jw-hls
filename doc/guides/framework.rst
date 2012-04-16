.. _framework:

About the Adaptive Framework
============================

This guide offers an introduction to the Adaptive framework; what it is, what it does and how it can be used.



Introduction
------------

The adaptive framework is an ActionScript 3 framework for parsing, muxing and playing adaptive streams in Flash. Two implementations of the framework currently exist:

* A provider that can be loaded into the JW Player 5. This implementation is for publishers who want to do actual adaptive streaming in production.
* A chromeless player that can be controlled from javascript. This implementation is for developers who want to experiment with adaptive streaming, or those who what to build a fully customized interface.

Both the JW Player provider and the chromeless player need only one option to get started: the URL to an adaptive stream. Under the premise of *It Just Works*, no other options for tweaking the framework are available (yet).

.. note::

   The adaptive framework requires a client to have at least Flash Player version 10.1 installed. This is the version that introduced the ability to load binary data into the video decoding pipeline. With an `install base of about 70% <http://riastats.com/>`_, this version is not yet ubiquitous.



Solutions support
-----------------

In a nutshell, support for the various adaptive streaming solutions is as follows:

.. describe:: Apple HTTP Live Streaming

   The framework supports Apple HTTP Live streaming for both Live and on-demand. Streams created by Apple's *mediafilesegmenter* as well as those from the USP and Wowza servers work.

.. describe:: Microsoft Smooth Streaming

   The framework currently does not support Microsoft Smooth Streaming. However, this is coming. Actionscript developers will find both the manifest parsing and MP4 fragment muxing to be largely implemented. At first, only on-demand streams featuring a single video and audio track (but multiple video qualities) will be supported.

.. describe:: Adobe Zeri (HTTP Dynamic Streaming)

   The framework currently does not support Adobe Zeri (HTTP Dynamic Streaming). Given the incompatibility of this format (can only be played in Flash), supporting it is not a priority at this point. Code commits or valid reasons for doing otherwise are of course welcome.

.. describe:: MPEG DASH

   The framework currently does not support MPEG DASH. Given the chances this might become the umbrella format for HTTP adaptive streaming, support will probably come.



Buffering Heuristics
--------------------

When a file is loaded, the framework first loads and parses the manifest file(s). Next, a number of fragments is loaded sequentially, until a 12 second buffer is filled. The player will at all times try to maintain this buffer, loading an additional fragment if the buffer drops below 100%.

If the buffer drops below 25%, playback will pause and the framework will enter a *BUFFERING* state. If the buffer fills beyond 25%, playback will resume and the framework will enter a *PLAYING* state.

If the framework receives a seek command, the existing buffer is purged. Next, the framework acts exactly the same as on first load: the buffer is filled to 100% seconds, and playback starts when 25% is hit. This implies cached fragments will never be re-used. The framework will always return to the webserver for fragments it might have previously loaded. After all, the environment might have been improved, and the user might now be able to see an HD version of a fragment he previously saw in 240p.

The first fragment that's loaded upon the first start is always of the lowest quality level, so the stream will start fast. Switching heuristics define which subsequent fragments are loaded.



Switching heuristics
--------------------

With the first fragment loaded, the framework's Loader component calculates bandwidth for the first time. It does so by dividing the fragment filesize by the duration of the download. This calculation is repeated after every fragment load. Deciding which fragment to load next is done according to the following decisions:

1. The player loads the highest quality fragment whose bitrate does not exceed 67% of the available bandwidth and whose width does not exceed 150% of the current display size.
2. The player will only switch 1 level up at a give time. So if, at a certain point, rule 1 implies the player should switch from level 3 to level 7, it will switch to level 4. Downward switching is not constrained to one level at a time.
3. The player will not take into account levels that are disabled.

Levels can be disabled because they cannot be played back at all (e.g. AAC-only), or because they led to too high a frame *droprate*. This droprate (frames dropped per second) is calculated after each fragment playout. The Loader disables levels according to the following decisions:

1. If the droprate for a fragment exceeded 25% of the framerate, all higher quality levels are disabled for 60 seconds.
2. If the droprate for a fragment exceeded 50% of the framerate, the current quality level is disabled for 60 seconds.
3. The lowest available quality level is never disabled.

.. note::
   
   This 60 seconds timeout ensures the framework will not rule out a quality level entirely, only because the movie contained a fast motion shot - or the viewer was at that time checking his email.



Errors
------

The framework is currently quite punitive towards playback errors. These errors can occur on either the network level  or the parsing / muxing level.

If an error is encountered, the framework resets and throws an error. The error is printed in the JW Player display, or broadcasted through the *onError* event in the chromeless player.
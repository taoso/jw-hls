.. _developers:

Implementing the Framework
==========================

This guide is for developers. It gives an overview of the framework and the chromeless player.



Structure
---------

The framework consists of three major components:

* The *Manifest*, which (re)loads the adaptive streaming manifest and exposes its information.
* The *Loader*, which loads the video fragments. It also keeps track of QOS metrics to decide which quality level to load.
* The *Buffer*, which manages playback and the playback buffer. If the buffer underruns, it requests new fragments from the *Loader*.

A schematic overview of how these three components work together can be seen in the separate **cheatsheet.pdf** file.



API
---

The three core components are wrapped by an *API*, which exposes a number of variables, functions and events to the outside world. The API can be used to e.g. *play*, *pause* and *stop* an adaptive stream, and to retrieve the list of *quality levels* or *QOS metrics*.

Actionscript developers interested in playing adaptive streams in their application need only import the following three classes in their application:

.. describe:: com.longtailvideo.adaptive.Adaptive

   The class that implement all API calls. Simply instantiate it and use the *getVideo()* call to get the video container to place on your stage.

.. describe:: com.longtailvideo.adaptive.AdaptiveEvent

   This class defines all event types fired by the API, plus their possible parameter.

.. describe:: com.longtailvideo.adaptive.AdaptiveState

   This class defines the four playback states of the framework (idle, buffering, paused and playing).

A list of available API calls can be found in the separate **cheatsheet.pdf** file. See the source code of the JW Player provider for an actionscript implementation of the framework.



Chromeless player
-----------------

The chromeless player can be used by javascript developers to provide a customized interface. It does three things:

* Displaying the video (With the correct aspect ratio).
* Forwarding all API calls to javascript.
* Pinging an *onAdaptiveReady(player)* function to signal javascript the player is initialized.

A full overview of all available API calls can be found in the separate **cheatsheet.pdf** file. All getters and setters behave exactly the same as in actionscript. Events can be retrieved by adding listeners to the player, **after** the ready call was fired. Please note the string representations of the functions in below example:

.. code-block:: javascript

    function onAdaptiveReady(player) {
        player.onComplete("completeHandler");
        player.onSwitch("switchHandler");
        player.play("http://example.com/manifest.m3u8");
    };
    function completeHandler() {
        alert("Video completed");
    };
    function switchHandler(level) {
        alert("Video switched to quality level "+level);
    };

A list of available API calls can be found in the separate **cheatsheet.pdf** file. See the source code of the framework's test page for a javascript implementation of the chromeless player.



Contributing
------------

As always, contributions and feedback to the framework are very welcome. We are especially interested in:

* Commits that accelerate the implementation of Smooth Streaming, Adobe Zeri and MPEG DASH.
* Feedback on support with/for the various transcoding and streaming tools out there.
* Actionscript or javascript implementations for third-party players.

Please direct feedback through the `player development section <http://www.longtailvideo.com/support/forums/jw-player/player-development-and-customization>`_ of our support forum.



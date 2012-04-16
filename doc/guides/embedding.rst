.. _embedding:

Embedding an Adaptive Stream
============================

This guide explains how to embed an adaptive stream into your website, using the JW Player. The resulting player will playback the adaptive stream in browsers that support Flash and on iDevices. For browsers that support neither, a download fallback is displayed.



Preparations
------------

If you haven't :ref:`encoded <encoding>` an adaptive stream yet, now would be the time. In addition to the adaptive stream, we'll use a plain MP4 encode of the video, for the download fallback. This MP4 version can e.g. be 320x180 pixels (the second quality level in the encoding guide).

A recent version of the JW Player (5.5+) is needed. As of this version, it is possible to set specific video files to load into the specific modes (Flash, HTML5, Download) of the player.

Last, you need the adaptive provider (*adaptive.swf*), since adaptive streaming support is not built into the core JW Player yet.

Copy all these files onto your webserver. A plain webserver will do, since adaptive streaming does not require a specialized streaming server (a big advantage). After uploading, please point your browser directly to one of the *.m3u8* and one of the *.ts* files. When they display or download, all is fine. If they 404, you should add mimetypes for supporting those formats to your webserver configuration. Please refer to your webserver's documentation for more help.

.. note::

   If the player and the stream are hosted at different domains, the domain hosting the adaptive stream **must contain a crossdomain.xml file in its wwwroot**. If not, The Flash plugin will be denied access to the manifest for crossdomain security reasons.



The embed code
--------------

With all the files copied onto your webserver, it's time to craft the embed code. First, make sure you load the JW Player library, e.g. somewhere in the head of your site:

.. code-block:: javascript

   <script type="text/javascript" src="/assets/jwplayer.js"></script>


Next, insert a <div> on your page at the location you want the player to appear:

.. code-block:: javascript

   <div id="container">The player will popup here.</div>
   
Finally, call the player setup script with all the appropriate options. This will ensure the contents of your <div> will be replaced by the JW Player:

.. code-block:: javascript

   <script type="text/javascript>
   jwplayer("container").setup({
      height: 360,
      modes: [
        { type:'flash', 
          src:'/assets/player.swf', 
          provider:'/assets/adaptive.swf', 
          file:'/videos/bbb.manifest.m3u8' },
        { type:'html5', 
          file:'/videos/bbb.manifest.m3u8' },
        { type:'download', 
          file:'/videos/bbb/fallback.mp4' }
     ],
     width: 640
   });
   </script>


The *height* and *width* of the player should be straightforward. The main logic resides in the *modes* block:

* For *flash*, the location to both the player and the adaptive provider is set. Additionally, the manifest file of the video to play is set.
* For *html5*, only the manifest file of the video to play is needed.
* For the *download* mode, the location of the fallback is provided.

This code will first check if a browser supports Flash, loading the player, provider and M3U8 manifest. Next, it will check if a browser supports HTML5. Since all desktop browsers support Flash, this will only leave the iOS browsers. Last, for all devices that support neither Flash nor HTML5 (e.g. Android < 2.2 or WinPho7), the download fallback is provided.



Live streaming
--------------

Live adaptive streaming can be done with e.g. the Wowza Media Server 2.0+. The server will take care of generating the TS fragments and manifest files, so you only need to upload the JW Player assets and provider.

The embed code setup is more or less the same, with the exception there's no download fallback. Instead, you could place a more descriptive message in the <div>, since the player will not overwrite the contents of this <div> if it cannot display anything. Example:

.. code-block:: javascript

   <div id="container">This live stream can only be watched in Flash or iOS</div>
   
   <script type="text/javascript>
   jwplayer("container").setup({
      height: 360,
      modes: [
        { type:'flash', 
          src:'/assets/player.swf', 
          provider:'/assets/adaptive.swf', 
          file:'http://example.com/live/manifest.m3u8' },
        { type:'html5', 
          file:'http://example.com/live/manifest.m3u8' }
     ],
     width: 640
   });
   </script>



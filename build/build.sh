# This is a simple script that compiles the plugin using MXMLC (free & cross-platform).
# Learn more at http://developer.longtailvideo.com/trac/wiki/PluginsCompiling
# To use, make sure you have downloaded and installed the Flex SDK in the following directory:

FLEXPATH=/home/lusurf/Apps/flex_sdk_4.6

echo ""
echo "Compiling helloOSMF.swf"
echo ""

$FLEXPATH/bin/mxmlc ../src/com/lusurf/HelloOSMF.as -sp ../src -o ../helloOSMF.swf -use-network=false -optimize=true -incremental=false -target-player="11.1" -static-link-runtime-shared-libraries=true -default-size 480 270 -default-background-color=0x000000
echo ""
echo "Compiling chromelessPlayer.swf"
echo ""

$FLEXPATH/bin/mxmlc ../src/ChromelessPlayer.as -sp ../src -o ../chromelessPlayer.swf -use-network=false -optimize=true -incremental=false -target-player="11.1" -static-link-runtime-shared-libraries=true -default-size 480 270 -default-background-color=0x000000

echo ""
echo "Compiling adaptiveProvider.swf"
echo ""

$FLEXPATH/bin/mxmlc ../src/com/longtailvideo/jwplayer/media/AdaptiveProvider.as -sp ../src -o ../adaptiveProvider.swf -library-path+=../libs -load-externs=../libs/jwplayer-5-classes.xml  -use-network=false -optimize=true -incremental=false -target-player="11.1" -static-link-runtime-shared-libraries=true

#cp ../adaptiveProvider.swf ~/Workspace/hello/assets/adaptiveProvider_debug.swf

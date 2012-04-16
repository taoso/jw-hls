FLEXPATH=/home/lusurf/Apps/flex_sdk_4.6

echo ""
echo "Compiling helloOSMF.swf"
echo ""

$FLEXPATH/bin/mxmlc ../src/com/lusurf/HelloOSMF.as -sp ../src -o ../helloOSMF.swf -use-network=false -optimize=true -incremental=false -target-player="11.1" -static-link-runtime-shared-libraries=true -default-size 480 270 -default-background-color=0x000000
echo ""
echo "Compiling hello.swf"
echo ""

$FLEXPATH/bin/mxmlc ../src/com/lusurf/Hello.as -sp ../src -o ../hello.swf -use-network=false -optimize=true -incremental=false -target-player="11.1" -static-link-runtime-shared-libraries=true -default-size 480 270 -default-background-color=0x000000

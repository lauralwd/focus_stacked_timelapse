### set variables

#output directory
outdir='/home/laura/timelapse'

# do checkups
if sispmctl present

if gphoto2 present

if camera reachable

if ! -d "$outdir"
then exit 1
fi

# Change the light from grow light to photo lights using a GEMBIRD programmable power strip
sispmctl -o 1,2
sispmctl -f 3,4

# Take photo
cd $outdir
gphoto2 --set-config whitebalance=4     \
        --set-config f-number=8         \
        --set-config shutterspeed=1/50  \
        --set-config iso=1              \
        --set-config flashmodemanualpower=1/32  \
        --set-config imagequality=4             \
        --capture-image-and-download            \
        --filename=\%Y\%m\%d-%H\%M\%S-\%-03n.\%C


# Change the light back to grow lights.
sispmctl -f 1,2
sispmctl -o 3,4

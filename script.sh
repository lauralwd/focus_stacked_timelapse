### set variables

#output directory
outdir='/home/laura/timelapse'

### do checkups

# is sispmctl present?
if     ! $(which sispmctl)
then   echo '\e[31mERROR: install sispmctl to control the lights\e[0m'
      #exit 1
else   echo '\e[32sispmctl found \e[0m'
fi

#if gphoto2 present
if     [ ! $(which gphoto2) ]
then   echo '\e[31minstall gphoto2 to contol the camera\e[0m'
       exit 1
else   echo '\e[32mOK: gphoto2 found \e[0m'
fi

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

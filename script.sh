### set variables

#output directory
outdir='/home/laura/timelapse'

focusstepsize=500
focusstepcount=10
focusreturn=$(( -1 * focusstepsize * focusstepcount ))

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

#if camera reachable
camera=$(gphoto2 --auto-detect | tail -n +3 | sed 's/usb:.*$//' )
cameras=$(gphoto2 --auto-detect | tail -n +3 | wc -l )
if     [ $cameras -eq 1  ]
then   echo "\e[32mOK: found 1 camera:\e[0m \n$camera \e[0m"
elif   [ $cameras -gt 1 ]
then   echo "\e[31mERROR found more than one camera?! I'm not sure how to deal with this:\e[0m\n\n$camera"
elif   [ $cameras -eq 0 ]
then   echo "\e[31mERROR: no camera found. Make sure it's turned on and confirm it can be found by gphoto2 by running 'gphoto2 --auto-detect'\e[0m"
       exit 1
fi


### prepare
if    [ ! -d "$outdir" ]
then  echo "\e[34mINFO: creating directory $outdir to store photo's \e[0m"
      mkdir "$outdir"
else  echo "\e[34mINFO: Found $outdir to store photo's \e[0m"
fi

# automatically unmount camera filesystem?

# Change the light from grow light to photo lights using a GEMBIRD programmable power strip
#sispmctl -o 1,2
#sispmctl -f 3,4


### make the photo

# use gphoto2 --list-config to lear about all specific options available
# use gphoto2 --get-config to learn more about the syntax and possibilities of a specific option 
# these may differ per camera model

# imagequality 2:FineJPEG  4: RAW+basicJPEG 6:RAW+FineJPEG

cd $outdir

#gphoto2 --capture-preview
take_picture () {
gphoto2 --set-config whitebalance=4     \
        --set-config f-number=4         \
        --set-config shutterspeed=1/10  \
        --set-config iso=0              \
        --set-config imagequality=2     \
        --capture-image-and-download            \
        --filename=\%Y\%m\%d-%H\%M\%S-\%03n-d$d.\%C
}


d=0
take_picture

for i in $(seq 1 1 $focusstepcount)
do  if   [ -f ./capture_preview.jpg ]
    then rm ./capture_preview.jpg
    fi
    gphoto2 --capture-preview --set-config /main/actions/manualfocusdrive="$focusstepsize"
    d=$i
    take_picture
    rm ./capture_preview.jpg
done


rm ./capture_preview.jpg
gphoto2 --capture-preview --set-config /main/actions/manualfocusdrive=-15000

### finish up

# Change the light back to grow lights.
#sispmctl -f 1,2
#sispmctl -o 3,4

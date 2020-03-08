### set variables

#output directory
outdir='/home/laura/timelapse'
prefix=$(date '+%Y%m%d-%H%M'  )

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

#if hugin-tools present
if     [ ! $(which align_image_stack) ]
then   echo '\e[31minstall hugin-tools to automatically align the images for subsequent focusstacking \e[0m'
       exit 1
else   echo '\e[32mOK: hugin-tools found \e[0m'
fi

#if hugin-tools present
if     [ ! $(which enfuse) ]
then   echo '\e[31minstall enfuse to automatically stack the aligned images\e[0m'
       exit 1
else   echo '\e[32mOK: enfuse found \e[0m'
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


### configure photo settings

# use gphoto2 --list-config to lear about all specific options available
# use gphoto2 --get-config to learn more about the syntax and possibilities of a specific option
# these may differ per camera model

# imagequality 2:FineJPEG  4: RAW+basicJPEG 6:RAW+FineJPEG

take_picture () {
gphoto2 --set-config whitebalance=4     \
        --set-config f-number=4         \
        --set-config shutterspeed=1/10  \
        --set-config iso=0              \
        --set-config imagequality=2     \
        --capture-image-and-download            \
        --filename=$prefix-d$d.\%C
}


### take the photos!
if    [ $focusstepcount -gt 0 ]
then  echo "\e[34mINFO: Making a focus stack! storing images in $outdir/$prefix \e[0m"
      mkdir "$outdir/$prefix"
      cd    "$outdir/$prefix"
elif  [ $focusstepcount -eq 0 ]
then  cd "$outdir"
fi

d=0
take_picture

if   [ $focusstepcount -gt 0 ]
then for i in $(seq 1 1 $focusstepcount)
     do  if   [ -f ./capture_preview.jpg ]
         then rm ./capture_preview.jpg
         fi
         gphoto2 --capture-preview --set-config /main/actions/manualfocusdrive="$focusstepsize"
         d=$i
         take_picture
         rm ./capture_preview.jpg
     done
fi

gphoto2 --capture-preview --set-config /main/actions/manualfocusdrive="$focusreturn"
rm ./capture_preview.jpg

### finish up
if    [ $focusstepcount -gt 0 ]
then  echo "\e[34mINFO: Aligning images for stacking \e[0m"
      cd "$outdir"
      cp "$prefix"/"$prefix"-d0.jpg "$prefix"/"$prefix"-d00.jpg
      align_image_stack -m -a "$prefix"/*.jpg -a "$prefix"/"$prefix"_aligned --gpu
      echo "\e[34mINFO: Stacking images \e[0m"
      enfuse --exposure-weight=0      \
             --saturation-weight=0    \
             --contrast-weight=1      \
             --hard-mask              \
             --compression=jpeg       \
             --output="$prefix"_stacked.jpg \
             "$prefix"/"$prefix"_aligned*.tif
      rm -f "$prefix"/"$prefix"_aligned*.tif
      rm -f "$prefix"/"$prefix"-d00.jpg
      prefix_stacked=$(echo "$prefix"_stacked)
      echo "\e[32mINFO: Stacked image available at $prefix_stacked.jpg \e[0m"
fi

# Change the light back to grow lights.
#sispmctl -f 1,2
#sispmctl -o 3,4

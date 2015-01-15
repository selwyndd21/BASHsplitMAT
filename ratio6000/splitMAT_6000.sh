#!/bin/sh
# Variable Preservation:
# 
#
#


###############################################################################
# Option definition
###############################################################################

####################
# Default parameters
####################
fileCE="mapCE.txt"
fileSAB="mapSAB.txt"
fileT="mapTemperature.txt"

# Locate the readflux_xsdrn.sh
SCRIPT=`basename ${BASH_SOURCE[0]}`
ScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#Help function
function HELP {
  echo -e "Help documentation for ${SCRIPT}."\\n
  echo -e "Basic usage: $SCRIPT file.out"\\n
  echo "Command line switches are just for demo."
  echo "The following switches are recognized."
  echo "-c  --Sets the temperature map for CE library for \$fileCE. Default: ${fileCE}."
  echo "-s  --Sets the temperature map for CE library for \$fileSAB. Default: ${fileSAB}."
  echo "-t  --Sets the temperature file for materials \$fileT. Default: ${fileT}."
  echo -e "-h  --Displays this help message. No further functions are performed."\\n
  echo -e "Example: $SCRIPT file.out"\\n
  exit 1
}



####################
# ERROR code: no any parameters
####################
opt=$#
if [ $opt -eq 0 ]; then
  echo "ERROR: No parameters nor inputs. Noting should be done!"
  echo
  HELP
  exit 2
fi

#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Read Options and Parameters Section:
#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
while getopts ":c:s:t:h" opt; do
  case $opt in
    c)
      fileCE=${OPTARG}
      ;;
    s)
      fileSAB=${OPTARG}
      ;;
    t)
      fileT=${OPTARG}
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      exit 2
      ;;
    h)  #show help
      HELP
      exit 1
      ;;
    :)
      echo " -$OPTARG requires an argument."
      echo -e "Use $SCRIPT -h to see the help documentation."\\n
      exit 2
      ;;
  esac
done
shift $((OPTIND-1))  #This tells getopts to move on to the next argument.
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
# End Options and Parameters section.
#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


####################
# ERROR code: check the input parameters
####################
inpfile=$*
if [[ -z "$inpfile" ]]; then
  echo "ERROR: no input file designated"
  exit 2
fi


########################################
# Input information
########################################
echo "CEmap: $fileCE, SABmap: $fileSAB, material temperature files: $fileT"
echo "Input file: $inpfile"

########################################
# Read Map for mx, mtx, and material temperature
########################################
i=0
while read line1 line2; do
  mCard[i]=$line1 # Put it into the array
  tCard[i]=$line2 # Put it into the array
  i=$(($i + 1))
done < $fileT
mNum=${#mCard[@]}  # array length
echo "Material Temperatures: $mNum"

################################################################################
# Main program
##  Line processing by flag == true
##  Condition for every line:
##  1. ^m[0-9]            : flag = true; calculate() and split();
##  2. ^mt                : flag = true; split();
##  3. ^\ && flag == true : calculate() and split();
##  else                  : print the line;
################################################################################
inpdata=(${inpfile// / })
length=${#inpdata[@]}
if [[ -f $MAT ]]; then
  rm m[0-9]*
  rm mt[0-9]*
fi

for (( inputcount=0; inputcount<$length; inputcount++ )) ; do
  inputfile=${inpdata[$inputcount]}
  # set output files name from input file
  filename=$(basename "$inputfile")
  case=${filename%\.*}

  flag=0
  if [[ -f ${case}_pseudo6000.inp ]]; then
    rm ${case}_pseudo6000.inp
  fi
  OLD_IFS=$IFS
  IFS=""
  while read -r line; do 
    # initial variables
    if [[ $flag == 0 ]]; then
      in_temp=5001
    fi
    IFS=$OLD_IFS
    array=($line) # separate lines
    
    ####################
    # Condition 1
    ####################
    if [[ ${array[0]} == [mM][0-9]* ]]; then
      flag=1
      MAT=${array[0]}
      
      ##########
      # find material temperature
      for (( i=0; $i < $mNum ; i++ )); do
        if [[ $MAT == ${mCard[$i]} ]]; then
          in_temp=$(( ${tCard[$i]} ))
          printf "    Condition 1: %5s is %5d K\n" "${array[0]}" "$in_temp"
          break
        fi
      done
      if [[ $(( in_temp)) -gt 5000 ]]; then
        echo "Error: No temperature defined for ${array[0]}!!!"
        echo "Error: Temperature will interpolated: $in_temp"
        exit 2
      fi
      
      if [[ -f $MAT ]]; then
        rm $MAT
      fi
      #////////// Python scripts
      # argv[1]: input Temperature
      # argv[2]: ZAID name
      # argv[3]: ZAID a/o
      # argv[4,5]: mapCE   mapSAB 
      # argv[6]: new mCard file
      #                  argv[1]  argv[2]            argv[3]     argv[4] argv[5]  argv[6]
      python -O split_6000.py $in_temp ${array[1] /\.*c/} ${array[2]} $fileCE $fileSAB ${MAT}
      cat $MAT >> ${case}_pseudo6000.inp
      TinM=$in_temp
      
    ####################
    # Condition 2    
    ####################
    elif [[ ${array[0]} == [mM][tT][0-9]* ]]; then
      MAT=${array[0]}
      flag=1
      printf "    Condition 2: %5s is %5d K\n" "${array[0]}" "$TinM"
      #////////// Python scripts
      # argv[1]: input Temperature
      # argv[2]: ZAID name
      # argv[3]: ZAID a/o
      # argv[4,5]: mapCE   mapSAB 
      # argv[6]: new mCard file
      #                  argv[1]  argv[2]            argv[3]     argv[4] argv[5]  argv[6]
      python -O split_6000.py $TinM    ${array[1] /\.*t/} 0           $fileCE $fileSAB ${MAT}
      cat $MAT >> ${case}_pseudo6000.inp
    ####################
    # Condition 3
    ####################
    elif [[ $flag == 1 ]] && [[ ${array[0]} == [1-9]* ]]; then
#     echo "    --Condition 3."
      if [[ -f ${MAT} ]]; then
        rm ${MAT}
      fi
      #////////// Python scripts
      # argv[1]: input Temperature
      # argv[2]: ZAID name
      # argv[3]: ZAID a/o
      # argv[4,5]: mapCE   mapSAB 
      # argv[6]: new mCard file
      #                  argv[1]  argv[2]            argv[3]     argv[4] argv[5]  argv[6]
      python -O split_6000.py $in_temp ${array[0] /\.*c/} ${array[1]} $fileCE $fileSAB ${MAT}
      cat $MAT >> ${case}_pseudo6000.inp
      TinM=$in_temp
    ####################
    # Condition 4
    ####################
    else
      IFS=""
      flag=0
      echo $line >> ${case}_pseudo6000.inp
    fi
    IFS=""
  done < $filename
  sed -i "s/0.0000E+00//g" ${case}_pseudo6000.inp
done

rm m[0-9]*
rm mt[0-9]*

exit

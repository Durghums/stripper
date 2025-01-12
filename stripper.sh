#!/bin/bash
OPT=$1

if [ -z "$OPT" ] || [ `echo "$OPT" | grep -Ev [ptsm]` ]
then
  echo -e "\033[38;5;138m\033[1mUSAGE: \033[0m"
  echo -e "\t\033[38;5;138m\033[1mstripper.sh\033[0m [\033[4mOPTIONS\033[0m]\n"
  echo -e "\033[38;5;138m\033[1mOPTIONS\033[0m"
  echo -e "\tPick one or more, no spaces between. Operations take place in the order below."
  echo -e "\n\t\033[38;5;138m\033[1mp\033[0m\tConvert periods and underscores to spaces in file and directory names."
  echo -e "\n\t\033[38;5;138m\033[1ms\033[0m\tSearch and remove pattern from file and directory names."
  echo -e "\n\t\033[38;5;138m\033[1mt\033[0m\tTrim directory names after title and year."
  echo -e "\n\t\033[38;5;138m\033[1mm\033[0m\tMatch filenames to parent directory names.\n"
  
  exit 0
fi

#-------------------------------------------------------------------------- Make periods and underscores into spaces

if echo "$OPT" | grep -q 'p'
then
  echo -n "Converting underscores and periods to spaces...    "

  for j in *
  do

    if [ -d "$j" ]
    then
      rename -E 's/\_/\ /g' -E 's/\./\ /g' "$j"
    elif [ -f "$j" ]
    then
    	rename -E 's/\_/\ /g' -E 's/\./\ /g' -E 's/ (...)$/.$1/' "$j"
    fi

  done

  echo "done"
fi

#------------------------------------------------------------------Search and destroy

if echo "$OPT" | grep -q 's'
then
  echo "Remove search pattern from filenames:"
  echo "Show file/directory list? y/n"
  read CHOICE

  if [ "$CHOICE" = "y" ]
  then
    echo
    ls -1
    echo
  fi

  echo "Enter pattern to be removed from filenames: "
  IFS=
  read SPATT
  echo -n "Removing pattern \"$SPATT\"...    "
  SPATT=`echo "$SPATT" | sed -e 's/\[/\\\[/g' -e 's/\]/\\\]/g' -e 's/ /\\\ /g' -e 's/\./\\\./g'\
														 -e 's/{/\\\{/g' -e 's/}/\\\}/g' -e 's/\!/\\\!/g' -e 's/\&/\\\&/g' `				#Escape out all special characters so it works in sed
  for i in *
  do
    FNAME=`echo "$i" | sed s/"$SPATT"//`
    if [ "$i" != "$FNAME" ]
    then
      mv "$i" "$FNAME"
    fi
  done

  echo "done"
fi

#------------------------------------------------------------------Trim directory names after year

if echo "$OPT" | grep -q 't'
then
  echo -n "Trimming directory names after title and year...    "
  for h in *
  do

    if [ -d "$h" ]
    then
      FNAME=`echo "$h" | sed 's/\[\ www\.Torrenting\.com\ \]\ \-\ //' | sed 's/1080//' | sed 's/1400//'`
      EARLY="$FNAME"
      FNAME=`echo "$FNAME" | sed 's/\(^.*([0-9]\{4\})\).*$/\1/'`      #this won't do anything unless the year is in parentheses

      if [ "$FNAME" = "$EARLY" ]                                      #testing whether parentheses-dependent sed command did anything
      then
        FNAME=`echo "$FNAME" | sed 's/\(^.*[0-9]\{4\}\).*$/\1/'`      #if not, trim after last digit in year
        FNAME=`echo "$FNAME" | sed 's/\([0-9]\{4\}\)/(\1)/'`          #and then add parentheses around year
        mv "$h" "$FNAME"                                              #and rename
      else
      	mv "$h" "$FNAME"                                              #if the parentheses-dependent sed worked, just rename it
      fi

    fi

  done
  rename 's/\[\(/\(/' *
  rename 's/\(\(/\(/' *
  echo "done"
fi

#------------------------------------------------------------------Match file names to parent directory names

if echo "$OPT" | grep -q 'm'
then

	echo -n "Matching filenames to parent directory names and deleting junk files...    "

	for h in *
	do

		if [ -d "$h" ]
		then
			rename 's/ /_/g' "$h"					#replace spaces in directory names
		fi															#with underscores so mv doesn't choke

	done

	for i in *
	do

		if [ -d "$i" ]
		then
			cd "$i"

			for j in *
			do
				rename 's/ /_/g' *				#replace spaces with underscores
			done												#in all filenames in each subdirectory

			cd ..
		fi

	done


	for k in *
	do
	
		if [ -d "$k" ]
		then
			cd "$k"																		#go into each directory
			find ./ -regex ".*[sS]ample.*" -delete		#take out the trash
			NEWN="$k"																	#NEWN="directory name"
			
			for m in *
			do
				EXTE=`echo $m | sed 's/^.*\(....$\)/\1/'`				#read file extension into EXTE
				if [ "$EXTE" = ".mp4" -o "$EXTE" = ".m4v" -o "$EXTE" = ".mkv" -o "$EXTE" = ".avi" ]
				then
					mv -n $m "./$NEWN$EXTE"	
						
				elif [ "$EXTE" = ".srt" ]
				then
					FISI=`du "$m" | sed 's/\([0-9]*\)\t.*/\1/'`		#check to see if .srt file is actually real\
					if [ "$FISI" -gt 10 ]													#subtitles or just a few words based on file size
					then
						mv -n $m "./$NEWN.eng$EXTE"									#if it's legit, rename it
					else
						rm $m																				#if it's not, delete it
					fi
						
				elif [ "$EXTE" = ".sub" -o "$EXTE" = ".idx" ]
					then
					mv -n $m "./$NEWN.eng$EXTE"
				
				elif [ "$EXTE" = ".nfo" -o "$EXTE" = ".NFO" -o "$EXTE" = ".sfv" -o "$EXTE" = ".exe" -o "$EXTE" = ".txt" -o "$EXTE" = ".jpg" -o "$EXTE" = ".JPG" -o "$EXTE" = ".png" -o "$EXTE" = "part" ]
					then
					rm $m																					#delete all extra junk files
				fi
				
			done
			cd ..
		fi
		
	done

																	#turn all the underscores back into spaces
	rename 's/_/ /g' *							#in directory names...

	for n in *
	do
		if [ -d "$n" ]
		then
			cd "$n"
			for p in *
			do
				rename 's/_/ /g' *				#...and files within directories
			done
			cd ..
		fi
	done
	
fi

#-----------------------------------------------------------------------List directories and files

echo "done"

echo

for  i in *
do
  if [ -f "$i" ]
  then
    echo -e "\033[34m$i\033[0m"
  elif [ -d "$i" ]
  then
    echo -e "\033[32;4m$i\033[0m"
    cd "$i"

    for j in *
    do
      if [ -f "$j" ]
      then
        echo -e "\t\033[34m$j\033[0m"
      elif [ -d "$j" ]
      then
        echo -e "\t\033[32;4m$j\033[0m"
      fi
    done
    echo
    cd ..
  fi

done

echo


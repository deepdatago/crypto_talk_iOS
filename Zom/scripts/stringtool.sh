#!/bin/bash

function showUsageAndExit {
    echo
    echo "Usage: $0 file file <operation> [file <operation> ...]";
    echo
    echo "file: any iOS strings file, encoded in UTF-16 or UTF-8"
    echo "operation: currently only -union supported"
    echo
    exit
}

function union {
    local count_0=0
    local count_1=0
    while [ "x${keys_1[count_1]}" != "x" ]
    do
	comment="${comments_1[count_1]}"
	key="${keys_1[count_1]}"
	value="${values_1[count_1]}"
	((count_1++))

	# Try to find it
	count_0=0
	found=0
	while [ "x${keys_0[count_0]}" != "x" ]
	do
	    key_0="${keys_0[count_0]}"
	    if [ "$key_0" == "$key" ]; then
		found=1
		break
	    fi	    
	    ((count_0++))
	done
	if [[ "$found" -ne 1 ]]; then
	    c=${#comments_0[@]}
	    comments_0["$c"]="$comment"
	    keys_0["$c"]="$key"
	    values_0["$c"]="$value"
	fi
    done
}

function outputStringFile {
    local count=0

    declare -a output_comments=("${!1}")
    declare -a output_keys=("${!2}")
    declare -a output_values=("${!3}")
    while [ "x${output_keys[count]}" != "x" ]
    do
	comment="${output_comments[count]}"
	key="${output_keys[count]}"
	value="${output_values[count]}"
	echo "$comment"
	echo "\"$key\" = \"$value\";"
	echo
	((count++))
    done
}

function parseiOSStringsFile {
    local filePath="$1"

    if [ ! -f "$filePath" ];then
	echo "Error: File $filePath not found!!!"
	return 0
    fi

    #>&2 echo "Parsing file $filePath"
    charset=$(file -I "$filePath" | fgrep -l "charset=utf-16")
    if [ "$charset" == "" ];then
	#>&2 echo "Charset: already UTF-8"
	cp "$filePath" /tmp/temp.strings
    else
	#>&2 echo "Charset: converting to UTF-8"
	iconv -f utf-16 -t utf-8 "$filePath" > /tmp/temp.strings
    fi

    filecontents=$(cat /tmp/temp.strings)

    # Cant set IFS to multichar string, so replace /* with single char \r to act as separator
    changed=$(echo "$filecontents" | sed "s/\/\*/$(printf '\r')/g")

    # Then read into array
    oldIFS="$IFS"
    IFS=$'\r' read -a lines -d '' <<< "$changed"
    IFS="$oldIFS"
    sep=$(printf '\r')
    for linein in "${lines[@]}"
    do
	line=$(echo "/*${linein}" | sed "s/\n/${sep}/g")
	line=$(echo "$line" | sed "s/\*\//${sep}/g")
	line=$(echo "$line" | sed "s/\" = \"/${sep}/g")
	oldIFS="$IFS"
	IFS=$'\r' read -a components -d '' <<< "$line"
	IFS="$oldIFS"

	comment="${components[0]}*/"
	#echo "Comment is $comment"
	key="${components[1]:2}"
	#echo "Key is $key"
	value="${components[2]}"
	value=$(echo "$value" | sed 's/";//g')
	#echo "Value is $value"
	if [ "$key" != "" ]; then
	    #>&2 echo "Adding mapping $key --> $value (comment $comment)"
	    eval "$2[\${#$2[@]}]=\$comment"
	    eval "$3[\${#$3[@]}]=\$key"
	    eval "$4[\${#$4[@]}]=\$value"
	fi
    done
}

nFiles=0

if [[ $# == 0 ]]; then
    showUsageAndExit
fi

# Parse indata
#
while [[ $# > 0 ]]
do
    key="$1"
    case $key in
	-library)
	    return 0
	    ;;
	-h|--help)
	    showUsageAndExit
	    ;;
	-union)
	    if [[ "$nFiles" -ne 2 ]];then
		echo "Error, union needs two files specified"
		exit 1
	    fi
	    union
	    nFiles=1
	    ;;
	*)
	    if [[ "$nFiles" -gt 2 ]];then
		echo "Error, too may files specified"
		exit 1
	    fi
	    declare -a comments_${nFiles}
	    declare -a keys_${nFiles}
	    declare -a values_${nFiles}
	    fileName="$1"
	    parseiOSStringsFile "$fileName" comments_${nFiles} keys_${nFiles} values_${nFiles} 
	    nFiles=$((nFiles + 1))
	    ;;
    esac
    shift # past argument or value
done

#Output result
outputStringFile comments_0[@] keys_0[@] values_0[@]

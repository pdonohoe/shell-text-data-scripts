#!/bin/sh
# script name: diff-files-known-xslt.sh
# Author: Paul Donohoe

# Description: Takes two XML files as arguments, and one or two optional XSLT files as options
# The XSLT files should remove known and accepted differences between the XML files
# Runs the XSLT on the XML files to create one or two temporary XML files
# then compares the results using the diff --ignore-space-change command
# to show unexpected differences

# Useful to compare two branches of eforms-test-notices to detect undocumented differences

# Dependencies: 
# Uses script "xslt", which in turn requires Saxon
# Global variables required: SCRIPTS_PATH

# command options
# -a OPTIONAL : Path to XSLT for file 1
# -b OPTIONAL : Path to XSLT for file 2

# get name of this script
command_name=$(basename "$0");
# get directory of this script
script_path=$(cd "$(dirname "$0")" || exit; pwd);
if [ "$script_path" = "" ] || [ ! -d "$script_path" ] || [ ! -e "$script_path/$command_name" ]; then echo "Variables \$command_name and \$script_path not set correctly for script $command_name"; exit 1; fi;

# set default options values
xslt_for_file_1="";
xslt_for_file_2="";
print_first_filename=0;

# command help
help_usage='
$command_name: Description: Compares two XML files using diff --ignore-space-change, after known and 
          accepted differences have been removed from one or both files using XSLT files given 
          in the options.

Syntax of $command_name:
$command_name  [ -a XSLT file ] [ -b XSLT file ] xml-file xml-file

REQUIRED OPTIONS (at least one of -a or -b is required):
-a Path to XSLT file to convert the first XML file 
-b Path to XSLT file to convert the second XML file

OPTIONAL OPTIONS:
-f      Always output first filename

Examples: 
$command_name  -a "known-xslt-1.xslt" -b "known-xslt-2.xslt" file1.xml file2.xml
find eforms-test-notices-misc-updates/test-viewer  -type f -name "*.xml" | while read -r file; do 
new_file="${file/-misc-updates/}"; '"$command_name"' -a "known-xslt-1.xslt" -b "known-xslt-2.xslt" "$file" "$new_file"; done
';

# retrieve command line options
while getopts "a:b:fh?" getopts_option
do
  case $getopts_option in
    f ) print_first_filename=1;;
    a ) xslt_for_file_1="$OPTARG";;
    b ) xslt_for_file_2="$OPTARG";;
    h | \? ) echo "$help_usage"; exit 0;;	
  esac
done;
# move shell command-line-argument pointer to end of options
shift $((OPTIND - 1));

# there must be exactly two arguments, and they must be existing files
[ "$#" != 2 ] && echo "There must be exactly two arguments;$help_usage" 1>&2 && exit 0;

# note XML file names
xml_file_1="${1-}";
xml_file_2="${2-}"

# validate options

# the arguments must be existing files
[ ! -e "$xml_file_1" ] && echo "Can't find first file $xml_file_1;$help_usage" 1>&2 && exit 0;
[ ! -e "$xml_file_2" ] && echo "Can't find second file $xml_file_2;$help_usage" 1>&2 && exit 0;

# there must be at least one XSLT file, and they must be existing files
[ "$xslt_for_file_1" = "" ] && [ "$xslt_for_file_2" = "" ] && echo "There must be at least one XSLT file in -a or -b;$help_usage" 1>&2 && exit 0;
[ "$xslt_for_file_1" != "" ] && [ ! -e "$xslt_for_file_1" ] && echo "Can't find XSLT file $xslt_for_file_1;$help_usage" 1>&2 && exit 0;
[ "$xslt_for_file_2" != "" ] && [ ! -e "$xslt_for_file_2" ] && echo "Can't find XSLT file $xslt_for_file_2;$help_usage" 1>&2 && exit 0;

# set compare files to original files
compare1="$xml_file_1";
compare2="$xml_file_2";

# create temporary directory for converted XML files as $temp_dir; exit if error
"$SCRIPTS_PATH"/maketempdir || exit;

# run XSLT conversions
if [ "$xslt_for_file_1" != "" ]; then
  # create temporary file; exit on error
  # mktemp does not work according to spec: option -p --tmpdir uses $TMPDIR instead of supplied directory
  temp_file=$(mktemp --tmpdir="$temp_dir" -t tmp.XXXXXXXXXX) || exit;
  # run XSLT to remove known differences
  #xslt -t -f "$xslt_for_file_1" -s "$xml_file_1" -o "$temp_file";
  xslt -f "$xslt_for_file_1" -s "$xml_file_1" -o "$temp_file";
  compare1="$temp_file";
fi
#exit
if [ "$xslt_for_file_2" != "" ]; then
  # create temporary file; exit on error
  # mktemp does not work according to spec: option -p --tmpdir uses $TMPDIR instead of supplied directory
  temp_file=$(mktemp --tmpdir="$temp_dir" -t tmp.XXXXXXXXXX) || exit;
  # run XSLT to remove known differences
  xslt -f "$xslt_for_file_2" -s "$xml_file_2" -o "$temp_file";
  compare2="$temp_file";
fi

# run compare
result="$(diff --ignore-space-change "$compare1" "$compare2" )";

if [ "$print_first_filename" -eq 1 ] || [ "$result" != "" ]; then
  echo "$xml_file_1";
fi;
if [ "$result" != "" ]; then
  echo "$result";
fi;

#!/bin/sh
# script name: diff-files-known-xslt-combined.sh
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
# -a REQUIRED : Path to a single XSLT for both files

# get name of this script
command_name=$(basename "$0");
# get directory of this script
script_path=$(cd "$(dirname "$0")" || exit; pwd);
if [ "$script_path" = "" ] || [ ! -d "$script_path" ] || [ ! -e "$script_path/$command_name" ]; then echo "Variables \$command_name and \$script_path not set correctly for script $command_name"; exit 1; fi;
# get current path
current_path=$(pwd);

# set default options values
xslt_file="";
print_filenames=0;

# command help
help_usage='
$command_name: Description: Compares two XML files using diff --ignore-space-change, after known and 
          accepted differences have been removed from one or both files using XSLT files given 
          in the options.

Syntax of $command_name:
$command_name  [ -a XSLT file ] xml-file xml-file

REQUIRED OPTIONS:
-a Path to XSLT file to convert both XML files

OPTIONAL OPTIONS:
-f      Always output first filename

Examples: 
$command_name  -a "known-xslt.xslt" file1.xml file2.xml
find test-xml-new  -type f -name "*.xml" | while read -r new_file; do 
old_file="$(printf "%s" "$old_file" | sed "s/xml-new/xml-old/")"; 
'"$command_name"' -a "known-xslt.xslt" "$file" "$new_file"; done
';


# retrieve command line options
while getopts "a:fh?" getopts_option
do
  case $getopts_option in
    f ) print_filenames=1;;
    a ) xslt_file_opt="$OPTARG";;
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

# the XSLT file must be specified and must exist
[ "$xslt_file_opt" = "" ] && echo "Option -a is required;$help_usage" 1>&2 && exit 0;

# XSLT file path can be relative or absolute: convert to absolute and exit if it doesn't exist
if [ -e "$xslt_file_opt" ]; 
  then xslt_file=$xslt_file_opt;
else
  if [ -e "$(getabsolutepath "$xslt_file_opt/$current_path")" ]; then
    xslt_file="$xslt_file_opt/$current_path";
  else
    echo "Can't find XSLT file $xslt_file_opt;$help_usage" 1>&2 && exit 0;
  fi;
fi;

# set compare files to original files
compare1="$xml_file_1";
compare2="$xml_file_2";

# create temporary directory for converted XML files as $temp_dir; exit if error
"$SCRIPTS_PATH"/maketempdir || exit;

# run XSLT conversions
# create temporary file; exit on error
# ~\AppData\Local\Temp
# mktemp does not work according to spec: option -p --tmpdir uses $TMPDIR instead of supplied directory
temp_file=$(mktemp --tmpdir="$temp_dir" -t tmp.XXXXXXXXXX) || exit;
# run XSLT to remove known differences
#xslt -t -f "$xslt_file" -s "$xml_file_1" -o "$temp_file";
xslt -f "$xslt_file" -s "$xml_file_1" -o "$temp_file" 'mode=file1';
compare1="$temp_file";

#exit
# create temporary file; exit on error
# mktemp does not work according to spec: option -p --tmpdir uses $TMPDIR instead of supplied directory
temp_file=$(mktemp --tmpdir="$temp_dir" -t tmp.XXXXXXXXXX) || exit;
# run XSLT to remove known differences
xslt -f "$xslt_file" -s "$xml_file_2" -o "$temp_file" 'mode=file2';
compare2="$temp_file";
echo "$compare1 vs $compare2";
# run compare
result="$(diff --ignore-space-change "$compare1" "$compare2" )";

if [ "$print_filenames" -eq 1 ] || [ "$result" != "" ]; then
  echo "$xml_file_1 vs $xml_file_2";
fi;
if [ "$result" != "" ]; then
  echo "$result";
fi;

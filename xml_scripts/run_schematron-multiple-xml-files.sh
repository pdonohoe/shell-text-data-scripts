#!/bin/bash
# script name: run-schematron-multiple-xml-files
# Author: Paul Donohoe
# Description: Converts the given Schematron file to XSLT, using iso_svrl_for_xslt2.xsl
#              Runs the generated XSLT against the given list of XML files as parameters, returning an SVRL report for each one

# Dependencies: 
# Uses script "xslt", which in turn requires Saxon
# Requires: ISO Schematron SVRL (iso_svrl_for_xslt2.xsl and iso_dsdl_include.xsl)
# Global variables required: SCHEMATRON_INCLUDE_FILE, SCHEMATRON_XSL_FILE, ISO_SVRL_PARAMETERS, SVRL_TO_TEXT

# command options
# -s REQUIRED : source schematron file
# -c REQUIRED : Assembled schematron file (default to schematron file's name plus -assembled)
# -x OPTIONAL : Intermediate XSL file (default to schematron file's name plus .xsl)
# -o OPTIONAL : Output SVRL file (default to input XML file's name plus .svrl)
# -p OPTIONAL : Parameters string, to be converted to XML file to be read by source schematron file
#                 Normally used to supply the file location of another XML file
#                 Format: Key:Value[;Key:Value ...]
#                 This option has been designed to allow local testing of change-notices.sch schematron,
#                  which requires a second (parent) XML file for comparison of element values.

# get name of this script
command_name=$(basename "$0");
# get directory of this script
script_path=$(cd "$(dirname "$0")" || exit; pwd);
if [ "$script_path" = "" ] || [ ! -d "$script_path" ] || [ ! -e "$script_path/$command_name" ]; then echo "Variables \$command_name and \$script_path not set correctly for script $command_name"; exit 1; fi;

make_xml_parameters_from_string () {
if [ "$1" = "" ]; then 
    echo "";
    else
    # parameters are separated by ; and key-value pairs of each parameter separated by :
    # read key-value pairs into an array
    IFS=';' read -ra param_array <<< "$1"
    # set parameter xml file header
    local param_file_xml='<?xml version="1.0" encoding="UTF-8"?>'"$new_line"'<parameters>'"$new_line";
    # loop through each item in the array
    for param in "${param_array[@]}"; do
        # only process param if it contains at least one :
        if [ "$( echo "$param" | egrep ":")" != "" ]; then
            param_key=${param%%:*};
            param_value=${param#*:};
            param_xml='<parameter><key>'"$param_key"'</key><value>'"$param_value"'</value></parameter>'"$new_line";
            param_file_xml="$param_file_xml$param_xml";
        fi;
    done
    param_file_xml="$param_file_xml"'</parameters>'"$new_line";
    echo "$param_file_xml";
fi;
}

new_line="$(printf '\n')";

# set default options values
parameters="";
output_text_files=0;

# command help
help_usage="

Syntax of $command_name:
$command_name -s schematron-file [ -c assembled-schematron-file ] [ -x xsl-file ] [ -o svrl-folder ] xml-file [ xml-file ... ]

REQUIRED OPTIONS:

-c FILE   Path to assembled schematron file
OR
-s FILE   Path to schematron file to be assembled

OPTIONAL OPTIONS:
-x        Path to generated XSLT file (default to schematron file's name plus .xsl)
-o        Folder where SVRL files are output (default folder of each input XML file)
-m        Parameter string used when assembling schematron file
-d        Output TEXT files summary of SVRL errors (input XML file's name plus .txt)

Examples: 
$command_name -s change-notices.sch -o ../sch-results ~/test-xml-files/*.xml
";

# retrieve command line options
while getopts "s:o:c:x:p:dh?" getopts_option
do
  case $getopts_option in
    t ) test_query=1;;
    s ) schematron_file="$OPTARG";;
    c ) assembled_sch_file="$OPTARG";;
    o ) svrl_folder="$OPTARG";;
    x ) xslt_file="$OPTARG";;
    d ) output_text_files=1;;
    p ) parameters="$OPTARG";;
    h | \? ) echo "$help_usage"; exit 0;;	
  esac
done;
# move shell command-line-argument pointer to end of options
shift $((OPTIND - 1));


# validate options

# schematron file is required and must exist
[ "$schematron_file" = "" ] && echo "-s (source schematron file) is required;$help_usage" 1>&2 && exit 0;
[ ! -e "$schematron_file" ] && echo "Can't find source schematron file $schematron_file;$help_usage" 1>&2 && exit 0;

# at least one input XML file is required and must exist
[ "$1" = "" ] && echo "at least one source XML file is required;$help_usage" 1>&2 && exit 0;
[ ! -e "$1" ] && echo "Can't find source XML file $1;$help_usage" 1>&2 && exit 0;

# set assembled schematron file
# get assembled schematron file from option -x or default of argument 1 with -assembled appended to basename
[ "$assembled_sch_file" = "" ] && assembled_sch_file="${schematron_file%.*}-assembled.sch";
assembled_sch_file=$(get_abs_filename "$assembled_sch_file");
echo "$assembled_sch_file" 1>&2;

# set output XSL file
# get output file from option -x or default of argument 1 with suffix changed to .xsl
[ "$xslt_file" = "" ] && xslt_file="${schematron_file%.*}.xsl";
xslt_file=$(get_abs_filename "$xslt_file");

# set output SVRL folder
# if option o is specified, get output folder and create it
if [ "$svrl_folder" != "" ]; then
  svrl_folder="$(get_abs_folder "$svrl_folder" )";
  [ -d "$svrl_folder" ] || mkdir -p "$svrl_folder";
fi
# 

# handle any given parameters to the schematron
if [ "$parameters" != "" ]; then 
    param_xml="$(make_xml_parameters_from_string "$parameters")";
    param_xml_file="${schematron_file%.*}-parameters.xml";
    echo "$param_xml" > "$param_xml_file";
fi;

# run XSLT conversions
# assemble schematron from parts
xslt -s "$schematron_file" -f "$SCHEMATRON_INCLUDE_FILE" -o "$assembled_sch_file"

# convert schematron file to XSLT
xslt -s "$assembled_sch_file" -f "$SCHEMATRON_XSL_FILE" -o "$xslt_file" "$ISO_SVRL_PARAMETERS" "$parameters"

# temporary fix for "{2,}" occurring in a pattern for email in SDK schematron XSLT
sed -r -i '/\{2,\}/{s%\{2,\}%{2,10}%}' "$xslt_file";

for xml_file do
  [ ! -e "$xml_file" ] && echo "Can't find source XML file $xml_file" 1>&2;
  if [ "$svrl_folder" != "" ]; then
    svrl_file="$svrl_folder/$(basename "$xml_file")";
    svrl_file="${svrl_file%.*}.svrl";
  else
    svrl_file="${xml_file%.*}.svrl";
  fi;
  echo "$xml_file";
  #echo "$svrl_file";
  # run converted XSLT against input XML file and produce SVRL report
  xslt -s "$xml_file" -f "$xslt_file" -o "$svrl_file"
  if [ "$output_text_files" != "" ]; then
    # set text filename to the svrl basename plus .txt
    text_file="${svrl_file%.}.txt"
    # generate the text file svrltotext
    my_command="xslt -s \"$svrl_file\" -f \"$SVRL_TO_TEXT\" -o \"$text_file\" ";
    if [ "$test_query" = 1 ]; then
      echo "$my_command";
    else
      eval "$my_command";
    fi;
  fi;
done

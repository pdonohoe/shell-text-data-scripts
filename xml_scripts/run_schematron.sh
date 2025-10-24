#!/bin/bash
# script name: run-schematron
# Author: Paul Donohoe
# Description: Converts the given Schematron file to XSLT, using iso_svrl_for_xslt2.xsl
#              Runs the generated XSLT against the given XML file returing an SVRL report

# Dependencies: 
# Uses script "xslt", which in turn requires Saxon
# Requires: ISO Schematron SVRL (iso_svrl_for_xslt2.xsl and iso_dsdl_include.xsl)
# Global variables required: SCHEMATRON_INCLUDE_FILE, SCHEMATRON_XSL_FILE, ISO_SVRL_PARAMETERS

# command options
# -i REQUIRED : Input XML file to be validated
# -s REQUIRED : source schematron file
# OR
# -c REQUIRED : Assembled schematron file (default to schematron file's name plus _assembled)

# -x OPTIONAL : Intermediate XSL file (default to schematron file's name plus .xsl)
# -o OPTIONAL : Output SVRL file (default to input XML file's name plus .svrl)
# -m OPTIONAL : Parameters string ??
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

# default text file is none
text_file="";
# command help
help_usage="

Syntax of $command_name:
$command_name [ -t ] -i xml-file ( -s schematron-file | -c assembled-schematron-file ) [ -x xsl-file ] 
     [ -o svrl-file ] [ -d text-file ] [ -m parameter_string ]

REQUIRED OPTIONS:
-i        Path to source XML file

-c FILE   Path to assembled schematron file
OR
-s FILE   Path to schematron file to be assembled

OPTIONAL OPTIONS:
-x        Path to generated XSLT file (default to schematron file's name plus .xsl)
-o        Output SVRL file (default to input XML file's name plus .svrl)
-d        Output TEXT file summary of SVRL errors (default to input XML file's name plus .txt)
-m        Parameter string used when assembling schematron file
-?        Print this summary

Examples: 
$command_name -s change-notices.sch -i ~/test-xml-files/my-test.xml
";

# retrieve command line options
while getopts "ts:i:x:c:o:d:p:m:h?" getopts_option
do
  case $getopts_option in
    t ) test_query=1;;
    s ) schematron_file="$OPTARG";;
    c ) assembled_sch_file="$OPTARG";;
    o ) svrl_file="$OPTARG";;
    d ) text_file="$OPTARG";;
    x ) xslt_file="$OPTARG";;
    i ) input_file="$OPTARG";;
    p ) parameters="$OPTARG";;
    m ) parameter_string="$OPTARG";;
    h | \? ) echo "$help_usage"; exit 0;;	
  esac
done;
# move shell command-line-argument pointer to end of options
shift $((OPTIND - 1));


# validate options

# at least one of -s or -c option must be given
[ "$schematron_file" = "" ] && [ "$assembled_sch_file" = "" ] && echo "One of options -s or -c must be given;$help_usage" 1>&2 && exit 0;


# if schematron file is given it must exist
if [ "$schematron_file" != "" ]; then
  [ ! -e "$schematron_file" ] && echo "Can't find source schematron file $schematron_file;$help_usage" 1>&2 && exit 1;

  # $SCHEMATRON_INCLUDE_FILE is required and must exist
  [ "$SCHEMATRON_INCLUDE_FILE" == "" ] && echo "Global variable \$SCHEMATRON_INCLUDE_FILE must be defined;$help_usage" 1>&2 && exit 1;
  [ ! -e "$SCHEMATRON_INCLUDE_FILE" ] && echo "Can't find Schematron Include File $SCHEMATRON_INCLUDE_FILE;$help_usage" 1>&2 && exit 1;
fi;

  # $SCHEMATRON_XSL_FILE is required and must exist
  [ "$SCHEMATRON_XSL_FILE" == "" ] && echo "Global variable \$SCHEMATRON_XSL_FILE must be defined;$help_usage" 1>&2 && exit 1;
  [ ! -e "$SCHEMATRON_XSL_FILE" ] && echo "Can't find Schematron XSL File $SCHEMATRON_XSL_FILE;$help_usage" 1>&2 && exit 1;

# schematron file must exist if specified
[ "$schematron_file" != "" ] && [ ! -e "$schematron_file" ] && echo "Can't find source schematron file $schematron_file;$help_usage" 1>&2 && exit 1;

# input XML file is required and must exist
[ "$input_file" = "" ] && echo "-i (source XML file) is required;$help_usage" 1>&2 && exit 1;
[ ! -e "$input_file" ] && echo "Can't find source XML file $input_file;$help_usage" 1>&2 && exit 1;

# set assembled schematron file
# get assembled schematron file from option -c or default of argument 1 with -assembled appended to basename
[ "$assembled_sch_file" = "" ] && assembled_sch_file="${schematron_file%.*}_assembled.sch";
assembled_sch_file=$(get_abs_filename "$assembled_sch_file");

# set output XSL file
# get output file from option -x or default of argument 1 with suffix changed to .xsl
[ "$xslt_file" = "" ] && xslt_file="${assembled_sch_file%.*}.xsl";
xslt_file=$(get_abs_filename "$xslt_file");

# set output SVRL file
# get output file from option -o or default of argument 1 with suffix changed to .xsl
[ "$svrl_file" = "" ] && svrl_file="${input_file%.*}.svrl";
svrl_file=$(get_abs_filename "$svrl_file");

# handle any given parameters to the schematron
if [ "$parameters" != "" ]; then 
    param_xml="$(make_xml_parameters_from_string "$parameters")";
    param_xml_file="${schematron_file%.*}-parameters.xml";
    echo "$param_xml" > "$param_xml_file";
fi;

# run XSLT conversions
# assemble schematron from parts if -s option is given
if [ "$schematron_file" != "" ]; then
  my_command="xslt -s \"$schematron_file\" -f \"$SCHEMATRON_INCLUDE_FILE\" -o \"$assembled_sch_file\" ";
  if [ "$test_query" = 1 ]; then
    echo "$my_command";
  else
    eval "$my_command";
  fi;
fi;

# convert schematron file to XSLT
# Developer note: iso_svrl_for_xslt2.xsl parameter full-path-notation determines the way namespaces are declared in the output svrl:failed-assert @location attribute
# 1 (default) : computer-readable, full namespace uri and position predicate for every element
# e.g.  /*:PriorInformationNotice[namespace-uri()='urn:oasis:names:specification:ubl:schema:xsd:PriorInformationNotice-2'][1]/*:TenderingTerms[namespace-uri()='urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'][1]/*:ProcurementLegislationDocumentReference[namespace-uri()='urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2'][3]/*:ID[namespace-uri()='urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2'][1]
# 2 (hard-coded for now) : human-readable, uses defined namespace prefixes, and only position predicates where required
# e.g. /PriorInformationNotice/cac:TenderingTerms/cac:ProcurementLegislationDocumentReference[2]/cbc:ID
my_command="xslt -s \"$assembled_sch_file\" -f \"$SCHEMATRON_XSL_FILE\" -o \"$xslt_file\" \"$parameter_string\"";
if [ "$test_query" = 1 ]; then
  echo "$my_command";
else
  eval "$my_command";
fi;
# full-path-notation=2

# temporary fix for "{2,}" occurring in a pattern for email in SDK schematron XSLT
sed -r -i '/\{2,\}/{s%\{2,\}%{2,10}%}' "$xslt_file";

# run generated XSLT against input XML file and produce SVRL report
my_command="xslt -s \"$input_file\" -f \"$xslt_file\" -o \"$svrl_file\" ";
if [ "$test_query" = 1 ]; then
  echo "$my_command";
else
  eval "$my_command";
fi;

if [ "$text_file" != "" ]; then
  # if text file is specified as "", use the svrl basename plus .txt
  [ "$text_file" = "" ] && text_file="${svrl_file%.}.txt"
  # generate the text file svrltotext
  my_command="xslt -s \"$svrl_file\" -f \"$SVRL_TO_TEXT\" -o \"$text_file\" ";
  if [ "$test_query" = 1 ]; then
    echo "$my_command";
  else
    eval "$my_command";
  fi;
fi;

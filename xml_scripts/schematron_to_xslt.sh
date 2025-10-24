#!/bin/sh
# script name: schematron_to_xslt
# Author: Paul Donohoe
# Description: Converts the given Schematron file to XSLT, using iso_svrl_for_xslt2.xsl

# Dependencies: 
# Uses script "xslt", which in turn requires Saxon
# Requires: ISO Schematron SVRL (iso_svrl_for_xslt2.xsl)
# Global variables required: SCHEMATRON_XSL_FILE, ISO_SVRL_PARAMETERS

# get name of this script
command_name=$(basename "$0");
# get directory of this script
script_path=$(cd "$(dirname "$0")" || exit; pwd);
if [ "$script_path" = "" ] || [ ! -d "$script_path" ] || [ ! -e "$script_path/$command_name" ]; then echo "Variables \$command_name and \$script_path not set correctly for script $command_name"; exit 1; fi;


# command help
help_usage="

Syntax of $command_name:
$command_name -s schematron-file [ -o xsl-file ] 


Examples: 
$command_name change-notices.sch
";


# retrieve command line options
while getopts "s:o:h?" getopts_option
do
  case $getopts_option in
    s ) schematron_file="$OPTARG";;
    o ) output_file="$OPTARG";;
    h | \? ) echo "$help_usage"; exit 0;;	
  esac
done;
# move shell command-line-argument pointer to end of options
shift $((OPTIND - 1));


# validate options

# schematron file is required and must exist
[ "$schematron_file" = "" ] && echo "-s (source schematron file) is required;$help_usage" 1>&2 && exit 0;
[ ! -e "$schematron_file" ] && echo "Can't find source schematron file $schematron_file;$help_usage" 1>&2 && exit 0;

# set output XSL file
# get output file from option -x or default of argument 1 with suffix changed to .xsl
[ "$output_file" = "" ] && output_file="${schematron_file%.*}.xsl";

# run conversion
xslt -s "$schematron_file" -f "$SCHEMATRON_XSL_FILE" -o "$output_file"  "$ISO_SVRL_PARAMETERS";

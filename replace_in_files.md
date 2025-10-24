
# replace_in_files

This is a powerful standalone perl script for replacing text in multiple files. It uses the perl regex engine to perform multiple replace operations on an arbitrary list of files. 

* Uses perl regex engine
* Simple, single replace operations can be specified using command-line options
* Multiple complex replace instructions can be specified in one file
* Each replace instruction can be single or recursive
* Replace text can be read from separate files
* Replace instruction file can include other replace instruction files
* Original files are backed up for changed files

## Syntax of command

replace_in_files [ -t ] ( -o | -b ) -d output-folder  ( -f script-file | [ -a ] -s search-regex -r replace-regex ) file-to-edit [ ... file-to-edit ]

```
REQUIRED OPTIONS: 
  -d output-folder  - this must be a valid folder path

EITHER:
  -o                - output changed files to given folder
OR:
  -b                - backup original files to given folder

EITHER: 
  -s search-regex   - this must be a valid Perl match regular expression. 
  -r replace-regex  - this must be a valid Perl replace expression. All
                       double quotes must be escaped eg \"bar\". 

  -a  (OPTIONAL)    - the Regex replace is executed repeatedly until no 
                       further changes are made. Note that this is limited 
                       to 100 iterations to avoid infinite loops. 
  -i  (OPTIONAL)    - the Regex search is case-insensitive 

OR: 
  -f script-file     - script-file must be a path to a valid replace_in_files script file.
                      Blank lines or those beginning with # will be ignored 
					  Lines beginning with "INSERTION_FILE:" define files which contents can 
					    be inserted in replace expressions
					  Lines begining with "RIF_FILE:" define the inclusion of separate
					    replace_in_script script files
                      Every other line of the script file must include the
                        -r and -s options, and may include the -a or -i options
                      Replaces are run sequentially on each file. 

OPTIONAL OPTIONS: 
  -t                - Test Mode.  The script runs normally, but does not  
                        change any files

By default, paths to files changed, with number of replacements, are printed to STDOUT

  -v                - Verbose Mode. Output folders, and full list of regexes, are also output to STDOUT
  -q                - Quiet Mode. No report output to STDOUT
  -m                - Minimal Mode. Only the grand total counts are output to STDOUT
  
  -?                - Prints this help, does not run the script. 
  -?  [ option ]    - Prints a help section, does not run the script. 
      d or desc or description - the Description section
      o or opts or options - the Options section
      u or usage - the Usage section
      e or examples - the Examples section
      f or file - the Regex section
      m or mode - the Reporting Mode section
```

## Fatal errors
The following conditions are treated as fatal errors; an error message is sent to STDERR and the script is terminated. No clean-up of replaced files is done.

* Invalid options given in command or in RIF_FILE script
* Invalid combinations of options given in command or in RIF_FILE script
* Required options missing in command or in RIF_FILE script
* No files are given as arguments
* Invalid Search or Replace expressions (Perl syntax is used)
* A RIF_FILE script file cannot be found, or cannot be read
* An INSERTION_FILE file cannot be found, or cannot be read
* An INSERTION_FILE ID is referenced, but not previously declared


## Non-fatal errors
The following conditions are reported to STDERR, and execution of the script will continue.
* A given argument is not a file, it cannot be found, or it cannot be read
* The output file cannot be written to
* A replace operation failed (result of replace on file contents is an empty string)
* A replace operation given as recursive (-a option) results in more than 100 replace iterations

## Specifics of replace

This script is written in Perl, and it uses the Perl regular expression replace - see [Perl regular expression documentation](https://perldoc.perl.org/perlre).

Each file is treated as a single string, the replaces are executed on the whole file.

New files are not output for source files which are unchanged by the script.

## Modifiers

Several modifiers are set for all replaces:

* g - global match - the replace is executed repeatedly in the string
* s - single line - the file is treaded as a single line, so the "." metacharacter matches any character, including a newline.
* ee - RHS as string - evaluate the replace expression (given by the -r option) first as a string, then evaluate the result

A single modifier can be set for each replace instruction:

* i - case-insensitive matching. If the -i option is given for a replace instruction, the i modifier is added to the replace.

No other modifiers are set. This script does not currently allow any other modifiers to be specified; the author found no need for them. 

### Consequences of modifiers

* The metacharacters "^" and "$" match the start of file and end of file respectively. In order to match the start or end of individual lines, the "\n" metacharacter must be used.
* The "ee" modifier allows backreferences specified in the replacement string to be correctly evaluated.


## INSERT_FILE

The entire contents of specified files can be inserted using the INSERT_FILE method.

Files whose contents are to be inserted are defined in a RIF file as follows:

INSERTION_FILE: file-identifier ! path-to-file

The colon after INSERTION_FILE and the ! separating the file-identifier and the path-to-file are mandatory.

The contents of the file can then be inserted by using the file identifier in a replace-regex-expression. The replace instruction is carried out, then afterwards the file identifier is replaced by the contents of the file.


## Recursive RIF_FILE

RIF files can reference other RIF files; this acts like an #include instruction. The replace instructions in these referenced RIF files are included in the overall set of replace instructions. The inclusion is recursive, so RIF files referenced from the main RIF file can themselves reference RIF files.

RIF files are defined in a RIF file as follows:

RIF_FILE: [:]path-to-file

If the colon before the path-to-file is included, the path is relative to that of the container RIF file. Otherwise, it is relative to the current path.

## RIF files to convert HTML files into valid XML files
Several RIF files for converting HTML files into valid XML files are included in this repository. These have been generated from the Wikipedia page https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references in August 2025. The XSLT file generating these files is also included in this repository: `wp_chars_to_rif_files.xslt`

### RIF files converting HTML named entities into numeric entity references, based on each ISO subtype
html_clean_entities_ISOamsa.rif
html_clean_entities_ISOamsb.rif
html_clean_entities_ISOamsc.rif
html_clean_entities_ISOamsn.rif
html_clean_entities_ISOamso.rif
html_clean_entities_ISOamsr.rif
html_clean_entities_ISObox.rif
html_clean_entities_ISOcyr1.rif
html_clean_entities_ISOcyr2.rif
html_clean_entities_ISOdia.rif
html_clean_entities_ISOgrk3.rif
html_clean_entities_ISOlat1.rif
html_clean_entities_ISOlat2.rif
html_clean_entities_ISOmfrk.rif
html_clean_entities_ISOmopf.rif
html_clean_entities_ISOmscr.rif
html_clean_entities_ISOnum.rif
html_clean_entities_ISOpub.rif
html_clean_entities_ISOtech.rif
html_clean_entities_new.rif

### A single RIF file "including" all the above ISO subtype RIF files
html_clean_entities_all.rif

### A single RIF file for closing void elements such as <img ...>
html_close_void_elements.rif

### A single RIF file "including" all the above RIF files
html_clean.rif



## Author's use case
I work in publishing, where data content is created as XML files. These are then processed by a publishing system to HTML files to be published on a website. I need to check the quality and content of these HTML files. But as there are many HTML files, and many quality checks, I need the checks to be partly automated. In particular, I need to do two types of checks:

1. Compare the text content in the HTML against the source data in the XML. 
2. Compare two HTML files visually.

For check 1, I need to extract the text at particular locations in the HTML file; I normally do this using XQuery, so the HTML files must be valid XML. But the publishing system creates HTML files that are not valid XML, and need many changes to make them valid HTML.

For check 2, the HTML files produced by the publishing system are intended to be viewed within a website. The HTML files contain a lot of CSS and javascript-produced styling, which works well within the website. However I am not able to replicate the environment of the website, so the HTML files do not display well on my system. The header, footer and left-hand-side menu area are also inconvenient.

So I need to convert many HTML files in the same way:

1. Execute many search-and-replace instructions to replace for example:
  1. Non-closed HTML tags such as <br> to XML-valid self-closing elements such as <br/>
  2. HTML character references such as "\&Atilde;" to XML-valid Unicode character references such as "\&#195;"
2. Remove all <script> and <style> elements, and insert my own CSS styling
3. Remove HTML elements for the header, footer and LHS menu area.

All of this can be done in a single replace_in_files command with a set of RIF files.

```
find html_files | xargs -d'\n' replace_in_files -d xml_files -o -f html_clean.rif
```

# XML processing scripts

These scripts process XML files using XQuery, XSLT or Schematron. They are intended to be run from a Unix command-line shell. They are effectively wrappers around the [Saxon XML processor](https://www.saxonica.com/documentation12/documentation.xml), providing simplified interfaces and adding additional functionality. These scripts were developed and tested using [Saxon HE 1.12](https://www.saxonica.com/html/documentation12/about/index.html); no guarantee is given that they will work with other XML processors. Saxon HE 1.12 supports XSLT versions 1.0, 2.0 and 3.0, and XQuery versions 1.0, 3.0 and 3.1.

The scripts use bash-specific arrays, so are not POSIX compliant.

These scripts were developed to satisfy particular needs of the author. Only some of the available options provided by Saxon are used.

## Required variables

Most of these scripts require certain variables to be defined.

| Variable | Required value |
| --- | --- |
| \$TMPDIR | File path to a directory with read/write permissions |
| \$SCRIPTS_PATH | File path to directory holding this github repository |
| \$XSLT_CLASS_PATH | Java Classpath where the Java jar files for an XSLT processor (such as Saxon ) exist |
| \$XSLT_CLASS | The Java Class used by the XSLT processor |
| \$XSLT_OPTIONS | Any options to use for the XSLT processor |
| \$XQUERY_CLASS_PATH | Java Classpath where the Java jar files for an XQuery processor (such as Saxon ) exist |
| \$XQUERY_CLASS | The Java Class used by the XQuery processor |
| \$SCHEMATRON_INCLUDE_FILE | The filepath to iso_dsdl_include.xsl Schematron inclusion preprocessor |
| \$SCHEMATRON_XSL_FILE | The filepath to iso_svrl_for_xslt2.xsl Schematron XSLT compiler |
| \$ISO_SVRL_PARAMETERS | The parameters to use for Schematron |
| \$SVRL_TO_TEXT | The filepath to svrl_to_text.xsl |

## xslt

This script is a wrapper around the [Saxon command-line Java XSLT processor](https://www.saxonica.com/documentation12/index.html#!using-xsl/commandline). It simplifies the call to the command, by supplying default parameters, and can optionally reformat the output so that XML tags do not span multiple lines.

It provides extra parameters to the called XSLT stylesheet:

| parameter | contains |
| --- | --- |
| execute_path | path to the current (execution) folder |
| xslt_file | XSLT file called |
| scripts_path | path to the location of this script |
| input_file | The input file, if supplied |
| output_file | The output file, if supplied |
| main_template | The main template to call, if no input file is given |

Additional parameters can be included using the -p option.

The output can be formatted:

| option | format |
| --- | --- |
| -l | XML tags / leaf XML elements are not split across multiple lines
| -e NUM | run the Linux "expand" command on the output, replacing X leading tabs with X * NUM spaces |
| -u NUM | run the Linux "unexpand" command on the output, replacing X leading blanks with X * NUM tabs |


## xquery

This script is a wrapper around the [Saxon command-line Java XQuery processor](https://www.saxonica.com/documentation12/index.html#!using-xquery/commandline). It simplifies the call to the command, by supplying default parameters and reading the prolog from a file. The body of the XQuery can be supplied on the command line or from a file. The script can also reformat the output in different ways.

To avoid having to include namespace declarations and imported modules with every query, these can be specified in a separate file. Another file containing other commonly-used XQuery settings can also be included. To increase portability, global or local variables can be referenced within these files, and the references will be substituted by the values of those variables.

This means that the XQuery code supplied on the command line, or from a file, can be a partial XQuery, even a single `return` statement.

There are options for formatting and post-processing the result.

To assist portability, a mechanism for substitution of variable references is included.

| Option | Option argument | Action |
| --- | --- | --- |
| s | FILE | The source XML file |
| q | Partial XQuery | The last part of the XQuery, supplied as a string on the command line |
| f | Partial XQuery | The last part of the XQuery, supplied as a file |
| d | - | The default XQuery prolog contained in file `xq_prolog` |
| p | FILE | An alternative XQuery prolog file |
| a | FILE | A second XQuery prolog file |
| o | - | Does not output the XML declaration |
| x | - | Removes the XML namespace declarations from the output |
| e | - | Expands self-closing empty elements (<elem/> -> <elem></elem>) |
| i | - | Indents the output XML |
| l | - | Removes empty <xqstring/> elements. Adds a newline after every closing </xqstring> Element |
| t | - | Outputs the constructed Java command to STDERR, does not run the command |

### Discussion

#### XQuery construction

The main intention of the different options to construct the XQuery to run is to avoid having to include frequently-used parts of XQuery in the command line each time. For most users, there are a small number of variations of namespace declarations (and module imports) that are frequently used. These can be abstracted away into one or more separate files.

The -q and -f options (which supply the main part of the XQuery) are mutually exclusive. 
The -d and -p options (which supply the XQuery prolog) are mutually exclusive. 
The -d option was added to provide a default prolog to use, to avoid having to specify a filepath every time.

The final XQuery sent to the Saxon XQuery processor is constructed as follows:

* Either the default XQuery prolog from file `xq_prolog` (option -d), or the alternative XQuery prolog from the file specified by option -p, or nothing
* Either the middle XQuery section from the file specified by option -a, or nothing
* The last part of the XQuery, either from the file specified by option -f, or the string in the command line command after option -q

The file `xq_prolog` included in this repository contains many common XML namespace declarations, plus those used by the author for [eForms](https://docs.ted.europa.eu/eforms/latest/schema/schemas.html#_namespaces). It also contains `import module` XQuery commands, with variable references to improve portability.

#### Variable substitutions

Variable references within the prolog section of the constructed XQuery may be substituted with their values.

The text "SCRIPTS_PATH" within the prolog is substituted with the value of variable $SCRIPTS_PATH. This is intended to allow 

#### Output formatting

Saxon formats the output depending on the content: 

> The Saxon command line processor for XQuery by default produces the output by converting the result sequence to a document following the rules of the XQuery document{} constructor, and then serializing this document.

Saxon version 12 (and possibly earlier versions) has options for other output formats; however the author has not catered for these in this script.

There are two typical output types of an XQuery: XML and text. 

##### XML output
When the result of an XQuery contains XML nodes, Saxon by default includes an XML declaration and any namspaces which are in scope for the output XML elements. These can be useful when the desired output is a valid XML file, or the output is to be further processed as XML. The option -i includes the `!indent=yes` parameter to Saxon, which results in the outut XML being indented.

However, often the XML declaration and XML namespace declarations are not needed, and complicate the output. The options -o and -x remove the XML declaration and in-scope namespace declarations.


#### Text output

When the XQuery result is a sequence of text nodes, Saxon returns these without embedding them in XML elements, and without any applied format. It can be useful to have the text output in a more structured form, especially in TSV format. While this is not difficult with Saxon 12, earlier versions are not consistent in their output.

A specific solution was developed for this, using the element `xqstring`. After the result output has been generated by Saxon, empty `xqstring` elements are removed, and then the content of the remaining `xqstring` elements are placed on separate lines: starting `<xqstring>` tags are removed, and closing `</xqstring>` tags are replaced by newline characters (`&#10;`). This allows fine control over the output that is consistent across versions of Saxon.

#### Example usage



## xquery_files

This script is an extension of the `xquery` script described above. It can be used to execute the same XQuery on an [arbitrary](#file-limit) number of XML files. While it is still much slower than executing the XQuery within an XML database, it is much faster than using the `xquery` script. This is because instead of calling the Saxon XQuery processor once for each file, it inserts code into the XQuery to read many XML files at once, compiles them into a single XML file, then executes the XQuery once on that compiled file. This reduces the number of times the Saxon XQuery processor (and thus Java) is called from the command line.

The command options are the same as for `xquery`, except that the -s option specifying an input XML file, is not used. Instead, each command argument after the options is treated as the path to an input XML file.

Another difference is that the partial XQuery code to be inserted into the XQuery is held in the `xquery_files_prolog` file in this repository and inserted by default. This can be overridden using the -a option to use a different file; however that file must also contain the correct insertion code which collates the XML files into a single XML file. `xquery_files_prolog` is written to be used in a Windows system; users of other operating systems will need to use a different file.

`xquery_files` simulates some aspects of an XML database, by allowing an (arbitrary)[#file-limit] number of XML files to be processed, but it has the following important differences:

* It is *much* slower. An XML database normally creates many indexes across the XML data, which it uses to dramatically improve performance. It also executes a single XQuery once across all XML files in the database; whereas `xquery_files` must repeat the XQuery many times.
* It cannot execute queries that address more than one XML file at a time. Thus it cannot resolve references between XML files.

However, it is useful when an XML database cannot be used. 



<a id="file-limit"></a>
### Limit on number of XML files
As the list of XML files to be processes is passed to `xquery_files` as a list of command arguments, there is a limit imposed by the user's CLI. This limit is normally in terms of a maximum number of characters, so the limit on file numbers will depend on the length of the paths to the files.

The in-built `xargs` command can be used to manage this. `xargs` converts input from STDIN into arguments to a command. If the input list is sufficiently large, xargs automatically breaks it into chunks, each chunk having the maximum number of arguments that the CLI can process. xargs runs the given command for each chunk. In this way, there is theoretically no limit to the number of XML files which can be processed.

The author has used xargs to process more than a million XML files at a time in this way. In the author's system, if the paths to the XML files are less than 40 characters, xargs typically collates 150 XML files into one command. This means `xquery_files` is executed more than 6,000 times, and this typically takes between 16 hours and two days. For this reason, the author used `xquery_files` to create a text-based "index" file, containing the most frequently-queried values from the XML dataset. This list can be queried using line-based tools such as grep, awk and sed, to create smaller lists of files for further XQuery analysis. 

`xargs -d'\n' xquery_files -lodx -f ~/scripts/get-dataset-info.xq < dataset-files.txt > dataset-info.txt`

The default partial XQuery used to collate the given XML files in `xquery_files_prolog` creates the following variables which can be used in the custom XQuery:

| Variable | Contains |
| --- | --- |
| $currpath | The Windows path to the current folder |
| $filelist | The list of files being processed as a string using "£" as a separator |
| $files | The list of files being processed as a sequence |
| $file | The Unix path to the current file in the list |
| $winfile | The Windows path to the current file in the list |
| $doc | The document node of the current file |
| $root | The root element of the current file |




## xquery_lines

*EXPERIMENTAL*

`xquery_lines` is a variation on `xquery_files`. 


## schematron_to_xslt.sh

This script is a wrapper around `iso_svrl_for_xslt2.xsl` (a different Schematron XSLT compiler may be used), and converts the given Schematron file into an executable XSLT file. Note: the Schematron file needs to be self-contained, or an assembled Schematron file. To create XSLT from a set of Schematron files using the include mechanism, use `TO BE WRITTEN`. 

## run-schematron.sh

This script compiles the given Schematron file into XSLT, then runs the XSLT against the given XML file to create a Schematron Validation Report Language (SVRL) report. The Schematron can be supplied either standalone/assembled, or set of Schematron files using the include mechanism. A text summary of the SVRL report can optionally be created.

## run_schematron-multiple-xml-files.sh

This script compiles the given Schematron file into XSLT, then runs the XSLT against the given list of XML files, returning an SVRL report for each one. Optionally, a text file summary of SVRL errors for each file can be generated.


## diff_files_known_xslt.sh and diff_files_known_xslt_combined.sh

These two scripts assist in the comparison of two XML files, while ignoring accepted differences. The scripts first run the given XML files against the given XSLT file(s), which should be designed to remove or hide known and accepted differences. The resulting XML files are then compared using the Unix `diff` command



## Custom functions

Functions have been created in XSLT and XQuery. 

pmd_functions.xslt
pmd_functions.xq


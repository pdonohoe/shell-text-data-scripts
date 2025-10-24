
# Tab-Separated data scripts

These scripts create or transform tab-separated data files.

I process text data in files using tab-separated format, meaning the columns are separated by tabs, and no text in a single column contains a tab. I use TSV instead of other formats such as CSV, because:
* It is much easier to code for, it doesn't require complicated processing or rely on other scripts
* Most of my data comes from XML files. By default, whitespace characters (space, tab, newline) are treated identically by XML processors. In my work, tabs have no special meaning in the XML, so I convert them to spaces before saving XML data as text.

## Syntax and usage

Most scripts support "-?" as an option. If used, no processing is done and information on the syntax and usage is output to STDERR.

## Naming of scripts
Script names are always in lowercase, and words separated by underscores. 

No file extensions are used, because:
* To look similar to built-in unix commands
* A user should not care what language the scripts use
* It is quicker to write

## Scripts

| input from | meaning |
| --- | --- |
| STDIN | script reads lines from STDIN |
| FILE | script reads lines from FILE given as a parameter |
| STDIN, FILE | script reads lines either from STDIN, or from FILE given as a parameter |
| FILES | script reads lines from more than one file given as parameters |
| STDIN, STRINGS | script reads either lines from SDTIN, or strings given as parameters |





### Sorting and de-duplicating

| script name | description | input from | Languages used |
| --- | --- | --- | --- |
| `uniq_sort` | equivalent to ` \| sort \| uniq`, but uses awk to remove duplicates before sorting. Up to 3x faster than ` \| sort \| uniq` | STDIN | awk |
| `uniq_not_sorted` | outputs the first instance of each unique line. Retains original sort order | STDIN | awk |
| `uniq_duplicates` | outputs only the lines that are duplicated; if -u is given, prints only one instance of each unique line. The source lines do not need to be sorted | STDIN | unix, awk |
| `uniq_count` | outputs the first instance of each unique line. Prepends the count of that line to a new first column. Retains original sort order | STDIN | awk |
| `uniq_col` | outputs only the lines with the first instance of a unique value in a given column | STDIN | unix, awk |
| `uniq_col_count` | outputs only the lines with the first instance of a unique value in a given column. Prepends the count of the uniq lines to a new first column | STDIN | unix, awk |
| `uniq_duplicates_col` |  outputs only the lines where there is more than one line with a unique value in a given column. In other words, does not print lines with unique values in the given column | STDIN | unix, awk |
| `sort_uniq_count` | Same as `\| sort \| uniq \| uniq_count_to_start_col`; outputs unique lines, sorted numerically by count. Prepends the count of the uniq lines to a new first column. | STDIN | awk |
| `sort_uniq_count_by_line` | outputs unique lines, sorted alphabetically by the line. Prepends the count of the uniq lines to a new first column | STDIN | awk |



### Collating and splitting

| script name | description | input from | Languages used |
| --- | --- | --- | --- |
| `collate_column` | Collates lines where they are identical except for the specified column. Replaces this column with all unique values found for the collated lines | STDIN, FILE | perl |
| `collate_on_column` | Collates lines for unique values for the specified column. That column is moved to the first column. All lines with that column value are combined into one line | STDIN, FILE | perl |
| `add_percentage_column` | Adds a new column containing the value of a specified column compared to the sum of that column, as a percentage | STDIN, FILE | perl |
| `paren_list` | simple command to read a list of lines and convert them to a single parenthesised list. | STDIN | unix, sed |
| `to_list` | reads a list of lines and converts them to a list. Characters used for quotes, item separators and parentheses can be specified | STDIN | unix, sed |
| `sample_file` | reads STDIN or a file and outputs the given number of lines, evenly spaced | STDIN, FILE | unix, awk |

### File comparison

| script name | description | input from | Languages used |
| --- | --- | --- | --- |
| `perc_lines` | outputs the ratio of number of lines of two files as a percentage two two decimal places | FILES | unix |
| `lines_not_in` | outputs the lines found in file1 that are not present in file2 | FILES | perl |
| `lines_extra_in` | found in file2 that are not present in file1 | FILES | unix |

### File manipulation

| script name | description | input from | Languages used |
| --- | --- | --- | --- |
| `only_lines_with` | outputs the lines or strings that contain at least COUNT of the given SEARCH. Uses grep, can specify grep options | STDIN, STRINGS | unix, grep |
| `pair_lines` | outputs sequential pairs of lines collated | STDIN, FILE | unix |
| sample_file | outputs N lines evenly distributed | STDIN, FILE | unix, awk |
| tsv_to_csv | Converts a TSV file to CSV, outputs to STDOUT | FILES | unix |
| cols_align_tabs_to_spaces | Replaces tabs with spaces. Adds enough spaces to each line to keep previous tab column alignment | FILES | unix |



### File tests

| script name | description | input from | Languages used |
| --- | --- | --- | --- |
| `files_exist` | Outputs lines from STDIN depending on whether they exist as files | STDIN | unix |
| `folders_exist` | Outputs lines from STDIN depending on whether they exist as folders | STDIN | unix |




# Shell Text Data Scripts

This repository contains a collection of shell commands (and a few Perl commands) for text-based data. Many of them are intended to be used within command-line pipes, so they take input from STDIN or from a list of arguments. Some can also read lines from a file.

It also contains bash scripts for executing XSLT and XQuery scripts on XML files.

These scripts have only been tested on Git Bash running on a Windows machine. Use them at your own risk.


## Install

These scripts do not need any special installation process, they run directly from the bash command line. Most of these scripts are independent. You can copy them individually, or use `git clone` to get this repository onto your computer.

Either copy individual scripts into your user "bin" folder (often located at /usr/local/bin or /c/Users/YOUR_USERNAME/bin), or add the local folder where you cloned this repository to your PATH environment variable.

Some of the scripts require other software to run, in particular Perl, and for the XML Processing scripts, an XML Processor.


## Conventions / Requirements

### Global variables

Some scripts are reliant on global variables set in the bash environment. These variables are named using uppercase SNAKE_CASE. You can set them manually on the command line, or declare them in your bash environment startup scripts (e.g. .bashrc or .bash_profile).

### Local variables

Local variables are named using lowercase snake_case. In Perl scripts, these are mostly defined at the top of each script, making them global within the script. While this is counter to standard practice, it has been adopted to simplify the development of these scripts.

### Script options

The Unix function "getopts" and the Perl function "getopts" (Getopt::Std) have been chosen, as opposed to "getopt" for bash and "getopts" (Getopt::Long), for their similarity in operation, simplicity to code, and portability. This means the scripts are limited to using single-letter options. The issue of portability is very complex, and I prefer to avoid it if possible.

Most scripts accept the -? option, which will print out help on the script syntax, and not execute the script.


### POSIX compatibility versus bash-specific syntax

These scripts have been developed and tested using the bash shell. Some effort has been made to make these scripts *partly* compatible with other shell flavours by replacing bashisms with POSIX-compliant code (see [Bashism](https://mywiki.wooledge.org/Bashism), [DashAsBinSh](https://wiki.ubuntu.com/DashAsBinSh) and [checkbashism](https://github.com/rocker-org/drd/blob/master/checkbashisms)). However, I have not found easy replacements for arrays in bash, so these remain. If you intend to use these scripts in other shells, please check their compatibility before relying on them.

I have also used the mktemp command in some scripts. mktemp is not specified (yet) by POSIX, but it is widely available. See [how portable is mktemp](https://stackoverflow.com/questions/2792675/how-portable-is-mktemp1) for details. I have tried to use only the most portable options.


## Contributions

I welcome contributions to these scripts, via [Discussions](https://github.com/pdonohoe/draft-bash-text-data-scripts/discussions). Bugs can be reported via [Issues](https://github.com/pdonohoe/draft-bash-text-data-scripts/issues).


## Scripts by Category

### Tab-Separated Data

[Tab-separated data scripts](TSV-SCRIPTS.md)
These are scripts which create or transform tab-separated data files.


### XML Processing scripts
[XML processing scripts](XML-SCRIPTS.md)
These are scripts which process XML files, using XQuery or XSLT. They require an XML processing engine such as Saxon.

### Powerful multiple file text replace script
[replace_in_files](replace_in_files.md)

## License and warranty

These scripts are released under a CC0 licence; anyone can use them for any purpose without attribution. They are provided without warranty of any kind. Please see [LICENSE.md] for further details.

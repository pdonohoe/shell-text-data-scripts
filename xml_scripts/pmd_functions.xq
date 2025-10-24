xquery version "3.0"; 
(:
: Custom XQuery function module
 
: Copyright (C) 2024 Paul Donohoe

 : This module is distributed in the hope that it will be useful,
 : but WITHOUT ANY WARRANTY; without even the implied warranty of
 : MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 : Lesser General Public License for more details.

 : This module uses the FunctX XQuery Function Library
 : which should be installed in the same location as this module

 : This module contains some general XQuery functions

:)
module namespace pmd="http://www.pmdonohoe.com/functions";

import module namespace functx="http://www.functx.com" at "functx-1.0.1-doc.xq";

  
(: boolean functions :)

(: implements XOR :)
 declare function pmd:xor
   ($bool1, $bool2 ) as xs:boolean {
   let $result := xs:boolean($bool1 and not($bool2) or $bool2 and not($bool1))
   return $result
   };

(: implements XNOR :)
 declare function pmd:xnor
   ($bool1, $bool2 ) as xs:boolean {
   let $result := not(pmd:xor($bool1, $bool2 ))
   return $result
   };


 (: implements value-unique - values that occur in only one of the two sequences, in any order :)
 declare function pmd:value-unique
   ($arg1 as xs:anyAtomicType*, $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {
   let $dups := functx:non-distinct-values(($arg1, $arg2)) 
   let $result := for $val in fn:distinct-values(($arg1, $arg2)) return $val[not(.= $dups)]
   return $result
   };



(: string functions :)


(: removes . and - from text then normalizes space :)
declare function pmd:clean-text ( $mytext as xs:string? ) as xs:string {
normalize-space(fn:lower-case(replace(replace($mytext, "\.", ""), "-", "")))
 };

(: finds the substring before the last occurrence of any of a sequences of delimiters :)
declare function pmd:substring-before-last-delims
	($arg as xs:string, $delims as xs:string+) as xs:string {
	let $lastpos := fn:max(for $delim in $delims return fn:string-length(functx:substring-before-last($arg, $delim)))
	return if ($lastpos = 0) then '' else fn:substring($arg, 1, $lastpos)
};


(: returns the position of the first occurrence of a delimiter in a string, starting from a given position. If the delimiter is not found, returns 0 :)
declare function pmd:index-of-string-first 
	 ($arg as xs:string, $substring as xs:string, $pos as xs:integer) as xs:integer? {
	let $realpos := if ($pos > 0) then $pos else if ($pos = 0) then 1 else if ((fn:string-length($arg) + $pos + 1) > 0) then fn:string-length($arg) + $pos + 1 else 1
	let $index := functx:index-of-string-first(fn:substring($arg, $realpos), $substring)
	let $returnpos := if ($index instance of xs:integer) then $realpos + $index - 1 else $realpos - 1
	return $returnpos
};


(: finds the position of the first difference between two strings :)
(: copied from https://www.oxygenxml.com/archives/xsl-list/200909/msg00136.html :)
(: author: Dimitre Novatchev :)
(: changed namespace prefixes to "pmd" :)
(: returns the position of the last common character plus 1 :)

declare function pmd:pos-first-difference-between-strings
  ($pS1 as xs:string, $pS2 as xs:string) as xs:double {
     for $len in min((string-length($pS1), string-length($pS2))),
          $comleteMatchResult in $len +1,
          $leftResult in pmd:aux-first-difference-between-strings(substring($pS1, 1, $len),
            substring($pS2, 1, $len)  )
        return min(($leftResult, $comleteMatchResult))
};

declare function pmd:aux-first-difference-between-strings
  ($pS1 as xs:string, $pS2 as xs:string) as xs:double {
     for $len in string-length($pS1)
       return
          if($len eq 1)
             then 1 + number($pS1 eq $pS2)
             else
               for $halfLen in $len idiv 2,
                   $leftDiffPos in pmd:aux-first-difference-between-strings(substring($pS1,1,$halfLen),
                       substring($pS2,1,$halfLen))
                return
                  if($leftDiffPos le $halfLen)
                    then $leftDiffPos
                    else $leftDiffPos +
                       pmd:aux-first-difference-between-strings(substring($pS1,$halfLen+1),
                         substring($pS2,$halfLen + 1) )- 1
};



(: functions to take a string containing strings and number ranges, and return a sequence of them, as strings :)

(: 1-ary function, uses defaults of , as item separator and - as range separator :)
declare function pmd:get-sequence-from-number-pattern 
	 ($pattern as xs:string) as xs:string* {
	pmd:get-sequence-from-number-pattern($pattern, ',', '-')
};

(: 2-ary function, uses default of - as range separator, can specify item separator  :)
declare function pmd:get-sequence-from-number-pattern 
	 ($pattern as xs:string, $separator as xs:string) as xs:string* {
	pmd:get-sequence-from-number-pattern($pattern, $separator, '-')
};

(: 3-ary function, can specify item separator and range separator  :)
declare function pmd:get-sequence-from-number-pattern 
	 ($pattern as xs:string, $separator as xs:string, $range-separator as xs:string) as xs:string* {
	
	(: remove whitespace from pattern string :)
	let $clean-pattern := fn:replace($pattern, '[ \t\r\n]', '')
	(: split pattern string using separator :)
	let $pattern-items := fn:tokenize($clean-pattern, $separator)
	let $pattern-items-integers := 
		for $item in $pattern-items
			return if (fn:contains($item, '-')) then 
					xs:integer(fn:substring-before($item, '-')) to xs:integer(fn:substring-after($item, '-'))
				 else $item
	(: convert any integers to strings :)
	return for $p in $pattern-items-integers return xs:string($p)
};



(: XPath string functions :)


(: finds the first occurrence of a / in an xpath, where the substring before has matching counts of [ and ]. If the / is not found, returns 0 :)
declare function pmd:find-first-slash 
     ($xpath as xs:string, $pos as xs:integer?) as xs:integer {
		 if (not($pos instance of xs:integer)) then fn:string-length($xpath) + 1 else 
			let $nextpos := pmd:index-of-string-first($xpath, '/', $pos)
			return if ($nextpos = 0) then 0
			else
			let $string := fn:substring($xpath, 1, $nextpos)
				return if (fn:string-length(fn:replace($string, '\[', '')) = fn:string-length(fn:replace($string, '\]', ''))) then $nextpos else 
				  pmd:find-first-slash($xpath, pmd:index-of-string-first($xpath, '/', $nextpos + 1))
};


(: tests if string is a valid xpath string :)
(: primitive: xpath must not contain either [ or ] inside a string :)
declare function pmd:is-valid-xpath 
     ($xpath as xs:string) as xs:boolean {
    
		 if (fn:substring($xpath, fn:string-length($xpath)) = '/') then fn:false() else 
		 if (fn:string-length(fn:replace($xpath, '\[', '')) = fn:string-length(fn:replace($xpath, '\]', ''))) then fn:true() else 
		 fn:false()
	
};



(: removes any leading predicates from an xpath string. under development, do not use :)
declare function pmd:strip-leading-predicates-from-xpath 
     ($xpath as xs:string) as xs:string {
		 if (fn:substring($xpath, 1, 1) != '[') then $xpath else 
			fn:substring($xpath, pmd:find-first-slash($xpath , 1))
};


(: removes all predicates from an XPath :)
(: primitive: xpath must not contain either [ or ] inside a string :)
declare function pmd:remove-predicates-from-xpath 
       ($xpath as xs:string) as xs:string {
	if (not((fn:contains($xpath, '[')))) then $xpath else pmd:remove-predicates-from-xpath(fn:replace($xpath, '\[[^\]]+\]', ''))
};


(: trims a string to a valid xpath string :)
declare function pmd:trim-to-valid-xpath 
     ($xpath as xs:string) as xs:string {
    let $dummy := 
		<testing></testing>
    let $dummycount := $dummy/fn:count(./ggg)
    (: remove any trailing slash :)
    let $testxpath := fn:replace($xpath, '/+$','')
		return
			 if (pmd:is-valid-xpath($testxpath)) then 
				$testxpath
			 else
				let $smallerxpath := fn:substring($testxpath, 1, fn:string-length($testxpath) -1 + $dummycount)
				let $lenclose := fn:string-length(functx:substring-before-last($smallerxpath, ']'))
				let $lenopen := fn:string-length(functx:substring-before-last($smallerxpath, '['))
				let $lenslash := fn:string-length(functx:substring-before-last($smallerxpath, '/'))
				let $maxthese := fn:max(($lenclose +1, $lenopen, $lenslash))
				let $trimmed := fn:substring($testxpath, 1, $maxthese)
				return pmd:trim-to-valid-xpath($trimmed)
};


(: returns the relative xpath from one xpath to another :)
declare function pmd:get-relative-path
	($path_1 as xs:string, $path_2 as xs:string) as xs:string {
	let $c1 := fn:count(fn:tokenize($path_1, '/')) - 1
	let $c2 := fn:count(fn:tokenize($path_2, '/')) - 1
	let $set_path1 := for $i in 1 to $c1 
		let $replace := fn:concat('(/[^/]*){', $i, '}$')
		let $path := replace($path_1, $replace, "")
		return $path
	let $set_path2 := for $i in 1 to $c1
		let $replace := fn:concat('(/[^/]*){', $i, '}$')
		let $path := replace($path_2, $replace, '')
		return $path 
	let $common_path:= fn:concat(fn:distinct-values($set_path1[.=$set_path2])[1], "/")
	let $path_1_unique := fn:substring-after($path_1, $common_path)
	let $path_2_unique := fn:substring-after($path_2, $common_path)
	let $path_1_ancestor := fn:replace($path_1_unique, '[^/]+', '..')
	let $relative_path := fn:concat($path_1_ancestor, '/', $path_2_unique)
return fn:string-join(($path_1, $path_2, $relative_path), '&#10;')
};




(: returns the common XPath of two XPaths :)
(: this function assumes that both parameters are valid XPath strings :)
declare function pmd:common-xpath 
     ($xpath1 as xs:string, $xpath2 as xs:string) as xs:string {
    (: find the position of the first different character :)
	let $first-diff-pos := pmd:pos-first-difference-between-strings($xpath1, $xpath2)
		(: if the strings are identical, return one of them :)
		 return if (fn:string-length($xpath1) lt $first-diff-pos) then $xpath1 else 
			(: remove any trailing text that is not a full common element name :)
			let $xpath-to-trim := 
				(: if that character is a / or a [ IN BOTH STRINGS, then the preceding text is a COMMON full element name. Go back to the character before the last / or [ :)
				 if ((fn:substring($xpath1, $first-diff-pos, 1) = ('/','[') and fn:substring($xpath2, $first-diff-pos, 1) = ('/','[') )) then fn:substring($xpath1, 1, $first-diff-pos -1) else 
				(: if that character is NOT a / or a [ IN BOTH STRINGS, then the preceding text is NOT a COMMON full element name. Go back to the character before the last / or [ :)
				pmd:substring-before-last-delims(fn:substring($xpath1, 1, $first-diff-pos -1), ('/','['))
		return pmd:trim-to-valid-xpath($xpath-to-trim)
};

(: splits an XPath into a sequence of steps :)
declare function pmd:xpath-to-steps
	($xpath  as xs:string) as xs:string* {
	let $firstslash := pmd:find-first-slash($xpath, 1)
	return if (not($firstslash instance of xs:integer) or $firstslash = 0) then $xpath
	else
		(fn:substring($xpath, 1, $firstslash - 1), pmd:xpath-to-steps(fn:substring($xpath, $firstslash + 1)))
};




(: given two XPaths as strings, returns a string of the relative XPath between the two. Primitive: the XPaths must not contain either [ or ] inside a string :)
declare function pmd:get-relative-xpath
   ( $from-xpath as xs:string, $to-xpath as xs:string, $first-diff-ancestor-predicates-important as xs:boolean) as xs:string* {
   let $dummy := ""
	(: return . if xpaths identical :)
   return if ($from-xpath eq $to-xpath) then "." else
		(: split both xpaths into their steps, and count the number of identical steps from the first step :)
	   let $from-xpath-steps as xs:string* := pmd:xpath-to-steps($from-xpath)
	   let $to-xpath-steps as xs:string* := pmd:xpath-to-steps($to-xpath)
		let $mincount := fn:min((fn:count($from-xpath-steps), fn:count($to-xpath-steps)))
		let $countidenticalsteps := fn:min(for $step in 1 to $mincount return if ($from-xpath-steps[$step] ne $to-xpath-steps[$step]) then $step else $mincount + 1) - 1
		return 
		(: if all the steps of from-xpath are identical to the same steps in to-xpath, return the relative xpath of to-xpath :)
		if ($countidenticalsteps = count($from-xpath-steps)) then string-join($to-xpath-steps[fn:position() gt $countidenticalsteps], '/')
		(: if all the steps of to-xpath are identical to the same steps in from-xpath, return the relative xpath of from-xpath as parent steps eg ../.. :)
		else if ($countidenticalsteps = count($to-xpath-steps)) then string-join(for $n in 1 to count($from-xpath-steps) - $countidenticalsteps return '..', '/')
		(: both from-xpath and to-xpath differ at a step, and both have that step :)
		(: if for that first different step, the steps without predicates are different, then return a relative path of the different steps of from-xpath as .. followed by relative path of the different steps of to-xpath :)
		else if (fn:replace($from-xpath-steps[$countidenticalsteps + 1], '\[.*', '') ne fn:replace($to-xpath-steps[$countidenticalsteps + 1], '\[.*', '')) 
			then string-join((for $n in 1 to count($from-xpath-steps) - $countidenticalsteps return '..', $to-xpath-steps[fn:position() gt $countidenticalsteps]), '/')
		(: if for that first different step, the steps without predicates identical, then parameter first-diff-ancestor-predicates-important comes into play :)
		(: if first-diff-ancestor-predicates-important is TRUE, then treat this step as fully different :)
		else if ($first-diff-ancestor-predicates-important) 
			(: return a relative path of the different steps of from-xpath as .. followed by relative path of the different steps of to-xpath :)
			then string-join((for $n in 1 to count($from-xpath-steps) - $countidenticalsteps return '..', $to-xpath-steps[fn:position() gt $countidenticalsteps]), '/')
		else 
			(: for that first different step, both xpaths use the same element, with or without predicates :)
			(: get the steps of to-xpath following that first different step :)
			 let $to-xpathextra := fn:string-join(('', $to-xpath-steps[fn:position() gt $countidenticalsteps + 1]), '/')
			(: get the predicate of that first different step of to-xpath, if any :)
			 let $to-xpathfirstpred := fn:replace($to-xpath-steps[$countidenticalsteps + 1], '^[^\[]+', '')
			(: if from-xpath has no further steps, return . otherwise return the differing steps of xpath 1 as parent steps eg ../.. :)
			 let $from-xpathdown := if (count($from-xpath-steps) = $countidenticalsteps + 1) then '.' else string-join(for $n in 1 to count($from-xpath-steps) - $countidenticalsteps - 1 return '..', '/')
			(: combine the three parts above for the full relative xpath :)
			 return concat($from-xpathdown, $to-xpathfirstpred, $to-xpathextra)
};
		


(: returns the XML node kind or built-in type of an item :)
declare function pmd:item-kind
   ( $items as item()* ) as xs:string* {
 for $item in $items
 return
 if ($item instance of element()) then 'element'
 else if ($item instance of attribute()) then 'attribute'
 else if ($item instance of text()) then 'text'
 else if ($item instance of document-node()) then 'document-node'
 else if ($item instance of comment()) then 'comment'
 else if ($item instance of processing-instruction()) then 'processing-instruction'
 else if ($item instance of xs:untypedAtomic) then 'xs:untypedAtomic'
 else if ($item instance of xs:anyURI) then 'xs:anyURI'
 else if ($item instance of xs:string) then 'xs:string'
 else if ($item instance of xs:QName) then 'xs:QName'
 else if ($item instance of xs:boolean) then 'xs:boolean'
 else if ($item instance of xs:base64Binary) then 'xs:base64Binary'
 else if ($item instance of xs:hexBinary) then 'xs:hexBinary'
 else if ($item instance of xs:integer) then 'xs:integer'
 else if ($item instance of xs:decimal) then 'xs:decimal'
 else if ($item instance of xs:float) then 'xs:float'
 else if ($item instance of xs:double) then 'xs:double'
 else if ($item instance of xs:date) then 'xs:date'
 else if ($item instance of xs:time) then 'xs:time'
 else if ($item instance of xs:dateTime) then 'xs:dateTime'
 else if ($item instance of xs:dayTimeDuration) then 'xs:dayTimeDuration'
 else if ($item instance of xs:yearMonthDuration) then 'xs:yearMonthDuration'
 else if ($item instance of xs:duration) then 'xs:duration'
 else if ($item instance of xs:gMonth) then 'xs:gMonth'
 else if ($item instance of xs:gYear) then 'xs:gYear'
 else if ($item instance of xs:gYearMonth) then 'xs:gYearMonth'
 else if ($item instance of xs:gDay) then 'xs:gDay'
 else if ($item instance of xs:gMonthDay) then 'xs:gMonthDay'
 else 'unknown'
 } ;
 
 
(: Namespace functions :)
 
(: the following two functions read a file like the following: 
<namespaces>
<namespace><prefix>xsi</prefix><uri>http://www.w3.org/2001/XMLSchema-instance</uri></namespace>
<namespace><prefix>xs</prefix><uri>http://www.w3.org/2001/XMLSchema</uri></namespace>
...
</namespaces>
:)

(: Given a namespace URI as a string, return the prefix used as defined in the given XML document :)
declare function pmd:namespace-uri-to-prefix-from-file
	($uri as xs:string, $xmlfile as xs:string) as xs:string {
	let $namespaces := fn:doc($xmlfile)
	let $nselem := $namespaces//namespace[uri=$uri]/fn:string(prefix)
	return if ($nselem = '') then ''
    else $nselem
} ;

(: Given a namespace URI as a string, return the prefix used as defined in XML document 'list-of-namespaces.xml' :)
declare function pmd:namespace-uri-to-prefix-from-default-file
	($uri as xs:string) as xs:string {
    let $defaultfile := "list-of-namespaces.xml"
	return pmd:namespace-uri-to-prefix-from-file($uri, $defaultfile)
} ;

(: finds the prefix used for the given uri in the given XQuery file or prolog (from imported modules and namespace declarations) :)
declare function pmd:namespace-uri-to-prefix-from-xquery-file
   ( $uri as xs:string, $xqfile as xs:string ) as xs:string {
   let $file:=fn:replace($xqfile, "^/([A-Za-z])/","/$1:/")
   return if (not(fn:unparsed-text-available($file))) then "" else
   let $text:=fn:unparsed-text($file)
   let $matches:=fn:analyze-string($text, '(?:import\s+module|declare)\s+namespace\s+([^ =]+)\s*=\s*"([^"]+)"')
   let $match:=$matches//fn:match[fn:group[@nr="2"][. eq $uri]][1]
   return if ($match) then $match/fn:group[@nr="1"]/fn:string() else ""
} ;

(: finds the prefix used for the given uri in the XQuery prolog "xq_prolog" (from imported modules and namespace declarations) :)
declare function pmd:namespace-uri-to-prefix-from-xquery-file
   ( $uri as xs:string ) as xs:string {
   let $defaultfile:="xq_prolog"
   return pmd:namespace-uri-to-prefix-from-xquery-file($uri, $defaultfile)
} ;



(: File functions :)


(: the following two functions read a file / node like the following: 
<files>
<commonroot>C:/path/to/github/eForms-SDK-1.13.2/schemas/</commonroot>
<file>common/BDNDR-CCTS_CCT_SchemaModule-1.1.xsd</file>
<file>common/BDNDR-UnqualifiedDataTypes-1.1.xsd</file>
<file>common/EFORMS-ExtensionAggregateComponents-2.3.xsd</file>
<file>common/EFORMS-ExtensionApex-2.3.xsd</file>
...
</files>
:)

(: Read XML document specified, and return the list of files defined :)
declare function pmd:get-list-of-files
	($source_file  as xs:string) as node() {
	let $doc := doc($source_file)
	return pmd:get-list-of-files-from-node($doc)
};

(: From the given node, return the list of files defined :)
declare function pmd:get-list-of-files-from-node
	($list_element as node() ) as node() {
	let $common_root := $list_element//common_root/text()
	let $list_of_files :=
		<files>
			{ for $file in $list_element//file
				let $file_path := fn:string($file)
				let $root := string($file/@root)
				return element file { attribute root { $root }, fn:concat($common_root, $file_path) }
			}
		</files>
	return $list_of_files
};


(: node functions :)




(: returns the name of the given element, and its sequence number as a predicate if there are more than one instance within its parent :)
(: Adapted from functx:path-to-node-with-pos, FunctX XSLT Function Library :)
declare function pmd:name-with-pos 
   ($element as element()) as xs:string {
  let $sibsOfSameName := $element/../*[name() = name($element)]
  return concat(name($element),
         if (count($sibsOfSameName) le 1)
         then ''
         else concat('[',functx:index-of-node($sibsOfSameName, $element),']'))
};


(: returns the name of an element with its prefix as defined in the input document :)
declare function pmd:get-elem-name-with-prefix($node as node()) as xs:string {
    let $name := $node/fn:local-name()
    return
    typeswitch ($node)
    case element()
        return
			let $prefix := fn:prefix-from-QName(fn:node-name($node))
			return if (not($prefix )) then $name else fn:concat($prefix, ":", $name)
    case attribute()
        return fn:concat("@", $name)
    default
        return ""
};


(: returns the XPath to an element or attribute :)
declare function pmd:path-to-node-or-attribute( $nodes as node()* )  as xs:string* {
for $node in $nodes 
    return fn:concat(
        $node/string-join(ancestor-or-self::*/name(.), '/'),
        if ($node instance of attribute()) then fn:concat('/@', $node/name(.)) else '')
 } ;


(: returns the XPath to an element with prefixes as defined in the input document :)
declare function pmd:get-path-to-node-with-prefixes($node as node()) as xs:string {
    typeswitch ($node)

    case element()
        return
            fn:string-join(
			for $elem in $node/ancestor-or-self::node()[not(self::document-node())]
				return pmd:get-elem-name-with-prefix($elem)
			, "/")
    case attribute()
        return
            fn:string-join(
			for $elem in $node/ancestor-or-self::node()[not(self::document-node())]
				return pmd:get-elem-name-with-prefix($elem)
			, "/")
    case document-node()
        return
            $node/fn:local-name()
    default
        return ""
};

(: returns the XPath to an element with positional predicates and with prefixes as defined in the input document :)
declare function pmd:get-path-to-node-with-prefixes-and-pos($node as node()) as xs:string {
    typeswitch ($node)

    case element()
        return string-join(
            for $ancestor in $node/ancestor-or-self::*
                let $sibsOfSameName := $ancestor/../*[name() = name($ancestor)]
                return concat(name($ancestor),
                    if (count($sibsOfSameName) <= 1)
                    then ''
                    else concat(
                    '[',functx:index-of-node($sibsOfSameName,$ancestor),']'))
        , '/')
     case attribute()
        return string-join(
            for $ancestor in $node/ancestor-or-self::node()
                let $sibsOfSameName := $ancestor/../*[name() = name($ancestor)]
                return concat(
                    if ($ancestor/self::attribute()) then '@' else '',
                    name($ancestor),
                    if (count($sibsOfSameName) <= 1)
                    then ''
                    else concat(
                    '[',functx:index-of-node($sibsOfSameName,$ancestor),']'))
        , '/')
    case document-node()
        return
            $node/fn:local-name()
    default
        return ""

};

(: returns the XPath to an element with attributes and with prefixes as defined in the input document :)
declare function pmd:get-path-to-node-with-prefixes-and-attributes($node as node()) as xs:string {
	let $value := pmd:get-path-to-node-with-prefixes-and-attributes($node, ())
return $value
};

(: returns the XPath to an element with attributes and with prefixes as defined in the input document, ignoring the specified attributes :)
declare function pmd:get-path-to-node-with-prefixes-and-attributes($node as node(), $skipattnames as xs:string*) as xs:string {
    typeswitch ($node)

    case element()
        return string-join(
            for $ancestor in $node/ancestor-or-self::*
                return concat(
					'',
					name($ancestor), string-join(
				   for $att in $ancestor/@*
					   let $attname := string($att/name())
					   where not($attname = $skipattnames)
					   return concat('[@', $att/name(), '="', fn:string($att),'"]')
					   , ''))
        , '/')
     case attribute()
        return string-join(
            for $ancestor in $node/ancestor-or-self::node()
                return concat(
                    if ($ancestor/self::attribute()) then '@' else '',
                    name($ancestor),
				   for $att in $ancestor/@*
					   return concat('[@', $att/name(), '="', fn:string($att),'"]'))
        , '/')
    case document-node()
        return
            $node/fn:local-name()
    default
        return ""

};

(: lists the unique names of child elements of the given element. If an element is repeated, follow its name by "+". :)
(: separate the list by tabs. :)
declare function pmd:list-uniqplus-children($node as node()) as xs:string {
    typeswitch ($node)
		case text() return ""
        case comment() return ""
		case attribute() return ""
		case processing-instruction() return ""
		case namespace-node() return ""
        default return
			let $child-names := ( for $child in $node/* return pmd:get-elem-name-with-prefix($child) )
			let $count := fn:count($child-names)
			return fn:string-join((
			for $name at $index in $child-names
				let $prev := if ($index = 1) then () else fn:subsequence($child-names, 1, $index - 1)
				let $foll := if ($index = $count) then () else fn:subsequence($child-names, $index + 1, $count - $index)
				return if ($name = $prev) then () else
					if ($name = $foll) then fn:concat($name, "+")
					else $name
			), "&#09;")
};

(: returns a list of the sibling elements of a node :) 
declare function pmd:sibling-elements($node as node()) as element()* {
    let $sibelems:=
        for $sib in functx:siblings($node)
            where $sib instance of element()
            return $sib
    return if (fn:count($sibelems) > 0) then $sibelems else ()
};


(: returns the given node with the given prefixes removed from all elements :)
declare function pmd:remove-prefixes($node as node(), $prefixes as xs:string*) as node() {
    typeswitch ($node)
    case element()
        return
            if ($prefixes = ('#all', prefix-from-QName(node-name($node)))) then
                element {QName(namespace-uri($node), local-name($node))} {
                    $node/@*,
                    $node/node()/pmd:remove-prefixes(., $prefixes)
                }
            else
                element {node-name($node)} {
                    $node/@*,
                    $node/node()/pmd:remove-prefixes(., $prefixes)
                }
    case document-node()
        return
            document {
                $node/node()/pmd:remove-prefixes(., $prefixes)
            }
    default
        return $node
};

(: returns the given element, removing the content, keeping only the attributes :)
declare function pmd:empty-element($elements as element()*) as element()* {
   for $element in $elements
   return element
     {node-name($element)}
     {$element/@* }
 } ;


(: returns a space-separated list of attributes from the given element, each name:value, separated by spaces :)
declare function pmd:get-atts-values($element as element()) as xs:string {
    fn:string-join( 
        for $att in $element/@* 
        let $attname:=$att/name() 
        let $attvalue:=fn:string($att) 
        return fn:concat($attname, ":", $attvalue)
    , " ")
 } ;
 
(: returns the trimmed XPath, attribute names and values, and text node content, of an element :)
declare function pmd:get-leaf-data($element as element(), $trimxpath as xs:string) as xs:string {
let $xpath:=functx:path-to-node-with-pos($element)
let $atts:=pmd:get-atts-values($element)
let $text:=fn:normalize-space(fn:string-join($element/text(),""))
return fn:concat(fn:substring-after($xpath, $trimxpath), "!", $atts, "!", $text)
};


(: returns the leaf-data of all descendant elements, as a sequence of strings :)
(: the XPaths returned are relative to the given element :)
declare function pmd:get-elem-data($element as element()) as xs:string* {
let $elementxpath:=functx:path-to-node-with-pos($element)
for $elem in $element//*
(: where $elem[@*] or fn:normalize-space(fn:string-join($elem/text(),"")):)
return pmd:get-leaf-data($elem, $elementxpath)
};

(: returns the difference in descendant element data between the first given element, and all the other given elements :)
(: the second argument is a boolean determining whether the differences of the first element are included :)
declare function pmd:get-elem-sequence-diffs($elements as element()*, $skipfirst as xs:boolean) as xs:string* {
let $firstelem:=$elements[1]
let $restelems:=$elements[not(position() = 1)]
return
if (not($restelems)) then "" else
let $firstelemdata:=pmd:get-elem-data($firstelem)
for $elem in $restelems
let $elemdata:=pmd:get-elem-data($elem)
return if ($skipfirst) then (
	distinct-values($elemdata[not(.=$firstelemdata)]),
	distinct-values($firstelemdata[not(.=$elemdata)])
) else (distinct-values($elemdata[not(.=$firstelemdata)]))
};

(: returns the difference in descendant element data between the first given element, and all the other given elements :)
(: the differences of the first element are included :)
declare function pmd:get-elem-sequence-diffs($elems as element()*) as xs:string* {
let $mytrue:=fn:true()
return pmd:get-elem-sequence-diffs($elems, $mytrue) 
};


(: compares two nodes for deep-equality, except the top level element of each :)
declare function pmd:descendants-deep-equal( $node1 as node(), $node2 as node() )  as xs:boolean {
	let $out1:=<out>{for $node in $node1/node() return $node}</out>
	let $out2:=<out>{for $node in $node2/node() return $node}</out>
	return fn:deep-equal($out1, $out2)
 } ;


(: compares two nodes for deep-equality in structure, ignoring all text  :)
declare function pmd:structure-deep-equal ( $node1 as node(), $node2 as node() )  as xs:boolean {
	let $stripped1 := pmd:strip-values-from-elements-deep($node1)
	let $stripped2 := pmd:strip-values-from-elements-deep($node2)
return fn:deep-equal($stripped1, $stripped2)
 } ;
 
(: returns the distinct XML nodes in a sequence (by content and attributes)  :)
declare function pmd:distinct-equal-nodes ( $nodes as node()* )  as node()* {
	let $distinctnodes :=
	for $node at $pos in $nodes
	let $exists := (for $prevnode in $nodes[position() < $pos] where fn:deep-equal($node, $prevnode) return 1)
	where count($exists) = 0
	return $node
return $distinctnodes
 } ;

(: returns the given nodes with text content and attribute content removed from all elements :)
declare function pmd:strip-values-from-elements-deep ( $nodes as node()* )  as node()* {
   for $node in $nodes
   return if ($node instance of attribute())
          then attribute { node-name($node) } { "" }
		  else if ($node instance of element())
          then element { node-name($node) }
                 { pmd:strip-values-from-elements-deep($node/($node/(@*|node())) )}
          else if ($node instance of document-node())
          then pmd:strip-values-from-elements-deep($node/($node/(@*|node())))
		  else if ($node instance of text()) then text { "" }
          else $node
 } ;

(: returns the given nodes with the descendant whitespace nodes that exist between elements removed :)
declare function pmd:remove-whitespace-between-elements
  ( $nodes as node()* )  as node()* {
   for $node in $nodes
   return if ($node instance of element())
        then element {node-name($node)}  { $node/@*, pmd:remove-whitespace-between-elements($node/node()) }
		else if (not($node instance of text())) then $node
		else if (fn:normalize-space($node) = '') then () else $node
 } ;

(: returns the given nodes with the descendant comment nodes removed :)
(: removes comment nodes :)
declare function pmd:remove-comments
  ( $nodes as node()* )  as node()* {
   for $node in $nodes
   return if ($node instance of element())
        then element {node-name($node)}  { $node/@*, pmd:remove-comments($node/node()) }
		else if ($node instance of comment()) then () else $node
 } ;
 
(: returns the given nodes with the descendant text nodes removed :)
declare function pmd:remove-text-nodes
  ( $nodes as node()* )  as node()* {
   for $node in $nodes
   return if ($node instance of element())
        then element {node-name($node)}  { $node/@*, pmd:remove-text-nodes($node/node()) }
		else if ($node instance of text()) then () else $node
 } ;


(: returns the given elements, removing the child content (text and elements), but leaving the attributes :)
declare function pmd:remove-element-content ( $elements as element()* )  as element()* {
   for $element in $elements
   return element { node-name($element) }
                 { $element/@* }
 } ;

(:  returns the given nodes with the attributes removed from the elements :)
declare function pmd:remove-attributes-from-element
  ( $nodes as node()* )  as node()* {
   for $node in $nodes
   return if (not($node instance of element()))
        then $node
		else element {node-name($node)}  { $node/node() }
 } ;

(: returns the given nodes, removing the content of the descendant elements that have any of the given names :)
declare function pmd:remove-named-element-content-deep
  ( $nodes as node()* ,
    $elementnames as xs:string+ )  as node()* {
   for $node in $nodes
   return if (not($node instance of element()))
        then $node
		else if ($node/fn:local-name() = $elementnames) then
			element {node-name($node)}  { $node/@* }
			else
			element {node-name($node)}  { $node/@*, pmd:remove-named-element-content-deep($node/node(), $elementnames) }
 } ;

(: returns the given nodes, removing the descendant elements that have any of the given names :)
declare function pmd:remove-named-elements-deep
  ( $nodes as node()* ,
    $elementnames as xs:string+ )  as node()* {
   for $node in $nodes
   return if (not($node instance of element()))
        then $node
		else if ($node/fn:local-name() = $elementnames) then
			()
			else
			element {node-name($node)}  { $node/@*, pmd:remove-named-elements-deep($node/node(), $elementnames) }
 } ;

(: given an XML node created by fn:json-to-xml, get the XPath with @key attribute if present :)
declare function pmd:path-to-node-with-key
  ( $node as node()? ) as xs:string {

	string-join(
	  for $ancestor in $node/ancestor-or-self::*
	  let $key := fn:string($ancestor/@key)
	  return concat(name($ancestor),
	   if ($key = "")
	   then ''
	   else concat(
		  '[key="',$key,'"]'))
	 , '/')
 } ;

(: returns the given nodes, removing all nodes at specified depth, useful for XML created by fn:json-to-xml :)
declare function pmd:remove-elements-depth
  ( $nodes as node()* , $depth as xs:integer)  as node()* {
   for $node in $nodes
   return
     if ($node instance of element())
     then if (functx:depth-of-node($node) > $depth)
          then ()
          else element { node-name($node)}
                { $node/@*,
                  pmd:remove-elements-depth($node/node(), $depth)}
     else if ($node instance of document-node())
     then pmd:remove-elements-depth($node/node(), $depth)
     else $node
 } ;
 
 (: splits an XPATH string into steps. WARNING: Cannot cope with / inside quotes like fn:string-join(c, "/") :)
 declare function pmd:get-xpath-steps
   ($xpath as xs:string ) as xs:string* {
   let $ispure := fn:not(fn:contains($xpath, "["))
   return
     if ($ispure)
        then fn:tokenize($xpath, "/")
     else
		 pmd:get-next-step($xpath, 1)
   };

(: gets the next step in an XPath :)
declare function pmd:get-next-step
   ( $xpath as xs:string,
     $pos as xs:integer ) as xs:string* {
     (: get the strings before and after the first / after $pos :)
   let $nextstring := fn:substring-before(fn:substring($xpath, $pos), "/")
   let $remainder := fn:substring-after(fn:substring($xpath, $pos), "/")
   (: get the string from the start up to the first / after $pos :)
   let $trystep := if ($pos > 1) then fn:concat(fn:substring($xpath, 1, $pos - 1), $nextstring) else $nextstring
   (: check if this string has matching numbers of [ and ] :)
   let $isrealstep := if (fn:count(fn:tokenize($trystep, "\[")) = fn:count(fn:tokenize($trystep, "\]"))) then true() else false()
   return (
		if ($isrealstep)  
          then ( 
            $trystep,
            if (fn:contains($remainder, "/")) then pmd:get-next-step($remainder, 1) else $remainder
           )
          else 
           if ($remainder eq "") then $xpath 
           else (  pmd:get-next-step($xpath, $pos + fn:string-length($nextstring) + 1))
   )
};



(: returns the node that is the closest ancestor of two nodes :)
declare function pmd:closest-common-ancestor($node1 as node(), $node2 as node()) as node() {
	let $closest := ($node1/ancestor::node() intersect $node2/ancestor::node())[fn:last()]
	return $closest
};

(: returns the node that is the closest ancestor of two nodes - kaysian version :)
declare function pmd:closest-common-ancestor-kaysian($node1 as node(), $node2 as node()) as node() {
	let $closest := $node1/ancestor::*[count(. | $node2/ancestor::*) = count($node2/ancestor::*)][1]
	return $closest
};


(: formats a number as decimal, from https://stackoverflow.com/questions/5838562/how-can-i-format-a-decimal-in-xquery :)
declare function pmd:format-dec($i as xs:decimal) as xs:string
{
  let $input := tokenize(string(abs($i)),'\.')[1]
  let $dec := substring(tokenize(string($i),'\.')[2],1,2)
  let $rev := reverse(string-to-codepoints(string($input)))
  let $comma := string-to-codepoints(',')

  let $chars :=
    for $c at $i in $rev
    return (
      $c,
      if ($i mod 3 eq 0 and not($i eq count($rev)))
      then $comma else ()
    )
  return concat(if ($i lt 0) then '-' else (),
                codepoints-to-string(reverse($chars)),
                if ($dec != '') then concat('.',$dec) else ()
                )
};


(: The following functions were designed to analyse UBL XSD schemas. I am not certain they have universal applicability :)

(: returns the prefix for the targetNamespace defined in an .xsd file :)
declare function pmd:get-xsd-prefix-for-file($file as xs:string) as xs:string {
    let $doc:=fn:doc($file)
    let $nsname := $doc/*/fn:string(@targetNamespace)
    return pmd:namespace-uri-to-prefix-from-xquery-file($nsname ) 
};

(: given a root node of an XSD file, returns the list of complexType nodes which contain a reference to elements with the given name :)
declare function pmd:get-xsd-named-parents-of-element-with-name($root as node(), $elemname as xs:string) as element()* {
    let $elemnamenoprefix := if (fn:contains($elemname, ":")) then fn:replace($elemname, "^.*:", "") else $elemname
    for $refelem in $root//*[fn:local-name() = "element"][fn:matches(@ref, fn:concat(":", $elemnamenoprefix, "$")) or fn:matches(@type, fn:concat("^", $elemnamenoprefix, "$"))]
        return ($refelem/ancestor::*[@name])[1]
};

(: given a root node of an XSD file, returns the list of names of complexType nodes which contain a reference to elements with the given name :)
declare function pmd:get-xsd-names-of-parents-of-element-with-name($root as node(), $elemname as xs:string) as xs:string* {
    let $elemnamenoprefix := if (fn:contains($elemname, ":")) then fn:replace($elemname, "^.*:", "") else $elemname
    for $parent in pmd:get-xsd-named-parents-of-element-with-name($root, $elemnamenoprefix)
        return $parent/fn:string(@name)
};

(: given a list of XSD files, returns the list of names of complexType nodes which contain a reference to elements with the given name :)
declare function pmd:get-xsd-names-of-parents-of-element-with-name-from-files($files as xs:string*, $elemname as xs:string) as xs:string* {
    for $file in $files let $doc:=fn:doc($file) for $root in $doc/*
        for $parent in pmd:get-xsd-named-parents-of-element-with-name($root, $elemname)
            return $parent/fn:string(@name)
};

(: given a list of XSD files, returns the list of names with prefixes of complexType nodes which contain a reference to elements with the given name :)
declare function pmd:get-xsd-names-with-prefixes-of-parents-of-element-with-name-from-files($files as xs:string*, $elemname as xs:string) as xs:string* {
    for $file in $files let $doc:=fn:doc($file) for $root in $doc/*
        let $prefix := pmd:get-xsd-prefix-for-file($file)
        for $parent in pmd:get-xsd-named-parents-of-element-with-name($root, $elemname)
            let $parentname := $parent/fn:string(@name)
            return if ($prefix = "" ) then $parentname else fn:concat($prefix, ":", $parentname)
};

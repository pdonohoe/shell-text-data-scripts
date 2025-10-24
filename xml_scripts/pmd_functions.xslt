<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:functx="http://www.functx.com" xmlns:pmd="http://www.pmdonohoe.com/functions">

<xsl:import href="functx-1.0.1-doc.xsl"/>
<xsl:variable name="newline" select="'&#10;'"/>
<xsl:variable name="tab" select="'&#09;'"/>
<xsl:variable name="singlequote">'</xsl:variable>

<!-- boolean functions -->

<!-- implements XOR -->
<xsl:function name="pmd:xor" as="xs:boolean">
	<xsl:param name="bool1"/>
	<xsl:param name="bool2"/>
	<xsl:sequence select="xs:boolean($bool1 and not($bool2) or $bool2 and not($bool1))"/>
</xsl:function>

<!-- implements XNOR -->
<xsl:function name="pmd:xnor" as="xs:boolean">
	<xsl:param name="bool1"/>
	<xsl:param name="bool2"/>
	<xsl:sequence select="not(pmd:xor($bool1, $bool2))"/>
</xsl:function>


<!-- implements value-unique - values that occur in only one of the two sequences, in any order -->
<xsl:function name="pmd:value-unique" as="xs:anyAtomicType*">
	<xsl:param name="arg1" as="xs:anyAtomicType*"/>
	<xsl:param name="arg2" as="xs:anyAtomicType*"/>
    <xsl:variable name="dups" select="functx:non-distinct-values(($arg1, $arg2))"/>
	<xsl:sequence select="for $val in fn:distinct-values(($arg1, $arg2)) return $val[not(.= $dups)]"/>
</xsl:function>


<!-- string functions -->

<!-- returns only matches from a regex search using xsl:analyze-string -->
<xsl:function name="pmd:get-matches" as="xs:string*">
	<xsl:param name="arg" as="xs:string"/>
	<xsl:param name="regex" as="xs:string"/>
	<xsl:variable name="results" as="xs:string*">
		<xsl:analyze-string regex="{$regex}" select="$arg">
			<xsl:matching-substring>
				<xsl:value-of select="."/>
			</xsl:matching-substring>
		</xsl:analyze-string>
	</xsl:variable>
	<xsl:sequence select="$results"/>
</xsl:function>


<!-- finds the substring before the last occurrence of any of a sequences of delimiters -->
<xsl:function name="pmd:substring-before-last-delims">
	<xsl:param name="arg" as="xs:string"/>
	<xsl:param name="delims" as="xs:string+"/>
	<xsl:variable name="lastpos" select="fn:max(for $delim in $delims return fn:string-length(functx:substring-before-last($arg, $delim)))"/>
	<xsl:sequence select="if ($lastpos = 0) then '' else fn:substring($arg, 1, $lastpos)"/>
</xsl:function>

<!-- returns the position of the first occurrence of a delimiter in a string, starting from a given position. If the delimiter is not found, returns the empty sequence -->
<xsl:function name="pmd:index-of-string-first" as="xs:integer?">
	<xsl:param name="arg" as="xs:string"/>
	<xsl:param name="substring" as="xs:string"/>
	<xsl:param name="pos" as="xs:integer"/>
	<xsl:variable name="realpos" select="if ($pos>0) then $pos else if ($pos=0) then 1 else if ((fn:string-length($arg)+$pos+1)>0) then fn:string-length($arg)+$pos+1 else 1"/>
    <xsl:variable name="returnpos" select="$realpos + functx:index-of-string-first(fn:substring($arg, $realpos), $substring) - 1 "/>
	<xsl:sequence select="$returnpos"/>
</xsl:function>

<!-- finds the position of the first difference between two strings -->
<!-- copied from https://www.oxygenxml.com/archives/xsl-list/200909/msg00136.html -->
<!-- author: Dimitre Novatchev -->
<!-- changed namespace prefixes to "paul" -->
<!-- returns the position of the last common character plus 1 -->


<xsl:function name="pmd:pos-first-difference-between-strings" as="xs:double">
    <xsl:param name="pS1" as="xs:string"/>
    <xsl:param name="pS2" as="xs:string"/>

    <xsl:sequence select=
     "for $len in min((string-length($pS1), string-length($pS2))),
          $comleteMatchResult in $len +1,
          $leftResult in pmd:aux-first-difference-between-strings(substring($pS1, 1, $len),
            substring($pS2, 1, $len)  )
        return min(($leftResult, $comleteMatchResult))
     "/>
  </xsl:function>

<xsl:function name="pmd:aux-first-difference-between-strings" as="xs:double">
    <xsl:param name="pS1" as="xs:string"/>
    <xsl:param name="pS2" as="xs:string"/>

    <xsl:sequence select=
     "for $len in string-length($pS1)
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
     "/>
</xsl:function>

<!-- functions to take a string containing strings and number ranges, and return a sequence of them, as strings -->

<!-- 1-ary function, uses defaults of , as item separator and - as range separator -->
<xsl:function name="pmd:get-sequence-from-number-pattern" as="xs:string*">
	<xsl:param name="pattern" as="xs:string"/>
	<xsl:sequence select="pmd:get-sequence-from-number-pattern($pattern, ',', '-')"/>
</xsl:function>

<!-- 2-ary function, uses default of - as range separator, can specify item separator  -->
<xsl:function name="pmd:get-sequence-from-number-pattern" as="xs:string*">
	<xsl:param name="pattern" as="xs:string"/>
	<xsl:param name="separator" as="xs:string"/>
	<xsl:sequence select="pmd:get-sequence-from-number-pattern($pattern, $separator, '-')"/>
</xsl:function>

<!-- 3-ary function, can specify item separator and range separator  -->
<xsl:function name="pmd:get-sequence-from-number-pattern" as="xs:string*">
	<xsl:param name="pattern" as="xs:string"/>
	<xsl:param name="separator" as="xs:string"/>
	<xsl:param name="range-separator" as="xs:string"/>
	
	<!-- remove whitespace from pattern string -->
	<xsl:variable name="clean-pattern" select="fn:replace($pattern, '[ \t\r\n]', '')"/>
	<!-- split pattern string using separator -->
	<xsl:variable name="pattern-items" select="fn:tokenize($clean-pattern, $separator)" as="xs:string*"/>
	<xsl:variable name="pattern-items-integers" as="xs:anyAtomicType*">
		<xsl:for-each select="$pattern-items">
			<xsl:choose>
				<xsl:when test="fn:contains(., '-')">
					<xsl:sequence select="xs:integer(fn:substring-before(., '-')) to xs:integer(fn:substring-after(., '-'))"/>
				</xsl:when>
				<xsl:otherwise><xsl:sequence select="."/></xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:variable>
	<!-- convert any integers to strings -->
	<xsl:sequence select="for $p in $pattern-items-integers return xs:string($p)"/>
</xsl:function>


<!-- XPath string functions -->



<!-- finds the first occurrence of a / in an xpath, where the substring before has matching counts of [ and ] -->
<xsl:function name="pmd:find-first-slash" as="xs:integer">
    <xsl:param name="xpath" as="xs:string"/>
    <xsl:param name="pos" as="xs:integer?"/>
    <xsl:choose>
		<xsl:when test="not($pos instance of xs:integer)"><xsl:sequence select="fn:string-length($xpath)+1"/></xsl:when>
		<xsl:otherwise>
			<xsl:variable name="nextpos" select="pmd:index-of-string-first($xpath, '/', $pos)"/>
			<xsl:variable name="string" select="fn:substring($xpath, 1, $nextpos)"/>
			<xsl:choose>
				<xsl:when test="$nextpos = 0"><xsl:sequence select="0"/></xsl:when>
				<xsl:when test="fn:string-length(fn:replace($string, '\[', '')) = fn:string-length(fn:replace($string, '\]', ''))"><xsl:sequence select="$nextpos"/></xsl:when>
				<xsl:otherwise><xsl:sequence select="pmd:find-first-slash($xpath, pmd:index-of-string-first($xpath, '/', $nextpos + 1))"/></xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:function>


<!-- tests if string is a valid xpath string -->
<!-- primitive: xpath must not contain either [ or ] inside a string -->
<xsl:function name="pmd:is-valid-xpath" as="xs:boolean">
    <xsl:param name="xpath" as="xs:string"/>
    <xsl:choose>
		<xsl:when test="fn:substring($xpath, fn:string-length($xpath)) = '/'"><xsl:sequence select="fn:false()"/></xsl:when>
		<xsl:when test="fn:string-length(fn:replace($xpath, '\[', '')) = fn:string-length(fn:replace($xpath, '\]', ''))"><xsl:sequence select="fn:true()"/></xsl:when>
		<xsl:otherwise><xsl:sequence select="fn:false()"/></xsl:otherwise>
	</xsl:choose>
</xsl:function>


<!-- removes any leading predicates from an xpath string. under development, do not use -->
<xsl:function name="pmd:strip-leading-predicates-from-xpath" as="xs:string">
    <xsl:param name="xpath" as="xs:string"/>
	<xsl:choose>
		<xsl:when test="fn:substring($xpath, 1, 1) != '['"><xsl:sequence select="$xpath"/></xsl:when>
		<xsl:otherwise>
			<xsl:sequence select="fn:substring($xpath, pmd:find-first-slash($xpath , 1))"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:function>

<!-- removes all predicates from an XPath -->
<!-- primitive: xpath must not contain either [ or ] inside a string -->
<xsl:function name="pmd:remove-predicates-from-xpath" as="xs:string">
    <xsl:param name="xpath" as="xs:string"/>
	<xsl:choose>
		<xsl:when test="not(fn:contains($xpath, '['))"><xsl:sequence select="$xpath"/></xsl:when>
		<xsl:otherwise>
			<xsl:sequence select="pmd:remove-predicates-from-xpath(fn:replace($xpath, '\[[^\]]+\]', ''))"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:function>


<!-- trims a string to a valid xpath string -->
<xsl:function name="pmd:trim-to-valid-xpath" as="xs:string">
    <xsl:param name="xpath" as="xs:string"/>
    <xsl:variable name="dummy">
		<testing></testing>
    </xsl:variable>
    <xsl:variable name="dummycount" select="$dummy/fn:count(./ggg)"/>
    <!-- remove any trailing slash -->
    <xsl:variable name="testxpath" select="fn:replace($xpath, '/+$','')"/>
		<xsl:choose>
			<xsl:when test="pmd:is-valid-xpath($testxpath)">
				<xsl:sequence select="$testxpath"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="smallerxpath" select="fn:substring($testxpath, 1, fn:string-length($testxpath) -1 + $dummycount)"/>
				<xsl:variable name="lenclose" select="fn:string-length(functx:substring-before-last($smallerxpath, ']'))"/>
				<xsl:variable name="lenopen" select="fn:string-length(functx:substring-before-last($smallerxpath, '['))"/>
				<xsl:variable name="lenslash" select="fn:string-length(functx:substring-before-last($smallerxpath, '/'))"/>
				<xsl:variable name="maxthese" select="fn:max(($lenclose +1, $lenopen, $lenslash))"/>
				<xsl:variable name="trimmed" select="fn:substring($testxpath, 1, $maxthese)"/>
				<xsl:sequence select="pmd:trim-to-valid-xpath($trimmed)"/>
			</xsl:otherwise>
		</xsl:choose>
</xsl:function>


<!-- returns the relative xpath from one xpath to another -->
<xsl:function name="pmd:get-relative-path" as="xs:string">
	<xsl:param name="path_1" as="xs:string"/>
	<xsl:param name="path_2" as="xs:string"/>
	<xsl:variable name="c1" select="fn:count(fn:tokenize($path_1, '/')) - 1"/>
	<xsl:variable name="c2" select="fn:count(fn:tokenize($path_2, '/')) - 1"/>
	<xsl:variable name="set_path1">
		<xsl:for-each select="1 to $c1">
			<xsl:variable name="i" select="."/>
			<xsl:variable name="replace" select="fn:concat('(/[^/]*){', $i, '}$')"/>
			<xsl:variable name="path" select="replace($path_1, $replace, '')"/>
			<xsl:value-of select="$path"/>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="set_path2">
		<xsl:for-each select="1 to $c2">
			<xsl:variable name="i" select="."/>
			<xsl:variable name="replace" select="fn:concat('(/[^/]*){', $i, '}$')"/>
			<xsl:variable name="path" select="replace($path_2, $replace, '')"/>
			<xsl:value-of select="$path"/>
		</xsl:for-each>
	</xsl:variable>
	<xsl:variable name="common_path" select="fn:concat(fn:distinct-values($set_path1[.=$set_path2])[1], '/')"/>
	<xsl:variable name="path_1_unique" select="fn:substring-after($path_1, $common_path)"/>
	<xsl:variable name="path_2_unique" select="fn:substring-after($path_2, $common_path)"/>
	<xsl:variable name="path_1_ancestor" select="fn:replace($path_1_unique, '[^/]+', '..')"/>
	<xsl:variable name="relative_path" select="fn:concat($path_1_ancestor, '/', $path_2_unique)"/>
	<xsl:value-of select="fn:string-join(($path_1, $path_2, $relative_path), '&#10;')"/>
</xsl:function>


<!-- returns the common XPath of two XPaths -->
<!-- this function assumes that both parameters are valid XPath strings -->
<xsl:function name="pmd:common-xpath" as="xs:string">
    <xsl:param name="xpath1" as="xs:string"/>
    <xsl:param name="xpath2" as="xs:string"/>
    <!-- find the position of the first different character -->
	<xsl:variable name="first-diff-pos" select="pmd:pos-first-difference-between-strings($xpath1, $xpath2)"/>
		<!-- if the strings are identical, return one of them -->
		<xsl:choose>
			<xsl:when test="fn:string-length($xpath1) &lt; $first-diff-pos"><xsl:sequence select="$xpath1"/></xsl:when>
			<xsl:otherwise>
				<!-- remove any trailing text that is not a full common element name -->
				<xsl:variable name="xpath-to-trim" as="xs:string">
					<xsl:choose>
						<!-- if that character is a / or a [ IN BOTH STRINGS, then the preceding text is a COMMON full element name. Go back to the character before the last / or [ -->
						<xsl:when test="(fn:substring($xpath1, $first-diff-pos, 1) = ('/','[') and fn:substring($xpath2, $first-diff-pos, 1) = ('/','[') )"><xsl:value-of select="fn:substring($xpath1, 1, $first-diff-pos -1)"/></xsl:when>
						<!-- if that character is NOT a / or a [ IN BOTH STRINGS, then the preceding text is NOT a COMMON full element name. Go back to the character before the last / or [ -->
						<xsl:otherwise><xsl:value-of select="pmd:substring-before-last-delims(fn:substring($xpath1, 1, $first-diff-pos -1), ('/','['))"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:sequence select="pmd:trim-to-valid-xpath($xpath-to-trim)"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:function>


<!-- splits an XPath into a sequence of steps -->
<xsl:function name="pmd:xpath-to-steps" as="xs:string*">
    <xsl:param name="xpath" as="xs:string"/>
	<xsl:variable name="firstslash" select="pmd:find-first-slash($xpath, 1)"/>
	<xsl:choose>
		<xsl:when test="not($firstslash instance of xs:integer) or $firstslash = 0"><xsl:sequence select="$xpath"/></xsl:when>
		<xsl:otherwise>
			<xsl:sequence select="fn:substring($xpath, 1, $firstslash - 1)"/>
			<xsl:sequence select="pmd:xpath-to-steps(fn:substring($xpath, $firstslash + 1))"/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:function>



<!-- given two XPaths as strings, returns a string of the relative XPath between the two. Primitive: the XPaths must not contain either [ or ] inside a string -->
<xsl:function name="pmd:get-relative-xpath" as="xs:string*">
    <xsl:param name="from-xpath" as="xs:string"/>
    <xsl:param name="to-xpath" as="xs:string"/>
    <xsl:param name="first-diff-ancestor-predicates-important" as="xs:boolean"/>
	<xsl:choose>
		<!-- return . if xpaths identical -->
		<xsl:when test="$from-xpath eq $to-xpath"><xsl:value-of select="'.'"/></xsl:when>
		<xsl:otherwise>
		     <!-- split both xpaths into their steps, and count the number of identical steps from the first step -->
			<xsl:variable name="from-xpath-steps" as="xs:string*" select="pmd:xpath-to-steps($from-xpath)"/>
			<xsl:variable name="to-xpath-steps" as="xs:string*" select="pmd:xpath-to-steps($to-xpath)"/>
			<xsl:variable name="mincount" select="fn:min((fn:count($from-xpath-steps), fn:count($to-xpath-steps)))"/>
			<xsl:variable name="countidenticalsteps" select="fn:min(for $step in 1 to $mincount return if ($from-xpath-steps[$step] ne $to-xpath-steps[$step]) then $step else $mincount + 1) - 1"/>
			<!--<xsl:value-of select="string($countidenticalsteps)"/>-->
			<xsl:choose>
				<!-- if all the steps of from-xpath are identical to the same steps in to-xpath, return the relative xpath of to-xpath -->
				<xsl:when test="$countidenticalsteps = count($from-xpath-steps)"><xsl:value-of select="string-join($to-xpath-steps[fn:position() gt $countidenticalsteps], '/')"/></xsl:when>
				<!-- if all the steps of to-xpath are identical to the same steps in from-xpath, return the relative xpath of from-xpath as parent steps eg ../.. -->
				<xsl:when test="$countidenticalsteps = count($to-xpath-steps)"><xsl:value-of select="string-join(for $n in 1 to count($from-xpath-steps) - $countidenticalsteps return '..', '/')"/></xsl:when>
				<!-- both from-xpath and to-xpath differ at a step, and both have that step -->
				<xsl:otherwise>
					<xsl:choose>
					    <!-- if for that first different step, the steps without predicates are different, then return a relative path of the different steps of from-xpath as .. followed by relative path of the different steps of to-xpath -->
						<xsl:when test="fn:replace($from-xpath-steps[$countidenticalsteps + 1], '\[.*', '') ne fn:replace($to-xpath-steps[$countidenticalsteps + 1], '\[.*', '')">
							<xsl:value-of select="string-join((for $n in 1 to count($from-xpath-steps) - $countidenticalsteps return '..', $to-xpath-steps[fn:position() gt $countidenticalsteps]), '/')"/>
						</xsl:when>
					    <!-- if for that first different step, the steps without predicates identical, then parameter first-diff-ancestor-predicates-important comes into play -->
					    <!-- if first-diff-ancestor-predicates-important is TRUE, then treat this step as fully different -->
					    <xsl:when test="$first-diff-ancestor-predicates-important">
							<!-- return a relative path of the different steps of from-xpath as .. followed by relative path of the different steps of to-xpath -->
							<xsl:value-of select="string-join((for $n in 1 to count($from-xpath-steps) - $countidenticalsteps return '..', $to-xpath-steps[fn:position() gt $countidenticalsteps]), '/')"/>
					    </xsl:when>
						<xsl:otherwise>
							<!-- for that first different step, both xpaths use the same element, with or without predicates -->
							<!-- get the steps of to-xpath following that first different step -->
							<xsl:variable name="to-xpathextra" select="fn:string-join(('', $to-xpath-steps[fn:position() gt $countidenticalsteps + 1]), '/')"/>
							<!-- get the predicate of that first different step of to-xpath, if any -->
							<xsl:variable name="to-xpathfirstpred" select="fn:replace($to-xpath-steps[$countidenticalsteps + 1], '^[^\[]+', '')"/>
							<!-- if from-xpath has no further steps, return . otherwise return the differing steps of xpath 1 as parent steps eg ../.. -->
							<xsl:variable name="from-xpathdown" select="if (count($from-xpath-steps) = $countidenticalsteps + 1) then '.' else string-join(for $n in 1 to count($from-xpath-steps) - $countidenticalsteps - 1 return '..', '/')"/>
							<!-- combine the three parts above for the full relative xpath -->
							<xsl:value-of select="concat($from-xpathdown, $to-xpathfirstpred, $to-xpathextra)"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:function>


<!-- returns the XML node kind or built-in type of an item -->
<xsl:function name="pmd:item-kind" as="xs:string*"
              xmlns:functx="http://www.functx.com">
  <xsl:param name="items" as="item()*"/>

 <xsl:sequence select="
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
 "/>

</xsl:function>


<!-- the following two functions read a file / node like the following: 
<namespaces>
<namespace><prefix>xsi</prefix><uri>http://www.w3.org/2001/XMLSchema-instance</uri></namespace>
<namespace><prefix>xs</prefix><uri>http://www.w3.org/2001/XMLSchema</uri></namespace>
...
</namespaces>
-->

<!-- Given a namespace URI as a string, return the prefix used as defined in XML document 'list-of-namespaces.xml' -->
<xsl:function name="pmd:namespace-uri-to-prefix-from-file" as="xs:string">
	<xsl:param name="uri" as="xs:string"/>
	<xsl:param name="xmlfile" as="xs:string"/>
	<xsl:variable name="namespaces" select="fn:doc($xmlfile)"/>
	<xsl:variable name="nselem" select="$namespaces//namespace[uri=$uri]/fn:string(prefix)"/>
	<xsl:choose>
		<xsl:when test="$nselem=''"><xsl:value-of select="''"/></xsl:when>
		<xsl:otherwise><xsl:value-of select="$nselem"/></xsl:otherwise>
	</xsl:choose>
</xsl:function>

<!-- Given a namespace URI as a string, return the prefix used as defined in XML document 'list-of-namespaces.xml' -->
<xsl:function name="pmd:namespace-uri-to-prefix-default" as="xs:string">
	<xsl:param name="uri" as="xs:string"/>
	<xsl:variable name="defaultfile" select="'list-of-namespaces.xml'"/>
	<xsl:sequence select="pmd:namespace-uri-to-prefix-from-file($uri, $defaultfile)"/>
</xsl:function>


<!-- the following two functions read a file / node like the following: 
<files>
<commonroot>C:/path/to/github/eForms-SDK-1.13.2/schemas/</commonroot>
<file>common/BDNDR-CCTS_CCT_SchemaModule-1.1.xsd</file>
<file>common/BDNDR-UnqualifiedDataTypes-1.1.xsd</file>
<file>common/EFORMS-ExtensionAggregateComponents-2.3.xsd</file>
<file>common/EFORMS-ExtensionApex-2.3.xsd</file>
...
</files>
-->

<!-- Read XML document specified, and return the list of files defined -->
<xsl:function name="pmd:get-list-of-files" as="node()">
	<xsl:param name="source_file" as="xs:string"/>
	<xsl:variable name="doc" select="doc($source_file)"/>
	<xsl:sequence select="pmd:get-list-of-files-from-node($doc)"/>
</xsl:function>

<!-- From the given node, return the list of files defined -->
<xsl:function name="pmd:get-list-of-files-from-node" as="node()">
	<xsl:param name="list_element" as="node()"/>
	<xsl:variable name="common_root" select="$list_element//common_root/text()"/>
	<xsl:variable name="list_of_files">
		<files>
			<xsl:for-each select="$list_element//file">
				<xsl:variable name="file_path" select="./text()"/>
				<xsl:variable name="root" select="@root"/>
				<file>
					<xsl:attribute name="root" select="$root"/>
					<xsl:value-of select="$common_root"/><xsl:value-of select="$file_path"/>
					<xsl:message terminate="no"><xsl:value-of select="$common_root"/><xsl:value-of select="$file_path"/></xsl:message>
				</file>
			</xsl:for-each>
		</files>
	</xsl:variable>
	<xsl:sequence select="$list_of_files"/>
</xsl:function>


<!-- node functions -->

<!-- returns the name of the given element, and its sequence number as a predicate if there are more than one instance within its parent -->
<!-- Adapted from functx:path-to-node-with-pos, FunctX XSLT Function Library -->
<xsl:function name="pmd:name-with-pos" as="xs:string">
  <xsl:param name="element" as="element()"/>
  <xsl:variable name="sibsOfSameName" select="$element/../*[name() = name($element)]"/>
  <xsl:sequence select="concat(name($element),
         if (count($sibsOfSameName) &lt;= 1)
         then ''
         else concat('[',functx:index-of-node($sibsOfSameName,$element),']'))"/>
</xsl:function>





<!-- XPath functions -->





</xsl:stylesheet>

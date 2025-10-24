<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:functx="http://www.functx.com">

<!--
XSLT to create a set of .rif files for use with replace_in_files
 to make HTML files valid XML by replacing named character entity references 
 with numeric unicode character references.

Source data is table saved from https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
converted to XML by replacing &nbsp; with space and closing <link> and <br> elements

replace_in_files -d chars -o -s '(<link [^>]*[^/>])>' -r '${1}/>' wp-char-entities.xml
sed -r 's%&nbsp;% %g;s%<br>%<br/>%g' chars/wp-char-entities.xml > wp-char-entities.xml

A separate file is written for each source ISO subset; 
Except these "source ISO subset"s are collated into one called "new": ISOproposed, NEWRFC2070, New, [blank]

The wikipedia page table has an identical char list as the WhatWG list at https://html.spec.whatwg.org/multipage/named-characters.html

xquerylines -loidx -q ' let $json:=fn:unparsed-text($file) let $xml:=fn:json-to-xml($json) return <xqstring>{$xml}</xqstring>' whatwg-html-entities.json > whatwg-html-entities.xml

linesnotin <(xquery -lodx -s html_clean_entities_all.xml -q 'for $ent in $root//char let $entname:=$ent/string(name)  return <xqstring>{$entname}</xqstring>' ) <(xquery -lodx -s whatwg-html-entities.xml -q 'for $ent in $root//map[ends-with(@key, ";")] let $entname:=string($ent/@key) return <xqstring>{$entname}</xqstring>') | head

linesnotin  <(xquery -lodx -s whatwg-html-entities.xml -q 'for $ent in $root//map[ends-with(@key, ";")] let $entname:=string($ent/@key) return <xqstring>{$entname}</xqstring>')  <(xquery -lodx -s html_clean_entities_all.xml -q 'for $ent in $root//char let $entname:=$ent/string(name)  return <xqstring>{$entname}</xqstring>' ) | head


-->
<xsl:import href="functx-1.0.1-doc.xsl"/>

<xsl:output method="text" version="1.0" encoding="UTF-8" indent="yes"/>
<xsl:variable name="newline" select="'&#10;'"/>

<xsl:template match="/">

	<!-- read and process wikipedia table in source XML file into a variable XML node -->
	<xsl:variable name="collated_table">
		<chars>
			<xsl:apply-templates select="*/tr"/>
		</chars>
	</xsl:variable>
	
	<!-- output XML file containing full set -->
	<xsl:variable name="file_name" select="'html_clean_entities_all.xml'"/>
	<xsl:result-document href="{$file_name}" method="xml">
		<xsl:copy-of select="$collated_table"/>
	</xsl:result-document>

	<!-- get a list of the ISO subset source names excluding 'ISOproposed', 'NEWRFC2070', 'New', '' -->
	<xsl:variable name="source_names" as="xs:string*">
		<xsl:for-each select="fn:distinct-values($collated_table/chars/char/source_string)">
			<xsl:variable name="source_name" select="."/>
			<xsl:choose>
				<xsl:when test="$source_name = ('ISOproposed', 'NEWRFC2070', 'New', '')"></xsl:when>
				<xsl:otherwise>
					<xsl:sequence select="$source_name"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:variable>
	
	<!-- output rif files from the list of ISO subset source names -->
	<xsl:for-each select="$source_names">
		<xsl:variable name="source_name" select="."/>
		<!-- create an rif file with filename based on the ISO subset source name -->
		<xsl:variable name="file_name" select="concat('html_clean_entities_', $source_name, '.rif')"/>
		<xsl:result-document href="{$file_name}" method="text">
		<!-- output comments at the top of the rif file -->
			<xsl:text># replace_in_files file to replace named entities with numeric entity references in HTML files</xsl:text>
			<xsl:value-of select="$newline"/>
			<xsl:text># from ISO subset: </xsl:text>
			<xsl:value-of select="$source_name"/>
			
			<!-- output extra comments for the ISOnum rif file -->
			<xsl:if test="$source_name eq 'ISOnum'">
				<xsl:value-of select="$newline"/>
				<xsl:text># ISOnum values between 32 (x20) and 125 (x7D) use normal ANSII chars except 60 (x3C, &lt;), 62 (x3E, &gt;), 38 (x26, &amp;), 34 (x22, &quot;) and 39 (x27, &apos;) </xsl:text>
			</xsl:if>
			
			<xsl:value-of select="$newline"/>
			<xsl:value-of select="$newline"/>
			<!-- output an RIF line for each source character from the ISO subset -->
			<xsl:for-each select="$collated_table/chars/char[source_string eq $source_name]">
				<xsl:call-template name="output_rif_line">
					<xsl:with-param name="char" select="."/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:result-document>
	</xsl:for-each>
	
	<!-- output rif files from new sources ( ISO subset source names of 'ISOproposed', 'NEWRFC2070', 'New', '' ) -->
	<xsl:variable name="file_name" select="'html_clean_entities_new.rif'"/>
	<xsl:result-document href="{$file_name}" method="text">
		<!-- output comments at the top of the rif file -->
		<xsl:text># replace_in_files file to replace named entities with numeric entity references in HTML files</xsl:text>
		<xsl:value-of select="$newline"/>
		<xsl:text># from new chars not in an ISO subset </xsl:text>
		
		<xsl:value-of select="$newline"/>
		<xsl:value-of select="$newline"/>
			<!-- output an RIF line for each source character from the ISO subsets -->
		<xsl:for-each select="$collated_table/chars/char[not(source_string = $source_names)]">
			<xsl:call-template name="output_rif_line">
				<xsl:with-param name="char" select="."/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:result-document>
	
	<!-- output single rif file "including" all individual rif files -->
	<xsl:variable name="file_name" select="'html_clean_entities_all.rif'"/>
	<xsl:result-document href="{$file_name}" method="text">
		<!-- output comments at the top of the rif file -->
		<xsl:text># Define RIF_FILE files to clean HTML entities</xsl:text>
		<xsl:value-of select="$newline"/>
		<xsl:text># for all HTML entities</xsl:text>
		<xsl:value-of select="$newline"/>
		<xsl:value-of select="$newline"/>

		<!-- output an RIF "include" line for each ISO subset -->
		<xsl:for-each select="$source_names">
			<xsl:variable name="source_name" select="."/>
			<xsl:variable name="file_name" select="concat('html_clean_entities_', $source_name, '.rif')"/>
			<xsl:text>RIF_FILE: :</xsl:text>
			<xsl:value-of select="$file_name"/>
			<xsl:value-of select="$newline"/>
		</xsl:for-each>
		<!-- output an RIF "include" line for the "new" ISO subset -->
		<xsl:text>RIF_FILE: :html_clean_entities_new.rif</xsl:text>
		<xsl:value-of select="$newline"/>
	</xsl:result-document>
			
</xsl:template>




<!-- template to output an RIF line -->

<xsl:template name="output_rif_line">
	<xsl:param name="char"/>
	<!-- decide what the replace string should be, mostly the numeric character string values from the XML file -->
	<xsl:variable name="replace_string">
		<xsl:choose>
			<!-- Exception for ISOnum values between 32 (x20) and 125 (x7D), they use the equivalent ANSII character -->
			<!-- Exclude from the exeption &quot; (x22), &apos; (x27) and \ (x5C) -->
			<xsl:when test="$char/source_string eq 'ISOnum' and matches($char/numeric_char_string, '#x00[2-7][0-9A-F];') and not(fn:replace($char/numeric_char_string, '^.*#', '') = ('x0022;', 'x0027;', 'x005C;'))">
				<xsl:variable name="numeric" select="fn:replace(fn:replace($char/numeric_char_string, '^.*x00', ''), ';', '')"/>
				<!-- use normal ANSII chars for most chars betwen 32 (x20) and 125 (x7D) -->
				<!-- Special exceptions and treatments for 60 (x3C, &lt;), 62 (x3E, &gt;), 38 (x26, &amp;), 34 (x22, &quot;) and 39 (x27, &apos;) </xsl:text> -->
				<xsl:choose>
					<xsl:when test="$numeric eq '3C'"><xsl:value-of select="'&amp;lt;'"/></xsl:when>
					<xsl:when test="$numeric eq '3E'"><xsl:value-of select="'&amp;gt;'"/></xsl:when>
					<xsl:when test="$numeric eq '26'"><xsl:value-of select="'&amp;amp;'"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$char/char_text"/></xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<!-- for all chars other than those excepted, use the numeric character string values from the XML file -->
			<xsl:otherwise>
				<xsl:value-of select="$char/numeric_char_string"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<!-- output the RIF line -->
	<xsl:text> -s '</xsl:text>
	<xsl:value-of select="$char/name"/>
	<xsl:text>' -r '</xsl:text>
	<xsl:value-of select="$replace_string"/>
	<xsl:text>'</xsl:text>
	<xsl:value-of select="$newline"/>
</xsl:template>


<!-- template to process wikipedia table rows and output <char> elements to the XML file -->

<xsl:template match="tr">
<!-- <td><link rel="mw-deduplicated-inline-style" href="mw-data:TemplateStyles:r886049734"/><span class="monospaced"> &amp;tdot;<br/> &amp;TripleDot;</span></td> -->
<!-- <td><link rel="mw-deduplicated-inline-style" href="mw-data:TemplateStyles:r886049734"/><span class="monospaced"> &amp;uml;</span><sup id="cite_ref-semicolon_2-18" class="reference"><a href="#cite_note-semicolon-2"><span class="cite-bracket">[</span>b<span class="cite-bracket">]</span></a></sup><br/><link rel="mw-deduplicated-inline-style" href="mw-data:TemplateStyles:r886049734"/><span class="monospaced"> &amp;Dot;<br/> &amp;die;<br/> &amp;DoubleDot;</span></td> -->

	<!-- process the first td to get the list of named character entity references -->
	<xsl:variable name="names_list" as="xs:string*">
		<xsl:apply-templates select="td[1]" mode="name"/>
	</xsl:variable>
	<xsl:variable name="names" as="xs:string*" select="fn:tokenize(fn:replace(fn:string-join($names_list, ''), ' ' , ''), '%')"/>

	<!-- process the second td to get the character text (used only for the ANSII characters in ISOnum) -->
	<xsl:variable name="char_text_list">
		<xsl:apply-templates select="td[2]" mode="text"/>
	</xsl:variable>
	<xsl:variable name="char_text" as="xs:string" select="fn:replace(fn:string-join($char_text_list, ''), ' ' , '')"/>

	<!-- process the third td to get the Unicode codepoints and generate the numeric character entity references -->
	<xsl:variable name="codes_list" as="xs:string*">
		<xsl:apply-templates select="td[3]" mode="codes"/>
	</xsl:variable>
	<xsl:variable name="codes" as="xs:string*" select="fn:tokenize(fn:replace(fn:string-join($codes_list, ''), ' ' , ''), '%')"/>
<!-- two codes have a bad extra semicolon -->
<!-- only three rows have td[3] containing <br/>, in each case, the last item is the HTML one -->
	<xsl:variable name="code_string" select="replace($codes[last()], ';', '')"/>
<!-- sometimes a character is represented by more than one unicode character (combining) eg U+003D U+20E5 -->
<!-- for each one, remove the leading "U+" and any following "0" then prefix with "&#x" and suffix with ";" eg &#x3D;&#x20E5;-->
	<xsl:variable name="numeric_char_string" select="fn:string-join(for $t in (fn:tokenize($code_string, 'U\+'))[fn:position() gt 1] return concat('&amp;#x', replace($t, '^00*', ''), ';'), '')"/>

	<!-- process the sixth td to get the name of the ISO subset -->
	<xsl:variable name="sources_list" as="xs:string*">
		<xsl:apply-templates select="td[6]" mode="sources"/>
	</xsl:variable>
	<xsl:variable name="sources" as="xs:string*" select="fn:tokenize(fn:replace(fn:replace(fn:string-join($sources_list, ''), ' ' , ''), '^%', ''), '%')"/>
<!-- only four rows have td[6] containing more than one source, in each case, the last item is the best one -->
	<xsl:variable name="source_string" select="$sources[last()]"/>
	
	<!-- output to the XML file one <char> element for each named character entity reference -->
	<xsl:for-each select="$names">
		<xsl:variable name="name" select="."/>
		<char>
			<name><xsl:value-of select="$name"/></name>
			<char_text><xsl:value-of select="$char_text"/></char_text>
			<numeric_char_string><xsl:value-of select="$numeric_char_string"/></numeric_char_string>
			<source_string><xsl:value-of select="$source_string"/></source_string>
		</char>
	</xsl:for-each>
</xsl:template>


<!-- template to process the names within tr/td[1] -->

<xsl:template match="node( )" mode="name">
	<xsl:choose>
		<xsl:when test="self::sup or self::style or self::link"></xsl:when>
		<xsl:when test="self::td or self::span">
			<xsl:apply-templates select="node( )" mode="name"/>
		</xsl:when>
		<xsl:when test="self::br">
			<xsl:value-of select="'%'"/>
		</xsl:when>
		<xsl:when test=". instance of text()">
			<xsl:value-of select="fn:normalize-space(.)"/>
		</xsl:when>
		<xsl:otherwise>
			<bad>
				<xsl:text>bad: </xsl:text>
				<xsl:value-of select="fn:local-name(.)"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="functx:path-to-node-with-pos(.)"/>
				<xsl:value-of select="$newline"/>
			</bad>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- template to process the names within tr/td[2] -->

<xsl:template match="node( )" mode="text">
	<xsl:choose>
		<xsl:when test="self::td or self::span or self::small or self::a">
			<xsl:apply-templates select="node( )" mode="text"/>
		</xsl:when>
		<xsl:when test=". instance of text()">
			<xsl:value-of select="fn:normalize-space(.)"/>
		</xsl:when>
		<xsl:otherwise>
			<bad>
				<xsl:text>bad: </xsl:text>
				<xsl:value-of select="fn:local-name(.)"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="functx:path-to-node-with-pos(.)"/>
				<xsl:value-of select="$newline"/>
			</bad>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- template to process the unicode codepoints within tr/td[3] -->

<!-- td[3] always contains <a> (exclude ancestor::sup); every such <a> contains exactly "U+" -->
<xsl:template match="node( )" mode="codes">
	<xsl:choose>
		<xsl:when test="self::sup or self::style or self::link"></xsl:when>
		<xsl:when test="self::td or self::span or self::ul or self::a or self::div">
			<xsl:apply-templates select="node( )" mode="codes"/>
		</xsl:when>
		<xsl:when test="self::li">
			<xsl:if test="not(fn:starts-with(., 'previously'))">
				<xsl:apply-templates select="node( )" mode="codes"/>
			</xsl:if>
		</xsl:when>
		<xsl:when test="self::br">
			<xsl:value-of select="'%'"/>
		</xsl:when>
		<xsl:when test=". instance of text()">
			<xsl:value-of select="fn:normalize-space(.)"/>
		</xsl:when>
		<xsl:otherwise>
			<bad>
				<xsl:text>bad: </xsl:text>
				<xsl:value-of select="fn:local-name(.)"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="functx:path-to-node-with-pos(.)"/>
				<xsl:value-of select="$newline"/>
			</bad>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


<!-- template to process the ISO subset names within tr/td[6] -->

<xsl:template match="node( )" mode="sources">
	<xsl:choose>
		<xsl:when test="self::sup or self::link"></xsl:when>
		<xsl:when test="self::td or self::ul or self::div or self::i">
			<xsl:apply-templates select="node( )" mode="sources"/>
		</xsl:when>
		<xsl:when test="self::li">
			<xsl:value-of select="'%'"/>
			<xsl:apply-templates select="node( )" mode="sources"/>
		</xsl:when>
		<xsl:when test=". instance of text()">
			<xsl:value-of select="fn:normalize-space(.)"/>
		</xsl:when>
		<xsl:otherwise>
			<bad>
				<xsl:text>bad: </xsl:text>
				<xsl:value-of select="fn:local-name(.)"/>
				<xsl:text> </xsl:text>
				<xsl:value-of select="functx:path-to-node-with-pos(.)"/>
				<xsl:value-of select="$newline"/>
			</bad>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>


</xsl:stylesheet>

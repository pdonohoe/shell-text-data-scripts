<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!-- https://schemas.teda.th/teda/teda-affiliate/department-of-health-service-support/hospital-services-establishment/blob/51762794a88db54b7fdbb6af4ac764a93057d964/schema/fhir/svrl_to_html.xslt -->
<!-- Electronic Transactions Development Agency ETDA Thailand https://etda.or.th/en -->
<xsl:stylesheet xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:svrl="http://purl.oclc.org/dsdl/svrl" xmlns:fn="http://www.w3.org/2005/xpath-functions" version="2.0" exclude-result-prefixes="svrl">
  <xsl:output method="text" indent="no"/>
  <!-- parameter "level" can be used to restrict the severity levels that are extracted. -->
  <!-- OMITTED, EMPTY, "all" or "info" - include "error", "warning" and "info" -->
  <!-- "warning" - include "error" and "warning" -->
  <!-- "error" - include only "error" -->
  <xsl:param name="level"/>

	<xsl:variable name="flagstoinclude" as="xs:string*">
		<xsl:sequence select="'error'"/>
		<xsl:choose>
			<xsl:when test="$level eq 'error'">
				<xsl:sequence select="'error'"/>
			</xsl:when>
			<xsl:when test="$level eq 'warning'">
				<xsl:sequence select="('error', 'warning')"/>
			</xsl:when>
			<xsl:when test="not($level) or $level = ('all', 'info', '')">
				<xsl:sequence select="('error', 'warning', 'info')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message terminate="yes">svrl-to-text.xsl: ERROR: invalid value of parameter "level": <xsl:value-of select="$level"/></xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>



  <xsl:variable name="tab" select="'&#09;'"/>
  <xsl:variable name="nl" select="'&#10;'"/>

  <xsl:template match="svrl:schematron-output">
        <xsl:apply-templates select="svrl:failed-assert"/>
  </xsl:template>

  <xsl:template match="svrl:text">
      <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="svrl:failed-assert">

	<xsl:if test="lower-case(@flag) = $flagstoinclude or not(@flag)">
		<xsl:variable name="flag">
		  <xsl:choose>
			<xsl:when test="lower-case(@flag) = 'error' or not(@flag)">
			  <xsl:value-of select="'ERROR'"/>
			</xsl:when>
			<xsl:when test="lower-case(@flag) = 'warning'">
			  <xsl:value-of select="'WARNING'"/>
			</xsl:when>
			<xsl:when test="lower-case(@flag) = 'info'">
			  <xsl:value-of select="'INFO'"/>
			</xsl:when>
		  </xsl:choose>	
		</xsl:variable>
		<xsl:variable name="text" select="svrl:text"/>
		<xsl:variable name="location" select="@location"/>
		<xsl:value-of select="fn:concat($flag, $tab, $location, $tab, $text, $nl)"/>
	</xsl:if>
  </xsl:template>
</xsl:stylesheet>

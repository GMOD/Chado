<?xml version = "1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="text" />

    <xsl:template match="/chaos/feature/feature_dbxref">
      <xsl:value-of select="../feature_id"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="../uniquename"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="../name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="dbxrefstr"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:template>
	
    <xsl:template match="text()|@*">
    </xsl:template>

</xsl:stylesheet>

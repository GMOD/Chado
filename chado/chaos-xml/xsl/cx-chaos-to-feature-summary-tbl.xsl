<?xml version = "1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" method="text" />


    <xsl:template match="/chaos/feature">
      <xsl:value-of select="feature_id"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="uniquename"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="type"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="dbxrefstr"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="featureloc/srcfeature_id"/>
      <xsl:text>:</xsl:text>
      <xsl:value-of select="featureloc/nbeg"/>
      <xsl:text>-></xsl:text>
      <xsl:value-of select="featureloc/nend"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="featureloc/strand"/>
      <xsl:text>] </xsl:text>
      <xsl:value-of select="featureprop/type"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="featureprop/value"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:template>
	
    <xsl:template match="text()|@*">
    </xsl:template>

</xsl:stylesheet>

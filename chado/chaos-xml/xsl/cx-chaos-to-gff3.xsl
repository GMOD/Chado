<?xml version = "1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:param name="source" select="'chado'"/>
  <xsl:output indent="yes" method="text" />

  <xsl:strip-space elements="text()|@*"/>
  <xsl:key name="k-feature" match="//feature" use="feature_id"/>
  <xsl:key 
    name="k-feature_relationship" 
    match="//feature_relationship" 
    use="subject_id"/>
  
  <xsl:template match="/chaos">
    <xsl:text>##gff-version  3&#10;</xsl:text>
    <xsl:apply-templates match="feature"/>
  </xsl:template>

  <xsl:template match="featureprop">
    <xsl:value-of select="type"/>
    <xsl:text>=</xsl:text>
    <xsl:apply-templates mode="escape" select="value"/>
    <xsl:text>;</xsl:text>
  </xsl:template>

  <xsl:template match="featureprop" mode="score">
  </xsl:template>

  <xsl:template match="feature_relationship">
  </xsl:template>

  <xsl:template match="feature">
    <xsl:if test="featureloc">
      <xsl:value-of select="normalize-space(featureloc/srcfeature_id)"/>
      <xsl:text>&#9;</xsl:text>
      <xsl:value-of select="$source"/>
      <xsl:text>&#9;</xsl:text>
      <xsl:value-of select="type"/>
      <xsl:text>&#9;</xsl:text>
      <xsl:value-of select="featureloc/nbeg"/>
      <xsl:text>&#9;</xsl:text>
      <xsl:value-of select="featureloc/nend"/>

      <xsl:text>&#9;</xsl:text>
      <xsl:choose>
        <xsl:when test="featureloc/phase">
          <xsl:value-of select="featureloc/phase"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>.</xsl:text>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:text>&#9;</xsl:text>
      <xsl:choose>
        <xsl:when test="featureprop[type = 'score']">
          <xsl:value-of select="featureprop[type = 'score']/value"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>.</xsl:text>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:text>&#9;</xsl:text>
      <xsl:choose>
        <xsl:when test="featureloc/strand = 1">
          <xsl:text>+</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>-</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#9;</xsl:text>
      <xsl:text>ID=</xsl:text>
      <xsl:value-of select="uniquename"/>
      <xsl:text>;</xsl:text>
      <xsl:for-each select="key('k-feature_relationship',feature_id)">
        <xsl:text>Parent=</xsl:text>
        <xsl:value-of select="key('k-feature', object_id)/uniquename"/>
        <xsl:text>;</xsl:text>
      </xsl:for-each>
      <xsl:apply-templates select="featureprop"/>
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="text()|@*">
  </xsl:template>

  <xsl:template mode="escape" match="text()">
    <xsl:value-of select="translate(.,' ','+')"/>
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="utf-8"?>

<!-- AUTHOR: Chris Mungall  cjm at fruitfly dot org  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml"/>

  <xsl:key name="k-feature" match="//feature" use="feature_id"/>

  <xsl:template match="/chado">
    <chado>
      <xsl:for-each select="//feature">
        <feature>
          <xsl:copy-of select="*[not(name(.) = 'feature_relationship')]"/>
        </feature>
      </xsl:for-each>
      <xsl:for-each select="//feature_relationship">
        <feature_relationship>
          <subject_id>
            <xsl:apply-templates mode="make-link" select=".."/>
          </subject_id>
          <object_id>
            <xsl:apply-templates mode="make-link" select="object_id/feature"/>
          </object_id>
          <xsl:copy-of select="type_id"/>
        </feature_relationship>
      </xsl:for-each>
    </chado>
  </xsl:template>

  <xsl:template mode="make-link" match="feature">
    <feature>
      <xsl:copy-of select="uniquename"/>
      <xsl:copy-of select="organism_id"/>
      <xsl:copy-of select="type_id"/>
    </feature>
  </xsl:template>

  <!-- block -->
  <xsl:template match="feature_relationship">
  </xsl:template>
  <xsl:template match="feature">
  </xsl:template>

  <xsl:template match="*">
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="utf-8"?>

<!-- AUTHOR: Chris Mungall  cjm at fruitfly dot org  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml"/>
  <xsl:strip-space elements="*"/>

  <!-- match everything -->
  <xsl:template match="/ | @* | node()">
    <xsl:choose>
      <xsl:when test="(name(.)='rank' or name(.)='locgroup' or name(.)='is_fmin_partial' or name(.)='is_fmax_partial' or name(.)='is_internal' or name(.)='is_analysis') and (.=0 or .='')"/>
      <xsl:when test="(name(.)='is_current') and .=1"/>
      <xsl:otherwise>
        <!-- recursively apply this same template again -->
        <xsl:copy>
          <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

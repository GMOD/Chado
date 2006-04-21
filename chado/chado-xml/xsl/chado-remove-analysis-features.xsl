<?xml version="1.0" encoding="utf-8"?>

<!-- AUTHOR: Chris Mungall  cjm at fruitfly dot org  -->
<!-- remove features with is_analysis="true" -->
<!-- NOT TESTED -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml"/>
  <xsl:strip-space elements="*"/>

  <!-- match everything -->
  <xsl:template match="/ | @* | node()">
    <xsl:choose>
      <xsl:when test="is_analysis='true'">
        <!-- ignore this element -->
      </xsl:when>
      <xsl:otherwise>
        <!-- recursively apply this same template again -->
        <xsl:copy>
          <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

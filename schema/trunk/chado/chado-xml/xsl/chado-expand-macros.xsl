<?xml version="1.0" encoding="utf-8"?>

<!-- AUTHOR: Chris Mungall  cjm at fruitfly dot org  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml"/>

  <!-- index everything with an ID attribute -->
  <xsl:key name="k-macro" match="//*" use="@id"/>

  <!-- match everything -->
  <xsl:template match="/ | @* | node()">
    <xsl:choose>
      <!-- replace terminal xxx_id elements with expanded macro -->
      <xsl:when test="contains(name(.),'_id') and not(*)">
        <xsl:if test="not(key('k-macro',.))">
          <xsl:message>No such ID: <xsl:value-of select="."/></xsl:message>
        </xsl:if>
        <!-- fetch expansion term from ID index -->
        <xsl:copy>
          <xsl:variable name="macro" select="key('k-macro',.)"/>
          <!-- recursively process macros (removing id attr) -->
          <xsl:for-each select="$macro">
            <xsl:copy>
              <xsl:apply-templates select="$macro/*"/>
            </xsl:copy>
          </xsl:for-each>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="count(@id)">
        <!-- remove existing macros (a macro is anything with id attr) -->
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

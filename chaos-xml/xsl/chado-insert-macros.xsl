<?xml version="1.0" encoding="utf-8"?>

<!-- Creates macros for repeated cv, cvterm and organism elements -->

<!-- All macros must be fully expanded before using this -->

<!-- Macro IDs correspond to unique key constraints in chado db -->
<!-- UK constraints are combined using double-underscore: '__' -->

<!-- NOTES: This transform uses some fairly advanced XSL concepts -->
<!-- (this is necessary for determining uniqueness of cvterms) -->

<!-- If you are inexperienced with XSL you may wish to look at -->
<!-- some of the other XSL files in this directory -->

<!-- AUTHOR: Chris Mungall  cjm at fruitfly dot org  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml"/>

  <!-- INDEXES -->
  <!-- create an index of every element by its database unique key -->

  <!-- ORGANISM INDEX -->
  <xsl:key name="k-organism_id" match="//organism_id[*]" use="concat(organism/genus,'__',organism/species)"/>
  <!-- DB INDEX -->
  <xsl:key name="k-db_id" match="//db_id[*]" use="db/name"/>
  <!-- CV INDEX -->
  <xsl:key name="k-cv_id" match="//cv_id[*]" use="cv/name"/>
  <!-- CVTERM-BY-TYPE_ID INDEX -->
  <xsl:key name="k-type_id" match="//type_id[*]" use="concat(cvterm/cv_id/cv/name,'__',cvterm/name)"/>

  <!-- UNIQUE NODESETS -->
  <!-- create a unique instance of each macroifyable element -->
  
  <!-- DISTINCT ORGANISMs -->
  <xsl:variable 
    name="u-organism_id"
    select="//organism_id[generate-id(.)=generate-id(key('k-organism_id',concat(organism/genus,'__',organism/species))[1])]"/>

  <!-- DISTINCT CVTERMs (by type_id) -->
  <xsl:variable 
    name="u-type_id"
    select="//type_id[generate-id(.)=generate-id(key('k-type_id',concat(cvterm/cv_id/cv/name,'__',cvterm/name))[1])]"/>

  <!-- DISTINCT CVs -->
  <xsl:variable 
    name="u-cv_id"
    select="//cv_id[generate-id(.)=generate-id(key('k-cv_id',cv/name)[1])]"/>

  <!-- DISTINCT DBs -->
  <xsl:variable 
    name="u-db_id"
    select="//db_id[generate-id(.)=generate-id(key('k-db_id',db/name)[1])]"/>

  <!-- ** TEMPLATES ** -->

  <!-- INITIAL MATCH -->
  <xsl:template match="/chado">
    <xsl:if test="count(//*[@id])">
      <xsl:message terminate="yes">
        The input already includes macros; if you wish to convert
        a partially macro-ized file you must first expand them
        using chado-expand-macros.xsl
      </xsl:message>
    </xsl:if>
    <chado>
      <!-- insect organism macro -->
      <xsl:for-each select="$u-organism_id">
        <xsl:apply-templates mode="insert-macro" select="organism">
          <xsl:with-param name="macro-id" select="concat(organism/genus,'__',organism/species)"/>
        </xsl:apply-templates>
      </xsl:for-each>
      <!-- insect db macro -->
      <xsl:for-each select="$u-db_id">
        <xsl:apply-templates mode="insert-macro" select="db">
          <xsl:with-param name="macro-id" select="concat('db__',db/name)"/>
        </xsl:apply-templates>
      </xsl:for-each>
      <!-- insect cv macro -->
      <xsl:for-each select="$u-cv_id">
        <xsl:apply-templates mode="insert-macro" select="cv">
          <xsl:with-param name="macro-id" select="concat('cv__',cv/name)"/>
        </xsl:apply-templates>
      </xsl:for-each>
      <!-- insect cvterm macro -->
      <xsl:for-each select="$u-type_id">
        <xsl:apply-templates mode="insert-macro" select="cvterm">
          <xsl:with-param name="macro-id" select="concat(cvterm/cv_id/cv/name,'__',cvterm/name)"/>
        </xsl:apply-templates>
      </xsl:for-each>

      <!-- process everything else as normal -->
      <xsl:apply-templates mode="main" select="*"/>
    </chado>
  </xsl:template>

  <!-- INSERT MACRO DEFINITION -->
  <xsl:template mode="insert-macro" match="*">
    <xsl:param name="macro-id"/>
    <xsl:copy>
      <xsl:attribute name="id">
        <xsl:value-of select="$macro-id"/>
      </xsl:attribute>
      <xsl:apply-templates mode="main" select="*"/>
    </xsl:copy>
  </xsl:template>

  <!-- NORMAL PROCESSING (RECURSIVE) -->
  <xsl:template mode="main" match="/ | @* | node()">
    <xsl:choose>
      <xsl:when test="name(.)='organism_id'">
        <xsl:copy>
          <xsl:value-of select="concat(organism/genus,'__',organism/species)"/>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="name(.)='type_id'">
        <xsl:copy>
          <xsl:value-of select="concat(cvterm/cv_id/cv/name,'__',cvterm/name)"/>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="name(.)='cv_id'">
        <xsl:copy>
          <xsl:value-of select="concat('cv__',cv/name)"/>
        </xsl:copy>
      </xsl:when>
      <xsl:when test="name(.)='db_id'">
        <xsl:copy>
          <xsl:value-of select="concat('db__',db/name)"/>
        </xsl:copy>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates mode="main" select="@* | node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="utf-8"?>

<!-- AUTHOR: Chris Mungall  cjm at fruitfly dot org  -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">

  <xsl:output indent="yes" method="xml"/>

  <xsl:key name="k-feature" match="//feature" use="feature_id"/>

  <xsl:template match="/chado">
    <chaos>
      <xsl:for-each select="//feature">
        <!-- nest all features directly under chado element -->
        <feature>
          <feature_id>
            <xsl:apply-templates mode="make-link" select="."/>
          </feature_id>
          <xsl:apply-templates select="*"/>
        </feature>
      </xsl:for-each>
      <xsl:for-each select="//feature_relationship">
        <!-- nest all feature_relationships directly under chado element -->
        <feature_relationship>
          <subject_id>
            <xsl:apply-templates mode="make-link" select=".."/>
          </subject_id>
          <object_id>
            <xsl:apply-templates mode="make-link" select="subject_id/feature"/>
          </object_id>
          <xsl:apply-templates select="type_id"/>
          <xsl:apply-templates select="rank"/>
        </feature_relationship>
      </xsl:for-each>
    </chaos>
  </xsl:template>

  <!-- TODO: allow macro vs no-macro -->
  <xsl:template mode="make-link" match="feature">
    <xsl:value-of select="concat(organism_id/organism/genus,'_',organism_id/organism/species,':',type_id/cvterm/name,':',uniquename)"/>
  </xsl:template>

  <xsl:template mode="make-link" match="organism">
    <xsl:value-of select="concat(genus,'_',species)"/>
  </xsl:template>

  <!-- block; we have already placed these at top-level -->
  <xsl:template match="feature_relationship">
  </xsl:template>

  <!-- filter out -->
  <xsl:template match="feature_pub">
  </xsl:template>

  <!-- filter for now -->
  <xsl:template match="feature_cvterm">
  </xsl:template>

  <xsl:template match="feature">
  </xsl:template>

  <xsl:template match="/ | * | node()">
    <xsl:choose>
      <xsl:when test="name(.)='is_current'"/>
      <xsl:when test="name(.)='is_fmin_partial'"/>
      <xsl:when test="name(.)='is_fmax_partial'"/>
      <xsl:when test="name(.)='timeaccessioned'"/>
      <xsl:when test="name(.)='timelastmodified'"/>
      <xsl:when test="name(.)='pub_id'"/>
      <xsl:when test="name(.)='srcfeature_id'">
        <srcfeature_id>
          <xsl:apply-templates mode="make-link" select="."/>
        </srcfeature_id>
      </xsl:when>
      <xsl:when test="name(.)='cv_id'">
        <cv>
          <xsl:value-of select="cv/name"/>
        </cv>
      </xsl:when>
      <xsl:when test="name(.)='cvterm_id'">
        <cvterm>
          <xsl:apply-templates select="cvterm/*" />
        </cvterm>
      </xsl:when>
      <xsl:when test="name(.)='dbxref_id'">
        <dbxrefstr>
          <xsl:value-of select="concat(dbxref/db_id/db/name,':',dbxref/accession)"/>
        </dbxrefstr>
      </xsl:when>
      <xsl:when test="name(.)='type_id'">
        <type>
          <xsl:value-of select="cvterm/name"/>
        </type>
      </xsl:when>
      <xsl:when test="name(.)='organism_id'">
        <organismstr>
          <xsl:value-of select="concat(organism/genus,' ',organism/species)"/>
        </organismstr>
      </xsl:when>
      <xsl:when test="name(.)='fmin'">
      </xsl:when>
      <xsl:when test="name(.)='fmax'">
        <xsl:choose>
          <xsl:when test="strand = -1">
            <nbeg>
              <xsl:value-of select="../fmax"/>
            </nbeg>
            <nend>
              <xsl:value-of select="../fmin"/>
            </nend>
          </xsl:when>
          <xsl:otherwise>
            <nbeg>
              <xsl:value-of select="../fmin"/>
            </nbeg>
            <nend>
              <xsl:value-of select="../fmax"/>
            </nend>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <!-- recursively apply this same template again -->
        <xsl:copy>
          <xsl:apply-templates select="* | node()" />
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>

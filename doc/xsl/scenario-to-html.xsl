<?xml version = "1.0"?>
<xsl:stylesheet version="1.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output indent="yes" method="html"/>

  <xsl:template match="/scenarios">

    <html>
      <head>
        <title>
          <xsl:value-of select="title"/>
          <xsl:text> version:</xsl:text>
          <xsl:value-of select="@version"/>
        </title>
        <link rel="SHORTCUT ICON" href="favicon.ico"/>
        <link rel="stylesheet" href="css/chado.css" type="text/css"/>
      </head>
      <body>

        <h1>
          <xsl:value-of select="title"/>
          <xsl:text> version:</xsl:text>
          <xsl:value-of select="@versio"/>
        </h1>

        <div id="index">
          <h2>Index</h2>
          <table>
            <xsl:for-each select="scenario">
              <tr>
                <td>
                  <a href="#{@id}">
                    <xsl:value-of select="@id"/>
                  </a>
                </td>
                <td>
                  <xsl:value-of select="@status"/>
                </td>
                <td>
                  <xsl:value-of select="summary"/>
                </td>
              </tr>
            </xsl:for-each>
          </table>
        </div>

        <div id="abstract">
          <h2>Abstract</h2>
          <xsl:apply-templates select="abstract"/>
        </div>

        <div id="scenarios">
          <h2>Scenarios</h2>
          <xsl:apply-templates select="scenario"/>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="scenario">
    <a name="{@id}"></a>
    <div class="scenario">
      <div class="id"><xsl:value-of select="@id"/></div>
      <xsl:apply-templates select="summary"/>
      <xsl:apply-templates select="status"/>
      <xsl:apply-templates select="description"/>
      <xsl:apply-templates select="parts"/>
      <xsl:apply-templates select="support"/>
      <xsl:apply-templates select="example"/>
    </div>
  </xsl:template>

  <xsl:template match="summary">
    <div class="summary">
      <xsl:apply-templates select="*|text()"/>
    </div>
  </xsl:template>

  <xsl:template match="description">
    <div class="description">
      <xsl:apply-templates select="*|text()"/>
    </div>
  </xsl:template>

  <xsl:template match="example">
    <div class="example">
      <h4>Example</h4>
      <xsl:apply-templates select="caption"/>
      <img src="{@id}.{img/@type}"/>
      <span class="download">
        <xsl:text>Download: </xsl:text>
        <xsl:for-each select="src">
          <xsl:text> [</xsl:text>
          <a href="{../@id}.{@type}">
            <xsl:value-of select="@type"/>
          </a>
          <xsl:text>] </xsl:text>
        </xsl:for-each>
      </span>
    </div>
  </xsl:template>

  <xsl:template match="support">
    <div class="support">
      <div class="tool">Tool: <xsl:value-of select="@tool"/></div>
      <div class="status">Status: <xsl:value-of select="@status"/></div>
      <xsl:apply-templates select="*|text()"/>
    </div>
  </xsl:template>

  <xsl:template match="parts">
    <div class="parts">
      <h4>This scenario involves rows in the following tables:</h4>
      <table>
        <th><xsl:text>table</xsl:text></th>
        <th><xsl:text>type_id</xsl:text></th>
        <th><xsl:text>number</xsl:text></th>
        <th><xsl:text>comments</xsl:text></th>
        <xsl:apply-templates select="part"/>
      </table>
    </div>
  </xsl:template>

  <xsl:template match="part">
    <tr>
      <td>
        <xsl:attribute name="href">
          <xsl:text>http://gmod.sourceforge.net/schema/doc/default_schema.html#</xsl:text>
          <xsl:value-of select="@table"/>
        </xsl:attribute>
        <xsl:value-of select="@table"/>
      </td>
      <td>
        <xsl:apply-templates select="@type"/>
      </td>
      <td>
        <xsl:value-of select="@number"/>
        <xsl:if test="@subj">
          <xsl:value-of select="@subj"/> 
          <xsl:text>[</xsl:text><xsl:value-of select="@inverse_cardinality"/>
          <xsl:text>]----&gt;[</xsl:text>
          <xsl:value-of select="@cardinality"/>
          <xsl:text>]</xsl:text><xsl:value-of select="@obj"/>
      </xsl:if>
      </td>
      <td>
        <span class="comment">
          <xsl:apply-templates select="comment"/>
        </span>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="@type">
    <b><xsl:value-of select="."/></b>
  </xsl:template>

  <xsl:template match="lastmod">
    <div class="metadata">
      <p>
        <xsl:copy>
          <xsl:copy-of select="@*"/>
          <xsl:apply-templates/>
        </xsl:copy>
      </p>
    </div>
  </xsl:template>

  <xsl:template match="lookup">
    <a>
      <xsl:attribute name="href">
        <xsl:text>#</xsl:text>
        <xsl:value-of select="@scenario"/>
      </xsl:attribute>
      <xsl:value-of select="@scenario"/>
    </a>
  </xsl:template>

  <xsl:template match="variant_of">
    <div class="variant_of">
      <xsl:text>variant of: </xsl:text>
      <a>
        <xsl:attribute name="href">
          <xsl:text>#</xsl:text>
          <xsl:value-of select="@scenario"/>
        </xsl:attribute>
        <xsl:value-of select="@scenario"/>
      </a>
    </div>
  </xsl:template>

  <xsl:template match="kw">
    <div class="code">
      <xsl:copy-of select="."/>
    </div>
  </xsl:template>

  <xsl:template match="code">
    <div class="code">
      <xsl:if test="desc">
        <p class="desc">
          <xsl:copy-of select="desc"/>
        </p>
      </xsl:if>
      <xsl:apply-templates select="pre"/>
    </div>
  </xsl:template>

  <xsl:template match="so">
    <!-- TODO: link to term -->
    <span class="term">
      <a>
        <xsl:attribute name="href">
          <xsl:text>http://song.sourceforge.net/#</xsl:text>
          <xsl:value-of select="@name"/>
        </xsl:attribute>
        <xsl:value-of select="@name"/>
      </a>
      <xsl:value-of select="name"/>
    </span>
  </xsl:template>

  <xsl:template match="view">
    <!-- TODO: link to term -->
    <span class="table">
      <xsl:value-of select="name"/>
    </span>
  </xsl:template>

  <xsl:template match="table">
    <span class="table">
    <a>
      <xsl:attribute name="href">
        <xsl:text>http://gmod.sourceforge.net/schema/doc/default_schema.html#</xsl:text>
        <xsl:value-of select="@name"/>
      </xsl:attribute>
      <xsl:value-of select="@name"/>
    </a>
    </span>
  </xsl:template>

  <!-- passthrough html -->
  <xsl:template match="*">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>


</xsl:stylesheet>

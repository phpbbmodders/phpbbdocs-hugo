<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="text" encoding="UTF-8"/>
<xsl:strip-space elements="*"/>

<xsl:key name="id" match="*[@id]" use="@id"/>

<xsl:param name="path.prefix" select="''"/>

<xsl:template match="/">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="book">
	<xsl:text># </xsl:text>
	<xsl:apply-templates select="bookinfo/title/node()"/>
	<xsl:text>&#10;&#10;</xsl:text>
	<xsl:apply-templates select="chapter"/>
</xsl:template>

<xsl:template match="bookinfo|sectioninfo"/>

<xsl:template match="chapter">
	<xsl:call-template name="anchor"/>
	<xsl:text>## </xsl:text>
	<xsl:apply-templates select="title/node()"/>
	<xsl:text>&#10;&#10;</xsl:text>
	<xsl:apply-templates select="node()[not(self::title or self::chapterinfo)]"/>
</xsl:template>

<xsl:template match="section">
	<xsl:call-template name="anchor"/>
	<xsl:call-template name="hashes">
		<xsl:with-param name="count" select="count(ancestor::section) + 3"/>
	</xsl:call-template>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="title/node()"/>
	<xsl:text>&#10;&#10;</xsl:text>
	<xsl:apply-templates select="node()[not(self::title or self::sectioninfo)]"/>
</xsl:template>

<xsl:template name="hashes">
	<xsl:param name="count"/>
	<xsl:if test="$count &gt; 0">
		<xsl:text>#</xsl:text>
		<xsl:call-template name="hashes">
			<xsl:with-param name="count" select="$count - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<xsl:template name="anchor">
	<xsl:if test="@id">
		<xsl:text>&lt;a id="</xsl:text>
		<xsl:value-of select="@id"/>
		<xsl:text>">&lt;/a>&#10;</xsl:text>
	</xsl:if>
</xsl:template>

<xsl:template match="para">
	<xsl:apply-templates/>
	<xsl:text>&#10;&#10;</xsl:text>
</xsl:template>

<xsl:template match="emphasis">
	<xsl:text>*</xsl:text><xsl:apply-templates/><xsl:text>*</xsl:text>
</xsl:template>

<xsl:template match="code|command|filename|guilabel|guimenuitem">
	<xsl:text>`</xsl:text><xsl:apply-templates/><xsl:text>`</xsl:text>
</xsl:template>

<xsl:template match="acronym|abbrev|glossterm|uri">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="ulink">
	<xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>](</xsl:text>
	<xsl:value-of select="@url"/><xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="link">
	<xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>](</xsl:text>
	<xsl:call-template name="target-href"><xsl:with-param name="linkend" select="@linkend"/></xsl:call-template>
	<xsl:text>)</xsl:text>
</xsl:template>

<xsl:template match="xref">
	<xsl:variable name="target" select="key('id', @linkend)"/>
	<xsl:text>[</xsl:text>
	<xsl:choose>
		<xsl:when test="$target/title"><xsl:value-of select="normalize-space($target/title)"/></xsl:when>
		<xsl:otherwise><xsl:value-of select="@linkend"/></xsl:otherwise>
	</xsl:choose>
	<xsl:text>](</xsl:text>
	<xsl:call-template name="target-href"><xsl:with-param name="linkend" select="@linkend"/></xsl:call-template>
	<xsl:text>)</xsl:text>
</xsl:template>

<xsl:template name="target-href">
	<xsl:param name="linkend"/>
	<xsl:text>#</xsl:text><xsl:value-of select="$linkend"/>
</xsl:template>

<xsl:template match="itemizedlist|orderedlist">
	<xsl:apply-templates select="listitem"/>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="listitem">
	<xsl:call-template name="indent">
		<xsl:with-param name="count" select="count(ancestor::listitem)"/>
	</xsl:call-template>
	<xsl:choose>
		<xsl:when test="parent::orderedlist"><xsl:text>1. </xsl:text></xsl:when>
		<xsl:otherwise><xsl:text>- </xsl:text></xsl:otherwise>
	</xsl:choose>
	<xsl:apply-templates select="para[1]/node()"/>
	<xsl:text>&#10;</xsl:text>
	<xsl:apply-templates select="node()[not(self::para[1])]"/>
</xsl:template>

<xsl:template name="indent">
	<xsl:param name="count"/>
	<xsl:if test="$count &gt; 0">
		<xsl:text>    </xsl:text>
		<xsl:call-template name="indent">
			<xsl:with-param name="count" select="$count - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<xsl:template match="variablelist">
	<xsl:apply-templates select="varlistentry"/>
</xsl:template>

<xsl:template match="varlistentry">
	<xsl:text>- **</xsl:text><xsl:apply-templates select="term/node()"/><xsl:text>:** </xsl:text>
	<xsl:apply-templates select="listitem/para[1]/node()"/><xsl:text>&#10;</xsl:text>
	<xsl:apply-templates select="listitem/node()[not(self::para[1])]"/>
</xsl:template>

<xsl:template match="note|tip|important|warning">
	<xsl:text>&gt; **</xsl:text>
	<xsl:choose>
		<xsl:when test="self::note">Note</xsl:when>
		<xsl:when test="self::tip">Tip</xsl:when>
		<xsl:when test="self::important">Important</xsl:when>
		<xsl:otherwise>Warning</xsl:otherwise>
	</xsl:choose>
	<xsl:text>:**&#10;</xsl:text>
	<xsl:for-each select="para">
		<xsl:text>&gt; </xsl:text><xsl:apply-templates select="node()"/><xsl:text>&#10;</xsl:text>
	</xsl:for-each>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="blockquote">
	<xsl:text>&#10;&gt; </xsl:text><xsl:apply-templates/><xsl:text>&#10;&#10;</xsl:text>
</xsl:template>

<xsl:template match="figure">
	<xsl:call-template name="anchor"/>
	<xsl:if test="title">
		<xsl:text>**</xsl:text><xsl:apply-templates select="title/node()"/><xsl:text>**&#10;&#10;</xsl:text>
	</xsl:if>
	<xsl:apply-templates select="mediaobject"/>
</xsl:template>

<xsl:template match="mediaobject">
	<xsl:text>![</xsl:text><xsl:value-of select="normalize-space(caption)"/><xsl:text>](</xsl:text>
	<xsl:call-template name="image-path"><xsl:with-param name="path" select="imageobject/imagedata/@fileref"/></xsl:call-template>
	<xsl:text>)&#10;&#10;</xsl:text>
	<xsl:if test="caption"><xsl:text>*</xsl:text><xsl:value-of select="normalize-space(caption)"/><xsl:text>*&#10;&#10;</xsl:text></xsl:if>
</xsl:template>

<xsl:template match="inlinemediaobject">
	<xsl:text>![image](</xsl:text>
	<xsl:call-template name="image-path"><xsl:with-param name="path" select="imageobject/imagedata/@fileref"/></xsl:call-template>
	<xsl:text>)</xsl:text>
</xsl:template>

<xsl:template name="image-path">
	<xsl:param name="path"/>
	<xsl:choose>
		<xsl:when test="starts-with($path, '../images/')">
			<xsl:value-of select="$path.prefix"/><xsl:text>images/</xsl:text><xsl:value-of select="substring-after($path, '../images/')"/>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$path"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="title|term|caption|imageobject|imagedata|authorgroup|author|othername|orgname"/>

</xsl:stylesheet>

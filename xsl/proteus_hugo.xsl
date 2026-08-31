<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:exsl="http://exslt.org/common"
	extension-element-prefixes="exsl"
	version="1.0">

<xsl:import href="proteus_markdown_chunked.xsl"/>

<xsl:output method="text" encoding="UTF-8"/>

<xsl:template match="book" mode="chunks">
	<xsl:text>---&#10;title: </xsl:text><xsl:value-of select="normalize-space(bookinfo/title)"/>
	<xsl:text>&#10;translationKey: home&#10;---&#10;&#10;</xsl:text>
	<xsl:text># </xsl:text><xsl:apply-templates select="bookinfo/title/node()"/><xsl:text>&#10;&#10;</xsl:text>
	<xsl:text>## Contents&#10;&#10;</xsl:text>
	<xsl:for-each select="chapter">
		<xsl:variable name="chapter.dir"><xsl:call-template name="chapter-dir"/></xsl:variable>
		<xsl:text>- [</xsl:text><xsl:value-of select="normalize-space(title)"/><xsl:text>](</xsl:text>
		<xsl:value-of select="$chapter.dir"/><xsl:text>/)&#10;</xsl:text>
		<xsl:call-template name="write-chapter">
			<xsl:with-param name="chapter.dir" select="$chapter.dir"/>
		</xsl:call-template>
	</xsl:for-each>
</xsl:template>

<xsl:template name="write-chapter">
	<xsl:param name="chapter.dir"/>
	<exsl:document href="{$output.base}/{$chapter.dir}/_index.md" method="text" encoding="UTF-8">
		<xsl:text>---&#10;title: </xsl:text><xsl:value-of select="normalize-space(title)"/>
		<xsl:text>&#10;translationKey: </xsl:text><xsl:value-of select="@id"/>
		<xsl:text>&#10;weight: </xsl:text><xsl:value-of select="position()"/>
		<xsl:text>&#10;---&#10;&#10;</xsl:text>
		<xsl:call-template name="anchor"/>
		<xsl:text># </xsl:text><xsl:apply-templates select="title/node()"/><xsl:text>&#10;&#10;</xsl:text>
		<xsl:apply-templates select="node()[not(self::title or self::chapterinfo or self::section)]"/>
		<xsl:text>## Contents&#10;&#10;</xsl:text>
		<xsl:for-each select="section">
			<xsl:text>- [</xsl:text><xsl:value-of select="normalize-space(title)"/><xsl:text>](</xsl:text>
			<xsl:value-of select="@id"/><xsl:text>/)&#10;</xsl:text>
		</xsl:for-each>
	</exsl:document>
	<xsl:for-each select="section">
		<exsl:document href="{$output.base}/{$chapter.dir}/{@id}/index.md" method="text" encoding="UTF-8">
			<xsl:text>---&#10;title: </xsl:text><xsl:value-of select="normalize-space(title)"/>
			<xsl:text>&#10;translationKey: </xsl:text><xsl:value-of select="@id"/>
			<xsl:text>&#10;weight: </xsl:text><xsl:value-of select="position()"/>
			<xsl:text>&#10;---&#10;&#10;</xsl:text>
			<xsl:apply-templates select="." mode="section-chunk"/>
		</exsl:document>
	</xsl:for-each>
</xsl:template>

<xsl:template name="target-href">
	<xsl:param name="linkend"/>
	<xsl:variable name="target" select="key('id', $linkend)"/>
	<xsl:variable name="target.chapter" select="$target/ancestor-or-self::chapter[1]"/>
	<xsl:variable name="target.section" select="$target/ancestor-or-self::section[parent::chapter][1]"/>
	<xsl:variable name="chapter.dir">
		<xsl:for-each select="$target.chapter"><xsl:call-template name="chapter-dir"/></xsl:for-each>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="$target.section">
			<xsl:value-of select="$path.prefix"/><xsl:value-of select="$chapter.dir"/><xsl:text>/</xsl:text>
			<xsl:value-of select="$target.section/@id"/><xsl:text>/#</xsl:text><xsl:value-of select="$linkend"/>
		</xsl:when>
		<xsl:when test="$target.chapter">
			<xsl:value-of select="$path.prefix"/><xsl:value-of select="$chapter.dir"/><xsl:text>/#</xsl:text><xsl:value-of select="$linkend"/>
		</xsl:when>
		<xsl:otherwise><xsl:text>#</xsl:text><xsl:value-of select="$linkend"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

</xsl:stylesheet>

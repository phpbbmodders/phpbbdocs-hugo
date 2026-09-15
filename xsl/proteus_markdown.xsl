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

<!-- Collapses whitespace runs in a text node: a run with no newline in
     it collapses to a single space; a run that DOES contain a newline
     collapses to a single bare newline instead of swallowing it into
     a space. xsl:strip-space only drops whitespace-only text nodes
     between elements, not whitespace inside one that has real content
     — so a <para> whose source is itself line-wrapped (common once
     translated content round-trips through a PO-based pipeline rather
     than staying hand-authored as dense single-line XML) would
     otherwise carry that line-wrapping's leading spaces/tabs straight
     into the generated Markdown. Markdown treats a 4-space indent as
     an indented code block, so the *symptom* is prose (and any links
     inside it) rendering as an unstyled, unlinked black code box
     instead of a normal paragraph.

     Preserving the newline itself (rather than flattening it to a
     space the way proteus_hugo_devdocs.xsl does — see that file's
     header comment for the original writeup this was ported from)
     matters here specifically: unlike Pandoc's devdocs output, this
     grammar lets a <para> directly contain a nested block-level child
     (<itemizedlist>, <note>, etc. — see e.g. the "General Options"
     paragraph in admin_guide.xml, whose intro sentence is followed by
     a nested <itemizedlist> on the next source line). A bare '\n' with
     no leading spaces after it is enough to fix the original bug
     (Markdown's code-block trigger is about a line STARTING with 4+
     spaces, not about a lone line break in the middle of a paragraph)
     while keeping that block child starting on its own line instead
     of getting run into the preceding sentence as if it read
     "...on your board. - Allow Mass PMs:...". -->
<xsl:template match="text()">
	<xsl:variable name="tabs-cr-as-spaces" select="translate(., '&#9;&#13;', '  ')"/>
	<xsl:variable name="newline-runs-collapsed">
		<xsl:call-template name="collapse-newline-adjacent-space">
			<xsl:with-param name="text" select="$tabs-cr-as-spaces"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:call-template name="collapse-whitespace">
		<xsl:with-param name="text" select="$newline-runs-collapsed"/>
	</xsl:call-template>
</xsl:template>

<!-- Eats any space adjacent to a newline (either side) and collapses
     consecutive newlines, so a run like "\n      " or "  \n\n  "
     reduces to a single bare "\n" before the space-only collapse
     below ever sees it. -->
<xsl:template name="collapse-newline-adjacent-space">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, ' &#10;')">
			<xsl:call-template name="collapse-newline-adjacent-space">
				<xsl:with-param name="text" select="concat(substring-before($text, ' &#10;'), '&#10;', substring-after($text, ' &#10;'))"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="contains($text, '&#10; ')">
			<xsl:call-template name="collapse-newline-adjacent-space">
				<xsl:with-param name="text" select="concat(substring-before($text, '&#10; '), '&#10;', substring-after($text, '&#10; '))"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="contains($text, '&#10;&#10;')">
			<xsl:call-template name="collapse-newline-adjacent-space">
				<xsl:with-param name="text" select="concat(substring-before($text, '&#10;&#10;'), '&#10;', substring-after($text, '&#10;&#10;'))"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Collapses runs of plain spaces (no newlines left in them by this
     point) down to a single space. -->
<xsl:template name="collapse-whitespace">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, '  ')">
			<xsl:call-template name="collapse-whitespace">
				<xsl:with-param name="text" select="concat(substring-before($text, '  '), ' ', substring-after($text, '  '))"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
	</xsl:choose>
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

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!--
	Renders exactly one dev-docs <article> (pandoc's DocBook output for
	one .rst source file, produced by convert_dev_docs_to_docbook.sh)
	into a single Hugo Markdown page.

	This is deliberately NOT built the way proteus_hugo.xsl is: that one
	processes a whole <book> in one pass, using exsl:document to fan a
	single input file out into many output files, because the
	hand-authored end-user docs are one XIncluded book. The dev-docs
	source is the opposite shape — 55 independent, already-separate
	<article> files nested in subdirectories — so here the *shell driver
	script* (phpbbdocs_hugo_devdocs.sh) does the multi-file/directory
	iteration, and this stylesheet just renders one article's body to
	stdout per invocation. Much simpler than replicating chunking logic
	for a structure that's already chunked by the filesystem.

	Reuses proteus_markdown.xsl's generic element templates (para,
	emphasis, links, lists, notes, images, etc. — none of that is
	book/chapter-specific) via import, and adds six things
	proteus_markdown.xsl doesn't have, because the hand-authored
	end-user docs never needed them but the dev-docs content (converted
	from Sphinx .rst) does:
	  - section headings (sect1-sect5 — see below for why)
	  - tables (informaltable/table — from Sphinx csv-table directives)
	  - code blocks (programlisting — from Sphinx code-block directives)
	  - explicit line breaks (br — from multi-line csv-table cells;
	    see convert_dev_docs_to_docbook.sh's header comment for why
	    these needed fixing up to self-closed <br/> in the first place)
	  - inline monospace text (literal — DocBook 4's tag for it; the
	    hand-authored docs use code/command/filename/guilabel instead,
	    covered by an inherited template, but never literal)
	  - text-node whitespace normalization (see the "text()" template
	    below for why this one's a real functional fix, not cosmetic)

	The text() override is the one worth understanding before touching
	this file: pandoc's DocBook writer pretty-prints its output, so a
	<para>'s text content is itself indented and line-wrapped, e.g.
	"\n      Some sentence that\n      wraps here.\n    " rather than a
	single unbroken line the way the hand-authored docs' source is
	written. Neither proteus_markdown.xsl (imported) nor DocBook's XML
	whitespace rules strip that — xsl:strip-space only drops
	whitespace-only text nodes between elements, not whitespace inside
	one that has real content — so without this override, every
	multi-line paragraph and list item comes out in the generated
	Markdown with each wrapped line indented 4+ spaces. Markdown treats
	a 4-space indent as an indented code block, so the *symptom* was
	prose (and any links inside it, since a code block's contents are
	never parsed as Markdown) rendering as an unstyled, unlinked black
	code box instead of a normal paragraph — confirmed against real
	rendered output before writing this fix, not a theoretical concern.

	convert_dev_docs_to_docbook.sh targets DocBook 4, not 5 — see that
	script's header comment for the full reasoning (short version: it
	avoids an XML-namespace mismatch against these namespace-unaware
	templates that otherwise silently renders every page empty). One
	consequence: DocBook 4 uses <articleinfo>, not <info>, and numbered
	<sect1>/<sect2>/<sect3>/... instead of DocBook 5's uniform, freely
	nestable <section> — so this file matches those DocBook 4 element
	names specifically, not the DocBook 5 names the format's newer
	syntax uses elsewhere.
-->

<xsl:import href="proteus_markdown.xsl"/>

<xsl:output method="text" encoding="UTF-8"/>

<xsl:param name="page.weight" select="'1'"/>
<xsl:param name="page.translationKey" select="''"/>

<!-- YAML double-quoted-scalar escaping for a front-matter value: only
     backslash and double-quote need it. Needed because unlike the
     hand-authored end-user docs' chapter/section titles, several
     dev-docs page titles contain a literal colon ("Tutorial: Modules"),
     which breaks Hugo's YAML front-matter parser if the title is
     emitted bare — a colon reads as introducing a nested mapping value.
     Quoting the whole string sidesteps that; escaping is only needed
     for characters that would end the quote early or need one
     themselves.

     XSLT 1.0 has no built-in string-replace, hence the recursion —
     but naively rebuilding the string with concat() and recursing on
     THAT would rescan the escape sequence just inserted (a literal
     backslash contains a backslash), infinitely re-escaping it. Each
     template below instead emits the already-scanned "before" portion
     and the replacement directly as output, and recurses only on the
     unscanned "after" remainder, so already-emitted text is never
     looked at again. Backslashes are escaped in a first full pass
     (backslash-escape), whose complete output is then fed through a
     second full pass for quotes (quote-escape) — safe to chain like
     this because escaping quotes can't introduce a backslash that
     would need the first pass re-run. -->
<xsl:template name="quote-escape">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, '&quot;')">
			<xsl:value-of select="substring-before($text, '&quot;')"/>
			<xsl:text>\&quot;</xsl:text>
			<xsl:call-template name="quote-escape">
				<xsl:with-param name="text" select="substring-after($text, '&quot;')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="backslash-escape">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, '\')">
			<xsl:value-of select="substring-before($text, '\')"/>
			<xsl:text>\\</xsl:text>
			<xsl:call-template name="backslash-escape">
				<xsl:with-param name="text" select="substring-after($text, '\')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="yaml-quote">
	<xsl:param name="text"/>
	<xsl:variable name="backslashes-done">
		<xsl:call-template name="backslash-escape">
			<xsl:with-param name="text" select="$text"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:call-template name="quote-escape">
		<xsl:with-param name="text" select="$backslashes-done"/>
	</xsl:call-template>
</xsl:template>

<xsl:template match="/">
	<xsl:text>---&#10;title: "</xsl:text>
	<xsl:call-template name="yaml-quote">
		<xsl:with-param name="text" select="normalize-space(article/articleinfo/title)"/>
	</xsl:call-template>
	<xsl:text>"&#10;weight: </xsl:text><xsl:value-of select="$page.weight"/>
	<xsl:if test="$page.translationKey != ''">
		<xsl:text>&#10;translationKey: </xsl:text><xsl:value-of select="$page.translationKey"/>
	</xsl:if>
	<xsl:text>&#10;---&#10;&#10;</xsl:text>
	<!-- articleinfo holds only the title (already used above for front
	     matter) and possibly author metadata neither Hugo nor the reader
	     needs here — everything else in the article is real body content. -->
	<xsl:apply-templates select="article/node()[not(self::articleinfo)]"/>
</xsl:template>

<!-- Collapses every run of whitespace (spaces, tabs, newlines) in a
     text node down to a single space — see the header comment for why
     this is a functional fix, not a cosmetic one. Deliberately does
     NOT trim leading/trailing whitespace down to nothing (only
     collapses runs to one space), which is enough to drop below
     Markdown's 4-space indented-code-block threshold without needing
     to reason about which text nodes are at the start/end of a block
     versus adjacent to inline markup, where a single space of
     separation still matters (e.g. "text <ulink>...</ulink> more").

     Deliberately does NOT touch programlisting — real code blocks need
     their whitespace preserved exactly, which is why that template
     (below) reads its content with xsl:value-of directly rather than
     via apply-templates, bypassing template dispatch (and this
     override) entirely for that element's text. -->
<xsl:template match="text()">
	<xsl:call-template name="collapse-whitespace">
		<xsl:with-param name="text" select="translate(., '&#9;&#10;&#13;', '   ')"/>
	</xsl:call-template>
</xsl:template>

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

<!-- DocBook 4's inline-monospace tag — proteus_markdown.xsl already
     backtick-wraps code/command/filename/guilabel/guimenuitem for the
     hand-authored docs, which never use "literal", but this content
     (converted from Sphinx's ``double-backtick`` inline markup) does,
     throughout. -->
<xsl:template match="literal">
	<xsl:text>`</xsl:text><xsl:apply-templates/><xsl:text>`</xsl:text>
</xsl:template>

<!-- DocBook 4's sect1-sect5 encode their own nesting depth in the
     element name itself, unlike DocBook 5's <section>, where the
     inherited "section" template (from proteus_markdown.xsl) instead
     counts ancestor::section elements to size its heading — that
     approach doesn't apply here, so this maps each sectN name straight
     to a heading level instead. -->
<xsl:template match="sect1|sect2|sect3|sect4|sect5">
	<xsl:call-template name="anchor"/>
	<xsl:variable name="level">
		<xsl:choose>
			<xsl:when test="self::sect1">1</xsl:when>
			<xsl:when test="self::sect2">2</xsl:when>
			<xsl:when test="self::sect3">3</xsl:when>
			<xsl:when test="self::sect4">4</xsl:when>
			<xsl:otherwise>5</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:call-template name="hashes">
		<xsl:with-param name="count" select="$level + 1"/>
	</xsl:call-template>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="title/node()"/>
	<xsl:text>&#10;&#10;</xsl:text>
	<xsl:apply-templates select="node()[not(self::title)]"/>
</xsl:template>

<!-- GitHub/Hugo-flavored Markdown table, one column width. DocBook
     tables can express colspan/rowspan/multiple header rows; none of
     that shows up in the csv-table-derived content this is built for,
     so this intentionally doesn't handle it — a table using those
     features would need this extended, not silently mis-render. -->
<xsl:template match="informaltable|table">
	<xsl:text>&#10;</xsl:text>
	<xsl:apply-templates select=".//thead/row[1]" mode="table-row"/>
	<xsl:text>|</xsl:text>
	<xsl:for-each select=".//thead/row[1]/entry">
		<xsl:text> --- |</xsl:text>
	</xsl:for-each>
	<xsl:text>&#10;</xsl:text>
	<xsl:apply-templates select=".//tbody/row" mode="table-row"/>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="row" mode="table-row">
	<xsl:text>|</xsl:text>
	<xsl:for-each select="entry">
		<xsl:text> </xsl:text>
		<xsl:apply-templates select="node()"/>
		<xsl:text> |</xsl:text>
	</xsl:for-each>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- A line break inside a table cell (see convert_dev_docs_to_docbook.sh
     for where these come from). No dedicated template means the default
     XSLT behavior applies templates to <br/>'s children — it has none,
     so the break would just silently vanish. Inline raw HTML <br> is
     valid inside a Markdown table cell and Hugo renders it fine, so
     emit that rather than trying to fake a line break some other way
     inside a single table-cell line. -->
<xsl:template match="br"><xsl:text>&lt;br&gt;</xsl:text></xsl:template>

<!-- Fenced code block. pandoc's DocBook writer doesn't carry the
     source's code-block language onto <programlisting> in a standard
     attribute, so this can't label the fence with a language — still
     far better than the default unmatched-element behavior, which
     would apply-templates into the text and lose the fencing and
     whitespace/indentation entirely. -->
<xsl:template match="programlisting">
	<xsl:text>&#10;```&#10;</xsl:text>
	<xsl:value-of select="."/>
	<xsl:text>&#10;```&#10;&#10;</xsl:text>
</xsl:template>

</xsl:stylesheet>

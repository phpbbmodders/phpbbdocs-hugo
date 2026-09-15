<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<!--
	Renders one Sphinx-produced Docutils XML file (from
	`sphinx-build -b xml -D language=<lang>`, against a localized
	`.po` catalog) into a single Hugo Markdown page.

	This is the Sphinx-native sibling of xsl/proteus_hugo_devdocs.xsl
	(the existing Pandoc/DocBook path for the same dev-docs content) —
	same "one invocation renders one page" shape, same xsltproc
	toolchain, but a completely different, unrelated input vocabulary
	(Docutils XML: <section>/<paragraph>/<literal_block>/<reference>,
	not DocBook's <sect1>/<para>/<programlisting>/<ulink>), so this
	file is standalone rather than importing proteus_markdown.xsl.

	Built from real Sphinx 8.1.3 output, not guessed — see
	tests/sphinx_devdocs/fixtures/ and
	docs/TODO/todo-sphinx-devdocs-spike.md for the two prior spikes
	this generalizes and the three real bugs they found, all fixed
	here:

	  1. Angle-bracket text loss: Goldmark (Hugo's Markdown renderer)
	     silently drops unrecognized-looking raw "<...>" as HTML.
	     Prose-emitting contexts (paragraph, admonitions, table cells,
	     etc. — anywhere via the text() template) HTML-escape "<"/">".
	     literal/literal_block bypass text() entirely (reading their
	     content with xsl:value-of instead), so code stays literal —
	     escaping code would corrupt it, which is why this can't be one
	     blanket rule.
	  2. block_quote + literal_block: every line inside a block_quote,
	     including a nested code block's lines, gets the "&gt;" prefix,
	     not just the fence's open/close lines.
	  3. Toctree navigation: <compound classes="toctree-wrapper"> is a
	     verified-reliable structural marker (built and inspected a
	     real 2-file Sphinx project to confirm this, not assumed) for
	     Sphinx's own auto-generated navigation — suppressed entirely.
	     Hugo generates its own section nav already
	     (phpbbdocs_hugo_devdocs.sh's existing approach).

	Two more things this stylesheet does that the spikes didn't need
	to, because a real converter has to be right on content the spikes
	didn't happen to include:

	  - Backtick-fence sizing: an inline `literal` or `literal_block`
	    whose content itself contains a run of backticks gets a fence
	    one backtick longer than that run (standard CommonMark
	    technique), instead of a fixed-width fence that would
	    prematurely terminate.
	  - Internal link resolution: a :doc:/:ref: role's refuri is a
	    Sphinx-relative path (e.g. "../testing/index"), resolved here
	    against $doc-dir (the current file's own directory, passed by
	    the driver script) into a target docname, checked against
	    $known-docnames (every RST file under the source root, also
	    passed by the driver) and emitted as a Hugo {{< relref >}}
	    shortcode — {{< relref >}} because it's Hugo's own robust,
	    self-correcting way to resolve a content-relative path, rather
	    than this stylesheet hand-computing a URL that could go stale.
	    An unresolvable target gets a loud inline diagnostic and an
	    xsl:message, never a silently dropped or silently broken link
	    (matching the same "loud, not silent" rule the catch-all
	    template below applies to any XML element this stylesheet
	    doesn't otherwise recognize).
-->

<xsl:output method="text" encoding="UTF-8"/>

<xsl:param name="page.weight" select="'1'"/>
<xsl:param name="page.translationKey" select="''"/>
<!-- This file's own docname's directory (e.g. "development" for
     development/git.rst, "" for a file directly at the source root),
     used to resolve refuri values on internal <reference> elements. -->
<xsl:param name="doc-dir" select="''"/>
<!-- Every known docname in the source corpus (source-root-relative
     path, no .rst extension, e.g. "testing/unit_testing"), space
     separated, used to validate a resolved internal link target
     before emitting it as a real link. -->
<xsl:param name="known-docnames" select="''"/>
<!-- The Hugo content section a resolved docname is published under
     (phpbbdocs_hugo_devdocs.sh's existing convention hard-codes this
     to "development" — content/<lang>/development/<chapter>/<slug>/ —
     so a relref target needs this prefix to actually resolve against
     real site content, not just the bare source-root-relative
     docname). -->
<xsl:param name="hugo-section" select="'development'"/>

<!-- ===================== string-escaping helpers ===================== -->
<!-- Same two-pass chained-recursion idiom as proteus_hugo_devdocs.xsl's
     quote-escape/backslash-escape/yaml-quote (not shared via import
     since the two stylesheets have no other overlap worth an import
     for) — each pass only emits already-scanned text plus a literal
     replacement and recurses on the unscanned remainder, so a
     replacement is never rescanned by the same pass. Chaining lt-then-gt
     is safe because escaping neither character can introduce the other. -->

<xsl:template name="escape-lt">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, '&lt;')">
			<xsl:value-of select="substring-before($text, '&lt;')"/>
			<xsl:text>&amp;lt;</xsl:text>
			<xsl:call-template name="escape-lt">
				<xsl:with-param name="text" select="substring-after($text, '&lt;')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="escape-gt">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, '&gt;')">
			<xsl:value-of select="substring-before($text, '&gt;')"/>
			<xsl:text>&amp;gt;</xsl:text>
			<xsl:call-template name="escape-gt">
				<xsl:with-param name="text" select="substring-after($text, '&gt;')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="escape-angle-brackets">
	<xsl:param name="text"/>
	<xsl:variable name="lt-done">
		<xsl:call-template name="escape-lt">
			<xsl:with-param name="text" select="$text"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:call-template name="escape-gt">
		<xsl:with-param name="text" select="$lt-done"/>
	</xsl:call-template>
</xsl:template>

<!-- Docutils XML is pretty-printed: a <paragraph>'s text content is
     itself indented/line-wrapped ("\n      Some sentence that\n
     wraps here.\n    "), not a single unbroken line, matching the
     same root cause and fix as proteus_hugo_devdocs.xsl's own text()
     override (see that file's header comment): collapsing whitespace
     runs down to one space is a functional fix, not cosmetic, since
     Markdown reads a 4-space indent as a code block. Deliberately
     does not touch literal_block/literal (they read their content via
     value-of, bypassing text() entirely, since real code needs its
     whitespace preserved exactly). -->
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

<xsl:template name="escape-pipe">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, '|')">
			<xsl:value-of select="substring-before($text, '|')"/>
			<xsl:text>\|</xsl:text>
			<xsl:call-template name="escape-pipe">
				<xsl:with-param name="text" select="substring-after($text, '|')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

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

<!-- Longest run of consecutive backticks anywhere in $text, so a code
     fence can be made one backtick longer than that (CommonMark rule
     for a code span/fence to survive backticks in its own content).

     Deliberately does NOT recurse one character at a time through the
     whole text (a first version of this did, and blew libxslt's
     default 3000-deep template-recursion limit on a real,
     several-thousand-character PHP code block that happened to
     contain zero backticks), so instead this jumps straight to each
     backtick occurrence via substring-after, so recursion depth is
     bounded by how many separate backtick runs exist in the text
     (typically zero or a handful, even in a large code block), not by
     the text's length. count-leading-backticks recurses once per
     character, but only within one run, which is always short. -->
<xsl:template name="count-leading-backticks">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="starts-with($text, '`')">
			<xsl:variable name="rest-count">
				<xsl:call-template name="count-leading-backticks">
					<xsl:with-param name="text" select="substring($text, 2)"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:value-of select="$rest-count + 1"/>
		</xsl:when>
		<xsl:otherwise>0</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="max-backtick-run">
	<xsl:param name="text"/>
	<xsl:param name="running-max" select="0"/>
	<xsl:choose>
		<xsl:when test="not(contains($text, '`'))">
			<xsl:value-of select="$running-max"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="after" select="substring-after($text, '`')"/>
			<xsl:variable name="leading">
				<xsl:call-template name="count-leading-backticks">
					<xsl:with-param name="text" select="$after"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="run-len" select="$leading + 1"/>
			<xsl:variable name="new-max">
				<xsl:choose>
					<xsl:when test="$run-len &gt; $running-max"><xsl:value-of select="$run-len"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$running-max"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:call-template name="max-backtick-run">
				<xsl:with-param name="text" select="substring($after, $leading + 1)"/>
				<xsl:with-param name="running-max" select="$new-max"/>
			</xsl:call-template>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="repeat-backtick">
	<xsl:param name="count"/>
	<xsl:if test="$count &gt; 0">
		<xsl:text>`</xsl:text>
		<xsl:call-template name="repeat-backtick">
			<xsl:with-param name="count" select="$count - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<xsl:template name="repeat-space">
	<xsl:param name="count"/>
	<xsl:if test="$count &gt; 0">
		<xsl:text> </xsl:text>
		<xsl:call-template name="repeat-space">
			<xsl:with-param name="count" select="$count - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!-- Replaces every "/" in $text with "-", used to flatten a resolved
     docname's sub-chapter path segments into phpbbdocs_hugo_devdocs.sh's
     real slug convention (see hugo-path-for-docname below). Bounded by
     segment count, not text length. -->
<xsl:template name="replace-slashes-with-hyphens">
	<xsl:param name="text"/>
	<xsl:choose>
		<xsl:when test="contains($text, '/')">
			<xsl:value-of select="substring-before($text, '/')"/>
			<xsl:text>-</xsl:text>
			<xsl:call-template name="replace-slashes-with-hyphens">
				<xsl:with-param name="text" select="substring-after($text, '/')"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Turns a resolved source-root-relative docname (e.g.
     "migrations/tools/index") into the actual published Hugo path
     phpbbdocs_hugo_devdocs.sh's existing convention produces
     ("migrations/tools-index"), since that script treats only the FIRST
     path segment as the chapter directory and flattens every deeper
     segment into one hyphen-joined slug (its own "Bare-filename slugs
     collide" comment explains why: tr '/' '-' on the path relative to
     the chapter dir). A docname with no "/" at all (a file directly at
     the source root) has no sub-chapter path to flatten. -->
<xsl:template name="hugo-path-for-docname">
	<xsl:param name="docname"/>
	<xsl:choose>
		<xsl:when test="contains($docname, '/')">
			<xsl:variable name="chapter" select="substring-before($docname, '/')"/>
			<xsl:variable name="rest" select="substring-after($docname, '/')"/>
			<xsl:value-of select="$chapter"/><xsl:text>/</xsl:text>
			<xsl:call-template name="replace-slashes-with-hyphens">
				<xsl:with-param name="text" select="$rest"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$docname"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- ===================== path resolution for internal links ===================== -->
<!-- Pops the last "/"-separated segment off $path (used for ".."
     while resolving a refuri). No "/" at all means $path is a single
     segment, and popping it leaves nothing. -->
<xsl:template name="drop-last-segment">
	<xsl:param name="path"/>
	<xsl:choose>
		<xsl:when test="contains($path, '/')">
			<xsl:variable name="first" select="substring-before($path, '/')"/>
			<xsl:variable name="rest" select="substring-after($path, '/')"/>
			<xsl:choose>
				<xsl:when test="contains($rest, '/')">
					<xsl:value-of select="$first"/><xsl:text>/</xsl:text>
					<xsl:call-template name="drop-last-segment">
						<xsl:with-param name="path" select="$rest"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="$first"/></xsl:otherwise>
			</xsl:choose>
		</xsl:when>
		<xsl:otherwise></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Resolves a Sphinx-relative path ($tokens, "/"-separated, may
     contain ".."/"." segments) against a base directory ($stack,
     starts as $doc-dir) into a normalized docname, the same way
     Sphinx itself resolves a :doc:/:ref: role's refuri. -->
<xsl:template name="resolve-path">
	<xsl:param name="tokens"/>
	<xsl:param name="stack"/>
	<xsl:choose>
		<xsl:when test="$tokens = ''">
			<xsl:value-of select="$stack"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="token">
				<xsl:choose>
					<xsl:when test="contains($tokens, '/')"><xsl:value-of select="substring-before($tokens, '/')"/></xsl:when>
					<xsl:otherwise><xsl:value-of select="$tokens"/></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="rest">
				<xsl:choose>
					<xsl:when test="contains($tokens, '/')"><xsl:value-of select="substring-after($tokens, '/')"/></xsl:when>
					<xsl:otherwise></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:variable name="new-stack">
				<xsl:choose>
					<xsl:when test="$token = '..'">
						<xsl:call-template name="drop-last-segment">
							<xsl:with-param name="path" select="$stack"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:when test="$token = '.' or $token = ''">
						<xsl:value-of select="$stack"/>
					</xsl:when>
					<xsl:when test="$stack = ''">
						<xsl:value-of select="$token"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$stack"/><xsl:text>/</xsl:text><xsl:value-of select="$token"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="contains($tokens, '/') or $rest != ''">
					<xsl:call-template name="resolve-path">
						<xsl:with-param name="tokens" select="$rest"/>
						<xsl:with-param name="stack" select="$new-stack"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise><xsl:value-of select="$new-stack"/></xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="is-known-docname">
	<xsl:param name="docname"/>
	<xsl:if test="contains(concat(' ', $known-docnames, ' '), concat(' ', $docname, ' '))">yes</xsl:if>
</xsl:template>

<!-- ===================== document root / front matter ===================== -->

<xsl:template match="/document">
	<xsl:variable name="root-section" select="section[1]"/>
	<xsl:text>---&#10;title: "</xsl:text>
	<xsl:call-template name="yaml-quote">
		<xsl:with-param name="text" select="normalize-space($root-section/title)"/>
	</xsl:call-template>
	<xsl:text>"&#10;weight: </xsl:text><xsl:value-of select="$page.weight"/>
	<xsl:if test="$page.translationKey != ''">
		<xsl:text>&#10;translationKey: </xsl:text><xsl:value-of select="$page.translationKey"/>
	</xsl:if>
	<xsl:text>&#10;---&#10;&#10;</xsl:text>
	<xsl:apply-templates select="$root-section/node()[not(self::title)]"/>
</xsl:template>

<!-- Prose text: HTML-escape "<"/">" so Goldmark can't misread them as
     unknown HTML tags and drop them (the angle-bracket bug). Table
     cells additionally need "|" escaped, since a bare "|" would
     otherwise be misread as a column separator. literal/literal_block
     bypass this template entirely (see their own templates). -->
<xsl:template match="text()">
	<xsl:variable name="collapsed">
		<xsl:call-template name="collapse-whitespace">
			<xsl:with-param name="text" select="translate(., '&#9;&#10;&#13;', '   ')"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="escaped">
		<xsl:call-template name="escape-angle-brackets">
			<xsl:with-param name="text" select="$collapsed"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="ancestor::entry">
			<xsl:call-template name="escape-pipe">
				<xsl:with-param name="text" select="$escaped"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise><xsl:value-of select="$escaped"/></xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- ===================== headings ===================== -->
<!-- The outermost <section> (the whole page) has no ancestor::section
     and its <title> already became the front-matter title above, so
     it's excluded here — only actual nested sections get a rendered
     Markdown heading. First real nesting level (ancestor count 1)
     renders "##" (H2), matching proteus_hugo_devdocs.xsl's sect1 -> H2
     convention, since the page's own H1 is the front-matter title. -->
<!-- Sphinx's own section @ids are stable across translation (they come
     from the ORIGINAL English heading text, not the translated one) ,
     translated heading text is not: Goldmark auto-generates a heading's
     HTML id by slugifying whatever text is actually there, so a
     translated heading gets a translated (different) auto-id, breaking
     any same-document `` `Name`_ `` or :ref: link still pointing at the
     original id. Appending "{#<original-id>}" (confirmed working
     against this project's actual Hugo/Goldmark config, which parses
     heading-attribute syntax by default) pins the anchor back to the
     stable id regardless of translation. A section can carry more than
     one space-separated id (RST target aliases); only the first is
     used, matching the id references in this corpus actually target. -->
<xsl:template match="section">
	<xsl:variable name="level" select="count(ancestor::section) + 1"/>
	<xsl:variable name="first-id">
		<xsl:choose>
			<xsl:when test="contains(@ids, ' ')"><xsl:value-of select="substring-before(@ids, ' ')"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="@ids"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:text>&#10;</xsl:text>
	<xsl:call-template name="repeat-hash">
		<xsl:with-param name="count" select="$level"/>
	</xsl:call-template>
	<xsl:text> </xsl:text>
	<xsl:apply-templates select="title/node()"/>
	<xsl:if test="$first-id != ''">
		<xsl:text> {#</xsl:text><xsl:value-of select="$first-id"/><xsl:text>}</xsl:text>
	</xsl:if>
	<xsl:text>&#10;&#10;</xsl:text>
	<xsl:apply-templates select="node()[not(self::title)]"/>
</xsl:template>

<xsl:template name="repeat-hash">
	<xsl:param name="count"/>
	<xsl:if test="$count &gt; 0">
		<xsl:text>#</xsl:text>
		<xsl:call-template name="repeat-hash">
			<xsl:with-param name="count" select="$count - 1"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!-- ===================== basic block/inline content ===================== -->

<xsl:template match="paragraph">
	<xsl:apply-templates/>
	<xsl:text>&#10;&#10;</xsl:text>
</xsl:template>

<xsl:template match="strong">
	<xsl:text>**</xsl:text><xsl:apply-templates/><xsl:text>**</xsl:text>
</xsl:template>

<xsl:template match="emphasis">
	<xsl:text>*</xsl:text><xsl:apply-templates/><xsl:text>*</xsl:text>
</xsl:template>

<!-- title_reference is RST's single-backtick role (`like this`) — this
     corpus uses it for command/branch-name-like text, so rendering it
     as inline code (matching how the DocBook path already treats
     "literal") is the correct reading, not a generic italic. -->
<xsl:template match="title_reference">
	<xsl:call-template name="inline-code">
		<xsl:with-param name="text" select="string(.)"/>
	</xsl:call-template>
</xsl:template>

<xsl:template match="literal">
	<xsl:call-template name="inline-code">
		<xsl:with-param name="text" select="string(.)"/>
	</xsl:call-template>
</xsl:template>

<!-- Shared by literal and title_reference: reads raw text via string()
     (bypassing the escaping text() template, since this is code/
     command text that must stay literal) and picks a fence at least
     one backtick longer than the content's own longest backtick run,
     padding with a space when the content starts/ends with a backtick
     so the fence doesn't visually fuse with it.

     Inside a table cell, a literal "|" in the code still needs
     escaping, unlike "<"/">" (which must stay literal for the code
     to render correctly), an unescaped "|" isn't a code-correctness
     question, it's a Markdown table-syntax question: table row
     parsing splits on "|" regardless of what's inside a code span, so
     this is table-context escaping layered on top of (not instead of)
     staying otherwise literal, matching how text() does the same for
     plain table-cell prose. -->
<xsl:template name="inline-code">
	<xsl:param name="text"/>
	<xsl:variable name="run">
		<xsl:call-template name="max-backtick-run">
			<xsl:with-param name="text" select="$text"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="fence-len" select="$run + 1"/>
	<xsl:variable name="pad" select="starts-with($text, '`') or substring($text, string-length($text)) = '`'"/>
	<xsl:variable name="display-text">
		<xsl:choose>
			<xsl:when test="ancestor::entry">
				<xsl:call-template name="escape-pipe">
					<xsl:with-param name="text" select="$text"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise><xsl:value-of select="$text"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:call-template name="repeat-backtick"><xsl:with-param name="count" select="$fence-len"/></xsl:call-template>
	<xsl:if test="$pad"><xsl:text> </xsl:text></xsl:if>
	<xsl:value-of select="$display-text"/>
	<xsl:if test="$pad"><xsl:text> </xsl:text></xsl:if>
	<xsl:call-template name="repeat-backtick"><xsl:with-param name="count" select="$fence-len"/></xsl:call-template>
</xsl:template>

<!-- Fenced code block. @language carries the real source language
     (unlike the DocBook path's programlisting, which pandoc doesn't
     tag) — "default"/"text" (Sphinx's fallback when no language was
     specified) is omitted rather than emitted as a bogus fence tag.
     Content read via value-of (bypassing text()'s escaping) since code
     must stay literal; xml:space="preserve" on the source element
     means whitespace here is already exactly as authored. -->
<xsl:template match="literal_block">
	<xsl:variable name="run">
		<xsl:call-template name="max-backtick-run">
			<xsl:with-param name="text" select="string(.)"/>
		</xsl:call-template>
	</xsl:variable>
	<xsl:variable name="fence-len">
		<xsl:choose>
			<xsl:when test="$run + 1 &gt; 3"><xsl:value-of select="$run + 1"/></xsl:when>
			<xsl:otherwise>3</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:if test="not(ancestor::block_quote)"><xsl:text>&#10;</xsl:text></xsl:if>
	<xsl:call-template name="repeat-backtick"><xsl:with-param name="count" select="$fence-len"/></xsl:call-template>
	<xsl:if test="@language != '' and @language != 'default' and @language != 'text'">
		<xsl:value-of select="@language"/>
	</xsl:if>
	<xsl:text>&#10;</xsl:text>
	<xsl:value-of select="."/>
	<xsl:text>&#10;</xsl:text>
	<xsl:call-template name="repeat-backtick"><xsl:with-param name="count" select="$fence-len"/></xsl:call-template>
	<xsl:text>&#10;&#10;</xsl:text>
</xsl:template>

<!-- Every line of a block_quote's rendered Markdown, including a
     nested literal_block's fence and code lines, needs the "&gt;"
     prefix or the blockquote breaks out of the quote partway through
     (the Phase 1 spike's bug 2) — rendering the quote's content
     normally first, into a variable, then prefixing every line of the
     RESULT is simpler and more reliable than teaching every possible
     nested template to emit its own prefix. -->
<xsl:template match="block_quote">
	<xsl:variable name="body">
		<xsl:apply-templates/>
	</xsl:variable>
	<xsl:call-template name="prefix-lines">
		<xsl:with-param name="text" select="$body"/>
		<xsl:with-param name="prefix" select="'&gt; '"/>
	</xsl:call-template>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- Prefixes EVERY line of $text with $prefix, including a genuinely
     blank line in the middle of $text, a blockquote's own Markdown
     rule is that an unmarked blank line ends the blockquote, so a
     blank line inside a quoted code block (this template's original
     motivating case: block_quote wrapping a literal_block whose code
     itself contains a blank line) needs the "&gt; " marker too, or
     the quote breaks apart around it. Also reused for list-item
     continuation indentation (a plain space prefix there), where a
     prefixed blank line is harmless even though not strictly required. -->
<xsl:template name="prefix-lines">
	<xsl:param name="text"/>
	<xsl:param name="prefix"/>
	<xsl:choose>
		<xsl:when test="contains($text, '&#10;')">
			<xsl:value-of select="$prefix"/><xsl:value-of select="substring-before($text, '&#10;')"/>
			<xsl:text>&#10;</xsl:text>
			<xsl:call-template name="prefix-lines">
				<xsl:with-param name="text" select="substring-after($text, '&#10;')"/>
				<xsl:with-param name="prefix" select="$prefix"/>
			</xsl:call-template>
		</xsl:when>
		<xsl:when test="$text != ''">
			<xsl:value-of select="$prefix"/><xsl:value-of select="$text"/>
		</xsl:when>
	</xsl:choose>
</xsl:template>

<xsl:template match="line_block">
	<xsl:apply-templates/>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="line">
	<xsl:apply-templates/>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="image">
	<xsl:text>&#10;![</xsl:text>
	<xsl:value-of select="@alt"/>
	<xsl:text>](</xsl:text>
	<xsl:value-of select="@uri"/>
	<xsl:text>)&#10;&#10;</xsl:text>
</xsl:template>

<!-- target is a pure anchor (heading-ID stability, cross-reference
     bookkeeping) with no visible content of its own — nothing to
     render, and it's expected/common, not "unsupported". -->
<xsl:template match="target"/>

<!-- ===================== admonitions ===================== -->

<xsl:template name="admonition">
	<xsl:param name="label"/>
	<xsl:variable name="body">
		<xsl:text>**</xsl:text><xsl:value-of select="$label"/><xsl:text>:** </xsl:text>
		<xsl:apply-templates/>
	</xsl:variable>
	<xsl:text>&#10;</xsl:text>
	<xsl:call-template name="prefix-lines">
		<xsl:with-param name="text" select="$body"/>
		<xsl:with-param name="prefix" select="'&gt; '"/>
	</xsl:call-template>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="note"><xsl:call-template name="admonition"><xsl:with-param name="label">Note</xsl:with-param></xsl:call-template></xsl:template>
<xsl:template match="warning"><xsl:call-template name="admonition"><xsl:with-param name="label">Warning</xsl:with-param></xsl:call-template></xsl:template>
<xsl:template match="tip"><xsl:call-template name="admonition"><xsl:with-param name="label">Tip</xsl:with-param></xsl:call-template></xsl:template>
<xsl:template match="seealso"><xsl:call-template name="admonition"><xsl:with-param name="label">See also</xsl:with-param></xsl:call-template></xsl:template>

<!-- ===================== lists ===================== -->

<xsl:template match="bullet_list">
	<xsl:text>&#10;</xsl:text>
	<xsl:for-each select="list_item">
		<xsl:call-template name="list-item-body">
			<xsl:with-param name="marker" select="'- '"/>
		</xsl:call-template>
	</xsl:for-each>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template match="enumerated_list">
	<xsl:text>&#10;</xsl:text>
	<xsl:for-each select="list_item">
		<xsl:variable name="marker"><xsl:value-of select="position()"/><xsl:text>. </xsl:text></xsl:variable>
		<xsl:call-template name="list-item-body">
			<xsl:with-param name="marker" select="$marker"/>
		</xsl:call-template>
	</xsl:for-each>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- A list item's own first paragraph renders on the marker's line (no
     leading blank line); anything else in the item (a nested list, a
     second paragraph, quoted/code continuation) is indented to the
     marker's own width via prefix-lines, matching CommonMark's
     requirement that a list item's continuation content be indented
     under its marker to stay part of that item rather than becoming
     unrelated top-level content, an ordered list's marker width
     varies with the item number's digit count ("1. " vs "10. "), so
     this is computed per item, not a fixed constant. -->
<xsl:template name="list-item-body">
	<xsl:param name="marker"/>
	<xsl:value-of select="$marker"/>
	<xsl:apply-templates select="paragraph[1]/node()"/>
	<xsl:text>&#10;</xsl:text>
	<xsl:variable name="rest">
		<xsl:apply-templates select="node()[not(self::paragraph and not(preceding-sibling::paragraph))]"/>
	</xsl:variable>
	<xsl:if test="$rest != ''">
		<xsl:variable name="indent">
			<xsl:call-template name="repeat-space">
				<xsl:with-param name="count" select="string-length($marker)"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:call-template name="prefix-lines">
			<xsl:with-param name="text" select="$rest"/>
			<xsl:with-param name="prefix" select="$indent"/>
		</xsl:call-template>
	</xsl:if>
</xsl:template>

<!-- ===================== tables ===================== -->
<!-- Handles both a real header row (thead present, from :header-rows:)
     and a headerless csv-table (only tbody, no :header: line) by
     promoting the first tbody row to the header in the latter case —
     either way GFM gets a valid header + separator. Column count comes
     from colspec/tgroup rather than counting header entries, so it
     stays correct even in the promoted-row case. -->
<xsl:template match="table">
	<xsl:variable name="cols">
		<xsl:choose>
			<xsl:when test="tgroup/@cols"><xsl:value-of select="tgroup/@cols"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="count(tgroup/colspec)"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:text>&#10;</xsl:text>
	<xsl:choose>
		<xsl:when test="tgroup/thead/row">
			<xsl:apply-templates select="tgroup/thead/row[1]" mode="table-row"/>
			<xsl:call-template name="table-separator"><xsl:with-param name="cols" select="$cols"/></xsl:call-template>
			<xsl:apply-templates select="tgroup/tbody/row" mode="table-row"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="tgroup/tbody/row[1]" mode="table-row"/>
			<xsl:call-template name="table-separator"><xsl:with-param name="cols" select="$cols"/></xsl:call-template>
			<xsl:apply-templates select="tgroup/tbody/row[position() &gt; 1]" mode="table-row"/>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template name="table-separator">
	<xsl:param name="cols"/>
	<xsl:text>|</xsl:text>
	<xsl:call-template name="table-separator-cell"><xsl:with-param name="remaining" select="$cols"/></xsl:call-template>
	<xsl:text>&#10;</xsl:text>
</xsl:template>

<xsl:template name="table-separator-cell">
	<xsl:param name="remaining"/>
	<xsl:if test="$remaining &gt; 0">
		<xsl:text> --- |</xsl:text>
		<xsl:call-template name="table-separator-cell">
			<xsl:with-param name="remaining" select="$remaining - 1"/>
		</xsl:call-template>
	</xsl:if>
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

<!-- entry's real content is wrapped in <paragraph>, whose own template
     would add a blank-line pair that has no place inside a table cell
     — apply-templates on entry (above) reaches paragraph/node()
     indirectly through the normal paragraph template otherwise, so
     override it specifically inside a cell to suppress that spacing. -->
<xsl:template match="entry/paragraph">
	<xsl:apply-templates/>
</xsl:template>

<!-- ===================== links ===================== -->

<!-- Toctree-generated navigation — verified structural marker, no
     empty-refuri fallback (see header comment). Suppressed entirely;
     Hugo builds its own section nav. -->
<xsl:template match="compound[contains(concat(' ', @classes, ' '), ' toctree-wrapper ')]"/>

<xsl:template match="reference">
	<xsl:choose>
		<xsl:when test="@internal = 'True' and @refuri">
			<xsl:call-template name="internal-reference"/>
		</xsl:when>
		<xsl:when test="@refid and not(@refuri)">
			<!-- RST's `` `Name`_ `` same-document-by-name reference
			     (e.g. an intro bullet list linking down to this page's
			     own later sections). Docutils gives these a @refid
			     with no @refuri at all, distinct from the :doc:/:ref:
			     cross-file case above. -->
			<xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>](#</xsl:text>
			<xsl:value-of select="@refid"/>
			<xsl:text>)</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>](</xsl:text>
			<xsl:value-of select="@refuri"/>
			<xsl:text>)</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="internal-reference">
	<xsl:variable name="path-part">
		<xsl:choose>
			<xsl:when test="contains(@refuri, '#')"><xsl:value-of select="substring-before(@refuri, '#')"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="@refuri"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:variable name="fragment">
		<xsl:choose>
			<xsl:when test="contains(@refuri, '#')"><xsl:value-of select="substring-after(@refuri, '#')"/></xsl:when>
			<xsl:otherwise></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<xsl:choose>
		<xsl:when test="@refuri = ''">
			<!-- Genuinely empty refuri, no path AND no "#fragment" at
			     all, distinct from a real "#fragment"-only same-page
			     link below. Not a valid target of any kind; loud, not a
			     silent link to nowhere. -->
			<xsl:message>
				<xsl:text>WARNING: internal reference has an empty refuri (no path, no fragment) -- no diagnosable target</xsl:text>
			</xsl:message>
			<xsl:apply-templates/>
			<xsl:text> [UNRESOLVED LINK: empty refuri]</xsl:text>
		</xsl:when>
		<xsl:when test="$path-part = ''">
			<!-- Pure "#fragment" same-document link: no docname to
			     resolve, just an in-page anchor. -->
			<xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>](#</xsl:text>
			<xsl:value-of select="$fragment"/><xsl:text>)</xsl:text>
		</xsl:when>
		<xsl:otherwise>
			<xsl:variable name="resolved">
				<xsl:call-template name="resolve-path">
					<xsl:with-param name="tokens" select="$path-part"/>
					<xsl:with-param name="stack" select="$doc-dir"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="known">
				<xsl:call-template name="is-known-docname">
					<xsl:with-param name="docname" select="$resolved"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$known = 'yes'">
					<xsl:variable name="hugo-path">
						<xsl:call-template name="hugo-path-for-docname">
							<xsl:with-param name="docname" select="$resolved"/>
						</xsl:call-template>
					</xsl:variable>
					<xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>]({{&lt; relref &quot;</xsl:text>
					<xsl:if test="$hugo-section != ''">
						<xsl:value-of select="$hugo-section"/><xsl:text>/</xsl:text>
					</xsl:if>
					<xsl:value-of select="$hugo-path"/>
					<xsl:if test="$fragment != ''">
						<xsl:text>#</xsl:text><xsl:value-of select="$fragment"/>
					</xsl:if>
					<xsl:text>&quot; &gt;}})</xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message>
						<xsl:text>WARNING: unresolved internal reference refuri="</xsl:text>
						<xsl:value-of select="@refuri"/>
						<xsl:text>" (resolved docname "</xsl:text>
						<xsl:value-of select="$resolved"/>
						<xsl:text>" not found in known-docnames)</xsl:text>
					</xsl:message>
					<xsl:apply-templates/>
					<xsl:text> [UNRESOLVED LINK: </xsl:text>
					<xsl:value-of select="@refuri"/>
					<xsl:text>]</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- The :doc:/:ref: role's own rendered text is wrapped one level
     deeper in <inline classes="doc">; nothing special to do beyond
     recursing into it like any other inline container. -->
<xsl:template match="inline">
	<xsl:apply-templates/>
</xsl:template>

<!-- ===================== catch-all: unsupported content is loud ===================== -->
<!-- Lowest-priority match (XSLT gives a bare "*" pattern priority
     -0.5, below every named-element template above), so this only
     fires for an element genuinely not handled anywhere above. Still
     recurses into children best-effort rather than silently dropping
     the subtree, but both an xsl:message and a visible inline marker
     make the gap impossible to miss. -->
<xsl:template match="*">
	<xsl:message>
		<xsl:text>WARNING: unsupported Sphinx XML element &lt;</xsl:text>
		<xsl:value-of select="name()"/>
		<xsl:text>&gt; encountered - rendering children best-effort, verify output.</xsl:text>
	</xsl:message>
	<xsl:text> [UNSUPPORTED: </xsl:text><xsl:value-of select="name()"/><xsl:text>] </xsl:text>
	<xsl:apply-templates/>
</xsl:template>

</xsl:stylesheet>

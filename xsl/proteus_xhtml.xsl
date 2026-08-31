<?xml version='1.0'?>
<xsl:stylesheet  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="xhtml/chunk.xsl"/>

<xsl:param name="base.dir" select="'./'"/>

<xsl:param name="chunk.fast" select="1"/>
<xsl:param name="chunk.section.depth" select="1"/>

<!-- Do NOT add the first section into the starting chunk -->
<xsl:param name="chunk.first.sections" select="1"/>
<!-- DO NOT Enumerate chapters/sections -->
<xsl:param name="chapter.autolabel" select="0"/>
<xsl:param name="section.autolabel" select="0"/>
<!-- Include numebers of the top elements -->
<xsl:param name="section.label.includes.component.label" select="0"/>
<!-- We use the section / chapter ids as filenames -->
<xsl:param name="use.id.as.filename" select="1"/>
<!-- TOC -->
<xsl:param name="toc.section.depth" select="1"/>

<xsl:param name="phpbb.suppress.authors" select="1"></xsl:param>
<xsl:param name="phpbb.suppress.revision" select="1"></xsl:param>
<xsl:param name="phpbb.suppress.chapterCopyright" select="1"></xsl:param>

<xsl:param name="chunker.output.omit-xml-declaration" select="'yes'"/>
<xsl:param name="chunker.output.doctype-public" select="''"/>
<xsl:param name="chunker.output.doctype-system" select="''"/>

<xsl:template name="chunk-element-content">
	<xsl:param name="prev"/>
	<xsl:param name="next"/>
	<xsl:param name="nav.context"/>
	<xsl:param name="content">
		<xsl:apply-imports/>
	</xsl:param>

	<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html>
&lt;html lang="</xsl:text>
	<xsl:copy-of select="$blang"/>
	<xsl:text disable-output-escaping="yes">" dir="</xsl:text>
	<xsl:copy-of select="$bdir"/>
	<xsl:text disable-output-escaping="yes">">
&lt;head>
&lt;title>phpBB 3.3 Documentation&lt;/title>
&lt;meta charset="UTF-8" />
&lt;meta name="viewport" content="width=device-width, initial-scale=1" />
&lt;style>
body {
	margin: 0;
	padding: 0;
	font-family: Helvetica,Arial,sans-serif;
	background-color: #f1f3f5;
	font-size: 16px;
	line-height: 21px;
}
hr, .toc > p, .author h3 {
	display: none;
}
p, h1, h2, h3, h4 {
	clear: both;
}
a {
	color: #069;
	font-weight: bold;
	text-decoration: none;
}
a:hover {
	color: #a22;
}
#wrap {
	position: relative;
	width: 95%;
	max-width: 1160px;
	margin: 10px auto;
   	background-color: #fff;
	color: #222;
	padding: 10px;
	border: solid 1px #ddd;
	border-radius: 8px;
}
h1.title {
	font-size: 28px;
	margin-bottom: 56px;
}
.nav {
	position: sticky;
	top: 0;
	z-index: 2;
	padding: 8px 0;
	background-color: inherit;
	text-align: right;
}
.navitem {
	display: inline-block;
	padding: 0 12px;
	height: 32px;
	line-height: 32px;
	background-color: #555;
	color: #eee;
	font-size: 18px;
	border-radius: 4px;
}
.navitem:hover {
	background-color: #379;
	color: #fff;
}
.navitem + .navitem {
	margin-left: 15px;
}
.toc p {
	margin-top: 0;
}
.toc dd {
	margin-left: 30px;
}
.toc span.chapter {
	display:block;
	margin: 10px 0 3px;
	font-size: 20px;
}
.tip, .important, .note, .copyright {
	margin: 0.8em 0.5em;
	color: #000;
	font-family: Verdana,Geneva,sans-serif;
	font-size: 0.9em;
	border: 1px solid #aaa;
	padding: 0.5em;
	border-radius: 4px;
	clear: both;
}
.tip {
	background-color: #ffc;
}
.important {
	background-color: #fc9;
}
.note {
	background-color: #ffc;
}
.copyright {
	margin: 2em 0 0;
	background-color: #eee;
	text-align:center;
}
.tip h3, .important h3, .note h3 {
	margin: 0 0 0.5em;
	padding: 0;
}
.tip p, .important p, .note p {
	margin: 0;
}
ul li p, ol li p {
	margin: 0;
}
.figure {
	float: left;
	margin: 10px 0;
	clear: both;
	margin-top: 20px;	
}
.figure .title {
	margin: 0;
	margin-left: 10px;
	background-color: #e1ebf2;
	display: inline;
	border-radius: 10px 10px 0 0;
	padding: 10px;
	padding-top: 5px;
}
.figure .title b {
	font-weight: normal;
}
.inlinemediaobject img {
	max-width: 100%;
}
.mediaobject img {
	display: block;
	background-color: #e1ebf2;	
	padding: 10px;
	max-width: calc(100% - 20px);
}
.mediaobject .caption p {
	text-align: center;
	font-size: 0.8em;
	line-height: 1em;
	margin: 0;
	padding: 0;
	margin-top: 5px;
	font-style: italic;
}
.guilabel {
	text-transform: uppercase;
	font-size: 0.8em;
	font-family: Arial;
}
.variablelist dt {
	font-weight: bold;
	margin: 0;
}
.variablelist dd p {
	font-style: italic;
	margin: 0;
	padding: 0;
}
.variablelist  dd {
	margin-bottom: 1em;
	margin-left: 0;
}
@media only screen and (max-width:899px) {
	#wrap {
		width: auto;
		max-width: none;
		margin: 0;
		padding: 10px;
		border: none;
		border-radius: 0;
	}
}
&lt;/style>
&lt;/head>
&lt;body>
&lt;div id="wrap">
</xsl:text>
	<xsl:call-template name="main.navigation">
		<xsl:with-param name="prev" select="$prev"/>
		<xsl:with-param name="next" select="$next"/>
		<xsl:with-param name="nav.context" select="$nav.context"/>
	</xsl:call-template>

	<xsl:copy-of select="$content"/>

<!-- Copyright -->
<xsl:text disable-output-escaping="yes">
	&lt;div class="copyright">(c) 2006, 2008 phpBB Group - Licensed under the Creative Commons &lt;a href="http://creativecommons.org/licenses/by-nc-sa/3.0/">Attribution-NonCommercial-ShareAlike 3.0&lt;/a> license&lt;br>Modified by Dion Designs to correctly output docs as HTML&lt;/div>
&lt;/div>
&lt;/body>
&lt;/html></xsl:text>
</xsl:template>

<!-- Prevent image links breaking on yavin -->
<xsl:template match="@fileref">
	<xsl:value-of select="."/>
</xsl:template>
</xsl:stylesheet>

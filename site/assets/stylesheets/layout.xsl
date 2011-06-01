<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output cdata-section-elements="script"/>

  <xsl:template match="/">

    <html>
    <head>
      <title>Reap</title>

      <link href="style.css" rel="stylesheet" type="text/css"/>
      <link href="img/source.png" rel="shortcut icon"/>
    </head>

    <body>

    <div class="menu">
      <a href="index.xml">Home</a> &#x00B7;
      <a href="tutorial.xml">Tutorial</a> &#x00B7;
      <a href="rdoc/index.html">Library</a> |
      <a href="http://rubyforge.org/frs/?group_id=811">Download</a> &#x00B7;
      <a href="http://rubyforge.org/mail/?group_id=811">Mail</a> &#x00B7;
      <a href="http://rubyforge.org/forum/?group_id=811">Forum</a> &#x00B7;
      <a href="http://rubyforge.org/news/?group_id=811">News</a> &#x00B7;
      <a href="http://rubyforge.org/scm/?group_id=811">Source</a> &#x00B7;
      <a href="http://rubyforge.org/tracker/?group_id=811">Ticket</a>
    </div>

    <div class="container">

      <div class="ad">
        <div class="tiger" style="padding-top: 10px;">
          <img src="img/tiger-sm.png"/>

          <a href="http://tigerops.psytower.info">
            <img src="img/tiger_logo.png" width="150px" align="top"/>
          </a>

          Ads for OSS!<br/><br/>

          <b>ALSO BY US</b><br/>

          <a href="http://english.rubyforge.org">English</a> <br/>
          <a href="http://stick.rubyforge.org">Stick</a> <br/>
          <a href="http://facets.rubyforge.org">Facets</a> <br/>
        </div>

        <iframe class="adframe" src="ads/amazon.html" scrolling="no" align="middle" frameborder="0" marginwidth="0"></iframe>
        <br/><br/>
        <iframe class="adframe" src="ads/google.html" scrolling="no" align="middle" frameborder="0" marginwidth="0"></iframe>
      </div>

      <div class="banner">
        <img src="img/clipboard.png" align="right" style="margin: 15px;"/> <br/>
        <span class="title">REAP</span> <br/>
        <span class="subtitle">Ruby Project Toolbox</span>
      </div>

      <div class="text">
        <div class="content textile">
          <xsl:apply-templates />
        </div>

        <div class="copyright">
          <p>Reap, Copyright &#x00A9; 2007 <a href="http://psytower.info/tigerops">Tiger Ops</a></p>

          <p>Website design by <a href="http://psytower.info/transcode/">Trans</a> using XSL/XSLT.</p>
        </div>
      </div>
    </div>

    </body>
    </html>

  </xsl:template>

  <xsl:template match="content">
    <xsl:copy-of select="."/>
  </xsl:template>

</xsl:stylesheet>

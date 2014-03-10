﻿<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="Guide.ascx.cs" Inherits="ILPathways.Controls.Guide" %>

<script type="text/javascript">
  var videosLoaded = false;
  var responsiveTimer = {};
  $(document).ready(function () {
    $(window).on("resize", function () {
      redrawLines();
      clearTimeout(responsiveTimer);
      responsiveTimer = setTimeout(function () {
        $(window).trigger("resize");
      }, 1100);
    }).trigger("resize");

  });

  function loadVideos() {
    if (videosLoaded) {
      return;
    }
    $("#overviewBox .youtube").attr("src", "//www.youtube.com/embed/j2wsNSGQQx4?wmode=transparent");
    $("#overviewBox .youtubeLink").attr("href", "http://www.youtube.com/watch?v=j2wsNSGQQx4");
    $("#searchBox .youtube").attr("src", "//www.youtube.com/embed/FedkwWdEiio?wmode=transparent");
    $("#searchBox .youtubeLink").attr("href", "http://www.youtube.com/watch?v=FedkwWdEiio");
    $("#contributeBox .youtube").attr("src", "//www.youtube.com/embed/AsuiH4bUdKY?wmode=transparent");
    $("#contributeBox .youtubeLink").attr("href", "http://www.youtube.com/watch?v=AsuiH4bUdKY");
    $("#resourceBox .youtube").attr("src", "//www.youtube.com/embed/TSvmUeVdGuQ?wmode=transparent");
    $("#resourceBox .youtubeLink").attr("href", "http://www.youtube.com/watch?v=TSvmUeVdGuQ");
    $("#librariesBox .youtube").attr("src", "//www.youtube.com/embed/bpUqQR0YZTA?wmode=transparent");
    $("#librariesBox .youtubeLink").attr("href", "http://www.youtube.com/watch?v=bpUqQR0YZTA");
    $("#shareBox .youtube").attr("src", "//www.youtube.com/embed/Kdgt1ZHkvnM?wmode=transparent");
    $("#shareBox .youtubeLink").attr("href", "http://www.youtube.com/watch?v=j2wsNSGQQx4");
    videosLoaded = true;
  }

  function redrawLines() {
    //Search box to...
    var overviewBox = $("#overviewBox");
    var searchBox = $("#searchBox");
    var contributeBox = $("#contributeBox");
    var resourceBox = $("#resourceBox");
    var librariesBox = $("#librariesBox");
    var isSmall = contributeBox.css("display") == "block";
    var shareBox = $("#shareBox");

    if (!isSmall && !videosLoaded) {
      loadVideos();
    }

    overviewBox.sPosition = overviewBox.position();
    overviewBox.sPosition.outerWidth = overviewBox.outerWidth() + parseInt(overviewBox.css("margin-left").replace("px", ""));
    overviewBox.sPosition.bottom = overviewBox.sPosition.top + parseInt(overviewBox.css("margin-top").replace("px", ""));
    overviewBox.sPosition.left1 = overviewBox.sPosition.left + (overviewBox.sPosition.outerWidth * 0.2);
    overviewBox.sPosition.left2 = overviewBox.sPosition.left + (overviewBox.sPosition.outerWidth * (isSmall ? 0.95 : 0.8));

    searchBox.sPosition = searchBox.position();
    searchBox.sPosition.outerWidth = searchBox.outerWidth() + parseInt(searchBox.css("margin-left").replace("px",""));
    searchBox.sPosition.bottom = searchBox.sPosition.top + searchBox.outerHeight() + parseInt(searchBox.css("margin-top").replace("px", ""));
    searchBox.sPosition.left1 = searchBox.sPosition.left + (searchBox.sPosition.outerWidth * (isSmall ? 0.08 : 0.25));
    searchBox.sPosition.left2 = searchBox.sPosition.left + (searchBox.sPosition.outerWidth * (isSmall ? 0.18 : 0.85));

    contributeBox.sPosition = contributeBox.position();
    contributeBox.sPosition.bottom = contributeBox.sPosition.top + contributeBox.outerHeight() + parseInt(contributeBox.css("margin-top").replace("px", ""));
    contributeBox.sPosition.left1 = contributeBox.sPosition.left + (contributeBox.outerWidth() * (isSmall ? 0.8 : 0.6));

    resourceBox.sPosition = resourceBox.position();
    resourceBox.sPosition.outerWidth = resourceBox.outerWidth();
    resourceBox.sPosition.top = resourceBox.sPosition.top + parseInt(resourceBox.css("margin-top").replace("px", ""));
    resourceBox.sPosition.bottom = resourceBox.sPosition.top + resourceBox.outerHeight();
    resourceBox.sPosition.left = resourceBox.sPosition.left + parseInt(resourceBox.css("margin-left").replace("px", ""));
    resourceBox.sPosition.left1 = resourceBox.sPosition.left + (resourceBox.sPosition.outerWidth * 0.5);
    resourceBox.sPosition.left2 = resourceBox.sPosition.left + (resourceBox.sPosition.outerWidth * 0.9);

    librariesBox.sPosition = librariesBox.position();
    librariesBox.sPosition.top = librariesBox.sPosition.top + parseInt(librariesBox.css("margin-top").replace("px", ""));
    librariesBox.sPosition.bottom = librariesBox.sPosition.top + librariesBox.outerHeight();
    librariesBox.sPosition.left1 = librariesBox.sPosition.left + (librariesBox.outerWidth() * 0.5);

    shareBox.sPosition = shareBox.position();
    shareBox.sPosition.top = shareBox.sPosition.top + parseInt(shareBox.css("margin-top").replace("px", ""));

    $("line#overviewToSearch").attr("x1", overviewBox.sPosition.left1).attr("y1", overviewBox.sPosition.bottom).attr("x2", overviewBox.sPosition.left1).attr("y2", searchBox.sPosition.top);
    $("line#overviewToContribute").attr("x1", overviewBox.sPosition.left2).attr("y1", overviewBox.sPosition.bottom).attr("x2", overviewBox.sPosition.left2).attr("y2", contributeBox.sPosition.top);
    $("line#searchToLibraries").attr("x1", searchBox.sPosition.left1).attr("y1", searchBox.sPosition.bottom).attr("x2", searchBox.sPosition.left1).attr("y2", librariesBox.sPosition.top);
    $("line#searchToResource").attr("x1", searchBox.sPosition.left2).attr("y1", searchBox.sPosition.bottom).attr("x2", searchBox.sPosition.left2).attr("y2", resourceBox.sPosition.top);
    $("line#contributeToResource").attr("x1", contributeBox.sPosition.left1).attr("y1", contributeBox.sPosition.bottom).attr("x2", contributeBox.sPosition.left1).attr("y2", resourceBox.sPosition.top);
    $("line#resourceToLibraries").attr("x1", resourceBox.sPosition.left1).attr("y1", resourceBox.sPosition.bottom).attr("x2", resourceBox.sPosition.left1).attr("y2", librariesBox.sPosition.top);
    $("line#librariesToShare").attr("x1", librariesBox.sPosition.left1).attr("y1", librariesBox.sPosition.bottom).attr("x2", librariesBox.sPosition.left1).attr("y2", shareBox.sPosition.top);
    $("line#resourceToShare").attr("x1", resourceBox.sPosition.left2).attr("y1", resourceBox.sPosition.bottom).attr("x2", resourceBox.sPosition.left2).attr("y2", shareBox.sPosition.top);
  }
</script>

<style type="text/css">

  /* Big stuff */
  * { box-sizing: border-box; -moz-box-sizing: border-box; font-size: 16px; }
  #content { min-width: 300px; transition: padding 1s; -webkit-transition: padding 1s; }
  #presentation { position: relative; max-width: 1200px; margin: 0 auto; }
  #steps { position: relative; z-index: 10; }
  .step { margin-bottom: 75px; padding: 0 10px; }
  .group { padding: 0px 10px 10px 30px; border-radius: 5px; background-color: #EEE; margin: 5px 0; position: relative; margin-left: 25px; }
  .group .icon { position: absolute; top: 0; left: -25px; background-color: #CCC; border-radius: 50%; width: 50px; }
  .group .data { overflow: auto; }
  h2 { font-size: 24px; }
  h3 { font-style: italic; color: #333; }
  .youtubeBox img { width: 100%; }
  .youtubeBox { position: relative; max-width: 550px; margin: 5px 0 5px 5px; }
  #searchBox .youtubeBox, #contributeBox .youtubeBox { margin: 5px 0 0 0; }
  .youtube { width: 100%; height: 100%; position: absolute; top: 0; left: 0; }
  .youtubeLink { display: none; font-weight: bold; text-align: right; padding: 2px; }
  .downlinks { margin-top: 5px; font-size: 0; }
  .downlinks a { display: inline-block; background-color: #3572B8; color: #FFF; width: 33%; margin-right: 0.5%; text-align: center; padding: 2px 1px; height: 2.6em; vertical-align: top; }
  .downlinks a:hover, .downlinks a:focus { background-color: #FF6A00 ; }
  .downlinks a:first-child { border-radius: 5px 0 0 5px; }
  .downlinks a:last-child { margin-right: 0; border-radius: 0 5px 5px 0; }
  .pdfLink { display: block; font-weight: bold; text-align: right; padding: 2px; }

  /* Individualism */
  #step1 { font-size: 0; }
  #searchBox, #contributeBox { width: calc(49% - 25px); display: inline-block; vertical-align: top; height: 100%; }
  #searchBox { margin-right: 1%; }
  #contributeBox { margin-left: calc(1% + 25px); }
  #resourceBox { margin-left: 20%; }
  #librariesBox { margin-right: 20%; }
  .data .youtubeBox { float: right; }

  /* SVG */
  #arrows { width: 100%; height: 100%; position: absolute; }
  #arrows line { stroke: #999; stroke-width: 1%; marker-end: url(#triangle); }
  #arrows marker { fill: #999; }

  /* Responsive */
  @media screen and (min-width: 980px) {
    #content { padding-left: 50px; }
  }
  @media screen and (max-width: 800px) {
    .data span { display: block; }
    .data .youtubeBox { float: none; margin: 0 auto; display: block; }
  }
  @media screen and (max-width: 650px) {
    .data .youtubeBox, .youtubeBox { display: none; }
    .youtubeLink { display: block; }
    .downlinks a { display: block; width: 100%; margin-bottom: 1px; height: auto; padding: 5px 2px; }
    .downlinks a:first-child { border-radius: 5px 5px 0 0; }
    .downlinks a:last-child { margin-right: 0; border-radius: 0 0 5px 5px; }
  }
  @media screen and (max-width: 500px) {
    .group { padding: 0 5px 5px 15px; margin-left: 12px; }
    .group .icon { left: -12px; width: 25px; }
    #searchBox, #contributeBox { display: block; }
    #searchBox { width: auto; margin-right: 15%; }
    #contributeBox { width: auto; margin-left: calc(20% + 12px); }
    #arrows line { stroke-width: 1%; }
    #resourceBox { margin-left: 15%; }
    #librariesBox { margin-right: 15%; }
  }

</style>

<div id="content">

  <h1 class="isleH1">Illinois Open Education Resources User Guide</h1>

  <div id="presentation">

    <svg id="arrows">
      <marker id="triangle" viewBox="0 0 8 10" refX="7" refY="5" markerUnits="strokeWidth" markerWidth="3" markerHeight="3" orient="auto">
			  <path d="M 0 0 L 10 5 L 0 10 z" />
			</marker>
      <line id="overviewToSearch" />
      <line id="overviewToContribute" />
      <line id="searchToLibraries" />
      <line id="searchToResource" />
      <line id="contributeToResource" />
      <line id="resourceToLibraries" />
      <line id="librariesToShare" />
      <line id="resourceToShare" />
    </svg>

    <div id="steps">
      <div class="step" id="step0">
        <div class="group" id="overviewBox">
          <img src="/images/icons/icon_help_med.png" class="icon" />
          <h2>Overview</h2>
          <h3>"What is this site all about?"</h3>
          <div class="data">
            <div class="youtubeBox">
              <img src="/images/youtube-autoresizer.png" />
              <iframe class="youtube" src="" frameborder="0" allowfullscreen></iframe>
            </div>
            <span>Hosting more than 200,000 open and available learning resources, IOER provides specific, standards-aligned resources utilizing filters and engaging tools to refine and share quality, peer-reviewed educational collections and resources. </span>
            <a class="pdfLink" href="/OERThumbs/files/QuickStart.pdf" target="_blank">View PDF</a>
            <a class="youtubeLink" href="#" target="_blank">Watch Video &rarr;</a>
          </div>
        </div>
      </div>

      <div class="step" id="step1">
        <div class="group" id="searchBox">
          <img src="/images/icons/icon_search_med.png" class="icon" />
          <h2>Search</h2>
          <h3>"I want to find Resources"</h3>
          <div class="data">
            <span>Providing a wide variety of Filters to refine your search, IOER have developed robust criteria for your search, such as Standards, Grade Level, Subjects and Career Clusters.  Finding quality learning materials is easier than ever with tools to sort and organize by Newest, Most Liked, Most Commented On, and a wide variety of Views and Libraries.</span>
            <a class="pdfLink" href="/OERThumbs/files/Search.pdf" target="_blank">View PDF</a>
          </div>
          <div class="youtubeBox">
            <img src="/images/youtube-autoresizer.png" />
            <iframe class="youtube" src="" frameborder="0" allowfullscreen></iframe>
          </div>
          <a class="youtubeLink" href="#" target="_blank">Watch Video &rarr;</a>
          <div class="downlinks">
            <a href="/Libraries/Default.aspx" target="_blank">Libraries Search</a>
            <a href="/Search.aspx" target="_blank">Resources Search</a>
            <a href="/Publishers.aspx" target="_blank">Publishers Search</a>
          </div>
        </div>

        <div class="group" id="contributeBox">
          <img src="/images/icons/icon_tag_med.png" class="icon" />
          <h2>Contribute</h2>
          <h3>"I want to submit Resources"</h3>
          <div class="data">
            <span>Many options for Contributing in IOER allow you to quickly tag a resource using standards alignment and keywords, create a new resource from your computer directly to the Internet, as well as more detailed tagging and creation tools.  Fast or methodical, IOER has learning resources for everyone.</span>
            <a class="pdfLink" href="/OERThumbs/files/Contribute.pdf" target="_blank">View PDF</a>
          </div>
          <div class="youtubeBox">
            <img src="/images/youtube-autoresizer.png" />
            <iframe class="youtube" src="" frameborder="0" allowfullscreen></iframe>
          </div>
          <a class="youtubeLink" href="#" target="_blank">Watch Video &rarr;</a>
          <div class="downlinks">
            <a href="/Publish.aspx" target="_blank">Tagging Tool</a>
            <a href="/My/Author.aspx" target="_blank">Authoring Tool</a>
            <a href="/Contribute" target="_blank">Quick Contribute</a>
          </div>
        </div>
      </div>

      <div class="step" id="step2">
        <div class="group" id="resourceBox">
          <img src="/images/icons/icon_resources_med.png" class="icon" />
          <h2>Resources</h2>
          <h3>"I want to learn about a Resource"</h3>
          <div class="data">
            <div class="youtubeBox">
              <img src="/images/youtube-autoresizer.png" />
              <iframe class="youtube" src="" frameborder="0" allowfullscreen></iframe>
            </div>
            <span>Each resource has its own Detail Page, providing in-depth information about each resource found in IOER.  In addition to highly detailed standards-alignment tabs, Commenting, Likes and Sharing options are available with just a click for each resource in the Learning Registry, through IOER.</span>
            <a class="pdfLink" href="/OERThumbs/files/Detail.pdf" target="_blank">View PDF</a>
          </div>
          <a class="youtubeLink" href="#" target="_blank">Watch Video &rarr;</a>
        </div>
      </div>

      <div class="step" id="step3">
        <div class="group" id="librariesBox">
          <img src="/images/icons/icon_library_med.png" class="icon" />
          <h2>Libraries</h2>
          <h3>"I want to catalog and organize Resources"</h3>
          <div class="data">
            <div class="youtubeBox">
              <img src="/images/youtube-autoresizer.png" />
              <iframe class="youtube" src="" frameborder="0" allowfullscreen></iframe>
            </div>
            <span>IOER Libraries provide many ways for you to tag, contribute, create, organize and share your learning resources with fast and easy-to-use tools that allow for public and private settings.  User and Organizational Libraries allow individuals and groups to quickly categorize their learning resources in so many ways.</span>
            <a class="pdfLink" href="/OERThumbs/files/Libraries.pdf" target="_blank">View PDF</a>
          </div>
          <a class="youtubeLink" href="#" target="_blank">Watch Video &rarr;</a>
        </div>
      </div>

      <div class="step" id="step4">
        <div class="group" id="shareBox">
          <img src="/images/icons/icon_swirl_med.png" class="icon" />
          <h2>Sharing</h2>
          <h3>"I want to share Resources with my colleagues"</h3>
          <div class="data">
            <!--<div class="youtubeBox">
              <img src="/images/youtube-autoresizer.png" />
              <iframe class="youtube" src="" frameborder="0" allowfullscreen></iframe>
            </div>-->
            <span>Community-building is what IOER is all about!  As you begin building your selected library of chosen collections of learning resources, you will find a continued focus on adding responsive design tools to assist you in the development of your learning environment.</span>
            <!--<a class="pdfLink" href="/OERThumbs/files/Contribute.pdf" target="_blank">View PDF</a>-->
          </div>
          <!--<a class="youtubeLink" href="#" target="_blank">Watch Video &rarr;</a>-->
        </div>
      </div>
    </div>
  </div>

</div>
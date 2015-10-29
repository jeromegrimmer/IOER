﻿<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="TrainingProviders.ascx.cs" Inherits="IOER.Pages.Developers.TrainingProviders" %>

<p>The Illinois workNet training providers API enables searching for training providers across the state of Illinois. The source includes WIA (Workforce Investment Act) providers from the Illlinois Workforce Development System (IWDS) and Illinois Department of Employments Services (IDES), through their Career Information Systems (CIS) partnership.</p>
<p>Searches may be conducted by city name or by using a zipcode with a search radius (in miles).</p>
<p>This API's documentation is generated by the system and can be viewed here:</p>
<p><a href="http://apps.il-work-net.com/providersApi/Help" target="_blank">http://apps.il-work-net.com/providersApi/Help</a></p>

<p><b>Conventions in this Document</b></p>
<p>Text in <b>bold</b> is required.  Text in italics should be substituted with the value of a parameter.</p>
<p>All URIs are relative to <a href="https://apps.il-work-net.com/providersApi" target="_blank">https://apps.il-work-net.com/providersApi</a></p>

<h2>Illinois workNet API/Provider API</h2>

<div class="api">
  <div class="title">Get Providers</div>
  <div class="description">​Returns a list of training providers based on the parameter values.<br /><a href="http://apps.il-work-net.com/providersApi/Help/Api/GET-api-Provider-Get_location_keywords_startingPageNbr_pageSize_miles_offerings_programTypes" target="_blank">See API details</a>
  </div>
  <div class="link">
    <div class="method">GET</div><div class="uri">​/api/Provider/Get</div>
  </div>
</div>

<div class="api">
  <div class="title">Get WIOA Program</div>
  <div class="description">​Returns details for a WIA training provider's program - formatted as Html - ready for display.<br /><a href="http://apps.il-work-net.com/providersApi/Help/Api/GET-api-Provider-Wia_id" target="_blank">See API details</a>
  </div>
  <div class="link">
    <div class="method">GET</div><div class="uri">​​/api/Provider/Wia</div>
  </div>
</div>

<div class="api">
  <div class="title">Get CIS Program</div>
  <div class="description">​Coming soon. ​Returns details for a CIS training provider's program - formatted as Html - ready for display.<br /><a href="http://apps.il-work-net.com/providersApi/Help/Api/GET-api-Provider-CIS_id" target="_blank">See API details</a>
  </div>
  <div class="link">
    <div class="method">GET</div><div class="uri">​​/api/Provider/CIS</div>
  </div>
</div>

<div class="api">
  <div class="title">Get Program Types</div>
  <div class="description">​TBD - can only use if relavent for both searches. Returns list of WIA Program Types.<br /><a href="http://apps.il-work-net.com/providersApi/Help/Api/GET-api-Codes-ProgramTypes" target="_blank">See API details</a>
  </div>
  <div class="link">
    <div class="method">GET</div><div class="uri">​/api/Codes/ProgramTypes</div>
  </div>
</div>

<div class="api">
  <div class="title">Get WIOA Offerings</div>
  <div class="description">​​TBD - can only use if relavent for both searches. Returns list of WIA Offering Types<br /><a href="http://apps.il-work-net.com/providersApi/Help/Api/GET-api-Codes-Offerings" target="_blank">See API details</a>
  </div>
  <div class="link">
    <div class="method">GET</div><div class="uri">​​/api/Codes/Offerings</div>
  </div>
</div>

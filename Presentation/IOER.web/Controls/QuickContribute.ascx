﻿<%@ Control Language="C#" AutoEventWireup="true" CodeBehind="QuickContribute.ascx.cs" Inherits="ILPathways.Controls.QuickContribute" %>
<%@ Register TagPrefix="uc1" TagName="CBXL" Src="/LRW/Controls/ListPanel.ascx" %>
<%@ Register TagPrefix="uc1" TagName="Rights" Src="/LRW/Controls/ConditionsOfUseSelector.ascx" %>

<div id="contributer" runat="server">
  <script type="text/javascript">
    <%=libraryData %>
    <%=maxFileSize %>
    <%=selectedLibraryOutput %>
    <%=selectedCollectionOutput %>
  </script>
  <!--[if IE]>
    <div id="iAmIE"></div>
  <![endif]-->
  <script type="text/javascript">
    //Variables
    var urlCheckTimer;
    var urlValue = "";
    var titleCheckTimer;
    var titleValue = "";
    var mode = "";
    var keywords = [];

    //Page setup
    $(document).ready(function () {
      if ($("#iAmIE").length > 0) {
        $(".txtURL").val("http://").on("click", function () { $(this)[0].select(); });
      }
      fixLabels();
      $("#step1 input[type=radio]").on("change", function () {
        updateDisabledStuff();
      });
      addNA("careerCluster");
      updateDisabledStuff();
      setupLibColDDLs();
      initValidations();
      updateValidations();
      loadKeywords();
      validateCBXL($(".tags#subject"), validations.subject);
      validateCBXL($(".tags#gradeLevel"), validations.gradeLevel);
      validateCBXL($(".tags#careerCluster"), validations.careerCluster);
      $("#txtKeywords").on("focus", function () {
        //$(".btnSubmit").attr("disabled", "disabled");
        $("form").attr("onsubmit", "return false;");
      });
    });

    function fixLabels() {
      var page = $(".rblTagWebpage");
      var up = $(".rblUploadFile");
      var debug = $(".debug input");
      page.parent().attr("for", page.attr("id")).css("cursor", "pointer");
      up.parent().attr("for", up.attr("id")).css("cursor", "pointer");
      if (debug.length > 0) {
        debug.parent().attr("for", debug.attr("id")).css("cursor", "pointer");
      }
    }

    function setupLibColDDLs() {
      var box = $("#ddlLibrary");
      //Reset the list
      box.html("");
      addOption(box, 0, "Select a Library...");
      //Load data dynamically
      for (i in libraryData) {
        var current = libraryData[i];
        addOption(box, current.id, current.title);
      }
      box.on("change", function () {
        reloadCollections();
      }).trigger("change");
      if (selectedLibraryID > 0) {
        box.find("option[value=" + selectedLibraryID + "]").attr("selected", "selected");
        box.trigger("change");
        if (selectedCollectionID > 0) {
          $("#ddlCollection option[value=" + selectedCollectionID + "]").attr("selected", "selected");
          $("#ddlCollection").trigger("change");
        }
      }
    }

    function loadKeywords() {
      var raw = $(".hdnKeywords").val().split("[separator]");
      if (raw.length > 1 || raw[0].trim().length > 0) {
        for (i in raw) {
          if (raw[i].trim() == "") { continue; }
          keywords.push(raw[i].trim());
        }
        renderKeywords();
      }
    }

    function addNA(target) {
      $("ul[tablename=" + target + "]").append(
        $("<li></li>")
        .append(
          $("<span></span>")
            .append(
              $("<label></label>")
                .attr("for", target + "_NA")
                .html("Not Applicable")
            )
            .append(
                $("<input></input>")
                  .attr("type", "checkbox")
                  .attr("value", "0")
                  .attr("id", target + "_NA")
              )
        )
      );
    }

    //Page functions
    function updateDisabledStuff() {
      var tagBox = $("#step1 input[value=tag]");
      var uploadBox = $("#step1 input[value=upload]");
      var urlBox = $(".txtURL");
      var fileBox = $(".fileFile");
      if (tagBox.prop("checked")) {
        mode = "tag";
        fileBox.attr("disabled", "disabled").val("");
        urlBox.removeAttr("disabled").val((urlBox.val().trim() == "" ? "" : urlBox.val().trim()));
        validations.file.valid = true;
        validations.url.valid = false;
        $("#validation_fileFile").attr("class", "vm green");
        $("#validation_txtURL").attr("class", "vm");
      }
      else if (uploadBox.prop("checked")) {
        mode = "upload";
        urlBox.attr("disabled", "disabled").val("");
        fileBox.removeAttr("disabled").val("");
        validations.url.valid = true;
        validations.file.valid = false;
        $("#validation_txtURL").attr("class", "vm green");
        $("#validation_fileFile").attr("class", "vm");
      }
      updateValidations();
      $("#validation_txtURL, #validation_fileFile").html("");
      validateStep1();
    }

    function reloadCollections() {
      var libraryID = parseInt($("#ddlLibrary option:selected").attr("value"));
      var box = $("#ddlCollection");
      $("#step3").attr("class", "step");
      if (libraryID == 0) {
        box.attr("disabled", "disabled");
        box.html("");
        addOption(box, 0, "Select a Library first.");
      }
      else {
        box.attr("disabled", false);
        box.html("");
        addOption(box, 0, "Select a Collection...")
        for (i in libraryData) {
          if (libraryData[i].id == libraryID) {
            for (j in libraryData[i].collections) {
              var current = libraryData[i].collections[j];
              addOption(box, current.id, current.title);
              if (current.isDefaultCollection) {
                box.find("option").last().attr("selected", "selected");
              }
            }
          }
        }
        //Box color changing
        box.on("change", function () {
          if ($(this).find("option:selected").attr("value") == "0") {
            $("#step3").attr("class", "step");
          }
          else {
            $("#step3").attr("class", "step okay");
          }
        }).trigger("change");
      }
    }

    function addOption(box, value, html) {
      box.append(
        $("<option></option>")
          .attr("value", value)
          .html(html)
      );
    }

    function checkExistingKeyword(text) {
      $("#keywordList .keyword .text").each(function () {
        if ($(this).html().toLowerCase() == text) {
          return true;
        }
        else {
          return false;
        }
      });
    }
    function renderKeywords() {
      var box = $("#keywordList");
      var hidden = $(".hdnKeywords");
      hidden.val("");
      box.html("");
      var template = $("#template_keyword").html();
      for (i in keywords) {
        var current = keywords[i];
        box.append(
          template
            .replace(/{text}/g, current)
            .replace(/{id}/g, i)
        );
        hidden.val(hidden.val().trim() + "[separator]" + current);
      }
      hidden.val(hidden.val().trim().replace("[separator]", ""));
      if (keywords.length > 0) {
        validations.keywords.valid = true;
      }
      else {
        $("#validation_txtKeywords").attr("class", "vm red").html("You must enter at least one keyword.");
      }
    }
    function removeKeyword(id) {
      var temp = [];
      for (i in keywords) {
        if (id != i) {
          temp.push(keywords[i]);
        }
      }
      keywords = temp;
      renderKeywords();
    }

    //AJAX Methods
    function DoAjax(method, data, success, passThruJSON) {
      $.ajax({
        url: "/Services/UtilityService.asmx/" + method,
        async: true,
        success: function (msg) {
          try {
            success($.parseJSON(msg.d), passThruJSON);
          }
          catch (e) {
            success(msg.d, passThruJSON);
          }
        },
        type: "POST",
        data: JSON.stringify(data),
        dataType: "json",
        contentType: "application/json; charset=utf-8"
      });
    }

    function successValidateTextBox(result, data) {
      if (result.isValid) {
        data.valid = true;
        $("#validation_" + data.name).attr("class", "vm green").html(data.data.fieldTitle + " is okay.");
      }
      else {
        data.valid = false;
        $("#validation_" + data.name).attr("class", "vm red").html(result.status);
      }
      updateValidations();
    }
    function successValidateKeyword(result, data) {
      var box = $("." + data.name);
      box.removeAttr("readonly");
      if (result.isValid) {
        $("#validation_" + data.name).attr("class", "vm green").html("");
        keywords.push(result.data);
        box.val("");
        renderKeywords();
      }
      else {
        $("#validation_" + data.name).attr("class", "vm red").html(result.status);
      }
      updateValidations();
    }
    function successValidateRights(result, data) {
      if (result.isValid) {
        data.valid = true;
        $("#validation_" + data.name).attr("class", "vm green").html("Usage Rights URL is okay.");
      }
      else {
        data.valid = false;
        $("#validation_" + data.name).attr("class", "vm red").html(result.status);
      }
      updateValidations();
    }
  </script>
  <script type="text/javascript">
    /* Validation */
    var validations = {
      url: { name: "txtURL", minLength: 12, valid: false, timer: null, method: "ValidateURL", data: { text: "", fieldTitle: "URL", mustBeNew: true }, success: successValidateTextBox, oldVal: "" },
      file: { name: "fileFile", valid: false },
      title: { name: "txtTitle", minLength: 10, valid: false, timer: null, method: "ValidateText", data: { text: "", minimumLength: 10, fieldTitle: "Title" }, success: successValidateTextBox, oldVal: "" },
      description: { name: "txtDescription", minLength: 25, valid: false, timer: null, method: "ValidateText", data: { text: "", minimumLength: 25, fieldTitle: "Description" }, success: successValidateTextBox, oldVal: "" },
      keywords: { name: "txtKeywords", minLength: 4, valid: false, method: "ValidateText", data: { text: "", minimumLength: 4, fieldTitle: "Keyword" }, success: successValidateKeyword },
      rights: { name: "txtConditionsOfUse", minLength: 12, valid: false, method: "ValidateURL", data: { text: "", fieldTitle: "Usage Rights URL", mustBeNew: false }, success: successValidateRights, oldVal: "" },
      subject: { name: "subject", valid: false },
      gradeLevel: { name: "gradeLevel", valid: false },
      careerCluster: { name: "careerCluster", valid: false }
    }

    /* Setup */
    function initValidations() {
      //Initial function assignments
      $("input[type=text]").on("keydown", function (event) {
        if (event.keyCode == 13 || event.which == 13) {
          event.preventDefault();
        }
      });
      $(".txtURL").on("keyup change", function () { validateStep1(); });
      $(".fileFile").on("change", function () { validateStep1(); });
      $(".txtTitle").on("keyup change", function () { validateTextBox(validations.title) });
      $(".txtDescription").on("keyup change", function () { validateTextBox(validations.description) });
      $(".txtKeywords").on("keyup", function (event) { validateKeyword(validations.keywords, event) });
      $(".ddlConditionsOfUse, .txtConditionsOfUse").on("keyup change", function () { validateRights(); }).trigger("change");
      $("ul[tablename=subject] input").on("change", function () { validateCBXL($(".tags#subject"), validations.subject); });
      $("ul[tablename=gradeLevel] input").on("change", function () { validateCBXL($(".tags#gradeLevel"), validations.gradeLevel); });
      $("ul[tablename=careerCluster] input").on("change", function () { validateCBXL($(".tags#careerCluster"), validations.careerCluster); });

      //Handle postback re-validation
      if ($(".txtURL").val() != "" && mode == "tag") { validateStep1(); }
      if ($(".txtTitle").val() != "") { validateTextBox(validations.title); }
      if ($(".txtDescription").val() != "") { validateTextBox(validations.description); }
      if ($("ul[tablename=subject] input:checked").length > 0) { validateCBXL($(".tags#subject"), validations.subject); }
      if ($("ul[tablename=gradeLevel] input:checked").length > 0) { validateCBXL($(".tags#gradeLevel"), validations.gradeLevel); }
      if ($("ul[tablename=careerCluster] input:checked").length > 0) { validateCBXL($(".tags#careerCluster"), validations.careerCluster); }
    }

    function validateTextBox(data) {
      var value = $("." + data.name).val().trim();
      var message = $("#validation_" + data.name);
      //If we haven't met the length threshhold...
      if (value.length < data.minLength) {
        data.valid = false;
        message.attr("class", "vm").html("Please enter at least " + (data.minLength - value.length) + " more characters.");
      }
        //Otherwise, do AJAX on timeout
      else {
        if (data.oldVal == value) { }
        else {
          message.attr("class", "vm").html("Checking " + data.data.fieldTitle + "...");
          data.oldVal = value;
          clearTimeout(data.timer);
          data.timer = setTimeout(function () {
            data.data.text = value;
            DoAjax(data.method, data.data, data.success, data);
          }, 800);
        }
      }
      updateValidations();
    }

    function validateKeyword(data, event) {
      //$(".btnSubmit").attr("disabled", "disabled");
      $("form").attr("onsubmit", "return false;");
      var box = $("." + data.name);
      var value = box.val().trim();
      var message = $("#validation_" + data.name);
      if (value.length == 0) {
        message.attr("class", "vm green").html("");
      }
      else if (value.length < data.minLength) {
        message.attr("class", "vm").html("Please enter at least " + (data.minLength - value.length) + " more characters.");
      }
      else if (checkExistingKeyword(value)) {
        message.attr("class", "vm red").html("That keyword already exists.");
      }
      else {
        message.attr("class", "vm").html("Press Enter to add this Keyword.");
      }
      if ((event.keyCode == 13 || event.which == 13) && value.length >= data.minLength) {
        message.attr("class", "vm").html("Checking " + data.data.fieldTitle + "...");
        data.data.text = value;
        DoAjax(data.method, data.data, data.success, data);
        box.attr("readonly", "readonly");
      }
    }

    function validateRights() {
      if ($(".ddlConditionsOfUse option:selected").attr("value") == "4") {
        //Doubling up to fix an odd timing issue
        validateTextBox(validations.rights);
        setTimeout(function () {
          validateTextBox(validations.rights);
          updateValidations();
        }, 1500);
      }
      else {
        $("#validation_txtConditionsOfUse").attr("class", "vm green").html("");
        validations.rights.valid = true;
      }
      updateValidations();
    }

    function validateCBXL(box, data) {
      var message = $("#validation_" + data.name);
      if (box.find("input:checked").length == 0) {
        data.valid = false;
        message.attr("class", "vm cbxl red").html("Please select at least one item.");
      }
      else {
        data.valid = true;
        message.attr("class", "vm cbxl green").html(" ");
      }
      updateValidations();
    }

    function validateStep1() {
      if (mode == "tag") {
        $("#validation_fileFile").html("");
        if (validations.url.oldVal == $(".txtURL").val()) { return; }
        validations.file.valid = true;
        validations.url.valid = false;
        validateTextBox(validations.url);
      }
      else if (mode == "upload") {
        $("#validation_txtURL").html("");
        if (validations.file.oldVal == $(".fileFile").val()) { return; }
        validations.url.valid = true;
        validations.file.valid = false;
        //Do file validation
        var fileBox = $(".fileFile");
        var message = $("#validation_fileFile");
        if (fileBox.val() == "") {
          validations.file.valid = false;
          message.attr("class", "vm").html($("#template_uploadMessage").html());
        }
        else {
          if (window.FileReader) {
            var size = fileBox[0].files[0].size;
            if (size >= maxFileSize) {
              validations.file.valid = false;
              message.attr("class", "vm red").html("That file is too large! The file must be under 20 megabytes.");
            }
            else {
              validations.file.valid = true;
              message.attr("class", "vm green").html("Your file will be uploaded when you click Finish.");
            }
          }
          else {
            validations.file.valid = true;
            message.attr("class", "vm green").html("Remember: Your file must be under 20 megabytes.");
          }
        }
      }
      updateValidations();
    }

    function updateValidations() {
      $("#step1, #step2").each(function () {
        var box = $(this);
        if (box.find(".vm.red").length > 0) {
          box.attr("class", "step error");
        }
        else if (box.find(".vm.green").length == box.find(".vm").length) {
          box.attr("class", "step okay");
        }
        else {
          box.attr("class", "step");
        }
      });
      for (i in validations) {
        if (validations[i].valid == false) {
          //$(".btnSubmit").attr("disabled", "disabled");
          $(".step:last-child").attr("class", "step error");
          $("#preButtonMessage").show();
          return false;
        }
      }
      $(".step:last-child").attr("class", "step okay");
      //$(".btnSubmit").removeAttr("disabled");
      $("#preButtonMessage").hide();
      if (!$("#txtKeywords").is(":focus")) {
        return true;
      }
      else {
        return false;
      }
    }

    function validatePage() {
      if (updateValidations()) {
        $("form").removeAttr("onsubmit");
        $(".btnSubmit").hide();
        $("#processing").show();
      }
    }
  </script>
  <style type="text/css">
    /* Big Stuff */
    * { box-sizing: border-box; -moz-box-sizing: border-box; }
    #content { transition: padding 1s; -webkit-transition: padding 1s; min-width: 300px; }

    /* Steps */
    .step { padding: 10px; background-color: #EEE; border-radius: 5px; margin: 0 auto 20px auto; font-size: 0; max-width: 1600px; position: relative; border: 1px solid rgba(238,238,238,0.4); transition: border 1s; -webkit-transition: border 1s; }
    .step * { font-size: 14px; }
    .step.okay { border: 1px solid rgba(74,163,148,0.4); }
    .step.error { border: 1px solid rgba(176,61,37,0.4); }
    .step h2 { font-size: 26px; margin-bottom: 5px; }
    .step label, p.label { font-weight: bold; width: 125px; display: inline-block; vertical-align: top; text-align: right; padding-right: 10px; }
    .step input[type=text], input[type=file], .step textarea, .step #tagLists, .step .conditionsSelector, .step select, .step p.data { width: calc(100% - 130px); display: inline-block; vertical-align: top; resize: none; }
    .step input[type=submit] { width: 100%; font-weight: bold; font-size: 20px; background-color: #4AA394; color: #FFF; transition: height 0.5s, margin 0.5s, padding 0.5s, opacity 0.5s; height: auto; margin: inherit; padding: 2px; opacity: 1; }
    .step input[type=submit]:hover, .step input[type=submit]:focus { background-color: #FF5707; cursor: pointer; }
    .step input[type=text].txtConditionsOfUse { width: 100%; }
    .step textarea { height: 5em; }
    .step #tagLists { text-align: left; }
    .step p { padding-left: 15px; }
    .step p.label, .step p.data { margin-left: 0; margin-right: 0; }
    .step p.vm { opacity: 1; overflow: hidden; padding-left: 125px; font-style: italic; line-height: 1.3em; min-height: 1.3em; max-height: 15em; transition: opacity 1s, max-height 1.5s, min-height 0.5s; -webkit-transition: opacity 1s, max-height 1.5s, min-height 0.5s; color: #555; }
    .step p.vm.green { color: #4AA394; }
    .step p.vm.red { color: #B03D25; }
    .step p.vm.cbxl { padding: 0; text-align: center; }
    .step p.vm:empty { min-height: 0.2em; max-height: 0.2em; opacity: 0; }
    .step p.tip { font-style: italic; }
    .step p.tip.last { margin-bottom: 15px; }
    .step ul { list-style-type: none; }
    .step ul li span { position: relative; display: block; }
    .step ul li input { position: absolute; top: 4px; left: 2px; cursor: pointer; }
    .step ul li label { text-align: left; padding-left: 5px; font-weight: normal; padding: 2px 5px 2px 20px; cursor: pointer; width: 100%; border-radius: 5px; }
    .step ul li label:hover, .step ul li label:focus { background-color: #DDD; }
    .step .conditionsSelector tbody, .step .conditionsSelector select { width: 100%; }
    .step .conditionsSelector .conditions_thumbnail { padding-right: 5px; }
    .step .conditionsSelector tr:first-child td:nth-child(2) { width: 99%; }
    .step #tagLists p.vm { padding: 0; }
    .step .tags { width: 32%; display: inline-block; vertical-align: top; }
    #step1 label { position: relative; }
    #step1 label input { position: absolute; top: 2px; left: 2px; cursor: pointer; }
    #step1 .txtURL { margin-bottom: 0; }
    #step1 input { transition: opacity 0.5s; -webkit-transition: opacity 0.5s; }
    #step1 input[disabled=disabled] { opacity: 0.5; }
    #step3 select { margin-bottom: 10px; }
    #processing { display: none; font-size: 20px; font-weight: bold; text-align: center; padding: 10px; }
    .step input.btnSubmit[disabled=disabled] { height: 0; margin: 0; padding: 0; opacity: 0; cursor: initial; }
    #preButtonMessage { text-align: center; font-weight: bold; font-size: 20px; }

    /* Keywords */
    #keywordList { padding-left: 125px; margin-bottom: 10px; transition: margin 0.5s, height 0.5s; -webkit-transition: margin 0.5s, height 0.5s; height: auto; }
    #keywordList:empty { margin-bottom: 0; height: 0; }
    #keywordList .keyword { overflow: hidden; display: inline-block; vertical-align: top; border: 1px solid #CCC; border-radius: 5px; padding: 2px 25px 2px 2px; position: relative; margin: 1px; }
    #keywordList .keyword .removeKeywordLink { padding: 2px; width: 20px; height: 100%; display: block; position: absolute; top: 0; right: 0; background-color: #B03D25; color: #FFF; font-weight: bold; text-align: center; }
    #keywordList .keyword .removeKeywordLink:hover, #keywordList .keyword .removeKeywordLink:focus { background-color: #F00; }

    /* Special */
    #step1 label.debug { display: block; width: 125px; position: absolute; top: 2px; right: 5px; }
    #step1 #supportedFileTypes b { display: inline-block; vertical-align: top; width: 100px; text-align: right; padding-right: 5px; }
    .required { color: #F00; font-weight: bold; }

    @media screen and (max-width: 450px) {
      .step .tags { width: 100%; }
    }
    @media screen and (max-width: 600px) {
      .step label { width: 100%; display: block; text-align: left; }
      #step1 p { text-align: left; padding-left: 15px; }
      .step input[type=text], .step textarea, .step #tagLists, .step .conditionsSelector, .step select { width: 100%; display: block; }
      #step1 label { padding-left: 20px; margin-bottom: 10px; }
      #keywordList { padding-left: 0; }
    }
    @media screen and (min-width: 980px) {
      #content { padding-left: 50px; }
    }
    @media screen and (min-width: 1200px) {
      .subcolumn { display: inline-block; vertical-align: top; width: 50%; }
      .subcolumn:last-child { padding-left: 30px; }
      .step #tagLists { width: 100%; }
      .step .subcolumn:last-child label { text-align: left; }
    }

  </style>

  <div id="content">
    <h1 class="isleH1">Contribute a Resource to IOER!</h1>

    <div class="step" id="step1">
      <label id="lblDebugMode" class="debug" runat="server" for="cbxDebug" title="Admin-only option. Sets publisher and creator fields to 'delete' in order to hide them from the Search."><asp:CheckBox ID="cbxDebug" runat="server" /> Testing Mode</label>
      <h2>1. Choose the type of Resource to Contribute:</h2>
      <p class="tip last">If you need to tag a file that is already hosted online, enter its URL in the Webpage field. No need to reupload it!</p>
      <label for="rblTagWebpage"><input type="radio" id="rblTagWebpage" value="tag" name="contributeType" runat="server" class="rblTagWebpage" /> Tag a Webpage </label>
      <input type="text" id="txtURL" value="" placeholder="http://" runat="server" class="txtURL" />
      <p class="vm" id="validation_txtURL">testing...</p>
      <label for="rblUploadFile"><input type="radio" id="rblUploadFile" value="upload" name="contributeType" runat="server" class="rblUploadFile" /> Upload a File </label>
      <asp:FileUpload ID="fileFile" runat="server" CssClass="fileFile" />
      <p class="vm" id="validation_fileFile">testing...</p>
    </div>

    <div class="step" id="step2">
      <h2>2. Describe your Resource:</h2>
      <p class="tip">More complete information will make it easier for others to find your resource!</p>
      <p class="tip last required">All fields are required.</p>
      <div class="subcolumn">
        <label for="txtTitle">Title</label>
        <input type="text" id="txtTitle" runat="server" class="txtTitle" />
        <p class="vm" id="validation_txtTitle"></p>
        <label for="txtDescription">Description</label>
        <textarea id="txtDescription" runat="server" class="txtDescription"></textarea>
        <p class="vm" id="validation_txtDescription"></p>
        <label for="txtKeywords">Keywords</label>
        <input type="text" id="txtKeywords" class="txtKeywords" />
        <p class="vm" id="validation_txtKeywords"></p>
        <input type="hidden" id="hdnKeywords" name="hdnKeywords" runat="server" class="hdnKeywords" />
        <div id="keywordList"></div>
        <label>Usage Rights</label>
        <uc1:Rights runat="server" ID="RightsSelector" />
        <p class="vm" id="validation_txtConditionsOfUse"></p>
      </div>
      <div class="subcolumn">
        <label>Tags</label>
        <div id="tagLists">
          <div class="tags" id="subject">
            <uc1:CBXL ID="cbxlSubject" TargetTable="subject" runat="server" ListMode="checkbox" UseBlankDefault="true" TitleText="Subject" UpdateMode="append" AllowUncheck="true" />
            <p class="vm cbxl" id="validation_subject"></p>
          </div>
          <div class="tags" id="gradeLevel">
            <uc1:CBXL ID="cbxlGradeLevel" TargetTable="gradeLevel" runat="server" ListMode="checkbox" UseBlankDefault="true" TitleText="Grade Level" UpdateMode="append" AllowUncheck="true" />
            <p class="vm cbxl" id="validation_gradeLevel"></p>
          </div>
          <div class="tags" id="careerCluster">
            <uc1:CBXL ID="cbxlCareerCluster" TargetTable="careerCluster" runat="server" ListMode="checkbox" UseBlankDefault="true" TitleText="Career Cluster" UpdateMode="append" AllowUncheck="true" />
            <p class="vm cbxl" id="validation_careerCluster"></p>
          </div>
        </div>
      </div>
    </div>

    <div class="step" id="step3">
      <h2>3. Add this Resource directly to a Library:</h2>
      <p class="tip last">This step is optional. Here you can pick a Library and Collection to add this Resource to.</p>
      <label>Select Library</label>
      <select id="ddlLibrary" name="ddlLibrary"></select>
      <label>Select Collection</label>
      <select id="ddlCollection" name="ddlCollection"></select>
    </div>
      <asp:Panel ID="submitPanel" runat="server" DefaultButton="btnSubmit" ></asp:Panel>
    <div class="step" id="step4">
      <h2>4. Finish!</h2>
      <asp:Button ID="btnSubmit" runat="server" OnClick="btnSubmit_Click" OnClientClick="validatePage()" CssClass="btnSubmit" Text="I'm Finished. Submit my Resource!" />
      <p id="processing">Processing, Please wait...</p>
      <p id="preButtonMessage">One or more fields above is not yet complete!</p>
    </div>

  </div>
  <div id="templates" style="display:none;">
    <div id="template_keyword">
      <div class="keyword" data-index="{id}">
        <span class="text">{text}</span><a href="#" class="removeKeywordLink" onclick="removeKeyword({id}); return false;">X</a>
      </div>
    </div>
    <div id="template_uploadMessage">
      <div>Select a file to upload. If your file already exists online, please tag its URL instead.</div>
      <div>IOER supports files up to 20MB in size, but upload performance can be affected by your network connection. For this reason, we recommend uploading files 10MB or smaller.</div>
      <div>Supported file types include:</div>
      <div>
        <ul id="supportedFileTypes">
          <li><b>MS Office</b> (.doc/docx, .ppt/pptx, .xls/xlsx, etc.)</li>
          <li><b>Documents</b> (.pdf, .txt, .rtf, etc.)</li>
          <li><b>Images</b> (.jpg, .png, .gif, etc.)</li>
          <li><b>Audio</b> (.wav, .mp3, .ogg, etc.)</li>
          <li><b>Archives</b> (.zip, .rar, .7z, etc.)</li>
          <li><b>Smart Board</b> (.xbk, .notebook)</li>
        </ul>
      </div>
    </div>
  </div>
</div>
<div id="error" runat="server">
  <p style="padding: 50px; text-align: center;">Please login to access the Quick Contribute Tool!</p>
</div>
<asp:Literal ID="createdContentItemId" runat="server" visible="false">0</asp:Literal>
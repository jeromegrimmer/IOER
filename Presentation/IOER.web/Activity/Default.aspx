﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="ILPathways.Activity.Default" MasterPageFile="/Masters/Responsive.Master" %>
<%@ Register TagPrefix="uc1" TagName="ActivityList" Src="/Controls/Activity1.ascx" %>

<asp:Content ContentPlaceHolderID="BodyContent" runat="server">
  <uc1:ActivityList id="Activities" runat="server" />
</asp:Content>

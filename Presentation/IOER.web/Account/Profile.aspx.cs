﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using ILPathways.Utilities;

namespace ILPathways.Account
{
    public partial class Profile : System.Web.UI.Page
    {
        protected void Page_Load( object sender, EventArgs e )
        {
            //if not using admin/login2.aspx template, will need to do the following:
            //this should be handled by the secure template now, so hide, or make configurable
            string host = Request.ServerVariables[ "HTTP_HOST" ];
            if ( Request.IsSecureConnection == false )
            {
                if ( UtilityManager.GetAppKeyValue( "SSLEnable", "0" ) == "1" )
                {

                    host = host.Replace( ":80", "" );

                    //do redirect
                    Response.Redirect( "https://" + host + Request.Url.PathAndQuery );
                }
            }
            else
            {
                //is secure
                if ( UtilityManager.GetAppKeyValue( "SSLEnable", "0" ) == "0" )
                {
                    //should not be https
                    host = host.Replace( ":80", "" );
                    Response.Redirect( "http://" + host + Request.Url.PathAndQuery );
                }
            }

            if ( !this.IsPostBack )
            {
                this.InitializeForm();
            }
        }

        private void InitializeForm()
        {
            try
            {
                //we don't want addThis on this page, so show literal in master
                Literal showingAddThis = ( Literal ) FormHelper.FindChildControl( Page, "litHidingAddThis" );
                if ( showingAddThis != null )
                    showingAddThis.Visible = true;
            }
            catch
            {
            }
        }
    }
}
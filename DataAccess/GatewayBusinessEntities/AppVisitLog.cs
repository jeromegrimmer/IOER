//------------------------------------------------------------------------------
// <auto-generated>
//    This code was generated from a template.
//
//    Manual changes to this file may cause unexpected behavior in your application.
//    Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace GatewayBusinessEntities
{
    using System;
    using System.Collections.Generic;
    
    public partial class AppVisitLog
    {
        public int id { get; set; }
        public string SessionId { get; set; }
        public System.DateTime CreatedDate { get; set; }
        public string Application { get; set; }
        public string URL { get; set; }
        public string Parameters { get; set; }
        public Nullable<bool> IsPostback { get; set; }
        public string Userid { get; set; }
        public string Comment { get; set; }
        public string RemoteIP { get; set; }
        public string ServerName { get; set; }
        public string CurrentZip { get; set; }
    }
}

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
    
    public partial class OrganizationRequest
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public Nullable<int> OrgId { get; set; }
        public string OrganzationName { get; set; }
        public string Action { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public Nullable<int> LastUpdatedById { get; set; }
    }
}

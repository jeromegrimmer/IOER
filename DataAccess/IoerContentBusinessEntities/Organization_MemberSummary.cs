//------------------------------------------------------------------------------
// <auto-generated>
//    This code was generated from a template.
//
//    Manual changes to this file may cause unexpected behavior in your application.
//    Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace IoerContentBusinessEntities
{
    using System;
    using System.Collections.Generic;
    
    public partial class Organization_MemberSummary
    {
        public int OrgMbrId { get; set; }
        public int OrgId { get; set; }
        public string Organization { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public Nullable<bool> IsIsleMember { get; set; }
        public int UserId { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string FullName { get; set; }
        public string SortName { get; set; }
        public string Email { get; set; }
        public string ImageUrl { get; set; }
        public string UserProfileUrl { get; set; }
        public Nullable<int> OrgMemberTypeId { get; set; }
        public string OrgMemberType { get; set; }
        public Nullable<int> BaseOrgId { get; set; }
        public string BaseOrganization { get; set; }
        public System.DateTime Created { get; set; }
        public System.DateTime MemberAdded { get; set; }
        public Nullable<int> CreatedById { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public Nullable<int> LastUpdatedById { get; set; }
    }
}

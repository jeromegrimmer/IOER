//------------------------------------------------------------------------------
// <auto-generated>
//    This code was generated from a template.
//
//    Manual changes to this file may cause unexpected behavior in your application.
//    Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace IOERBusinessEntities
{
    using System;
    using System.Collections.Generic;
    
    public partial class Patron_Summary
    {
        public int Id { get; set; }
        public string UserName { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string FullName { get; set; }
        public string SortName { get; set; }
        public string Email { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public int HasProfile { get; set; }
        public string JobTitle { get; set; }
        public string RoleProfile { get; set; }
        public string ImageUrl { get; set; }
        public Nullable<int> OrganizationId { get; set; }
        public string Organization { get; set; }
        public Nullable<int> PublishingRoleId { get; set; }
        public string PublishingRole { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public System.Guid UserRowId { get; set; }
        public string UserProfileUrl { get; set; }
    }
}
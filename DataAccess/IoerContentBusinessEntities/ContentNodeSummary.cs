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
    
    public partial class ContentNodeSummary
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string ContentTitle { get; set; }
        public string Summary { get; set; }
        public Nullable<int> TypeId { get; set; }
        public string ContentType { get; set; }
        public Nullable<int> StatusId { get; set; }
        public string ContentStatus { get; set; }
        public Nullable<int> PrivilegeTypeId { get; set; }
        public int SortOrder { get; set; }
        public int ParentId { get; set; }
        public string ContentPrivilege { get; set; }
        public bool IsPublished { get; set; }
        public string UseRightsUrl { get; set; }
        public bool IsOrgContentOwner { get; set; }
        public System.Guid RowId { get; set; }
    }
}

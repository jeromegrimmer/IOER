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
    
    public partial class ContentConnector_ChildSummary
    {
        public int ContentConnectorId { get; set; }
        public int ConnectorParentId { get; set; }
        public int NbrParents { get; set; }
        public int ContentId { get; set; }
        public int ParentId { get; set; }
        public Nullable<int> TypeId { get; set; }
        public string ContentType { get; set; }
        public string Title { get; set; }
        public string Summary { get; set; }
        public string Description { get; set; }
        public Nullable<int> StatusId { get; set; }
        public string ContentStatus { get; set; }
        public Nullable<int> PrivilegeTypeId { get; set; }
        public int SortOrder { get; set; }
        public string ContentPrivilege { get; set; }
        public int ConditionsOfUseId { get; set; }
        public int ResourceVersionId { get; set; }
        public string ResourceUrl { get; set; }
        public Nullable<int> ResourceIntId { get; set; }
        public bool IsPublished { get; set; }
        public string UseRightsUrl { get; set; }
        public bool IsOrgContentOwner { get; set; }
        public bool IsActive { get; set; }
        public int OrgId { get; set; }
        public Nullable<System.Guid> DocumentRowId { get; set; }
        public string DocumentUrl { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<int> CreatedById { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public Nullable<int> LastUpdatedById { get; set; }
        public Nullable<int> ApprovedById { get; set; }
        public Nullable<System.DateTime> Approved { get; set; }
        public System.Guid ContentRowId { get; set; }
        public System.Guid RowId { get; set; }
        public string ParentHierarchyFull { get; set; }
        public string ParentHierarchy { get; set; }
    }
}
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
    
    public partial class Resource_ResourceType
    {
        public System.Guid RowId { get; set; }
        public Nullable<System.Guid> ResourceId { get; set; }
        public Nullable<int> ResourceTypeId { get; set; }
        public string OriginalType { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<int> CreatedById { get; set; }
        public Nullable<int> ResourceIntId { get; set; }
    }
}
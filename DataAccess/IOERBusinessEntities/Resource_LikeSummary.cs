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
    
    public partial class Resource_LikeSummary
    {
        public int Id { get; set; }
        public Nullable<int> ResourceIntId { get; set; }
        public Nullable<int> LikeCount { get; set; }
        public Nullable<int> DislikeCount { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public Nullable<System.Guid> ResourceId { get; set; }
    
        public virtual Resource Resource { get; set; }
    }
}

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
    
    public partial class ActivityLog
    {
        public int Id { get; set; }
        public Nullable<System.DateTime> CreatedDate { get; set; }
        public string ActivityType { get; set; }
        public string Activity { get; set; }
        public string Event { get; set; }
        public string Comment { get; set; }
        public Nullable<int> TargetUserId { get; set; }
        public Nullable<int> ActionByUserId { get; set; }
        public Nullable<int> ActivityObjectId { get; set; }
        public Nullable<int> Int2 { get; set; }
        public string RelatedImageUrl { get; set; }
        public string RelatedTargetUrl { get; set; }
    }
}

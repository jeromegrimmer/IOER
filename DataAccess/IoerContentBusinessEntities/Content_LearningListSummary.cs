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
    
    public partial class Content_LearningListSummary
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public int PartnerTypeId { get; set; }
        public Nullable<int> PartnerUserId { get; set; }
        public string PartnerType { get; set; }
        public string Summary { get; set; }
        public string ImageUrl { get; set; }
        public Nullable<int> OrgId { get; set; }
        public Nullable<int> StatusId { get; set; }
        public Nullable<bool> IsPublished { get; set; }
        public Nullable<int> ResourceIntId { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<int> CreatedById { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public Nullable<int> LastUpdatedById { get; set; }
    }
}
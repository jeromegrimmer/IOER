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
    
    public partial class Community
    {
        public Community()
        {
            this.Community_Member = new HashSet<Community_Member>();
            this.Community_PostItem = new HashSet<Community_PostItem>();
        }
    
        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public Nullable<int> ContactId { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public string ImageUrl { get; set; }
        public Nullable<int> CreatedById { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public Nullable<int> LastUpdatedById { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public Nullable<int> OrgId { get; set; }
        public int PublicAccessLevel { get; set; }
        public int OrgAccessLevel { get; set; }
        public Nullable<bool> IsModerated { get; set; }
    
        public virtual ICollection<Community_Member> Community_Member { get; set; }
        public virtual ICollection<Community_PostItem> Community_PostItem { get; set; }
        public virtual Codes_LibraryAccessLevel Codes_LibraryAccessLevel { get; set; }
        public virtual Codes_LibraryAccessLevel Codes_LibraryAccessLevel1 { get; set; }
    }
}

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
    
    public partial class Library_SectionMember
    {
        public int Id { get; set; }
        public int LibrarySectionId { get; set; }
        public int UserId { get; set; }
        public int MemberTypeId { get; set; }
        public Nullable<System.Guid> RowId { get; set; }
        public System.DateTime Created { get; set; }
        public Nullable<int> CreatedById { get; set; }
        public System.DateTime LastUpdated { get; set; }
        public Nullable<int> LastUpdatedById { get; set; }
    
        public virtual Codes_LibraryMemberType Codes_LibraryMemberType { get; set; }
        public virtual Library_Section Library_Section { get; set; }
    }
}

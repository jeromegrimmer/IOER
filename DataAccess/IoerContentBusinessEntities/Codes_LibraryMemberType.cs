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
    
    public partial class Codes_LibraryMemberType
    {
        public Codes_LibraryMemberType()
        {
            this.Library_Member = new HashSet<Library_Member>();
            this.Library_SectionMember = new HashSet<Library_SectionMember>();
        }
    
        public int Id { get; set; }
        public string Title { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
    
        public virtual ICollection<Library_Member> Library_Member { get; set; }
        public virtual ICollection<Library_SectionMember> Library_SectionMember { get; set; }
    }
}

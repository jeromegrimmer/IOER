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
    
    public partial class Community_Member
    {
        public int Id { get; set; }
        public int CommunityId { get; set; }
        public int UserId { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
    
        public virtual Community Community { get; set; }
    }
}

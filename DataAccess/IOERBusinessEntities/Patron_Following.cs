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
    
    public partial class Patron_Following
    {
        public int Id { get; set; }
        public int FollowingUserId { get; set; }
        public int FollowedByUserId { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
    
        public virtual Patron Patron { get; set; }
        public virtual Patron Patron1 { get; set; }
    }
}

//------------------------------------------------------------------------------
// <auto-generated>
//    This code was generated from a template.
//
//    Manual changes to this file may cause unexpected behavior in your application.
//    Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace GatewayBusinessEntities
{
    using System;
    using System.Collections.Generic;
    
    public partial class AppGroup_Privilege
    {
        public int GroupId { get; set; }
        public int ObjectId { get; set; }
        public int Id { get; set; }
        public Nullable<int> CreatePrivilege { get; set; }
        public Nullable<int> ReadPrivilege { get; set; }
        public Nullable<int> WritePrivilege { get; set; }
        public Nullable<int> DeletePrivilege { get; set; }
        public Nullable<int> AppendPrivilege { get; set; }
        public Nullable<int> AppendToPrivilege { get; set; }
        public Nullable<int> AssignPrivilege { get; set; }
        public Nullable<int> ApprovePrivilege { get; set; }
        public Nullable<int> SharePrivilege { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
    
        public virtual AppGroup AppGroup { get; set; }
        public virtual ApplicationObject ApplicationObject { get; set; }
        public virtual ApplicationObject ApplicationObject1 { get; set; }
    }
}

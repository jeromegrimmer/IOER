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
    
    public partial class CodeTable
    {
        public int Id { get; set; }
        public string CodeName { get; set; }
        public string LanguageCode { get; set; }
        public string StringValue { get; set; }
        public Nullable<decimal> NumericValue { get; set; }
        public Nullable<int> IntegerValue { get; set; }
        public string Description { get; set; }
        public Nullable<byte> SortOrder { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> Modified { get; set; }
    }
}

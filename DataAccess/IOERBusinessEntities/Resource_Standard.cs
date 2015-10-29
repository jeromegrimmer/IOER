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
    
    public partial class Resource_Standard
    {
        public Resource_Standard()
        {
            this.Resource_StandardEvaluation = new HashSet<Resource_StandardEvaluation>();
        }
    
        public int Id { get; set; }
        public int ResourceIntId { get; set; }
        public int StandardId { get; set; }
        public string StandardUrl { get; set; }
        public Nullable<int> AlignedById { get; set; }
        public Nullable<int> AlignmentTypeCodeId { get; set; }
        public Nullable<int> AlignmentDegreeId { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<int> CreatedById { get; set; }
        public Nullable<bool> IsDirectStandard { get; set; }
    
        public virtual StandardBody_Node StandardBody_Node { get; set; }
        public virtual Resource Resource { get; set; }
        public virtual ICollection<Resource_StandardEvaluation> Resource_StandardEvaluation { get; set; }
    }
}

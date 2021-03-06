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
    
    public partial class Resource
    {
        public Resource()
        {
            this.Resource_Version = new HashSet<Resource_Version>();
            this.Resource_Cluster = new HashSet<Resource_Cluster>();
            this.Resource_GradeLevel = new HashSet<Resource_GradeLevel>();
            this.Resource_Keyword = new HashSet<Resource_Keyword>();
            this.Resource_Subject = new HashSet<Resource_Subject>();
            this.Resource_IntendedAudience = new HashSet<Resource_IntendedAudience>();
            this.Resource_Tag = new HashSet<Resource_Tag>();
            this.Resource_Standard = new HashSet<Resource_Standard>();
            this.Resource_AssessmentType = new HashSet<Resource_AssessmentType>();
            this.Resource_EducationUse = new HashSet<Resource_EducationUse>();
            this.Resource_Evaluation = new HashSet<Resource_Evaluation>();
            this.Resource_GroupType = new HashSet<Resource_GroupType>();
            this.Resource_Like = new HashSet<Resource_Like>();
            this.Resource_LikeSummary = new HashSet<Resource_LikeSummary>();
            this.Resource_Language = new HashSet<Resource_Language>();
        }
    
        public System.Guid RowId { get; set; }
        public string ResourceUrl { get; set; }
        public Nullable<int> ViewCount { get; set; }
        public Nullable<int> FavoriteCount { get; set; }
        public Nullable<System.DateTime> Created { get; set; }
        public Nullable<System.DateTime> LastUpdated { get; set; }
        public Nullable<bool> IsActive { get; set; }
        public Nullable<bool> HasPathwayGradeLevel { get; set; }
        public int Id { get; set; }
        public string ImageUrl { get; set; }
    
        public virtual ICollection<Resource_Version> Resource_Version { get; set; }
        public virtual ICollection<Resource_Cluster> Resource_Cluster { get; set; }
        public virtual ICollection<Resource_GradeLevel> Resource_GradeLevel { get; set; }
        public virtual ICollection<Resource_Keyword> Resource_Keyword { get; set; }
        public virtual ICollection<Resource_Subject> Resource_Subject { get; set; }
        public virtual ICollection<Resource_IntendedAudience> Resource_IntendedAudience { get; set; }
        public virtual Resource_PublishedBy Resource_PublishedBy { get; set; }
        public virtual ICollection<Resource_Tag> Resource_Tag { get; set; }
        public virtual ICollection<Resource_Standard> Resource_Standard { get; set; }
        public virtual ICollection<Resource_AssessmentType> Resource_AssessmentType { get; set; }
        public virtual ICollection<Resource_EducationUse> Resource_EducationUse { get; set; }
        public virtual ICollection<Resource_Evaluation> Resource_Evaluation { get; set; }
        public virtual ICollection<Resource_GroupType> Resource_GroupType { get; set; }
        public virtual ICollection<Resource_Like> Resource_Like { get; set; }
        public virtual ICollection<Resource_LikeSummary> Resource_LikeSummary { get; set; }
        public virtual ICollection<Resource_Language> Resource_Language { get; set; }
    }
}

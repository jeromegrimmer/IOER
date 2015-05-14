﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.Data;
using System.Data.SqlClient;
using Microsoft.ApplicationBlocks.Data;
using System.Web.Script.Serialization;

using LRWarehouse.Business;
using LRWarehouse.Business.ResourceV2;
using LRWarehouse.DAL;

namespace Isle.BizServices
{
  public class ResourceV2Services
  {
    #region Get Methods
    //Get Resource DB
    public ResourceDB GetResourceDB( int resourceID )
    {
      var result = new ResourceDB();
      result.UsageRights = GetUsageRights( "" );
      result.Fields = GetFieldAndTagCodeData();

      if ( resourceID == 0 )
      {
        return result;
      }

      //Get Resource Data
      var data = new ResourceManager().Get( resourceID );

      //Handle erroneous ID
      if ( data.Id == 0 )
      {
        return result;
      }

      //Get Version Data
      data.Version = new ResourceVersionManager().GetByResourceId( resourceID );

      //Get Keywords
      var keywords = new ResourceKeywordManager().Select( resourceID ).Select( m => m.OriginalValue ).ToList();

      //Get Standards
      var standardsRaw = new ResourceStandardManager().Select( resourceID );
      var standards = new List<StandardsDB>();
      foreach ( var item in standardsRaw )
      {
        standards.Add( new StandardsDB()
        {
          StandardId = item.StandardId,
          RecordId = item.Id,
          CreatedById = item.CreatedById,
          Description = item.StandardDescription,
          NotationCode = item.StandardNotationCode,
          AlignmentType = item.AlignmentTypeValue,
          AlignmentTypeId = item.AlignmentTypeCodeId,
          AlignmentDegree = item.AlignmentDegree,
          AlignmentDegreeId = item.AlignmentDegreeId,
        } );
      }

      //Get Usage Rights
      var usageRights = GetUsageRights( data.Version.Rights );

      //Get ISLE Section IDs
      List<int> isleSectionIds = new List<int>();
      var isleSectionIdData = DatabaseManager.DoQuery( "SELECT [SiteId] FROM [Resource.Site] WHERE ResourceIntId = " + resourceID );
      foreach ( DataRow dr in isleSectionIdData.Tables[ 0 ].Rows )
      {
        isleSectionIds.Add( int.Parse( DatabaseManager.GetRowColumn( dr, "SiteId" ) ) );
      }
      if ( !isleSectionIds.Contains( 1 ) ) { isleSectionIds.Add( 1 ); } //All sites at least have IOER
      if ( !isleSectionIds.Contains( 5 ) ) { isleSectionIds.Add( 5 ); } //All sites also have all sites

      //Get Paradata
      var status = "";
      var likeData = new ResourceLikeSummaryManager().Get( resourceID, ref status ) ?? new ResourceLikeSummary();
      var favorites = SqlHelper.ExecuteDataset( DatabaseManager.ContentConnectionRO(), CommandType.Text, "SELECT Id FROM [Library.Resource] WHERE ResourceIntId = " + resourceID ).Tables[ 0 ].Rows.Count;
      var resourceViews = DatabaseManager.DoQuery( "SELECT Id FROM [Resource.View] WHERE ResourceIntId = " + resourceID ).Tables[ 0 ].Rows.Count;
      //Evaluations
      var evaluationsData = new ResourceEvaluationManager().GetRatingsForResource( resourceID, 0 );
      var evaluations = new List<LRWarehouse.Business.ResourceEvaluation>();
      var standardEvaluations = new List<LRWarehouse.Business.ResourceStandardEvaluation>();
      foreach ( var item in evaluationsData.rubricRatings )
      {
        evaluations.Add( new ResourceEvaluation()
        {
          Id = item.id,
          ResourceIntId = resourceID,
          Score = int.Parse( ( item.communityRating ).ToString().Split( '.' )[ 0 ] ) //Truncate
        } );
      }
      foreach ( var item in evaluationsData.standardRatings )
      {
        standardEvaluations.Add( new ResourceStandardEvaluation()
        {
          ResourceStandardId = item.id,
          Score = int.Parse( ( item.communityRating ).ToString().Split( '.' )[ 0 ] ) //Truncate
        } );
      }
      var paradata = new ParadataDB()
      {
        Comments = new ResourceCommentManager().SelectList( resourceID ),
        Likes = likeData.LikeCount,
        Dislikes = likeData.DislikeCount,
        Favorites = favorites,
        Evaluations = evaluations,
        StandardEvaluations = standardEvaluations,
        ResourceViews = resourceViews
      };

      //Get Fields
      var fields = GetFieldAndTagData( resourceID );

      //Get Thumbnail
      var thumbailUrl = GetThumbnailUrl( resourceID );

      //Fill Resource Data
      var resource = new ResourceDB()
      {
        ResourceId = resourceID,
        VersionId = data.Version.Id,
        CreatedById = data.CreatedById,
        LrDocId = data.Version.LRDocId,
        Title = data.Version.Title,
        UrlTitle = data.Version.SortTitle,
        Description = data.Version.Description,
        Requirements = data.Version.Requirements,
        Url = data.ResourceUrl,
        ResourceCreated = data.Version.Created.ToShortDateString(),
        Creator = data.Version.Creator,
        Publisher = data.Version.Publisher,
        Submitter = data.Version.Submitter,
        ThumbnailUrl = thumbailUrl,
        Keywords = keywords,
        IsleSectionIds = isleSectionIds,
        Created = data.Created,
        IsActive = true,
        Standards = standards,
        Updated = data.Version.LastUpdated,
        UsageRights = usageRights,
        Paradata = paradata,
        Fields = fields
      };

      return resource;
    }

    //Get Resource DTO
    public ResourceDTO GetResourceDTO( int resourceID )
    {
      //Load basic data
      var data = GetResourceDB( resourceID );
      //Handles conversion because casting/as-ing doesn't convert base type to derived type (all properties are null, even shared ones), but this does
      var serializer = new JavaScriptSerializer();

      var resource = serializer.Deserialize<ResourceDTO>( serializer.Serialize( data ) );

      //Load Standards
      foreach ( var item in data.Standards )
      {
        var standard = serializer.Deserialize<StandardsDTO>( serializer.Serialize( item ) );
        resource.Standards.Add( standard );
      }

      //Load Paradata
      resource.Paradata = serializer.Deserialize<ParadataDTO>( serializer.Serialize( data.Paradata ) );
      foreach ( var item in data.Paradata.Comments )
      {
        resource.Paradata.Comments.Add( new CommentDTO()
        {
          Id = item.Id,
          Date = item.Created.ToShortDateString(),
          Name = item.Commenter,
          UserId = item.CreatedById,
          Text = item.Comment
        } );
      }
      foreach ( var item in data.Paradata.Evaluations )
      {
        resource.Paradata.Evaluations.Add( new LRWarehouse.Business.ResourceV2.EvaluationDTO()
        {
          Id = item.Id,
          ContextId = item.RubricId,
          Score = item.Score,
          UserId = item.CreatedById
        } );
      }
      foreach ( var item in data.Paradata.StandardEvaluations )
      {
        resource.Paradata.StandardEvaluations.Add( new LRWarehouse.Business.ResourceV2.EvaluationDTO()
        {
          Id = item.Id,
          ContextId = item.ResourceStandardId,
          Score = item.Score,
          UserId = item.CreatedById
        } );
      }

      //Load Fields
      resource.Fields = serializer.Deserialize<List<FieldDTO>>( serializer.Serialize( data.Fields ) );

      return resource;
    }

    //Get Resource ES
    public ResourceES GetResourceES( int resourceID )
    {
      var result = new ResourceES();

      //Convert old style tags to new table
      DatabaseManager.ExecuteProc( "[ResourceTag.ConvertById]", new SqlParameter[] { new SqlParameter( "@resourceID", resourceID ) } );

      //Get data from tag tables
      var resourceData = DatabaseManager.ExecuteProc( "[Resource_IndexV3TextsUpdate]", new SqlParameter[] { new SqlParameter( "@resourceID", resourceID ) } );
      var tagData = DatabaseManager.ExecuteProc( "[Resource_IndexV3TagsUpdate]", new SqlParameter[] { new SqlParameter( "@resourceID", resourceID ) } );

      if ( resourceData != null && tagData != null )
      {
        //Get version Data
        result = GetResourceESVersionData( resourceData.Tables[ 0 ].Rows[ 0 ] );
        result.Fields = GetFieldCodes();

        //Assemble tag data
        foreach ( DataRow dr in tagData.Tables[ 0 ].Rows )
        {
          //Construct field data
          var fieldData = new FieldES()
          {
            Id = GetColumn<int>("CategoryId", dr),
            Ids = GetIntList("IDs", dr),
            Tags = GetStringList("Titles", dr)
          };

          //Get aliases if available
          var aliases = GetColumn<string>( "AliasValues", dr ).Split( ',' );
          if ( aliases.Count() > 0 )
          {
            result.GradeAliases = aliases.ToList();
          }

          //For the matching field, add the ID and Tag data
          var targetField = result.Fields.Where( f => f.Id == fieldData.Id ).FirstOrDefault();
          if ( targetField != null )
          {
            targetField.Ids = fieldData.Ids;
            targetField.Tags = fieldData.Tags;
          }
        }

      }

      //Return resource
      return result;
    }

    //Get Resource ES from Version Data
    public ResourceES GetResourceESVersionData( DataRow versionData )
    {
      var rights = GetUsageRightsList();
      return GetResourceESVersionData( versionData, rights );
    }

    //Get Resource ES from Version Data
    public ResourceES GetResourceESVersionData( DataRow versionData, List<UsageRights> usageRightsData )
    {
      //Get Resource ID
      var resourceID = GetColumn<int>( "ResourceIntId", versionData );

      //Safely construct created date
      var created = DateTime.Now;
      try {
        created = GetColumn<DateTime>( "ResourceCreated", versionData);
      }
      catch { }

      //Safely construct usage rights
      var rights = new UsageRights();
      for ( int i = 0 ; i < usageRightsData.Count() ; i++ )
      {
        if ( usageRightsData[ i ].Url == GetColumn<string>( "RightsUrl", versionData ) )
        {
          rights = usageRightsData[ i ];
        }
      }

      //Safely construct evaluation score
      var evaluations = GetColumn<int>( "P_Evaluations", versionData );
      var scoreRaw = GetColumn<int>( "P_EvaluationsScore", versionData );
      var score = GetPercentage( scoreRaw, evaluations );

      //Safely construct rating
      var likes = GetColumn<int>( "P_Likes", versionData );
      var dislikes = GetColumn<int>( "P_Dislikes", versionData );
      var rating = GetPercentage( likes - dislikes, likes + dislikes );

      //Safely determine favorites
      var favoritesRaw = GetColumn<int>( "P_Favorites", versionData );
      var libIDs = GetIntList( "LibraryIds", versionData );
      var favorites = libIDs.Count(); // favoritesRaw > libIDs.Count() ? favoritesRaw : libIDs.Count();

      //Build the rest of the resource
      var res = new ResourceES()
      {
        ResourceId = resourceID,
        VersionId = GetColumn<int>( "ResourceVersionId", versionData ),
        LrDocId = GetColumn<string>( "DocId", versionData ),
        Title = GetColumn<string>( "Title", versionData ),
        Description = GetColumn<string>( "Description", versionData ),
        Requirements = GetColumn<string>( "Requirements", versionData ),
        Url = GetColumn<string>( "Url", versionData ),
        ResourceCreated = created.ToShortDateString(),
        UrlTitle = GetColumn<string>( "UrlTitle", versionData ),
        ThumbnailUrl = GetThumbnailUrl( resourceID ),
        Creator = GetColumn<string>( "Creator", versionData ),
        Publisher = GetColumn<string>( "Publisher", versionData ),
        Submitter = GetColumn<string>( "Submitter", versionData ),
        UsageRights = rights,
        Keywords = GetStringList( "Keywords", versionData ),
        LibraryIds = libIDs,
        CollectionIds = GetIntList( "CollectionIds", versionData ),
        StandardIds = GetIntList( "StandardIds", versionData ),
        StandardNotations = GetStringList( "StandardNotations", versionData ),
        Paradata = new ParadataES()
        {
          Favorites = favorites,
          ResourceViews = GetColumn<int>( "P_ResourceViews", versionData ),
          Likes = likes,
          Dislikes = dislikes,
          Rating = rating,
          Comments = GetColumn<int>( "P_Comments", versionData ),
          Evaluations = evaluations,
          EvaluationsScore = score
        }
      };

      return res;
    }
    private double GetPercentage( int score, int total )
    {
      if ( total == 0 )
      {
        return 0.0;
      }
      return ( double ) ( score / total );
    }

    //Merge resource data, tag data, and tag codetable data
    public ResourceES GetResourceESViaDataMerge( DataRow versionData, List<GroupedTagData> tagData, List<UsageRights> usageRightsData, List<FieldES> fieldCodes )
    {
      //Resource Data
      var res = GetResourceESVersionData( versionData, usageRightsData );

      //Thumbnail Url
      res.ThumbnailUrl = GetThumbnailUrl( res.ResourceId );

      //Clone Fields to avoid pass-by-reference problems
      for ( int i = 0 ; i < fieldCodes.Count() ; i++ )
      {
        //IDs and Tags will be new or filled
        var ids = new List<int>();
        var tags = new List<string>();

        //For each item in tagData...
        for ( int j = 0 ; j < tagData.Count() ; j++ )
        {
          //If the item has any alias values, set the resource's grade aliases to them
          if ( tagData[ j ].AliasValues.Count() > 0 )
          {
            res.GradeAliases = tagData[ j ].AliasValues;
          }
          //If the item's ID matches the current codetable item's ID...
          if ( tagData[ j ].FieldData.Id == fieldCodes[ i ].Id )
          {
            //Fill out the ID and Tag lists
            ids = tagData[ j ].FieldData.Ids;
            tags = tagData[ j ].FieldData.Tags;
            break;
          }
        }

        //Add the field to the resource
        res.Fields.Add( new FieldES()
        {
          Id = fieldCodes[ i ].Id,
          Title = fieldCodes[ i ].Title,
          Schema = fieldCodes[ i ].Schema,
          Ids = ids,
          Tags = tags
        } );
      }

      return res;
    }

    //Get Resource ES from Version and Tag data
    public ResourceES GetResourceESFromVersionAndTagData( DataRow versionData, List<GroupedTagData> groupData, ResourceJSONManager json, List<UsageRights> usageRightsData, List<FieldES> fieldCodes )
    {
      var res = GetResourceESVersionData( versionData );

      //Thumbnail
      res.ThumbnailUrl = GetThumbnailUrl( res.ResourceId );

      //Fields
      res.Fields = fieldCodes; //Should have been cloned before getting here

      //var targetData = tagData.Where( i => i.ResourceId == res.ResourceId ).ToList();

      foreach ( var item in groupData )
      {
        var fieldSet = res.Fields.Where( f => f.Id == item.FieldData.Id ).FirstOrDefault();
        if ( fieldSet == null ) { continue; }
        fieldSet.Ids = new List<int>( item.FieldData.Ids );
        fieldSet.Tags = new List<string>( item.FieldData.Tags );
        if ( item.AliasValues.Count > 0 )
        {
          res.GradeAliases = item.AliasValues;
        }
      }

      //Ensure site IDs are properly added
      var siteIDs = res.Fields.Where( f => f.Id == 27 ).FirstOrDefault();
      try
      {
        if ( !siteIDs.Ids.Contains( 275 ) )
        {
          siteIDs.Ids.Add( 275 );
          siteIDs.Tags.Add( "IOER" );
        }
      }
      catch { }

      if ( siteIDs != null )
      {
        res.IsleSectionIds = siteIDs.Ids;
      }

      return res;
    }

    //Get LR Payload from Resource DTO
    public string GetJSONLRMIPayloadFromResource( ResourceDTO input )
    {
      //Hold output
      var resource = new Dictionary<string, object>();

      //Simple fields
      resource.Add( "name", input.Title );
      resource.Add( "url", input.Url );
      resource.Add( "description", input.Description );
      resource.Add( "author", input.Creator );
      resource.Add( "publisher", input.Publisher );
      resource.Add( "dateCreated", input.ResourceCreated );
      resource.Add( "requires", input.Requirements );
      resource.Add( "useRightsUrl", input.UsageRights.Url );
      resource.Add( "about", input.Keywords );

      //Dynamic fields
      foreach ( var item in input.Fields.Where( m => m.Tags.Where( t => t.Selected ).Count() > 0 ).ToList() )
      {
        if ( item.Schema != "gradeLevel" ) //Grade Level is handled separately
        {
          resource.Add( item.Schema, item.Tags.Where( t => t.Selected ).Select( t => t.Title ).ToList() );
        }
      }

      //Special fields
      //If any grades are selected, go through the cantankerous process of figuring out age range and assign the grade level alignment object
      var grades = input.Fields.Where( m => m.Schema == "gradeLevel" ).FirstOrDefault().Tags.Where( t => t.Selected ).OrderBy( t => t.Id ).ToList();
      if ( grades.Count > 0 )
      {
        var ageRangeDS = DatabaseManager.DoQuery(
            "SELECT codes.[Id], codes.[FromAge], codes.[ToAge], tags.[Id] AS TagId, tags.Title " +
            "FROM [Codes.GradeLevel] codes " +
            "LEFT JOIN [Codes.TagValue] tags ON tags.CodeId = codes.Id " +
            "WHERE tags.CategoryId = " + input.Fields.Where( m => m.Schema == "gradeLevel" ).FirstOrDefault().Id + " AND tags.IsActive = 1"
            );
        var fromAge = "";
        var toAge = "";
        foreach ( DataRow dr in ageRangeDS.Tables[ 0 ].Rows )
        {
          var currentID = int.Parse( DatabaseManager.GetRowColumn( dr, "TagId" ) );
          if ( currentID == grades.First().Id )
          {
            fromAge = DatabaseManager.GetRowColumn( dr, "FromAge" );
          }
          if ( currentID == grades.Last().Id )
          {
            toAge = DatabaseManager.GetRowColumn( dr, "ToAge" );
          }
        }
        resource.Add( "typicalAgeRange", fromAge + "-" + toAge );
        var alignmentObject = new AlignmentObject()
        {
          targetName = "gradeLevel",
          educationalFramework = "US P-20",
          targetDescription = grades.Select( m => m.Title ).ToList(),
          alignmentType = "gradeLevel"
        };
        resource.Add( "gradeLevel", alignmentObject );
      }

      //Standards
      //Get standard bodies
      var standardBodies = GetStandardBodiesList();
      //Assign standard bodies to standards
      foreach ( var item in input.Standards )
      {
        item.BodyId = standardBodies.Where( m => m.IdRanges.Where( n => n.Key <= item.StandardId && n.Value >= item.StandardId ).Count() > 0 ).FirstOrDefault().BodyId;
        if ( item.NotationCode == null || item.NotationCode == "" )
        {
          item.NotationCode = item.Description;
        }
      }
      //Create alignmentObjects
      var alignments = new List<AlignmentObject>();
      foreach ( var item in standardBodies )
      {
        if ( input.Standards.Where( m => m.BodyId == item.BodyId ).Count() == 0 ) { continue; }

        var alignmentObject = new AlignmentObject()
        {
          targetName = item.Title,
          educationalFramework = item.Url,
          targetDescription = input.Standards.Where( m => m.BodyId == item.BodyId ).Select( n => n.NotationCode ).ToList(),
          alignmentType = "learningStandard"
        };
        alignments.Add( alignmentObject );
      }
      //Add alignments
      if ( alignments.Count() > 0 )
      {
        resource.Add( "learningStandards", alignments );
      }


      return new JavaScriptSerializer().Serialize( resource );
    }

    //Used by import
    public void ImportRefreshResources( List<int> resourceIDs )
    {
      ImportRefreshResources( resourceIDs, true );
    }
    public void ImportRefreshResources( List<int> resourceIDs, bool sendEmailErrors )
    {
      var errors = new List<string>();
      try
      {
        var resources = new List<ResourceES>();
        foreach ( var item in resourceIDs )
        {
          try
          {
            resources.Add( GetResourceES( item ) );
          }
          catch ( Exception ex )
          {
            errors.Add( "Error updating resource " + item + ": " + ex.Message );
          }
        }

        var bulk = new List<object>();
        foreach ( var item in resources )
        {
          LoadBulkItem( ref bulk, item );
        }

        new ElasticSearchManager().DoBulkUpload( bulk );

        if ( ServiceHelper.GetAppKeyValue( "currentlyRebuildingIndex", "no" ) == "yes" )
        {
          var messageTitle = "Resources need to be reindexed after import";
          var messageBody = "Resources " + string.Join( ", ", resourceIDs ) + " were created/updated during index rebuild on " + DateTime.Now.ToShortDateString() + " and their index entries need to be refreshed.";
          if ( sendEmailErrors )
          {
            ServiceHelper.NotifyAdmin( messageTitle, messageBody );
          }
          else
          {
            throw new DataException( messageTitle + "<br />" + System.Environment.NewLine + messageBody );
          }
        }

        if ( errors.Count() > 0 )
        {
          var messageTitle = "One or more resources failed to update during import";
          var messageBody = "There were one or more errors during the GetResourceES() method in the ImportRefreshResources() method in ResourceV2Services: " + ( sendEmailErrors ? System.Environment.NewLine : "<br />" ) + string.Join( ( sendEmailErrors ? System.Environment.NewLine : "<br />" ), errors );
          if ( sendEmailErrors )
          {
            ServiceHelper.NotifyAdmin( messageTitle, messageBody );
          }
          else
          {
            throw new DataException( messageTitle + "<br />" + System.Environment.NewLine + messageBody );
          }
        }
      }
      catch ( DataException dex )
      {
        throw dex;
      }
      catch ( Exception ex )
      {
        var messageTitle = "Entire index update failed during import";
        var messageBody = "The bulk index upload process encountered an error while attempting to update the index. Resources " + string.Join( ", ", resourceIDs ) + " were created/updated on " + DateTime.Now.ToShortDateString() + " and their index entries need to be refreshed. The error was: " + ( sendEmailErrors ? System.Environment.NewLine : "<br />" ) + ex.Message + ( sendEmailErrors ? System.Environment.NewLine : "<br />" ) + ex.ToString();

        if ( sendEmailErrors )
        {
          ServiceHelper.NotifyAdmin( messageTitle, messageBody );
        }
        else
        {
          throw new Exception( messageTitle + "<br />" + System.Environment.NewLine + messageBody );
        }
      }
    }

    //Update or create a resource
    public void RefreshResource( int resourceID )
    {
      try
      {
        var manager = new ElasticSearchManager();
        //manager.RefreshResourceOld( resourceID );

        var resource = GetResourceES( resourceID );
        var bulk = new List<object>();
        LoadBulkItem( ref bulk, resource );
        manager.DoBulkUpload( bulk );

        if ( ServiceHelper.GetAppKeyValue( "currentlyRebuildingIndex", "no" ) == "yes" )
        {
          ServiceHelper.NotifyAdmin( "Resource needs to be reindexed", "Resource " + resourceID + " was updated during index rebuild on " + DateTime.Now.ToShortDateString() + " and its index entry needs to be refreshed: http://ioer.ilsharedlearning.org/Resource/" + resourceID );
          //ServiceHelper.LogError( "Resource " + resourceID + " was updated during index rebuild and its index entry needs to be refreshed." );
        }
      }
      catch ( Exception ex )
      {
        ServiceHelper.LogError( ex, "Error updating elasticsearch for resource " + resourceID + ":" );
      }
    }
    
    //Get fields for a library/collection as DTO
    public List<FieldDTO> GetFieldsDTOForLibCol( List<int> libraryIDs, List<int> collectionIDs, int isleSectionID )
    {
      var output = new List<FieldDTO>();
      var fields = GetFieldsForLibCol( libraryIDs, collectionIDs, isleSectionID );
      foreach ( var item in fields )
      {
        var newField = new FieldDTO()
        {
          Id = item.Id, Title = item.Title, Schema = item.Schema, IsleSectionIds = item.IsleSectionIds
        };
        foreach ( var tag in item.Tags )
        {
          newField.Tags.Add( new TagDTO()
          {
            Id = tag.Id, Title = tag.Title, Selected = tag.Selected
          } );
        }
        output.Add( newField );
      }
      return output;
    }

    //Get fields for a library/collection
    //There should probably be a more efficient way of doing this that lives closer to the database
    public List<FieldDB> GetFieldsForLibCol( List<int> libraryIDs, List<int> collectionIDs, int isleSectionID )
    {
      var output = new List<FieldDB>();
      var codes = GetFieldAndTagCodeData();

      //Get based on collections
      foreach(var item in collectionIDs){
        var collectionFilters = LibraryBizService.Collection_GetPresentFiltersOnly( isleSectionID, item );
        AddFieldsAndTags( 0, item, collectionFilters.SiteTagCategories, codes, ref output );
      }
      //Get based on libraries
      foreach(var item in libraryIDs)
      {
        var libraryFilters = LibraryBizService.Library_GetPresentFiltersOnly( isleSectionID, item );
        AddFieldsAndTags( item, 0, libraryFilters.SiteTagCategories, codes, ref output );
      }
      //If no library or collection IDs, just get all fields
      if ( libraryIDs.Count() == 0 && collectionIDs.Count() == 0 )
      {
        output = codes;
      }

      return output;
    }
    private void AddFieldsAndTags( int libraryID, int collectionID, List<Isle.DTO.SiteTagCategory> data, List<FieldDB> codes, ref List<FieldDB> output )
    {
      //For each field in the data for this filter...
      foreach ( var filter in data )
      {
        //Find the matching field already in output
        var target = output.Where( f => f.Id == filter.CategoryId ).FirstOrDefault(); //Id or CategoryId ?
        //If the output already contains this field...
        if ( target != null )
        {
          //...then try to get the right tags for this filter.
          var tagsForThisFilter = GetTagsForThisFilter( filter.TagValues, libraryID, collectionID, filter.CategoryId );
          
          //For each surviving tag...
          foreach ( var tag in tagsForThisFilter )
          {
            //...check to see if the tag is already there.
            var targetTag = target.Tags.Where( t => t.Id == tag.id ).FirstOrDefault();
            //If the tag isn't there...
            if ( targetTag == null )
            {
              //Try to add it.
              try
              {
                target.Tags.Add( codes.Single( m => m.Id == target.Id ).Tags.Single( n => n.Id == tag.id ) );
              }
              catch { }
            }
          }
        }
        //If the output doesn't contain this field yet...
        else
        {
          //Find the matching field in the code table
          var targetCode = codes.Where( i => i.Id == filter.CategoryId ).FirstOrDefault(); //Id or CategoryId ?
          //If it exists...
          if ( targetCode != null )
          {
            //Add a copy of it (don't want to copy the raw tags) to the output
            output.Add( new FieldDB() { Id = targetCode.Id, Title = targetCode.Title, Schema = targetCode.Schema, IsleSectionIds = targetCode.IsleSectionIds } );
            //Then add only the desired tags
            var targetfield = output.Single( f => f.Id == targetCode.Id );

            var tagsForThisFilter = GetTagsForThisFilter( filter.TagValues, libraryID, collectionID, filter.CategoryId );
            foreach ( var tag in tagsForThisFilter )
            {
              try
              {
                targetfield.Tags.Add( targetCode.Tags.Single( s => s.Id == tag.id ) );
              }
              catch { }
            }
          }
        }
      }
    }
    private List<Isle.DTO.Filters.TagFilterBase> GetTagsForThisFilter( List<Isle.DTO.Filters.TagFilterBase> tagValues, int libraryID, int collectionID, int filterID )
    {
      var tagsForThisFilterData = new List<Isle.DTO.Filters.TagFilterBase>();
      if( collectionID > 0 )
      {
        tagsForThisFilterData = LibraryBizService.AvailableFiltersForCollectionCategory( collectionID, filterID );
      }
      else 
      {
        tagsForThisFilterData = LibraryBizService.AvailableFiltersForLibraryCategory( libraryID, filterID );
      }
      return tagsForThisFilterData;
    }

    //Delete a resource
    public void DeleteResourceByVersionID( int versionID )
    {
      var intID = new ResourceBizService().GetIntIDFromVersionID( versionID );
      DeleteResource( intID );
    }
    public void DeleteResource( int resourceID )
    {
      new ElasticSearchManager().DeleteResource( resourceID );
    }

    #endregion
    #region Update methods

    public void AddResourceClickThrough( int resourceID, Patron user, string title )
    {
      new ResourceViewManager().Create( resourceID, user.Id );

      ActivityBizServices.ResourceClickThroughHit( resourceID, user.RowId.ToString(), title );

      new Isle.BizServices.ResourceV2Services().RefreshResource( resourceID );
    }

    #endregion
    #region Helper methods
    //Get strongly typed value
    public T GetColumn<T>( string columnName, DataRow row )
    {
      try
      {
        return row.Field<T>( columnName );
      }
      catch
      {
        return default( T );
      }
    }
    public List<int> GetIntList( string columnName, DataRow row )
    {
      var data = GetColumn<string>( columnName, row );
      try
      {
        return data.Split( new string[] { "," }, StringSplitOptions.RemoveEmptyEntries ).Select( int.Parse ).ToList();
      }
      catch
      {
        return new List<int>();
      }
    }
    public List<string> GetStringList( string columnName, DataRow row )
    {
      var data = GetColumn<string>( columnName, row );
      try
      {
        return data.Split( new string[] { "," }, StringSplitOptions.RemoveEmptyEntries ).ToList();
      }
      catch
      {
        return new List<string>();
      }
    }

    public List<UsageRights> GetUsageRightsList()
    {
      var rights = new List<UsageRights>();

      DataSet ds = DatabaseManager.DoQuery( "SELECT * FROM [ConditionOfUse] WHERE IsActive = 1 ORDER BY SortOrderAuthoring" );
      foreach ( DataRow dr in ds.Tables[ 0 ].Rows )
      {
        rights.Add( new UsageRights()
        {
          Id = int.Parse( DatabaseManager.GetRowColumn( dr, "Id" ) ),
          Url = DatabaseManager.GetRowPossibleColumn( dr, "Url" ) ?? "",
          Title = DatabaseManager.GetRowColumn( dr, "Summary" ),
          Description = DatabaseManager.GetRowColumn( dr, "Title" ),
          IconUrl = DatabaseManager.GetRowColumn( dr, "IconUrl" ),
          MiniIconUrl = DatabaseManager.GetRowColumn( dr, "MiniIconUrl" )
        } );
      }

      return rights;
    }
    public UsageRights GetUsageRights( string url )
    {
      var usageRights = new UsageRights();
      DataSet ds = DatabaseManager.DoQuery( "IF( SELECT COUNT(*) FROM [ConditionOfUse] WHERE [Url] = '" + url + "' ) = 0 SELECT * FROM [ConditionOfUse] WHERE [Url] IS NULL ELSE SELECT * FROM [ConditionOfUse] WHERE [Url] = '" + url + "'" );
      if ( DatabaseManager.DoesDataSetHaveRows( ds ) )
      {
        DataRow dr = ds.Tables[ 0 ].Rows[ 0 ];
        usageRights.Title = DatabaseManager.GetRowColumn( dr, "Summary" );
        usageRights.Id = int.Parse( DatabaseManager.GetRowColumn( dr, "Id" ) );
        usageRights.Description = DatabaseManager.GetRowColumn( dr, "Title" );
        usageRights.Url = url;
        usageRights.IconUrl = DatabaseManager.GetRowColumn( dr, "IconUrl" );
        usageRights.MiniIconUrl = DatabaseManager.GetRowColumn( dr, "MiniIconUrl" );
      }

      return usageRights;
    }

    public List<DDLItem> GetContentPrivilegesList()
    {
      var result = new List<DDLItem>();
      var data = new ContentServices().ContentPrivilegeCodes_Select();
      foreach ( DataRow dr in data.Tables[0].Rows )
      {
        result.Add( new DDLItem()
        {
          Id = GetColumn<int>( "Id", dr ),
          Title = GetColumn<string>( "Title", dr )
        });
      }
      return result;
    }

    public List<DDLLibrary> GetUserLibraryAndCollectionList( int userID )
    {
      var libService = new LibraryBizService();
      var libraries = libService.Library_SelectListWithContributeAccess( userID );
      var myLibrariesData = new List<DDLLibrary>();
      foreach ( var item in libraries )
      {
        var lib = new DDLLibrary()
        {
          Id = item.Id,
          Title = item.Title
        };

        var colData = libService.LibrarySections_SelectListWithContributeAccess( item.Id, userID );
        foreach ( var col in colData )
        {
          lib.Collections.Add( new DDLCollection()
          {
            Id = col.Id,
            Title = col.Title
          } );
        }

        myLibrariesData.Add( lib );
      }
      return myLibrariesData;
    }

    //Get a code table style object of all fields and tags
    public List<FieldDB> GetFieldAndTagCodeData()
    {
      return GetFieldAndTagData( 0 );
    }
    public List<FieldES> GetFieldCodes()
    {
      //Get code table
      var fieldCodesDS = DatabaseManager.DoQuery( "SELECT [Id], [Title], [SchemaTag] FROM [Codes.TagCategory] WHERE IsActive = 1" );
      var json = new ResourceJSONManager();

      //Assemble code data
      var fieldCodes = new List<FieldES>();
      foreach ( DataRow dr in fieldCodesDS.Tables[ 0 ].Rows )
      {
        fieldCodes.Add( new FieldES()
        {
          Id = json.MakeInt( json.Get( dr, "Id" ) ),
          Title = json.MakeString( json.Get( dr, "Title" ) ),
          Schema = json.MakeString( json.Get( dr, "SchemaTag" ) )
        } );
      }

      //Return data
      return fieldCodes;
    }
    //Get data for a resource
    public List<FieldDB> GetFieldAndTagData( int resourceID )
    {
      var fields = new List<FieldDB>();

      //Get code data
      var codesDS = GetFieldAndTagDataDS( 0 );
      //Get Isle Section IDs
      var sitesDS = DatabaseManager.DoQuery( "SELECT [SiteId], [CategoryId] FROM [Codes.SiteTagCategory] WHERE [IsActive] = 1" );

      //Make a list of objects to temporarily hold the Isle Section IDs data
      var sites = new List<SiteData>();
      foreach ( DataRow dr in sitesDS.Tables[ 0 ].Rows )
      {
        sites.Add( new SiteData()
        {
          SiteId = int.Parse( DatabaseManager.GetRowColumn( dr, "SiteId" ) ),
          CategoryId = int.Parse( DatabaseManager.GetRowColumn( dr, "CategoryId" ) )
        } );
      }

      //Build the list of fields
      foreach ( DataRow dr in codesDS.Tables[ 0 ].Rows )
      {
        //Get ID
        var id = int.Parse( DatabaseManager.GetRowColumn( dr, "CategoryId" ) );
        //Skip this row if this category was already added
        if ( fields.Where( m => m.Id == id ).Count() > 0 ) { continue; }
        //Otherwise, add the category
        var field = new FieldDB()
        {
          Id = id,
          Title = DatabaseManager.GetRowColumn( dr, "Category" ),
          Schema = DatabaseManager.GetRowColumn( dr, "SchemaCat" )
        };
        //Determine the list of section IDs
        field.IsleSectionIds = sites.Where( m => m.CategoryId == field.Id ).Select( m => m.SiteId ).ToList();

        //Add the field
        fields.Add( field );
      }

      var selectedIDs = new List<int>();
      if ( resourceID > 0 )
      {
        //Get resource tags
        var idsDS = GetResourceTagValueIDs( resourceID );

        //Set "Selected" = true for things that were selected
        foreach ( DataRow dr in idsDS.Tables[ 0 ].Rows )
        {
          selectedIDs.Add( int.Parse( DatabaseManager.GetRowColumn( dr, "TagvalueId" ) ) );
        }
      }

      //Add tags to fields
      foreach ( DataRow dr in codesDS.Tables[ 0 ].Rows )
      {
        var categoryID = int.Parse( DatabaseManager.GetRowColumn( dr, "CategoryId" ) );
        var id = int.Parse( DatabaseManager.GetRowColumn( dr, "TagId" ) );
        fields.Where( m => m.Id == categoryID ).FirstOrDefault().Tags.Add( new TagDB()
        {
          Id = id,
          Title = DatabaseManager.GetRowColumn( dr, "Tag" ),
          CategoryId = categoryID,
          Selected = selectedIDs.Contains( id ),
          OldCodeId = int.Parse( DatabaseManager.GetRowColumn( dr, "CodeId" ) ),
          Schema = DatabaseManager.GetRowColumn( dr, "SchemaTag" )
        } );
      }

      //Have to keep this around for legacy resources
      if ( resourceID > 0 )
      {
        GetOldStyleTagData( resourceID, ref fields );
      }

      return fields;
    }
    public DataSet GetFieldAndTagDataDS( int resourceID )
    {
      //Get combined table of category and tag data in one call
      DataSet ds = DatabaseManager.DoQuery(
        "SELECT DISTINCT tags.[Id] AS 'TagId', " +
        "vals.[Title] AS 'Tag', vals.[SortOrder] AS 'TagSort', vals.[CategoryId], vals.[CodeId]," +
        "cats.[SchemaTag] AS 'SchemaCat', vals.[SchemaTag] AS 'SchemaTag', cats.[Title] AS 'Category', cats.[SortOrder] AS 'CategorySort' " +
        ( resourceID == 0 ? "" : ", res.[ResourceIntId]" ) +
        "FROM [Codes.TagValue] tags " +
        "LEFT JOIN [Codes.TagValue] vals ON tags.[Id] = vals.[Id] " +
        "LEFT JOIN [Codes.TagCategory] cats ON vals.[CategoryId] = cats.[Id] " +
        ( resourceID == 0 ? "" : "LEFT JOIN [Resource.Tag] res ON res.[TagValueId] = tags.[Id]" ) +
        "WHERE " + ( resourceID == 0 ? "" : "res.[ResourceIntId] = " + resourceID + " AND " ) + "vals.[IsActive] = 1 AND cats.[IsActive] = 1" +
        "ORDER BY cats.[SortOrder], cats.[Title], vals.[SortOrder]" );

      return ds;
    }
    public DataSet GetResourceTagValueIDs( int resourceID )
    {
      DataSet ds = DatabaseManager.DoQuery(
        "SELECT [TagvalueId] FROM [Resource.Tag] WHERE [ResourceIntId] = " + resourceID
      );

      return ds;
    }

    //Get Thumbnail URL (may make this dynamic later)
    public string GetThumbnailUrl( int resourceID )
    {
      return "/OERThumbs/large/" + resourceID + "-large.png";
    }

    //Add stuff to a list
    public void AddItemPairToBulkList( ref List<object> bulkList, DataRow dr, List<GroupedTagData> groupData, ResourceJSONManager json, List<UsageRights> usageRightsData, List<FieldES> fieldCodes )
    {
      //Format Data
      var data = GetResourceESFromVersionAndTagData( dr, groupData, json, usageRightsData, fieldCodes );

      //Add index and resource pairs
      LoadBulkItem( ref bulkList, data );

    }
    public void LoadBulkItem( ref List<object> bulk, ResourceES item )
    {
      LoadBulkItem( ref bulk, item, "mainSearchCollection" );
    }
    public void LoadBulkItem( ref List<object> bulk, ResourceES item, string indexName )
    {
      bulk.Add( new { index = new { _index = indexName, _type = "resource", _id = item.ResourceId } } );
      bulk.Add( item );
    }

    //Get old style tag data - hopefully temporary!
    private void GetOldStyleTagData( int resourceID, ref List<FieldDB> fields )
    {
      //Resource Type
      var resourceTypeIDs = new ResourceTypeManager().Select( resourceID ).Select( m => m.CodeId ).ToList();
      SelectTagsFromIDs( resourceTypeIDs, ref fields, "learningResourceType" );

      //Media Type
      var mediaTypeIDs = new ResourceFormatManager().Select( resourceID ).Select( m => m.CodeId ).ToList();
      SelectTagsFromIDs( mediaTypeIDs, ref fields, "mediaType" );

      //K-12 Subject
      var subjectIDsDS = DatabaseManager.DoQuery( "SELECT [CodeId] FROM [Resource.Subject] WHERE ResourceIntId = 9 AND [CodeId] IS NOT NULL" );
      var subjectIDs = new List<int>();
      foreach ( DataRow dr in subjectIDsDS.Tables[ 0 ].Rows )
      {
        subjectIDs.Add( int.Parse( DatabaseManager.GetRowColumn( dr, "CodeId" ) ) );
      }
      SelectTagsFromIDs( subjectIDs, ref fields, "k12Subject" );

      //Educational Use
      var edUseIDsDS = new ResourceEducationUseManager().SelectedCodes( resourceID );
      var edUseIDs = new List<int>();
      foreach ( DataRow dr in edUseIDsDS.Tables[ 0 ].Rows )
      {
        edUseIDs.Add( int.Parse( DatabaseManager.GetRowColumn( dr, "Id" ) ) );
      }
      SelectTagsFromIDs( edUseIDs, ref fields, "educationalUse" );

      //Career Cluster
      var careerClusterIDsDS = new ResourceClusterManager().SelectedCodes( resourceID );
      var careerClusterIDs = new List<int>();
      foreach ( DataRow dr in careerClusterIDsDS.Tables[ 0 ].Rows )
      {
        if ( DatabaseManager.GetRowColumn( dr, "IsSelected" ).ToLower() == "true" )
        {
          careerClusterIDs.Add( int.Parse( DatabaseManager.GetRowColumn( dr, "Id" ) ) );
        }
      }
      SelectTagsFromIDs( careerClusterIDs, ref fields, "careerCluster" );

      //Grade Level
      var gradeLevelIDs = new ResourceGradeLevelManager().Select( resourceID ).Select( m => m.CodeId ).ToList();
      SelectTagsFromIDs( gradeLevelIDs, ref fields, "gradeLevel" );

      //End User
      var endUserIDs = new ResourceIntendedAudienceManager().SelectCollection( resourceID ).Select( m => m.CodeId ).ToList();
      SelectTagsFromIDs( endUserIDs, ref fields, "educationalRole" );

      //Group Type
      var groupTypeIDsDS = new ResourceGroupTypeManager().SelectedCodes( resourceID );
      var groupTypeIDs = new List<int>();
      foreach ( DataRow dr in groupTypeIDsDS.Tables[ 0 ].Rows )
      {
        groupTypeIDs.Add( int.Parse( DatabaseManager.GetRowColumn( dr, "Id" ) ) );
      }
      SelectTagsFromIDs( groupTypeIDs, ref fields, "groupType" );

      //Access Rights
      var accessRightsIDs = new List<int>() { new ResourceVersionManager().GetByResourceId( resourceID ).AccessRightsId };
      if ( accessRightsIDs[ 0 ] < 2 ) { accessRightsIDs[ 0 ] = 2; }
      SelectTagsFromIDs( accessRightsIDs, ref fields, "accessRights" );

      //Language
      var languageIDs = new ResourceLanguageManager().Select( resourceID ).Select( m => m.CodeId ).ToList();
      SelectTagsFromIDs( languageIDs, ref fields, "inLanguage" );

    }
    private void SelectTagsFromIDs( List<int> ids, ref List<FieldDB> fields, string schema )
    {
      try
      {
        var field = fields.Where( m => m.Schema == schema ).FirstOrDefault();
        foreach ( var item in ids )
        {
          field.Tags.Where( m => m.OldCodeId == item ).FirstOrDefault().Selected = true;
        }
      }
      catch { }
    }

    #endregion
    #region Helper classes
    public class AlignmentObject
    {
      public string targetName { get; set; }
      public string educationalFramework { get; set; }
      public object targetDescription { get; set; }
      public string alignmentType { get; set; }
    }
    public struct GroupedTagData
    {
      public int ResourceId { get; set; }
      public FieldES FieldData { get; set; }
      public List<string> AliasValues { get; set; }
    }
    public class SiteData
    {
      public int SiteId { get; set; }
      public int CategoryId { get; set; }
    };
    public class DDLItem
    {
      public int Id { get; set; }
      public string Title { get; set; }
    }
    public class DDLLibrary : DDLItem
    {
      public DDLLibrary()
      {
        Collections = new List<DDLCollection>();
      }
      public List<DDLCollection> Collections { get; set; }
    }
    public class DDLCollection : DDLItem
    {
    }

    #endregion

    //Super mega kludge - is this association made at all in the database? I couldn't figure how, if it is.
    public List<StandardBody> GetStandardBodiesList()
    {
      var output = new List<StandardBody>();
      //CCSS Math
      output.Add( new StandardBody()
      {
        BodyId = 1,
        Url = "http://asn.desire2learn.com/resources/D10003FB",
        Title = "Common Core Math Standards",
        NotationPrefix = "CCSS.Math.Content",
        IdRanges = new Dictionary<int, int>() { { 1, 694 }, { 2472, 2481 } } //Pesky math practice standards
      } );
      //CCSS English
      output.Add( new StandardBody()
      {
        BodyId = 2,
        Url = "http://asn.desire2learn.com/resources/D10003FC",
        Title = "Common Core ELA/Literacy Standards",
        NotationPrefix = "CCSS.ELA-Literacy",
        IdRanges = new Dictionary<int, int>() { { 695, 1778 } }
      } );
      //NGSS
      output.Add( new StandardBody()
      {
        BodyId = 3,
        Url = "http://asn.desire2learn.com/resources/D2603111",
        Title = "Next Generation Science Standards",
        NotationPrefix = "NGSS",
        IdRanges = new Dictionary<int, int>() { { 2500, 2829 } }
      } );
      //Fine Arts
      output.Add( new StandardBody()
      {
        BodyId = 4,
        Url = "http://asn.jesandco.org/resources/D10002E1",
        Title = "Illinois Fine Arts Standards",
        NotationPrefix = "IL.FA",
        IdRanges = new Dictionary<int, int>() { { 3000, 3082 } }
      } );
      //Physical Development and Health
      output.Add( new StandardBody()
      {
        BodyId = 5,
        Url = "http://asn.jesandco.org/resources/D2406779",
        Title = "Illinois Physical Development and Health Standards",
        NotationPrefix = "IL.PDH",
        IdRanges = new Dictionary<int, int>() { { 3250, 3402 } }
      } );
      //Social Science
      output.Add( new StandardBody()
      {
        BodyId = 5,
        Url = "http://asn.jesandco.org/resources/D2407056",
        Title = "Illinois Social Science Standards",
        NotationPrefix = "IL.SS",
        IdRanges = new Dictionary<int, int>() { { 3500, 3782 } }
      } );
      //NHES
      output.Add( new StandardBody()
      {
        BodyId = 6,
        Url = "http://asn.desire2learn.com/resources/D2589605",
        Title = "National Health Education Standards",
        NotationPrefix = "NHES",
        IdRanges = new Dictionary<int, int>() { { 4003, 4154 } }
      } );
      //Social Emotional
      output.Add( new StandardBody()
      {
        BodyId = 7,
        Url = "http://asn.jesandco.org/resources/D2406942",
        Title = "Illinois Social/Emotional Development Standards",
        NotationPrefix = "IL.SED",
        IdRanges = new Dictionary<int, int>() { { 4200, 4314 } }
      } );
      //ABE Reading
      output.Add( new StandardBody()
      {
        BodyId = 8,
        Url = "http://asn.desire2learn.com/resources/D2609410",
        Title = "Illinois Adult Education (ABE/ASE) Reading Standards",
        NotationPrefix = "IL.ABE.Reading",
        IdRanges = new Dictionary<int, int>() { { 4500, 4643 } }
      } );
      //ABE Writing
      output.Add( new StandardBody()
      {
        BodyId = 9,
        Url = "http://asn.desire2learn.com/resources/D2609411",
        Title = "Illinois Adult Education (ABE/ASE) Writing Standards",
        NotationPrefix = "IL.ABE.Writing",
        IdRanges = new Dictionary<int, int>() { { 5000, 5100 } }
      } );
      //ABE Math
      output.Add( new StandardBody()
      {
        BodyId = 10,
        Url = "http://asn.desire2learn.com/resources/D2609857",
        Title = "Illinois Adult Education (ABE/ASE) Mathematics Standards",
        NotationPrefix = "IL.ABE.Math",
        IdRanges = new Dictionary<int, int>() { { 5500, 6115 } }
      } );
      //K-12 Personal Finance
      output.Add( new StandardBody()
      {
        BodyId = 11,
        Url = "http://asn.desire2learn.com/resources/D2609021",
        Title = "National Standards in K-12 Personal Finance Education",
        NotationPrefix = "Finance.K12PFE",
        IdRanges = new Dictionary<int, int>() { { 6200, 6588 } }
      } );
      //Voluntary Economics
      output.Add( new StandardBody()
      {
        BodyId = 12,
        Url = "http://asn.desire2learn.com/resources/D2604645",
        Title = "Voluntary National Content Standards in Economics",
        NotationPrefix = "Finance.VNCSE",
        IdRanges = new Dictionary<int, int>() { { 6700, 6943 } }
      } );
      //Financial Literacy
      output.Add( new StandardBody()
      {
        BodyId = 13,
        Url = "http://asn.desire2learn.com/resources/D2604492",
        Title = "National Standards for Financial Literacy",
        NotationPrefix = "Finance.NSFL",
        IdRanges = new Dictionary<int, int>() { { 7000, 7150 } }
      } );

      return output;
    }
    public class StandardBody
    {
      public int BodyId { get; set; }
      public string Url { get; set; }
      public string Title { get; set; }
      public string NotationPrefix { get; set; }
      public Dictionary<int, int> IdRanges { get; set; }
    }

  }

}

USE [IsleContent]
GO
/****** Object:  User [lrAdmin]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE USER [lrAdmin] FOR LOGIN [lrAdmin] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  User [lrReader]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE USER [lrReader] FOR LOGIN [lrReader] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [lrAdmin]
GO
ALTER ROLE [db_datareader] ADD MEMBER [lrReader]
GO
/****** Object:  StoredProcedure [dbo].[Activity.MyFollowingSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
select * from [LR.PatronOrgSummary]

select * from [Library.Subscription] where userId = 2
go
select * from [Library.SectionSubscription] where userId = 2
go

[Activity.MyFollowingSummary] 2, 2
*/
/*
Get summary of activity
*/
CREATE PROCEDURE [dbo].[Activity.MyFollowingSummary]
    @HistoryDays int
	,@UserId int
As
Declare @LibUrl varchar(200),@CollectionUrl varchar(200),@ContentUrl varchar(200)
,@ResourceUrl varchar(200),@ResImgeUrl varchar(200)
,@CommunityUrl varchar(200),@CommImgeUrl varchar(200),@CommPostingUrl varchar(200)
,@ActorUrl varchar(200),@DefActorImageUrl varchar(200),@PdfImageUrl varchar(200)
, @LimitToUser bit

--set @UserId = 2
set @LimitToUser = 0

set @LibUrl = '/Libraries/Library.aspx?id=@lid'
set @LibUrl = '/Library/@lid/@Title'
set @CollectionUrl = '/Libraries/Library.aspx?id=@lid&col=@cid'
set @ResourceUrl = '/IOER/@rvid/@title'
set @ContentUrl = '/CONTENT/@cid/@title'
set @ResImgeUrl = '//ioer.ilsharedlearning.org/OERThumbs/thumb/@rvid-thumb.png'
set @PdfImageUrl = '//ioer.ilsharedlearning.org/images/icons/filethumbs/filethumb_pdf_200x150.png'
--prob should use guid!
set @ActorUrl = '/Profiles/default.aspx?id=@uid'
set @DefActorImageUrl = '/Images/defaultProfileImg.jpg'
--
--
set @CommunityUrl = '/Communities/default.aspx?id=@cid'
set @CommunityUrl = '/Community/@cid/@Title'
set @CommPostingUrl = '/Community/@cid/@Title?id=@PostintId'
set @CommImgeUrl = '/Images/icons/icon_community_med.png'


-- library comments
SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Commented On' As Activity

	  ,objct.Id as ObjectId
	  ,'Comment' as ObjectType
	  ,'Comment' as ObjectTitle
	  ,objct.Comment as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Library' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(@LibUrl, '@lid', objct.LibraryId) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.Comment] objct
  inner join (
	select libraryId, count(*) As Counts from dbo.[Library.Comment] group by libraryId) 
	As ObjectGroup on objct.LibraryId = ObjectGroup.LibraryId
  inner join [Library] target on objct.LibraryId = target.Id
  inner join[LR.PatronOrgSummary] crby on objct.CreatedById = crby.UserId
  inner join [Library.Subscription] following on target.id = following.LibraryId
  where 
		(following.UserId = @UserId
		OR (target.LibraryTypeId = 1 AND target.CreatedById  = @UserId))
  AND objct.[Created] >  getdate() - @HistoryDays
  UNION
  -- collection comments
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Commented On' As Activity

	  ,objct.Id as ObjectId
	  ,'Comment' as ObjectType
	  ,'Comment' as ObjectTitle
	  ,objct.Comment as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Collection' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(replace(@CollectionUrl, '@lid', target.LibraryId), '@cid', objct.SectionId) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.SectionComment] objct
    inner join (
	select SectionId, count(*) As Counts from dbo.[Library.SectionComment] group by SectionId) 
	As ObjectGroup on objct.SectionId = ObjectGroup.SectionId
  inner join [Library.Section] target on objct.SectionId = target.Id
  inner join [Library] lib on target.LibraryId = lib.Id
  inner join[LR.PatronOrgSummary] crby on objct.CreatedById = crby.UserId
  inner join [Library.SectionSubscription] following on target.id = following.SectionId
  where 
		(following.UserId = @UserId
		OR (lib.LibraryTypeId = 1 AND lib.CreatedById  = @UserId))
  AND objct.[Created] >  getdate() - @HistoryDays

  UNION
  --  library Like
  SELECT Distinct
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
  	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Liked' As Activity

  	  ,objct.Id as ObjectId
	  ,'Like' as ObjectType
	  ,'' as ObjectTitle
	  ,'' as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,LikesCrosstab.LikeCounts as ObjectCount
	  ,LikesCrosstab.DislikeCounts as ObjectCount2
	  ,case when HasRating.IsLike is null then 0 else 1 end as HasObject
	  --,isnull(HasRating.IsLike,0) As HasObject

	  ,'Library' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(@LibUrl, '@lid', objct.LibraryId) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.Like] objct
  --  inner join (
		--select LibraryId, count(*) As Counts from dbo.[Library.Like] ll where ll.IsLike = 1 group by LibraryId) 
		--As ObjectGroup on objct.LibraryId = ObjectGroup.LibraryId
	inner join (
		Select LibraryId, Sum(Case Cast(IsLike As nvarchar(100)) When N'1'   Then 1 Else 0 End ) as [LikeCounts],
		Sum(Case Cast(IsLike As nvarchar(100)) When N'0'   Then 1 Else 0 End ) as [DislikeCounts] From [Library.Like]
		Group By LibraryId
	) As LikesCrosstab on  objct.LibraryId = LikesCrosstab.LibraryId
	left join [dbo].[Library.Like] HasRating  on objct.LibraryId = HasRating.LibraryId And HasRating.CreatedById = @UserId
		
	inner join [Library] target on objct.LibraryId = target.Id
	inner join[LR.PatronOrgSummary] crby on objct.CreatedById = crby.UserId
	inner join [Library.Subscription] following on target.id = following.LibraryId
  where 
		(following.UserId = @UserId
		OR (target.LibraryTypeId = 1 AND target.CreatedById  = @UserId))
  AND objct.[Created] >  getdate() - @HistoryDays
  AND objct.IsLike = 1
  UNION
  -- collection Like
  SELECT Distinct
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
  	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Liked' As Activity

	  ,objct.Id as ObjectId
	  ,'Like' as ObjectType
	  ,'' as ObjectTitle
	  ,'' as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,LikesCrosstab.LikeCounts as ObjectCount
	  ,LikesCrosstab.DislikeCounts as ObjectCount2
	  ,case when HasRating.IsLike is null then 0 else 1 end as HasObject
	  --,isnull(HasRating.IsLike,0) As HasObject

	  ,'Collection' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(replace(@CollectionUrl, '@lid', target.LibraryId), '@cid', objct.SectionId) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.SectionLike] objct
  --  inner join (
		--select SectionId, count(*) As Counts from dbo.[Library.SectionLike] ll where ll.IsLike = 1 group by SectionId) 
		--As ObjectGroup on objct.SectionId = ObjectGroup.SectionId
	inner join (
		Select SectionId, Sum(Case Cast(IsLike As nvarchar(100)) When N'1'   Then 1 Else 0 End ) as LikeCounts,
		Sum(Case Cast(IsLike As nvarchar(100)) When N'0'   Then 1 Else 0 End ) as DislikeCounts From [Library.SectionLike]
		Group By SectionId
	) As LikesCrosstab on  objct.SectionId = LikesCrosstab.SectionId

	left join [dbo].[Library.SectionLike] HasRating  on objct.SectionId = HasRating.SectionId And HasRating.CreatedById = @UserId
	inner join [Library.Section] target on objct.SectionId = target.Id
	inner join [Library] lib on target.LibraryId = lib.Id
	inner join[LR.PatronOrgSummary] crby on objct.CreatedById = crby.UserId
    inner join [Library.SectionSubscription] following on target.id = following.SectionId
  where 
		(following.UserId = @UserId
		OR (lib.LibraryTypeId = 1 AND lib.CreatedById  = @UserId))
  AND objct.[Created] >  getdate() - @HistoryDays
  AND objct.IsLike = 1
  UNION
   --  library follow
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.UserId As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.UserId = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Is Following' As Activity

	  ,objct.Id as ObjectId
	  ,'Following' as ObjectType
	  ,'Is Following' as ObjectTitle
	  ,'' as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Library' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(@LibUrl, '@lid', objct.LibraryId) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.Subscription] objct
  inner join (
	select libraryId, count(*) As Counts from dbo.[Library.Subscription] group by libraryId) 
	As ObjectGroup on objct.LibraryId = ObjectGroup.LibraryId
	inner join [Library] target on objct.LibraryId = target.Id
	inner join[LR.PatronOrgSummary] crby on objct.UserId = crby.UserId
	inner join [Library.Subscription] following on target.id = following.LibraryId
  where 
		(following.UserId = @UserId
		OR (target.LibraryTypeId = 1 AND target.CreatedById  = @UserId))
  AND objct.[Created] >  getdate() - @HistoryDays
  UNION
  -- collection follow
  --==> should also include if following library, and collection is not restricted?. really minor though
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.UserId As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.UserId = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Is Following' As Activity

	  ,objct.Id as ObjectId
	  ,'Following' as ObjectType
	  ,'Is Following' as ObjectTitle
	  ,'' as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Collection' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(replace(@CollectionUrl, '@lid', target.LibraryId), '@cid', objct.SectionId) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.SectionSubscription] objct
    inner join (
	select SectionId, count(*) As Counts from dbo.[Library.SectionSubscription] group by SectionId) 
	As ObjectGroup on objct.SectionId = ObjectGroup.SectionId
	inner join [Library.Section] target on objct.SectionId = target.Id
	inner join [Library] lib on target.LibraryId = lib.Id
	inner join[LR.PatronOrgSummary] crby on objct.UserId = crby.UserId
	inner join [Library.SectionSubscription] following on target.id = following.SectionId
  where 
		(following.UserId = @UserId
		OR (lib.LibraryTypeId = 1 AND lib.CreatedById  = @UserId))
  AND objct.[Created] >  getdate() - @HistoryDays
  UNION
  -- add library resource
  -- ==> should check if has access to collection?
  SELECT 
		base.[Created]
      ,convert(varchar(10), base.[Created],120) as [ActivityDay]
      ,base.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when base.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Added Resource to' As Activity

	  ,res.ResourceVersionIntId as ObjectId
	  ,'Resource' as ObjectType
	  ,res.Title as ObjectTitle
	  ,res.Description as ObjectText
	  ,replace(replace(@ResourceUrl,  '@rvid',res.ResourceVersionIntId), '@title', replace(res.SortTitle, ' ', '_')) As ObjectUrl
  	  ,case when Right(rtrim(lower(res.ResourceUrl)), 4) = '.pdf' then @PdfImageUrl
		else replace(@ResImgeUrl, '@rvid', res.ResourceIntId) end As ObjectImageUrl
	  --,replace(@ResImgeUrl, '@rvid', res.ResourceIntId) As ObjectImageUrl

	  ,rls.[LikeCount] as ObjectCount
	  ,rls.[DislikeCount] as ObjectCount2
	  ,case when HasRating.IsLike is null then 0 else 1 end as HasObject

	  ,'Collection' as TargetType
	  ,LibrarySectionId As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(replace(@LibUrl, '@lid', target.LibraryId), '@cid', target.Id) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.Resource] base
  inner join [Library.Section] target		on base.LibrarySectionId = target.Id
  inner join [Library] lib					on target.LibraryId = lib.Id
  inner join[LR.PatronOrgSummary] crby		on base.CreatedById = crby.UserId
  inner join [LR.ResourceVersion_Summary] res on base.ResourceIntId = res.ResourceIntId
  left join [LR.ResourceLikesSummary] rls	on base.ResourceIntId = rls.ResourceIntId
  left join [dbo].[LR.ResourceLike] HasRating  on base.ResourceIntId = HasRating.[ResourceIntId] And HasRating.CreatedById = @UserId
  
  inner join [Library.Subscription] following on target.id = following.LibraryId
  where 
		(following.UserId = @UserId
		OR (lib.LibraryTypeId = 1 AND lib.CreatedById  = @UserId))
  AND base.[Created] >  getdate() - @HistoryDays

  UNION
  -- comment on resource in library 
  -- ==> should check if has access to collection?
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Commented On' As Activity

	  --object is comment
	  ,objct.Id as ObjectId
	  ,'Comment' as ObjectType
	  ,'Comment on resource' as ObjectTitle
	  ,objct.Comment as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  --exception: likes are for target, not object?
	  ,rls.[LikeCount] as ObjectCount
	  ,rls.[DislikeCount] as ObjectCount2
	  ,case when HasRating.IsLike is null then 0 else 1 end as HasObject

	  --target is resource
	  ,'Resource' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(replace(@ResourceUrl,  '@rvid',target.ResourceVersionIntId), '@title', replace(target.SortTitle, ' ', '_')) As TargetUrl
   	  ,case when Right(rtrim(lower(target.ResourceUrl)), 4) = '.pdf' then @PdfImageUrl
		else replace(@ResImgeUrl, '@rvid', target.ResourceIntId) end As TargetImageUrl
	  --,replace(@ResImgeUrl, '@rvid', res.ResourceIntId) As TargetImageUrl

	FROM dbo.[LR.ResourceComment] objct
  inner join dbo.[Library.Resource] base	on objct.ResourceIntId = base.ResourceIntId
  inner join [Library.Section] ls			on base.LibrarySectionId = ls.Id
  inner join [Library] lib					on ls.LibraryId = lib.Id
  inner join[LR.PatronOrgSummary] crby		on objct.CreatedById = crby.UserId
  inner join [LR.ResourceVersion_Summary] target on base.ResourceIntId = target.ResourceIntId
  left join [LR.ResourceLikesSummary] rls on base.ResourceIntId = rls.ResourceIntId
  left join [dbo].[LR.ResourceLike] HasRating  on base.ResourceIntId = HasRating.[ResourceIntId] And HasRating.CreatedById = @UserId
  
  inner join [Library.Subscription] following on lib.id = following.LibraryId
    where 
		(following.UserId = @UserId
		OR (lib.LibraryTypeId = 1 AND lib.CreatedById  = @UserId))
  AND base.[Created] >  getdate() - @HistoryDays

  UNION
  ----- library add collection
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Added Collection to' As Activity

	  ,objct.Id As ObjectTypeId
	  ,'Collection' as ObjectType
	  ,objct.Title as ObjectTitle
	  ,objct.Description as ObjectText
	  ,replace(replace(@CollectionUrl, '@lid', target.Id), '@cid', objct.Id) As ObjectUrl
	  ,objct.ImageUrl As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Library' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(@LibUrl, '@lid', target.Id) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library] target
  inner join [Library.Section] objct on target.Id = objct.LibraryId
    inner join (
	select libraryId, count(*) As Counts from dbo.[Library.Section] group by libraryId) 
	As ObjectGroup on objct.LibraryId = ObjectGroup.LibraryId
  inner join[LR.PatronOrgSummary] crby on target.CreatedById = crby.UserId

  inner join [Library.Subscription] following on target.id = following.LibraryId
  where following.UserId = @UserId
  AND objct.[Created] >  getdate() - @HistoryDays
  UNION
  ----- user posts to community
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,crby.UserId As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Posted To' As Activity

	 ,objct.Id as ObjectId
	  ,'CommunityPosting' as ObjectType
	  ,'Community Posting' as ObjectTitle
	  ,objct.Message as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,0 as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Community' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  --,replace(@CommunityUrl, '@cid', target.Id) As TargetUrl
	  ,replace(replace(@CommunityUrl,  '@cid',target.Id), '@title', replace(target.Title, ' ', '_')) As TargetUrl
	  ,@CommImgeUrl As TargetImageUrl

  FROM [LR.PatronOrgSummary] crby
  inner join [dbo].[Community.Posting] objct	on crby.UserId = objct.CreatedById
  inner join [Community] target					on objct.CommunityId = target.Id
  
  inner join [Community.Member] following on target.id = following.CommunityId
  where following.UserId = @UserId
  AND objct.[Created] >  getdate() - @HistoryDays

   UNION
  ----- user published resource
  -- where following actor
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,crby.UserId As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.PublishedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Published' As [Action]
	  ,'Published Resource' As Activity

	  ,res.ResourceVersionIntId as ObjectId
	  ,'Resource' as ObjectType
	  ,res.Title as ObjectTitle
	  ,res.Description as ObjectText
	  ,replace(replace(@ResourceUrl,  '@rvid',res.ResourceVersionIntId), '@title', replace(res.SortTitle, ' ', '_')) As ObjectUrl

  	  ,case when Right(rtrim(lower(res.ResourceUrl)), 4) = '.pdf' then @PdfImageUrl
		else replace(@ResImgeUrl, '@rvid', res.ResourceIntId) end As ObjectImageUrl
	  --,replace(@ResImgeUrl, '@rvid', res.ResourceIntId) As ObjectImageUrl
	  ,rls.[LikeCount] as ObjectCount
	  ,rls.[DislikeCount] as ObjectCount2
	  ,case when HasRating.IsLike is null then 0 else 1 end as HasObject

	  ,'' as TargetType
	  ,'' as TargetObjectId
	  ,'' as TargetTitle
	  ,'' as TargetText
	  ,'' as TargetUrl
	  ,'' as TargetImageUrl

  FROM [Person.Following] following 
  Inner  join [LR.PatronOrgSummary]						crby	on following.FollowingUserId = crby.UserId
  inner join [Isle_IOER].[dbo].[Resource.PublishedBy]	objct	on crby.UserId = objct.PublishedById
  inner join [LR.ResourceVersion_Summary]				res		on objct.ResourceIntId = res.ResourceIntId
  left join [LR.ResourceLikesSummary]					rls		on res.ResourceIntId = rls.ResourceIntId
  left join [dbo].[LR.ResourceLike] HasRating					on res.ResourceIntId = HasRating.[ResourceIntId] And HasRating.CreatedById = @UserId

  where following.FollowedByUserId = @UserId
  AND objct.[Created] >  getdate() - @HistoryDays
  --UNION
  ------- user posts to community that is followed
  --SELECT 
		--objct.[Created]
  --    ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
  --    ,crby.UserId As ActorId
	 -- ,crby.FullName As Actor
	 -- ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	 -- ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	 -- ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	 -- ,'Added' As [Action]
	 -- ,'Added Posting' As Activity

	 --,objct.Id as ObjectId
	 -- ,'CommunityPosting' as ObjectType
	 -- ,'Community Posting' as ObjectTitle
	 -- ,objct.Message as ObjectText
	 -- ,'' As ObjectUrl
	 -- ,'' As ObjectImageUrl
	 -- ,0 as ObjectCount
	 -- ,0 as ObjectCount2
	 -- ,0 As HasObject

	 -- ,'Community' as TargetType
	 -- ,target.Id As TargetObjectId
	 -- ,target.Title as TargetTitle
	 -- ,target.Description as TargetText
	 -- ,replace(@CommunityUrl, '@cid', target.Id) As TargetUrl
	 -- ,@CommImgeUrl As TargetImageUrl

  --FROM [LR.PatronOrgSummary] crby
  --inner join [dbo].[Community.Posting] objct	on crby.UserId = objct.CreatedById
  --inner join [Community] target					on objct.CommunityId = target.Id
  --where objct.[Created] >  getdate() - @HistoryDays

  --   UNION
  ------- user authored resource
  --SELECT 
		--objct.[Created]
  --    ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
  --    ,crby.UserId As ActorId
	 -- ,crby.FullName As Actor
	 -- ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrlActorImageUrl
	 -- ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
--	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	 -- ,'Authored' As [Action]
	 -- ,'Authored a Resource' As Activity

	 -- ,objct.Id as ObjectId
	 -- ,'Resource' as ObjectType
	 -- ,objct.Title as ObjectTitle
	 -- ,objct.Description as ObjectText
	 -- ,replace(replace(@ContentUrl,  '@cid',objct.Id), '@title', replace(objct.Title, ' ', '_')) As ObjectUrl
	 -- --would need to check for a version Id and use that to get the image?? or in future may have an upload
	 -- ,'' As ObjectImageUrl
	 -- ,0 as ObjectCount
	 --,0 as ObjectCount2
	 -- ,0 As HasObject

	 -- ,'' as TargetType
	 -- ,'' as TargetObjectId
	 -- ,'' as TargetTitle
	 -- ,'' as TargetText
	 -- ,'' as TargetUrl
	 -- ,'' as TargetImageUrl

  --FROM [LR.PatronOrgSummary] crby
  --inner join [Content] objct on crby.UserId = objct.CreatedById
  --where objct.[Created] >  getdate() - @HistoryDays

  order by  1  desc

GO
/****** Object:  StoredProcedure [dbo].[Activity.UnionAll]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Activity.UnionAll] 15, 2
*/
/*
Get summary of activity
Mods
- will need to 
*/
CREATE PROCEDURE [dbo].[Activity.UnionAll]
    @HistoryDays int
	,@UserId int = 0
As
Declare @LibUrl varchar(200),@CollectionUrl varchar(200),@ContentUrl varchar(200)
,@ResourceUrl varchar(200),@ResImgeUrl varchar(200)
,@CommunityUrl varchar(200),@CommImgeUrl varchar(200),@CommPostingUrl varchar(200)
,@ActorUrl varchar(200),@DefActorImageUrl varchar(200),@PdfImageUrl varchar(200)
, @LimitToUser bit

--set @UserId = 0
if @UserId is null set @UserId= 0
set @LimitToUser = 0

set @LibUrl = '/Libraries/Library.aspx?id=@lid'
set @LibUrl = '/Library/@lid/@Title'
set @CollectionUrl = '/Libraries/Library.aspx?id=@lid&col=@cid'
set @CollectionUrl = '/Library/Collection/@lid/@cid/@Title'
set @ResourceUrl = '/IOER/@rvid/@title'
set @ContentUrl = '/CONTENT/@cid/@title'
set @ResImgeUrl = '//ioer.ilsharedlearning.org/OERThumbs/thumb/@rvid-thumb.png'
set @PdfImageUrl = '//ioer.ilsharedlearning.org/images/icons/filethumbs/filethumb_pdf_200x150.png'
--prob should use guid!
set @ActorUrl = '/Profiles/default.aspx?id=@uid'
set @DefActorImageUrl = '/Images/defaultProfileImg.jpg'
--prob should use guid!
set @CommunityUrl = '/Communities/default.aspx?id=@cid'
set @CommunityUrl = '/Community/@cid/@Title'
set @CommPostingUrl = '/Community/@cid/@Title?id=@PostintId'
set @CommImgeUrl = '/Images/icons/icon_community_med.png'

-- library comments
SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Commented On' As Activity

	  ,objct.Id as ObjectId
	  ,'Comment' as ObjectType
	  ,'Comment' as ObjectTitle
	  ,objct.Comment as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Library' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  --,replace(@LibUrl, '@lid', objct.LibraryId) As TargetUrl
	  ,replace(replace(@LibUrl,  '@lid',target.Id), '@title', replace(target.Title, ' ', '_')) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.Comment] objct
  inner join (
	select libraryId, count(*) As Counts from dbo.[Library.Comment] group by libraryId) 
	As ObjectGroup on objct.LibraryId = ObjectGroup.LibraryId
  inner join [Library] target on objct.LibraryId = target.Id
  inner join[LR.PatronOrgSummary] crby on objct.CreatedById = crby.UserId
  where target.PublicAccessLevel > 1
  AND objct.[Created] >  getdate() - @HistoryDays
  UNION
  -- collection comments
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Commented On' As Activity

	  ,objct.Id as ObjectId
	  ,'Comment' as ObjectType
	  ,'Comment' as ObjectTitle
	  ,objct.Comment as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Collection' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	 -- ,replace(replace(@CollectionUrl, '@lid', target.LibraryId), '@cid', target.Id) As TargetUrl
	  ,replace(replace(replace(@CollectionUrl,  '@lid',target.LibraryId), '@title', replace(target.Title, ' ', '_')),'@cid',target.Id) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.SectionComment] objct
    inner join (
	select SectionId, count(*) As Counts from dbo.[Library.SectionComment] group by SectionId) 
	As ObjectGroup on objct.SectionId = ObjectGroup.SectionId
  inner join [Library.Section] target on objct.SectionId = target.Id
  inner join[LR.PatronOrgSummary] crby on objct.CreatedById = crby.UserId
  where target.PublicAccessLevel > 1
  AND objct.[Created] >  getdate() - @HistoryDays
  UNION
  --  library Like
  SELECT Distinct
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Liked' As Activity

  	  ,objct.Id as ObjectId
	  ,'Like' as ObjectType
	  ,'' as ObjectTitle
	  ,'' as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,LikesCrosstab.LikeCounts as ObjectCount
	  ,LikesCrosstab.DislikeCounts as ObjectCount2
	  ,case when HasRating.IsLike is null then 0 else 1 end as HasObject
	  --,isnull(HasRating.IsLike,0) As HasObject

	  ,'Library' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  	  --,replace(@LibUrl, '@lid', objct.LibraryId) As TargetUrl
	  ,replace(replace(@LibUrl,  '@lid',target.Id), '@title', replace(target.Title, ' ', '_')) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.Like] objct
  --  inner join (
		--select LibraryId, count(*) As Counts from dbo.[Library.Like] ll where ll.IsLike = 1 group by LibraryId) 
		--As ObjectGroup on objct.LibraryId = ObjectGroup.LibraryId
	inner join (
		Select LibraryId, Sum(Case Cast(IsLike As nvarchar(100)) When N'1'   Then 1 Else 0 End ) as [LikeCounts],
		Sum(Case Cast(IsLike As nvarchar(100)) When N'0'   Then 1 Else 0 End ) as [DislikeCounts] From [Library.Like]
		Group By LibraryId
	) As LikesCrosstab on  objct.LibraryId = LikesCrosstab.LibraryId
	left join [dbo].[Library.Like] HasRating  on objct.LibraryId = HasRating.LibraryId And HasRating.CreatedById = @UserId
		
	inner join [Library] target on objct.LibraryId = target.Id
	inner join[LR.PatronOrgSummary] crby on objct.CreatedById = crby.UserId
    where target.PublicAccessLevel > 1
	AND objct.[Created] >  getdate() - @HistoryDays
	AND objct.IsLike = 1
  UNION
  -- collection Like
  SELECT Distinct
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Liked' As Activity

	  ,objct.Id as ObjectId
	  ,'Like' as ObjectType
	  ,'' as ObjectTitle
	  ,'' as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,LikesCrosstab.LikeCounts as ObjectCount
	  ,LikesCrosstab.DislikeCounts as ObjectCount2
	  ,case when HasRating.IsLike is null then 0 else 1 end as HasObject
	  --,isnull(HasRating.IsLike,0) As HasObject

	  ,'Collection' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  --,replace(replace(@CollectionUrl, '@lid', target.LibraryId), '@cid', objct.SectionId) As TargetUrl
	  ,replace(replace(replace(@CollectionUrl,  '@lid',target.LibraryId), '@title', replace(target.Title, ' ', '_')),'@cid',target.Id) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.SectionLike] objct
  --  inner join (
		--select SectionId, count(*) As Counts from dbo.[Library.SectionLike] ll where ll.IsLike = 1 group by SectionId) 
		--As ObjectGroup on objct.SectionId = ObjectGroup.SectionId
	inner join (
		Select SectionId, Sum(Case Cast(IsLike As nvarchar(100)) When N'1'   Then 1 Else 0 End ) as LikeCounts,
		Sum(Case Cast(IsLike As nvarchar(100)) When N'0'   Then 1 Else 0 End ) as DislikeCounts From [Library.SectionLike]
		Group By SectionId
	) As LikesCrosstab on  objct.SectionId = LikesCrosstab.SectionId
	left join [dbo].[Library.SectionLike] HasRating  on objct.SectionId = HasRating.SectionId And HasRating.CreatedById = @UserId
  inner join [Library.Section] target on objct.SectionId = target.Id
  inner join[LR.PatronOrgSummary] crby on objct.CreatedById = crby.UserId
    where target.PublicAccessLevel > 1
  AND objct.[Created] >  getdate() - @HistoryDays
  AND objct.IsLike = 1
  UNION
   --  library follow
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.UserId As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.UserId = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Is Following' As Activity

	  ,objct.Id as ObjectId
	  ,'Following' as ObjectType
	  ,'Is Following' as ObjectTitle
	  ,'' as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Library' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  	  --,replace(@LibUrl, '@lid', objct.LibraryId) As TargetUrl
	  ,replace(replace(@LibUrl,  '@lid',target.Id), '@title', replace(target.Title, ' ', '_')) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.Subscription] objct
  inner join (
	select libraryId, count(*) As Counts from dbo.[Library.Subscription] group by libraryId) 
	As ObjectGroup on objct.LibraryId = ObjectGroup.LibraryId
  inner join [Library] target on objct.LibraryId = target.Id
  inner join[LR.PatronOrgSummary] crby on objct.UserId = crby.UserId
    where target.PublicAccessLevel > 1
  AND objct.[Created] >  getdate() - @HistoryDays
  UNION
  -- collection follow
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.UserId As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.UserId = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Is Following' As Activity

	  ,objct.Id as ObjectId
	  ,'Following' as ObjectType
	  ,'' as ObjectTitle
	  ,'' as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Collection' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  --,replace(replace(@CollectionUrl, '@lid', target.LibraryId), '@cid', objct.SectionId) As TargetUrl
	  ,replace(replace(replace(@CollectionUrl,  '@lid',target.LibraryId), '@title', replace(target.Title, ' ', '_')),'@cid',target.Id) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.SectionSubscription] objct
    inner join (
	select SectionId, count(*) As Counts from dbo.[Library.SectionSubscription] group by SectionId) 
	As ObjectGroup on objct.SectionId = ObjectGroup.SectionId
  inner join [Library.Section] target on objct.SectionId = target.Id
  inner join[LR.PatronOrgSummary] crby on objct.UserId = crby.UserId
  where target.PublicAccessLevel > 1
  AND objct.[Created] >  getdate() - @HistoryDays
  UNION
  -- library added resource
  SELECT 
		base.[Created]
      ,convert(varchar(10), base.[Created],120) as [ActivityDay]
      ,base.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when base.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Added Resource to' As Activity

	  ,res.ResourceVersionIntId as ObjectId
	  ,'Resource' as ObjectType
	  ,res.Title as ObjectTitle
	  ,res.Description as ObjectText
	  ,replace(replace(@ResourceUrl,  '@rvid',res.ResourceVersionIntId), '@title', replace(res.SortTitle, ' ', '_')) As ObjectUrl
	  ,case when Right(rtrim(lower(res.ResourceUrl)), 4) = '.pdf' then @PdfImageUrl
		else replace(@ResImgeUrl, '@rvid', res.ResourceIntId) end As ObjectImageUrl
	  ,rls.[LikeCount] as ObjectCount
	  ,rls.[DislikeCount] as ObjectCount2
	  ,0 As HasObject

	  ,'Collection' as TargetType
	  ,LibrarySectionId As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	 -- ,replace(replace(@CollectionUrl, '@lid', target.LibraryId), '@cid', target.Id) As TargetUrl
	  ,replace(replace(replace(@CollectionUrl,  '@lid',target.LibraryId), '@title', replace(target.Title, ' ', '_')),'@cid',target.Id) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library.Resource] base
  inner join [Library.Section] target on base.LibrarySectionId = target.Id
  inner join[LR.PatronOrgSummary] crby on base.CreatedById = crby.UserId
  inner join [LR.ResourceVersion_Summary] res on base.ResourceIntId = res.ResourceIntId
  left join [LR.ResourceLikesSummary] rls on base.ResourceIntId = rls.ResourceIntId

  where target.PublicAccessLevel > 1
  AND base.[Created] >  getdate() - @HistoryDays

  UNION
  ----- library: add collection
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Added Collection to' As Activity

	  ,objct.Id As ObjectTypeId
	  ,'Collection' as ObjectType
	  ,objct.Title as ObjectTitle
	  ,objct.Description as ObjectText
	  --,replace(replace(@CollectionUrl, '@lid', target.Id), '@cid', objct.Id) As ObjectUrl
	  ,replace(replace(replace(@CollectionUrl,  '@lid',target.Id), '@title', replace(objct.Title, ' ', '_')),'@cid',objct.Id) As TargetUrl
	  ,objct.ImageUrl As ObjectImageUrl
	  ,ObjectGroup.Counts as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Library' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  --,replace(@LibUrl, '@lid', target.Id) As TargetUrl
	  ,replace(replace(@LibUrl,  '@lid',target.Id), '@title', replace(target.Title, ' ', '_')) As TargetUrl
	  ,target.ImageUrl As TargetImageUrl

  FROM dbo.[Library] target
  inner join [Library.Section] objct on target.Id = objct.LibraryId
    inner join (
	select libraryId, count(*) As Counts from dbo.[Library.Section] group by libraryId) 
	As ObjectGroup on objct.LibraryId = ObjectGroup.LibraryId
  inner join[LR.PatronOrgSummary] crby on target.CreatedById = crby.UserId
  where target.PublicAccessLevel > 1
  And objct.PublicAccessLevel > 0 and objct.IsDefaultSection = 0
  AND objct.[Created] >  getdate() - @HistoryDays

   UNION
  ----- user published resource
  -- could check if target is within ioer
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,crby.UserId As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.PublishedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Published' As [Action]
	  ,'Published Resource' As Activity

	  ,res.ResourceVersionIntId as ObjectId
	  ,'Resource' as ObjectType
	  ,res.Title as ObjectTitle
	  ,res.Description as ObjectText
	  ,replace(replace(@ResourceUrl,  '@rvid',res.ResourceVersionIntId), '@title', replace(res.SortTitle, ' ', '_')) As ObjectUrl
  	  ,case when Right(rtrim(lower(res.ResourceUrl)), 4) = '.pdf' then @PdfImageUrl
		else replace(@ResImgeUrl, '@rvid', res.ResourceIntId) end As ObjectImageUrl
	  --,replace(@ResImgeUrl, '@rvid', res.ResourceIntId) As ObjectImageUrl
	  ,0 as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'' as TargetType
	  ,'' as TargetObjectId
	  ,'' as TargetTitle
	  ,'' as TargetText
	  ,'' as TargetUrl
	  ,'' as TargetImageUrl

  FROM [LR.PatronOrgSummary] crby
  inner join [Isle_IOER].[dbo].[Resource.PublishedBy] objct on crby.UserId = objct.PublishedById
  inner join [LR.ResourceVersion_Summary] res				on objct.ResourceIntId = res.ResourceIntId
  where objct.[Created] >  getdate() - @HistoryDays
  
  UNION
  -- comment on resource 
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,objct.[CreatedById] As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Commented On' As Activity

	  --object is comment
	  ,objct.Id as ObjectId
	  ,'Comment' as ObjectType
	  ,'Comment on resource' as ObjectTitle
	  ,objct.Comment as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  --exception: likes are for target, not object?
	  ,rls.[LikeCount] as ObjectCount
	  ,rls.[DislikeCount] as ObjectCount2
	  ,case when HasRating.IsLike is null then 0 else 1 end as HasObject

	  --target is resource
	  ,'Resource' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  ,replace(replace(@ResourceUrl,  '@rvid',target.ResourceVersionIntId), '@title', replace(target.SortTitle, ' ', '_')) As TargetUrl
   	  ,case when Right(rtrim(lower(target.ResourceUrl)), 4) = '.pdf' then @PdfImageUrl
		else replace(@ResImgeUrl, '@rvid', target.ResourceIntId) end As TargetImageUrl
	  --,replace(@ResImgeUrl, '@rvid', res.ResourceIntId) As TargetImageUrl

	FROM dbo.[LR.ResourceComment] objct
  inner join dbo.[Library.Resource] base	on objct.ResourceIntId = base.ResourceIntId
  inner join [Library.Section] ls			on base.LibrarySectionId = ls.Id
  inner join [Library] lib					on ls.LibraryId = lib.Id
  inner join[LR.PatronOrgSummary] crby		on objct.CreatedById = crby.UserId
  inner join [LR.ResourceVersion_Summary] target on base.ResourceIntId = target.ResourceIntId
  left join [LR.ResourceLikesSummary] rls on base.ResourceIntId = rls.ResourceIntId
  left join [dbo].[LR.ResourceLike] HasRating  on base.ResourceIntId = HasRating.[ResourceIntId] And HasRating.CreatedById = @UserId
  
    where base.[Created] >  getdate() - @HistoryDays

   UNION
  ----- user posts to community
  SELECT 
		objct.[Created]
      ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
      ,crby.UserId As ActorId
	  ,crby.FullName As Actor
	  ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	  ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	  ,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	  ,'Added' As [Action]
	  ,'Posted To' As Activity

	 ,objct.Id as ObjectId
	  ,'CommunityPosting' as ObjectType
	  ,'Community Posting' as ObjectTitle
	  ,objct.Message as ObjectText
	  ,'' As ObjectUrl
	  ,'' As ObjectImageUrl
	  ,0 as ObjectCount
	  ,0 as ObjectCount2
	  ,0 As HasObject

	  ,'Community' as TargetType
	  ,target.Id As TargetObjectId
	  ,target.Title as TargetTitle
	  ,target.Description as TargetText
	  --,replace(@CommunityUrl, '@cid', target.Id) As TargetUrl
	  ,replace(replace(@CommunityUrl,  '@cid',target.Id), '@title', replace(target.Title, ' ', '_')) As TargetUrl
	  ,@CommImgeUrl As TargetImageUrl

  FROM [LR.PatronOrgSummary] crby
  inner join [dbo].[Community.Posting] objct	on crby.UserId = objct.CreatedById
  inner join [Community] target					on objct.CommunityId = target.Id
  where objct.[Created] >  getdate() - @HistoryDays
          
  --- user authored resource
  --	skip for now, will catch for publish, would have to check status
  --UNION
  --SELECT 
		--objct.[Created]
  --    ,convert(varchar(10), objct.[Created],120) as [ActivityDay]
  --    ,crby.UserId As ActorId
	 -- ,crby.FullName As Actor
	 -- ,case when crby.ImageUrl is null then @DefActorImageUrl else crby.ImageUrl end As ActorImageUrl
	 -- ,replace(@ActorUrl, '@uid', crby.UserRowId) As ActorUrl
	 --,case when objct.CreatedById = @UserId then 1 else 0 end as IsMyAction

	 -- ,'Authored' As [Action]
	 -- ,'Authored a Resource' As Activity

	 -- ,objct.Id as ObjectId
	 -- ,'Resource' as ObjectType
	 -- ,objct.Title as ObjectTitle
	 -- ,objct.Summary as ObjectText
	 -- ,replace(replace(@ContentUrl,  '@cid',objct.Id), '@title', replace(objct.Title, ' ', '_')) As ObjectUrl
	 -- --would need to check for a version Id and use that to get the image?? or in future may have an upload
	 -- ,'' As ObjectImageUrl
	 -- ,0 as ObjectCount
	 -- ,0 as ObjectCount2
	 -- ,0 As HasObject

	 -- ,'' as TargetType
	 -- ,'' as TargetObjectId
	 -- ,'' as TargetTitle
	 -- ,'' as TargetText
	 -- ,'' as TargetUrl
	 -- ,'' as TargetImageUrl

  --FROM [LR.PatronOrgSummary] crby
  --inner join [Content] objct on crby.UserId = objct.CreatedById
  --where objct.[Created] >  getdate() - @HistoryDays

  order by  1  desc

GO
/****** Object:  StoredProcedure [dbo].[ActivityLogInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
--- Insert Procedure for ActivityLog---

CREATE PROCEDURE [dbo].[ActivityLogInsert]
        @ActivityType varchar(25), 
        @Activity     varchar(75), 
        @Event        varchar(75), 
        @Comment      varchar(500) 
        ,@TargetUserId      int
        ,@ActivityObjectId      int 
        ,@ActionByUserId      int 
        ,@Integer2      int
As
If @ActivityType = ''   SET @ActivityType = 'audit' 
If @Activity  = ''      SET @Activity  = 'Unknown'  
If @Event = ''          SET @Event = NULL 
If @Comment = ''        SET @Comment = NULL 
If @TargetUserId = 0          SET @TargetUserId = NULL 
If @ActivityObjectId = 0          SET @ActivityObjectId = NULL 
If @ActionByUserId = 0          SET @ActionByUserId = NULL 
If @Integer2 = 0          SET @Integer2 = NULL 

INSERT INTO ActivityLog
(
    CreatedDate, 
    ActivityType, 
    Activity, 
    Event, 
    Comment, 
    TargetUserId 
    ,ActivityObjectId 
    ,ActionByUserId 
    ,Int2
)
Values (

    getdate(), 
    @ActivityType, 
    @Activity, 
    @Event, 
    @Comment 
    ,@TargetUserId 
    ,@ActivityObjectId
    ,@ActionByUserId 
    ,@Integer2
)
 
select SCOPE_IDENTITY() As Id


GO
/****** Object:  StoredProcedure [dbo].[aspCreateProcedure_Delete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Exec aspCreateProcedure_Delete 'Contact', 1

Exec aspCreateProcedure_Delete 'Contact', 1, 0, 'pre', '_suf', 'DeleteName', 'GrantToMtce'

Exec aspCreateProcedure_Delete 'WiaContract.Action', 1, 0, '', '_Delete','', 'GrantToMtce'
*/
-- =========================================================================
-- 12/09/13 mparsons - updated to handle tables with dot notation (ex.Policy.Version)
-- =========================================================================
CREATE  Procedure [dbo].[aspCreateProcedure_Delete]
		@tableName 		varchar(128) 
		,@print 		bit 
		,@tableFirst	bit = 1
		,@Prefix		varchar(20) = '' 
		,@Suffix		varchar(20) = '' 
		,@ProcName		varchar(128) = 'Delete' 
		,@GrantGroup	varchar(128) = '' 
AS

Declare 
	@SQLStatement 		varchar(8000), --Actual Delete Procedure string
	@parameters 		varchar(8000), -- Parameters to be passed to the Stored Procedure
	@deleteStatement 	varchar(8000), -- To Store the Delete SQL Statement
	@procedurename 		varchar(128), -- To store the procedure name
	@DropProcedure 		varchar(1000), --Drop procedure sql statement
	@GrantProcedure 	varchar(1000) 	--To Store Grant execute Procedure SQL Statement

-- Initialize Variables
SET @parameters = ''
SET @deleteStatement = ''

--Get Parameters and Delete Where Clause needed for the Delete Procedure.
SELECT	@parameters = @parameters + 
			Case When @parameters = '' Then ''
					Else ', ' + Char(13) + Char(10) 
					End + '        @' + + INFORMATION_SCHEMA.Columns.COLUMN_NAME + ' ' + 
					DATA_TYPE + 
					Case When CHARACTER_MAXIMUM_LENGTH is not null Then 
						'(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(4)) + ')' 
						Else '' 
					End,
	@deleteStatement = @deleteStatement + Case When @deleteStatement = '' Then ''
					Else ' AND ' + Char(13) + Char(10) 
					End + INFORMATION_SCHEMA.Columns.COLUMN_NAME + ' = @' + + INFORMATION_SCHEMA.Columns.COLUMN_NAME
FROM	
	INFORMATION_SCHEMA.Columns,
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS,
	INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
WHERE 	INFORMATION_SCHEMA.TABLE_CONSTRAINTS.CONSTRAINT_NAME = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.CONSTRAINT_NAME AND
	INFORMATION_SCHEMA.Columns.Column_name = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.Column_name AND
	INFORMATION_SCHEMA.Columns.table_name = INFORMATION_SCHEMA.TABLE_CONSTRAINTS.TABLE_NAME AND
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS.table_name = @tableName AND 
	CONSTRAINT_TYPE = 'PRIMARY KEY'

-- the following logic can be changed as per your standards. 
SET @procedurename = @ProcName	--'Delete'

If @tableFirst = 1 Begin
	-- Use syntax of prefix + TableName + ProcedureType + Suffix
	--	ex.	ContactSelect, uspContactSelect, ContactSelect_usp
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix +  + SubString(@tableName, 4, Len(@tableName))  + @procedurename  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @tableName + @procedurename  + @Suffix
	End
End
Else Begin
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix + @procedurename + SubString(@tableName, 4, Len(@tableName))  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @procedurename + @tableName + @Suffix
	End
End


--Stores DROP Procedure Statement
SET @DropProcedure = 'if exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[' + @procedurename + ']'') and OBJECTPROPERTY(id, N''IsProcedure'') = 1)' + Char(13) + Char(10) +
				'Drop Procedure [' + @procedurename + ']'

--Stores grant procedure statement
if len(@GrantGroup) > 0 
	SET @GrantProcedure = 'grant execute on [' + @procedurename + ']  to ' + @GrantGroup
Else
	SET @GrantProcedure = ''

-- In case you want to create the procedure pass in 0 for @print else pass in 1 and stored procedure will be displayed in results pane.
If @print = 0
Begin
	-- Create the final procedure and store it..
	Exec (@DropProcedure)
	SET @SQLStatement = 'CREATE PROCEDURE [' + @procedurename + '] ' +  Char(13) + Char(10) + @parameters + Char(13) + Char(10) + ' AS ' + 
				 + Char(13) + Char(10) + ' Delete FROM [' + @tableName + '] ' + ' WHERE ' + @deleteStatement + Char(13) + Char(10) 

	-- Execute the SQL Statement to create the procedure
	--Print @SQLStatement
	Exec (@SQLStatement)

	-- Do the grant
	if len(@GrantProcedure) > 0 Begin
		Exec (@GrantProcedure)
	End	
End
Else
Begin
	--Print the Procedure to Results pane
	Print ''
	Print ''
	Print ''
	Print '--- Delete Procedure for [' + @tableName + '] ---'
	Print @DropProcedure
	Print 'GO'
	Print 'CREATE PROCEDURE [' + @procedurename + ']'
	Print @parameters
	Print 'As'
	Print 'DELETE FROM [' + @tableName + ']'
	Print 'WHERE ' + @deleteStatement
	Print 'GO'
	Print @GrantProcedure
	Print 'Go'
End



GO
/****** Object:  StoredProcedure [dbo].[aspCreateProcedure_Get]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
Exec aspCreateProcedure_Get 'Contact', 1

Exec aspCreateProcedure_Get 'Contact', 1, 0, 'pre', 'suf', 'GetName'

Exec aspCreateProcedure_Get 'WiaContract.Action', 1, 0, '', '_Select', ''
*/
-- =========================================================================
-- 12/09/13 mparsons - updated to handle tables with dot notation (ex.Policy.Version)
-- =========================================================================
CREATE  Procedure [dbo].[aspCreateProcedure_Get] 
		@tableName 		varchar(128) 
		,@print 		bit 
		,@tableFirst	bit = 1
		,@Prefix		varchar(20) = '' 
		,@Suffix		varchar(20) = '' 
		,@ProcName		varchar(128) = 'Select' 

AS

Declare 
	@SQLStatement 		varchar(8000), 	--Actual Get Procedure string
	@SelectStatement 	varchar(8000), 	--Actual Select Statement that returns result set.
	@procedurename 		varchar(128), 	-- To store the procedure name
	@DropProcedure 		varchar(1000), --To Store Drop Procedure SQL Statement
	@GrantProcedure 	varchar(1000) 	--To Store Grant execute Procedure SQL Statement

SET @SelectStatement = ''

-- Get Columns from the table to be displayed.
SELECT @SelectStatement = @SelectStatement + 
				Case When @SelectStatement = '' Then ''  + Char(13) + Char(10) 
					Else ', ' + Char(13) + Char(10) 
				End + '    ' + COLUMN_NAME
FROM INFORMATION_SCHEMA.Columns
WHERE	table_name = @tableName

-- the following logic can be changed as per your standards. In our case tbl is for tables and tlkp is for lookup tables. Needed to remove tbl and tlkp...
SET @procedurename = @ProcName	--'Select'

If @tableFirst = 1 Begin
	-- Use syntax of prefix + TableName + ProcedureType + Suffix
	--	ex.	ContactSelect, uspContactSelect, ContactSelect_usp
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix +  + SubString(@tableName, 4, Len(@tableName))  + @procedurename  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @tableName + @procedurename  + @Suffix
	End
End
Else Begin
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix + @procedurename + SubString(@tableName, 4, Len(@tableName))  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @procedurename + @tableName + @Suffix
	End
End

--Stores DROP Procedure Statement
SET @DropProcedure = 'if exists (select * from dbo.sysobjects where id = object_id(N''[' + @procedurename + ']'') and OBJECTPROPERTY(id, N''IsProcedure'') = 1)' + Char(13) + Char(10) +
				'Drop Procedure [' + @procedurename + ']'

--Stores grant procedure statement
SET @GrantProcedure = 'grant execute on [' + @procedurename + '] to public ' 

-- In case you want to create the procedure pass in 0 for @print else pass in 1 and stored procedure will be displayed in results pane.
If @print = 0
Begin
	-- Drop the current procedure.
	Exec (@DropProcedure)
	-- Create the final procedure and store it..
	SET @SQLStatement = 	
				'CREATE PROCEDURE [' + @procedurename + '] ' +  Char(13) + Char(10) + ' AS ' + Char(13) + Char(10) +
				'SELECT ' + @SelectStatement + Char(13) + Char(10) + 
				'FROM [' + @tableName + '] ' + Char(13) + Char(10) 

	-- Execute the SQL Statement to create the procedure	
	Exec (@SQLStatement)
	-- Do the egrant
	Exec (@GrantProcedure)
End
Else
Begin
	--Print the Procedure to Results pane
	Print ''
	Print ''
	Print ''
	Print '--- Get Procedure for [' + @tableName + '] ---'
	Print @DropProcedure
	Print 'Go'
	Print 'CREATE PROCEDURE [' + @procedurename + ']'
	Print 'As'
	Print 'SELECT ' + @SelectStatement 
	Print 'FROM [' + @tableName + ']'
	Print 'GO'
	Print @GrantProcedure
	Print 'Go'
End



GO
/****** Object:  StoredProcedure [dbo].[aspCreateProcedure_GetSingle]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
Exec aspCreateProcedure_GetSingle 'WiaContract.Action', 1

Exec aspCreateProcedure_GetSingle 'WiaContract.Action', 1, 0, 'pre', '_suf', 'GetSingle', 'GrantToPublic'

Exec aspCreateProcedure_GetSingle 'WiaContract.Action', 1, 0, '', '_Select', '', 'GrantToPublic'
*/
-- =========================================================================
-- 12/09/13 mparsons - updated to handle tables with dot notation (ex.Policy.Version)
-- =========================================================================
CREATE   Procedure [dbo].[aspCreateProcedure_GetSingle] 
		@tableName 		varchar(128) 
		,@print 		bit 
		,@tableFirst	bit = 1
		,@Prefix		varchar(20) = '' 
		,@Suffix		varchar(20) = '' 
		,@ProcName		varchar(128) = 'Get' 
		,@GrantGroup	varchar(128) = '' 
AS

Declare @SQLStatement varchar(8000), 	-- Actual GetSingle Procedure string
	@parameters varchar(8000), 			-- To store parameter list.
	@SelectStatement varchar(8000), 	-- Actual Select Statement that returns result set.
	@WhereStatement varchar(8000), 		-- Where clause to pick the single record
	@procedurename varchar(128), 		-- To store the procedure name
	@DropProcedure 		varchar(1000), -- Drop procedure sql statement
	@GrantProcedure 	varchar(1000) 	-- To Store Grant execute Procedure SQL Statement

SET @parameters = ''
SET @SelectStatement = ''
SET @WhereStatement = ''

--Build parameter list and where clause
SELECT	@parameters = @parameters + Case When @parameters = '' Then ''
					Else ', ' + Char(13) + Char(10) 
					End + '    @' + INFORMATION_SCHEMA.Columns.COLUMN_NAME + ' ' + 
					DATA_TYPE + 
					Case When CHARACTER_MAXIMUM_LENGTH is not null Then 
						'(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(4)) + ')' 
						Else '' 
					End,
	@WhereStatement = @WhereStatement + Case When @WhereStatement = '' Then ''
					Else ' AND ' + Char(13) + Char(10) 
					End + INFORMATION_SCHEMA.Columns.COLUMN_NAME + ' = @' + + INFORMATION_SCHEMA.Columns.COLUMN_NAME
FROM	
	INFORMATION_SCHEMA.Columns,
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS,
	INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
WHERE 	
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS.CONSTRAINT_NAME = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.CONSTRAINT_NAME AND
	INFORMATION_SCHEMA.Columns.Column_name = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.Column_name AND
	INFORMATION_SCHEMA.Columns.table_name = INFORMATION_SCHEMA.TABLE_CONSTRAINTS.TABLE_NAME AND
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS.table_name = @tableName AND 
	CONSTRAINT_TYPE = 'PRIMARY KEY'

--Store column names from the select statement
SELECT	@SelectStatement = @SelectStatement + Case When @SelectStatement = '' Then ''
					Else ', ' + Char(13) + Char(10) 
					End + '    ' + COLUMN_NAME
FROM	INFORMATION_SCHEMA.Columns
WHERE	table_name = @tableName

-- the following logic can be changed as per your standards. 
SET @procedurename = @ProcName	--'GetSingle'

If @tableFirst = 1 Begin
	-- Use syntax of prefix + TableName + ProcedureType + Suffix
	--	ex.	ContactSelect, uspContactSelect, ContactSelect_usp
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix +  + SubString(@tableName, 4, Len(@tableName))  + @procedurename  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @tableName + @procedurename  + @Suffix
	End
End
Else Begin
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix + @procedurename + SubString(@tableName, 4, Len(@tableName))  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @procedurename + @tableName + @Suffix
	End
End

--Stores DROP Procedure Statement
SET @DropProcedure = 'if exists (select * from dbo.sysobjects where id = object_id(N''[' + @procedurename + ']'') and OBJECTPROPERTY(id, N''IsProcedure'') = 1)' + Char(13) + Char(10) +
					'Drop Procedure [' + @procedurename + ']'

--Stores grant procedure statement
if len(@GrantGroup) > 0 
	SET @GrantProcedure = 'grant execute on [' + @procedurename + '] to ' + @GrantGroup
Else
	SET @GrantProcedure = ''

-- In case you want to create the procedure pass in 0 for @print else pass in 1 and stored procedure will be displayed in results pane.
If @print = 0
Begin
	-- Drop the current procedure.
	Exec (@DropProcedure)
	-- Create the final procedure and store it..	
	SET @SQLStatement = 'CREATE PROCEDURE [' + @procedurename + '] ' +  Char(13) + Char(10) + @parameters + Char(13) + Char(10) + ' AS ' + 
				'SELECT ' + @SelectStatement + Char(13) + Char(10) + 
				'FROM [' + @tableName + '] ' + Char(13) + Char(10) +
				'WHERE ' + @WhereStatement
	-- Execute the SQL Statement to create the procedure
	Exec(@SQLStatement)

	-- Do the grant
	if len(@GrantProcedure) > 0 Begin
		Exec (@GrantProcedure)
	End	
End
Else
Begin
	--Print the Procedure to Results pane
	Print ''
	Print ''
	Print ''
	Print '--- Get Single Procedure for [' + @tableName + '] ---'
	Print @DropProcedure
	Print 'Go'
	Print 'CREATE PROCEDURE [' + @procedurename + ']'
	Print @parameters
	Print 'As'
	Print 'SELECT ' + @SelectStatement 
	Print 'FROM [' + @tableName + ']'
	Print 'WHERE ' + @WhereStatement
	Print 'GO'
	Print @GrantProcedure
	Print 'Go'
End




GO
/****** Object:  StoredProcedure [dbo].[aspCreateProcedure_Insert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/****** Object:  Stored Procedure dbo.aspCreateProcedure_Insert    Script Date: 7/8/2005 11:16:33 AM ******/
/*
Exec aspCreateProcedure_Insert 'Building', 0
Exec aspCreateProcedure_Insert 'Contact', 1

Exec aspCreateProcedure_Insert 'Contact', 1, 0, 'pre', 'suf', 'CreateName', 'GrantToMtce'

Exec aspCreateProcedure_Insert 'WiaContract.Action', 1, 0, '', '_Insert', '', 'GrantToMtce'

*/
-- =========================================================================
-- 08/05/28 mparsons - added code to handle varchar(MAX) - length is equal to -1 in CHARACTER_MAXIMUM_LENGTH
-- 12/09/13 mparsons - updated to handle tables with dot notation (ex.Policy.Version)
-- =========================================================================
CREATE   Procedure [dbo].[aspCreateProcedure_Insert]
		@tableName 		varchar(128) 
		,@print 		bit 
		,@tableFirst	bit = 1
		,@Prefix		varchar(20) = '' 
		,@Suffix		varchar(20) = '' 
		,@ProcName		varchar(128) = 'Insert' 
		,@GrantGroup		varchar(128) = '' 
AS

-- =============================================================
-- = TODO
-- =	- consider trying to handle nullable fields on input parms 
-- =	  (i.e. default to null, so don't have to be provided)
-- =
-- =============================================================
Declare 
	@SQLStatement 		varchar(8000), --Actual Delete Procedure string
	@parameters 		varchar(8000), -- Parameters to be passed to the Stored Procedure
	@InsertStatement 	varchar(8000), --To store Insert Clause.
	@ValuesStatement 	varchar(8000), -- To store Values Clause
	@NullStatement 		varchar(8000), --To store special handling of null values.
	@procedurename 		varchar(128), -- To store the procedure name
	@DropProcedure 		varchar(1000), --Drop procedure sql statement
	@GrantProcedure 	varchar(1000) 	--To Store Grant execute Procedure SQL Statement
	--TODO add process to do a grant - ex to a passed role
	,@KeyCount			int

-- Initialize Variables
SET @parameters = ''
SET @InsertStatement = ''
SET @ValuesStatement = ''
SET @NullStatement = ''

-- Do check for multiple primary key columns
SELECT @KeyCount = count(*) 
			FROM 	INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
				JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE 
					ON INFORMATION_SCHEMA.TABLE_CONSTRAINTS.CONSTRAINT_NAME = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.CONSTRAINT_NAME
			WHERE	
-- 				INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.COLUMN_NAME = INFORMATION_SCHEMA.Columns.COLUMN_NAME 
-- 			AND	
				INFORMATION_SCHEMA.TABLE_CONSTRAINTS.table_name = @tableName 
			AND CONSTRAINT_TYPE = 'PRIMARY KEY'

if @KeyCount > 1 begin
	print '******************************************************************'
	print '  Warning requested table has multiple primary keys. '
	print '  You may need to manually add these to the create procedure if  '
	print '  they are not of the autogenerate type!				'
	print '******************************************************************'
end

-- Get Parameters, insert, values and Null statements.

SELECT	@parameters = @parameters + 
		Case When @parameters = '' Then '    ' 
			Else ', ' + Char(13) + Char(10) + '    ' 
			End + '        @' + + INFORMATION_SCHEMA.Columns.COLUMN_NAME + ' ' + 
			DATA_TYPE + 
			Case 
				When CHARACTER_MAXIMUM_LENGTH = -1 Then 
					'(MAX)' 
				When CHARACTER_MAXIMUM_LENGTH is not null Then 
					'(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(4)) + ')' 
				Else '' 
			End,
	@InsertStatement = @InsertStatement + 
		Case When @InsertStatement = '' Then ''
			Else ', ' 
			End + Char(13) + Char(10) + '    ' +
			COLUMN_NAME,
	@ValuesStatement = @ValuesStatement + Case When @ValuesStatement = '' Then ''
			Else ', ' 
			End + Char(13) + Char(10) + '    @' +
			COLUMN_NAME,
	@NullStatement = @NullStatement + Case When @NullStatement = '' Then '' 
			Else Char(13) + Char(10)
			End + 
			CASE WHEN DATA_TYPE = 'int' OR DATA_TYPE = 'smallint' OR 
				DATA_TYPE = 'tinyint' OR DATA_TYPE = 'real' OR 
				DATA_TYPE = 'float' OR DATA_TYPE = 'decimal' OR 
				DATA_TYPE = 'bit' OR DATA_TYPE = 'numeric' OR DATA_TYPE = 'bigint' Then 
				'If @' + COLUMN_NAME + ' = 0 ' 
			Else 
				'If @' + COLUMN_NAME + ' = '''' ' 
			End + '  SET @' + COLUMN_NAME + ' = NULL '
--  select *
FROM	
	INFORMATION_SCHEMA.Columns
WHERE	
	table_name = @tableName AND 
	NOT EXISTS(SELECT * 
			FROM 	INFORMATION_SCHEMA.TABLE_CONSTRAINTS JOIN
				INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ON INFORMATION_SCHEMA.TABLE_CONSTRAINTS.CONSTRAINT_NAME = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.CONSTRAINT_NAME
			WHERE	INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.COLUMN_NAME = INFORMATION_SCHEMA.Columns.COLUMN_NAME AND
				INFORMATION_SCHEMA.TABLE_CONSTRAINTS.table_name = @tableName AND 
				CONSTRAINT_TYPE = 'PRIMARY KEY')
				
-- the following logic can be changed as per your standards. In our case tbl is for tables and tlkp is for lookup tables. Needed to remove tbl and tlkp...
SET @procedurename = @ProcName	--'Create'

If @tableFirst = 1 Begin
	-- Use syntax of prefix + TableName + ProcedureType + Suffix
	--	ex.	ContactSelect, uspContactSelect, ContactSelect_usp
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix +  + SubString(@tableName, 4, Len(@tableName))  + @procedurename  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @tableName + @procedurename  + @Suffix
	End
End
Else Begin
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix + @procedurename + SubString(@tableName, 4, Len(@tableName))  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @procedurename + @tableName + @Suffix
	End
End

--Stores DROP Procedure Statement
SET @DropProcedure = 'if exists (select * from dbo.sysobjects where id = object_id(N''[' + @procedurename + ']'') and OBJECTPROPERTY(id, N''IsProcedure'') = 1)' + Char(13) + Char(10) +
				'Drop Procedure [' + @procedurename + ']'

--Stores grant procedure statement
if len(@GrantGroup) > 0 
	SET @GrantProcedure = 'grant execute on [' + @procedurename + '] to ' + @GrantGroup
Else
	SET @GrantProcedure = ''

-- In case you want to create the procedure pass in 0 for @print else pass in 1 and stored procedure will be displayed in results pane.
If @print = 0
Begin
	--print 'Doing drop'
	-- Drop the current procedure.
	Exec (@DropProcedure)
	--print 'Doing create'
	-- Create the final procedure 
	SET @SQLStatement = 'CREATE PROCEDURE [' + @procedurename + '] ' +  Char(13) + Char(10) + @parameters + Char(13) + Char(10) + 'AS' + Char(13) + Char(10) +
				@NullStatement + Char(13) + Char(10) + 'INSERT INTO [' + @tableName + '] (' + @InsertStatement + ')' + Char(13) + Char(10) + 
				'Values (' + @ValuesStatement + ')' + Char(13) + Char(10) + 'select SCOPE_IDENTITY()'
	--print str(len(@SQLStatement)) + @SQLStatement 
	-- Execute the SQL Statement to create the procedure
	Exec(@SQLStatement)

	-- Do the grant
	if len(@GrantProcedure) > 0 Begin
		Exec (@GrantProcedure)
	End	

End
Else
Begin
	--Print the Procedure to Results pane
	Print ''
	Print ''
	Print ''
	Print '--- Insert Procedure for [' + @tableName + '] ---'
	Print @DropProcedure
	Print 'Go'
	Print 'CREATE PROCEDURE [' + @procedurename + ']'
	Print @parameters
	Print 'As'
	Print @NullStatement
	Print 'INSERT INTO [' + @tableName + '] ('
	Print @InsertStatement
	Print ')'
	Print 'Values ('
	Print @ValuesStatement
	Print ')'
	Print ''
	Print 'select SCOPE_IDENTITY() as Id'
	Print 'GO'
	Print @GrantProcedure
	Print 'Go'
End




GO
/****** Object:  StoredProcedure [dbo].[aspCreateProcedure_Update]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
Exec aspCreateProcedure_Update 'Contact', 1

Exec aspCreateProcedure_Update 'Contact', 1, 0, '', '_usp', 'Update', 'GrantToMtce'

Exec aspCreateProcedure_Update 'WiaContract.Action', 1, 0, '', '_Insert', '', 'GrantToMtce'
*/
-- =========================================================================
-- 08/05/28 mparsons - added code to handle varchar(MAX) - length is equal to -1 in CHARACTER_MAXIMUM_LENGTH
-- 12/09/13 mparsons - updated to handle tables with dot notation (ex.Policy.Version)
-- =========================================================================
CREATE  Procedure [dbo].[aspCreateProcedure_Update] 
		@tableName 		varchar(128) 
		,@print 		bit 
		,@tableFirst	bit = 1
		,@Prefix		varchar(20) = '' 
		,@Suffix		varchar(20) = '' 
		,@ProcName		varchar(128) = 'Update' 
		,@GrantGroup	varchar(128) = '' 
AS
-- =============================================================
-- = TODO
-- =	- consider trying to handle nullable fields on input parms 
-- =	  (i.e. default to null, so don't have to be provided)
-- =
-- =============================================================
Declare 
	@SQLStatement 		varchar(8000), --Actual Delete Procedure string
	@parameters 		varchar(8000), -- Parameters to be passed to the Stored Procedure
	@updateStatement 	varchar(8000), -- To Store the update SQL Statement
	@NullStatement 		varchar(8000), -- To Store Null handling for null allowed columns.
	@procedurename 		varchar(128), -- To store the procedure name
	@WhereClause 		varchar(8000), -- To Store Where clause information for the update statement.
	@DropProcedure 		varchar(1000), --Drop procedure sql statement
	@GrantProcedure 	varchar(1000) 	--To Store Grant execute Procedure SQL Statement
	--TODO add process to do a grant - ex to a passed role

-- Initialize Variables
SET @parameters = ''
SET @updateStatement = ''
SET @NullStatement = ''
SET @WhereClause = ''
SET @DropProcedure = ''

-- Build Parameters, Update and Null Statements

SELECT	@parameters = @parameters + Case When @parameters = '' Then ''
					Else ', ' + Char(13) + Char(10) 
					End + '        @' + + INFORMATION_SCHEMA.Columns.COLUMN_NAME + ' ' + 
					DATA_TYPE + 
					Case 
						When CHARACTER_MAXIMUM_LENGTH = -1 Then 
							'(MAX)' 
						When CHARACTER_MAXIMUM_LENGTH is not null Then 
						'(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(4)) + ')' 
						Else '' 
					End,
	@updateStatement = @updateStatement + Case When @updateStatement = '' Then ''
					Else ', ' 
					End + Char(13) + Char(10) + '    ' + COLUMN_NAME + ' = @' +
					COLUMN_NAME,
	@NullStatement = @NullStatement + Case When @NullStatement = '' Then '' 
					Else Char(13) + Char(10)
					End + 
					CASE WHEN DATA_TYPE = 'int' OR DATA_TYPE = 'smallint' OR 
						DATA_TYPE = 'tinyint' OR DATA_TYPE = 'real' OR 
						DATA_TYPE = 'float' OR DATA_TYPE = 'decimal' OR 
						DATA_TYPE = 'bit' OR DATA_TYPE = 'numeric' OR DATA_TYPE = 'bigint' Then 
						'If @' + COLUMN_NAME + ' = 0 ' 
					Else 
						'If @' + COLUMN_NAME + ' = '''' ' 
					End + '  SET @' + COLUMN_NAME + ' = NULL '
FROM	
	INFORMATION_SCHEMA.Columns
WHERE	
	table_name = @tableName AND 
	NOT EXISTS(SELECT * 
			FROM 	INFORMATION_SCHEMA.TABLE_CONSTRAINTS JOIN
				INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ON INFORMATION_SCHEMA.TABLE_CONSTRAINTS.CONSTRAINT_NAME = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.CONSTRAINT_NAME
			WHERE	INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.COLUMN_NAME = INFORMATION_SCHEMA.Columns.COLUMN_NAME AND
				INFORMATION_SCHEMA.TABLE_CONSTRAINTS.table_name = @tableName AND 
				CONSTRAINT_TYPE = 'PRIMARY KEY')

-- Build Parameters and Where Clause with Primary key

SELECT	@parameters = @parameters + Case When @parameters = '' Then ''
					Else ', ' + Char(13) + Char(10) 
					End + '@' + + INFORMATION_SCHEMA.Columns.COLUMN_NAME + ' ' + 
					DATA_TYPE + 
					Case When CHARACTER_MAXIMUM_LENGTH is not null Then 
						'(' + Cast(CHARACTER_MAXIMUM_LENGTH as varchar(4)) + ')' 
						Else '' 
					End,
	@WhereClause = @WhereClause + Case When @WhereClause = '' Then ''
					Else ' AND ' + Char(13) + Char(10) 
					End + INFORMATION_SCHEMA.Columns.COLUMN_NAME + ' = @' + + INFORMATION_SCHEMA.Columns.COLUMN_NAME
FROM	
	INFORMATION_SCHEMA.Columns,
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS,
	INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE
WHERE 	
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS.CONSTRAINT_NAME = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.CONSTRAINT_NAME AND
	INFORMATION_SCHEMA.Columns.Column_name = INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE.Column_name AND
	INFORMATION_SCHEMA.Columns.table_name = INFORMATION_SCHEMA.TABLE_CONSTRAINTS.TABLE_NAME AND
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS.table_name = @tableName AND 
	CONSTRAINT_TYPE = 'PRIMARY KEY'

-- the following logic can be changed as per your standards. 
SET @procedurename = @ProcName	--'Update'

If @tableFirst = 1 Begin
	-- Use syntax of prefix + TableName + ProcedureType + Suffix
	--	ex.	ContactSelect, uspContactSelect, ContactSelect_usp
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix +  + SubString(@tableName, 4, Len(@tableName))  + @procedurename  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @tableName + @procedurename  + @Suffix
	End
End
Else Begin
	If Left(@tableName, 3) = 'tbl' Begin
		SET @procedurename = @Prefix + @procedurename + SubString(@tableName, 4, Len(@tableName))  + @Suffix
	End
	Else Begin
		-- In case none of the above standards are followed then just get the table name.
		SET @procedurename = @Prefix + @procedurename + @tableName + @Suffix
	End
End


--Stores DROP Procedure Statement
SET @DropProcedure = 'if exists (select * from dbo.sysobjects where id = object_id(N''[' + @procedurename + ']'') and OBJECTPROPERTY(id, N''IsProcedure'') = 1)' + Char(13) + Char(10) +
				'Drop Procedure [' + @procedurename + ']'

--Stores grant procedure statement
if len(@GrantGroup) > 0 
	SET @GrantProcedure = 'grant execute on [' + @procedurename + '] to ' + @GrantGroup
Else
	SET @GrantProcedure = ''

If @print = 0
Begin
	-- Drop the current procedure.
	Exec (@DropProcedure)
	-- Create the final procedure 
	SET @SQLStatement = 'CREATE PROCEDURE [' + @procedurename + '] ' +  Char(13) + Char(10) + @parameters + Char(13) + Char(10) + 'AS ' + Char(13) + Char(10) +
				@NullStatement + Char(13) + Char(10) + 'Update ' + @tableName + '] ' + Char(13) + Char(10) + 'SET ' + @UpdateStatement + Char(13) + Char(10) +
				'WHERE ' + @WhereClause
	-- Execute the SQL Statement to create the procedure
	--Print @SQLStatement
	Exec (@SQLStatement)

	-- Do the grant
	if len(@GrantProcedure) > 0 Begin
		Exec (@GrantProcedure)
	End	

End
Else
Begin
	--Print the Procedure to Results pane
	Print ''
	Print ''
	Print ''
	Print @DropProcedure
	Print 'Go'
	Print '--- Update Procedure for [' + @tableName + '] ---'
	Print 'CREATE PROCEDURE [' + @procedurename + ']'
	Print @parameters
	Print 'As'
	Print @NullStatement
	Print 'UPDATE [' + @tableName + '] '
	Print 'SET ' + @UpdateStatement
	Print 'WHERE ' + @WhereClause
	Print 'GO'
	Print @GrantProcedure
	Print 'Go'
End



GO
/****** Object:  StoredProcedure [dbo].[aspCreateProcedures]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

exec aspCreateProcedures 1,1,1,1,1,'|Resource.GroupType|',1,'public'

exec aspCreateProcedures 1,1,1,1,1,'|GroupTeamMember|',1,'public'

exec aspCreateProcedures 1,1,1,1,1,'|Contact|',1,'public'
exec aspCreateProcedures 1,1,1,1,1,'|Organization|',1,'public'
exec aspCreateProcedures 1,1,1,1,1,'|Apartment|',0,'public'

exec aspCreateProcedures 1,1,1,1,1,'|SiteLandlord|',0,'public'

Exec aspCreateProcedure_Insert 'Building', 0
Exec aspCreateProcedure_Update 'Building', 0

Exec aspCreateProcedure_Get 'Contact', 1
Exec aspCreateProcedure_GetSingle 'Contact', 1

Exec aspCreateProcedure_Insert 'Contact', 0
Exec aspCreateProcedure_Update 'Contact', 0
Exec aspCreateProcedure_Delete 'Contact', 1
*/

CREATE   PROCEDURE [dbo].[aspCreateProcedures] 
	@insertProc 	bit,
	@updateProc 	bit,
	@selectProc 		bit,
	@getSingleProc 	bit,
	@deleteProc 	bit,
	@tables 		varchar(2000),
	@printtoFile 	bit
	,@DefaultRole varchar(50) = 'public'
AS
/* 
	Usage:
		aspCreateProcedures
				@insertProc 	  1 to create an insert proc, 0 to skip,
				@updateProc 	  1 to create an update proc, 0 to skip,
				@selectProc 		1 to create a select proc, 0 to skip,
				@getSingleProc 	1 to create a getSingle proc, 0 to skip,
				@deleteProc 	  1 to create a delete proc, 0 to skip,
				@tables 		    list of tables, blank for all
				@printtoFile 	  1 to preview the SQL, 0 to actually create
				@DefaultRole	  default role (grants execute to this role

	User Can pass in multiple table names separated by |. The following cursor will get 
	the right table names and then run procedures for each tables. 

	EX: 
		exec aspCreateProcedures 0,0,1,0,0,'|Contact|Account|', 0	
	Would create: get only for Account and Contact

	If creating for full database just pass in '' for @tables.

	TODO:
	- consider supplying parms to dictate naming format (ex for usp prefix, suffix, etc.)
*/
Declare
	@Prefix				varchar(10)
	,@Suffix			varchar(10)
	,@SelectProcName		varchar(50) 
	,@GetSingleProcName	varchar(50) 
	,@CreateProcName	varchar(50) 
	,@UpdateProcName	varchar(50) 
	,@DeleteProcName	varchar(50) 
	,@GetSingleGrantRole	varchar(50) 
	,@CreateGrantRole	varchar(50) 
	,@UpdateGrantRole	varchar(50) 
	,@DeleteGrantRole	varchar(50) 
	,@tableFirst		bit

-- Set defaults for the current database /application 
set @tableFirst 	= 1		-- 1 to place table name before the procedure type (ContactInsert), 0 for after (InsertContact)
set @Prefix 		= ''	-- use to add a prefix to the procedure name )
set @Suffix 		= ''	-- use to add a suffix to the procedure name
-- Default procedure names
set @SelectProcName 	= 'Select' 
set @CreateProcName = 'Insert'
set @UpdateProcName = 'Update'
set @DeleteProcName = 'Delete'
set @GetSingleProcName 	= 'Get' 

-- Default grant role (can have multiplies, comma separated) 
set @CreateGrantRole = @DefaultRole	--'Maintenance'
set @UpdateGrantRole = @DefaultRole	--'Maintenance'
set @DeleteGrantRole = @DefaultRole	--'Maintenance'
set @GetSingleGrantRole = 'Public' 

Declare curTables CURSOR
FOR
	SELECT TABLE_NAME
	FROM INFORMATION_SCHEMA.TABLES 
	WHERE 
		TABLE_TYPE = 'BASE TABLE' 
	AND
		(CharIndex('|' + TABLE_NAME + '|', @tables) > 0 OR
		LTrim(RTrim(@tables)) = '')

Open curTables
Declare @Table_name varchar(128)
FETCH NEXT FROM curTables INTO @table_name

WHILE @@FETCH_STATUS = 0
Begin
	-- Check if insert procedure needs to be created. 
	If @insertProc = 1
		Exec aspCreateProcedure_Insert @table_name, @printtoFile, @tableFirst, @Prefix, @Suffix, @CreateProcName, @CreateGrantRole

	-- Check if update procedure needs to be created. 
	If @updateProc = 1
		Exec aspCreateProcedure_Update @table_name, @printtoFile, @tableFirst, @Prefix, @Suffix, @UpdateProcName, @UpdateGrantRole

	-- Check if get procedure needs to be created. 
	If @SelectProc = 1
		Exec aspCreateProcedure_Get @table_name, @printtoFile, @tableFirst, @Prefix, @Suffix, @SelectProcName
			 
	-- Check if get single procedure needs to be created. 
	If @getSingleProc = 1
		Exec aspCreateProcedure_GetSingle @table_name, @printtoFile, @tableFirst, @Prefix, @Suffix, @GetSingleProcName, @GetSingleGrantRole

	-- Check if delete procedure needs to be created. 
	If @deleteProc = 1
		Exec aspCreateProcedure_Delete @table_name, @printtoFile, @tableFirst, @Prefix, @Suffix, @DeleteProcName, @DeleteGrantRole

	FETCH NEXT FROM curTables INTO @table_name
End
Close curTables
Deallocate curTables



GO
/****** Object:  StoredProcedure [dbo].[aspGenerateColumnDef]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--*** need to update to handle varchar(max)!!!

-- =========================================================================
-- generate columns in a format for use by the dictionary program
-- Loops through all tables
--	- add a filter to retrieve a subset
-- raw select without any joins - for updates
-- Outputs to a local table called _Dictionary
-- 05/03/02 mparsons - added column desc
-- 06/10/27 mparsons - removed column description as the latter doesn't exist under ss2005
-- 08/05/21 mparsons - added code to handle varchar(MAX) - length is equal to -1 in syscolumns
-- 10/11/10 mparsons - added code to handle table names containing a period
-- =========================================================================
/*	
	drop table _Dictionary
 aspGenerateColumnDef @TableFilter = NULL, @TypeFilter='table', @Debug=8

 aspGenerateColumnDef @TableFilter = 'bus%', @TypeFilter='table'
*/
CREATE     PROCEDURE [dbo].[aspGenerateColumnDef]
	@TableFilter	varchar(50) = null,
	@TypeFilter		varchar(25) = null,
	@Debug 			int = 0
   	with recompile
As

Declare 
	@tablename 	nvarchar(128), 
	@entityType nvarchar(25), 
	@EntityFilter nvarchar(25), 
	@flags 		int , 
	@orderby 	nvarchar(10),
	@flags2 	int ,
	@AllColumns int,
    @msg        char(255),
	@fetch_cnt	int,
	@objid 		int

-- Set following defaults
set @flags 		= 0 
set @orderby 	= null
set @flags2 	= 0
set @AllColumns	= 1

IF EXISTS (SELECT name, type from sysobjects where type = 'U' and name = N'#genColDef') begin 
	drop table #genColDef
	end

-- Create work table
create table #genColDef
(
	tableName        	nvarchar(128)   COLLATE database_default NOT NULL,
	col_id           	int             NOT NULL,
	colName     		nvarchar(128)   COLLATE database_default NOT NULL,
	datatype     		nvarchar(30)   	COLLATE database_default NOT NULL,
	col_precScale		nvarchar(50)	NULL,
	col_null         	bit           	NOT NULL,  /* status & 8 */
	DefaultValue      	nvarchar(257)  	COLLATE database_default NULL
   ,col_identity    	bit               /* status & 128 */

   ,col_desc			nvarchar(250)	NULL
   ,entityType			nvarchar(25)    NULL	
   ,CreatedDate			datetime        NOT NULL CONSTRAINT DF_genColDef_CreatedDate DEFAULT (getdate())

)

if (@TypeFilter is null) 
	set @entityFilter = null
else begin
	set @entityFilter = '%' + @TypeFilter + '%' 
end

-- ********************************************************************
-- * - declare cursor for loop thru table
-- ********************************************************************
declare curLocal CURSOR FOR
	-- Get tables
	SELECT 
	--	*,
	-- 	Table_Schema, 
	 	Table_Name 
		,Case When Table_Type = 'BASE TABLE' Then 'table'
			  When Table_Type = 'VIEW' Then 'view'
		 else Table_Type
		 end As EntityType
	FROM 
		Information_Schema.Tables 
	WHERE 
-- 		lower(Table_Type) = 'base table' 
--  	AND 
		Table_Name <> 'dtproperties'
-- 	AND Table_Name Like 'HD07%'
	And (Table_Name Like @TableFilter or @TableFilter is null)
	And (Table_Type Like @entityFilter or @entityFilter is null)
	Order by Table_Name

open  curLocal
fetch next from curLocal into @tablename, @entityType
WHILE @@FETCH_STATUS = 0 Begin
	--set @tablename = '[' + @tablename + ']'
	select @objid = object_id('[' + @tablename + ']')
	--select object_id('[program.unit]')

	if @Debug > 5 begin
		print 'next: ' + @tablename
		print '@objid: ' + convert(varchar,@objid)
		end

	Insert #genColDef 
	select
		@tablename, 
		c.colid, 
		c.name, 
		st.name As DataType,
--          	case 
-- 				when bt.name in (N'nchar', N'nvarchar') 
-- 				then c.length/2 
-- 				else c.length end As Length,

		PrecScale = 
			case when (st.name in (N'decimal',N'numeric') )
				 	then cast(c.xprec as varchar(3)) + ', ' + cast(c.xscale  as varchar(3))
				 when c.length = -1
				 	then 'MAX'
				 when st.name in (N'nchar', N'nvarchar') 
				 	then cast(c.length/2  as varchar(4))
				 else cast(c.length  as varchar(4)) end,

		-- Nullable
		convert(bit, ColumnProperty(@objid, c.name, N'AllowsNull')) As AllowNulls
		,IsNull(cn.text,'') As DefaultValue
		-- Identity
			,case 
				when (@flags & 0x40000000 = 0) 
				then convert(bit, ColumnProperty(@objid, c.name, N'IsIdentity')) 
				else 0 
			end As IdentityType
-- 			,ColumnProperty(@objid, c.name, N'Precision') As TypePrecision
-- 			,ColumnProperty(@objid, c.name, N'Scale')	 As Scale

		--,convert(nvarchar(250),sp.value)
		,'TBD'
		,@entityType
		,getdate()
-- 
-- 	select * 
	from 
		dbo.syscolumns c
--where c.name = 'description'
		-- NonDRI Default and Rule filters
		left outer join dbo.sysobjects d on d.id = c.cdefault
		left outer join dbo.sysobjects r on r.id = c.domain
		-- Fully derived data type name
		join dbo.systypes st on st.xusertype = c.xusertype
		-- Physical base data type name
		join dbo.systypes bt on bt.xusertype = c.xtype
		-- DRIDefault text, if it's only one row.
		left outer join dbo.syscomments t on t.id = c.cdefault and t.colid = 1
				and not exists (select * from dbo.syscomments where id = c.cdefault and colid = 2)
		left outer join dbo.syscomments 	cn on t.id is not null and cn.id = t.id
		-- Any description for the column
		-- mp - sysproperties doesn't exist under ss2005
--		left outer join dbo.sysproperties 	sp 
--			on  c.id = sp.id and c.colid = sp.smallid and sp.name = 'MS_Description'
	where 
		c.id = @objid
	order by 
		c.colid

	/* Get next row                                    */
	fetch next from curLocal into @tablename, @entityType

   	set @fetch_cnt = @@rowcount

end /* while */

close curLocal
deallocate curLocal
-- Now display columns

IF EXISTS (SELECT name, type from sysobjects where type = 'U' and name = N'_Dictionary') begin 
--	select 'exists'
	delete from _Dictionary
	Insert _Dictionary select * from #genColDef 
	end
else begin
--	select 'not found'
	select * Into _Dictionary from #genColDef order by tableName, col_id

	end
IF EXISTS (SELECT name, type from sysobjects where type = 'U' and name = N'_DictTable') begin 
	-- only add new tables
	Insert _DictTable 
		select distinct tablename, tablename + '- TBD' As Description, 1 As IsActive, 1 As ReportGroup, 1 As ReportOrder, 1 As Synchronize, getdate() As Created
		from _Dictionary 
		Where (tablename not like '_d%') and tablename not in (select tablename from _DictTable)
	end
else begin
--	select 'not found'
	select distinct tablename, tablename + '- TBD' As Description, 1 As IsActive, 1 As ReportGroup, 1 As ReportOrder, 1 As Synchronize, getdate() As Created  into _DictTable from _Dictionary 

	end

select * From _Dictionary order by tableName, col_id

select distinct tablename From _Dictionary order by tableName
-- drop temp table
drop table #genColDef




GO
/****** Object:  StoredProcedure [dbo].[Codes.ContentPrivilegeSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Codes.ContentPrivilegeSelect]
As
SELECT 
    Id, 
    Title, 
    Description, 
    IsActive, 
    Created
FROM [Codes.ContentPrivilege]
where IsActive = 1
order by SortOrder


GO
/****** Object:  StoredProcedure [dbo].[Codes.SubscriptionTypeSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Codes.SubscriptionTypeSelect]
As
SELECT 
    Id, 
    Title
FROM [Codes.SubscriptionType]
where IsActive = 1
Order by Title

GO
/****** Object:  StoredProcedure [dbo].[Community.PostingSearch]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

-- ===========================================================

DECLARE @RC int,@Filter varchar(500), @StartPageIndex int, @PageSize int, @totalRows int,@SortOrder varchar(100)
set @SortOrder = '' 
set @Filter = ' createdById = 2 '

--set @Filter = ''
set @StartPageIndex = 1
set @PageSize = 15

exec [Community.PostingSearch] @Filter, @SortOrder, @StartPageIndex  ,@PageSize  ,@totalRows OUTPUT

select 'total rows = ' + convert(varchar,@totalRows)


*/

/* =================================================
= Community.Posting search
=		@StartPageIndex - starting page number. If interface is at 20 when next page is requested, this would be set to 21?
=		@PageSize - number of records on a page
=		@totalRows OUTPUT - total available rows. Used by interface to build a custom pager
= ------------------------------------------------------
= Modifications
= 14-03-06 mparsons - Created 
-- ================================================= */
Create PROCEDURE [dbo].[Community.PostingSearch]
		@Filter				varchar(500)
		,@SortOrder			varchar(500)
		,@StartPageIndex	int
		,@PageSize		    int
		,@TotalRows			int OUTPUT
AS 
DECLARE 
	@first_id			int
	,@startRow		int
	,@debugLevel	int
	,@SQL             varchar(5000)
	,@OrderBy         varchar(100)

	SET NOCOUNT ON;

-- ==========================================================
Set @debugLevel = 4
if len(@SortOrder) > 0
	set @OrderBy = ' Order by ' + @SortOrder
else 
  set @OrderBy = ' Order by cps.Created DESC'
--===================================================
-- Calculate the range
--===================================================
SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

 
-- =================================
CREATE TABLE #tempWorkTable(
	RowNumber int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Id int NOT NULL,
	CreatedById int

)
-- =================================

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter 
     end
	 else begin 
	 set @Filter =     '  '
	 end
 
set @SQL = 'SELECT [Id]  ,[CreatedById]   FROM [dbo].[Community.PostingSummary] cps  '  
	  + @Filter

if charindex( 'order by', lower(@Filter) ) = 0 
	set @SQL = 	@SQL + @OrderBy
if @debugLevel > 3 begin
  print '@SQL len: '  +  convert(varchar,len(@SQL))
	print @SQL
	end
	
INSERT INTO #tempWorkTable (Id, CreatedById)
exec (@sql)
   SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Show the StartPageIndex
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

SELECT     Distinct
		RowNumber,
		[CommunityId]
      ,[Community]
      ,base.[CreatedById]
      ,[UserFullName]
      ,[UserImageUrl]
	  ,base.Id
      ,[Message]
      ,base.[RelatedPostingId]
	  , case when isnull(base.[RelatedPostingId],0) > 0 then 1 else 0 end As HasParentPosting
	  , isnull(replys.TotalPosts,0) As TotalReplys
  
From #tempWorkTable temp
inner join [dbo].[Community.PostingSummary] base on temp.Id = base.Id

    Left Join [LR.PatronOrgSummary] creator on base.CreatedById = creator.Userid
	
	left join (SELECT cp.[RelatedPostingId], count(*) As TotalPosts
		  FROM [Community.Posting] cp group by cp.[RelatedPostingId]) 
		  As replys on base.id = replys.RelatedPostingId

WHERE RowNumber > @first_id 
order by RowNumber		

SET ROWCOUNT 0

GO
/****** Object:  StoredProcedure [dbo].[Content.HistoryInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.HistoryInsert]
            @ContentId int, 
            @Action varchar(75), 
            @Description varchar(MAX), 
            @CreatedById int
As

If @Action = ''   SET @Action = 'Unknown' 
If @Description = ''   SET @Description = NULL 
If @CreatedById = 0   SET @CreatedById = NULL 

INSERT INTO [Content.History] (

    ContentId, 
    Action, 
    Description, 
    Created, 
    CreatedById
)
Values (

    @ContentId, 
    @Action, 
    @Description, 
    getdate(), 
    @CreatedById
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Content.HistorySelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.HistorySelect]
    @ContentId int
As
SELECT     
    h.Id, 
    h.ContentId, 
    h.[Action], 
    h.Description, 
    h.Created, 
    h.CreatedById, usr.FullName As CreatedBy
    
FROM [Content.History] h
Inner Join [Content] c on h.ContentId = c.Id
Left Join [LR.PatronOrgSummary] usr on h.CreatedById = usr.UserId

WHERE ContentId = @ContentId
order by Created DESC, [Action]
 


GO
/****** Object:  StoredProcedure [dbo].[Content.ReferenceDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.ReferenceDelete]
        @Id int
As
DELETE FROM [Content.Reference]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Content.ReferenceGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.ReferenceGet]
    @Id int
As
SELECT     Id, 
    ParentId, 
    Title, 
    Author, 
    Publisher, 
    ISBN, 
    ReferenceUrl, AdditionalInfo,
    Created, 
    CreatedById, 
    LastUpdated, 
    LastUpdatedById
FROM [Content.Reference]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Content.ReferenceInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.ReferenceInsert]
            @ParentId int, 
            @Title varchar(200), 
            @Author varchar(100), 
            @Publisher varchar(100), 
            @ISBN varchar(50), 
            @ReferenceUrl varchar(200), 
            @AdditionalInfo varchar(500), 
            @CreatedById int
As

If @Title = ''   SET @Title = NULL 
If @Author = ''   SET @Author = NULL 
If @Publisher = ''   SET @Publisher = NULL 
If @ISBN = ''   SET @ISBN = NULL 
If @ReferenceUrl = ''   SET @ReferenceUrl = NULL 
If @AdditionalInfo = ''   SET @AdditionalInfo = NULL 
If @CreatedById = 0   SET @CreatedById = NULL 

INSERT INTO [Content.Reference] (

    ParentId, 
    Title, 
    Author, 
    Publisher, 
    ISBN, 
    ReferenceUrl, 
    AdditionalInfo,
    Created, 
    CreatedById, 
    LastUpdatedById
)
Values (

    @ParentId, 
    @Title, 
    @Author, 
    @Publisher, 
    @ISBN, 
    @ReferenceUrl, 
    @AdditionalInfo,
    getdate(), 
    @CreatedById, 
    @CreatedById
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Content.ReferenceSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.ReferenceSelect]
  @ParentId int
As
SELECT 
    Id, 
    ParentId, 
    Title, 
    Author, 
    Publisher, 
    ISBN, 
    ReferenceUrl, AdditionalInfo,
    Created, 
    CreatedById, 
    LastUpdated, 
    LastUpdatedById
FROM [Content.Reference]
WHERE ParentId = @ParentId
Order by Title, Id

GO
/****** Object:  StoredProcedure [dbo].[Content.ReferenceUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- Update Procedure for [Content.Reference] ---
CREATE PROCEDURE [dbo].[Content.ReferenceUpdate]
        @Id int,
        @Title varchar(200), 
        @Author varchar(100), 
        @Publisher varchar(100), 
        @ISBN varchar(50), 
        @ReferenceUrl varchar(200), 
        @AdditionalInfo varchar(500), 
        @LastUpdatedById int

As

If @Title = ''   SET @Title = NULL 
If @Author = ''   SET @Author = NULL 
If @Publisher = ''   SET @Publisher = NULL 
If @ISBN = ''   SET @ISBN = NULL 
If @ReferenceUrl = ''   SET @ReferenceUrl = NULL 
If @AdditionalInfo = ''   SET @AdditionalInfo = NULL 
If @LastUpdatedById = 0   SET @LastUpdatedById = NULL 

UPDATE [Content.Reference] 
SET 
    Title = @Title, 
    Author = @Author, 
    Publisher = @Publisher, 
    ISBN = @ISBN, 
    ReferenceUrl = @ReferenceUrl, 
    AdditionalInfo = @AdditionalInfo, 
    LastUpdated = getdate(), 
    LastUpdatedById = @LastUpdatedById
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Content.SupplementDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.SupplementDelete]
        @Id int
As
DELETE FROM [Content.Supplement]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Content.SupplementGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.SupplementGet]
    @Id int,
    @RowId varchar(40)
As
If @Id = 0   SET @Id = NULL 
If @RowId = 0   SET @RowId = NULL 

if @Id is null AND @RowId is null begin
  print '[Content.SupplementGet] Error: Incomplete parameters were provided'
	RAISERROR('[Content.SupplementGet] Error: incomplete parameters were provided. Require item @Id, OR @RowId', 18, 1)    
	RETURN -1 
  end
  
Select
    base.Id, 
    ParentId, 
    base.Title, 
    base.Description, 
    base.ResourceUrl, 
    base.PrivilegeTypeId, codes.Title As PrivilegeType,
    base.IsActive, 
    base.Created, 
    base.CreatedById, 
    base.LastUpdated, 
    base.LastUpdatedById,
    RowId
    ,DocumentRowId
    
FROM [Content.Supplement] base
Inner join [Codes.ContentPrivilege] codes on base.PrivilegeTypeId = codes.Id

WHERE 
    (base.Id = @Id OR @Id is null)
AND (RowId = @RowId OR @RowId is null)    


GO
/****** Object:  StoredProcedure [dbo].[Content.SupplementInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Content.SupplementInsert]
            @ParentId int, 
            @Title varchar(200), 
            @Description varchar(MAX), 
            @ResourceUrl varchar(200), 
            @PrivilegeTypeId int, 
            @IsActive bit, 
            @CreatedById int
            ,@DocumentRowId varchar(40)

As
If @ParentId = 0   SET @ParentId = NULL 
If @Title = ''   SET @Title = NULL 
If @Description = ''   SET @Description = NULL 
If @ResourceUrl = ''   SET @ResourceUrl = NULL 
If @PrivilegeTypeId = 0   SET @PrivilegeTypeId = NULL 
If @IsActive = 0   SET @IsActive = NULL 
If @CreatedById = 0   SET @CreatedById = NULL 
 
 If @DocumentRowId = ''   SET @DocumentRowId = NULL 
 
INSERT INTO [Content.Supplement] (

    ParentId, 
    Title, 
    Description, 
    ResourceUrl, 
    PrivilegeTypeId, 
    IsActive, 
    CreatedById, 
    LastUpdatedById
    ,DocumentRowId
)
Values (

    @ParentId, 
    @Title, 
    @Description, 
    @ResourceUrl, 
    @PrivilegeTypeId, 
    @IsActive, 
    @CreatedById, 
    @CreatedById
    ,@DocumentRowId
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Content.SupplementSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Content.SupplementSelect] 2032
*/
CREATE PROCEDURE [dbo].[Content.SupplementSelect]
    @ParentId int
As
Select
    base.Id, 
    ParentId, 
    base.Title, 
    base.Description, 
    base.ResourceUrl, 
    base.PrivilegeTypeId, codes.Title As PrivilegeType,
    base.IsActive, 
    base.Created, 
    base.CreatedById, 
    base.LastUpdated, 
    base.LastUpdatedById,
    RowId
    ,DocumentRowId
    
FROM [Content.Supplement] base
Inner join [Codes.ContentPrivilege] codes on base.PrivilegeTypeId = codes.Id

where ParentId= @ParentId
Order by Title

GO
/****** Object:  StoredProcedure [dbo].[Content.SupplementUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- Update Procedure for [Content.Supplement] ---
CREATE PROCEDURE [dbo].[Content.SupplementUpdate]
        @Id int,
        @Title varchar(200), 
        @Description varchar(MAX), 
        @ResourceUrl varchar(200), 
        @PrivilegeTypeId int, 
        @IsActive bit,  
        @LastUpdatedById int 
        ,@DocumentRowId varchar(40)

As

If @Title = ''   SET @Title = NULL 
If @Description = ''   SET @Description = NULL 
If @ResourceUrl = ''   SET @ResourceUrl = NULL 
If @PrivilegeTypeId = 0   SET @PrivilegeTypeId = NULL 
If @IsActive = 0   SET @IsActive = NULL 
If @LastUpdatedById = 0   SET @LastUpdatedById = NULL 
If @DocumentRowId = ''   SET @DocumentRowId = NULL 

UPDATE [Content.Supplement] 
SET 
    Title = @Title, 
    Description = @Description, 
    ResourceUrl = @ResourceUrl, 
    PrivilegeTypeId = @PrivilegeTypeId, 
    IsActive = @IsActive, 
    DocumentRowId = @DocumentRowId,
    LastUpdated = GETDATE(), 
    LastUpdatedById = @LastUpdatedById
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Content.UpdateResourceVersionId]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- Update ResourceVersionId for [Content] ---
-- ====================================================================
--mods
--13-04-23 mparsons - added ResourceVersionId

Create  PROCEDURE [dbo].[Content.UpdateResourceVersionId]
        @Id int,
        @ResourceVersionId int
As

If @ResourceVersionId = 0   SET @ResourceVersionId = NULL 

UPDATE [Content] 
SET 
    ResourceVersionId = @ResourceVersionId,
    LastUpdated = GETDATE()
    
WHERE Id = @Id


GO
/****** Object:  StoredProcedure [dbo].[Content_SelectTemplates]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Content_SelectTemplates] 1

*/
Create PROCEDURE [dbo].[Content_SelectTemplates]
    @OrgId int
As
declare @ParentOrgId int

SELECT @ParentOrgId = isnull([ParentOrgId],0) FROM [dbo].[ContentSummaryView] where [OrgId] = @OrgId
if @ParentOrgId is null or @ParentOrgId = 0 set @ParentOrgId = @OrgId
 
SELECT [ContentId] as Id
      ,[Title]
     
      
  FROM [IsleContent].[dbo].[ContentSummaryView]
where [TypeId] = 15 
and [ContentStatus] = 'Published'
and ([OrgId] = @OrgId OR [OrgId] = @ParentOrgId)


GO
/****** Object:  StoredProcedure [dbo].[ContentDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ContentDelete]
        @Id int
As
DELETE FROM [Content]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[ContentGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[ContentGet] 2003, ''

[ContentGet] 0, 'E97C5948-C020-4C0B-B4F5-FB53EBAF44F2'

*/

-- ====================================================================
--mods
--13-04-23 mparsons - added ResourceVersionId
--13-04-24 mparsons - added UseRightsUrl
--14-01-30 mparsons - added documentUrl, and documentRowId
-- ====================================================================
CREATE PROCEDURE [dbo].[ContentGet]
    @Id int
     ,@RowId varchar(40)
As
If @Id = 0          SET @Id = NULL 
If @RowId = ''      SET @RowId = NULL 

if @Id is null AND @RowId is null begin
  print '[Content.Get] Error: Incomplete parameters were provided'
	RAISERROR('[Content.Get] Error: incomplete parameters were provided. Require item @Id, OR @RowId', 18, 1)    
	RETURN -1 
  end
  
  
SELECT     
    base.Id, 
    base.TypeId, ctype.Title As ContentType,
    base.Title, base.Summary,
    base.Description, 
    base.StatusId, stat.Title As [Status],
    base.PrivilegeTypeId, prv.Title as PrivilegeType,
    base.ConditionsOfUseId, cou.Title as ConditionsOfUse, 
    cou.IconUrl as ConditionsOfUseIconUrl,
    case when base.UseRightsUrl is not null AND len(base.UseRightsUrl) > 0 then
      base.UseRightsUrl
    else cou.Url end As ConditionsOfUseUrl,
    base.UseRightsUrl,
    base.ResourceVersionId, 
    base.IsActive, 
    IsOrgContentOwner, 
    base.OrgId,
    org.Name as Organization,
    org.ParentId As ParentOrgId,
    case when org.ParentId > 0 then org.[ParentOrganization]
    else '' end as [ParentOrganization],

    base.IsPublished, 
    base.Created, base.CreatedById, 
    createdBy.OrganizationId As AuthorOrgId,
    case when createdBy.UserId is not null then
      createdBy.FullName + '<br/>' + Organization
      else '' end As Author,
    base.LastUpdated, base.LastUpdatedById, 
    base.Approved, base.ApprovedById,
    base.RowId
	,base.DocumentUrl
	,base.DocumentRowId
    
FROM [Content] base
left join [ContentType] ctype             on base.TypeId = ctype.Id
left join [LR.PatronOrgSummary] createdBy on base.CreatedById = createdBy.Userid
left join [Codes.ContentPrivilege] prv    on base.PrivilegeTypeId = prv.Id
left join [Codes.ContentStatus] stat      on base.StatusId = stat.Id
left join [LR.ConditionOfUse_Select] cou  on base.ConditionsOfUseId = cou.Id
Left Join [Gateway.OrgSummary] org        on base.OrgId = org.Id
WHERE 
    (base.Id = @Id or @Id IS NULL)
AND (base.RowId = @RowId or @RowId IS NULL)    

GO
/****** Object:  StoredProcedure [dbo].[ContentInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ====================================================================
--mods
--13-04-24 mparsons - added UseRightsUrl
--14-01-30 mparsons - added documentUrl, and documentRowId
-- ====================================================================
CREATE PROCEDURE [dbo].[ContentInsert]
            @TypeId int, 
            @Title varchar(200), 
            @Summary varchar(MAX),             
            @Description varchar(MAX), 
            @StatusId int, 
            @PrivilegeTypeId int,
            @ConditionsOfUseId int, 
            @IsActive bit, 
            @OrgId  int,
            @IsOrgContentOwner bit,
            @CreatedById int,
            @UseRightsUrl varchar(200),
			@DocumentUrl varchar(200),
			@DocumentRowId varchar(36)


As
If @TypeId = 0          SET @TypeId = 10 
If @Title = ''          SET @Title = NULL 
If @Summary = ''        SET @Summary = NULL 
If @Description = ''    SET @Description = NULL 
If @StatusId = 0        SET @StatusId = 1 
If @PrivilegeTypeId = 0   SET @PrivilegeTypeId = 1 
If @ConditionsOfUseId = 0   SET @ConditionsOfUseId = 3 
If @OrgId = 0   SET @OrgId = NULL 
If @CreatedById = 0   SET @CreatedById = NULL 
If @UseRightsUrl = ''    SET @UseRightsUrl = NULL 
If @DocumentUrl = ''    SET @DocumentUrl = NULL 
If @DocumentRowId = '' OR @DocumentRowId = '00000000-0000-0000-0000-000000000000'   SET @DocumentRowId = NULL 

INSERT INTO [Content] (

    TypeId, 
    Title, Summary, 
    Description, 
    StatusId, 
    PrivilegeTypeId, 
    ConditionsOfUseId,
    IsActive, 
    OrgId,
    IsOrgContentOwner,
    IsPublished,
    Created, 
    CreatedById, 
    LastUpdated, 
    LastUpdatedById
    ,UseRightsUrl
	,DocumentUrl
	,DocumentRowId
)
Values (

    @TypeId, 
    @Title, @Summary,
    @Description, 
    @StatusId, 
    @PrivilegeTypeId, 
    @ConditionsOfUseId,
    @IsActive,
    @OrgId,
    @IsOrgContentOwner, 
    0, 
    GETDATE(), 
    @CreatedById, 
    GETDATE(), 
    @CreatedById
    ,@UseRightsUrl
	,@DocumentUrl
	,@DocumentRowId
)
 
select SCOPE_IDENTITY() as Id


GO
/****** Object:  StoredProcedure [dbo].[ContentSearch]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
SELECT [Id]
      ,[TypeId]
      ,[Title]
      ,[Summary]
      ,[Description]
      ,[StatusId]
      ,[PrivilegeTypeId], ConditionsOfUseId
      ,[IsActive]
      ,[IsPublished]
      ,[OrgId]
      ,[Created]
      ,[CreatedById]
      ,[LastUpdated]
      ,[LastUpdatedById]
      ,[Approved]
      ,[ApprovedById]
      ,[RowId]

  FROM [IsleContent].[dbo].[Content]
GO
select * from [ContentSummaryView]


select * from [LR.PatronOrgSummary]

--=====================================================

DECLARE @RC int,@SortOrder varchar(100),@Filter varchar(5000)
DECLARE @StartPageIndex int, @PageSize int, @TotalRows int
--
set @SortOrder = 'ContentPrivilege'

-- blind search 
set @Filter = ''
set @Filter = ' where createdById = 2'

set @StartPageIndex = 1
set @PageSize = 55
--set statistics time on       
EXECUTE @RC = [ContentSearch]
     @Filter,@SortOrder  ,@StartPageIndex  ,@PageSize, @TotalRows OUTPUT

select 'total rows = ' + convert(varchar,@TotalRows)

--set statistics time off       


*/


/* =============================================
      Description:      Content search
  Uses custom paging to only return enough rows for one page
     Options:

  @StartPageIndex - starting page number. If interface is at 20 when next
page is requested, this would be set to 21?
  @PageSize - number of records on a page
  @TotalRows OUTPUT - total available rows. Used by interface to build a
custom pager
  ------------------------------------------------------
Modifications
13-03-22 mparsons - new
13-04-23 mparsons - added ResourceVersionId

*/

CREATE PROCEDURE [dbo].[ContentSearch]
		@Filter           varchar(5000)
		,@SortOrder       varchar(100)
		,@StartPageIndex  int
		,@PageSize        int
		,@TotalRows       int OUTPUT

As

SET NOCOUNT ON;
-- paging
DECLARE
      @first_id               int
      ,@startRow        int
      ,@debugLevel      int
      ,@SQL             varchar(5000)
      ,@OrderBy         varchar(100)


-- =================================

Set @debugLevel = 4

if len(@SortOrder) > 0
      set @OrderBy = ' Order by ' + @SortOrder
else
      set @OrderBy = ' Order by base.Title '

--===================================================
-- Calculate the range
--===================================================
SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

 
-- =================================
CREATE TABLE #tempWorkTable(
      RowNumber         int PRIMARY KEY IDENTITY(1,1) NOT NULL,
      Id int,
      Title             varchar(200)
)

-- =================================

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter
     end

  print '@Filter len: '  +  convert(varchar,len(@Filter))
  --set @SQL = 'SELECT base.Id, base.Title 
  --      FROM [dbo].[Content] base  
  --      Left Join [LR.PatronOrgSummary] auth on base.CreatedById = auth.UserId '
  --      + @Filter
  set @SQL = 'SELECT base.ContentId, base.Title 
        FROM [dbo].[ContentSummaryView] base  
        Left Join [LR.PatronOrgSummary] auth on base.CreatedById = auth.UserId '
        + @Filter        
  if charindex( 'order by', lower(@Filter) ) = 0
    set @SQL = @SQL + ' ' + @OrderBy

  print '@SQL len: '  +  convert(varchar,len(@SQL))
  print @SQL

  INSERT INTO #tempWorkTable (Id, Title)
  exec (@SQL)
  --print 'rows: ' + convert(varchar, @@ROWCOUNT)
  SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Calculate the range
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

-- =================================
--SELECT Distinct TOP (@PageSize)
SELECT Distinct    
    RowNumber,
    base.ContentId, 
    base.TypeId, ContentType, 
    base.Title, base.Summary,
    base.Description, 
    base.StatusId, ContentStatus,
    base.PrivilegeTypeId, ContentPrivilege,
    base.ConditionsOfUseId, base.ResourceVersionId,
    base.IsPublished, 
    base.OrgId, base.Organization, IsOrgContentOwner,
    auth.FullName As Author,
    auth.LastName + ', ' + auth.FirstName as AuthorSortName,
    convert(varchar, base.Created, 107) As Created, base.CreatedById, 
    convert(varchar, base.LastUpdated, 107) As LastUpdatedDisplay, 
    base.LastUpdated, base.LastUpdatedById
    ,[ApprovedById]
    ,[Approved]
    ,ContentRowId 
      
From #tempWorkTable work
    Inner join [dbo].[ContentSummaryView] base on work.Id = base.ContentId
    Left Join [LR.PatronOrgSummary] auth on base.CreatedById = auth.UserId
   
WHERE RowNumber > @first_id
order by RowNumber 


GO
/****** Object:  StoredProcedure [dbo].[ContentTypeSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Content.TypeSelect]

*/
CREATE PROCEDURE [dbo].[ContentTypeSelect]
  
As
SELECT 
    Id, 
    Title, 
    Description, 
    HasApproval, 
    MaxVersions, 
    IsActive, 
    Created
FROM [ContentType]
where IsActive= 1
Order by Title


GO
/****** Object:  StoredProcedure [dbo].[ContentUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- ====================================================================
--- Update Procedure for [Content] ---
--mods
--13-05-03 mparsons - added ResourceVersionId, 
--          and maybe IsOrgContentOwner (to maybe allow upgrade from personal to org)
-- ====================================================================
CREATE PROCEDURE [dbo].[ContentUpdate]
        @Id int,
        @Title varchar(200), 
        @Summary varchar(MAX),             
        @Description varchar(MAX), 
        @StatusId int, 
        @PrivilegeTypeId int, 
        @ConditionsOfUseId int, 
        @IsActive bit, 
        @IsPublished bit, 
        @LastUpdatedById int,
        @UseRightsUrl varchar(200),
        @ResourceVersionId int
        --,@IsOrgContentOwner bit
		--,@DocumentUrl varchar(200)
		--,@DocumentRowId varchar(36)

As

If @Title = ''   SET @Title = NULL 
If @Summary = ''   SET @Summary = NULL 
If @Description = ''   SET @Description = NULL 
If @StatusId = 0        SET @StatusId = 2 
If @PrivilegeTypeId = 0   SET @PrivilegeTypeId = 1 
If @ConditionsOfUseId = 0   SET @ConditionsOfUseId = 3 

If @IsPublished = 0   SET @IsPublished = NULL 
If @LastUpdatedById = 0   SET @LastUpdatedById = NULL 
If @UseRightsUrl = ''    SET @UseRightsUrl = NULL 
If @ResourceVersionId = 0   SET @ResourceVersionId = NULL 
-- prob need to allow switch from personal to org, and maybe org (from school to district and back)
--If @OrgId = 0   SET @OrgId = NULL 

UPDATE [Content] 
SET 
    Title = @Title, 
    Summary = @Summary, 
    Description = @Description, 
    StatusId = @StatusId, 
    PrivilegeTypeId = @PrivilegeTypeId, 
    ConditionsOfUseId = @ConditionsOfUseId, 
    IsActive = @IsActive, 
    IsPublished = @IsPublished, 
    LastUpdated = GETDATE(), 
    LastUpdatedById = @LastUpdatedById,
    UseRightsUrl = @UseRightsUrl,
    ResourceVersionId = @ResourceVersionId
	--,DocumentUrl = @DocumentUrl
    --,DocumentRowId = @DocumentRowId
    --,IsOrgContentOwner = @IsOrgContentOwner
WHERE Id = @Id


GO
/****** Object:  StoredProcedure [dbo].[DocumentVersion_SetToPublished]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--- Update Procedure for Document.Version
--- Set document to published. 
--Used to minimize orphans where the doc version needs to be persisted before parent record and then something happens to prevent the parent from being saved
CREATE PROCEDURE [dbo].[DocumentVersion_SetToPublished]
				@RowId varchar(36)
As

UPDATE [Document.Version]
SET 
    Status = 'Published', 
    LastUpdated = getdate()

WHERE RowId = @RowId


GO
/****** Object:  StoredProcedure [dbo].[DocumentVersionDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DocumentVersionDelete]
        @RowId uniqueidentifier
As
DELETE FROM [Document.Version]
WHERE RowId = @RowId


GO
/****** Object:  StoredProcedure [dbo].[DocumentVersionGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DocumentVersionGet]
    @RowId uniqueidentifier
As
SELECT     
		RowId, 
    Title, 
    Summary, 
    Status, 
    FileName, 
    FileDate, 
    MimeType, 
    Bytes, 
    Data, 
		URL,
    Created, CreatedById, 
    LastUpdated, LastUpdatedById
FROM [Document.Version]
WHERE RowId = @RowId


GO
/****** Object:  StoredProcedure [dbo].[DocumentVersionInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DocumentVersionInsert]
            @Title varchar(200), 
            @Summary varchar(500), 
            @Status varchar(25), 
            @FileName varchar(150), 
            @FileDate datetime, 
            @MimeType varchar(150), 
            @Bytes bigint, 
            @Data varbinary(MAX), 
            @URL varchar(150), 
            @CreatedById int
As

If @Summary = ''			SET @Summary = 'TBD' 
If @Status = ''				SET @Status = 'initial' 
If @FileDate < '1990-01-01'			SET @FileDate = getdate() 
If @URL = ''				  SET @URL = NULL

declare @newId uniqueidentifier
set @newId = newId()

INSERT INTO [Document.Version](
		RowId,
    Title, 
    Summary, 
    [Status], 
    [FileName], 
    FileDate, 
    MimeType, 
    Bytes, 
    Data, 
    URL,
    Created, 
    CreatedById, 
    LastUpdated, 
    LastUpdatedById
)
Values (
		@newId,
    @Title, 
    @Summary, 
    @Status, 
    @FileName, 
    @FileDate, 
    @MimeType, 
    @Bytes, 
    @Data, 
    @URL,
    getdate(), 
    @CreatedById, 
    getdate(), 
    @CreatedById
)
 
select @newId As RowId


GO
/****** Object:  StoredProcedure [dbo].[DocumentVersionUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--- Update Procedure for Document.Version---
CREATE PROCEDURE [dbo].[DocumentVersionUpdate]
				@RowId uniqueidentifier,
        @Title varchar(200), 
        @Summary varchar(500), 
        @Status varchar(25), 
        @FileName varchar(150), 
        @FileDate datetime, 
        @MimeType varchar(150), 
        @Bytes bigint, 
        @Data varbinary(MAX),
        @URL varchar(150),   
        @LastUpdatedById int

As
If @Summary = ''			SET @Summary = 'TBD' 
If @Status = ''				SET @Status = 'updated' 
If @FileDate < '1990-01-01'			SET @FileDate = getdate() 
If @URL = ''				  SET @URL = NULL

UPDATE [Document.Version]
SET 
    Title = @Title, 
    Summary = @Summary, 
    Status = @Status, 
    FileName = @FileName, 
    FileDate = @FileDate, 
    MimeType = @MimeType, 
    Bytes = @Bytes, 
    Data = @Data, 
    URL = @URL,
    LastUpdated = getdate(), 
    LastUpdatedById = @LastUpdatedById

WHERE RowId = @RowId


GO
/****** Object:  StoredProcedure [dbo].[Library.CommentSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
[Library.CommentSelect] 1
*/
/*
Select all comments for a library
- or do we want to implement paging?
*/
CREATE PROCEDURE [dbo].[Library.CommentSelect]
    @LibraryId int
As
SELECT     Id, 
    LibraryId, 
    Comment, 
	base.Created, 
    base.CreatedById,  
    pos.Fullname, pos.Firstname, pos.Lastname
FROM [Library.Comment] base
inner join [LR.PatronOrgSummary] pos on base.createdById = pos.UserId
WHERE LibraryId = @LibraryId
Order by base.created desc

GO
/****** Object:  StoredProcedure [dbo].[Library.EditAccessSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.EditAccessSelect] 2
*/

CREATE PROCEDURE [dbo].[Library.EditAccessSelect]
  @UserId int
As


SELECT distinct
	base.[Id]
	,base.[Title]
	,base.LibraryTypeId, lt.Title as LibraryType
	,base.ImageUrl
	,base.[OrgId]
	,base.[CreatedById]

  FROM [dbo].[Library] base
  inner join [Library.Type] lt on base.LibraryTypeId = lt.Id
  inner join [Library.Section] ls on base.id = ls.LibraryId
  left join [Library.SectionMember] lsm on ls.id = lsm.LibrarySectionId
  left join [Library.Member] mbr on base.id = mbr.LibraryId
where 
	[IsActive]= 1
And (
	(base.[CreatedById]= @UserId and LibraryTypeId = 1)
	OR
	(mbr.UserId = @UserId AND mbr.MemberTypeId > 1)
	OR
	(lsm.UserId = @UserId AND lsm.MemberTypeId > 1)
)
Order by base.Title 


GO
/****** Object:  StoredProcedure [dbo].[Library.GetMyLibrary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

[Library.GetMyLibrary] 2

*/
--get personal library
CREATE PROCEDURE [dbo].[Library.GetMyLibrary]
    @CreatedById int
As
SELECT     
    base.Id, 
    base.Title, 
    base.Description, 
    LibraryTypeId, 
    lt.Title as LibraryType,
    IsDiscoverable, 
        0 as OrgId,
    'Personal' As Organization,
    IsPublic, IsActive,
		base.PublicAccessLevel,
	base.OrgAccessLevel,
    base.ImageUrl, 
    base.Created, base.CreatedById, 
    base.LastUpdated, base.LastUpdatedById
    
FROM [Library] base
inner join [Library.Type] lt on base.LibraryTypeId = lt.Id
WHERE base.CreatedById = @CreatedById
And lt.Id = 1

GO
/****** Object:  StoredProcedure [dbo].[Library.GetMyOrgLibrary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

[Library.GetMyOrgLibrary] 2

*/
--get personal library
CREATE PROCEDURE [dbo].[Library.GetMyOrgLibrary]
    @OrgId int
As
SELECT     
    base.Id, 
    base.Title, 
    base.Description, 
    LibraryTypeId, 
    lt.Title as LibraryType,
    IsDiscoverable, 
	OrgId,
    'Personal' As Organization,
    IsPublic, IsActive,
    base.ImageUrl, 
    base.Created, base.CreatedById, 
    base.LastUpdated, base.LastUpdatedById
    
FROM [Library] base
inner join [Library.Type] lt on base.LibraryTypeId = lt.Id
WHERE base.OrgId = @OrgId
And lt.Id = 2


GO
/****** Object:  StoredProcedure [dbo].[Library.InvitationDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.InvitationDelete]
        @RowId uniqueidentifier
As
DELETE FROM [Library.Invitation]
WHERE RowId = @RowId

GO
/****** Object:  StoredProcedure [dbo].[Library.InvitationGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.InvitationGet]
	@Id int,
    @RowId varchar(36)
As
if @Id = 0 set @Id = NULL
if @RowId = '' OR @RowId = '00000000-0000-0000-0000-000000000000'  set @RowId = NULL

if @Id is null AND @RowId is null begin
	print '[Library.InvitationGet] Error: Incomplete parameters were provided'
	RAISERROR('[Library.InvitationGet] Error: incomplete parameters were provided. Require: @Id OR @RowId ', 18, 1)    
	RETURN -1 
	end

SELECT    Id, 
	LibraryId, 
    RowId, 
    InvitationType, 
    PassCode, 
    TargetEmail, 
    TargetUserId, 
    Subject, 
    MessageContent, 
    EmailNoticeCode, 
    Response, 
    ResponseDate, 
    ExpiryDate, 
    IsActive, 
    DeleteOnResponse, 
    Created, 
    CreatedById, 
    LastUpdated, 
    LastUpdatedById
FROM [Library.Invitation]
WHERE 
	(@Id = Id or Id is null)
And	(RowId = @RowId or @RowId is null)

GO
/****** Object:  StoredProcedure [dbo].[Library.InvitationInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Library.InvitationInsert]
            @LibraryId int, 
            @InvitationType varchar(50), 
            @PassCode varchar(50), 
            @TargetEmail varchar(150), 
            @TargetUserId int, 
            @Subject varchar(100), 
            @MessageContent varchar(MAX), 
            @EmailNoticeCode varchar(50), 
            @Response varchar(50), 
            @ResponseDate datetime, 
            @ExpiryDate datetime, 
            @DeleteOnResponse bit,  
            @CreatedById int

As

If @InvitationType = ''   SET @InvitationType = 'Personal' 
If @PassCode = ''   SET @PassCode = NULL 
If @TargetEmail = ''   SET @TargetEmail = NULL 
If @TargetUserId = 0   SET @TargetUserId = NULL 
If @Subject = ''   SET @Subject = NULL 
If @MessageContent = ''   SET @MessageContent = NULL 
If @EmailNoticeCode = ''   SET @EmailNoticeCode = NULL 
If @Response = ''   SET @Response = NULL 
If @ResponseDate = ''   SET @ResponseDate = NULL 
If @ExpiryDate = ''   SET @ExpiryDate = NULL 

If @CreatedById = 0   SET @CreatedById = NULL 

INSERT INTO [Library.Invitation] (

    LibraryId, 
    InvitationType, 
    PassCode, 
    TargetEmail, 
    TargetUserId, 
    Subject, 
    MessageContent, 
    EmailNoticeCode, 
    Response, 
    ResponseDate, 
    ExpiryDate, 
    DeleteOnResponse, 
    CreatedById, 
    LastUpdatedById
)
Values (

    @LibraryId, 
    @InvitationType, 
    @PassCode, 
    @TargetEmail, 
    @TargetUserId, 
    @Subject, 
    @MessageContent, 
    @EmailNoticeCode, 
    @Response, 
    @ResponseDate, 
    @ExpiryDate, 
    @DeleteOnResponse, 
    @CreatedById, 
    @CreatedById
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.LikeGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--use to check for existing like
CREATE PROCEDURE [dbo].[Library.LikeGet]
    @LibraryId int,
	@UserId int
As
SELECT     Id, 
    LibraryId, 
    IsLike, 
    Created, 
    CreatedById
FROM [Library.Like]
WHERE 
	LibraryId = @LibraryId
and CreatedById= @UserId

GO
/****** Object:  StoredProcedure [dbo].[Library.LikeInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.LikeInsert]
            @LibraryId int, 
            @IsLike bit, 
            @CreatedById int
As

If @CreatedById = 0   SET @CreatedById = NULL 
INSERT INTO [Library.Like] (

    LibraryId, 
    IsLike, 
    CreatedById
)
Values (

    @LibraryId, 
    @IsLike, 
    @CreatedById
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.LikeSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
select list of like respondants
*/
CREATE PROCEDURE [dbo].[Library.LikeSelect]
    @LibraryId int
As
SELECT     base.Id, 
    base.LibraryId, 
    IsLike, 
    base.Created, 
    base.CreatedById, 
	pos.Fullname, pos.Firstname
FROM [Library.Like] base
inner join [LR.PatronOrgSummary] pos on base.createdById = pos.UserId
WHERE LibraryId = @LibraryId 


GO
/****** Object:  StoredProcedure [dbo].[Library.LikeSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.LikeSummary] 1
*/
/*
Get summary of likes for the library
*/
CREATE PROCEDURE [dbo].[Library.LikeSummary]
    @LibraryId int
As
SELECT     
    LibraryId, 
     
  	SUM(CASE WHEN IsLike = 0 THEN 1 
			ELSE 0 END) AS DisLikes, 
	SUM(CASE WHEN IsLike = 1 THEN 1 
			ELSE 0 END) AS Likes, 
	SUM(1) AS Total

FROM [Library.Like] base
WHERE LibraryId = @LibraryId
Group By LibraryId


GO
/****** Object:  StoredProcedure [dbo].[Library.MemberDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.MemberDelete]
        @Id int
As
DELETE FROM [Library.Member]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.MemberGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

[Library.MemberGet] 1, 0, 0

*/
CREATE PROCEDURE [dbo].[Library.MemberGet]
    @Id int,
	@LibraryId int,
	@UserId int
As


If @Id = 0 And ( @LibraryId = 0 or @UserId = 0 ) begin
  RAISERROR('[Library.MemberGet] - invalid request. Require @Id, OR @LibraryId AND @UserId', 18, 1)  
  return -1
  end

if @Id = 0 set @Id = null
if @LibraryId = 0 set @LibraryId = null
if @UserId = 0 set @UserId = null


SELECT 
    base.Id, 
    base.LibraryId, 
    base.UserId, usr.SortName,
    base.MemberTypeId, 
   -- RowId, 
    base.Created, base.CreatedById, 
    base.LastUpdated, base.LastUpdatedById
FROM [Library.Member] base
Inner Join [LR.PatronOrgSummary] usr on base.UserId = usr.UserId
inner join [Codes.LibraryMemberType] lmt on base.MemberTypeId = lmt.Id
WHERE 
	(base.Id = @Id or @Id is null)
AND (base.LibraryId = @LibraryId or @LibraryId is null)
AND	(base.UserId = @UserId or @UserId is null)

GO
/****** Object:  StoredProcedure [dbo].[Library.MemberInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.MemberInsert]
            @LibraryId int, 
            @UserId int, 
            @MemberTypeId int,
			@CreatedById int

As
If @LibraryId = 0   SET @LibraryId = NULL 
If @UserId = 0   SET @UserId = NULL 
If @MemberTypeId = 0   SET @MemberTypeId = 1
 
if @LibraryId IS NULL OR @UserId IS NULL begin
	RAISERROR(' Error - LibraryId and UserId are required', 18, 1)   
	return -1
	end

INSERT INTO [Library.Member] (
    LibraryId, 
    UserId, 
    MemberTypeId,
	CreatedById, 
    LastUpdatedById
)
Values (
    @LibraryId, 
    @UserId, 
    @MemberTypeId,
	@CreatedById, 
    @CreatedById
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.MemberSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.MemberSelect]
	@LibraryId int
As

SELECT 
    base.Id, 
    base.LibraryId, 
    base.UserId, usr.SortName,
    base.MemberTypeId, 
   -- RowId, 
    base.Created, base.CreatedById, 
    base.LastUpdated, base.LastUpdatedById
FROM [Library.Member] base
Inner Join [LR.PatronOrgSummary] usr on base.UserId = usr.UserId
inner join [Codes.LibraryMemberType] lmt on base.MemberTypeId = lmt.Id
where LibraryId = @LibraryId


GO
/****** Object:  StoredProcedure [dbo].[Library.MemberUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- Update Procedure for [Library.Member] ---
CREATE PROCEDURE [dbo].[Library.MemberUpdate]
        @Id int, 
        @MemberTypeId int, 
        @LastUpdatedById int
As

If @MemberTypeId = 0   SET @MemberTypeId = 1 

if @Id = 0 OR @LastUpdatedById = 0 begin
	RAISERROR(' Error - LibraryId and UserId are required', 18, 1)   
	return -1
	end
UPDATE [Library.Member] 
SET 
    MemberTypeId = @MemberTypeId, 
    LastUpdated = GETDATE(), 
    LastUpdatedById = @LastUpdatedById
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.PartyMemberInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
@ParentRowId could be for library or librarySection
*/
CREATE PROCEDURE [dbo].[Library.PartyMemberInsert]
            @LibraryId int, 
            @UserId int, 
            @MemberTypeId int,
			@ParentRowId uniqueidentifier, 
			@CreatedById int

As
If @LibraryId = 0   SET @LibraryId = NULL 
If @UserId = 0   SET @UserId = NULL 
If @MemberTypeId = 0   SET @MemberTypeId = 1
 
if @LibraryId IS NULL OR @UserId IS NULL begin
	RAISERROR(' Error - LibraryId and UserId are required', 18, 1)   
	return -1
	end
declare @NewId uniqueidentifier, @Id int
set @NewId = newId()

INSERT INTO [Library.Member] (
    LibraryId, 
    UserId, 
    MemberTypeId,
	CreatedById, 
    LastUpdatedById,
	RowId
)
Values (
    @LibraryId, 
    @UserId, 
    @MemberTypeId,
	@CreatedById, 
    @CreatedById,
	@NewId
)
 
set @Id = SCOPE_IDENTITY() 

INSERT INTO [Library.Party] (

    ParentRowId, 
    RelatedRowId
)
Values (

    @ParentRowId, 
    @NewId
)

select @Id As Id, @newId as RelatedRowId

GO
/****** Object:  StoredProcedure [dbo].[Library.PurgeOrphanResource]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
SELECT base.[Id]      ,[LibrarySectionId]      ,[ResourceIntId]
  FROM [IsleContent].[dbo].[Library.Resource] base
  left join Isle_IOER.[dbo].[Resource] res on base.ResourceIntId = res.Id
  where res.[ResourceUrl] is null



Exec [Library.PurgeOrphanResource] 
        
*/

--- Purge Procedure for [Library.Resource] ---
CREATE PROCEDURE [dbo].[Library.PurgeOrphanResource]
As

DELETE FROM [dbo].[Library.Resource]
  FROM [IsleContent].[dbo].[Library.Resource] base
  left join Isle_IOER.[dbo].[Resource] res on base.ResourceIntId = res.Id
  where res.[ResourceUrl] is null


GO
/****** Object:  StoredProcedure [dbo].[Library.ResourceCopy]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
SELECT 
    Id, CreatedById, LibrarySectionId,
    ResourceIntId
FROM [Library.Resource]
order by CreatedById, LibrarySectionId

[Library.ResourceCopy] 0, 0, 391196, 63, 2

[Library.ResourceCopy] 5, 0, 0, 5, 2
        
-dups
[Library.ResourceCopy] 5, 0, 0, 1, 2

[Library.ResourceCopy] 0, 5, 438562, 5, 2

[Library.ResourceCopy] 0, 5, 444654, 4, 2

*/
/*
--- Update Procedure for [Library.Resource] ---
Modifications
14-01-09 mparsons - removing @SourceLibrarySectionId (will physically remove later)
*/
CREATE PROCEDURE [dbo].[Library.ResourceCopy]
        @LibraryResourceId int,
		@SourceLibrarySectionId int,
		@ResourceIntId int,
        @NewLibrarySectionId int,
        @CreatedById int

As
If @LibraryResourceId = 0		SET @LibraryResourceId = NULL 
If @ResourceIntId = 0			SET @ResourceIntId = NULL 
If @SourceLibrarySectionId = 0  SET @SourceLibrarySectionId = NULL 
If @NewLibrarySectionId = 0		SET @NewLibrarySectionId = NULL 

if (@LibraryResourceId is null AND @ResourceIntId is null) OR @NewLibrarySectionId is null begin
  print '[Library.ResourceCopy] Error: Incomplete parameters were provided'
	RAISERROR('[Library.ResourceCopy] Error: incomplete parameters were provided. Require destination @NewLibrarySectionId, and Source @LibraryResourceId, or  @ResourceIntId', 18, 1)    
	RETURN -1 
  end

  --check for dups
if @LibraryResourceId is not null begin
	if exists( SELECT target.ResourceIntId FROM dbo.[Library.Resource] AS base INNER JOIN dbo.[Library.Resource] AS target ON base.ResourceIntId = target.ResourceIntId
			WHERE (target.LibrarySectionId = @NewLibrarySectionId) AND (base.Id = @LibraryResourceId)
		) begin
		print '[Library.ResourceCopy] Error: resource already exists in collection'
		RAISERROR('[Library.ResourceCopy] Error: resource already exists in collection', 18, 1)    
		RETURN -1 
		end 
	else begin
		SELECT @ResourceIntId = isnull(ResourceIntId,0) FROM [Library.Resource] where Id = @LibraryResourceId
		if (@ResourceIntId is null OR @ResourceIntId =0) begin
		  print '[Library.ResourceCopy] Error: Incomplete parameters were provided'
			RAISERROR('[Library.ResourceCopy] Error: invalid @LibraryResourceId - not found', 18, 1)    
			RETURN -1 
		  end
		end
	end
else begin
	if exists(SELECT [ResourceIntId] FROM [dbo].[Library.Resource] 
		where [ResourceIntId]= @ResourceIntId and LibrarySectionId = @NewLibrarySectionId) begin
		print '[Library.ResourceCopy] Error: resource already exists in collection'
		RAISERROR('[Library.ResourceCopy] Error: resource already exists in collection', 18, 1)    
		RETURN -1 
		end 
	end
		  

INSERT INTO [Library.Resource] (

    LibrarySectionId, 
    ResourceIntId, 
    Created, 
    CreatedById
)
Values (

    @NewLibrarySectionId, 
    @ResourceIntId, 
    getdate(), 
    @CreatedById
)
--SELECT 
--    @NewLibrarySectionId, 
--    ResourceIntId,  
--    getdate(), 
--    @CreatedById
--FROM [Library.Resource]
--where 
--	(Id = @LibraryResourceId OR @LibraryResourceId is null)
--AND (ResourceIntId = @ResourceIntId OR @ResourceIntId is null)

select isnull(SCOPE_IDENTITY(),0) as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.ResourceDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
[Library.ResourceDelete] 0, 0,0
[Library.ResourceDelete] 0, 1,0
[Library.ResourceDelete] 0, 0,1

[Library.ResourceDelete] 178, 0,0

[Library.ResourceDelete] 0, 79,447822

*/
CREATE PROCEDURE [dbo].[Library.ResourceDelete]
        @LibraryResourceId int,
		@SourceLibrarySectionId int,
		@ResourceIntId int

As
If @LibraryResourceId = 0		SET @LibraryResourceId = NULL 
If @SourceLibrarySectionId = 0  SET @SourceLibrarySectionId = NULL 
If @ResourceIntId = 0			SET @ResourceIntId = NULL 

if @LibraryResourceId is null AND (@SourceLibrarySectionId is null OR @ResourceIntId is null) begin
  print '[Library.ResourceDelete] Error: Incomplete parameters were provided'
	RAISERROR('[Library.ResourceDelete] Error: incomplete parameters were provided. Require Source @LibraryResourceId, or  (@SourceLibrarySectionId AND @ResourceIntId)', 18, 1)    
	RETURN -1 
  end

DELETE FROM [Library.Resource]
where 
	(Id = @LibraryResourceId OR @LibraryResourceId is null)
AND (ResourceIntId = @ResourceIntId OR @ResourceIntId is null)
AND (LibrarySectionId = @SourceLibrarySectionId OR @SourceLibrarySectionId is null)


GO
/****** Object:  StoredProcedure [dbo].[Library.ResourceGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.ResourceGet]
    @Id int
As
SELECT     
	Id, 
	Id As LibraryResourceId,
    LibrarySectionId, 
    ResourceIntId, 
    Comment, 
    Created, 
    CreatedById
FROM [Library.Resource]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.ResourceInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
select top 200 * from [resource.version_summary]



[Library.ResourceInsert] 1, 0, 153249, 'TBD', 2

*/
/*
need to handle insert by code (for views, published, etc
If @LibrarySectionId is 0, and have a code, would need to look up by code and createdById
  - would have to handle creating of the section for the first time.
  - might be cleaner to handle server side
  
- we may want to handle my published differently anyway - or allow to delete?
  - if persisting under Resource.PublishedBy, no need to persist specifically, just allow display
- we could allow null section id - useful for quick adds
*/
CREATE PROCEDURE [dbo].[Library.ResourceInsert]
            @LibraryId int, 
            @LibrarySectionId int, 
            @ResourceIntId int, 
            @Comment varchar(500), 
            @CreatedById int
As
If @ResourceIntId = 0   SET @ResourceIntId = NULL 
If @LibrarySectionId = 0   SET @LibrarySectionId = NULL 
If @LibraryId = 0   SET @LibraryId = NULL 
If @Comment = ''   SET @Comment = NULL 
If @CreatedById = 0   SET @CreatedById = NULL 

If (@LibrarySectionId is null AND @LibraryId is null) OR @ResourceIntId is null begin
  print '[Library.ResourceInsert] Error: Incomplete parameters were provided'
	RAISERROR('[Library.ResourceInsert] Error: incomplete parameters were provided. Require Source @ResourceIntId, and @sectionId or @LibraryId', 18, 1)    
	RETURN -1 
  end
declare @sectionId int
,@availableSectionsCount int
,@setSectionAsDefault bit

set @setSectionAsDefault= 0

  
If @LibrarySectionId is null begin
    print '@LibrarySectionId not include, get default'
   select @LibrarySectionId = isnull(Id,0) from [Library.Section] where LibraryId = @LibraryId and IsDefaultSection = 1
   if @LibrarySectionId is null or @LibrarySectionId = 0 begin
      print 'default section not found, get min updateable'
      select @LibrarySectionId = isnull(min(Id),0) from [Library.Section] where LibraryId = @LibraryId and AreContentsReadOnly = 0
      if @LibrarySectionId is null or @LibrarySectionId = 0 begin
        print 'no available updateable sections, creating'
        --create
        INSERT INTO [dbo].[Library.Section]
           ([LibraryId]
           ,[SectionTypeId]
           ,[Description]
           ,[ParentId]
           ,[IsDefaultSection]
           ,[AreContentsReadOnly]
           ,[Created]
           ,[CreatedById]
           ,[LastUpdated]
           ,[LastUpdatedById])
         VALUES
               (@LibraryId, 
               3, 
               'Default section', 
               null, 
               1, 
               0, 
               getdate(), @CreatedById, 
               getdate(), @CreatedById 
                )
        set @LibrarySectionId = SCOPE_IDENTITY()
        end  --insert 
     else begin
        -- set as default
        UPDATE [dbo].[Library.Section]    
          SET [IsDefaultSection] = 1
        WHERE id = @LibrarySectionId
        end --min updateable found
      end --= default not found
      
   end --get default
   
--check for dups
if exists(SELECT [ResourceIntId] FROM [dbo].[Library.Resource] 
    where [ResourceIntId]= @ResourceIntId and LibrarySectionId = @LibrarySectionId) begin
    print '[Library.ResourceInsert] Error: resource already exists in collection'
    RAISERROR('[Library.ResourceInsert] Error: resource already exists in collection', 18, 1)    
    RETURN -1 
    end   
    
INSERT INTO [Library.Resource] (

    LibrarySectionId, 
    ResourceIntId, 
    Comment, 
    Created, 
    CreatedById
)
Values (

    @LibrarySectionId, 
    @ResourceIntId, 
    @Comment, 
    getdate(), 
    @CreatedById
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.ResourceMove]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
SELECT 
    Id, CreatedById, LibrarySectionId,
    ResourceIntId
FROM [Library.Resource]
order by CreatedById, LibrarySectionId

[Library.ResourceMove] 0, 0, 0, 5, 2

[Library.ResourceMove] 5, 0, 0, 5, 2

--dup
[Library.ResourceMove] 14, 0, 0, 1, 2
        
*/

--- Move Procedure for [Library.Resource] ---
CREATE PROCEDURE [dbo].[Library.ResourceMove]
        @LibraryResourceId		int,
		@SourceLibrarySectionId int,
		@ResourceIntId			int,
        @NewLibrarySectionId	int,
        @CreatedById int

As
If @LibraryResourceId = 0		SET @LibraryResourceId = NULL 
If @ResourceIntId = 0			SET @ResourceIntId = NULL 
If @SourceLibrarySectionId = 0  SET @SourceLibrarySectionId = NULL 
If @NewLibrarySectionId = 0		SET @NewLibrarySectionId = NULL  

if @LibraryResourceId is null AND (@SourceLibrarySectionId is null OR @ResourceIntId is null) begin
  print '[Library.ResourceMove] Error: Incomplete parameters were provided'
	RAISERROR('[Library.ResourceMove] Error: incomplete parameters were provided. Require Source @LibraryResourceId, or  (@SourceLibrarySectionId AND @ResourceIntId)', 18, 1)    
	RETURN -1 
  end

  --check for dups==> doesn't matter, as move to itself is not an error!
if @LibraryResourceId is not null begin
	if exists( SELECT target.ResourceIntId FROM dbo.[Library.Resource] AS base INNER JOIN dbo.[Library.Resource] AS target ON base.ResourceIntId = target.ResourceIntId
			WHERE (target.LibrarySectionId = @NewLibrarySectionId) AND (base.Id = @LibraryResourceId)
		) begin
		print '[Library.ResourceMove] Error: resource already exists in collection'
		RAISERROR('[Library.ResourceMove] Error: resource already exists in collection', 18, 1)    
		RETURN -1 
		end 
	end
else begin
	if exists(SELECT [ResourceIntId] FROM [dbo].[Library.Resource] 
		where [ResourceIntId]= @ResourceIntId and LibrarySectionId = @NewLibrarySectionId) begin
		print '[Library.ResourceMove] Error: resource already exists in collection'
		RAISERROR('[Library.ResourceMove] Error: resource already exists in collection', 18, 1)    
		RETURN -1 
		end 
	end
		  
UPDATE [Library.Resource] 
SET 
    LibrarySectionId = @NewLibrarySectionId,
    CreatedById = @CreatedById
WHERE 
	(Id = @LibraryResourceId OR @LibraryResourceId is null)
AND (ResourceIntId = @ResourceIntId OR @ResourceIntId is null)
AND (LibrarySectionId = @SourceLibrarySectionId OR @SourceLibrarySectionId is null)

GO
/****** Object:  StoredProcedure [dbo].[Library.ResourceSearch]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

--set @Filter = @Filter + ' OR FREETEXT(lrs.SubjectCsv, ''physic'') '
set @Filter = @Filter + ' OR lrs.SubjectsIdx like ''%physic%'' '

set @Filter = ' where  (lr.Title like ''a %'' OR lr.[Description] like ''a %'' OR lr.[ResourceUrl] like ''a %'' OR lrs.Subject like ''a %'' OR lr.Keywords like ''a %'') '
-- OR lr.[Description] like ''%Finance%'' OR lr.[Description] like ''%Manufacturing%'' 
set @Filter = ' where (LibraryTypeId = 1 and lib.LibraryCreatedById = 2) AND ( (lr.Title like ''%mouse%'' OR lr.[Description] like ''%mouse%'' OR lrs.[Subject] like '%mouse%' ) ) '
 

--=====================================================

DECLARE @RC int,@SortOrder varchar(100),@Filter varchar(5000)
DECLARE @StartPageIndex int, @PageSize int, @TotalRows int
--
set @SortOrder = ''

-- blind search 
set @Filter = ''
                       
set @Filter = ' where ( lr.id in (select ResourceIntId from [Resource.Language] where LanguageId in (1)) ) AND ( (lr.AccessRightsId in (2,4)) ) AND ( lr.id in (select ResourceIntId from [Resource.Cluster] where ClusterId in (8,11)) )  '


set @filter = ' where   ([IsDiscoverable] = 1 )  '
                     
set @filter = ' where    (LibraryTypeId = 1 and LibraryCreatedById = 2)'
 
--set @filter = ' where   (LibraryId = 1 )'
 
set @filter = ' where   ( (LibraryTypeId = 1 and LibraryCreatedById = 2) AND ((lr.id in (select ResourceIntId from (SELECT [ResourceIntId], count(*) As RecCount FROM [dbo].[LR.ResourceStandard] group by [ResourceIntId] ) As ResStandards )) ) )'


set @StartPageIndex = 1
set @PageSize = 55
--set statistics time on       
EXECUTE @RC = [Library.ResourceSearch]
     @Filter,@SortOrder  ,@StartPageIndex  ,@PageSize, @TotalRows OUTPUT

select 'total rows = ' + convert(varchar,@TotalRows)

--set statistics time off       


*/

/* =============================================
      Description:      Library Resource search
  Uses custom paging to only return enough rows for one page
     Options:

  @StartPageIndex - starting page number. If interface is at 20 when next
page is requested, this would be set to 21?
  @PageSize - number of records on a page
  @TotalRows OUTPUT - total available rows. Used by interface to build a
custom pager
  ------------------------------------------------------
Modifications
13-03-12 mparsons - new

*/

CREATE PROCEDURE [dbo].[Library.ResourceSearch]
		@Filter           varchar(5000)
		,@SortOrder       varchar(100)
		,@StartPageIndex  int
		,@PageSize        int
		,@TotalRows       int OUTPUT

As

SET NOCOUNT ON;
-- paging
DECLARE
      @first_id               int
      ,@startRow        int
      ,@debugLevel      int
      ,@SQL             varchar(5000)
      ,@OrderBy         varchar(100)


-- =================================

Set @debugLevel = 4

if len(@SortOrder) > 0
      set @OrderBy = ' Order by ' + @SortOrder
else
      set @OrderBy = ' Order by lr.SortTitle '

--===================================================
-- Calculate the range
--===================================================
SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

 
-- =================================
CREATE TABLE #tempWorkTable(
      RowNumber         int PRIMARY KEY IDENTITY(1,1) NOT NULL,
      LibraryId int,
      LibraryResourceId    int,
      Title             varchar(200)
)

-- =================================

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter
     end

  print '@Filter len: '  +  convert(varchar,len(@Filter))
  set @SQL = 'SELECT distinct lib.LibraryId, lib.LibraryResourceId, lr.SortTitle 
        FROM [dbo].[Library.SectionResourceSummary] lib 
        inner join [dbo].[LR.ResourceVersion_Summary] lr on lib.ResourceIntId = lr.ResourceIntId '
        + @Filter
        
  if charindex( 'order by', lower(@Filter) ) = 0
    set @SQL = @SQL + ' ' + @OrderBy

  print '@SQL len: '  +  convert(varchar,len(@SQL))
  print @SQL

  INSERT INTO #tempWorkTable (LibraryId, LibraryResourceId, Title)
  exec (@SQL)
  --print 'rows: ' + convert(varchar, @@ROWCOUNT)
  SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Calculate the range
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

-- =================================
--SELECT Distinct TOP (@PageSize)
SELECT Distinct    
    RowNumber,
    lib.[LibraryId] ,[Library]
    ,lib.[LibraryTypeId]
    ,lib.[LibraryType]
    --,[OrgId]
    ,lib.[IsDiscoverable]
    ,lib.[IsPublic]
    ,lib.[LibraryCreatedById]
	,convert(varchar(11),lib.DateAddedToCollection,109) As DateAddedToCollection
	--,convert(varchar(11),lib.DateAddedToCollection,120) As DateAddedToCollection2
    ,lib.[LibrarySectionId], lib.LibrarySection
    ,lib.[SectionTypeId] ,[LibrarySectionType]
    ,lib.[IsDefaultSection]
    ,lib.[AreContentsReadOnly]
    ,lib.LibraryResourceId
    ,lib.[ResourceIntId]
    ,lib.DateAddedToCollection
	,lib.libResourceCreatedById
    --,lr.ResourceVersionId As RowId,
    ,lr.ResourceVersionIntId,
    lr.ResourceUrl,
	convert(varchar(11),lr.[Modified],109) As ResourceCreated,
    CASE
      WHEN lr.Title IS NULL THEN 'No Title'
      WHEN len(lr.Title) = 0 THEN 'No Title'
      ELSE lr.Title
    END AS Title
    ,lr.SortTitle
    ,lr.[Description]
    ,isnull(Publisher,'Unknown') As Publisher
    ,rtrim(ltrim(isnull(Creator,''))) As Creator

		,isnull([LikeCount], 0) As [LikeCount]
    ,isnull([DislikeCount], 0) As [DislikeCount]
		,Rights
    ,AccessRights
    ,isnull(UserComments.RecordsCount, 0) As NbrComments
    ,isnull(ResStandards.RecordsCount, 0) As NbrStandards
    ,isnull(evals.EvaluationsCount, 0)    As NbrEvaluations
    
From #tempWorkTable
    Inner join  [dbo].[Library.SectionResourceSummary] lib on #tempWorkTable.LibraryResourceId = lib.LibraryResourceId
    Inner join  [dbo].[lr.ResourceVersion_Summary] lr on lib.ResourceIntId = lr.ResourceIntId
    
    left Join   [dbo].[LR.ResourceLikesSummary] rlike on lr.ResourceIntId = rlike.ResourceIntId
    
    left join (SELECT [ResourceIntId], count(*) as RecordsCount FROM [dbo].[LR.ResourceComment]
  group by [ResourceIntId]) As UserComments on lib.ResourceIntId = UserComments.ResourceIntId

    left join (SELECT [ResourceIntId], count(*) as RecordsCount FROM dbo.[LR.ResourceStandard]
  group by [ResourceIntId]) As ResStandards on lib.ResourceIntId = ResStandards.ResourceIntId

    left join [LR.Resource.EvaluationsCount] evals on lib.ResourceIntId = evals.ResourceIntId


WHERE RowNumber > @first_id
order by RowNumber 


GO
/****** Object:  StoredProcedure [dbo].[Library.ResourceUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- Update Procedure for [Library.Resource] ---
CREATE PROCEDURE [dbo].[Library.ResourceUpdate]
        @Id int,
        @Comment varchar(500)
As

If @Comment = ''   SET @Comment = NULL 

UPDATE [Library.Resource] 
SET 
    Comment = @Comment
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionCommentSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Select all comments for a library
- or do we want to implement paging?
*/
CREATE PROCEDURE [dbo].[Library.SectionCommentSelect]
    @SectionId int
As
SELECT     
	Id, 
    SectionId, 
    Comment, 
    base.Created, 
    base.CreatedById, pos.Fullname, pos.Firstname, pos.Lastname
FROM [Library.SectionComment] base
inner join [LR.PatronOrgSummary] pos on base.createdById = pos.UserId
WHERE SectionId = @SectionId
Order by base.created desc

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Delete a collection
Modifications
140309 mparsons - need yo manually delete external collections, if exists
				- only promote if [Library.ExternalSection] in use

*/
CREATE PROCEDURE [dbo].[Library.SectionDelete]
        @Id int
As

--check for external sections (probably don't need to bother with exits check)
if exists(SELECT Id FROM [Library.ExternalSection] base where base.externalSectionId = @Id ) begin
    print 'external sections found'
    DELETE FROM [Library.ExternalSection] WHERE ExternalSectionId = @Id
    end   

DELETE FROM [Library.Section]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

[Library.SectionGet] 0, ''

[Library.SectionGet] 1, ''

[Library.SectionGet] 0, '4FDDEF88-46A8-4C17-AC89-B5FE5EAA69D3'

modifications
14-01-10 mparsons - updated to return rowId
14-01-12 mparsons - updated to optionally retrieve by rowId
*/
CREATE PROCEDURE [dbo].[Library.SectionGet]
    @Id int,
	@RowId varchar(50)
As
If @Id = 0   SET @Id = NULL 
If @RowId = '' OR @RowId = '00000000-0000-0000-0000-000000000000'  SET @RowId = NULL 

if @Id IS NULL And @RowId is null begin
	RAISERROR(' Error - either Library section Id or Library section RowId are required', 18, 1)   
	return -1
	end
SELECT     
    base.Id, 
    LibraryId, lib.Title As LibraryTitle,
    base.Title,
    SectionTypeId, lst.Title As SectionType ,
    base.Description, 
    ParentId, 
    base.IsDefaultSection, base.IsPublic,
	base.PublicAccessLevel,
	base.OrgAccessLevel,
    base.AreContentsReadOnly, 
    base.ImageUrl, Lib.ImageUrl As LibraryImageUrl,
    base.Created, 
    base.CreatedById, 
    base.LastUpdated, 
    base.LastUpdatedById,
	    base.RowId
    
FROM [Library.Section] base
Inner join [Library] lib on base.LibraryId = lib.Id
Inner join [Library.SectionType] lst on base.SectionTypeId = lst.Id

WHERE 
	(base.Id = @Id OR @Id is null)
AND (base.RowId = @RowId or @RowId is null)

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionGetDefault]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
-- could use a search instead

[Library.SectionGetDefault] 1

*/
CREATE PROCEDURE [dbo].[Library.SectionGetDefault]
    @LibraryId int
    --,@CreatedById int
As
If @LibraryId = 0   SET @LibraryId = NULL 
--If @CreatedById = 0   SET @CreatedById = NULL 

SELECT     
    base.Id, 
    LibraryId, lib.Title As LibraryTitle,
    base.Title,
    SectionTypeId, lst.Title As SectionType ,
    base.Description, 
    ParentId, 
    base.IsDefaultSection, base.IsPublic,
	base.PublicAccessLevel,
	base.OrgAccessLevel,
    base.AreContentsReadOnly, 
    base.ImageUrl, Lib.ImageUrl As LibraryImageUrl,
    base.Created, 
    base.CreatedById, 
    base.LastUpdated, 
    base.LastUpdatedById
FROM [Library.Section] base
Inner join [Library] lib on base.LibraryId = lib.Id
Inner join [Library.SectionType] lst on base.SectionTypeId = lst.Id

WHERE LibraryId = @LibraryId
--And CreatedById = @CreatedById
And base.IsDefaultSection= 1


GO
/****** Object:  StoredProcedure [dbo].[Library.SectionInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Insert a Library.Section
Modifications
14-01-09 mparsons - added @ImageUrl
14-01-10 mparsons - added rowId - done explicityly now to facilitate use for the imageUrl.
					Added logic to unset a existing default collection setting if the new one is to be the default
*/
CREATE PROCEDURE [dbo].[Library.SectionInsert]
            @LibraryId int, 
            @SectionTypeId int, 
            @Title varchar(100),
            @Description varchar(500), 
            @IsDefaultSection bit, 
            @PublicAccessLevel int, 
            @OrgAccessLevel int, 
            @AreContentsReadOnly bit, 
            @ParentId int, 
            @CreatedById int,
			@ImageUrl varchar(200),
			@RowId varchar(50)
As
If @Title = ''			SET @Title = 'Missing - TBD' 
If @Description = ''	SET @Description = NULL 
If @ImageUrl = ''		SET @ImageUrl = NULL 
If @ParentId = 0		SET @ParentId = NULL 
If @CreatedById = 0		SET @CreatedById = NULL 
If @RowId = '' OR @RowId = '00000000-0000-0000-0000-000000000000'  SET @RowId = newId() 

declare @IsPublic bit
-- temp check during transition
if  @PublicAccessLevel = 0 begin
	set @IsPublic= 0
	end
	else begin
	set @IsPublic= 1
	if @OrgAccessLevel = 0
		set @OrgAccessLevel= 2
	end

if @IsDefaultSection = 1 begin
  --unset any existing
  update [Library.Section] set IsDefaultSection = 0 
  WHERE LibraryId = @LibraryId 
  end


INSERT INTO [Library.Section] (

    LibraryId, 
    SectionTypeId, 
    Title,
    Description, 
    ParentId, 
    IsDefaultSection,
	PublicAccessLevel,
	OrgAccessLevel,
	IsPublic,
    AreContentsReadOnly, 
	ImageUrl,
    CreatedById, 
    LastUpdatedById,
	RowId
)
Values (

    @LibraryId, 
    @SectionTypeId, 
    @Title,
    @Description, 
    @ParentId, 
    @IsDefaultSection, 
	@PublicAccessLevel,
	@OrgAccessLevel,
    @IsPublic,
    @AreContentsReadOnly, 
	@ImageUrl,
    @CreatedById, 
    @CreatedById,
	@RowId
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionLikeGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--use to check for existing like
CREATE PROCEDURE [dbo].[Library.SectionLikeGet]
    @SectionId int,
	@UserId int
As
SELECT     Id, 
    SectionId, 
    IsLike, 
    Created, 
    CreatedById
FROM [Library.SectionLike]
WHERE 
	SectionId = @SectionId
and CreatedById= @UserId

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionLikeInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Library.SectionLikeInsert]
            @SectionId int, 
            @IsLike bit, 
            @CreatedById int
As

If @CreatedById = 0   SET @CreatedById = NULL 
INSERT INTO [Library.SectionLike] (

    SectionId, 
    IsLike, 
    CreatedById
)
Values (

    @SectionId, 
    @IsLike, 
    @CreatedById
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionLikeSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Get summary of likes for the collection
*/
CREATE PROCEDURE [dbo].[Library.SectionLikeSelect]
    @SectionId int
As
SELECT     
	Id, 
    SectionId, 
    IsLike, 
    base.Created, 
    base.CreatedById,  
	pos.Fullname, pos.Firstname
FROM [Library.SectionLike] base
inner join [LR.PatronOrgSummary] pos on base.createdById = pos.UserId
WHERE SectionId = @SectionId

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionLikeSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
[Library.SectionLikeSummary] 2
*/
/*
Get summary of likes for the collection
*/
CREATE PROCEDURE [dbo].[Library.SectionLikeSummary]
    @SectionId int
As
SELECT     
    SectionId, 
     
  	SUM(CASE WHEN IsLike = 0 THEN 1 
			ELSE 0 END) AS DisLikes, 
	SUM(CASE WHEN IsLike = 1 THEN 1 
			ELSE 0 END) AS Likes, 
	SUM(1) AS Total

FROM [Library.SectionLike] base
WHERE SectionId = @SectionId
Group By SectionId


GO
/****** Object:  StoredProcedure [dbo].[Library.SectionMember_Search]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

-- ===========================================================

DECLARE @RC int,@Filter varchar(500), @StartPageIndex int, @PageSize int, @totalRows int,@SortOrder varchar(100)
set @SortOrder = '' 
set @Filter = ' LibraryId = 1 '
set @Filter = ' Userid = 2 '                 
set @StartPageIndex = 1
set @PageSize = 15

exec [Library.SectionMember_Search] @Filter, @SortOrder, @StartPageIndex  ,@PageSize  ,@totalRows OUTPUT

select 'total rows = ' + convert(varchar,@totalRows)


*/

/* =================================================
= Library.SectionMember_Search
=		@StartPageIndex - starting page number. If interface is at 20 when next page is requested, this would be set to 21?
=		@PageSize - number of records on a page
=		@totalRows OUTPUT - total available rows. Used by interface to build a custom pager
= ------------------------------------------------------
= Modifications
= 14-02-04 mparsons - Created 
-- ================================================= */
Create PROCEDURE [dbo].[Library.SectionMember_Search]
		@Filter				    varchar(500)
		,@SortOrder	      varchar(500)
		,@StartPageIndex  int
		,@PageSize		    int
		,@TotalRows			  int OUTPUT
AS 
DECLARE 
@first_id			int
,@startRow		int
,@debugLevel	int
,@SQL             varchar(5000)
,@OrderBy         varchar(100)

	SET NOCOUNT ON;

-- ==========================================================
Set @debugLevel = 4
if len(@SortOrder) > 0
	set @OrderBy = ' Order by ' + @SortOrder
else 
  set @OrderBy = ' Order by Library, Collection, SortName '
--===================================================
-- Calculate the range
--===================================================
SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

 
-- =================================
CREATE TABLE #tempWorkTable(
	RowNumber int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Id int NOT NULL,
	UserId int
)
-- =================================

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter
     end
 
set @SQL = 'SELECT [Id] ,[UserId]   FROM [dbo].[Library.SectionMemberSummary] 	  '  
	  + @Filter

if charindex( 'order by', lower(@Filter) ) = 0 
	set @SQL = 	@SQL + @OrderBy
if @debugLevel > 3 begin
  print '@SQL len: '  +  convert(varchar,len(@SQL))
	print @SQL
	end
	
INSERT INTO #tempWorkTable (Id,  UserId)
exec (@sql)
   SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Show the StartPageIndex
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

SELECT     Distinct
		RowNumber,
		lib.[Id],
	lib.LibraryId, 
	lib.Library,
	lib.LibrarySectionId,
	lib.[Collection]
      ,lib.[UserId]
      ,[FullName]
      ,[SortName]
      ,[Email]
      ,[MemberTypeId]
      ,[MemberType]
      ,CONVERT(varchar(10), lib.Created, 120) As Created
      ,[CreatedById]
	  ,CONVERT(varchar(10), lib.[LastUpdated], 120) As [LastUpdated]
      ,[LastUpdatedById]
  
From #tempWorkTable temp
    Inner Join [dbo].[Library.SectionMemberSummary] lib on temp.Id = lib.Id

WHERE RowNumber > @first_id 
order by RowNumber		

SET ROWCOUNT 0

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionSearch]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

-- ===========================================================

DECLARE @RC int,@Filter varchar(500), @StartPageIndex int, @PageSize int, @totalRows int,@SortOrder varchar(100)
set @SortOrder = '' 
set @Filter = ' ResourceLastAddedDate > ''2013-06-01'' '

set @Filter = ' base.Id in (Select LibrarySectionId from [Library.SectionMember] where userid = 2 ) '  

set @Filter = ' lib.Id in (Select LibraryId from [Library.Member] where userid = 2 ) '  

--set @Filter = ' base.Id in (Select SectionId from [Library.SectionSubscription] where userid = 2 ) '           
--set @Filter = ' '

set @StartPageIndex = 1
set @PageSize = 15

exec [Library.SectionSearch] @Filter, @SortOrder, @StartPageIndex  ,@PageSize  ,@totalRows OUTPUT

select 'total rows = ' + convert(varchar,@totalRows)


*/

/* ==========================================================================================
= Library collection search
=		@StartPageIndex - starting page number. If interface is at 20 when next page is requested, this would be set to 21?
=		@PageSize - number of records on a page
=		@totalRows OUTPUT - total available rows. Used by interface to build a custom pager
= ------------------------------------------------------
= Modifications
= 14-02-24 mparsons - Created 
-- ========================================================================================= */
Create PROCEDURE [dbo].[Library.SectionSearch]
	@Filter				varchar(500)
	,@SortOrder			varchar(500)
	,@StartPageIndex	int
	,@PageSize			int
	,@TotalRows			int OUTPUT
AS 
DECLARE 
	@first_id			int
	,@startRow		int
	,@debugLevel	int
	,@SQL             varchar(5000)
	,@OrderBy         varchar(100)

	SET NOCOUNT ON;

-- ==========================================================
Set @debugLevel = 4
if len(@SortOrder) > 0
	set @OrderBy = ' Order by ' + @SortOrder
else 
  set @OrderBy = ' Order by lib.Title '
--===================================================
-- Calculate the range
--===================================================
SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

 
-- =================================
CREATE TABLE #tempWorkTable(
	RowNumber int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Id int NOT NULL,
	Title varchar(100),
	TotalResources int
)
-- =================================

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter
     end
 
set @SQL = 'SELECT base.Id, base.Title, isnull(lrt.TotalResources,0) As TotalResources FROM [Library.Section]  base
		Inner Join [Library] lib on base.LibraryId = lib.Id
	  Left Join [LR.PatronOrgSummary] owner on lib.CreatedById = owner.Userid
	  Left join [Gateway.OrgSummary] org on lib.OrgId = org.id
	  Left Join [Library.SectionType] sect on base.SectionTypeId = sect.Id 
	  Left Join ( SELECT LibrarySectionId, max([ResourceCreated]) ResourceLastAddedDate  FROM [dbo].[Library.SectionResourceSummary] group by LibrarySectionId) 
				As SectionLastActivity  on base.Id = SectionLastActivity.LibrarySectionId
	  left join (SELECT LibrarySectionId, count(*) As TotalResources
		  FROM [Library.SectionResourceSummary] group by LibrarySectionId) 
		  As lrt on base.id = lrt.LibrarySectionId
	  '  
	  + @Filter

if charindex( 'order by', lower(@Filter) ) = 0 
	set @SQL = 	@SQL + @OrderBy
if @debugLevel > 3 begin
  print '@SQL len: '  +  convert(varchar,len(@SQL))
	print @SQL
	end
	
INSERT INTO #tempWorkTable (Id, Title, TotalResources)
exec (@sql)
   SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Show the StartPageIndex
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

SELECT     Distinct
	RowNumber,
	--==================================================================================================
    lib.Id As LibraryId,     lib.Title as LibraryTitle,     lib.Description As LibraryDescription, 
    LibraryTypeId, libt.Title as LibraryType,
	case when lib.PublicAccessLevel > 1 then 'Public'
      else 'Private' end as LibraryViewType,
    case when isnull(lib.ImageUrl,'') = '' then 'defaultUrl' else lib.ImageUrl end as LibraryImageUrl, 
    lib.OrgId,
	case when isnull(lib.OrgId,0) > 0 then org.Name 
      when isnull(creator.OrganizationId,0) > 0 then creator.Organization 
      else 'Personal' end as Organization,
	--==================================================================================================
	coll.Id, coll.Id As SectionId, coll.Title,     coll.Description, 
    SectionTypeId, sect.Title as SectionType,
    coll.IsDefaultSection,
	coll.PublicAccessLevel,
	coll.OrgAccessLevel,
	coll.AreContentsReadOnly,
    case when coll.PublicAccessLevel > 1 then 'Public'
      else 'Private' end as ViewType,
    case when isnull(coll.ImageUrl,'') = '' then 'defaultUrl' else coll.ImageUrl end as ImageUrl, 
    
    isnull(lrt.TotalResources,0) As TotalResources,
    coll.Created, coll.CreatedById, coll.LastUpdated, coll.LastUpdatedById
    
	,case 
		when creator.userid is not null Then creator.FullName
		else '' End As FullName
	,case 
		when creator.userid is not null Then creator.SortName
		else '' End As SortName    
  ,ResourceLastAddedDate

From #tempWorkTable temp
	Inner join [Library.Section] coll		on temp.Id = coll.Id
	Left Join [Library.SectionType] sect	on coll.SectionTypeId = sect.Id 
    Inner Join [Library] lib				on coll.LibraryId = lib.Id
    Inner Join [Library.Type] libt			on lib.LibraryTypeId = libt.Id
    Left Join [LR.PatronOrgSummary] creator on lib.CreatedById = creator.Userid
	Left join [Gateway.OrgSummary] org		on lib.OrgId = org.id
    Left Join ( SELECT libraryId, max([ResourceCreated]) ResourceLastAddedDate  FROM [dbo].[Library.SectionResourceSummary] group by libraryId) As LibLastActivity  on lib.Id = LibLastActivity.libraryId

	left join (SELECT LibraryId, count(*) As TotalResources
		  FROM [Library.SectionResourceSummary] group by LibraryId) 
		  As lrt on lib.id = lrt.LibraryId
    
WHERE RowNumber > @first_id 
order by RowNumber		

SET ROWCOUNT 0

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.SectionSelect]  1, 1

*/
CREATE PROCEDURE [dbo].[Library.SectionSelect]
   @LibraryId int,
   @ShowingAll int
As
If @LibraryId = 0   SET @LibraryId = NULL 
Declare @IsPublic bit
if @ShowingAll = 0 set @IsPublic = 0
else if @ShowingAll = 1 set @IsPublic = 1
else set @IsPublic = NULL

SELECT     
    base.Id, 
    LibraryId, 
	lib.Title As Library,
	lib.Title As LibraryTitle,
    base.Title,
    case when resCount.Records is null then base.Title + ' (0)'
    else base.Title + ' (' + convert(varchar,resCount.Records) + ')' end As FormattedTitle,
    
    case when resCount.Records is null then 0
    else resCount.Records end As SectionResourceCount,
    SectionTypeId, lst.Title As SectionType ,
    base.Description, 
    ParentId, 
    base.IsDefaultSection,base.IsPublic,
	base.PublicAccessLevel,
	base.OrgAccessLevel,
    base.AreContentsReadOnly, 
    base.ImageUrl, Lib.ImageUrl As LibraryImageUrl,
    base.Created, base.CreatedById, 
    base.LastUpdated, base.LastUpdatedById
    
FROM [Library.Section] base
Inner join [Library] lib on base.LibraryId = lib.Id
Inner join [Library.SectionType] lst on base.SectionTypeId = lst.Id
left join (Select LibrarySectionId, count(*) As Records from [Library.SectionResourceSummary] group by LibrarySectionId) resCount on  base.Id = resCount.LibrarySectionId

WHERE  
    (base.LibraryId = @LibraryId or @LibraryId is null)
AND (base.IsPublic = @IsPublic or @IsPublic is null)

order by lib.Title, base.Title


GO
/****** Object:  StoredProcedure [dbo].[Library.SectionSelectCanContribute]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.SectionSelectCanContribute] 45,22
*/

/*
Select all collections in library where user has edit access. Includes:
- personal
- libraries where has curate access
- collections where has curate access
- org libraries with implicit access
- members of multiple orgs are not implemented as yet (thru org.member)
Modifications
14-01-20 mparsons - corrected name (from [LibrarySection.SelectCanEdit])
*/
CREATE PROCEDURE [dbo].[Library.SectionSelectCanContribute]
	@LibraryId int,
	@UserId int
As
declare @BaseMemberId int
set @BaseMemberId = 2	--contributor

SELECT distinct
	ls.[Id]
	,base.Id as LibraryId
	,base.Title as Library
	,base.Title as LibraryTitle
	,ls.[Title] As [Collection]
	,ls.[Title] As Title
	,ls.SectionTypeId, lst.Title As SectionType 
	,ls.[Description]
	,ls.IsDefaultSection
	,ls.IsPublic
	,ls.PublicAccessLevel
	,ls.OrgAccessLevel
	,ls.AreContentsReadOnly
	,ls.ImageUrl
	,ls.Created, ls.LastUpdated, ls.CreatedById, ls.LastUpdatedById
	,lsmt.Title as CollectionMemberType
	,base.[OrgId]
	,base.LibraryTypeId


  FROM [dbo].[Library] base
  inner join [Library.Section] ls on base.id = ls.LibraryId
  Inner join [Library.SectionType] lst on ls.SectionTypeId = lst.Id
  left join [Library.SectionMember] lsm on ls.id = lsm.LibrarySectionId
  left join [Codes.LibraryMemberType] lsmt on lsm.MemberTypeId = lsmt.Id
  left join [Library.Member] mbr on base.id = mbr.LibraryId
--all orgs with libraries where user is associted
  left Join (
	Select distinct OrganizationId as OrgId ,pos.UserId
	from [dbo].[LR.PatronOrgSummary] pos
	inner join Library orgLib on pos.OrganizationId = orgLib.OrgId
	) orgLibs on base.OrgId = orgLibs.OrgId
--all orgs members with libraries with implicit access. Just Admin, and staff?
 -- left Join (
	--Select distinct OrganizationId as OrgId ,pos.UserId
	--from [dbo].[LR.PatronOrgSummary] pos
	--inner join Library orgLib on pos.OrganizationId = orgLib.OrgId
	--) orgMbrLibs on base.OrgId = orgLibs.OrgId

where 
	[IsActive]= 1 
And base.id = @LibraryId
And (
	(base.[CreatedById]= @UserId and LibraryTypeId = 1)
	OR
	(mbr.UserId = @UserId AND mbr.MemberTypeId > 1)
	OR
	(lsm.UserId = @UserId AND lsm.MemberTypeId > 1)
	OR
	(orgLibs.UserId = @UserId)
)
Order by ls.Title 


GO
/****** Object:  StoredProcedure [dbo].[Library.SectionSelectCanEdit]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.SectionSelectCanEdit] 45,22
*/

/*
Select all collections in library where user has edit access. Includes:
- personal
- libraries where has curate access
- collections where has curate access
- org libraries with implicit access
- members of multiple orgs are not implemented as yet (thru org.member)
Modifications
14-01-20 mparsons - corrected name (from [LibrarySection.SelectCanEdit])
14-02-12 mparsons - made more generic by adding BaseMemberId. Calling will specify the base as editor, contributor, even reader to handle private with members
*/
CREATE PROCEDURE [dbo].[Library.SectionSelectCanEdit]
	@LibraryId int,
	@UserId int
	--,@BaseMemberId int
As
declare @BaseMemberId int
set @BaseMemberId = 3	--editor

SELECT distinct
	ls.[Id]
	,base.Id as LibraryId
	,base.Title as Library
	,base.Title as LibraryTitle
	,ls.[Title] As [Collection]
	,ls.[Title] As Title
	,ls.SectionTypeId, lst.Title As SectionType 
	,ls.[Description]
	,ls.IsDefaultSection
	,ls.IsPublic
	,ls.PublicAccessLevel
	,ls.OrgAccessLevel
	,ls.AreContentsReadOnly
	,ls.ImageUrl
	,ls.Created, ls.LastUpdated, ls.CreatedById, ls.LastUpdatedById
	,lsmt.Title as CollectionMemberType
	,base.[OrgId]
	,base.LibraryTypeId


  FROM [dbo].[Library] base
  inner join [Library.Section] ls on base.id = ls.LibraryId
  Inner join [Library.SectionType] lst on ls.SectionTypeId = lst.Id
  left join [Library.SectionMember] lsm on ls.id = lsm.LibrarySectionId
  left join [Codes.LibraryMemberType] lsmt on lsm.MemberTypeId = lsmt.Id
  left join [Library.Member] mbr on base.id = mbr.LibraryId
--all orgs with libraries where user is associted
  left Join (
	Select distinct OrganizationId as OrgId ,pos.UserId
	from [dbo].[LR.PatronOrgSummary] pos
	inner join Library orgLib on pos.OrganizationId = orgLib.OrgId
	
	) orgLibs on base.OrgId = orgLibs.OrgId
where 
	[IsActive]= 1 ANd base.id = @LibraryId
And (
	(base.[CreatedById]= @UserId and LibraryTypeId = 1)
	OR
	(mbr.UserId = @UserId AND mbr.MemberTypeId >= @BaseMemberId)
	OR
	(lsm.UserId = @UserId AND lsm.MemberTypeId >= @BaseMemberId)
	OR
	(orgLibs.UserId = @UserId)
)
Order by ls.Title 


GO
/****** Object:  StoredProcedure [dbo].[Library.SectionSubscriptionDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.SectionSubscriptionDelete]
        @Id int
As
DELETE FROM [Library.SectionSubscription]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionSubscriptionGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.SectionSubscriptionGet] 2, null, 0

[Library.SectionSubscriptionGet] 0, 132, 0

[Library.SectionSubscriptionGet] 0, null, 22

*/
CREATE PROCEDURE [dbo].[Library.SectionSubscriptionGet]
	@Id int,
	@SectionId int, 
	@UserId int

As
If @Id = 0   SET @Id = NULL 
If @SectionId = 0   SET @SectionId = NULL 
If @UserId = 0   SET @UserId = NULL 


If @Id is null and ( @SectionId is null Or @UserId is null ) begin
	print '[Library.SectionSubscriptionGet] Error: Incomplete parameters were provided'
	RAISERROR('[Library.SectionSubscriptionGet] Error: incomplete parameters were provided. Require: @Id OR (@SectionId and @UserId) ', 18, 1)    
	RETURN -1 
  end

SELECT     
	Id, 
    SectionId, 
	--ParentId is used for generic handling of a subscription 
	SectionId As ParentId,
    UserId, 
    SubscriptionTypeId, 
    PrivilegeId, 
    Created, 
    LastUpdated
FROM [Library.SectionSubscription]
WHERE (Id = @Id or @Id is null)
And (SectionId = @SectionId or @SectionId is null)
And (UserId = @UserId or @UserId is null)


GO
/****** Object:  StoredProcedure [dbo].[Library.SectionSubscriptionInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.SectionSubscriptionInsert]
            @SectionId int, 
            @UserId int, 
            @SubscriptionTypeId int
As
If @SectionId = 0   SET @SectionId = NULL 
If @UserId = 0   SET @UserId = NULL 
If @SubscriptionTypeId = 0   SET @SubscriptionTypeId = NULL 


INSERT INTO [Library.SectionSubscription] (

    SectionId, 
    UserId, 
    SubscriptionTypeId
)
Values (

    @SectionId, 
    @UserId, 
    @SubscriptionTypeId
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionSubscriptionUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- Update Procedure for [Library.SectionSubscription] ---
CREATE PROCEDURE [dbo].[Library.SectionSubscriptionUpdate]
		@Id int,
        @SubscriptionTypeId int

As

UPDATE [Library.SectionSubscription] 
SET 
    SubscriptionTypeId = @SubscriptionTypeId, 
    LastUpdated = getdate()
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionTypeSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
[Library.SectionTypeSelect]

*/
CREATE PROCEDURE [dbo].[Library.SectionTypeSelect]

As

SELECT [Id]
      ,[Title]
      ,[AreContentsReadOnly]
      ,[Decription]
      ,[SectionCode]
      ,[Created]
  FROM [dbo].[Library.SectionType]
  Order by 2

GO
/****** Object:  StoredProcedure [dbo].[Library.SectionUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* 
==================================================================
--- Update Procedure for [Library.Section] ---
Modifications
13-05-28 mparsons - added @LibraryId to allow for easy reset of IsDefault 
14-02-05 mparsons - added Access levels. planning to remove IsPublic
==================================================================
*/
CREATE PROCEDURE [dbo].[Library.SectionUpdate]
        @Id int, 
        @LibraryId int, 
        @Title varchar(100),
        @Description varchar(500), 
        @IsDefaultSection bit, 
        @PublicAccessLevel int, 
		@OrgAccessLevel int, 
        @AreContentsReadOnly bit, 
        @LastUpdatedById int,
		@ImageUrl varchar(200)

As
If @Title = ''   SET @Title = 'Missing - TBD' 
If @Description = ''   SET @Description = NULL 
If @ImageUrl = ''		SET @ImageUrl = NULL 
If @LastUpdatedById = 0   SET @LastUpdatedById = NULL 


declare @IsPublic bit
-- temp check during transition
if  @PublicAccessLevel = 0 begin
	set @IsPublic= 0
	end
	else begin
	set @IsPublic= 1
	if @OrgAccessLevel = 0
		set @OrgAccessLevel= 2
	end

if @IsDefaultSection = 1 begin
  --unset any existing
  update [Library.Section] set IsDefaultSection = 0 
  WHERE LibraryId = @LibraryId 
  end

UPDATE [Library.Section] 
SET 
    Title = @Title, 
    Description = @Description, 
    IsDefaultSection = @IsDefaultSection,  
	PublicAccessLevel = @PublicAccessLevel, 
	OrgAccessLevel = @OrgAccessLevel, 
    IsPublic = @IsPublic,  
    AreContentsReadOnly = @AreContentsReadOnly,  
	ImageUrl= @ImageUrl,
    LastUpdated = getdate(), 
    LastUpdatedById = @LastUpdatedById
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SelectCanContribute]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

[Library.SelectCanContribute] 2, 0
go
[Library.SelectCanContribute] 2, 43



[Library.SelectCanContribute] 92, 43

*/

/*
Select all libraries/collections where user has contribute access. Includes:
- personal
- libraries where has curate access
- collections where has curate access
- org libraries with implicit access
- members of multiple orgs are not implemented as yet (thru org.member)
Modifications

*/
CREATE PROCEDURE [dbo].[Library.SelectCanContribute]
  @UserId		int
  ,@LibraryId	int
  --,@BaseMemberId int
As
declare @BaseMemberId int
set @BaseMemberId = 2	--contributor

if @LibraryId = 0	set @LibraryId = NULL

SELECT distinct
	base.[Id]
	,base.[Title]
	,base.Description
	,base.LibraryTypeId, lt.Title as LibraryType
	,IsDiscoverable
	,isnull(base.OrgId,0) As OrgId
    ,isnull(orgLibs.Organization, '') As Organization
	,base.IsPublic, base.IsActive
	,base.PublicAccessLevel
	,base.OrgAccessLevel
	,base.ImageUrl
	,base.Created, base.CreatedById
    ,base.LastUpdated, base.LastUpdatedById,
    base.RowId

  FROM [dbo].[Library] base
  inner join [Library.Type] lt on base.LibraryTypeId = lt.Id
  inner join [Library.Section] ls on base.id = ls.LibraryId
  left join [Library.SectionMember] lsm on ls.id = lsm.LibrarySectionId
  left join [Library.Member] mbr on base.id = mbr.LibraryId
  --all orgs with libraries where user is associated
  left Join (
	Select distinct OrganizationId as OrgId ,pos.UserId, pos.Organization
	from [dbo].[LR.PatronOrgSummary] pos
	inner join Library orgLib on pos.OrganizationId = orgLib.OrgId
	) orgLibs on base.OrgId = orgLibs.OrgId
where 
	[IsActive]= 1
And (base.Id = @LibraryId OR @LibraryId is null)
And (
	(base.[CreatedById]= @UserId and LibraryTypeId = 1)
	OR
	(mbr.UserId = @UserId AND mbr.MemberTypeId >= @BaseMemberId)
	OR
	(lsm.UserId = @UserId AND lsm.MemberTypeId >= @BaseMemberId)
	OR
	(orgLibs.UserId = @UserId)
)
Order by base.Title 


GO
/****** Object:  StoredProcedure [dbo].[Library.SelectCanEdit]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.SelectCanEdit] 2,0
*/

/*
Select all libraries/collections where user has edit access. Includes:
- personal
- libraries where has curate access
- collections where has curate access
- org libraries with implicit access
- members of multiple orgs are not implemented as yet (thru org.member)
Modifications
14-02-10 mparsons - add optional lib parm to reduce the recordset and allow easy check of access to a specific library
*/
CREATE PROCEDURE [dbo].[Library.SelectCanEdit]
  @UserId int
  ,@LibraryId	int
  --,@BaseMemberId int
As
if @LibraryId = 0	set @LibraryId = NULL

declare @BaseMemberId int
set @BaseMemberId = 3	--editor

SELECT distinct
	base.[Id]
	,base.[Title]
	,base.[Title] + ' ( ' + lt.Title + ' )' As FormattedTitle
	,base.Description
	,base.LibraryTypeId, lt.Title as LibraryType
	,IsDiscoverable
	,isnull(base.OrgId,0) As OrgId
    ,isnull(orgLibs.Organization, '') As Organization
	,base.IsPublic, base.IsActive
	,base.PublicAccessLevel
	,base.OrgAccessLevel
	,base.ImageUrl
	,base.Created, base.CreatedById
    ,base.LastUpdated, base.LastUpdatedById,
    base.RowId

  FROM [dbo].[Library] base
  inner join [Library.Type] lt on base.LibraryTypeId = lt.Id
  inner join [Library.Section] ls on base.id = ls.LibraryId
  left join [Library.SectionMember] lsm on ls.id = lsm.LibrarySectionId
  left join [Library.Member] mbr on base.id = mbr.LibraryId
  --all orgs with libraries where user is associted
  left Join (
	Select distinct OrganizationId as OrgId ,pos.UserId, pos.Organization
	from [dbo].[LR.PatronOrgSummary] pos
	inner join Library orgLib on pos.OrganizationId = orgLib.OrgId
	
	) orgLibs on base.OrgId = orgLibs.OrgId
where 
	[IsActive]= 1
And (base.Id = @LibraryId OR @LibraryId is null)
And (
	(base.[CreatedById]= @UserId and LibraryTypeId = 1)
	OR
	(mbr.UserId = @UserId AND mbr.MemberTypeId >= @BaseMemberId)
	OR
	(lsm.UserId = @UserId AND lsm.MemberTypeId >= @BaseMemberId)
	OR
	(orgLibs.UserId = @UserId)
)
Order by base.Title 


GO
/****** Object:  StoredProcedure [dbo].[Library.SelectWhichContainResource]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.SelectWhichContainResource] 21632
*/
CREATE PROCEDURE [dbo].[Library.SelectWhichContainResource]
  @ResourceIntId int
As

SELECT 
    base.Id, 
    base.Title, 
	base.[Description],
	res.ResourceIntId,
    base.LibraryTypeId, 
    lt.Title as LibraryType,
    base.IsDiscoverable, 
    base.IsPublic
		,base.PublicAccessLevel
	,base.OrgAccessLevel,
    base.ImageUrl,
	base.IsActive,
	    base.Created, base.CreatedById, 
    base.LastUpdated, base.LastUpdatedById
    
FROM [Library] base
inner join [Library.Type] lt on base.LibraryTypeId = lt.Id
inner join [Library.SectionResourceSummary] res on base.id = res.libraryId
where     (res.ResourceIntId = @ResourceIntId)

Order by ResourceIntId,lt.Title, base.Title


GO
/****** Object:  StoredProcedure [dbo].[Library.SubscriptionDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.SubscriptionDelete]
        @Id int,
        @LibraryId int, 
        @UserId int
As

If @Id = 0          SET @Id = NULL 
If @LibraryId = 0   SET @LibraryId = NULL 
If @UserId = 0      SET @UserId = NULL 

If @Id = 0 OR ( @LibraryId = 0 And @UserId = 0 ) begin
  RAISERROR('[Library.SubscriptionDelete] - invalid request. Require @Id, OR @LibraryId AND @UserId', 18, 1)  
  return -1
  end

DELETE FROM [Library.Subscription]
WHERE 
    (Id = @Id or @Id is null)
And (LibraryId = @LibraryId or @LibraryId is null)    
And (UserId = @UserId or @UserId is null)


GO
/****** Object:  StoredProcedure [dbo].[Library.SubscriptionGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*

[Library.SubscriptionGet] 0,25,29
[Library.SubscriptionGet] 0,0,29
[Library.SubscriptionGet] 0,25,0

[Library.SubscriptionGet] 0,0,0
*/
CREATE PROCEDURE [dbo].[Library.SubscriptionGet]
        @Id int,
        @LibraryId int, 
        @UserId int
As
If @Id = 0          SET @Id = NULL 
If @LibraryId = 0   SET @LibraryId = NULL 
If @UserId = 0      SET @UserId = NULL 

If @Id is null and ( @LibraryId is null Or @UserId is null ) begin
  RAISERROR('[Library.SubscriptionGet] - invalid request. Require @Id, OR @LibraryId AND @UserId', 18, 1)  
  return -1
  end

  
SELECT     
    base.Id, 
    LibraryId, lib.Title as Library,
	--ParentId is used for generic handling of a subscription 
	LibraryId As ParentId,
    UserId, 
    SubscriptionTypeId, cst.Title as SubscriptionType,
    --PrivilegeId As MemberTypeId, 
    base.Created
FROM [Library.Subscription] base
Inner Join dbo.Library lib on base.LibraryId = lib.Id
Inner Join dbo.[Codes.SubscriptionType] cst on base.SubscriptionTypeId = cst.Id
WHERE 
    (base.Id = @Id or @Id is null)
And (LibraryId = @LibraryId or @LibraryId is null)    
And (UserId = @UserId or @UserId is null)


GO
/****** Object:  StoredProcedure [dbo].[Library.SubscriptionInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Library.SubscriptionInsert]
            @LibraryId int, 
            @UserId int, 
            @SubscriptionTypeId int
			--, @MemberTypeId int
As

If @SubscriptionTypeId = 0   SET @SubscriptionTypeId = NULL 
--If @MemberTypeId = 0   SET @MemberTypeId = NULL 

INSERT INTO [Library.Subscription] (

    LibraryId, 
    UserId, 
    SubscriptionTypeId
  --,  PrivilegeId
)
Values (

    @LibraryId, 
    @UserId, 
    @SubscriptionTypeId
   --, @MemberTypeId
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[Library.SubscriptionUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--- Update Procedure for [Library.Subscription] ---
CREATE PROCEDURE [dbo].[Library.SubscriptionUpdate]
        @Id int,
        @SubscriptionTypeId int
        
As

If @SubscriptionTypeId = 0    SET @SubscriptionTypeId = NULL 

UPDATE [Library.Subscription] 
SET 
    SubscriptionTypeId = @SubscriptionTypeId, 
    LastUpdated = getdate()
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[Library.TypeSelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
[Library.TypeSelect]

*/
CREATE PROCEDURE [dbo].[Library.TypeSelect]

As

SELECT [Id]
      ,[Title]
      ,[Description]
      ,[Created]
  FROM [dbo].[Library.Type]
  Order by 2

GO
/****** Object:  StoredProcedure [dbo].[Library.UniqueLibrariesForResource]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.UniqueLibrariesForResource] 21632

[Library.UniqueLibrariesForResource] 62959
go
[Library.UniqueLibrariesForResource] 87451

*/
CREATE PROCEDURE [dbo].[Library.UniqueLibrariesForResource]
  @ResourceIntId int
As

SELECT distinct 
    res.ResourceIntId, lib.Id as LibraryId, ls.Id as CollectionId

FROM [Library.Resource] res
inner join [Library.Section] ls on res.LibrarySectionId = ls.Id 
Inner join Library lib on ls.LibraryId = lib.Id	
where     (res.ResourceIntId = @ResourceIntId)

Order by res.ResourceIntId, lib.Id, ls.Id


GO
/****** Object:  StoredProcedure [dbo].[Library.UniqueSectionsForResource]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[Library.UniqueSectionsForResource] 21632
*/
CREATE PROCEDURE [dbo].[Library.UniqueSectionsForResource]
  @ResourceIntId int
As

SELECT distinct 
    res.ResourceIntId, ls.Id as CollectionId

FROM [Library.Resource] res
inner join [Library.Section] ls on res.LibrarySectionId = ls.Id 

where     (res.ResourceIntId = @ResourceIntId)

Order by res.ResourceIntId, ls.Id


GO
/****** Object:  StoredProcedure [dbo].[LibraryDelete]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[LibraryDelete]
        @Id int
As
DELETE FROM [Library]
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[LibraryGet]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

[LibraryGet] 1, ''

[LibraryGet] 0, '0ACD2A29-7027-4D5E-95AC-B32632BDD6CF'

[LibraryGet] 0, ''

*/
CREATE PROCEDURE [dbo].[LibraryGet]
    @Id int,
    @RowId varchar(40)
As
if @Id = 0      set @Id= NULL
if @RowId = ''  set @RowId= NULL

If @Id is null and @RowId is null begin
	print '[Library.Get] Error: Incomplete parameters were provided'
	RAISERROR('[Library.Get] Error: incomplete parameters were provided. Require: @Id OR @RowId ) ', 18, 1)    
	RETURN -1 
  end

SELECT     
    base.Id, 
    base.Title, 
    base.Description, 
    LibraryTypeId, lt.Title as LibraryType,
    IsDiscoverable, 
    isnull(base.OrgId,0) As OrgId,
    isnull(org.Name, '') As Organization,
    base.IsPublic, base.IsActive,
	base.PublicAccessLevel,
	base.OrgAccessLevel,
    base.ImageUrl, 
    base.Created, base.CreatedById, 
    base.LastUpdated, base.LastUpdatedById,
    base.RowId
    
FROM [Library] base
inner join [Library.Type] lt on base.LibraryTypeId = lt.Id
left join [dbo].[Gateway.OrgSummary] org on base.OrgId = org.id
WHERE 
    (base.Id = @Id OR @Id is null)
AND (base.RowId = @RowId OR @RowId is null)    

GO
/****** Object:  StoredProcedure [dbo].[LibraryInsert]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Insert a Library
Modifications
14-01-10 mparsons - added rowId - done explicityly now to facilitate use for the imageUrl
14-02-05 mparsons - added Access levels. planning to remove IsPublic
*/
CREATE PROCEDURE [dbo].[LibraryInsert]
            @Title varchar(200), 
            @Description varchar(500), 
            @LibraryTypeId int, 
            @IsDiscoverable bit, 
			@PublicAccessLevel int, 
            @OrgAccessLevel int, 
            @CreatedById int,
            @ImageUrl varchar(100),
			@OrgId int,
			@RowId varchar(50)
			--,@IsPublic bit
As
If @CreatedById = 0   SET @CreatedById = NULL 
If @OrgId = 0   SET @OrgId = NULL 
If @ImageUrl = ''   SET @ImageUrl = NULL 
If @RowId = '' OR @RowId = '00000000-0000-0000-0000-000000000000'  SET @RowId = newId() 

--declare @IsPublic bit
---- temp check during transition
--if  @PublicAccessLevel < 2 begin
--	set @IsPublic= 0
--	end
--	else begin
--	set @IsPublic= 1
--	if @OrgAccessLevel = 0
--		set @OrgAccessLevel= 2
--	end

INSERT INTO [Library] (

    Title, 
    Description, 
    LibraryTypeId, 
    IsDiscoverable, 
	PublicAccessLevel,
	OrgAccessLevel,
	OrgId,
    ImageUrl,
    CreatedById, 
    LastUpdatedById,
	RowId
)
Values (

    @Title, 
    @Description, 
    @LibraryTypeId, 
    @IsDiscoverable, 
	@PublicAccessLevel,
	@OrgAccessLevel,
	@OrgId, 
    @ImageUrl,
    @CreatedById,
    @CreatedById,
	@RowId
)
 
select SCOPE_IDENTITY() as Id

GO
/****** Object:  StoredProcedure [dbo].[LibraryMember_Search]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

-- ===========================================================

DECLARE @RC int,@Filter varchar(500), @StartPageIndex int, @PageSize int, @totalRows int,@SortOrder varchar(100)
set @SortOrder = '' 
set @Filter = ' LibraryId = 1 '
                 
set @StartPageIndex = 1
set @PageSize = 15

exec [LibraryMember_Search] @Filter, @SortOrder, @StartPageIndex  ,@PageSize  ,@totalRows OUTPUT

select 'total rows = ' + convert(varchar,@totalRows)


*/

/* =================================================
= LibraryMember_Search
=		@StartPageIndex - starting page number. If interface is at 20 when next page is requested, this would be set to 21?
=		@PageSize - number of records on a page
=		@totalRows OUTPUT - total available rows. Used by interface to build a custom pager
= ------------------------------------------------------
= Modifications
= 14-02-04 mparsons - Created 
-- ================================================= */
Create PROCEDURE [dbo].[LibraryMember_Search]
		@Filter				    varchar(500)
		,@SortOrder	      varchar(500)
		,@StartPageIndex  int
		,@PageSize		    int
		,@TotalRows			  int OUTPUT
AS 
DECLARE 
@first_id			int
,@startRow		int
,@debugLevel	int
,@SQL             varchar(5000)
,@OrderBy         varchar(100)

	SET NOCOUNT ON;

-- ==========================================================
Set @debugLevel = 4
if len(@SortOrder) > 0
	set @OrderBy = ' Order by ' + @SortOrder
else 
  set @OrderBy = ' Order by Library, SortName '
--===================================================
-- Calculate the range
--===================================================
SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

 
-- =================================
CREATE TABLE #tempWorkTable(
	RowNumber int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Id int NOT NULL,
	LibraryId int,
	UserId int
)
-- =================================

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter
     end
 
set @SQL = 'SELECT [Id] ,[LibraryId],[UserId]   FROM [dbo].[Library.MemberSummary] 	  '  
	  + @Filter

if charindex( 'order by', lower(@Filter) ) = 0 
	set @SQL = 	@SQL + @OrderBy
if @debugLevel > 3 begin
  print '@SQL len: '  +  convert(varchar,len(@SQL))
	print @SQL
	end
	
INSERT INTO #tempWorkTable (Id, LibraryId, UserId)
exec (@sql)
   SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Show the StartPageIndex
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

SELECT     Distinct
		RowNumber,
		lib.[Id]
      ,lib.[LibraryId]
      ,[Library]
      ,lib.[UserId]
      ,[FullName]
      ,[SortName]
	  ,[FullName] AS MemberName
      ,[SortName] As MemberSortName
      ,[Email]
      ,[MemberTypeId]
      ,[MemberType]
      ,CONVERT(varchar(10), lib.Created, 120) As Created
      ,[CreatedById]
	  ,CONVERT(varchar(10), lib.[LastUpdated], 120) As [LastUpdated]
      ,[LastUpdatedById]
  
From #tempWorkTable temp
    Inner Join [dbo].[Library.MemberSummary] lib on temp.Id = lib.Id

WHERE RowNumber > @first_id 
order by RowNumber		

SET ROWCOUNT 0

GO
/****** Object:  StoredProcedure [dbo].[LibrarySearch]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

-- ===========================================================

DECLARE @RC int,@Filter varchar(500), @StartPageIndex int, @PageSize int, @totalRows int,@SortOrder varchar(100)
set @SortOrder = '' 
set @Filter = ' ResourceLastAddedDate > ''2013-06-01'' '

set @Filter = ' lib.Id in (Select LibraryId from [Library.Member] where userid = 2 ) '          
set @StartPageIndex = 1
set @PageSize = 15

exec [LibrarySearch] @Filter, @SortOrder, @StartPageIndex  ,@PageSize  ,@totalRows OUTPUT

select 'total rows = ' + convert(varchar,@totalRows)


*/

/* =================================================
= Library search
=		@StartPageIndex - starting page number. If interface is at 20 when next page is requested, this would be set to 21?
=		@PageSize - number of records on a page
=		@totalRows OUTPUT - total available rows. Used by interface to build a custom pager
= ------------------------------------------------------
= Modifications
= 13-05-12 mparsons - Created 
= 13-06-12 mparsons - added search by last resource activity
= 14-01-20 mparsons - added addition return fields so Library.Fill has all required columns
-- ================================================= */
Create PROCEDURE [dbo].[LibrarySearch]
    @Filter				    varchar(500)
    ,@SortOrder	      varchar(500)
		,@StartPageIndex  int
		,@PageSize		    int
		,@TotalRows			  int OUTPUT
AS 
DECLARE 
	@first_id			int
	,@startRow		int
	,@debugLevel	int
	,@SQL             varchar(5000)
  ,@OrderBy         varchar(100)

	SET NOCOUNT ON;

-- ==========================================================
Set @debugLevel = 4
if len(@SortOrder) > 0
	set @OrderBy = ' Order by ' + @SortOrder
else 
  set @OrderBy = ' Order by lib.Title '
--===================================================
-- Calculate the range
--===================================================
SET @StartPageIndex =  (@StartPageIndex - 1)  * @PageSize
IF @StartPageIndex < 1        SET @StartPageIndex = 1

 
-- =================================
CREATE TABLE #tempWorkTable(
	RowNumber int PRIMARY KEY IDENTITY(1,1) NOT NULL,
	Id int NOT NULL,
	Title varchar(100),
	TotalResources int
)
-- =================================

  if len(@Filter) > 0 begin
     if charindex( 'where', @Filter ) = 0 OR charindex( 'where',  @Filter ) > 10
        set @Filter =     ' where ' + @Filter + '  AND (lib.IsActive = 1) '
     end
	 else begin 
	 set @Filter =     ' where  (lib.IsActive = 1) '
	 end
 
set @SQL = 'SELECT lib.Id, lib.Title, lrt.TotalResources FROM [Library]  lib
	  Left Join [LR.PatronOrgSummary] owner on lib.CreatedById = owner.Userid
	  Left join [Gateway.OrgSummary] org on lib.OrgId = org.id
	  Left Join [Library.Type] libt on lib.LibraryTypeId = libt.Id 
	  Left Join ( SELECT libraryId, max([ResourceCreated]) ResourceLastAddedDate  FROM [dbo].[Library.SectionResourceSummary] group by libraryId) 
				As LibLastActivity  on lib.Id = LibLastActivity.libraryId
	  left join (SELECT LibraryId, count(*) As TotalResources
		  FROM [Library.SectionResourceSummary] group by LibraryId) 
		  As lrt on lib.id = lrt.LibraryId
	  '  
	  + @Filter

if charindex( 'order by', lower(@Filter) ) = 0 
	set @SQL = 	@SQL + @OrderBy
if @debugLevel > 3 begin
  print '@SQL len: '  +  convert(varchar,len(@SQL))
	print @SQL
	end
	
INSERT INTO #tempWorkTable (Id, Title, TotalResources)
exec (@sql)
   SELECT @TotalRows = @@ROWCOUNT
-- =================================

print 'added to temp table: ' + convert(varchar,@TotalRows)
if @debugLevel > 7 begin
  select * from #tempWorkTable
  end

-- Show the StartPageIndex
--===================================================
PRINT '@StartPageIndex = ' + convert(varchar,@StartPageIndex)

SET ROWCOUNT @StartPageIndex
--SELECT @first_id = RowNumber FROM #tempWorkTable   ORDER BY RowNumber
SELECT @first_id = @StartPageIndex
PRINT '@first_id = ' + convert(varchar,@first_id)

if @first_id = 1 set @first_id = 0
--set max to return
SET ROWCOUNT @PageSize

SELECT     Distinct
		RowNumber,
    lib.Id, lib.Id As LibraryId, 
    lib.Title, 
    lib.Description, 
    LibraryTypeId, libt.Title as LibraryType,
    IsDiscoverable, 
    IsPublic, lib.IsActive,
	lib.PublicAccessLevel,
	lib.OrgAccessLevel,
    case when lib.PublicAccessLevel > 1 then 'Public'
      else 'Private' end as ViewType,
    case when isnull(lib.ImageUrl,'') = '' then 'defaultUrl' else lib.ImageUrl end as ImageUrl, 
    
    isnull(lst.TotalSections,0) As TotalSections,
    isnull(lrt.TotalResources,0) As TotalResources,
    lib.Created, lib.CreatedById, 
    lib.LastUpdated, lib.LastUpdatedById
    ,lib.OrgId
    ,case when isnull(lib.OrgId,0) > 0 then org.Name 
      when isnull(creator.OrganizationId,0) > 0 then creator.Organization 
      else 'Personal' end as Organization
	,case 
		when creator.userid is not null Then creator.FullName
		else '' End As FullName
	,case 
		when creator.userid is not null Then creator.SortName
		else '' End As SortName    
  ,ResourceLastAddedDate
,lcoll.[Titles] As Collections
From #tempWorkTable temp
    Inner Join [Library] lib on temp.Id = lib.Id
    Inner Join [Library.Type] libt on lib.LibraryTypeId = libt.Id
    Left Join [LR.PatronOrgSummary] creator on lib.CreatedById = creator.Userid
	Left join [Gateway.OrgSummary] org on lib.OrgId = org.id
    Left Join ( SELECT libraryId, max([ResourceCreated]) ResourceLastAddedDate  FROM [dbo].[Library.SectionResourceSummary] group by libraryId) As LibLastActivity  on lib.Id = LibLastActivity.libraryId
	left join (SELECT LibraryId, count(*) As TotalSections
		  FROM [Library.Section] group by LibraryId) 
		  As lst on lib.id = lst.LibraryId
	left join (SELECT LibraryId, count(*) As TotalResources
		  FROM [Library.SectionResourceSummary] group by LibraryId) 
		  As lrt on lib.id = lrt.LibraryId
    left join [LibraryCollection.ResourceCountCSV] lcoll on lib.id = lcoll.LibraryId
WHERE RowNumber > @first_id 
order by RowNumber		

SET ROWCOUNT 0

GO
/****** Object:  StoredProcedure [dbo].[LibrarySearch_SelectUsedValuesForFilter]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
SELECT [Id] FROM dbo.[Codes.GroupType] codes 
WHERE IsActive = 1 AND codes.Id in (
	select distinct res.GroupTypeId from [dbo].[Resource.GroupType]  lres 
	INNER JOIN [dbo].[Library.Section] lsec ON lres.LibrarySectionId = lsec.Id 
	inner join dbo.[Resource.GroupType] res on lres.ResourceIntId = res.ResourceIntId 
	where 
		lsec.LibraryId	= 1OR	lsec.Id			= 0	)


[LibrarySearch_SelectUsedValuesForFilter] 'dbo.[Codes.GroupType]'
			, '[Resource.GroupType] '
			, 'GroupTypeId'
			,1,0


[LibrarySearch_SelectUsedValuesForFilter] 'dbo.[Codes.ResourceType]'
			, '[Resource.ResourceType] '
			, 'ResourceTypeId'
			,1,0
*/
Create PROCEDURE [dbo].[LibrarySearch_SelectUsedValuesForFilter]
		@CodeTable			varchar(50)
		,@ResourceChildTable	varchar(50)
		,@FKey				varchar(50)
		,@LibraryId			int
		,@LibrarySectionId  int

As
declare @Sql varchar(500)
SET NOCOUNT ON;
--caller must set square brackets if needed
set @sql = 'SELECT [Id], Title FROM ' + @CodeTable + ' codes 
WHERE IsActive = 1 AND codes.Id in (
	select distinct res.' + @FKey + ' 
	from [dbo].' + @ResourceChildTable + ' res 
	inner join dbo.[Library.Resource] lres on res.ResourceIntId = lres.ResourceIntId 
	INNER JOIN [dbo].[Library.Section] lsec ON lres.LibrarySectionId = lsec.Id 
	where 
		lsec.LibraryId	= ' + convert(varchar,@LibraryId) + ' 
	OR	lsec.Id			= ' + convert(varchar,@LibrarySectionId) + '	)
	Order by 2'
	
	print @sql
	exec(@sql)

GO
/****** Object:  StoredProcedure [dbo].[LibrarySection.SelectCanEdit]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
[LibrarySection.SelectCanEdit] 45,22
*/

CREATE PROCEDURE [dbo].[LibrarySection.SelectCanEdit]
	@LibraryId int,
	@UserId int
As


SELECT distinct
	ls.[Id]
	,base.Id as LibraryId
	,base.Title as Library
	,base.Title as LibraryTitle
	,ls.[Title] As [Collection]
	,ls.[Title] As Title
	,ls.[Description]
	,ls.IsDefaultSection
	,ls.IsPublic
	,ls.AreContentsReadOnly
	,ls.ImageUrl
	,ls.Created, ls.LastUpdated, ls.CreatedById, ls.LastUpdatedById
	,lsmt.Title as CollectionMemberType
	,base.[OrgId]
	,base.LibraryTypeId


  FROM [dbo].[Library] base
  inner join [Library.Section] ls on base.id = ls.LibraryId
  left join [Library.SectionMember] lsm on ls.id = lsm.LibrarySectionId
  left join [Codes.LibraryMemberType] lsmt on lsm.MemberTypeId = lsmt.Id
  left join [Library.Member] mbr on base.id = mbr.LibraryId
--all orgs with libraries where user is associted
  left Join (
	Select distinct OrganizationId as OrgId ,pos.UserId
	from [dbo].[LR.PatronOrgSummary] pos
	inner join Library orgLib on pos.OrganizationId = orgLib.OrgId
	
	) orgLibs on base.OrgId = orgLibs.OrgId
where 
	[IsActive]= 1 ANd base.id = @LibraryId
And (
	(base.[CreatedById]= @UserId and LibraryTypeId = 1)
	OR
	(mbr.UserId = @UserId AND mbr.MemberTypeId > 1)
	OR
	(lsm.UserId = @UserId AND lsm.MemberTypeId > 1)
	OR
	(orgLibs.UserId = @UserId)
)
Order by ls.Title 


GO
/****** Object:  StoredProcedure [dbo].[LibrarySelect]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

*/
CREATE PROCEDURE [dbo].[LibrarySelect]
  @OwnerId int,
  @LibraryTypeId int
As

If @OwnerId = 0   SET @OwnerId = NULL 
If @LibraryTypeId = 0   SET @LibraryTypeId = NULL 

SELECT 
    base.Id, 
    base.Title, 
    base.Description, 
    LibraryTypeId, 
    lt.Title as LibraryType,
    IsDiscoverable, 
    IsPublic, 
    base.ImageUrl, 
    base.Created, base.CreatedById, 
    base.LastUpdated, base.LastUpdatedById
    
FROM [Library] base
inner join [Library.Type] lt on base.LibraryTypeId = lt.Id
where 
    (CreatedById = @OwnerId OR @OwnerId is null)
AND (LibraryTypeId = @LibraryTypeId OR @LibraryTypeId is null)

Order by lt.Title, base.Title


GO
/****** Object:  StoredProcedure [dbo].[LibraryUpdate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Update a Library
Modifications
14-02-05 mparsons - added Access levels. planning to remove IsPublic
*/
CREATE PROCEDURE [dbo].[LibraryUpdate]
        @Id int,
        @Title varchar(200), 
        @Description varchar(500), 
        @IsDiscoverable bit, 
        @PublicAccessLevel int, 
        @OrgAccessLevel int, 
        @LastUpdatedById int,
        @ImageUrl varchar(100)

As
If @Description = ''   SET @Description = NULL  
If @LastUpdatedById = 0   SET @LastUpdatedById = NULL 
If @ImageUrl = ''   SET @ImageUrl = NULL 


declare @IsPublic bit
-- temp check during transition
if  @PublicAccessLevel = 0 begin
	set @IsPublic= 0
	end
	else begin
	set @IsPublic= 1
	if @OrgAccessLevel = 0
		set @OrgAccessLevel= 2
	end

UPDATE [Library] 
SET 
    Title = @Title, 
    Description = @Description, 
    IsDiscoverable = @IsDiscoverable, 
	PublicAccessLevel = @PublicAccessLevel, 
	OrgAccessLevel = @OrgAccessLevel, 
    IsPublic = @IsPublic, 
    ImageUrl = @ImageUrl,
    LastUpdated = getdate(), 
    LastUpdatedById = @LastUpdatedById
WHERE Id = @Id

GO
/****** Object:  StoredProcedure [dbo].[SendCollectionFollowerEmail]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Description:	Sends email notifications of resources recently added to followed collections
--
-- Debug levels:
-- 10 = Send email to admin address instead of actual recipient.
-- 11 = Same as 10 plus skip the update of the System.Process record
-- 12 = Send *NO* e-mail and skip update of the System.Process record
-- =============================================
CREATE PROCEDURE [dbo].[SendCollectionFollowerEmail]
	@code varchar(50),
	@subscriptionTypeId int,
	@debug int = 1,
	@adminAddress varchar(50) = 'jgrimmer@siuccwd.com'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Get last run date
	DECLARE @sysprocId int, @sysprocLastRun datetime
	SELECT @sysprocId = Id, @sysprocLastRun = LastRunDate
	FROM Isle_IOER.dbo.[System.Process]
	WHERE Code = @code
	DECLARE @LastRunDate datetime
	SET @LastRunDate = GETDATE()
	
	-- Get email notice
	DECLARE @Subject varchar(100), @HtmlBodyTemplate nvarchar(max)
	SELECT @Subject = [Subject], @HtmlBodyTemplate = HtmlBody
	FROM [IsleContent].dbo.EmailNotice
	WHERE NoticeCode = 'CollectionsNotification'
	
	DECLARE @HtmlBody nvarchar(max), @Data nvarchar(max), @LibraryTemplate nvarchar(100), @CollectionTemplate nvarchar(100), @ResourceTemplate nvarchar(500)
	SET @LibraryTemplate = '<h1>Library: @LibraryName</h1>'
	SET @CollectionTemplate = '<h2>Collection: @CollectionName</h2>'
	SET @ResourceTemplate = '<a href="http://ioer.ilsharedlearning.org/ResourceDetail.aspx?vid=@VersionId">@ResourceTitle</a><br />@Description<br /><br />'
	
	DECLARE @UserId int, @FullName varchar(101), @Email varchar(100), @LibraryId int, @LibraryTitle varchar(200),
		@CollectionId int, @CollectionTitle varchar(100),
		@ResourceVersionId int, @ResourceTitle varchar(300), @ResourceDescription varchar(max),
		@HoldUserId int, @HoldEmail varchar(100), @HoldLibraryId int, @HoldCollectionId int,
		@FirstTimeThru bit, @DoLibraryBreak bit, @DoCollectionBreak bit, @EmailsSent int, @BatchSize int
	SET @FirstTimeThru = 'True'
	SET @DoLibraryBreak = 'False'
	SET @DoCollectionBreak = 'False'
	SET @EmailsSent = 0
	SET @BatchSize = 2000
		
	-- Loop through subscribers
	PRINT 'Looping through subscribers'
	DECLARE dataCursor CURSOR FOR
		SELECT MIN(libsub.UserId) AS UserId, FullName, Email, als.Id AS LibraryId, als.Library AS LibraryTitle,
			libsec.Id AS CollectionId, libsec.Title AS CollectionTitle,
			ResourceVersionId, libres.Title AS ResourceTitle, libres.[Description]
		FROM [IsleContent].dbo.[Library.Subscription] libsub
		INNER JOIN [Patron_Summary] patsum ON libsub.UserId = patsum.Id
		INNER JOIN [IsleContent].dbo.ActiveCollectionSummary als ON libsub.LibraryId = als.Id
		INNER JOIN [Library.Section] libsec ON als.Id = libsec.LibraryId
		INNER JOIN [Library.Resource] libres ON libsec.Id = libres.LibrarySectionId
		WHERE als.LastUpdated >= @sysprocLastRun 
		AND libres.Created >= @sysprocLastRun
		GROUP BY FullName, Email, als.Id, als.Library, libsec.Id, libsec.Title, ResourceVersionId, libres.Title, libres.Description
		ORDER BY UserId, als.Library, als.Id, libsec.Title, libsec.Id, libres.Title
	OPEN dataCursor
	FETCH NEXT FROM dataCursor INTO @UserId, @FullName, @Email, @LibraryId, @LibraryTitle,
		@CollectionId, @CollectionTitle, @ResourceVersionId, @ResourceTitle, @ResourceDescription
	
	WHILE @@FETCH_STATUS = 0 BEGIN
		-- Do First Record special processing
		IF @FirstTimeThru = 'True' BEGIN
			SET @HtmlBody = @HtmlBodyTemplate
			SET	@HtmlBody = REPLACE(@HtmlBody,'@FullName',@FullName)
			SET @HoldEmail = @Email
			SET @HoldUserId = @UserId
			SET @Data = @LibraryTemplate+@CollectionTemplate
			SET @Data = REPLACE(@Data,'@LibraryName',@LibraryTitle)
			SET @Data = REPLACE(@Data,'@CollectionName',@CollectionTitle)
			SET @HoldUserId = @UserId
			SET @HoldLibraryId = @LibraryId
			SET @HoldCollectionId = @CollectionId
			SET @FirstTimeThru = 'False'
		END
		
		-- Do @UserId control break processing
		IF @UserId <> @HoldUserId BEGIN
			SET @DoLibraryBreak = 'True'
			SET @HtmlBody = REPLACE(@HtmlBody,'@ResourceList',@Data)
			IF @debug > 11 BEGIN
				PRINT 'Skipping Email for  <'+@HoldEmail+'>: '+@HtmlBody
			END ELSE IF @debug > 9 BEGIN
				PRINT 'Skipping Email for '+@HoldEmail+'> - Sending to '+@adminAddress+': '+@HtmlBody
				EXEC msdb.dbo.sp_send_dbmail
					@profile_name = 'DoNotReply-ILSharedLearning',
					@recipients=@adminAddress,
					@subject=@Subject,
					@body=@HtmlBody,
					@body_format='HTML'
			END ELSE BEGIN
				EXEC msdb.dbo.sp_send_dbmail
					@profile_name='DoNotReply-ILSharedLearning',
					@recipients=@HoldEmail,
					@subject=@Subject,
					@body=@HtmlBody,
					@body_format='HTML'
			END
			SET @HtmlBody = @HtmlBodyTemplate
			SET	@HtmlBody = REPLACE(@HtmlBody,'@FullName',@FullName)
			SET @HoldEmail = @Email
			SET @HoldUserId = @UserId
			SET @Data = ''
			
			SET @EmailsSent = @EmailsSent + 1
			IF @EmailsSent % @BatchSize = 0 BEGIN
				WAITFOR DELAY '00:01:00'
				EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_status='sent'
			END
		END
		
		-- Do @LibraryId control break processing
		IF @LibraryId <> @HoldLibraryId OR @DoLibraryBreak = 'True' BEGIN
			SET @DoLibraryBreak = 'False'
			SET @DoCollectionBreak = 'True'
			SET @Data = @Data+@LibraryTemplate
			SET @Data = REPLACE(@Data,'@LibraryName',@LibraryTitle)
			SET @HoldLibraryId = @LibraryId
		END
		
		-- Do @CollectionId control break processing
		IF @CollectionId <> @HoldCollectionId OR @DoCollectionBreak = 'True' BEGIN
			SET @DoCollectionBreak = 'False'
			SET @Data = @Data+@CollectionTemplate
			SET @Data = REPLACE(@Data,'@CollectionName',@CollectionTitle)
			SET @HoldCollectionId = @CollectionId
		END
		
		-- Do Resource processing
		SET @Data = @Data+@ResourceTemplate
		SET @Data = REPLACE(@Data,'@VersionId',@ResourceVersionId)
		SET @Data = REPLACE(@Data,'@ResourceTitle',@ResourceTitle)
		SET @Data = REPLACE(@Data,'@Description',@ResourceDescription)
		
		FETCH NEXT FROM dataCursor INTO @UserId, @FullName, @Email, @LibraryId, @LibraryTitle,
			@CollectionId, @CollectionTitle, @ResourceVersionId, @ResourceTitle, @ResourceDescription
	END
	CLOSE dataCursor
	DEALLOCATE dataCursor
	SET @HtmlBody = REPLACE(@HtmlBody,'@ResourceList',@Data)
	IF @debug > 11 BEGIN
		PRINT 'Skipping Email for  <'+@HoldEmail+'>: '+@HtmlBody
	END ELSE IF @debug > 9 BEGIN
		PRINT 'Skipping Email for '+@HoldEmail+'> - Sending to '+@adminAddress+': '+@HtmlBody
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DoNotReply-ILSharedLearning',
			@recipients=@adminAddress,
			@subject=@Subject,
			@body=@HtmlBody,
			@body_format='HTML'
	END ELSE BEGIN
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name='DoNotReply-ILSharedLearning',
			@recipients=@HoldEmail,
			@subject=@Subject,
			@body=@HtmlBody,
			@body_format='HTML'
	END

	-- Cleanup emails already sent
	WAITFOR DELAY '00:01:00'
	EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_status='sent'
	
	-- Update System.Process record if applicable
	IF @debug < 11 BEGIN
		UPDATE [System.Process]
		SET LastRunDate = @LastRunDate
		WHERE Code = @code
	END	
END

GO
/****** Object:  StoredProcedure [dbo].[SendLibraryFollowerEmail]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Jerome Grimmer
-- Create date: 7/16/2013
-- Description:	Sends email notifications of resources recently added to followed libraries
--
-- Debug levels:
-- 10 = Send email to admin address instead of actual recipient.
-- 11 = Same as 10 plus skip the update of the System.Process record
-- 12 = Send *NO* e-mail and skip update of the System.Process record
--
-- 2014-01-28 jgrimmer - Altered to run in IsleContent database, where IOER libraries live.
-- =============================================
CREATE PROCEDURE [dbo].[SendLibraryFollowerEmail]
	@code varchar(50),
	@subscriptionTypeId int,
	@debug int = 1,
	@adminAddress varchar(50) = 'jgrimmer@siuccwd.com'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Get last run date
	DECLARE @sysprocId int, @sysprocLastRun datetime
	SELECT @sysprocId = Id, @sysprocLastRun = LastRunDate
	FROM [System.Process]
	WHERE Code = @code
	DECLARE @LastRunDate datetime
	SET @LastRunDate = GETDATE()
	
	-- Get email notice
	DECLARE @Subject varchar(100), @HtmlBodyTemplate nvarchar(max)
	SELECT @Subject = [Subject], @HtmlBodyTemplate = HtmlBody
	FROM EmailNotice
	WHERE NoticeCode = 'LibraryNotification'
	
	DECLARE @HtmlBody nvarchar(max), @Data nvarchar(max), @LibraryTemplate nvarchar(100), @CollectionTemplate nvarchar(100), @ResourceTemplate nvarchar(500)
	SET @LibraryTemplate = '<h1>Library: @LibraryName</h1>'
	SET @CollectionTemplate = '<h2>Collection: @CollectionName</h2>'
	SET @ResourceTemplate = '<a href="http://ioer.ilsharedlearning.org/ResourceDetail.aspx?vid=@VersionId">@ResourceTitle</a><br />@Description<br /><br />'
	
	DECLARE @UserId int, @FullName varchar(101), @Email varchar(100), @LibraryId int, @LibraryTitle varchar(200),
		@CollectionId int, @CollectionTitle varchar(100),
		@ResourceVersionId int, @ResourceTitle varchar(300), @ResourceDescription varchar(max),
		@HoldUserId int, @HoldEmail varchar(100), @HoldLibraryId int, @HoldCollectionId int,
		@FirstTimeThru bit, @DoLibraryBreak bit, @DoCollectionBreak bit, @EmailsSent int, @BatchSize int
	SET @FirstTimeThru = 'True'
	SET @DoLibraryBreak = 'False'
	SET @DoCollectionBreak = 'False'
	SET @EmailsSent = 0
	SET @BatchSize = 2000
		
	-- Loop through subscribers
	PRINT 'Looping through subscribers'
	DECLARE dataCursor CURSOR FOR
		SELECT MIN(libsub.UserId) AS UserId, FullName, Email, als.Id AS LibraryId, als.Title AS LibraryTitle,
			libsec.Id AS CollectionId, libsec.Title AS CollectionTitle,
			ResourceVersionId, libres.Title AS ResourceTitle, libres.[Description]
		FROM [Library.Subscription] libsub
		INNER JOIN Isle_IOER.dbo.[Patron_Summary] patsum ON libsub.UserId = patsum.Id
		INNER JOIN Isle_IOER.dbo.[ActiveLibrarySummary] als ON libsub.LibraryId = als.Id
		INNER JOIN Isle_IOER.dbo.[Library.Section] libsec ON als.Id = libsec.LibraryId
		INNER JOIN Isle_IOER.dbo.[Library.Resource] libres ON libsec.Id = libres.LibrarySectionId
		WHERE als.LastUpdated >= @sysprocLastRun AND libres.Created >= @sysprocLastRun AND
			patsum.Email NOT IN (SELECT [E-mail Address] FROM BouncedEmails WHERE [Bounce Type] = 'hard')
		GROUP BY FullName, Email, als.Id, als.Title, libsec.Id, libsec.Title, ResourceVersionId, libres.Title, libres.Description
		ORDER BY UserId, als.Title, als.Id, libsec.Title, libsec.Id, libres.Title
	OPEN dataCursor
	FETCH NEXT FROM dataCursor INTO @UserId, @FullName, @Email, @LibraryId, @LibraryTitle,
		@CollectionId, @CollectionTitle, @ResourceVersionId, @ResourceTitle, @ResourceDescription
	
	WHILE @@FETCH_STATUS = 0 BEGIN
		-- Do First Record special processing
		IF @FirstTimeThru = 'True' BEGIN
			SET @HtmlBody = @HtmlBodyTemplate
			SET	@HtmlBody = REPLACE(@HtmlBody,'@FullName',@FullName)
			SET @HoldEmail = @Email
			SET @HoldUserId = @UserId
			SET @Data = @LibraryTemplate+@CollectionTemplate
			SET @Data = REPLACE(@Data,'@LibraryName',@LibraryTitle)
			SET @Data = REPLACE(@Data,'@CollectionName',@CollectionTitle)
			SET @HoldUserId = @UserId
			SET @HoldLibraryId = @LibraryId
			SET @HoldCollectionId = @CollectionId
			SET @FirstTimeThru = 'False'
		END
		
		-- Do @UserId control break processing
		IF @UserId <> @HoldUserId BEGIN
			SET @DoLibraryBreak = 'True'
			SET @HtmlBody = REPLACE(@HtmlBody,'@ResourceList',@Data)
			IF @debug > 11 BEGIN
				PRINT 'Skipping Email for  <'+@HoldEmail+'>: '+@HtmlBody
			END ELSE IF @debug > 9 BEGIN
				PRINT 'Skipping Email for '+@HoldEmail+'> - Sending to '+@adminAddress+': '+@HtmlBody
				EXEC msdb.dbo.sp_send_dbmail
					@profile_name = 'DoNotReply-ILSharedLearning',
					@recipients=@adminAddress,
					@subject=@Subject,
					@body=@HtmlBody,
					@body_format='HTML'
			END ELSE BEGIN
				EXEC msdb.dbo.sp_send_dbmail
					@profile_name='DoNotReply-ILSharedLearning',
					@recipients=@HoldEmail,
					@subject=@Subject,
					@body=@HtmlBody,
					@body_format='HTML'
			END
			SET @HtmlBody = @HtmlBodyTemplate
			SET	@HtmlBody = REPLACE(@HtmlBody,'@FullName',@FullName)
			SET @HoldEmail = @Email
			SET @HoldUserId = @UserId
			SET @Data = ''
			
			SET @EmailsSent = @EmailsSent + 1
			IF @EmailsSent % @BatchSize = 0 BEGIN
				WAITFOR DELAY '00:01:00'
				EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_status='sent'
			END
		END
		
		-- Do @LibraryId control break processing
		IF @LibraryId <> @HoldLibraryId OR @DoLibraryBreak = 'True' BEGIN
			SET @DoLibraryBreak = 'False'
			SET @DoCollectionBreak = 'True'
			SET @Data = @Data+@LibraryTemplate
			SET @Data = REPLACE(@Data,'@LibraryName',@LibraryTitle)
			SET @HoldLibraryId = @LibraryId
		END
		
		-- Do @CollectionId control break processing
		IF @CollectionId <> @HoldCollectionId OR @DoCollectionBreak = 'True' BEGIN
			SET @DoCollectionBreak = 'False'
			SET @Data = @Data+@CollectionTemplate
			SET @Data = REPLACE(@Data,'@CollectionName',@CollectionTitle)
			SET @HoldCollectionId = @CollectionId
		END
		
		-- Do Resource processing
		SET @Data = @Data+@ResourceTemplate
		SET @Data = REPLACE(@Data,'@VersionId',@ResourceVersionId)
		SET @Data = REPLACE(@Data,'@ResourceTitle',@ResourceTitle)
		SET @Data = REPLACE(@Data,'@Description',@ResourceDescription)
		
		FETCH NEXT FROM dataCursor INTO @UserId, @FullName, @Email, @LibraryId, @LibraryTitle,
			@CollectionId, @CollectionTitle, @ResourceVersionId, @ResourceTitle, @ResourceDescription
	END
	CLOSE dataCursor
	DEALLOCATE dataCursor
	SET @HtmlBody = REPLACE(@HtmlBody,'@ResourceList',@Data)
	IF @debug > 11 BEGIN
		PRINT 'Skipping Email for  <'+@HoldEmail+'>: '+@HtmlBody
	END ELSE IF @debug > 9 BEGIN
		PRINT 'Skipping Email for '+@HoldEmail+'> - Sending to '+@adminAddress+': '+@HtmlBody
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = 'DoNotReply-ILSharedLearning',
			@recipients=@adminAddress,
			@subject=@Subject,
			@body=@HtmlBody,
			@body_format='HTML'
	END ELSE BEGIN
		EXEC msdb.dbo.sp_send_dbmail
			@profile_name='DoNotReply-ILSharedLearning',
			@recipients=@HoldEmail,
			@subject=@Subject,
			@body=@HtmlBody,
			@body_format='HTML'
	END

	-- Cleanup emails already sent
	WAITFOR DELAY '00:01:00'
	EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_status='sent'
	
	-- Update System.Process record if applicable
	IF @debug < 11 BEGIN
		UPDATE [System.Process]
		SET LastRunDate = @LastRunDate
		WHERE Code = @code
	END	
END

GO
/****** Object:  StoredProcedure [dbo].[sp_CrossTab]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
	exec sp_CrossTab 'MicrosoftVoucherAllocation', 'OrgId', 'Org', 
				'VoucherTypeId', 'VoucherCount', 'orgid = 515 '

*/
Create PROC [dbo].[sp_CrossTab]
	@table			AS sysname,				-- table to crosstab (or view?)
	@onRows			AS nvarchar(128),		-- Grouping key values
	@onRowsAlias	AS sysname = NULL,		-- Alias for grouping column
	@onCols			AS nvarchar(128),		-- Destination columns (on columns)
	@sumCol			AS sysname = NULL,		-- Data cells
	@where			AS nvarchar(128) = NULL
	,@printOnly		as bit = 0				-- set to zero, to just display the generate SQL
AS

Declare
	@sql		AS varchar (8000),
	@newLine	as char(1)

Set @newLine = char(10)

Declare @filter		nvarchar(128)
Print 'Check filter'

Set @filter = 
		Case
		   When @where Is Not Null Then ' Where ' + @where + ' ' + @newLine
		   Else ''
		End
Print 'filter = ' + @filter

-- step 1 beginning of sql string ===============================
Set @sql = 'Select ' + @newLine + 
	    ' ' + @onRows +
		Case
		   When @onRowsAlias Is Not Null Then ' AS ' + @onRowsAlias
		   Else ''
		End


Print ' - step 1 - ' + @newLine + @sql + @newLine 	
-- step 2

Create Table #keys(keyValue nvarchar(100) Not Null Primary Key)

Declare @keysSql as varchar(1000)
Set @keysSql = 
		'Insert Into #keys ' +
		'Select Distinct Cast(' + @onCols + ' AS nvarchar(100) )' + 
		'From ' + @table + ' ' + @filter

Print ' - step 2 - ' + @newLine + @keysSql + @newLine 	

Exec (@keysSql)

-- step 3
Declare @key as nvarchar(100)
Select @key = Min(keyValue) From #keys
Print ' - step 3 - Min key = ' + @key + @newLine 	

While @key Is Not Null
Begin
--if (@printOnly = 1) print @key

	Set @sql = @sql + ', ' + @newLine +
		'	Sum(Case Cast(' + @onCols + ' As nvarchar(100)) ' + @newLine +
		'	       When N''' + @key + 
		           '''   Then ' + Case 
					      When @sumCol Is Null Then '1'
					      Else @sumCol
					   End + @newLine +
		'	     Else 0' + @newLine +
		'	     End ) as [c' + @key + ']'
	

	Select @key = Min(keyValue) From #keys Where keyValue > @key
End


-- Print ' - sql = ' + @sql + @newLine 

Print 'Final sql, length = ' + Cast(len(@sql) As nvarchar(5))

Set @sql = @sql + @newLine +
	'From ' + @table + @newLine +
	@filter + @newLine + 
	'Group By ' + @onRows + @newLine + 
	'Order By ' + @onRows

Print @sql + @newLine 	

if (@printOnly = 0) begin
Exec (@sql)
end


GO
/****** Object:  Table [dbo].[ActivityLog]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ActivityLog](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CreatedDate] [datetime] NULL,
	[ActivityType] [varchar](25) NOT NULL,
	[Activity] [varchar](100) NOT NULL,
	[Event] [varchar](100) NOT NULL,
	[Comment] [varchar](500) NULL,
	[TargetUserId] [int] NULL,
	[ActionByUserId] [int] NULL,
	[ActivityObjectId] [int] NULL,
	[Int2] [int] NULL,
	[RelatedImageUrl] [varchar](200) NULL,
	[RelatedTargetUrl] [varchar](200) NULL,
 CONSTRAINT [PK_ActivityLog] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BouncedEmails]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BouncedEmails](
	[E-mail Address] [nvarchar](50) NULL,
	[Date] [varchar](50) NULL,
	[Count] [nvarchar](50) NULL,
	[Bounce Type] [nvarchar](150) NULL,
	[Bounce Reason] [nvarchar](250) NULL,
	[id] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_BouncedEmails] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Codes.ContentPrivilege]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Codes.ContentPrivilege](
	[Id] [int] NOT NULL,
	[Title] [varchar](50) NULL,
	[StemTitle] [varchar](50) NULL,
	[Description] [varchar](200) NULL,
	[SortOrder] [int] NULL,
	[IsActive] [bit] NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Codes.ContentPrivilege] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Codes.ContentStatus]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Codes.ContentStatus](
	[Id] [int] NOT NULL,
	[Title] [varchar](50) NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Codes.ContentStatus] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Codes.LibraryAccessLevel]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Codes.LibraryAccessLevel](
	[Id] [int] NOT NULL,
	[Title] [varchar](50) NULL,
	[IsActive] [bit] NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Codes.LibraryAccessLevel] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Codes.LibraryMemberType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Codes.LibraryMemberType](
	[Id] [int] NOT NULL,
	[Title] [varchar](50) NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Codes.LibraryMemberType] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Codes.SubscriptionType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Codes.SubscriptionType](
	[Id] [int] NOT NULL,
	[Title] [varchar](50) NULL,
	[IsActive] [bit] NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Codes.SubscriptionType] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Community]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Community](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](max) NULL,
	[ImageUrl] [varchar](200) NULL,
	[ContactId] [int] NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Community] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Community.Member]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Community.Member](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CommunityId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Community.Member] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Community.Posting]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Community.Posting](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CommunityId] [int] NOT NULL,
	[Message] [nvarchar](max) NULL,
	[CreatedById] [int] NOT NULL,
	[Created] [datetime] NULL,
	[RelatedPostingId] [int] NULL,
 CONSTRAINT [PK_Community.Posting] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Community.PostingDocument]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Community.PostingDocument](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PostingId] [int] NULL,
	[DocumentId] [uniqueidentifier] NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NULL,
 CONSTRAINT [PK_Community.PostingDocument] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Content]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Content](
	[Id] [int] IDENTITY(1000,1) NOT NULL,
	[TypeId] [int] NULL,
	[Title] [varchar](200) NULL,
	[Summary] [varchar](max) NULL,
	[Description] [varchar](max) NULL,
	[StatusId] [int] NULL,
	[PrivilegeTypeId] [int] NULL,
	[ConditionsOfUseId] [int] NULL,
	[IsActive] [bit] NULL,
	[IsPublished] [bit] NULL,
	[IsOrgContentOwner] [bit] NULL,
	[OrgId] [int] NULL,
	[ResourceVersionId] [int] NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedById] [int] NULL,
	[Approved] [datetime] NULL,
	[ApprovedById] [int] NULL,
	[RowId] [uniqueidentifier] NOT NULL,
	[UseRightsUrl] [varchar](200) NULL,
	[DocumentRowId] [uniqueidentifier] NULL,
	[DocumentUrl] [varchar](200) NULL,
 CONSTRAINT [PK_Table_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Content.History]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Content.History](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ContentId] [int] NOT NULL,
	[Action] [varchar](75) NOT NULL,
	[Description] [varchar](max) NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NOT NULL,
 CONSTRAINT [PK_Content.History] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Content.Reference]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Content.Reference](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ParentId] [int] NOT NULL,
	[Title] [varchar](200) NOT NULL,
	[Author] [varchar](100) NULL,
	[Publisher] [varchar](100) NULL,
	[ISBN] [varchar](50) NULL,
	[ReferenceUrl] [varchar](200) NULL,
	[AdditionalInfo] [varchar](500) NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedById] [int] NULL,
 CONSTRAINT [PK_Content.Reference] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Content.Supplement]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Content.Supplement](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ParentId] [int] NOT NULL,
	[Title] [varchar](200) NOT NULL,
	[Description] [varchar](max) NULL,
	[ResourceUrl] [varchar](200) NULL,
	[PrivilegeTypeId] [int] NULL,
	[IsActive] [bit] NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedById] [int] NULL,
	[RowId] [uniqueidentifier] NULL,
	[DocumentRowId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Content.Supplement] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ContentFile]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ContentFile](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [varchar](200) NOT NULL,
	[Description] [varchar](max) NULL,
	[ResourceUrl] [varchar](200) NOT NULL,
	[OrgId] [int] NULL,
	[ResourceVersionId] [int] NULL,
	[IsActive] [bit] NOT NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NULL,
	[LastUpdated] [datetime] NOT NULL,
	[LastUpdatedById] [int] NULL,
	[DocumentRowId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_ContentFile] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ContentTemplate]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ContentTemplate](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [varchar](50) NULL,
	[Template] [varchar](max) NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_ContentTemplate] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ContentType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[ContentType](
	[Id] [int] NOT NULL,
	[Title] [varchar](50) NOT NULL,
	[Description] [varchar](200) NOT NULL,
	[HasApproval] [bit] NULL,
	[MaxVersions] [smallint] NULL,
	[IsActive] [bit] NULL,
	[Created] [datetime] NULL,
	[RowId] [uniqueidentifier] NOT NULL,
 CONSTRAINT [PK_Content.Type] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Document.Version]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Document.Version](
	[RowId] [uniqueidentifier] NOT NULL,
	[Title] [varchar](200) NOT NULL,
	[Summary] [varchar](500) NULL,
	[Status] [varchar](25) NULL,
	[FileName] [varchar](150) NULL,
	[FileDate] [datetime] NULL,
	[MimeType] [varchar](150) NULL,
	[Bytes] [bigint] NULL,
	[Data] [varbinary](max) NOT NULL,
	[Url] [varchar](150) NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NOT NULL,
	[LastUpdated] [datetime] NOT NULL,
	[LastUpdatedById] [int] NOT NULL,
 CONSTRAINT [PK_Document.Version] PRIMARY KEY CLUSTERED 
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IdesOccupations]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IdesOccupations](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Occupation] [varchar](150) NULL,
	[Agency] [varchar](150) NULL,
	[Phone] [varchar](50) NULL,
	[URL] [varchar](150) NULL,
	[JobDescription] [varchar](max) NULL,
	[Statute] [varchar](150) NULL,
	[TypeOfRegulation] [varchar](150) NULL,
	[NumberRegulated] [varchar](150) NULL,
	[Age] [varchar](50) NULL,
	[Education_Experience] [varchar](max) NULL,
	[Exam] [varchar](max) NULL,
	[ExamType] [varchar](150) NULL,
	[Administered] [varchar](150) NULL,
	[ExamFee] [varchar](150) NULL,
	[PassingCriteria] [varchar](150) NULL,
	[Repeats] [varchar](150) NULL,
	[ContinuingEducation] [varchar](max) NULL,
	[Citizenship] [varchar](150) NULL,
	[Other] [varchar](max) NULL,
	[Note] [varchar](max) NULL,
	[ApplicationFee] [varchar](150) NULL,
	[LicenseFee] [varchar](150) NULL,
	[RenewalFee] [varchar](150) NULL,
	[ReinstatementFee] [varchar](150) NULL,
	[LicensePeriod] [varchar](150) NULL,
	[Reciprocity_Endorsement] [varchar](max) NULL,
 CONSTRAINT [PK_IdesOccupations_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [varchar](200) NOT NULL,
	[Description] [varchar](500) NULL,
	[LibraryTypeId] [int] NULL,
	[IsDiscoverable] [bit] NULL,
	[PublicAccessLevel] [int] NOT NULL,
	[OrgAccessLevel] [int] NOT NULL,
	[OrgId] [int] NULL,
	[IsActive] [bit] NULL,
	[ImageUrl] [varchar](200) NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedById] [int] NULL,
	[RowId] [uniqueidentifier] NOT NULL,
	[IsPublic] [bit] NULL,
 CONSTRAINT [PK_Library] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library.Comment]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library.Comment](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibraryId] [int] NULL,
	[Comment] [varchar](1000) NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NULL,
 CONSTRAINT [PK_Library.Comment] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library.ExternalSection]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Library.ExternalSection](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibraryId] [int] NOT NULL,
	[ExternalSectionId] [int] NOT NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NULL,
	[RowId] [uniqueidentifier] NULL,
 CONSTRAINT [PK_Library.ExternalSection] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Library.Invitation]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library.Invitation](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibraryId] [int] NULL,
	[RowId] [uniqueidentifier] NOT NULL,
	[InvitationType] [varchar](50) NULL,
	[PassCode] [varchar](50) NULL,
	[TargetEmail] [varchar](150) NULL,
	[TargetUserId] [int] NULL,
	[Subject] [varchar](100) NULL,
	[MessageContent] [varchar](max) NULL,
	[EmailNoticeCode] [varchar](50) NULL,
	[Response] [varchar](50) NULL,
	[ResponseDate] [datetime] NULL,
	[ExpiryDate] [datetime] NULL,
	[IsActive] [bit] NULL,
	[DeleteOnResponse] [bit] NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NOT NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedById] [int] NULL,
	[LibMemberTypeId] [int] NULL,
	[StartingUrl] [varchar](200) NULL,
 CONSTRAINT [PK_Library.Invitation] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library.Like]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Library.Like](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibraryId] [int] NOT NULL,
	[IsLike] [bit] NOT NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NOT NULL,
 CONSTRAINT [PK_Library.Like_1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Library.Member]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Library.Member](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibraryId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[MemberTypeId] [int] NOT NULL,
	[RowId] [uniqueidentifier] NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NULL,
	[LastUpdated] [datetime] NOT NULL,
	[LastUpdatedById] [int] NULL,
 CONSTRAINT [PK_Library.Member] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_Library.Member_LibUser] UNIQUE NONCLUSTERED 
(
	[LibraryId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Library.Party]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Library.Party](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ParentRowId] [uniqueidentifier] NOT NULL,
	[RelatedRowId] [uniqueidentifier] NOT NULL,
	[Created] [datetime] NOT NULL,
 CONSTRAINT [PK_Library.Party] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Library.PartyComment]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library.PartyComment](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RowId] [uniqueidentifier] NOT NULL,
	[Comment] [varchar](1000) NOT NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NOT NULL,
 CONSTRAINT [PK_Library.PartyComment] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library.Resource]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library.Resource](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibrarySectionId] [int] NOT NULL,
	[ResourceIntId] [int] NOT NULL,
	[IsActive] [bit] NULL,
	[Comment] [varchar](500) NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NULL,
 CONSTRAINT [PK_Library.Resource] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library.Section]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library.Section](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibraryId] [int] NOT NULL,
	[SectionTypeId] [int] NOT NULL,
	[Title] [varchar](100) NULL,
	[Description] [varchar](500) NULL,
	[ParentId] [int] NULL,
	[IsDefaultSection] [bit] NULL,
	[PublicAccessLevel] [int] NOT NULL,
	[OrgAccessLevel] [int] NOT NULL,
	[AreContentsReadOnly] [bit] NULL,
	[ImageUrl] [varchar](200) NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NULL,
	[LastUpdated] [datetime] NULL,
	[LastUpdatedById] [int] NULL,
	[RowId] [uniqueidentifier] NULL,
	[IsPublic] [bit] NULL,
 CONSTRAINT [PK_Library.Section] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library.SectionComment]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library.SectionComment](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SectionId] [int] NULL,
	[Comment] [varchar](1000) NULL,
	[Created] [datetime] NULL,
	[CreatedById] [int] NULL,
 CONSTRAINT [PK_Library.SectionComment] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library.SectionLike]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Library.SectionLike](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SectionId] [int] NOT NULL,
	[IsLike] [bit] NOT NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NOT NULL,
 CONSTRAINT [PK_Library.SectionLike] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Library.SectionMember]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Library.SectionMember](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibrarySectionId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[MemberTypeId] [int] NOT NULL,
	[RowId] [uniqueidentifier] NULL,
	[Created] [datetime] NOT NULL,
	[CreatedById] [int] NULL,
	[LastUpdated] [datetime] NOT NULL,
	[LastUpdatedById] [int] NULL,
 CONSTRAINT [PK_Library.SectionMember] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_Library.SectionMember_LibUser] UNIQUE NONCLUSTERED 
(
	[LibrarySectionId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Library.SectionSubscription]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Library.SectionSubscription](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SectionId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[SubscriptionTypeId] [int] NULL,
	[PrivilegeId] [int] NULL,
	[Created] [datetime] NULL,
	[LastUpdated] [datetime] NULL,
 CONSTRAINT [PK_Library.SectionSubscription] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Library.SectionType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library.SectionType](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [varchar](50) NOT NULL,
	[AreContentsReadOnly] [bit] NULL,
	[Decription] [varchar](200) NULL,
	[SectionCode] [varchar](25) NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Library.SectionType] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Library.Subscription]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Library.Subscription](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LibraryId] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[SubscriptionTypeId] [int] NULL,
	[PrivilegeId] [int] NULL,
	[Created] [datetime] NULL,
	[LastUpdated] [datetime] NULL,
 CONSTRAINT [PK_Library.Subscription] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Library.Type]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Library.Type](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Title] [varchar](50) NULL,
	[Description] [varchar](300) NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Library.Type] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Person.Following]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Person.Following](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FollowingUserId] [int] NOT NULL,
	[FollowedByUserId] [int] NOT NULL,
	[Created] [datetime] NULL,
 CONSTRAINT [PK_Person.Following] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[LibraryCollection.ResourceCount]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
SELECT [LibraryId]
      ,[Library]
      ,[Collection]
      ,[NbrResources]
  FROM [dbo].[LibraryCollection.ResourceCount]
order by 2, 3




*/
CREATE VIEW [dbo].[LibraryCollection.ResourceCount]
AS
SELECT     LibraryId, Library, Title + ' (' + CONVERT(varchar(10), NbrResources) + ')' AS [Collection], NbrResources
FROM         (SELECT     l.Id AS LibraryId, l.Title As Library, ls.Title, ISNULL(COUNT(lr.ResourceIntId), 0) AS NbrResources
                       FROM          dbo.Library AS l INNER JOIN
                                              dbo.[Library.Section] AS ls ON l.Id = ls.LibraryId LEFT OUTER JOIN
                                              dbo.[Library.Resource] AS lr ON ls.Id = lr.LibrarySectionId
                       GROUP BY l.Id, l.Title, ls.Title) AS ltbl


GO
/****** Object:  View [dbo].[Library.ResourceCount]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
USE [IsleContent]
GO

SELECT [LibraryId]
      ,[Library]
      ,[LibraryResourceCount]
  FROM [dbo].[Library.ResourceCount]
--where libraryId = 25
order by 3 desc


*/
Create  VIEW [dbo].[Library.ResourceCount] AS

SELECT [LibraryId], Library
      ,sum(NbrResources) As LibraryResourceCount
  FROM [dbo].[LibraryCollection.ResourceCount]
  group by LibraryId, Library
  --order by 3 desc
  

GO
/****** Object:  View [dbo].[Gateway.OrgSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
SELECT [id]
      ,[Name]
      ,[OrgTypeId]
      ,[OrgType]
      ,[parentId]

      ,base.[IsActive]
      ,[MainPhone],[MainExtension],[Fax],[TTY]
      ,[WebSite],[Email]
      ,[LogoUrl]
      ,[Address],[Address2],[City],[State],[Zipcode]
      ,base.[Created]      ,base.[CreatedById]
      ,[LastUpdated]      ,[LastUpdatedById]
  FROM [IsleContent].[dbo].[Gateway.OrgSummary]
GO



*/

/*
[Gateway.OrgSummary] - select org summary . 
    
*/
Create VIEW [dbo].[Gateway.OrgSummary] AS

SELECT [id]
      ,[Name]
      ,[OrgTypeId]
      ,[OrgType]
      ,[parentId],[ParentOrganization]
      ,[IsActive]
      ,[MainPhone],[MainExtension],[Fax],[TTY]
      ,[WebSite],[Email],[LogoUrl]
      ,[Address],[Address2],[City],[State],[Zipcode]
      ,[Created],[CreatedById]
      ,[LastUpdated],[LastUpdatedById]

  FROM [Gateway].[dbo].[Organization_Summary]



GO
/****** Object:  View [dbo].[LR.PatronOrgSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
SELECT [UserId]
  ,[UserName]
  ,SortName
  ,[FullName]
  ,[OrganizationId]
  ,[Organization]
  ,[FirstName]
  ,[LastName]
  ,[Email]
  ,[JobTitle]
  ,[RoleProfile]
   ,ImageUrl 
	  ,UserRowId
  FROM [IsleContent].[dbo].[LR.PatronOrgSummary]
  order by LastName
 

*/
/*
[LR.PatronOrgSummary] - select User summary . 
    
*/
Create VIEW [dbo].[LR.PatronOrgSummary] AS
SELECT base.[Id] As UserId
      ,base.[UserName]
      ,base.[FirstName],base.[LastName], base.[FullName], base.SortName
      ,base.[Email]
      ,PublishingRole
      ,base.[JobTitle]
      ,base.[RoleProfile]
	  ,base.ImageUrl 
	  ,base.UserRowId
      ,base.[OrganizationId]
      ,case when org.Id is not null then org.Name
        else 'none' end As Organization
        ,base.Created, base.LastUpdated
  FROM [Isle_IOER].[dbo].[Patron_Summary] base
  Left join [Gateway].[dbo].[Organization] org on base.OrganizationId = org.Id
  

GO
/****** Object:  View [dbo].[ContentSummaryView]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
SELECT [ContentId]
      ,[TypeId]
      ,[ContentType]
      ,[Title]
      ,[Summary]
      ,[Description]
      ,[StatusId]
      ,[ContentStatus]
      ,[PrivilegeTypeId]
      ,[ContentPrivilege], ConditionsOfUseId
      ,[IsPublished]
      ,[OrgId], IsOrgContentOwner
      ,Author
      ,[Created]
      ,[CreatedById]
      ,[LastUpdated]
      ,[LastUpdatedById]
      ,[ApprovedById]
      ,[Approved]
--    select *      
  FROM [IsleContent].[dbo].[ContentSummaryView]
GO
select * 
FROM [IsleContent].[dbo].[ContentSummaryView]
where OrgKey = 'siuccwd'
And AuthorKey = 'MichaelParsons'
And TypeId = 20



UPDATE [IsleContent].[dbo].[Content]
   SET [IsOrgContentOwner] = 1
 WHERE OrgId > 0
GO

UPDATE [IsleContent].[dbo].[Content]
   SET [IsOrgContentOwner] = 0
 WHERE OrgId is null
GO



*/
/* =============================================
Description: Content summary, convenience view

  ------------------------------------------------------
Modifications
13-04-23 mparsons - added ResourceVersionId
14-01-29 mparsons - added missing IsActive
*/

CREATE VIEW [dbo].[ContentSummaryView]
AS
SELECT     
  base.Id As ContentId,
  base.TypeId, dbo.ContentType.Title AS ContentType, 
  base.Title, 
  base.Summary, 
  base.Description, 
  base.StatusId, dbo.[Codes.ContentStatus].Title AS ContentStatus, 
  case when PrivilegeTypeId is null then 1
  else PrivilegeTypeId end as PrivilegeTypeId,
  
  case when PrivilegeTypeId is null then 'Public'
  else dbo.[Codes.ContentPrivilege].Title end as ContentPrivilege,  
  ConditionsOfUseId, 
  isnull(ResourceVersionId, 0) AS ResourceVersionId,
  base.IsPublished, 
  IsOrgContentOwner, 
  base.IsActive,
  base.OrgId,
  org.Name as Organization,
  org.ParentId ParentOrgId,
  case when org.ParentId > 0 then org.[ParentOrganization]
  else '' end as [ParentOrganization],
  
  base.Created, base.CreatedById, 
  isnull(author.FullName, '') As Author,
  	replace(isnull(author.FullName, ''), ' ','') As AuthorKey,
	replace(isnull(org.Name, ''), ' ','') As OrgKey,
  base.LastUpdated, base.LastUpdatedById, 
  base.ApprovedById, base.Approved
  ,base.RowId As ContentRowId 
FROM         
  dbo.[Content] base
  INNER JOIN dbo.[Codes.ContentStatus]    ON base.StatusId = dbo.[Codes.ContentStatus].Id 
  INNER JOIN dbo.ContentType              ON base.TypeId = dbo.ContentType.Id 
  Left JOIN dbo.[Codes.ContentPrivilege]  ON base.PrivilegeTypeId = dbo.[Codes.ContentPrivilege].Id
  Left Join dbo.[LR.PatronOrgSummary] author on base.CreatedById = author.UserId
  Left Join [Gateway.OrgSummary] org      on base.OrgId = org.Id


GO
/****** Object:  View [dbo].[Library.MemberSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[Library.MemberSummary]
AS

SELECT        
	base.Id, 
	base.LibraryId, 
	dbo.Library.Title AS Library, 
	base.UserId, 
	acct.FullName, 
	acct.SortName,
	acct.Email, 
	base.MemberTypeId, 
	code.Title AS MemberType, 
	base.Created, 
	base.CreatedById, 
	base.LastUpdated, 
	base.LastUpdatedById

FROM            dbo.[Library.Member] base
INNER JOIN dbo.[Codes.LibraryMemberType] code ON base.MemberTypeId = code.Id 
INNER JOIN dbo.[LR.PatronOrgSummary] acct ON base.UserId = acct.UserId
INNER JOIN dbo.Library ON base.LibraryId = dbo.Library.Id


GO
/****** Object:  View [dbo].[Library.SectionMemberSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[Library.SectionMemberSummary]
AS

SELECT        
	base.Id, 
	ls.LibraryId, 
	dbo.Library.Title AS Library,
	base.LibrarySectionId,
	ls.Title As [Collection],
	base.UserId, 
	acct.FullName, 
	acct.SortName,
	acct.Email, 
	base.MemberTypeId, 
	code.Title AS MemberType, 
	base.Created, 
	base.CreatedById, 
	base.LastUpdated, 
	base.LastUpdatedById

FROM  dbo.[Library.SectionMember] base
INNER JOIN dbo.[Library.Section] ls ON base.LibrarySectionId = ls.Id
INNER JOIN dbo.[Codes.LibraryMemberType] code ON base.MemberTypeId = code.Id 
INNER JOIN dbo.[LR.PatronOrgSummary] acct ON base.UserId = acct.UserId 
INNER JOIN dbo.Library ON ls.LibraryId = dbo.Library.Id


GO
/****** Object:  View [dbo].[Community.PostingSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
USE [IsleContent]
GO

SELECT [CommunityId]
      ,[Community]
      ,[CreatedById]
      ,[UserFullName]
      ,[UserImageUrl]
	  ,Id
      ,[Message]
      ,[RelatedPostingId]
  FROM [dbo].[Community.PostingSummary]
GO



*/

CREATE VIEW [dbo].[Community.PostingSummary]
AS
SELECT        
	cp.CommunityId, 
	dbo.Community.Title AS Community, 
	cp.CreatedById, 
	cp.Created,
	dbo.[LR.PatronOrgSummary].FullName As UserFullName, 
	dbo.[LR.PatronOrgSummary].ImageUrl As UserImageUrl, 
	cp.Id As Id,
	cp.Message, 
	cp.RelatedPostingId
FROM            
	dbo.Community 
INNER JOIN [Community.Posting] cp ON dbo.Community.Id = cp.CommunityId 
INNER JOIN dbo.[LR.PatronOrgSummary] ON cp.CreatedById = dbo.[LR.PatronOrgSummary].UserId


GO
/****** Object:  View [dbo].[LR.ResourceVersion_Summary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
select * from [LR.ResourceVersion_Summary]
where [ResourceUrl] like '%209.7.195.215%'


*/
/*
[LR.ResourceVersion_Summary] - select conditions of use from IOER database . 
    
*/
CREATE VIEW [dbo].[LR.ResourceVersion_Summary] AS
SELECT [ResourceUrl]
      ,[Id]
      ,[ResourceIntId]
      ,[ResourceId]
    --  ,[ResourceVersionId]
      ,[ResourceVersionIntId]
      ,[Title]
      ,[Description]
      ,[Publisher]
      ,[Creator]
      ,[Rights]
      ,[ViewCount]
      ,[FavoriteCount]
      ,[AccessRightsId]
      ,[AccessRights]
      ,[InteractivityTypeId]
      ,[TypicalLearningTime]
      ,[Modified]
      ,[Submitter]
      ,[SortTitle]
  FROM [Isle_IOER].[dbo].[Resource.Version_Summary]

GO
/****** Object:  View [dbo].[Library.SectionResourceSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
SELECT 
      [LibraryId]
      ,[Library]
      ,[LibraryTypeId]
      ,[LibraryType]
      ,[OrgId]
      ,[IsDiscoverable]
      ,[IsPublic]
      ,[LibraryCreatedById]
      ,[LibrarySectionId], LibrarySection
      ,[SectionTypeId]
      ,[LibrarySectionType]
      ,[IsDefaultSection]
	  ,IsCollectionPublic
      ,[AreContentsReadOnly]
      ,LibraryResourceId, [ResourceIntId]
      ,DateAddedToCollection
		,ResourceCreated
  FROM [dbo].[Library.SectionResourceSummary]
where 
ResourceIntId = 446014
--LibrarySectionId= 4




*/
/*
[Library.SectionResourceSummary] - summary of library resource . 
    
*/
CREATE VIEW [dbo].[Library.SectionResourceSummary] AS

SELECT      
  libSection.LibraryId, 
  lib.Title AS Library, 
  lib.LibraryTypeId, 
  dbo.[Library.Type].Title AS LibraryType, 
  isnull(lib.OrgId, 0) As OrgId, 
  lib.IsDiscoverable, 
  lib.IsPublic, 
  lib.CreatedById AS LibraryCreatedById, 
  libResource.LibrarySectionId, 
  libSection.SectionTypeId, 
  libSection.Title AS LibrarySection, 
  dbo.[Library.SectionType].Title AS LibrarySectionType, 
  libSection.IsDefaultSection, 
  libSection.IsPublic as IsCollectionPublic, 
  dbo.[Library.SectionType].AreContentsReadOnly,
  libResource.Id As LibraryResourceId,
  libResource.ResourceIntId
  ,libResource.Created as DateAddedToCollection
  ,libResource.CreatedById AS libResourceCreatedById

  ,lr.[Modified] as ResourceCreated
  ,lr.Title
  ,lr.ResourceVersionIntId

FROM  dbo.Library lib
INNER JOIN dbo.[Library.Section] libSection			ON lib.Id = libSection.LibraryId 
INNER JOIN dbo.[Library.Type]						ON lib.LibraryTypeId = dbo.[Library.Type].Id 
INNER JOIN dbo.[Library.SectionType]				ON libSection.SectionTypeId = dbo.[Library.SectionType].Id 
INNER JOIN dbo.[Library.Resource] libResource		ON libSection.Id = libResource.LibrarySectionId
Inner join [dbo].[LR.ResourceVersion_Summary] lr	on libResource.ResourceIntId = lr.ResourceIntId 
--leave it up to usage to determine if a lib can be included
--where [IsDiscoverable]= 1



GO
/****** Object:  View [dbo].[LibraryCollection.ResourceCountCSV]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[LibraryCollection.ResourceCountCSV]
AS 
SELECT LibraryId, LEFT(Titles, LEN(Titles) - 1) AS Titles
FROM (
	SELECT LibraryId, (
		SELECT isnull(itbl.Collection,'')+','
		FROM [LibraryCollection.ResourceCount] itbl
		WHERE itbl.LibraryId = tbl.LibraryId
		FOR XML PATH('')) Titles
	FROM [LibraryCollection.ResourceCount] tbl
	GROUP BY LibraryId) otbl

GO
/****** Object:  View [dbo].[ActiveCollectionSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create VIEW [dbo].[ActiveCollectionSummary] AS
	SELECT 
	lib.Id As LibraryId, lib.Title As Library, LibraryTypeId,
	libsec.Id, libsec.Title As [Collection], 
		
		isnull(colResCount.ResCount, 0) AS NbrResources, 
		colResUpdated.LastUpdated
	FROM dbo.[Library] lib
	INNER JOIN dbo.[Library.Section] libsec on lib.Id = libsec.LibraryId
	--INNER JOIN dbo.[Library.Resource] libres on libsec.Id = libres.LibrarySectionId
	Left Join (Select LibrarySectionId, count(*) As ResCount from [Library.Resource] group by LibrarySectionId ) 
		As colResCount on libsec.id = colResCount.LibrarySectionId
	Left Join (Select LibrarySectionId, MAX(Created) As LastUpdated from [Library.Resource] group by LibrarySectionId ) 
		As colResUpdated on libsec.id = colResUpdated.LibrarySectionId

	WHERE lib.IsActive = 1
	--Order BY lib.Title, libsec.Title


GO
/****** Object:  View [dbo].[ActiveLibrarySummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- moved from Isle_IOER
CREATE VIEW [dbo].[ActiveLibrarySummary] AS
	SELECT lib.Id, lib.Title, lib.[Description], 
		LibraryTypeId, lt.Title as LibraryType, 
		IsDiscoverable, 
		lib.IsPublic, 
		lib.imageUrl,
		isnull(libResCount.ResCount, 0) AS NbrResources, 
		libResUpdated.LastUpdated
	FROM dbo.[Library] lib
	inner join [Library.Type] lt on lib.LibraryTypeId = lt.Id
	Left Join (
		Select ls.LibraryId, count(*) As ResCount from [Library.Resource] lr
		inner join [Library.Section] ls on lr.LibrarySectionId = ls.Id group by ls.LibraryId ) 
			As libResCount on lib.id = libResCount.LibraryId
	Left Join (Select ls.LibraryId, MAX(lr.Created) As LastUpdated from [Library.Resource] lr
		inner join [Library.Section] ls on lr.LibrarySectionId = ls.Id group by ls.LibraryId ) 
			As libResUpdated on lib.id = libResUpdated.LibraryId
	WHERE lib.IsActive = 1



GO
/****** Object:  View [dbo].[Codes.AccessRights]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Codes.AccessRights] AS
SELECT [Id]
      ,[Title]
      ,[Description]
      ,[IsActive]
      ,[WarehouseTotal]
      ,[SortOrder]
  FROM Isle_IOER.[dbo].[Codes.AccessRights]



GO
/****** Object:  View [dbo].[Codes.AudienceType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Codes.AudienceType] AS
SELECT [Id]
      ,[Title]
      ,[NsdtTitle]
      ,[Description]
      ,[IsPathways]
      ,[IsActive]
      ,[IsPublishingRole]
      ,[WarehouseTotal]
  FROM Isle_IOER.[dbo].[Codes.AudienceType]


GO
/****** Object:  View [dbo].[Codes.CareerCluster]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[Codes.CareerCluster] AS
SELECT [Id]
      ,[Title]
      ,[WarehouseTotal]
	  ,IsActive
  FROM Isle_IOER.[dbo].[Codes.CareerCluster]




GO
/****** Object:  View [dbo].[Codes.EducationalUse]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[Codes.EducationalUse] AS
SELECT [Id]
      ,[Title]
      ,[Description]
      ,[IsActive]
      ,[WarehouseTotal]
  FROM Isle_IOER.[dbo].[Codes.EducationalUse]



GO
/****** Object:  View [dbo].[Codes.GradeLevel]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Codes.GradeLevel] AS
SELECT [Id]
      ,[Title]
      ,[NsdlTitle]
      ,[AgeLevel]
      ,[Description]
      ,[IsPathwaysLevel]
      ,[IsK12Level]
      ,[IsActive]
      ,[AlignmentUrl]
      ,[SortOrder]
      ,[WarehouseTotal]
      ,[GradeRange]
      ,[GradeGroup]
      ,[PathwaysEducationLevelId]
  FROM Isle_IOER.[dbo].[Codes.GradeLevel]


GO
/****** Object:  View [dbo].[Codes.GroupType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[Codes.GroupType] AS
SELECT [Id]
      ,[Title]
      ,[Description]
      ,[IsActive]
      ,[WarehouseTotal]
  FROM Isle_IOER.[dbo].[Codes.GroupType]



GO
/****** Object:  View [dbo].[Codes.IntendedAudience]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create VIEW [dbo].[Codes.IntendedAudience] AS
SELECT [Id]
      ,[Title]
      ,[IsActive]
      ,[WarehouseTotal]
  FROM [Isle_IOER].[dbo].[Codes.AudienceType]

GO
/****** Object:  View [dbo].[Codes.ResourceFormat]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Codes.ResourceFormat] AS
SELECT [Id]
      ,[Title]
      ,[Description]
      ,[IsIsleCode]
      ,[IsActive]
      ,[WarehouseTotal]
      ,[OrigTitle]
  FROM Isle_IOER.[dbo].[Codes.ResourceFormat]


GO
/****** Object:  View [dbo].[Codes.ResourceType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Codes.ResourceType] AS
SELECT [Id]
      ,[Title]
      ,[Description]
      ,[IsIsleItem]
      ,[IsActive]
      ,[SortOrder]
      ,[WarehouseTotal]
      ,[CategoryId]
      ,[OrigTitle]
  FROM Isle_IOER.[dbo].[Codes.ResourceType]


GO
/****** Object:  View [dbo].[EmailNotice]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[EmailNotice]
AS
SELECT        id, Title, Category, NoticeCode, Description, Filter, isActive, LanguageCode, FromEmail, CcEmail, BccEmail, Subject, HtmlBody, TextBody, Created, CreatedBy, 
                         LastUpdated, LastUpdatedBy
FROM            Isle_IOER.dbo.EmailNotice

GO
/****** Object:  View [dbo].[LR.ConditionOfUse_Select]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*


*/
/*
[LR.ConditionOfUse_Select] - select conditions of use from IOER database . 
    
*/
CREATE VIEW [dbo].[LR.ConditionOfUse_Select] AS
SELECT [Id]
      ,[Summary]
      ,[Title]
      ,[Description]
      ,[IsActive]
      ,[Url]
      ,[IconUrl]
      ,[ConditionOfUseCategory]
      ,[WarehouseTotal]
  FROM Isle_IOER.[dbo].[ConditionOfUse]


GO
/****** Object:  View [dbo].[LR.Resource.Evaluations]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[LR.Resource.Evaluations] AS
  select distinct  [ResourceIntId],[CreatedById]
  --,count(*) as REcounts
  FROM [Isle_IOER].[dbo].[Resource.Evaluation] 



GO
/****** Object:  View [dbo].[LR.Resource.EvaluationsCount]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[LR.Resource.EvaluationsCount] AS

SELECT [ResourceIntId]
      ,[EvaluationsCount]
  FROM [Isle_IOER].[dbo].[Resource.EvaluationsCount]


GO
/****** Object:  View [dbo].[LR.ResourceComment]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*

*/
/*
[LR.ResourceComment] - select LR comments . 
    
*/
CREATE VIEW [dbo].[LR.ResourceComment] AS

SELECT [Id]
      ,[ResourceIntId]
      ,[Comment]
      ,[IsActive]
      ,[Created]
      ,[CreatedById]
      ,[CreatedBy]

  FROM Isle_IOER.[dbo].[Resource.Comment]
  where CreatedById is not null and [IsActive] = 1


GO
/****** Object:  View [dbo].[LR.ResourceLike]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
SELECT [ResourceIntId]
      ,[LikeCount]
      ,[DislikeCount]
  FROM [IsleContent].[dbo].[LR.ResourceLikes]
GO


*/
/*
[LR.ResourceLikes] - select LR likes . 
    
*/
CREATE VIEW [dbo].[LR.ResourceLike] AS

SELECT [Id]
      ,[ResourceIntId]
      ,[IsLike]
      ,[Created]
      ,[CreatedById]
      
  FROM Isle_IOER.[dbo].[Resource.Like]


GO
/****** Object:  View [dbo].[LR.ResourceLikesSummary]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/*

*/
/*
[LR.ResourceLikesSummary] - select LR likes . 
    
*/
CREATE VIEW [dbo].[LR.ResourceLikesSummary] AS

SELECT [ResourceIntId]
      ,[LikeCount]
      ,[DislikeCount]

  FROM Isle_IOER.[dbo].[Resource.LikesSummary]
  where LikeCount> 0 OR DislikeCount > 0


GO
/****** Object:  View [dbo].[LR.ResourceStandard]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*

*/
/*
[LR.ResourceStandard] - select LR standards . 
    
*/
CREATE VIEW [dbo].[LR.ResourceStandard] AS
SELECT [Id]
      ,[ResourceIntId]
      ,[StandardId]
      ,[StandardUrl]
      ,[AlignedById]
      ,[AlignmentTypeCodeId]
      ,[AlignmentDegreeId]
      ,[Created]
      ,[CreatedById]
  FROM Isle_IOER.[dbo].[Resource.Standard]




GO
/****** Object:  View [dbo].[Resource.AccessRights]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create VIEW [dbo].[Resource.AccessRights] AS
SELECT [Id]
      ,[ResourceIntId]
      ,[AccessRightsId]
	  ,Created
  FROM [Isle_IOER].[dbo].[Resource.Version]
  where [AccessRightsId] is not null 
  AND [AccessRightsId]> 0
  --and [ResourceIntId] is null


GO
/****** Object:  View [dbo].[Resource.CareerCluster]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create VIEW [dbo].[Resource.CareerCluster] AS
SELECT [Id]
      ,[ResourceIntId]
      ,[ClusterId] As CareerClusterId
  FROM Isle_IOER.[dbo].[Resource.Cluster]


GO
/****** Object:  View [dbo].[Resource.EducationalUse]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Resource.EducationalUse] AS
SELECT [Id]
      ,[ResourceIntId]
      ,[EducationUseId] As EducationalUseId
  FROM Isle_IOER.[dbo].[Resource.EducationUse]


GO
/****** Object:  View [dbo].[Resource.Format]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Resource.Format] AS
SELECT [RowId]
      ,[ResourceId]
      ,[OriginalValue]
      ,[CodeId]
      ,[Created]
      ,[CreatedById]
      ,[ResourceIntId]
  FROM Isle_IOER.[dbo].[Resource.Format]


GO
/****** Object:  View [dbo].[Resource.GradeLevel]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Resource.GradeLevel] AS
SELECT [Id]
      ,[ResourceIntId]
      ,[GradeLevelId]
      ,[OriginalLevel]
      ,[Created]
      ,[CreatedById]
      ,[PathwaysEducationLevelId]
  FROM Isle_IOER.[dbo].[Resource.GradeLevel]


GO
/****** Object:  View [dbo].[Resource.GroupType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[Resource.GroupType] AS
SELECT [Id]
      ,[ResourceIntId]
      ,[GroupTypeId]
      ,[Created]
      ,[CreatedById]
  FROM Isle_IOER.[dbo].[Resource.GroupType]


GO
/****** Object:  View [dbo].[Resource.IntendedAudience]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[Resource.IntendedAudience] AS
SELECT [RowID]
      ,[AudienceId]
	  ,[AudienceId] As IntendedAudienceId
      ,[CreatedById]
      ,[Created]
      ,[ResourceIntId]
  FROM [Isle_IOER].[dbo].[Resource.IntendedAudience]

GO
/****** Object:  View [dbo].[Resource.ResourceFormat]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create VIEW [dbo].[Resource.ResourceFormat] AS
SELECT [RowId]
      ,[ResourceIntId]
      ,[CodeId] As ResourceFormatId

      
  FROM [Isle_IOER].[dbo].[Resource.Format]

GO
/****** Object:  View [dbo].[Resource.ResourceType]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[Resource.ResourceType] AS
SELECT [RowId]
      ,[ResourceIntId]
      ,[ResourceTypeId]
      ,[Created]
      ,[CreatedById]

  FROM [Isle_IOER].[dbo].[Resource.ResourceType]

GO
/****** Object:  View [dbo].[Resource.Standard]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[Resource.Standard] AS
SELECT [Id]
      ,[ResourceIntId]
      ,[StandardId]
      ,[StandardUrl]
      ,[AlignedById]
      ,[AlignmentTypeCodeId]
      ,[AlignmentDegreeId]
      ,[Created]
      ,[CreatedById]
  FROM Isle_IOER.[dbo].[Resource.Standard]


GO
/****** Object:  View [dbo].[Resource.Version]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[Resource.Version] AS
SELECT 
[Id]
--,[ResourceId]
      --,[DocId]
      ,[Title]
     -- ,[Description]
      ,[Publisher]
      ,[Creator]
      ,[Rights]
      ,[AccessRights]
      ,[Modified]
      ,[Submitter]
      ,[Imported]
      ,[Created]
      ,[TypicalLearningTime]
      ,[IsSkeletonFromParadata]
    --  ,[IsActive]
    --  ,[Requirements]
      ,[SortTitle]
    --  ,[Schema]
      ,[AccessRightsId]
      ,[InteractivityTypeId]
      ,[ResourceIntId]
      
      ,[InteractivityType]
  FROM Isle_IOER.[dbo].[Resource.Version]
  where [IsActive]= 1


GO
/****** Object:  View [dbo].[System.Process]    Script Date: 3/9/2014 10:03:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[System.Process]
AS
SELECT        Id, Code, Title, Description, Created, CreatedBy, LastUpdated, LastUpdatedBy, LastRunDate, StringParameter, IntParameter
FROM            Isle_IOER.dbo.[System.Process]

GO
/****** Object:  Index [IX_ActivityLog_ActionByUserId]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_ActivityLog_ActionByUserId] ON [dbo].[ActivityLog]
(
	[ActionByUserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_ActivityLog_Activities]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_ActivityLog_Activities] ON [dbo].[ActivityLog]
(
	[ActivityType] ASC,
	[Activity] ASC,
	[Event] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_ActivityLog_Created]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_ActivityLog_Created] ON [dbo].[ActivityLog]
(
	[CreatedDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Community.Member]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Community.Member] ON [dbo].[Community.Member]
(
	[CommunityId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Community.Posting]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Community.Posting] ON [dbo].[Community.Posting]
(
	[CommunityId] ASC,
	[Created] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Community.PostingDocument]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Community.PostingDocument] ON [dbo].[Community.PostingDocument]
(
	[PostingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.Comment]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Library.Comment] ON [dbo].[Library.Comment]
(
	[LibraryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.Invitation_RowId]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Library.Invitation_RowId] ON [dbo].[Library.Invitation]
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.Like]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Library.Like] ON [dbo].[Library.Like]
(
	[LibraryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.Like_LibIdUserId]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Library.Like_LibIdUserId] ON [dbo].[Library.Like]
(
	[LibraryId] ASC,
	[CreatedById] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.Party_ParentIdx]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Library.Party_ParentIdx] ON [dbo].[Library.Party]
(
	[ParentRowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.PartyRelatedIdx]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Library.PartyRelatedIdx] ON [dbo].[Library.Party]
(
	[RelatedRowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.Resource]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Library.Resource] ON [dbo].[Library.Resource]
(
	[LibrarySectionId] ASC,
	[ResourceIntId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.Resource_1]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Library.Resource_1] ON [dbo].[Library.Resource]
(
	[ResourceIntId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library_Section_RowId]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Library_Section_RowId] ON [dbo].[Library.Section]
(
	[RowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Library.SectionLike_UnqSIdUsId]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Library.SectionLike_UnqSIdUsId] ON [dbo].[Library.SectionLike]
(
	[SectionId] ASC,
	[CreatedById] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Person.Following_ByUserId]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Person.Following_ByUserId] ON [dbo].[Person.Following]
(
	[FollowedByUserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Person.Following_FollowingUserId]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE NONCLUSTERED INDEX [IX_Person.Following_FollowingUserId] ON [dbo].[Person.Following]
(
	[FollowingUserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Person.Following_Unq_FUId_FByUId]    Script Date: 3/9/2014 10:03:03 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_Person.Following_Unq_FUId_FByUId] ON [dbo].[Person.Following]
(
	[FollowingUserId] ASC,
	[FollowedByUserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ActivityLog] ADD  CONSTRAINT [DF_ActivityLog_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [dbo].[ActivityLog] ADD  CONSTRAINT [DF_ActivityLog_Type]  DEFAULT ('audit') FOR [ActivityType]
GO
ALTER TABLE [dbo].[Codes.ContentPrivilege] ADD  CONSTRAINT [DF_Codes.ContentPrivilege_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Codes.ContentPrivilege] ADD  CONSTRAINT [DF_Codes.ContentPrivilege_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Codes.ContentStatus] ADD  CONSTRAINT [DF_Codes.ContentStatus_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Codes.LibraryAccessLevel] ADD  CONSTRAINT [DF_Codes.LibraryAccessLevel_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Codes.LibraryAccessLevel] ADD  CONSTRAINT [DF_Codes.LibraryAccessLevel_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Codes.LibraryMemberType] ADD  CONSTRAINT [DF_Codes.LibraryMemberType_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Codes.SubscriptionType] ADD  CONSTRAINT [DF_Codes.SubscriptionType_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Community] ADD  CONSTRAINT [DF_Community_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Community.Member] ADD  CONSTRAINT [DF_Community.Member_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Community.Posting] ADD  CONSTRAINT [DF_Community.Posting_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Community.PostingDocument] ADD  CONSTRAINT [DF_Community.PostingDocument_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Content] ADD  CONSTRAINT [DF_Content_TypeId]  DEFAULT ((10)) FOR [TypeId]
GO
ALTER TABLE [dbo].[Content] ADD  CONSTRAINT [DF_Table_1_StatusId]  DEFAULT ((1)) FOR [StatusId]
GO
ALTER TABLE [dbo].[Content] ADD  CONSTRAINT [DF_Table_1_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Content] ADD  CONSTRAINT [DF_Content_IsPublished]  DEFAULT ((0)) FOR [IsPublished]
GO
ALTER TABLE [dbo].[Content] ADD  CONSTRAINT [DF_Table_1_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Content] ADD  CONSTRAINT [DF_Table_1_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Content] ADD  CONSTRAINT [DF_Table_1_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Content.History] ADD  CONSTRAINT [DF_Content.History_Content.History]  DEFAULT ('Project Action') FOR [Action]
GO
ALTER TABLE [dbo].[Content.History] ADD  CONSTRAINT [DF_Content.History_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Content.Reference] ADD  CONSTRAINT [DF_Content.Reference_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Content.Reference] ADD  CONSTRAINT [DF_Content.Reference_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Content.Supplement] ADD  CONSTRAINT [DF_Content.Supplement_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Content.Supplement] ADD  CONSTRAINT [DF_Content.Supplement_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Content.Supplement] ADD  CONSTRAINT [DF_Content.Supplement_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Content.Supplement] ADD  CONSTRAINT [DF_Content.Supplement_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[ContentFile] ADD  CONSTRAINT [DF_ContentFile_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ContentFile] ADD  CONSTRAINT [DF_ContentFile_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[ContentFile] ADD  CONSTRAINT [DF_ContentFile_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[ContentTemplate] ADD  CONSTRAINT [DF_ContentTemplate_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[ContentType] ADD  CONSTRAINT [DF_Content.Type_HasApproval]  DEFAULT ((0)) FOR [HasApproval]
GO
ALTER TABLE [dbo].[ContentType] ADD  CONSTRAINT [DF_Content.Type_MaxVersions]  DEFAULT ((1)) FOR [MaxVersions]
GO
ALTER TABLE [dbo].[ContentType] ADD  CONSTRAINT [DF_Content.Type_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ContentType] ADD  CONSTRAINT [DF_Content.Type_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[ContentType] ADD  CONSTRAINT [DF_Content.Type_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Document.Version] ADD  CONSTRAINT [DF_Document.Version_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Document.Version] ADD  CONSTRAINT [DF_Document.Version_Status]  DEFAULT ('Pending') FOR [Status]
GO
ALTER TABLE [dbo].[Document.Version] ADD  CONSTRAINT [DF_Document.Version_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Document.Version] ADD  CONSTRAINT [DF_Document.Version_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Library] ADD  CONSTRAINT [DF_Library_PublicAccessLevel]  DEFAULT ((1)) FOR [PublicAccessLevel]
GO
ALTER TABLE [dbo].[Library] ADD  CONSTRAINT [DF_Library_OrgAccessLevel]  DEFAULT ((2)) FOR [OrgAccessLevel]
GO
ALTER TABLE [dbo].[Library] ADD  CONSTRAINT [DF_Library_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Library] ADD  CONSTRAINT [DF_Library_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library] ADD  CONSTRAINT [DF_Library_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Library] ADD  CONSTRAINT [DF_Library_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Library.Comment] ADD  CONSTRAINT [DF_Library.Comment_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.ExternalSection] ADD  CONSTRAINT [DF_Library.ExternalSection_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.ExternalSection] ADD  CONSTRAINT [DF_Library.ExternalSection_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Library.Invitation] ADD  CONSTRAINT [DF_Library.Invitation_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Library.Invitation] ADD  CONSTRAINT [DF_Library.Invitation_Type]  DEFAULT ('Individual') FOR [InvitationType]
GO
ALTER TABLE [dbo].[Library.Invitation] ADD  CONSTRAINT [DF_Library.Invitation_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Library.Invitation] ADD  CONSTRAINT [DF_Library.Invitation_DeleteOnResponse]  DEFAULT ((0)) FOR [DeleteOnResponse]
GO
ALTER TABLE [dbo].[Library.Invitation] ADD  CONSTRAINT [DF_Table_1_DateSent]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.Invitation] ADD  CONSTRAINT [DF_Library.Invitation_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Library.Like] ADD  CONSTRAINT [DF_Library.Like_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.Member] ADD  CONSTRAINT [DF_Library.Member_MemberTypeId]  DEFAULT ((0)) FOR [MemberTypeId]
GO
ALTER TABLE [dbo].[Library.Member] ADD  CONSTRAINT [DF_Library.Member_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Library.Member] ADD  CONSTRAINT [DF_Library.Member_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.Member] ADD  CONSTRAINT [DF_Library.Member_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Library.Party] ADD  CONSTRAINT [DF_Library.Party_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.PartyComment] ADD  CONSTRAINT [DF_Library.PartyComment_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Library.PartyComment] ADD  CONSTRAINT [DF_Library.PartyComment_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.Resource] ADD  CONSTRAINT [DF_Library.Resource_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Library.Resource] ADD  CONSTRAINT [DF_Library.Resource_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_SectionTypeId]  DEFAULT ((3)) FOR [SectionTypeId]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_IsDefaultSection]  DEFAULT ((0)) FOR [IsDefaultSection]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_PublicAccessLevel]  DEFAULT ((1)) FOR [PublicAccessLevel]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_OrgAccessLevel]  DEFAULT ((2)) FOR [OrgAccessLevel]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_AreContentsReadOnly]  DEFAULT ((0)) FOR [AreContentsReadOnly]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Library.Section] ADD  CONSTRAINT [DF_Library.Section_IsPublic]  DEFAULT ((1)) FOR [IsPublic]
GO
ALTER TABLE [dbo].[Library.SectionComment] ADD  CONSTRAINT [DF_Library.SectionComment_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.SectionLike] ADD  CONSTRAINT [DF_Library.SectionLike_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.SectionMember] ADD  CONSTRAINT [DF_Library.SectionMember_MemberTypeId]  DEFAULT ((0)) FOR [MemberTypeId]
GO
ALTER TABLE [dbo].[Library.SectionMember] ADD  CONSTRAINT [DF_Library.SectionMember_RowId]  DEFAULT (newid()) FOR [RowId]
GO
ALTER TABLE [dbo].[Library.SectionMember] ADD  CONSTRAINT [DF_Library.SectionMember_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.SectionMember] ADD  CONSTRAINT [DF_Library.SectionMember_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Library.SectionSubscription] ADD  CONSTRAINT [DF_Library.SectionSubscription_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.SectionSubscription] ADD  CONSTRAINT [DF_Library.SectionSubscription_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Library.SectionType] ADD  CONSTRAINT [DF_Library.SectionType_IsReadOnly]  DEFAULT ((0)) FOR [AreContentsReadOnly]
GO
ALTER TABLE [dbo].[Library.SectionType] ADD  CONSTRAINT [DF_Library.SectionType_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.Subscription] ADD  CONSTRAINT [DF_Library.Subscription_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Library.Subscription] ADD  CONSTRAINT [DF_Library.Subscription_LastUpdated]  DEFAULT (getdate()) FOR [LastUpdated]
GO
ALTER TABLE [dbo].[Library.Type] ADD  CONSTRAINT [DF_Library.Type_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Person.Following] ADD  CONSTRAINT [DF_Person.Following_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[Community.Member]  WITH CHECK ADD  CONSTRAINT [FK_Community.Member_Community] FOREIGN KEY([CommunityId])
REFERENCES [dbo].[Community] ([Id])
GO
ALTER TABLE [dbo].[Community.Member] CHECK CONSTRAINT [FK_Community.Member_Community]
GO
ALTER TABLE [dbo].[Community.Posting]  WITH CHECK ADD  CONSTRAINT [FK_Community.Posting_Community] FOREIGN KEY([CommunityId])
REFERENCES [dbo].[Community] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Community.Posting] CHECK CONSTRAINT [FK_Community.Posting_Community]
GO
ALTER TABLE [dbo].[Community.Posting]  WITH CHECK ADD  CONSTRAINT [FK_Community.Posting_Community.Posting] FOREIGN KEY([RelatedPostingId])
REFERENCES [dbo].[Community.Posting] ([Id])
GO
ALTER TABLE [dbo].[Community.Posting] CHECK CONSTRAINT [FK_Community.Posting_Community.Posting]
GO
ALTER TABLE [dbo].[Community.PostingDocument]  WITH CHECK ADD  CONSTRAINT [FK_Community.PostingDocument_Community.Posting] FOREIGN KEY([PostingId])
REFERENCES [dbo].[Community.Posting] ([Id])
GO
ALTER TABLE [dbo].[Community.PostingDocument] CHECK CONSTRAINT [FK_Community.PostingDocument_Community.Posting]
GO
ALTER TABLE [dbo].[Community.PostingDocument]  WITH CHECK ADD  CONSTRAINT [FK_Community.PostingDocument_Document.Version] FOREIGN KEY([DocumentId])
REFERENCES [dbo].[Document.Version] ([RowId])
GO
ALTER TABLE [dbo].[Community.PostingDocument] CHECK CONSTRAINT [FK_Community.PostingDocument_Document.Version]
GO
ALTER TABLE [dbo].[Content]  WITH CHECK ADD  CONSTRAINT [FK_Content_Codes.ContentPrivilege] FOREIGN KEY([PrivilegeTypeId])
REFERENCES [dbo].[Codes.ContentPrivilege] ([Id])
GO
ALTER TABLE [dbo].[Content] CHECK CONSTRAINT [FK_Content_Codes.ContentPrivilege]
GO
ALTER TABLE [dbo].[Content]  WITH CHECK ADD  CONSTRAINT [FK_Content_Codes.ContentStatus] FOREIGN KEY([StatusId])
REFERENCES [dbo].[Codes.ContentStatus] ([Id])
GO
ALTER TABLE [dbo].[Content] CHECK CONSTRAINT [FK_Content_Codes.ContentStatus]
GO
ALTER TABLE [dbo].[Content]  WITH CHECK ADD  CONSTRAINT [FK_Content_ContentType] FOREIGN KEY([TypeId])
REFERENCES [dbo].[ContentType] ([Id])
GO
ALTER TABLE [dbo].[Content] CHECK CONSTRAINT [FK_Content_ContentType]
GO
ALTER TABLE [dbo].[Content.History]  WITH CHECK ADD  CONSTRAINT [FK_Content.History_Content] FOREIGN KEY([ContentId])
REFERENCES [dbo].[Content] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Content.History] CHECK CONSTRAINT [FK_Content.History_Content]
GO
ALTER TABLE [dbo].[Content.Reference]  WITH CHECK ADD  CONSTRAINT [FK_Content.Reference_Content] FOREIGN KEY([ParentId])
REFERENCES [dbo].[Content] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Content.Reference] CHECK CONSTRAINT [FK_Content.Reference_Content]
GO
ALTER TABLE [dbo].[Content.Supplement]  WITH CHECK ADD  CONSTRAINT [FK_Content.Supplement_Codes.ContentPrivilege] FOREIGN KEY([PrivilegeTypeId])
REFERENCES [dbo].[Codes.ContentPrivilege] ([Id])
GO
ALTER TABLE [dbo].[Content.Supplement] CHECK CONSTRAINT [FK_Content.Supplement_Codes.ContentPrivilege]
GO
ALTER TABLE [dbo].[Content.Supplement]  WITH CHECK ADD  CONSTRAINT [FK_Content.Supplement_Content] FOREIGN KEY([ParentId])
REFERENCES [dbo].[Content] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Content.Supplement] CHECK CONSTRAINT [FK_Content.Supplement_Content]
GO
ALTER TABLE [dbo].[Library]  WITH CHECK ADD  CONSTRAINT [FK_Library_Codes.OrgAccessLevel] FOREIGN KEY([OrgAccessLevel])
REFERENCES [dbo].[Codes.LibraryAccessLevel] ([Id])
GO
ALTER TABLE [dbo].[Library] CHECK CONSTRAINT [FK_Library_Codes.OrgAccessLevel]
GO
ALTER TABLE [dbo].[Library]  WITH CHECK ADD  CONSTRAINT [FK_Library_Codes.PublicAccessLevel] FOREIGN KEY([PublicAccessLevel])
REFERENCES [dbo].[Codes.LibraryAccessLevel] ([Id])
GO
ALTER TABLE [dbo].[Library] CHECK CONSTRAINT [FK_Library_Codes.PublicAccessLevel]
GO
ALTER TABLE [dbo].[Library]  WITH CHECK ADD  CONSTRAINT [FK_Library_Library.Type] FOREIGN KEY([LibraryTypeId])
REFERENCES [dbo].[Library.Type] ([Id])
GO
ALTER TABLE [dbo].[Library] CHECK CONSTRAINT [FK_Library_Library.Type]
GO
ALTER TABLE [dbo].[Library.Comment]  WITH CHECK ADD  CONSTRAINT [FK_Library.Comment_Library] FOREIGN KEY([LibraryId])
REFERENCES [dbo].[Library] ([Id])
GO
ALTER TABLE [dbo].[Library.Comment] CHECK CONSTRAINT [FK_Library.Comment_Library]
GO
ALTER TABLE [dbo].[Library.ExternalSection]  WITH CHECK ADD  CONSTRAINT [FK_Library.ExternalSection_Library] FOREIGN KEY([LibraryId])
REFERENCES [dbo].[Library] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Library.ExternalSection] CHECK CONSTRAINT [FK_Library.ExternalSection_Library]
GO
ALTER TABLE [dbo].[Library.ExternalSection]  WITH CHECK ADD  CONSTRAINT [FK_Table_1_Library.Section_ExtSectionId] FOREIGN KEY([ExternalSectionId])
REFERENCES [dbo].[Library.Section] ([Id])
GO
ALTER TABLE [dbo].[Library.ExternalSection] CHECK CONSTRAINT [FK_Table_1_Library.Section_ExtSectionId]
GO
ALTER TABLE [dbo].[Library.Invitation]  WITH CHECK ADD  CONSTRAINT [FK_Library.Invitation_Library] FOREIGN KEY([LibraryId])
REFERENCES [dbo].[Library] ([Id])
GO
ALTER TABLE [dbo].[Library.Invitation] CHECK CONSTRAINT [FK_Library.Invitation_Library]
GO
ALTER TABLE [dbo].[Library.Like]  WITH CHECK ADD  CONSTRAINT [FK_Library.Like_Library] FOREIGN KEY([LibraryId])
REFERENCES [dbo].[Library] ([Id])
GO
ALTER TABLE [dbo].[Library.Like] CHECK CONSTRAINT [FK_Library.Like_Library]
GO
ALTER TABLE [dbo].[Library.Member]  WITH CHECK ADD  CONSTRAINT [FK_Library.Member_Codes.LibraryMemberType] FOREIGN KEY([MemberTypeId])
REFERENCES [dbo].[Codes.LibraryMemberType] ([Id])
GO
ALTER TABLE [dbo].[Library.Member] CHECK CONSTRAINT [FK_Library.Member_Codes.LibraryMemberType]
GO
ALTER TABLE [dbo].[Library.Member]  WITH CHECK ADD  CONSTRAINT [FK_Library.Member_Library] FOREIGN KEY([LibraryId])
REFERENCES [dbo].[Library] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Library.Member] CHECK CONSTRAINT [FK_Library.Member_Library]
GO
ALTER TABLE [dbo].[Library.Resource]  WITH CHECK ADD  CONSTRAINT [FK_Library.Resource_Library.Section] FOREIGN KEY([LibrarySectionId])
REFERENCES [dbo].[Library.Section] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Library.Resource] CHECK CONSTRAINT [FK_Library.Resource_Library.Section]
GO
ALTER TABLE [dbo].[Library.Section]  WITH CHECK ADD  CONSTRAINT [FK_Library.Section_Library] FOREIGN KEY([LibraryId])
REFERENCES [dbo].[Library] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Library.Section] CHECK CONSTRAINT [FK_Library.Section_Library]
GO
ALTER TABLE [dbo].[Library.Section]  WITH CHECK ADD  CONSTRAINT [FK_Library.Section_Library.SectionType] FOREIGN KEY([SectionTypeId])
REFERENCES [dbo].[Library.SectionType] ([Id])
GO
ALTER TABLE [dbo].[Library.Section] CHECK CONSTRAINT [FK_Library.Section_Library.SectionType]
GO
ALTER TABLE [dbo].[Library.SectionComment]  WITH CHECK ADD  CONSTRAINT [FK_Library.SectionComment_LibrarySection] FOREIGN KEY([SectionId])
REFERENCES [dbo].[Library.Section] ([Id])
GO
ALTER TABLE [dbo].[Library.SectionComment] CHECK CONSTRAINT [FK_Library.SectionComment_LibrarySection]
GO
ALTER TABLE [dbo].[Library.SectionLike]  WITH CHECK ADD  CONSTRAINT [FK_Library.SectionLike_LibrarySection] FOREIGN KEY([SectionId])
REFERENCES [dbo].[Library.Section] ([Id])
GO
ALTER TABLE [dbo].[Library.SectionLike] CHECK CONSTRAINT [FK_Library.SectionLike_LibrarySection]
GO
ALTER TABLE [dbo].[Library.SectionMember]  WITH CHECK ADD  CONSTRAINT [FK_Library.SectionMember_Codes.LibraryMemberType] FOREIGN KEY([MemberTypeId])
REFERENCES [dbo].[Codes.LibraryMemberType] ([Id])
GO
ALTER TABLE [dbo].[Library.SectionMember] CHECK CONSTRAINT [FK_Library.SectionMember_Codes.LibraryMemberType]
GO
ALTER TABLE [dbo].[Library.SectionMember]  WITH CHECK ADD  CONSTRAINT [FK_Library.SectionMember_Library.Section] FOREIGN KEY([LibrarySectionId])
REFERENCES [dbo].[Library.Section] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Library.SectionMember] CHECK CONSTRAINT [FK_Library.SectionMember_Library.Section]
GO
ALTER TABLE [dbo].[Library.SectionSubscription]  WITH CHECK ADD  CONSTRAINT [FK_Library.SectionSubscription_Codes.SubscriptionType] FOREIGN KEY([SubscriptionTypeId])
REFERENCES [dbo].[Codes.SubscriptionType] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Library.SectionSubscription] CHECK CONSTRAINT [FK_Library.SectionSubscription_Codes.SubscriptionType]
GO
ALTER TABLE [dbo].[Library.SectionSubscription]  WITH CHECK ADD  CONSTRAINT [FK_Library.SectionSubscription_Library.Section] FOREIGN KEY([SectionId])
REFERENCES [dbo].[Library.Section] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Library.SectionSubscription] CHECK CONSTRAINT [FK_Library.SectionSubscription_Library.Section]
GO
ALTER TABLE [dbo].[Library.Subscription]  WITH CHECK ADD  CONSTRAINT [FK_Library.Subscription_Codes.SubscriptionType] FOREIGN KEY([SubscriptionTypeId])
REFERENCES [dbo].[Codes.SubscriptionType] ([Id])
GO
ALTER TABLE [dbo].[Library.Subscription] CHECK CONSTRAINT [FK_Library.Subscription_Codes.SubscriptionType]
GO
ALTER TABLE [dbo].[Library.Subscription]  WITH CHECK ADD  CONSTRAINT [FK_Library.Subscription_Library] FOREIGN KEY([LibraryId])
REFERENCES [dbo].[Library] ([Id])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Library.Subscription] CHECK CONSTRAINT [FK_Library.Subscription_Library]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'FK to AppItemType table' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Content', @level2type=N'COLUMN',@level2name=N'TypeId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Track last user to update an org' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Content', @level2type=N'COLUMN',@level2name=N'LastUpdatedById'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Track last user to update an org' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Content', @level2type=N'COLUMN',@level2name=N'Approved'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Track last user to update an org' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Content', @level2type=N'COLUMN',@level2name=N'ApprovedById'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'FK to AppItemType table' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Content.Reference', @level2type=N'COLUMN',@level2name=N'ParentId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Track last user to update an org' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Content.Reference', @level2type=N'COLUMN',@level2name=N'LastUpdatedById'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'FK to AppItemType table' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Content.Supplement', @level2type=N'COLUMN',@level2name=N'ParentId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Track last user to update an org' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Content.Supplement', @level2type=N'COLUMN',@level2name=N'LastUpdatedById'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'PK, but set by creator' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ContentType', @level2type=N'COLUMN',@level2name=N'Id'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'do we need to distinguish between upload date and actual last mod date of the file?' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Document.Version', @level2type=N'COLUMN',@level2name=N'FileDate'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Individual or Library' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Library.Invitation', @level2type=N'COLUMN',@level2name=N'InvitationType'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[40] 2[1] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Content"
            Begin Extent = 
               Top = 2
               Left = 16
               Bottom = 187
               Right = 238
            End
            DisplayFlags = 280
            TopColumn = 7
         End
         Begin Table = "Codes.ContentStatus"
            Begin Extent = 
               Top = 18
               Left = 314
               Bottom = 144
               Right = 474
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ContentType"
            Begin Extent = 
               Top = 22
               Left = 529
               Bottom = 173
               Right = 747
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Codes.ContentPrivilege"
            Begin Extent = 
               Top = 114
               Left = 297
               Bottom = 233
               Right = 504
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 1500
         Table = 2430
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
 ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ContentSummaryView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'        Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ContentSummaryView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ContentSummaryView'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "EmailNotice (Isle_IOER.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'EmailNotice'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'EmailNotice'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "ltbl"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 110
               Right = 198
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LibraryCollection.ResourceCount'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'LibraryCollection.ResourceCount'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "System.Process (Isle_IOER.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 212
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'System.Process'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'System.Process'
GO

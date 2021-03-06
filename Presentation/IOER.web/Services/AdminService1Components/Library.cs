﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

using ILPathways.Business;
using LRWarehouse.Business;
using IOER.Services;
using Isle.BizServices;

namespace IOER.Services.AdminService1Components
{
  public class Library : IManageObject
  {
    LibraryBizService service = new LibraryBizService();

    //Get methods
    public List<Privilege> ListPrivileges()
    {
      var data = LibraryBizService.GetCodes_LibraryMemberType();
      var results = new List<Privilege>();
      foreach ( var item in data )
      {
        results.Add( new Privilege()
        {
          id = item.Id,
          text = item.Title
        } );
      }
      return results;
    }
    public List<UserDTO> ListAllMembers( int manageID )
    {
      var data = service.LibraryMembers_GetAll( manageID );
      return GetUserDTOs( data );
    }
    public List<UserDTO> ListMembers( int manageID, int privilegeID )
    {
      var data = service.LibraryMembers_GetAll( manageID, privilegeID );
      return GetUserDTOs( data );
    }
    private List<UserDTO> GetUserDTOs( List<LibraryMember> data )
    {
      var results = new List<UserDTO>();
      foreach ( var item in data )
      {
        results.Add( new UserDTO()
        {
          id = item.UserId,
          name = item.MemberName,
          privileges = item.MemberType,
          privilegesID = item.MemberTypeId,
          date = item.Created.ToShortDateString(),
          imageURL = item.MemberImageUrl
        } );
      }
      return results;
    }
    public List<UserDTO> ListPendingInvitations( int manageID )
    {
      var data = service.LibraryMembers_ListPending( manageID );
      return GetUserDTOs( data );
    }

    //Set methods
    public Valid Member_UpdateMembership( int manageID, Patron user, int memberID, int privilegeID )
    {
      //Do update
      var result = GetUpdatedMembership( manageID, memberID, privilegeID, user.Id );

      //Update status
      var code = LibraryBizService.GetCodes_LibraryMemberType().Where( m => m.Id == privilegeID ).FirstOrDefault().Title;
      result.extra = new { title = code, error = "" };
      result.text = "Successfully updated privileges.";

      return result;
    }
    public Valid Member_ApproveMembership( int manageID, Patron user, int memberID, int privilegeID, string customMessage )
    {
      //Do update
      var result = GetUpdatedMembership( manageID, memberID, privilegeID, user.Id );

      //Update status
      result.text = "Membership approved. Click \"Membership Requests\" to refresh.";

      return result;
    }
    private Valid GetUpdatedMembership( int manageID, int memberID, int privilegeID, int userID )
    {
      var result = new Valid() { id = memberID };

      if ( service.LibraryMember_Update( manageID, memberID, privilegeID, userID ) )
      {
        result.valid = true;
      }
      else
      {
        throw new InvalidOperationException( "There was an error performing this action." );
      }
      return result;
    }
    public Valid Member_RevokeMembership( int manageID, Patron user, int memberID )
    {
      var result = new Valid() { id = memberID };

      //Get the membership record
      var member = service.LibraryMember_Get( manageID, memberID );

      //Do the removal
      if ( service.LibraryMember_Delete( member.Id ) )
      {
        result.valid = true;
        result.text = "Member deleted. Click \"Current Members\" to refresh.";
        result.extra = new { error = "" };
      }
      else
      {
        throw new InvalidOperationException( "There was an error removing this member" );
      }

      return result;
    }
    public Valid Member_DenyMembership( int manageID, Patron user, int memberID, string customMessage )
    {
      var status = "";
      var success = service.LibraryMember_DenyPending( manageID, user.Id, memberID, customMessage, ref status );
      var result = new Valid()
      {
        id = memberID,
        valid = success,
        extra = status
      };

      result.text = success ? "Membership denied." : "There was an error denying this membership.";

      return result;
    }
    public Valid Member_InviteExistingUser( int manageID, Patron user, Patron invitee, int privilegeID, string customMessage )
    {
      var status = "";
      var success = service.InviteExistingUser( manageID, user.Id, invitee.Id, privilegeID, customMessage, ref status );
      var result = new Valid()
      {
        id = invitee.Id,
        valid = success,
        extra = status
      };

      result.text = success ? "Member invited." : "There was an error inviting this member.";

      return result;
    }
    public Valid Member_InviteNewUser( int manageID, Patron user, string validatedEmail, int privilegeID, string customMessage )
    {
      var status = "";
      var success = service.InviteNewUser( manageID, user.Id, validatedEmail, privilegeID, customMessage, ref status );
      var result = new Valid()
      {
        valid = success,
        extra = status
      };

      result.text = success ? "Member invited." : "There was an error inviting this member.";

      return result;
    }

  }
}
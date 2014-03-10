﻿using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Web;
using System.Web.Security;
using System.Web.SessionState;
using Microsoft.ApplicationBlocks.Data;
using Entity = LRWarehouse.Business.ResourceSubject;
using MapEntity = LRWarehouse.Business.ResourceChildItem;
using MyEntity = LRWarehouse.Business.ResourceChildItem;
using EntityCollection = LRWarehouse.Business.ResourceSubjectCollection;


namespace LRWarehouse.DAL
{
    public class ResourceSubjectManager : BaseDataManager
    {
        const string className = "ResourceSubjectManager";
        #region Subject only Methods

        public string CreateFromEntity( MapEntity entity, ref string statusMessage )
        {
            Entity oldEntity = new Entity();
            oldEntity.ResourceId = entity.ResourceId;
            oldEntity.ResourceIntId = entity.ResourceIntId;
            oldEntity.Subject = entity.OriginalValue;
            return Create( oldEntity );
        }

        public string Import( Entity entity )
        {
            string statusMessage = "";

            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 2 ];
                sqlParameter[ 0 ] = new SqlParameter( "@ResourceIntId", entity.ResourceIntId );
                sqlParameter[ 1 ] = new SqlParameter( "@Subject", entity.Subject );

                SqlHelper.ExecuteNonQuery( ConnString, CommandType.StoredProcedure, "[Resource.SubjectImport]", sqlParameter );
                statusMessage = "successful";
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.Import(): " + ex.ToString() );
                statusMessage = ex.Message;
            }
            return statusMessage;
        }

        public string Create( Entity entity )
        {
            string statusMessage = "";

            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 3 ];
                sqlParameter[ 0 ] = new SqlParameter( "@ResourceIntId", entity.ResourceIntId );
                sqlParameter[ 1 ] = new SqlParameter( "@Subject", entity.Subject );
                sqlParameter[ 2 ] = new SqlParameter( "@CreatedById", entity.CreatedById );

                SqlHelper.ExecuteNonQuery( ConnString, CommandType.StoredProcedure, "[Resource.SubjectInsert2]", sqlParameter );
                statusMessage = "successful";
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.Create(): " + ex.ToString() );
                statusMessage = ex.Message;
            }
            return statusMessage;
        }

        public void Create( MapEntity entity, ref string status )
        {
            status = Create( entity );
        }

        public string Create( MapEntity entity )
        {
            string statusMessage = "";

            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 3 ];
                sqlParameter[ 0 ] = new SqlParameter( "@ResourceIntId", entity.ResourceIntId );
                sqlParameter[ 1 ] = new SqlParameter( "@Subject", entity.OriginalValue );
                sqlParameter[ 2 ] = new SqlParameter( "@CreatedById", entity.CreatedById );

                SqlHelper.ExecuteNonQuery( ConnString, CommandType.StoredProcedure, "[Resource.SubjectInsert2]", sqlParameter );
                statusMessage = "successful";
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.Create(): " + ex.ToString() );
                statusMessage = ex.Message;
            }
            return statusMessage;
        }

        /// <summary>
        /// not clear this is being used, or why there would be an update at this time. 
        /// </summary>
        /// <param name="entity"></param>
        /// <returns></returns>
        private string Update( Entity entity )
        {
            string statusMessage = "successful";
            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 2 ];
                sqlParameter[ 0 ] = new SqlParameter( "@ResourceId", entity.ResourceId );
                sqlParameter[ 1 ] = new SqlParameter( "@Subject", entity.SubjectCsv );

                SqlHelper.ExecuteNonQuery( ConnString, CommandType.StoredProcedure, "[Resource.SubjectUpdate]", sqlParameter );
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.Update(): " + ex.ToString() );
                statusMessage = ex.Message;
            }

            return statusMessage;
        }
        /// <summary>
        /// OBSOLETE
        /// </summary>
        /// <param name="resourceId"></param>
        /// <param name="status"></param>
        /// <returns></returns>
        private EntityCollection Get( string resourceId, ref string status )
        {
            status = "successful";
            EntityCollection subject = new EntityCollection();
            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 1 ];
                sqlParameter[ 0 ] = new SqlParameter( "@ResourceId", resourceId );

                DataSet ds = SqlHelper.ExecuteDataset( ConnString, CommandType.StoredProcedure, "[Resource.SubjectGet]", sqlParameter );
                if ( DoesDataSetHaveRows( ds ) )
                {
                    foreach ( DataRow dr in ds.Tables[ 0 ].Rows )
                    {
                        Entity entity = FillEntity( dr );
                        subject.Add( entity );
                    }
                }
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.Get(): " + ex.ToString() );
                status = ex.Message;
            }

            return subject;
        }

        public EntityCollection Get( int resourceIntId, ref string status )
        {
            status = "successful";
            EntityCollection subject = new EntityCollection();
            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 1 ];
                sqlParameter[ 0 ] = new SqlParameter( "@resourceIntId", resourceIntId );

                DataSet ds = SqlHelper.ExecuteDataset( ConnString, CommandType.StoredProcedure, "[Resource.SubjectGet]", sqlParameter );
                if ( DoesDataSetHaveRows( ds ) )
                {
                    foreach ( DataRow dr in ds.Tables[ 0 ].Rows )
                    {
                        Entity entity = FillEntity( dr );
                        subject.Add( entity );
                    }
                }
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.Get(): " + ex.ToString() );
                status = ex.Message;
            }

            return subject;
        }

        public Entity FillEntity( DataRow dr )
        {
            Entity entity = new Entity();
            entity.ResourceIntId = GetRowColumn( dr, "ResourceIntId", 0 );
            entity.Subject = GetRowColumn( dr, "Subject", "" );
            entity.CreatedById = GetRowColumn( dr, "CreatedById", 0 );
            entity.Created = GetRowColumn( dr, "Created", entity.DefaultDate );

            return entity;
        }
        public List<MyEntity> Select( int pResourceIntId )
        {
            List<MyEntity> collection = new List<MyEntity>();

            SqlParameter[] sqlParameters = new SqlParameter[ 1 ];
            sqlParameters[ 0 ] = new SqlParameter( "@ResourceIntId", pResourceIntId );

            DataSet ds = new DataSet();
            try
            {
                ds = SqlHelper.ExecuteDataset( ReadOnlyConnString, CommandType.StoredProcedure, "[Resource.SubjectSelect]", sqlParameters );

                if ( DoesDataSetHaveRows( ds ) )
                {
                    foreach ( DataRow dr in ds.Tables[ 0 ].Rows )
                    {
                        MyEntity entity = Fill( dr );
                        collection.Add( entity );
                    }
                }
                return collection;
            }
            catch ( Exception ex )
            {
                LogError( ex, className + ".Select( int pResourceIntId ) " );
                return null;

            }
        }
        public MyEntity Fill( DataRow dr )
        {
            MyEntity entity = new MyEntity();
            entity.Id = GetRowColumn( dr, "Id", 0 );
            entity.ResourceIntId = GetRowColumn( dr, "ResourceIntId", 0 );
            entity.OriginalValue = GetRowColumn( dr, "Subject", "" );
            entity.CreatedById = GetRowColumn( dr, "CreatedById", 0 );
            entity.Created = GetRowColumn( dr, "Created", entity.DefaultDate );

            return entity;
        }
        #endregion


        #region Subject CSV Methods
        public string CreateCsv( Entity entity )
        {
            string statusMessage = "";

            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 3 ];
                sqlParameter[ 0 ] = new SqlParameter( "@ResourceId", entity.ResourceId.ToString() );
                sqlParameter[ 1 ] = new SqlParameter( "@SubjectCsv", SqlDbType.VarChar );
                sqlParameter[ 1 ].Size = -1;
                sqlParameter[ 1 ].Value = entity.SubjectCsv;

                SqlHelper.ExecuteNonQuery( ConnString, CommandType.StoredProcedure, "[Resource.SubjectCsvInsert]", sqlParameter );
                statusMessage = "successful";
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.Create(): " + ex.ToString() );
                statusMessage = ex.Message;
            }
            return statusMessage;
        }
        public string UpdateCsv( Entity entity )
        {
            string statusMessage = "successful";
            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 2 ];
                sqlParameter[ 0 ] = new SqlParameter( "@ResourceId", entity.ResourceId );
                sqlParameter[ 1 ] = new SqlParameter( "@SubjectCsv", entity.SubjectCsv );

                SqlHelper.ExecuteNonQuery( ConnString, CommandType.StoredProcedure, "[Resource.SubjectCsvUpdate]", sqlParameter );
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.Update(): " + ex.ToString() );
                statusMessage = ex.Message;
            }

            return statusMessage;
        }


        public Entity GetCsv( string resourceId )
        {
            try
            {
                SqlParameter[] sqlParameter = new SqlParameter[ 1 ];
                sqlParameter[ 0 ] = new SqlParameter( "@ResourceId", resourceId );

                DataSet ds = SqlHelper.ExecuteDataset( ConnString, CommandType.StoredProcedure, "[Resource.SubjectCsvGet]", sqlParameter );
                if ( DoesDataSetHaveRows( ds ) )
                {
                    Entity entity = FillEntity( ds.Tables[ 0 ].Rows[ 0 ] );
                    return entity;
                }
                else
                {
                    return null;
                }
            }
            catch ( Exception ex )
            {
                LogError( "ResourceSubjectManager.GetCsv(): " + ex.ToString() );
                return null;
            }
        }

        public Entity FillCsv( DataRow dr )
        {
            Entity entity = new Entity();
            entity.ResourceId = new Guid( GetRowColumn( dr, "ResourceId", DEFAULT_GUID ) );
            entity.SubjectCsv = GetRowColumn( dr, "SubjectCsv", "" );

            return entity;
        }
        #endregion
    }
}

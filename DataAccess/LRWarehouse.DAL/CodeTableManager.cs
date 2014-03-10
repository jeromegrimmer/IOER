﻿using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using Microsoft.ApplicationBlocks.Data;

using MyEntity = LRWarehouse.Business.ResourceChildItem;
using MyEntityCollection = System.Collections.Generic.List<LRWarehouse.Business.ResourceChildItem>;
using CodeGradeLevel = LRWarehouse.Business.CodeGradeLevel;
using CodeGradeLevelCollection = LRWarehouse.Business.CodeGradeLevelCollection;

namespace LRWarehouse.DAL
{
    public class CodeTableManager : BaseDataManager
    {
        static string className = "CodeTableManager";

        #region generic
        public static DataSet SelectCodes( string resourceTable, string titleField)
        {
            return SelectCodes( resourceTable, titleField, "Title" );
        }

        public static DataSet SelectCodes( string resourceTable, string titleField, string sortField )
        {
            if ( sortField == null || sortField.Trim().Length == 0 )
                sortField = "Title";
            return SelectCodesWithValues( resourceTable, titleField, sortField, false );
        }

        
        public static DataSet SelectCodesWithValues( string resourceTable, string titleField )
        {
            return SelectCodesWithValues( resourceTable, titleField, "Title", true );
        }

        private static DataSet SelectCodesWithValues( string resourceTable, string titleField, string sortField, bool mustHaveValues )
        {
            if ( sortField == null || sortField.Trim().Length == 0 )
                sortField = "Title";

            string sql = string.Format( "SELECT [Id], [Title], [Title] + ' (' + isnull(convert(varchar,WareHouseTotal),0) + ')' As FormattedTitle FROM [{0}] Where IsActive = 1 ORDER BY {1}", resourceTable, sortField );
            string sql2 = string.Format( "SELECT [Id], [Title], [Title] + ' (' + isnull(convert(varchar,WareHouseTotal),0) + ')' As FormattedTitle FROM [{0}] Where IsActive = 1 && WareHouseTotal > 0 ORDER BY {1}", resourceTable, sortField );
            DataSet ds;
            if (mustHaveValues)
                ds= DatabaseManager.DoQuery( sql );
            else
                ds = DatabaseManager.DoQuery( sql2 );

            return ds;
        }

        #endregion

        #region  [ConditionOfUse]
        public static DataSet ConditionsOfUse_Select()
        {
            string connectionString = GetReadOnlyConnection();
            DataSet ds = new DataSet();
            try
            {
                ds = SqlHelper.ExecuteDataset( LRWarehouseRO(), "[ConditionsOfUse_Select]" );
                if ( ds.HasErrors )
                {
                    return null;
                }
                return ds;

            }
            catch ( Exception ex )
            {
                LogError( ex, className + ".ConditionsOfUse_Select() " );

                return null;
            }

        }//
        #endregion

        #region  GradeLevel
        public static CodeGradeLevel GradeLevelGet( int pId )
        {
            return GradeLevelGet( pId, "", "", "" );

        }//

        public static CodeGradeLevel GradeLevelGetByTitle( string title )
        {
            return GradeLevelGet( 0, title, "", "" );

        }//

        public static CodeGradeLevel GradeLevelGetByDesc( string desc )
        {
            return GradeLevelGet( 0, "", desc, "" );

        }//
        public static CodeGradeLevel GradeLevelGetByUrl( string url )
        {
            return GradeLevelGet( 0, "", "", url );

        }//

        /// <summary>
        /// Get GradeLevel record
        /// </summary>
        /// <param name="pId"></param>
        /// <returns></returns>
        private static CodeGradeLevel GradeLevelGet( int pId, string title, string desc, string url )
        {
            string connectionString = GetReadOnlyConnection();
            CodeGradeLevel entity = new CodeGradeLevel();
            try
            {
                SqlParameter[] sqlParameters = new SqlParameter[ 4 ];
                sqlParameters[ 0 ] = new SqlParameter( "@id", pId);
                sqlParameters[ 1 ] = new SqlParameter( "@title", title );
                sqlParameters[ 2 ] = new SqlParameter( "@descriptions", desc );
                sqlParameters[ 3 ] = new SqlParameter( "@url", url );

                DataSet ds = SqlHelper.ExecuteDataset( connectionString, "[Codes.GradeLevelGet]", sqlParameters );

                if ( DoesDataSetHaveRows(ds) )
                {
                    // it should return only one record.
                    entity = GradeLevelFill( ds.Tables[0].Rows[0] );
                }
                else
                {
                    entity.Message = "Record not found";
                    entity.IsValid = false;
                }
                return entity;

            }
            catch ( Exception ex )
            {
                LogError( ex, className + ".Get() " );
                entity.Message = "Unsuccessful: " + className + ".Get(): " + ex.Message.ToString();
                entity.IsValid = false;
                return entity;

            }

        }//

        public static CodeGradeLevelCollection GradeLevelGetByAgeRange(int fromAge, int toAge, bool isEducationBand, ref string status)
        {
            string connectionString = LRWarehouseRO();
            status = "successful";
            CodeGradeLevelCollection collection = new CodeGradeLevelCollection();
            try
            {
                SqlParameter[] sqlParameters = new SqlParameter[3];
                sqlParameters[0] = new SqlParameter("@MinAge", fromAge);
                sqlParameters[1] = new SqlParameter("@MaxAge", toAge);
                sqlParameters[2] = new SqlParameter("@IsEducationBand", isEducationBand);

                DataSet ds = SqlHelper.ExecuteDataset(connectionString, "[Codes.GradeLevelSelectByAgeRange]", sqlParameters);
                if (DoesDataSetHaveRows(ds))
                {
                    foreach (DataRow dr in ds.Tables[0].Rows)
                    {
                        CodeGradeLevel gradeLevel = GradeLevelFill(dr);
                        collection.Add(gradeLevel);
                    }
                }
            }
            catch (Exception ex)
            {
                LogError(className + ".GradeLevelGetByAgeRange(): " + ex.ToString());
                status = ex.Message;
            }

            return collection;
        }

        private static CodeGradeLevel GradeLevelFill(DataRow dr)
        {
            CodeGradeLevel entity = new CodeGradeLevel();
            entity.Id = GetRowColumn(dr, "Id", 0);
            entity.Title = GetRowColumn(dr, "Title", "");
            entity.AgeLevel = GetRowColumn(dr, "AgeLevel", 0);
            entity.Description = GetRowColumn(dr, "Description", "");
            entity.IsPathwaysLevel = GetRowColumn(dr, "IsPathwaysLevel", false);
            entity.AlignmentUrl = GetRowColumn(dr, "AlignmentUrl", "");
            entity.SortOrder = GetRowColumn(dr, "SortOrder", 0);
            entity.WarehouseTotal = GetRowColumn(dr, "WarehouseTotal", 0);
            entity.GradeRange = GetRowColumn(dr, "GradeRange", "");
            entity.GradeGroup = GetRowColumn(dr, "GradeGroup", "");
            entity.IsActive = GetRowColumn(dr, "IsActive", false);
            entity.IsEducationBand = GetRowColumn(dr, "IsEducationBand", false);
            entity.FromAge = GetRowColumn(dr, "FromAge", 0);
            entity.ToAge = GetRowColumn(dr, "ToAge", 0);

            return entity;
        }
        #endregion

    }
}

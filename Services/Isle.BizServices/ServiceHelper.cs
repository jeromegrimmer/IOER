﻿using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;

//temp use of:ILPathways.Utilities for email - probably should do differently
using ILPathways.Utilities;

namespace Isle.BizServices
{
    public class ServiceHelper
    {
        public static int DefaultMiles = 25;
        private static string thisClassName = "ServiceHelper";
        //

        #region === Security related Methods ===

        /// <summary>
        /// Encrypt the text using MD5 crypto service
        /// This is used for one way encryption of a user password - it can't be decrypted
        /// </summary>
        /// <param name="data"></param>
        /// <returns></returns>
        public static string Encrypt( string data )
        {
            byte[] byDataToHash = ( new UnicodeEncoding() ).GetBytes( data );
            byte[] bytHashValue = new MD5CryptoServiceProvider().ComputeHash( byDataToHash );
            return BitConverter.ToString( bytHashValue );
        }

        /// <summary>
        /// Encrypt the text using the provided password (key) and CBC CipherMode
        /// </summary>
        /// <param name="text"></param>
        /// <param name="password"></param>
        /// <returns></returns>
        public static string Encrypt_CBC( string text, string password )
        {
            RijndaelManaged rijndaelCipher = new RijndaelManaged();

            rijndaelCipher.Mode = CipherMode.CBC;
            rijndaelCipher.Padding = PaddingMode.PKCS7;
            rijndaelCipher.KeySize = 128;
            rijndaelCipher.BlockSize = 128;

            byte[] pwdBytes = System.Text.Encoding.UTF8.GetBytes( password );

            byte[] keyBytes = new byte[ 16 ];

            int len = pwdBytes.Length;

            if ( len > keyBytes.Length ) len = keyBytes.Length;

            System.Array.Copy( pwdBytes, keyBytes, len );

            rijndaelCipher.Key = keyBytes;
            rijndaelCipher.IV = keyBytes;

            ICryptoTransform transform = rijndaelCipher.CreateEncryptor();

            byte[] plainText = Encoding.UTF8.GetBytes( text );

            byte[] cipherBytes = transform.TransformFinalBlock( plainText, 0, plainText.Length );

            return Convert.ToBase64String( cipherBytes );

        }

        /// <summary>
        /// Decrypt the text using the provided password (key) and CBC CipherMode
        /// </summary>
        /// <param name="text"></param>
        /// <param name="password"></param>
        /// <returns></returns>
        public static string Decrypt_CBC( string text, string password )
        {
            RijndaelManaged rijndaelCipher = new RijndaelManaged();

            rijndaelCipher.Mode = CipherMode.CBC;
            rijndaelCipher.Padding = PaddingMode.PKCS7;
            rijndaelCipher.KeySize = 128;
            rijndaelCipher.BlockSize = 128;

            byte[] encryptedData = Convert.FromBase64String( text );

            byte[] pwdBytes = System.Text.Encoding.UTF8.GetBytes( password );

            byte[] keyBytes = new byte[ 16 ];

            int len = pwdBytes.Length;

            if ( len > keyBytes.Length ) len = keyBytes.Length;

            System.Array.Copy( pwdBytes, keyBytes, len );

            rijndaelCipher.Key = keyBytes;
            rijndaelCipher.IV = keyBytes;

            ICryptoTransform transform = rijndaelCipher.CreateDecryptor();

            byte[] plainText = transform.TransformFinalBlock( encryptedData, 0, encryptedData.Length );

            return Encoding.UTF8.GetString( plainText );

        }

        #endregion
        #region Helpers and validaton

        public static int StringToInt( string value, int defaultValue )
        {
            int returnValue = defaultValue;
            if ( Int32.TryParse( value, out returnValue ) == true )
                return returnValue;
            else
                return defaultValue;
        }


        public static bool StringToDate( string value, ref DateTime returnValue )
        {
            if ( System.DateTime.TryParse( value, out returnValue ) == true )
                return true;
            else
                return false;
        }

        /// <summary>
        /// IsInteger - test if passed string is an integer
        /// </summary>
        /// <param name="stringToTest"></param>
        /// <returns></returns>
        public static bool IsInteger( string stringToTest )
        {
            int newVal;
            bool result = false;
            try
            {
                newVal = Int32.Parse( stringToTest );

                // If we get here, then number is an integer
                result = true;
            }
            catch
            {

                result = false;
            }
            return result;

        }


        /// <summary>
        /// IsDate - test if passed string is a valid date
        /// </summary>
        /// <param name="stringToTest"></param>
        /// <returns></returns>
        public static bool IsDate( string stringToTest )
        {

            DateTime newDate;
            bool result = false;
            try
            {
                newDate = System.DateTime.Parse( stringToTest );
                result = true;
            }
            catch
            {

                result = false;
            }
            return result;

        } //end

        /// <summary>
        /// Check if the passed dataset is indicated as one containing an error message (from a web service)
        /// </summary>
        /// <param name="wsDataset">DataSet for a web service method</param>
        /// <returns>True if dataset contains an error message, otherwise false</returns>
        public static bool HasErrorMessage( DataSet wsDataset )
        {

            if ( wsDataset.DataSetName == "ErrorMessage" )
                return true;
            else
                return false;

        } //

        /// <summary>
        /// Check if the passed dataset is indicated as one containing an error message (from a web service) and returns the contained message
        /// </summary>
        /// <param name="wsDataset">DataSet for a web service method</param>
        /// <returns>The contained message for the dataset</returns>
        public static string GetWsMessage( DataSet wsDataset )
        {
            string wsMessage = "";

            try
            {

                if ( wsDataset.DataSetName == "ErrorMessage" )
                {
                    wsMessage = wsDataset.Tables[ 0 ].Rows[ 0 ][ "Message" ].ToString();
                }
            }
            catch ( Exception ex )
            {
                //ignore?

            }
            return wsMessage;
        } //
        #endregion

        #region === Dataset helper Methods ===
        /// <summary>
        /// Check is dataset is valid and has at least one table with at least one row
        /// </summary>
        /// <param name="ds"></param>
        /// <returns></returns>
        public static bool DoesDataSetHaveRows( DataSet ds )
        {

            try
            {
                if ( ds != null && ds.Tables.Count > 0 && ds.Tables[ 0 ].Rows.Count > 0 )
                    return true;
                else
                    return false;
            }
            catch
            {

                return false;
            }
        }//

        /// <summary>
        /// Helper method to retrieve a string column from a row but will ignore missing columns (unlike GetRowColumn)
        /// </summary>
        /// <param name="row"></param>
        /// <param name="column"></param>
        /// <returns></returns>
        public static string GetRowPossibleColumn( DataRow row, string column )
        {
            string colValue = "";

            try
            {
                colValue = row[ column ].ToString();

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = "";

            }
            catch ( Exception ex )
            {
                //this method will ignore not found
                colValue = "";
            }
            return colValue;

        } // end method
        public static int GetRowPossibleColumn( DataRow row, string column, int defaultValue )
        {
            int colValue = 0;

            try
            {
                colValue = Int32.Parse( row[ column ].ToString() );

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {
                //this method will ignore not found
                colValue = defaultValue;
            }
            return colValue;

        } // end method
        /// <summary>
        /// Helper method to retrieve a string column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRow</param>
        /// <param name="column">Column Name</param>
        /// <returns></returns>
        public static string GetRowColumn( DataRow row, string column )
        {
            return GetRowColumn( row, column, "" );
        } // end method

        /// <summary>
        /// Helper method to retrieve a string column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRow</param>
        /// <param name="column">Column Name</param>
        /// <param name="defaultValue">Default value to return if column data is invalid</param>
        /// <returns></returns>
        public static string GetRowColumn( DataRow row, string column, string defaultValue )
        {
            string colValue = "";

            try
            {
                colValue = row[ column ].ToString();

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {
                if ( column.IndexOf( "CUSTOMER_STATUS" ) > -1 )
                {
                    //ignore

                }
                else
                {

                    string exType = ex.GetType().ToString();
                    LogError( exType + " Exception in GetRowColumn( DataRow row, string column, string defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                }
                colValue = defaultValue;
            }
            return colValue;

        } // end method
        /// <summary>
        /// Helper method to retrieve an int column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRow</param>
        /// <param name="column">Column Name</param>
        /// <param name="defaultValue">Default value to return if column data is invalid</param>
        /// <returns></returns>
        public static int GetRowColumn( DataRow row, string column, int defaultValue )
        {
            int colValue = 0;

            try
            {
                colValue = Int32.Parse( row[ column ].ToString() );

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {


                LogError( "Exception in GetRowColumn( DataRow row, string column, int defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                colValue = defaultValue;
                //throw ex;
            }
            return colValue;

        } // end method

        /// <summary>
        /// Helper method to retrieve a bool column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRow</param>
        /// <param name="column">Column Name</param>
        /// <param name="defaultValue">Default value to return if column data is invalid</param>
        /// <returns></returns>
        public static bool GetRowColumn( DataRow row, string column, bool defaultValue )
        {
            bool colValue;

            try
            {
                colValue = Boolean.Parse( row[ column ].ToString() );

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {

                LogError( "Exception in GetRowColumn( DataRow row, string column, bool defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                colValue = defaultValue;
                //throw ex;
            }
            return colValue;

        } // end method

        /// <summary>
        /// Helper method to retrieve a DateTime column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRow</param>
        /// <param name="column">Column Name</param>
        /// <param name="defaultValue">Default value to return if column data is invalid</param>
        /// <returns></returns>      
        public static System.DateTime GetRowColumn( DataRow row, string column, System.DateTime defaultValue )
        {
            System.DateTime colValue;

            try
            {
                colValue = System.DateTime.Parse( row[ column ].ToString() );
            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {

                LogError( "Exception in GetRowColumn( DataRow row, string column, System.DateTime defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                colValue = defaultValue;
            }
            return colValue;

        } // end method


        /// <summary>
        /// Helper method to retrieve a column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRow</param>
        /// <param name="column">Column Name</param>
        /// <param name="defaultValue">Default value to return if column data is invalid</param>
        /// <returns></returns>
        public static decimal GetRowColumn( DataRow row, string column, decimal defaultValue )
        {
            decimal colValue = 0;

            try
            {
                colValue = Convert.ToDecimal( row[ column ].ToString() );

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {

                LogError( "Exception in GetRowColumn( DataRow row, string column, decimal defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                colValue = defaultValue;
            }
            return colValue;

        } // end method

        public static string GetRowColumn( DataRowView row, string column )
        {
            return GetRowColumn( row, column, "" );
        } // end method

        /// <summary>
        /// Helper method to retrieve a string column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRow</param>
        /// <param name="column">Column Name</param>
        /// <param name="defaultValue">Default value to return if column data is invalid</param>
        /// <returns></returns>
        public static string GetRowColumn( DataRowView row, string column, string defaultValue )
        {
            string colValue = "";

            try
            {
                colValue = row[ column ].ToString();

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {

                string exType = ex.GetType().ToString();
                LogError( exType + " Exception in GetRowColumn( DataRowView row, string column, string defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                colValue = defaultValue;
            }
            return colValue;

        } // end method

        /// <summary>
        /// Helper method to retrieve a string column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRowView</param>
        /// <param name="column">Column Name</param>
        /// <param name="defaultValue">Default value to return if column data is invalid</param>
        /// <returns></returns>
        public static int GetRowColumn( DataRowView row, string column, int defaultValue )
        {
            int colValue = 0;

            try
            {
                colValue = Int32.Parse( row[ column ].ToString() );

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {

                LogError( "Exception in GetRowColumn( DataRowView row, string column, int defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                colValue = defaultValue;
                //throw ex;
            }
            return colValue;

        } // end method

        /// <summary>
        /// Helper method to retrieve a bool column from a row while handling invalid values
        /// </summary>
        /// <param name="row"></param>
        /// <param name="column"></param>
        /// <param name="defaultValue"></param>
        /// <returns></returns>
        public static bool GetRowColumn( DataRowView row, string column, bool defaultValue )
        {
            bool colValue;

            try
            {
                colValue = Boolean.Parse( row[ column ].ToString() );

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {

                LogError( "Exception in GetRowColumn( DataRowView row, string column, bool defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                colValue = defaultValue;
                //throw ex;
            }
            return colValue;

        } // end method

        /// <summary>
        /// Helper method to retrieve a column from a row while handling invalid values
        /// </summary>
        /// <param name="row">DataRowView</param>
        /// <param name="column">Column Name</param>
        /// <param name="defaultValue">Default value to return if column data is invalid</param>
        /// <returns></returns>
        public static decimal GetRowColumn( DataRowView row, string column, decimal defaultValue )
        {
            decimal colValue = 0;

            try
            {
                colValue = Convert.ToDecimal( row[ column ].ToString() );

            }
            catch ( System.FormatException fex )
            {
                //Assuming FormatException means null or invalid value, so can ignore
                colValue = defaultValue;

            }
            catch ( Exception ex )
            {

                LogError( "Exception in GetRowColumn( DataRowView row, string column, decimal defaultValue ) for column: " + column + ". \r\n" + ex.Message.ToString(), true );
                colValue = defaultValue;
            }
            return colValue;

        } // end method

        #endregion

        #region === Application Keys Methods ===

        /// <summary>
        /// Gets the value of an application key from web.config. Returns blanks if not found
        /// </summary>
        /// <remarks>This property is explicitly thread safe.</remarks>
        public static string GetAppKeyValue( string keyName )
        {

            return GetAppKeyValue( keyName, "" );
        } //

        /// <summary>
        /// Gets the value of an application key from web.config. Returns the default value if not found
        /// </summary>
        /// <remarks>This property is explicitly thread safe.</remarks>
        public static string GetAppKeyValue( string keyName, string defaultValue )
        {
            string appValue = "";

            try
            {
                appValue = System.Configuration.ConfigurationManager.AppSettings[ keyName ];
                if ( appValue == null )
                    appValue = defaultValue;
            }
            catch
            {
                appValue = defaultValue;
                LogError( string.Format( "@@@@ Error on appKey: {0},  using default of: {1}", keyName, defaultValue ) );
            }

            return appValue;
        } //
        public static int GetAppKeyValue( string keyName, int defaultValue )
        {
            int appValue = -1;

            try
            {
                appValue = Int32.Parse( System.Configuration.ConfigurationManager.AppSettings[ keyName ] );

                // If we get here, then number is an integer, otherwise we will use the default
            }
            catch
            {
                appValue = defaultValue;
                LogError( string.Format( "@@@@ Error on appKey: {0},  using default of: {1}", keyName, defaultValue ) );
            }

            return appValue;
        } //
        #endregion

        #region Error Logging ================================================
        /// <summary>
        /// Format an exception and message, and then log it
        /// </summary>
        /// <param name="ex">Exception</param>
        /// <param name="message">Additional message regarding the exception</param>
        public static void LogError( Exception ex, string message )
        {
            bool notifyAdmin = false;
            LogError( ex, message, notifyAdmin );
        }

        /// <summary>
        /// Format an exception and message, and then log it
        /// </summary>
        /// <param name="ex">Exception</param>
        /// <param name="message">Additional message regarding the exception</param>
        /// <param name="notifyAdmin">If true, an email will be sent to admin</param>
        public static void LogError( Exception ex, string message, bool notifyAdmin )
        {

            string sessionId = "unknown";
            string remoteIP = "unknown";
            string path = "unknown";
            //string queryString = "unknown";
            string url = "unknown";
            string parmsString = "";

            try
            {

                string serverName = GetAppKeyValue( "serverName", "unknown" );

            }
            catch
            {
                //eat any additional exception
            }

            try
            {
                string errMsg = message +
                    "\r\nType: " + ex.GetType().ToString() + ";" +
                    "\r\nSession Id - " + sessionId + "____IP - " + remoteIP +
                    "\r\nException: " + ex.Message.ToString() + ";" +
                    "\r\nStack Trace: " + ex.StackTrace.ToString() +
                    "\r\nServer\\Template: " + path +
                    "\r\nUrl: " + url;

                if ( parmsString.Length > 0 )
                    errMsg += "\r\nParameters: " + parmsString;

                LogError( errMsg );
            }
            catch
            {
                //eat any additional exception
            }

        } //


        /// <summary>
        /// Write the message to the log file.
        /// </summary>
        /// <remarks>
        /// The message will be appended to the log file only if the flag "logErrors" (AppSetting) equals yes.
        /// The log file is configured in the web.config, appSetting: "error.log.path"
        /// </remarks>
        /// <param name="message">Message to be logged.</param>
        public static void LogError( string message )
        {

            if ( GetAppKeyValue( "notifyOnException", "no" ).ToLower() == "yes" )
            {
                LogError( message, true );
            }
            else
            {
                LogError( message, false );
            }

        } //
        /// <summary>
        /// Write the message to the log file.
        /// </summary>
        /// <remarks>
        /// The message will be appended to the log file only if the flag "logErrors" (AppSetting) equals yes.
        /// The log file is configured in the web.config, appSetting: "error.log.path"
        /// </remarks>
        /// <param name="message">Message to be logged.</param>
        /// <param name="notifyAdmin"></param>
        public static void LogError( string message, bool notifyAdmin )
        {
            if ( GetAppKeyValue( "logErrors" ).ToString().Equals( "yes" ) )
            {
                try
                {
                    string datePrefix = System.DateTime.Today.ToString( "u" ).Substring( 0, 10 );
                    string logFile = GetAppKeyValue( "path.error.log", "C:\\VOS_LOGS.txt" );
                    string outputFile = logFile.Replace( "[date]", datePrefix );

                    StreamWriter file = File.AppendText( outputFile );
                    file.WriteLine( DateTime.Now + ": " + message );
                    file.WriteLine( "---------------------------------------------------------------------" );
                    file.Close();

                    if ( notifyAdmin )
                    {
                        if ( GetAppKeyValue( "notifyOnException", "no" ).ToLower() == "yes" )
                        {
                            EmailManager.NotifyAdmin( "workNet Exception encountered", message );
                        }
                    }
                }
                catch ( Exception ex )
                {
                    //eat any additional exception
                    DoTrace( 5, thisClassName + ".LogError(string message, bool notifyAdmin). Exception: " + ex.Message );
                }
            }
        } //


        /// <summary>
        /// Handle trace requests - typically during development, but may be turned on to track code flow in production.
        /// </summary>
        /// <param name="message">Trace message</param>
        /// <remarks>This is a helper method that defaults to a trace level of 10</remarks>
        public static void DoTrace( string message )
        {
            //default level to 10
            DoTrace( 10, message, true );
        }

        /// <summary>
        /// Handle trace requests - typically during development, but may be turned on to track code flow in production.
        /// </summary>
        /// <param name="level"></param>
        /// <param name="message"></param>
        public static void DoTrace( int level, string message )
        {
            DoTrace( level, message, true );
        }

        /// <summary>
        /// Handle trace requests - typically during development, but may be turned on to track code flow in production.
        /// </summary>
        /// <param name="level"></param>
        /// <param name="message"></param>
        /// <param name="showingDatetime">If true, precede message with current date-time, otherwise just the message> The latter is useful for data dumps</param>
        public static void DoTrace( int level, string message, bool showingDatetime )
        {
            //TODO: Future provide finer control at the control level
            string msg = "";
            int appTraceLevel = 0;
            //bool useBriefFormat = true;

            try
            {
                appTraceLevel = GetAppKeyValue( "appTraceLevel", 1 );

                //Allow if the requested level is <= the application thresh hold
                if ( level <= appTraceLevel )
                {
                    string usingBriefFormat = GetAppKeyValue( "usingBriefFormat", "yes" );
                    if ( usingBriefFormat == "yes" )
                    {
                        if ( showingDatetime )
                            msg = "\n " + System.DateTime.Now.ToString() + " - " + message;
                        else
                            msg = "\n " + message;

                    }
                    else
                    {
                        msg = "\n======================= Trace ================================= ";
                        msg += "\nTime: " + System.DateTime.Now.ToString();
                        msg += "\nTrace: " + message;
                        msg += "\n=============================================================== ";
                    }
                    string datePrefix = System.DateTime.Today.ToString( "u" ).Substring( 0, 10 );
                    string logFile = GetAppKeyValue( "path.trace.log", "C:\\VOS_LOGS.txt" );
                    string outputFile = logFile.Replace( "[date]", datePrefix );

                    StreamWriter file = File.AppendText( outputFile );

                    file.WriteLine( msg );
                    file.Close();

                }
            }
            catch
            {
                //ignore errors
            }

        }
        #endregion

        #region Common Utility Methods
        public static string HandleApostrophes( string strValue )
        {

            if ( strValue.IndexOf( "'" ) > -1 )
            {
                strValue = strValue.Replace( "'", "''" );
            }
            if ( strValue.IndexOf( "''''" ) > -1 )
            {
                strValue = strValue.Replace( "''''", "''" );
            }

            return strValue;
        }
        public static String CleanText( String text )
        {
            if ( String.IsNullOrEmpty( text.Trim() ) )
                return String.Empty;

            String output = String.Empty;
            try
            {
                String rxPattern = "<(?>\"[^\"]*\"|'[^']*'|[^'\">])*>";
                Regex rx = new Regex( rxPattern );
                output = rx.Replace( text, String.Empty );
                if ( output.ToLower().IndexOf( "<script" ) > -1
                    || output.ToLower().IndexOf( "javascript" ) > -1 )
                {
                    output = "";
                }
            }
            catch ( Exception ex )
            {

            }

            return output;
        }
        /// <summary>
        /// Format a string item for a search string (where)
        /// </summary>
        /// <param name="sqlWhere"></param>
        /// <param name="colName"></param>
        /// <param name="colValue"></param>
        /// <param name="booleanOperator"></param>
        /// <returns></returns>
        public static string FormatSearchItem( string sqlWhere, string colName, string colValue, string booleanOperator )
        {
            string item = "";
            string boolean = " ";

            if ( colValue.Length == 0 )
                return "";

            if ( sqlWhere.Length > 0 )
            {
                boolean = " " + booleanOperator + " ";
            }
            //allow asterisks
            colValue = colValue.Replace( "*", "%" );

            if ( colValue.IndexOf( "%" ) > -1 )
            {
                item = boolean + " (" + colName + " like '" + colValue + "') ";
            }
            else
            {
                item = boolean + " (" + colName + " = '" + colValue + "') ";
            }

            return item;

        }	// End method

        /// <summary>
        /// Format an integer item for a search string (where)
        /// </summary>
        /// <param name="sqlWhere"></param>
        /// <param name="colName"></param>
        /// <param name="colValue"></param>
        /// <param name="booleanOperator"></param>
        /// <returns></returns>
        public static string FormatSearchItem( string sqlWhere, string colName, int colValue, string booleanOperator )
        {
            string item = "";
            string boolean = " ";

            if ( sqlWhere.Length > 0 )
            {
                boolean = " " + booleanOperator + " ";
            }

            item = boolean + " (" + colName + " = " + colValue + ") ";

            return item;

        }	// End method

        /// <summary>
        /// Format an item for a search string (where)
        /// </summary>
        /// <param name="sqlWhere"></param>
        /// <param name="filter"></param>
        /// <param name="booleanOperator"></param>
        /// <returns></returns>
        public static string FormatSearchItem( string sqlWhere, string filter, string booleanOperator )
        {
            string item = "";
            string boolean = " ";

            if ( filter.Trim().Length == 0 )
                return "";

            if ( sqlWhere.Length > 0 )
            {
                boolean = " " + booleanOperator + " ";
            }

            item = boolean + " (" + filter + ") ";

            return item;

        }	// End method

        #endregion
    }
}

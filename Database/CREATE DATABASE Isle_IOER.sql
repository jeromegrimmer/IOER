USE [master]
GO

/****** Object:  Database [Isle_IOER]    Script Date: 3/9/2014 9:22:23 PM ******/
CREATE DATABASE [Isle_IOER] ON  PRIMARY 
( NAME = N'Isle_IOER', FILENAME = N'C:\sql2008Data\Data\Isle_IOER.mdf' , SIZE = 4460544KB , MAXSIZE = UNLIMITED, FILEGROWTH = 51200KB )
 LOG ON 
( NAME = N'Isle_IOER_log', FILENAME = N'C:\sql2008Data\Logs\Isle_IOER_logs.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

ALTER DATABASE [Isle_IOER] ADD FILEGROUP [Search]
GO

ALTER DATABASE [Isle_IOER] SET COMPATIBILITY_LEVEL = 90
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Isle_IOER].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [Isle_IOER] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [Isle_IOER] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [Isle_IOER] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [Isle_IOER] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [Isle_IOER] SET ARITHABORT OFF 
GO

ALTER DATABASE [Isle_IOER] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [Isle_IOER] SET AUTO_CREATE_STATISTICS ON 
GO

ALTER DATABASE [Isle_IOER] SET AUTO_SHRINK ON 
GO

ALTER DATABASE [Isle_IOER] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [Isle_IOER] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [Isle_IOER] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [Isle_IOER] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [Isle_IOER] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [Isle_IOER] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [Isle_IOER] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [Isle_IOER] SET  DISABLE_BROKER 
GO

ALTER DATABASE [Isle_IOER] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [Isle_IOER] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [Isle_IOER] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [Isle_IOER] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [Isle_IOER] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [Isle_IOER] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [Isle_IOER] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [Isle_IOER] SET RECOVERY SIMPLE 
GO

ALTER DATABASE [Isle_IOER] SET  MULTI_USER 
GO

ALTER DATABASE [Isle_IOER] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [Isle_IOER] SET DB_CHAINING OFF 
GO

ALTER DATABASE [Isle_IOER] SET  READ_WRITE 
GO



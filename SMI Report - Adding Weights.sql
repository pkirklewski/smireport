
-- ================================================================================================================================================================
-- Author:Piotr Kirklewski
-- Create date: 11/04/17
-- Description: Runs [ReportsGetSecurityInspectionFormHeaderDetails] Stored Procedure repeatedly for all the FormInstanceIDs of SMI form in the specified timeframe
-- ================================================================================================================================================================

USE MobileForms; 
DECLARE @FormInstanceID INT
DECLARE @licznik INT
DECLARE @numberOfInstances INT
DECLARE @x INT
SET @licznik = 0

SELECT FormInstanceId
INTO #allInstances
FROM MobileForms.dbo.FormInstance 
WHERE FormDefinitionId = 263 
AND CreatedDate BETWEEN '2017-01-01 00:00:00.000' AND '2017-02-01 00:00:00.000'
--SELECT * from #allInstances

SET @numberOfInstances = (SELECT COUNT(*) FROM #allInstances)

--CREATE TABLE SMI_REPORT
--(FormInstanceID VARCHAR(255),
--CreatedDate VARCHAR(255),
--Questions VARCHAR(255) ,
--QNum VARCHAR(255) ,
--QStatusInt VARCHAR(255) ,
--QuestionCount VARCHAR(255) ,
--WeightedScores VARCHAR(255) ,
--Observation VARCHAR(255) ,
--Aspect VARCHAR(255) ,
--AspectSort VARCHAR(255) ,
--QStatus VARCHAR(255) ,
--QComments VARCHAR(255) ,
--WorkOrderNumber VARCHAR(255))

--EXEC [dbo].[ReportsGetSecurityInspectionFormHeaderDetails001] 754732

------------------------------------------------------------------------------------------------------------------------

-- Create a Tenp Table -------------------------------------------------------------------------------------------------

CREATE TABLE #smi_report_basic
(FormInstanceID VARCHAR(255),
CreatedDate VARCHAR(255),
Questions VARCHAR(255) ,
QNum VARCHAR(255) ,
QStatusInt VARCHAR(255) ,
QuestionCount VARCHAR(255) ,
WeightedScores VARCHAR(255) ,
Observation VARCHAR(255) ,
Aspect VARCHAR(255) ,
AspectSort VARCHAR(255) ,
QStatus VARCHAR(255) ,
QComments VARCHAR(255) ,
WorkOrderNumber VARCHAR(255))

-- END OF Create a Temp table -------------------------------------------------------------------------------------------------

CREATE TABLE #gor_to_region (GOR INT,Region INT,RegionLetter VARCHAR(255),RegionName VARCHAR(255))

INSERT INTO #gor_to_region VALUES (1,1,'A','Scotland and North East')
INSERT INTO #gor_to_region VALUES (2,1,'A','Scotland and North East')
INSERT INTO #gor_to_region VALUES (3,3,'B','North West and East Midlands')
INSERT INTO #gor_to_region VALUES (4,3,'B','North West and East Midlands')
INSERT INTO #gor_to_region VALUES (5,4,'C','Wales, West Midlands and East')
INSERT INTO #gor_to_region VALUES (6,4,'C','Wales, West Midlands and East')
INSERT INTO #gor_to_region VALUES (7,4,'C','Wales, West Midlands and East')
INSERT INTO #gor_to_region VALUES (8,4,'C','Wales, West Midlands and East')
INSERT INTO #gor_to_region VALUES (9,5,'D','South West, South East and London')
INSERT INTO #gor_to_region VALUES (10,5,'D','South West, South East and London')
INSERT INTO #gor_to_region VALUES (11,5,'D','South West, South East and London')

CREATE TABLE #yes_or_no (FormInstanceID INT,Qstatus VARCHAR(10))

--delete from #gor_to_region
--select * from #gor_to_region

--delete from #gor_to_region
--select * from #gor_to_region


WHILE ( @licznik ) < (@numberOfInstances)
 
BEGIN
   	
   	SET @FormInstanceID =  (SELECT TOP 1 #allInstances.FormInstanceId from #allInstances)
 
   	set @licznik = @licznik + 1
   	
	--INSERT INTO #smi_report EXEC [dbo].[ReportsGetSecurityInspectionFormHeaderDetails001] @FormInstanceID

	INSERT INTO #smi_report_basic EXEC [dbo].[ReportsGetSecurityInspectionFormHeaderDetails001] @FormInstanceID 


	-- Yes vs No =======================================================================================================
			
	INSERT INTO #yes_or_no SELECT FormInstanceID,QStatus FROM #smi_report_basic WHERE FormInstanceID = @FormInstanceID AND (QStatus = 'Yes' OR QStatus ='No')

	-- End of Yes vs No ================================================================================================

	DELETE FROM #allInstances WHERE #allInstances.FormInstanceId = @FormInstanceID
END
------------------------------------------------------------------------------------------------------------------------

select *  from #yes_or_no
















SELECT DISTINCT #smi_report_basic.FormInstanceID 
INTO #FormInstanceIDs
FROM #smi_report_basic

--select count(*) as FormInstanceIDsCount from #FormInstanceIDs

SELECT DISTINCT #smi_report_basic.FormInstanceId
,[MobileForms].[dbo].[FieldValue].Value as BuildingAddress
INTO #WORKADDRESS
FROM #smi_report_basic
LEFT JOIN [MobileForms].[dbo].[FieldValue] ON [MobileForms].[dbo].[FieldValue].FormInstanceId  = #smi_report_basic.FormInstanceID
WHERE [MobileForms].[dbo].[FieldValue].FieldDefinitionId = 5907 

--select * from #WORKADDRESS



--select * from #FormInstanceIDs

SELECT [MobileForms].[dbo].[FieldValue].FormInstanceId,[MobileForms].[dbo].[FieldValue].Value as BuildingName
INTO #BUILDINGNAME
FROM [MobileForms].[dbo].[FieldValue]
LEFT JOIN #FormInstanceIDs ON [MobileForms].[dbo].[FieldValue].FormInstanceId  = #FormInstanceIDs.FormInstanceID
WHERE [MobileForms].[dbo].[FieldValue].FieldDefinitionId = 5908
AND [MobileForms].[dbo].[FieldValue].FormInstanceId IN (SELECT #FormInstanceIDs.FormInstanceID FROM #FormInstanceIDs)

SELECT DISTINCT #smi_report_basic.FormInstanceID
,#smi_report_basic.WorkOrderNumber
INTO #WORKORDERNUMBER
FROM #smi_report_basic
WHERE #smi_report_basic.FormInstanceID IN (SELECT #FormInstanceIDs.FormInstanceID FROM #FormInstanceIDs)
AND #smi_report_basic.WorkOrderNumber IS NOT NULL

SELECT [MobileForms].[dbo].[FieldValue].FormInstanceId,[MobileForms].[dbo].[FieldValue].Value as BuildingID
INTO #BUILDINGID
FROM [MobileForms].[dbo].[FieldValue]
LEFT JOIN #FormInstanceIDs ON [MobileForms].[dbo].[FieldValue].FormInstanceId= #FormInstanceIDs.FormInstanceID
WHERE [MobileForms].[dbo].[FieldValue].FieldDefinitionId = 5899
AND [MobileForms].[dbo].[FieldValue].FormInstanceId IN (SELECT #FormInstanceIDs.FormInstanceID FROM #FormInstanceIDs)
--select * from #BUILDINGNAME
--select * from #FormInstanceIDs
--select count(*) #BUILDINGID
--select * from #BUILDINGID

SELECT [MobileForms].[dbo].[FieldValue].FormInstanceId,[MobileForms].[dbo].[FieldValue].Value as FirstName
INTO #FMFIRSTNAME
FROM [MobileForms].[dbo].[FieldValue]
LEFT JOIN #FormInstanceIDs ON [MobileForms].[dbo].[FieldValue].FormInstanceId = #FormInstanceIDs.FormInstanceID
WHERE [MobileForms].[dbo].[FieldValue].FieldDefinitionId = 5904
AND [MobileForms].[dbo].[FieldValue].FormInstanceId IN (SELECT #FormInstanceIDs.FormInstanceID FROM #FormInstanceIDs)

--select count(*) from #FMFIRSTNAME
--select * from #FMFIRSTNAME

SELECT [MobileForms].[dbo].[FieldValue].FormInstanceId,[MobileForms].[dbo].[FieldValue].Value as LastName
INTO #FMLASTNAME
FROM [MobileForms].[dbo].[FieldValue]
LEFT JOIN #FormInstanceIDs ON [MobileForms].[dbo].[FieldValue].FormInstanceId = #FormInstanceIDs.FormInstanceID
WHERE [MobileForms].[dbo].[FieldValue].FieldDefinitionId = 5905
AND [MobileForms].[dbo].[FieldValue].FormInstanceId IN (SELECT #FormInstanceIDs.FormInstanceID FROM #FormInstanceIDs)

--select count(*) FROM #FMLASTNAME
--select * from #FMLASTNAME

SELECT #BUILDINGID.BuildingID,[MobileForms].[dbo].[Schedule6BuildingData].GOR 
INTO #BUILDINGGOR
FROM #BUILDINGID
LEFT JOIN [MobileForms].[dbo].[Schedule6BuildingData] ON [MobileForms].[dbo].[Schedule6BuildingData].BuildingId  = #BUILDINGID.BuildingID

 --select COUNT(*) BUILDINGGOR_COUNT from #BUILDINGGOR
 --select COUNT(*) as BUILDINGID_COUNT  from #BUILDINGID

 --select * from #BUILDINGGOR
 --select * from #BUILDINGID

  -- select count(*) as CountAllInstances from #allInstances
  -- Final Report 

SELECT #BUILDINGID.BuildingID
,#smi_report_basic.FormInstanceID
,#smi_report_basic.Observation
,#smi_report_basic.Aspect
,#smi_report_basic.Questions
,#smi_report_basic.QStatus as Answers
,#smi_report_basic.QComments as Comments
INTO #smi_report_with_buildingID
FROM #smi_report_basic
LEFT JOIN #BUILDINGID ON #BUILDINGID.FormInstanceID = #smi_report_basic.FormInstanceID

--select count(*) as smi_report_basic from #smi_report_basic
--select count(*) as smi_report_with_buildingID from #smi_report_with_buildingID
--select * from #smi_report_with_buildingID

SELECT DISTINCT #BUILDINGGOR.GOR as RegionName
,#smi_report_with_buildingID.BuildingID
,#smi_report_with_buildingID.FormInstanceID
,#smi_report_with_buildingID.Observation
,#smi_report_with_buildingID.Aspect
,#smi_report_with_buildingID.Questions
,#smi_report_with_buildingID.Answers
,#smi_report_with_buildingID.Comments
INTO #smi_report_with_GOR
FROM #smi_report_with_buildingID
LEFT JOIN #BUILDINGGOR ON #BUILDINGGOR.BuildingId = #smi_report_with_buildingID.BuildingID 

--select count(*)  as smi_report_with_GOR from #smi_report_with_GOR --where FormInstanceID = 754732
--select * from #smi_report_with_GOR
--==================================================================================================================

SELECT RegionName 
, #FMFIRSTNAME.FirstName + ' ' + #FMLASTNAME.LastName as FacilitiesManager
,#smi_report_with_GOR.FormInstanceID
,#smi_report_with_GOR.BuildingID
,#smi_report_with_GOR.Observation
,#smi_report_with_GOR.Aspect
,#smi_report_with_GOR.Questions
,#smi_report_with_GOR.Answers
,#smi_report_with_GOR.Comments
INTO #smi_report_with_fmname
FROM #smi_report_with_GOR
LEFT JOIN #FMFIRSTNAME ON #FMFIRSTNAME.FormInstanceID = #smi_report_with_GOR.FormInstanceID 
LEFT JOIN #FMLASTNAME ON #FMLASTNAME.FormInstanceID = #smi_report_with_GOR.FormInstanceID

--select * from #smi_report_with_fmname

SELECT #smi_report_with_fmname.RegionName
,#smi_report_with_fmname.FacilitiesManager
,#BUILDINGNAME.BuildingName
,#smi_report_with_fmname.FormInstanceID
,#smi_report_with_fmname.BuildingID
,#smi_report_with_fmname.Observation
,#smi_report_with_fmname.Aspect
,#smi_report_with_fmname.Questions
,#smi_report_with_fmname.Answers
,#smi_report_with_fmname.Comments
INTO #smi_report_with_BuildngName
FROM #smi_report_with_fmname
LEFT JOIN #BUILDINGNAME ON #smi_report_with_fmname.FormInstanceID = #BUILDINGNAME.FormInstanceId --= #smi_report_with_fmname.FormInstanceID 


SELECT #smi_report_with_BuildngName.RegionName
,#smi_report_with_BuildngName.FacilitiesManager
,#smi_report_with_BuildngName.BuildingName AS BUILDINGNAME
,#WORKADDRESS.BuildingAddress AS WORKADDRESS
,#smi_report_with_BuildngName.FormInstanceID
,#smi_report_with_BuildngName.BuildingID
,#smi_report_with_BuildngName.Observation
,#smi_report_with_BuildngName.Aspect
,#smi_report_with_BuildngName.Questions
,#smi_report_with_BuildngName.Answers
,#smi_report_with_BuildngName.Comments
INTO #smi_report_with_BuildngAddress
FROM #smi_report_with_BuildngName
LEFT JOIN #WORKADDRESS ON #smi_report_with_BuildngName.FormInstanceID = #WORKADDRESS.FormInstanceId 

SELECT #smi_report_with_BuildngAddress.RegionName
,#smi_report_with_BuildngAddress.FacilitiesManager
,#smi_report_with_BuildngAddress.BUILDINGNAME
,#smi_report_with_BuildngAddress.WORKADDRESS 
,#smi_report_with_BuildngAddress.FormInstanceID
,#smi_report_with_BuildngAddress.BuildingID
,#smi_report_with_BuildngAddress.Observation
,#smi_report_with_BuildngAddress.Aspect
,#smi_report_with_BuildngAddress.Questions
,#smi_report_with_BuildngAddress.Answers
,#smi_report_with_BuildngAddress.Comments
,#WORKORDERNUMBER.WorkOrderNumber
INTO #smi_report_with_WorkOrderNumber
FROM #smi_report_with_BuildngAddress
LEFT JOIN #WORKORDERNUMBER ON #WORKORDERNUMBER.FormInstanceID = #smi_report_with_BuildngAddress.FormInstanceID


SELECT #gor_to_region.Region as RegionNumber
,#gor_to_region.RegionLetter 
,#gor_to_region.RegionName
,#smi_report_with_WorkOrderNumber.FacilitiesManager
,#smi_report_with_WorkOrderNumber.BUILDINGNAME
,#smi_report_with_WorkOrderNumber.WORKADDRESS 
,#smi_report_with_WorkOrderNumber.FormInstanceID
,#smi_report_with_WorkOrderNumber.BuildingID
,#smi_report_with_WorkOrderNumber.Observation
,#smi_report_with_WorkOrderNumber.Aspect
,#smi_report_with_WorkOrderNumber.Questions
,#smi_report_with_WorkOrderNumber.Answers
,#smi_report_with_WorkOrderNumber.Comments
, ISNULL (#smi_report_with_WorkOrderNumber.WorkOrderNumber,'_') as WorkOrderNumber
INTO #smi_report_with_RegionLetterAndName
FROM #smi_report_with_WorkOrderNumber
LEFT JOIN #gor_to_region ON #smi_report_with_WorkOrderNumber.RegionName = #gor_to_region.GOR

 
 select * from #smi_report_with_RegionLetterAndName WHERE Answers = 'No'
--select * from #WORKORDERNUMBER

--select count(*) AS WORKORDRNUMBER_COUNT FROM #WORKORDERNUMBER

--select * from #smi_report_with_WorkOrderNumber

--SELECT * FROM #smi_report_with_BuildngAddress
--SELECT * FROM #smi_report_basic

DROP TABLE #allInstances
DROP TABLE #smi_report_basic
DROP TABLE #WORKADDRESS
DROP TABLE #BUILDINGNAME
DROP TABLE #BUILDINGID
DROP TABLE #FMFIRSTNAME
DROP TABLE #FMLASTNAME
DROP TABLE #smi_report_with_buildingID
DROP TABLE #BUILDINGGOR
DROP TABLE #FormInstanceIDs
DROP TABLE #smi_report_with_GOR
DROP TABLE #smi_report_with_fmname
DROP TABLE #smi_report_with_BuildngName
DROP TABLE #smi_report_with_BuildngAddress
DROP TABLE #smi_report_with_WorkOrderNumber
DROP TABLE #WORKORDERNUMBER
DROP TABLE #gor_to_region
DROP TABLE #smi_report_with_RegionLetterAndName
drop table #yes_or_no
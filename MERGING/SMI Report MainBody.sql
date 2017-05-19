
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
AND CreatedDate BETWEEN '2017-01-01 00:00:00.000' AND '2017-01-31 23:59:59.999'

--SELECT * from #allInstances

SET @numberOfInstances = (SELECT COUNT(*) FROM #allInstances)


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

CREATE TABLE #yes_no_percent_final
(FormInstanceID INT
,YesValue INT
,NoValue INT
,TotalValue INT
,NoToYesPercent DECIMAL(4,2)
,Reinspection INT
,ERROR VARCHAR(255)
)



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

DELETE FROM [MobileForms].[dbo].[FormInstanceProcessed]

--CREATE TABLE #yes_or_no (FormInstanceID INT,Qstatus VARCHAR(10))

WHILE ( @licznik ) < (@numberOfInstances)
 
BEGIN
   	
   	SET @FormInstanceID =  (SELECT TOP 1 #allInstances.FormInstanceId from #allInstances)
 
   	INSERT INTO [MobileForms].[dbo].FormInstanceProcessed VALUES (@FormInstanceID,@licznik)
	
	set @licznik = @licznik + 1

	BEGIN TRY
	INSERT INTO #smi_report_basic EXEC [dbo].[ReportsGetSecurityInspectionFormHeaderDetails001] @FormInstanceID 
    END TRY
	BEGIN CATCH
	END CATCH

SELECT  FormInstanceID,QStatus 
INTO #yes_or_no
FROM #smi_report_basic 
WHERE FormInstanceID = @FormInstanceID
AND (QStatus = 'Yes' OR QStatus ='No')
	
	
select (Select DISTINCT #yes_or_no.FormInstanceID) as FormInstanceID
,#yes_or_no.QStatus
,ISNULL((SELECT COUNT(#yes_or_no.QStatus) WHERE #yes_or_no.QStatus = 'Yes'),0)  AS 'Yes'
,ISNULL((SELECT COUNT(#yes_or_no.QStatus) WHERE #yes_or_no.QStatus = 'No'),0) AS 'No' 
INTO #yes_no_values
FROM #yes_or_no 
WHERE #yes_or_no.FormInstanceID = @FormInstanceID
GROUP BY #yes_or_no.FormInstanceID,#yes_or_no.QStatus


DECLARE @y INT
DECLARE @y0 INT
DECLARE @y_final INT
DECLARE @n INT
DECLARE @n0 INT
DECLARE @n_final INT
DECLARE @total INT
DECLARE @pcent INT

SET @y = ISNULL((select #yes_no_values.Yes from #yes_no_values WHERE #yes_no_values.FormInstanceID = @FormInstanceID AND #yes_no_values.Yes > 0),0)
SET @y0 = ISNULL((select #yes_no_values.Yes from #yes_no_values WHERE #yes_no_values.FormInstanceID = @FormInstanceID AND #yes_no_values.Yes = 0),0)
SET @n = ISNULL((select #yes_no_values.No from #yes_no_values WHERE #yes_no_values.FormInstanceID = @FormInstanceID AND #yes_no_values.No > 0),0) 
SET @n0 = ISNULL((select #yes_no_values.No from #yes_no_values WHERE #yes_no_values.FormInstanceID = @FormInstanceID AND #yes_no_values.no = 0),0) 

SET @y_final = @y + @y0
SET @n_final = @n + @n0


DECLARE @p DECIMAL(4,2)

SET @p = (SELECT CASE WHEN (@n_final + @y_final)  = 0  THEN 77.77 ELSE (CAST((@n_final / ((@y_final + @n_final)/100.00)) AS DECIMAL(4,2))) END)

SELECT DISTINCT #yes_no_values.FormInstanceID AS FormInstanceID
,@y_final AS YesValue
,@n_final AS NoValue
,@y_final + @n_final AS TotalValue
,@p as NoToYesPercent 
, (SELECT CASE WHEN @p < 90.00 THEN 0 WHEN @p >= 90.00 THEN 1 END) AS Reinspection
INTO #YesNoPercent
FROM #yes_no_values WHERE #yes_no_values.FormInstanceID = @FormInstanceID

INSERT INTO #yes_no_percent_final VALUES (#yes_no_percent_final.FormInstanceID,#yes_no_percent_final.YesValue,#yes_no_percent_final.NoValue,#yes_no_percent_final.TotalValue,#yes_no_percent_final.NoToYesPercent,Reinspection)

--select * from  #yes_no_values

DELETE FROM #allInstances WHERE #allInstances.FormInstanceId = @FormInstanceID

DROP TABLE #yes_or_no
DROP TABLE #yes_no_values 
DROP TABLE #YesNoPercent

DELETE FROM #allInstances WHERE #allInstances.FormInstanceId = @FormInstanceID

END --WND OF THE WHILE LOOP ===============================================================================================





SELECT DISTINCT #smi_report_basic.FormInstanceID 
INTO #FormInstanceIDs
FROM #smi_report_basic


SELECT DISTINCT #smi_report_basic.FormInstanceId
,[MobileForms].[dbo].[FieldValue].Value as BuildingAddress
INTO #WORKADDRESS
FROM #smi_report_basic
LEFT JOIN [MobileForms].[dbo].[FieldValue] ON [MobileForms].[dbo].[FieldValue].FormInstanceId  = #smi_report_basic.FormInstanceID
WHERE [MobileForms].[dbo].[FieldValue].FieldDefinitionId = 5907 


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


SELECT [MobileForms].[dbo].[FieldValue].FormInstanceId,[MobileForms].[dbo].[FieldValue].Value as FirstName
INTO #FMFIRSTNAME
FROM [MobileForms].[dbo].[FieldValue]
LEFT JOIN #FormInstanceIDs ON [MobileForms].[dbo].[FieldValue].FormInstanceId = #FormInstanceIDs.FormInstanceID
WHERE [MobileForms].[dbo].[FieldValue].FieldDefinitionId = 5904
AND [MobileForms].[dbo].[FieldValue].FormInstanceId IN (SELECT #FormInstanceIDs.FormInstanceID FROM #FormInstanceIDs)


SELECT [MobileForms].[dbo].[FieldValue].FormInstanceId,[MobileForms].[dbo].[FieldValue].Value as LastName
INTO #FMLASTNAME
FROM [MobileForms].[dbo].[FieldValue]
LEFT JOIN #FormInstanceIDs ON [MobileForms].[dbo].[FieldValue].FormInstanceId = #FormInstanceIDs.FormInstanceID
WHERE [MobileForms].[dbo].[FieldValue].FieldDefinitionId = 5905
AND [MobileForms].[dbo].[FieldValue].FormInstanceId IN (SELECT #FormInstanceIDs.FormInstanceID FROM #FormInstanceIDs)


SELECT #BUILDINGID.BuildingID,[MobileForms].[dbo].[Schedule6BuildingData].GOR 
INTO #BUILDINGGOR
FROM #BUILDINGID
LEFT JOIN [MobileForms].[dbo].[Schedule6BuildingData] ON [MobileForms].[dbo].[Schedule6BuildingData].BuildingId  = #BUILDINGID.BuildingID


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
DROP TABLE #yes_no_percent_final


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

	-- Add Yes_VS_No calculation here - insert into  =================================================================================================================




DELETE FROM #allInstances WHERE #allInstances.FormInstanceId = @FormInstanceID



--DROP TABLE #FormInstanceIDs



-- END OF Add Yes_VS_No calculation here - insert into =============================================================================
END

SELECT  FormInstanceID,QStatus 
INTO #yes_or_no
FROM #smi_report_basic 
WHERE FormInstanceID = 754732
AND (QStatus = 'Yes' OR QStatus ='No')


select (Select DISTINCT #yes_or_no.FormInstanceID) as FormInstanceID
,#yes_or_no.QStatus
,(SELECT COUNT(#yes_or_no.QStatus) WHERE #yes_or_no.QStatus = 'Yes')  AS 'Yes'
,(SELECT COUNT(#yes_or_no.QStatus) WHERE #yes_or_no.QStatus = 'No') AS 'No' 
INTO #yes_no_values
FROM #yes_or_no 
WHERE #yes_or_no.FormInstanceID = 754732
GROUP BY #yes_or_no.FormInstanceID,#yes_or_no.QStatus


SELECT DISTINCT #yes_no_values.FormInstanceID AS FormInstanceID
,(select #yes_no_values.Yes from #yes_no_values WHERE #yes_no_values.Yes IS NOT NULL) AS YesValue
,(select #yes_no_values.No from #yes_no_values WHERE #yes_no_values.No IS NOT NULL) AS NoValue
,((select #yes_no_values.Yes from #yes_no_values WHERE #yes_no_values.Yes IS NOT NULL) + (SELECT #yes_no_values.No from #yes_no_values WHERE #yes_no_values.No IS NOT NULL)) AS TotalValue
,(select #yes_no_values.No from #yes_no_values WHERE #yes_no_values.No IS NOT NULL) / ((((select #yes_no_values.Yes from #yes_no_values WHERE #yes_no_values.Yes IS NOT NULL) + (SELECT #yes_no_values.No from #yes_no_values WHERE #yes_no_values.No IS NOT NULL)))/100.00) AS PerCentValue
INTO #YesNoPercent
FROM #yes_no_values 

select * from #YesNoPercent


DROP TABLE #allInstances
DROP TABLE #gor_to_region
DROP TABLE #smi_report_basic
DROP TABLE #yes_or_no
DROP TABLE #yes_no_values 
DROP TABLE #YesNoPercent
------------------------------------------------------------------------------------------------------------------------

--SELECT DISTINCT #smi_report_basic.FormInstanceID 
--INTO #FormInstanceIDs
--FROM #smi_report_basic

--select * from #FormInstanceIDs







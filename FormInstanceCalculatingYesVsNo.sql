
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
AND CreatedDate BETWEEN '2017-01-01 00:00:00.000' AND '2017-01-31 23:59:59.999'--'2017-03-30 17:30:00.000' AND '2017-03-30 23:59:00.000'

-- The problem is in FormInstanceID = 786259 TimeFrame  '2017-03-30 16:30:00.000' AND '2017-03-30 18:00:00.000'
-- However FromInstanceID = 786356 (next in line) TimeFrame '2017-03-30 16:30:00.000' AND '2017-03-30 18:00:00.000' does not have the same issue
-- The issue indeed is in the SP ReportsGetSecurityInspectionFormHeaderDetails001 at line 29 where the following line of code starts:


--Get All the header information for the submitted form
--WITH FormHeader AS(
--SELECT sr.Code
--		, fv.Value
--FROM FormDefinition fd (NOLOCK)
--		INNER JOIN FormInstance fi (NOLOCK) ON fi.FormDefinitionId = fd.FormDefinitionId
--		INNER JOIN FieldValue fv (NOLOCK) ON fv.FormInstanceId = fi.FormInstanceId
--		INNER JOIN FieldDefinition fid (NOLOCK) ON fid.FieldDefinitionId = fv.FieldDefinitionId
--		...



--SELECT * from #allInstances

SET @numberOfInstances = (SELECT COUNT(*) FROM #allInstances)

--SELECT TOP 1 #allInstances.FormInstanceId from #allInstances
--SELECT TOP 1 * FROM #allInstances

--select @numberOfInstances AS NumberOFInstances


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




-- Create a temp table to store the @FormInstanceIDs that are being processed in order to figure out why the 'string or binary data would be truncated' Error in the SP at line 29
--USE MobileForms;
--CREATE TABLE [MobileForms].[dbo].[FormInstanceProcessed] (FormInstanceID INT)



-- ===========



DELETE FROM [MobileForms].[dbo].[FormInstanceProcessed]

--select from [MobileForms].[dbo].[FormInstanceProcessed].

WHILE ( @licznik ) < (@numberOfInstances)
 
BEGIN
--START THE TRY BLOCK =====================================================================================================================
   
   --BEGIN TRY
   
   	SET @FormInstanceID =  (SELECT TOP 1 #allInstances.FormInstanceId from #allInstances)
	
	--PLease run againg
	--OK
   	--PRINT FORMINSTANCEID
	PRINT @FormInstanceID

	INSERT INTO [MobileForms].[dbo].FormInstanceProcessed VALUES (@FormInstanceID,@licznik)

   	set @licznik = @licznik + 1
   	
	--INSERT INTO #smi_report EXEC [dbo].[ReportsGetSecurityInspectionFormHeaderDetails001] @FormInstanceID
	--In this part, some FormInstanceID returns data with invalid lenght

	BEGIN TRY
	INSERT INTO #smi_report_basic EXEC [dbo].[ReportsGetSecurityInspectionFormHeaderDetails001] @FormInstanceID 
	END TRY
	BEGIN CATCH
	END CATCH
	-- Add Yes_VS_No calculation here - insert into  =================================================================================================================

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

--select * from #yes_no_values WHERE #yes_no_values.FormInstanceID = @FormInstanceID AND #yes_no_values.Yes > 0 
--select #yes_no_values.Yes from #yes_no_values WHERE #yes_no_values.Yes IS NOT NULL AND #yes_no_values.FormInstanceID = @FormInstanceID

DECLARE @p DECIMAL(4,2)

SET @p = 0.00

--SELECT CASE WHEN @n_final < 1 THEN (SET @p = 0.00) END

SET @p = (SELECT CASE WHEN (@n_final + @y_final)  = 0  THEN 77.77 ELSE (CAST((@n_final / ((@y_final + @n_final)/100.00)) AS DECIMAL(4,2))) END)

SELECT DISTINCT #yes_no_values.FormInstanceID AS FormInstanceID
,@y_final AS YesValue
,@n_final AS NoValue
,@y_final + @n_final AS TotalValue
,@p as p 
, (SELECT CASE WHEN @p < 90.00 THEN 0 WHEN @p >= 90.00 THEN 1 END) AS Reinspection
INTO #YesNoPercent
FROM #yes_no_values WHERE #yes_no_values.FormInstanceID = @FormInstanceID

select * from #YesNoPercent 
--SELECT TOP 1 #allInstances.FormInstanceId AS TOP1_FROM_allInstances FROM #allInstances


--END TRY
--BEGIN CATCH
--PRINT ERROR_NUMBER()
--PRINT ERROR_MESSAGE()
--    SELECT   
--		@FormInstanceID
--        ,ERROR_NUMBER() AS ErrorNumber  
--       ,ERROR_MESSAGE() AS ErrorMessage;  
--END CATCH

--END TRY =============================================================================================================================================


--BEGIN CATCH
--show the top 1 of #allinstances
--END CATCH

DELETE FROM #allInstances WHERE #allInstances.FormInstanceId = @FormInstanceID

--DROP TABLE #FormInstanceIDs

DROP TABLE #yes_or_no
DROP TABLE #yes_no_values 
DROP TABLE #YesNoPercent

-- END OF Add Yes_VS_No calculation here - insert into =============================================================================

END

DROP TABLE #allInstances
DROP TABLE #gor_to_region
DROP TABLE #smi_report_basic
------------------------------------------------------------------------------------------------------------------------







-- go on 
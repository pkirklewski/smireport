
DECLARE @formInstanceId INT
SET @formInstanceId = 786356 -- Problematc FormInstanceID: 786259

DECLARE @FormInstanceCreatedDate VARCHAR(255)
--SET @formInstanceId = 754732
SET @FormInstanceCreatedDate = (SELECT FormInstance.CreatedDate FROM FormInstance WHERE FormInstance.FormInstanceId = @formInstanceId)


BEGIN
WITH FormHeader AS(
SELECT sr.Code
		, fv.Value
FROM FormDefinition fd (NOLOCK)
		INNER JOIN FormInstance fi (NOLOCK) ON fi.FormDefinitionId = fd.FormDefinitionId
		INNER JOIN FieldValue fv (NOLOCK) ON fv.FormInstanceId = fi.FormInstanceId
		INNER JOIN FieldDefinition fid (NOLOCK) ON fid.FieldDefinitionId = fv.FieldDefinitionId
		INNER JOIN SystemRef sr (NOLOCK) ON sr.SystemRefId = fid.SystemRefId
WHERE fd.IsMaster = 1
and fi.FormInstanceId = @formInstanceId
)

--Get all the latest questions from Process library and Assign observation and aspect to the questions.
, Questions As(
SELECT   QNum
	   , QCount + '. ' + Questions Questions
	   , CASE   WHEN QCount IN (5, 7, 11, 14, 16, 17, 18, 19, 21, 22, 25, 38, 47, 54, 56, 61, 64, 65, 66, 71, 75, 77, 78, 80, 81) THEN 5
				WHEN QCount IN (6, 9, 20, 48, 50, 52, 58, 69, 70) THEN 10
				ELSE 1
		 END WeightedScores
	   , CASE   WHEN QNum between  1 and 19 THEN 'Assignment Log Book'
				WHEN QNum between 20 and 22 THEN 'Porterage'
				WHEN QNum between 23 and 45 THEN 'Keys'
				WHEN QNum between 46 and 65 THEN 'CCTV'
				WHEN QNum between 66 and 70 THEN 'Panic Alarm Testing'
				WHEN QNum = 71			    THEN 'ID'
				WHEN QNum IN (72,73)		THEN 'Uniform'
				WHEN QNum between 74 and 76 THEN 'Designated Security Area'
				WHEN QNum between 77 and 81 THEN 'Management Visits'
				WHEN QNum between 82 and 85 THEN 'Training'
				WHEN QNum = 86				THEN 'F0880'
				ELSE 'Unknown'
			END	Aspect
		, CASE  WHEN QNum between  1 and 19 THEN 1
				WHEN QNum between 20 and 22 THEN 2
				WHEN QNum between 23 and 45 THEN 3
				WHEN QNum between 46 and 65 THEN 4
				WHEN QNum between 66 and 70 THEN 5
				WHEN QNum = 71				THEN 6
				WHEN QNum IN (72,73)		THEN 7
				WHEN QNum between 74 and 76 THEN 8
				WHEN QNum between 77 and 81 THEN 9
				WHEN QNum between 82 and 85 THEN 10
				WHEN QNum = 86				THEN 11
				ELSE 12
			END	AspectSort
	   
FROM
	(SELECT fid.Label Questions
			, RTRIM(LTRIM(REPLACE(sr.Code,'Q', ''))) QNum
			, CAST(ROW_NUMBER() OVER (Order by FieldDefinitionId) as varchar(3)) QCount
			, FieldDefinitionId
	FROM	Process p (NOLOCK)
			INNER JOIN FormDefinition fd (NOLOCK) on fd.ProcessId = p.ProcessId
			INNER JOIN FormPage fp (NOLOCK) ON fd.FormDefinitionId = fp.FormDefinitionId
			INNER JOIN FormPageSection fps (NOLOCK) ON fp.FormPageId = fps.FormPageId
			INNER JOIN FieldDefinition fid (NOLOCK) ON fid.FormPageSectionId = fps.FormPageSectionId
			INNER JOIN SystemRef sr (NOLOCK) ON sr.SystemRefId = fid.SystemRefId
	WHERE ProcessCode = 'SMI' 
	AND left(sr.Code,1) = 'Q'
	AND fd.[FormDefinitionId] = (SELECT MAX([FormDefinitionId])
								FROM FormDefinition fd (NOLOCK)
								WHERE FormNumber = 'SMI')
	) t
)

--Get the Relevant WO for the questions. Few questions have more than one WO.
--Concatanate multiple WO to display in output report.
, WorkOrderNumber AS(
SELECT t1.QNum
		, ISNULL(t1.WorkOrderNumber, '') + 
		  CASE WHEN t2.WorkOrderNumber IS NOT NULL 
					THEN ' ,' + ISNULL(t2.WorkOrderNumber, '') 
				    ELSE '' 
		  END WorkOrderNumber
		, t1.WorkOrderDescription
FROM 
	(SELECT  CASE SDMRef  
					 WHEN 'SDMREF0041' THEN '6'
					 WHEN 'SDMREF0001' THEN '9'
					 WHEN 'SDMREF0002' THEN '17'
					 WHEN 'SDMREF0042' THEN '18'
					 WHEN 'SDMREF0043' THEN '19'
					 WHEN 'SDMREF0044' THEN '20'
					 WHEN 'SDMREF0045' THEN '21'
					 WHEN 'SDMREF0003' THEN '22'
					 WHEN 'SDMREF0004' THEN '49'
					 WHEN 'SDMREF0005' THEN '50'
					 WHEN 'SDMREF0049' THEN '72'
					 WHEN 'SDMREF0006' THEN '73'
			END QNum
			, WorkOrderNumber
			, WorkOrderDescription
	FROM WorkOrderDetailView (NOLOCK)
	WHERE FormInstanceId = @formInstanceId
	AND SDMRef NOT IN ('SDMREF0046', 'SDMREF0048')) t1
LEFT JOIN 
	(SELECT  CASE SDMRef  
					 WHEN 'SDMREF0046' THEN '49'
					 WHEN 'SDMREF0048' THEN '50'
			 END QNum
			, WorkOrderNumber
	FROM WorkOrderDetailView  (NOLOCK)
	WHERE FormInstanceId = @formInstanceId
	AND SDMRef IN ('SDMREF0046', 'SDMREF0048')) t2
ON t1.QNum = t2.QNum
)


--Get the Answers to the Questions (Yes/No/NA)
, FormHeaderQStatus AS(
SELECT Code Question
		, REPLACE(Code, 'Q', '')  QNum
		, Value QStatus
FROM FormHeader
WHERE LEFT(Code, 1) = 'Q'
)

--Get the Comments to the Questions when the Answer is No
, FormHeaderQComments AS(
SELECT Code Question
		, REPLACE(Code, 'Comments', '')  QNum
		, Value QComments
FROM FormHeader
WHERE LEFT(Code, 8) = 'Comments'
)

--Get the Severity status for Question 49
, Q49Severity As (
SELECT  '49' QNum
		, Value Severity
FROM FormHeader
WHERE Code = 'SEVERITY'
)

--Main Query. Joins all the CTE's to form the output query.
SELECT    
@formInstanceId FormInstanceID
,@FormInstanceCreatedDate CreatedDate
,q.Questions
		, q.QNum
		, CASE QStatus 
				WHEN 'Yes' THEN 1
				ELSE 0
		   END QStatusInt
		, CASE QStatus 
				WHEN 'Yes' THEN 1
				WHEN 'No'  THEN 1
		   END QuestionCount
		, CASE QStatus
				WHEN 'Yes' THEN q.WeightedScores
			    WHEN 'No'  THEN q.WeightedScores
			    ELSE 0
		    END WeightedScores
		, CASE  WHEN q.QNum IN ('9', '17', '22', '49', '50', '71', '73')	THEN 'Work Order'
				WHEN q.QNum IN ('6', '18', '19', '20', '21', '72')			THEN 'PMS Reportable'
				ELSE 'Observation'
		  END Observation
		, q.Aspect
		, q.AspectSort
		, s.QStatus
		, ISNULL(c.QComments, '') + ISNULL(WorkOrderDescription, '') QComments
		, CASE WHEN s.QNum = '71' and s.QStatus = 'No' THEN '1HR24'
			   WHEN s.QNum = '49' and q49.Severity = 'Crisis (1HR24 Work Order)' THEN ISNULL(w.WorkOrderNumber, '') + ', 1HR24'
			   WHEN s.QNum = '49' and q49.Severity = 'Urgent (24HR Work order)'  THEN ISNULL(w.WorkOrderNumber, '') + ', 24HR'
		  ELSE w.WorkOrderNumber END WorkOrderNumber		
FROM Questions q
		LEFT JOIN FormHeaderQStatus		s	ON s.QNum = q.QNum
		LEFT JOIN FormHeaderQComments	c   ON s.QNum = c.QNum
		LEFT JOIN WorkOrderNumber		w   ON s.QNum = w.QNum
		LEFT JOIN Q49Severity			q49	ON s.QNum = q49.QNum
END
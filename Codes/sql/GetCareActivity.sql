WITH snomed AS (
  SELECT
    CAST(Concept_ID AS NVARCHAR) AS concept_id,
    LEFT(Term, CHARINDEX(' (', Term + ' (') - 1) AS term,
    TYPE_ID AS type,
    COALESCE(Effective_From, '1970-01-01 00:00:01.000') AS effective_from,
    COALESCE(Effective_To, '2022-01-01 00:00:01.000') AS effective_to
  FROM 
    [UK_Health_Dimensions].[SNOMED].[Descriptions_SCD]
  WHERE
    Active = 1
    AND Type_ID = '900000000000003001'
),
care_activities AS (
	SELECT
		CareContactId AS care_contact_id,
		CASE
			WHEN CHARINDEX(':', CodeProcAndProcStatus) > 0 THEN LEFT(CodeProcAndProcStatus, CHARINDEX(':', CodeProcAndProcStatus) - 1)
			ELSE CodeProcAndProcStatus
		END AS code,
		ReportingPeriodStartDate AS report_date,
		Pseudo_NHS_Number AS nhs_number
	FROM
		[Warehouse_LDM].[dbo].[v_SF_Latest_CareActivity]
)
SELECT
	ca.*,
	s.term
FROM
	care_activities ca
LEFT JOIN snomed s ON
	ca.code = s.concept_id
	AND ca.report_date >= s.effective_from
	AND ca.report_date <= s.effective_to;
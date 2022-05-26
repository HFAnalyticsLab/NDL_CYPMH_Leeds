WITH ethnic_lookup AS (
	SELECT 
		Main_Code_Text AS code, 
		Category AS ethnic_group
	FROM 
		[UK_Health_Dimensions].[Data_Dictionary].[Ethnic_Category_Code_SCD]
	WHERE 
		Is_Latest = 1
)
SELECT
	Spell_ID AS spell_id,
	Episode_Number AS spell_no,
	NHS_Number AS nhs_number,
  Age_At_Start_Of_Episode AS ip_age,
  Sex AS sex,
  ethnic_group,
  Method_of_Admission_Code AS method_of_admission,
  Destination_on_Discharge_Code AS discharge_destination,
  Discharge_Method_Code AS discharge_method,
  Source_of_Admission_Code AS source_of_admission,
  ADMISSION_DATE AS admission_date,
  DISCHARGE_DATE AS discharge_date,
  Episode_Number AS episode_number,
  Last_In_Spell_Indicator AS last_in_spell_no,
  Procedure_Status AS procedure_status,
  Episode_Start_Date AS episode_start_date,
  Episode_End_Date AS episode_end_date,
  Diag_Version AS diagnosis_version,
  Primary_Diagnosis AS primary_diagnosis,
  Primary_Operative_Procedure AS primary_procedure,
  Secondary_Diagnosis_1 AS secondary_1,
  Secondary_Diagnosis_2 AS secondary_2,
  Secondary_Diagnosis_3 AS secondary_3,
  Secondary_Diagnosis_4 AS secondary_4,
  Secondary_Diagnosis_5 AS secondary_5,
  Secondary_Diagnosis_6 AS secondary_6,
  Secondary_Diagnosis_7 AS secondary_7,
  Secondary_Diagnosis_8 AS secondary_8,
  Secondary_Diagnosis_9 AS secondary_9,
  Secondary_Diagnosis_10 AS secondary_10,
  Secondary_Diagnosis_11 AS secondary_11,
  Secondary_Diagnosis_12 AS secondary_12,
  PODCode AS pod_code,
  Provider_ID AS provider_id,
  Practice_Code AS practice_code,
  Postcode_of_Usual_Address AS lsoa
FROM
	[Warehouse_LDM].[dbo].[Pseudo_IP_Data_FY<XYXY>] ip
LEFT JOIN ethnic_lookup el ON
  ip.Ethnic_Origin = el.code
WHERE
	Age_At_Start_Of_Episode > 10
	AND Age_At_Start_Of_Episode < 26
	AND	(
-- Secondary Diagnosis 1
		Secondary_Diagnosis_1 LIKE 'X6%' 
	  OR Secondary_Diagnosis_1 LIKE 'X7%'
		OR Secondary_Diagnosis_1 LIKE 'X80%'
		OR Secondary_Diagnosis_1 LIKE 'X81%'
		OR Secondary_Diagnosis_1 LIKE 'X82%'
		OR Secondary_Diagnosis_1 LIKE 'X83%'
		OR Secondary_Diagnosis_1 LIKE 'X84%'
-- Secondary Diagnosis 2
		OR Secondary_Diagnosis_2 LIKE 'X6%' 
		OR Secondary_Diagnosis_2 LIKE 'X7%'
		OR Secondary_Diagnosis_2 LIKE 'X80%'
		OR Secondary_Diagnosis_2 LIKE 'X81%'
		OR Secondary_Diagnosis_2 LIKE 'X82%'
		OR Secondary_Diagnosis_2 LIKE 'X83%'
		OR Secondary_Diagnosis_2 LIKE 'X84%'
-- Secondary Diagnosis 3
		OR Secondary_Diagnosis_3 LIKE 'X6%' 
		OR Secondary_Diagnosis_3 LIKE 'X7%'
		OR Secondary_Diagnosis_3 LIKE 'X80%'
		OR Secondary_Diagnosis_3 LIKE 'X81%'
		OR Secondary_Diagnosis_3 LIKE 'X82%'
		OR Secondary_Diagnosis_3 LIKE 'X83%'
		OR Secondary_Diagnosis_3 LIKE 'X84%'
-- Secondary Diagnosis 4
		OR Secondary_Diagnosis_4 LIKE 'X6%' 
		OR Secondary_Diagnosis_4 LIKE 'X7%'
		OR Secondary_Diagnosis_4 LIKE 'X80%'
		OR Secondary_Diagnosis_4 LIKE 'X81%'
		OR Secondary_Diagnosis_4 LIKE 'X82%'
		OR Secondary_Diagnosis_4 LIKE 'X83%'
		OR Secondary_Diagnosis_4 LIKE 'X84%'
-- Secondary Diagnosis 5
		OR Secondary_Diagnosis_5 LIKE 'X6%' 
		OR Secondary_Diagnosis_5 LIKE 'X7%'
		OR Secondary_Diagnosis_5 LIKE 'X80%'
		OR Secondary_Diagnosis_5 LIKE 'X81%'
		OR Secondary_Diagnosis_5 LIKE 'X82%'
		OR Secondary_Diagnosis_5 LIKE 'X83%'
		OR Secondary_Diagnosis_5 LIKE 'X84%'
-- Secondary Diagnosis 6
		OR Secondary_Diagnosis_6 LIKE 'X6%' 
		OR Secondary_Diagnosis_6 LIKE 'X7%'
		OR Secondary_Diagnosis_6 LIKE 'X80%'
		OR Secondary_Diagnosis_6 LIKE 'X81%'
		OR Secondary_Diagnosis_6 LIKE 'X82%'
		OR Secondary_Diagnosis_6 LIKE 'X83%'
		OR Secondary_Diagnosis_6 LIKE 'X84%'
-- Secondary Diagnosis 7
		OR Secondary_Diagnosis_7 LIKE 'X6%' 
		OR Secondary_Diagnosis_7 LIKE 'X7%'
		OR Secondary_Diagnosis_7 LIKE 'X80%'
		OR Secondary_Diagnosis_7 LIKE 'X81%'
		OR Secondary_Diagnosis_7 LIKE 'X82%'
		OR Secondary_Diagnosis_7 LIKE 'X83%'
		OR Secondary_Diagnosis_7 LIKE 'X84%'
-- Secondary Diagnosis 8
		OR Secondary_Diagnosis_8 LIKE 'X6%' 
		OR Secondary_Diagnosis_8 LIKE 'X7%'
		OR Secondary_Diagnosis_8 LIKE 'X80%'
		OR Secondary_Diagnosis_8 LIKE 'X81%'
		OR Secondary_Diagnosis_8 LIKE 'X82%'
		OR Secondary_Diagnosis_8 LIKE 'X83%'
		OR Secondary_Diagnosis_8 LIKE 'X84%'
-- Secondary Diagnosis 9
		OR Secondary_Diagnosis_9 LIKE 'X6%' 
		OR Secondary_Diagnosis_9 LIKE 'X7%'
		OR Secondary_Diagnosis_9 LIKE 'X80%'
		OR Secondary_Diagnosis_9 LIKE 'X81%'
		OR Secondary_Diagnosis_9 LIKE 'X82%'
		OR Secondary_Diagnosis_9 LIKE 'X83%'
		OR Secondary_Diagnosis_9 LIKE 'X84%'
-- Secondary Diagnosis 10
		OR Secondary_Diagnosis_10 LIKE 'X6%' 
		OR Secondary_Diagnosis_10 LIKE 'X7%'
		OR Secondary_Diagnosis_10 LIKE 'X80%'
		OR Secondary_Diagnosis_10 LIKE 'X81%'
		OR Secondary_Diagnosis_10 LIKE 'X82%'
		OR Secondary_Diagnosis_10 LIKE 'X83%'
		OR Secondary_Diagnosis_10 LIKE 'X84%'
-- Secondary Diagnosis 11
		OR Secondary_Diagnosis_11 LIKE 'X6%' 
		OR Secondary_Diagnosis_11 LIKE 'X7%'
		OR Secondary_Diagnosis_11 LIKE 'X80%'
		OR Secondary_Diagnosis_11 LIKE 'X81%'
		OR Secondary_Diagnosis_11 LIKE 'X82%'
		OR Secondary_Diagnosis_11 LIKE 'X83%'
		OR Secondary_Diagnosis_11 LIKE 'X84%'
-- Secondary Diagnosis 12
		OR Secondary_Diagnosis_12 LIKE 'X6%' 
		OR Secondary_Diagnosis_12 LIKE 'X7%'
		OR Secondary_Diagnosis_12 LIKE 'X80%'
		OR Secondary_Diagnosis_12 LIKE 'X81%'
		OR Secondary_Diagnosis_12 LIKE 'X82%'
		OR Secondary_Diagnosis_12 LIKE 'X83%'
		OR Secondary_Diagnosis_12 LIKE 'X84%'
	);
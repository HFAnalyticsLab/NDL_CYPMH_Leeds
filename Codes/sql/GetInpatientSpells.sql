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
    NHS_Number AS nhs_number,
    Age_At_Start_Of_Episode AS ip_age,
    Method_of_Admission_Code AS method_of_admission,
    Destination_on_Discharge_Code AS discharge_destination,
    Discharge_Method_Code AS discharge_method,
    Source_of_Admission_Code AS source_of_admission,
    ADMISSION_DATE AS admission_date,
    DISCHARGE_DATE AS discharge_date,
    Episode_Number AS episode_number,
    Last_In_Spell_Indicator AS last_in_spell_flag,
    Procedure_Status AS procedure_status,
    Episode_Start_Date AS episode_start_date,
    Episode_End_Date AS episode_end_date,
--    Spell_Report_Flag AS spell_report_flag,
    Diag_Version AS diagnosis_version,
    Primary_Diagnosis AS primary_diagnosis,
    Primary_Operative_Procedure AS primary_procedure,
    PODCode AS pod_code,
    ethnic_group,
    Postcode_of_Usual_Address AS lsoa
  FROM
    [Warehouse_LDM].[dbo].[Pseudo_IP_Data_FY<XYXY>] ip
  LEFT JOIN ethnic_lookup el ON
    ip.Ethnic_Origin = el.code
  WHERE 
    --PODCode LIKE '%NEL%'
    NHS_Number IN ('<nhs_number>');
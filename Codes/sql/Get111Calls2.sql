WITH covid AS (
	SELECT DISTINCT
		NHSNumber_PSEUDO AS nhs_number,
		Ethnicity AS ethnicity
	FROM
		[Warehouse_LDM].[covid19].[COVID19_Patient_List_COMMISSIONING_LDM_New]
),
ethnic_lookup AS (
	SELECT 
		Main_Code_Text AS code, 
		Category AS ethnic_group
	FROM 
		[UK_Health_Dimensions].[Data_Dictionary].[Ethnic_Category_Code_SCD]
	WHERE 
		Is_Latest = 1
),
ae AS (
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_AE_Data_FY1617] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_AE_Data_FY1718] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_AE_Data_FY1819] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_AE_Data_FY1920] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_AE_Data_FY2021] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
),
ip AS (
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_IP_Data_FY1617] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_IP_Data_FY1718] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_IP_Data_FY1819] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_IP_Data_FY1920] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_IP_Data_FY2021] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
),
op AS (
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_OP_Data_FY1617] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_OP_Data_FY1718] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_OP_Data_FY1819] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_OP_Data_FY1920] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
	UNION
	(SELECT DISTINCT 
		NHS_Number AS nhs_number,
		ethnic_group
	FROM [Warehouse_LDM].[dbo].[Pseudo_OP_Data_FY2021] a
	LEFT JOIN ethnic_lookup el ON
		a.Ethnic_Origin = el.code)
),
symptoms AS (
  SELECT DISTINCT
    Symptom_Type_1 AS code,
    Symptom_Type_1_Desc AS symptom_1
  FROM
    [Warehouse_LDM].[yas].[YAS_111]
  WHERE
	Symptom_Type_1_Desc IS NOT NULL
),
yas AS (
  (SELECT
    PSEUDO_NHS_No AS nhs_number,
    Age AS age,
    Sex AS sex,
    Reg_Practice AS gpp_code,
    Call_Commenced_Date_Time AS call_date,
    Symptom_Type_1_Desc AS symptom_1
  FROM 
    [Warehouse_LDM].[yas].[YAS_111]
  WHERE 
    Symptom_Type_1 IN (
      4044, 
      4053, 
      4177, 
      4178, 
      4179, 
      4205, 
      4206, 
      4207, 
      4208, 
      4209, 
      4211, 
      4238, 
      4244, 
      4245, 
      4303
    ) 
    AND Age > 10
    AND Age < 26)
    
    UNION
    
    (SELECT
    [PSEUDO_NHS Number] AS nhs_number,
    Age AS age,
    Sex AS sex,
    [GP Surgery ID] AS gpp_code,
    Call_Commenced_Date_Time AS call_date,
    symptom_1
  FROM 
    [Warehouse_LDM].[iucadc].[Local_111_MDS_RX8]
  LEFT JOIN symptoms s ON
    [Final Symptom Discriminator] = s.code
  WHERE 
    [Final Symptom Discriminator] IN (
      4044, 
      4053, 
      4177, 
      4178, 
      4179, 
      4205, 
      4206, 
      4207, 
      4208, 
      4209, 
      4211, 
      4238, 
      4244, 
      4245, 
      4303
    ) 
    AND Age > 10
    AND Age < 26)
)
SELECT
	COALESCE(
		c.ethnicity, 
		ae.ethnic_group, 
		ip.ethnic_group, 
		op.ethnic_group
	) AS ethnicity,
	c.ethnicity AS covid_ethnicity, 
	ae.ethnic_group AS ae_ethnicity, 
	ip.ethnic_group AS ip_ethnicity, 
	op.ethnic_group AS op_ethnicity,
	y.*
FROM
	yas y
LEFT JOIN covid c ON
	y.nhs_number = c.nhs_number
LEFT JOIN ae ON
	y.nhs_number = ae.nhs_number
LEFT JOIN ip ON
	y.nhs_number = ip.nhs_number
LEFT JOIN op ON
	y.nhs_number = op.nhs_number;
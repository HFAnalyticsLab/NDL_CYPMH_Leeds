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
iapt AS (
	(SELECT DISTINCT 
		PSEUDO_NHSNumber AS nhs_number,
		ethnic_group
	FROM
		[Warehouse_LDM].[iapt].[IDS001MPI] a
	LEFT JOIN [Warehouse_LDM].[iapt].[Bridging] b ON
		a.Person_ID = b.Person_ID
	LEFT JOIN ethnic_lookup el ON
		a.EthnicCategory = el.code)
	UNION
	(SELECT DISTINCT 
		PSEUDO_NHS_Number AS nhs_number,
		ethnic_group
	FROM
		[Warehouse_LDM].[iapt_v1.5].[Patient] a
	LEFT JOIN [Warehouse_LDM].[iapt_v1.5].[Bridging] b ON
		a.IAPT_PERSON_ID = b.Person_ID
	LEFT JOIN ethnic_lookup el ON
		a.ETHNICITY = el.code)
),
yas AS (
	SELECT DISTINCT
		PSEUDO_NHS_No AS nhs_number,
		ethnic_group
	FROM
		[Warehouse_LDM].[yas].[YAS_111] a
	LEFT JOIN ethnic_lookup e ON
		a.Ethnic_Category = e.code
)
SELECT DISTINCT
	PSEUDO_DEC_NHS_NUMBER AS nhs_number,
	COALESCE(
		ae.ethnic_group,
		ip.ethnic_group,
		op.ethnic_group,
		iapt.ethnic_group,
		yas.ethnic_group
	) AS ethnic_group,
	CASE 
		WHEN DEC_SEX = 1 THEN 'M' 
		WHEN DEC_SEX = 2 THEN 'F'
		ELSE DEC_SEX 
	END AS sex,
	DEC_AGEC AS age,
	REG_DATE_OF_DEATH AS date_of_death,
	S_UNDERLYING_COD_ICD10 AS underlying_icd10
FROM
	[Warehouse_LDM].[crd].[Deaths] d
LEFT JOIN ae ON
	d.PSEUDO_DEC_NHS_NUMBER = ae.nhs_number
LEFT JOIN ip ON
	d.PSEUDO_DEC_NHS_NUMBER = ip.nhs_number
LEFT JOIN op ON
	d.PSEUDO_DEC_NHS_NUMBER = op.nhs_number
LEFT JOIN iapt ON
	d.PSEUDO_DEC_NHS_NUMBER = iapt.nhs_number
LEFT JOIN yas ON
	d.PSEUDO_DEC_NHS_NUMBER = yas.nhs_number
WHERE
	REG_DATE_OF_DEATH >= '2016-04-01'
	AND REG_DATE_OF_DEATH <= '2021-03-31'
	AND DEC_AGEC > 10
	AND DEC_AGEC < 26
	AND (
		S_UNDERLYING_COD_ICD10 LIKE 'X6%' 
			OR S_UNDERLYING_COD_ICD10 LIKE 'X7%'
			OR S_UNDERLYING_COD_ICD10 LIKE 'X80%'
			OR S_UNDERLYING_COD_ICD10 LIKE 'X81%'
			OR S_UNDERLYING_COD_ICD10 LIKE 'X82%'
			OR S_UNDERLYING_COD_ICD10 LIKE 'X83%'
			OR S_UNDERLYING_COD_ICD10 LIKE 'X84%' 
		);
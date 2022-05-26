WITH patient_sex AS (
	SELECT
		Main_Code_Text,
		Main_Description AS gender
	FROM
		[UK_Health_Dimensions].[Data_Dictionary].[Sex_Of_Patients_Code_SCD]
	WHERE
		IS_Latest = 1
),
ethnicity_lookup AS (
	SELECT
		Main_Code_Text,
		Main_Description AS ethnicity
	FROM
		[UK_Health_Dimensions].[Data_Dictionary].[Ethnic_Category_Code_SCD]
	WHERE
		IS_Latest = 1
),
psych_qof_flags AS (
	SELECT DISTINCT
		Patient_Pseudonym AS nhs_number,
		CASE 
			WHEN schizophrenia_condition != 'NP' THEN 1
			WHEN bipolar_disorder_condition != 'NP' THEN 1
			ELSE 0
		END AS smi,
		CASE 
			WHEN depression_condition != 'NP' THEN 1
			ELSE 0
		END AS depression
	FROM 
		[Warehouse_LDMPC].[dbo].[EMIS_ACG_Patient_Details]
	UNION
	SELECT DISTINCT
		Patient_Pseudonym AS nhs_number,
		CASE 
			WHEN schizophrenia_condition != 'NP' THEN 1
			WHEN bipolar_disorder_condition != 'NP' THEN 1
			ELSE 0
		END AS smi,
		CASE 
			WHEN depression_condition != 'NP' THEN 1
			ELSE 0
		END AS depression
	FROM 
		[Warehouse_LDMPC].[dbo].[TPP_ACG_Patient_Details]
),
mhsds_bridging AS (
	SELECT DISTINCT
		Person_Id AS patient_id,
		Pseudo_NHS_Number AS nhs_number
	FROM
		[Warehouse_LDM].[mhsds_v4].[Bridging]
	UNION
	SELECT DISTINCT
		Person_Id AS patient_id,
		Pseudo_NHS_Number AS nhs_number
	FROM
		[Warehouse_LDM].[mhsds_v3].[Bridging]
	UNION
	SELECT DISTINCT
		Person_Id AS patient_id,
		PSEUDO_NHSNumber AS nhs_number
	FROM
		[Warehouse_LDM].[mhsds].[Bridging]
),
patients AS (
	SELECT
		COALESCE(Person_ID, UniqMHSDSPersID) AS patient_id,
		ps.gender,
		AgeRepPeriodEnd AS age,
		LSOA2011 AS lsoa,
		UniqMonthId AS month_id,
		ethnicity,
		Pseudo_NHS_Number AS nhs_number
	FROM
		[Warehouse_LDM].[dbo].[v_SF_Latest_MPI] mpi
	LEFT JOIN patient_sex ps ON
		mpi.Gender = ps.Main_Code_Text
	LEFT JOIN ethnicity_lookup el ON
		mpi.EthnicCategory = el.Main_Code_Text
)
SELECT
	p.*,
	pq.smi AS known_smi,
	pq.depression AS known_depression
FROM
	patients p
LEFT JOIN mhsds_bridging mb ON
	p.patient_id = mb.patient_id
LEFT JOIN psych_qof_flags pq ON
	mb.nhs_number = pq.nhs_number;
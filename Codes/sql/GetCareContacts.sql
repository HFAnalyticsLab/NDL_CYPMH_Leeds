WITH consultation_lookup AS (
	SELECT 
		Main_Code_Text,
		Main_Description AS consultation_medium
	FROM	
		[UK_Health_Dimensions].[Data_Dictionary].[Consultation_Medium_Used_SCD]
	WHERE
		Is_Latest = 1
),
location_lookup AS (
	SELECT
		Main_Code_Text,
		Main_Description AS activity_location
	FROM
		[UK_Health_Dimensions].[Data_Dictionary].[Activity_Location_Type_Code_SCD]
	WHERE
		IS_Latest = 1
),
attendance_lookup AS (
	SELECT
		Main_Code_Text,
		Main_Description AS attendance_type
	FROM
		[UK_Health_Dimensions].[Data_Dictionary].[Attended_Or_Did_Not_Attend_SCD]
	WHERE
		IS_Latest = 1
),
p1 AS (
	SELECT 
		Organisation_Code,
		Organisation_Name
	FROM
		[UK_Health_Dimensions].[ODS].[All_Providers_and_purchasers_SCD]
	WHERE
		Is_Latest = 1
),
p2 AS (
	SELECT 
		Organisation_Code_5_Char,
		Organisation_Name
	FROM
		[UK_Health_Dimensions].[ODS].[All_Providers_SCD]
	WHERE
		Is_Latest = 1
),
p3 AS (
	SELECT 
		Organisation_Code,
		Organisation_Name
	FROM
		[UK_Health_Dimensions].[ODS].[NHS_Trusts_And_Trust_Sites_SCD]
	WHERE
		Is_Latest = 1
),
p4 AS (
	SELECT 
		Organisation_Code,
		Organisation_Name
	FROM
		[UK_Health_Dimensions].[ODS].[NonNHS_Organisations_SCD]
	WHERE
		Is_Latest = 1
),
p5 AS (
	SELECT 
		Organisation_Code,
		Organisation_Name
	FROM
		[UK_Health_Dimensions].[ODS].[Ind_Healthcare_Provider_Sites_SCD]
	WHERE
		Is_Latest = 1
),
p6 AS (
	SELECT 
		Organisation_Code,
		LA_Name
	FROM
		[UK_Health_Dimensions].[ODS].[Local_Authorities_In_England_And_Wales_SCD]
	WHERE
		Is_Latest = 1
),
organisation_lookup AS (
	SELECT
		OrgIDProv,
		COALESCE(p1.Organisation_Name,p2.Organisation_Name,p3.Organisation_Name,p4.Organisation_Name,p5.Organisation_Name,p6.LA_Name) AS provider_name
	FROM
		[Warehouse_LDM].[dbo].[v_SF_Latest_CareContact] cc
	LEFT JOIN p1
		ON p1.Organisation_Code = cc.OrgIDProv
	LEFT JOIN p2
		ON p2.Organisation_Code_5_Char = cc.OrgIDProv
	LEFT JOIN p3
		ON p3.Organisation_Code = cc.OrgIDProv
	LEFT JOIN p4
		ON p4.Organisation_Code = cc.OrgIDProv
	LEFT JOIN p5
		ON p5.Organisation_Code = cc.OrgIDProv
	LEFT JOIN p6
		ON p6.Organisation_Code = cc.OrgIDProv
	GROUP BY
		OrgIDProv,
		COALESCE(p1.Organisation_Name,p2.Organisation_Name,p3.Organisation_Name,p4.Organisation_Name,p5.Organisation_Name,p6.LA_Name)
)
SELECT
		ServiceRequestId AS service_id,
		CareContactId AS care_contact_id,
		CareContDate AS care_contact_date,
		COALESCE(Person_ID, UniqMHSDSPersID) AS patient_id,
		Pseudo_NHS_Number AS nhs_number,
		UniqMonthID AS month_id,
		ClinContDurOfCareCont AS contact_duration,
		AgeCareContDate AS age_at_contact,
		consultation_medium,
		activity_location,
		attendance_type,
		provider_name,
		cc.OrgIDProv AS provider_id,
		ActLocTypeCode AS activity_location_code
FROM
	[Warehouse_LDM].[dbo].[v_SF_Latest_CareContact] cc
LEFT JOIN consultation_lookup cl ON
	cc.ConsMediumUsed = cl.Main_Code_Text
LEFT JOIN location_lookup ll ON
	cc.ActLocTypeCode = ll.Main_Code_Text
LEFT JOIN attendance_lookup al ON
	cc.AttendOrDNACode = al.Main_Code_Text
LEFT JOIN organisation_lookup ol ON
	cc.OrgIDProv = ol.OrgIDProv;
WITH emis_bridge AS (
  SELECT Patient_Pseudonym, Leeds_CCG_Patient_ID
  FROM [Warehouse_LDMPC].[dbo].[EMIS_Patients]
  WHERE Patient_Pseudonym IN ('<nhs_number>')
), tpp_bridge AS (
  SELECT Patient_Pseudonym, Leeds_CCG_Patient_ID
  FROM [Warehouse_LDMPC].[dbo].[TPP_Patients]
  WHERE Patient_Pseudonym IN ('<nhs_number>')
),
emis_meds AS (
	SELECT 
		Patient_Pseudonym AS nhs_number,
		EffectiveDate AS medication_date,
		OriginalTerm AS prescription
	FROM
		[Warehouse_LDMPC].[dbo].[EMIS_Medication] m
	INNER JOIN emis_bridge e ON m.Leeds_CCG_Patient_ID = e.Leeds_CCG_Patient_ID
),
tpp_meds AS (
	SELECT 
		Patient_Pseudonym AS nhs_number,
		EventDate AS medication_date,
		NameOfMedication AS prescription
	FROM
		[Warehouse_LDMPC].[dbo].[TPP_Medication_Details] m
	INNER JOIN tpp_bridge t ON m.Leeds_CCG_Patient_ID = t.Leeds_CCG_Patient_ID
)
SELECT * FROM emis_meds 
UNION
SELECT * FROM tpp_meds;
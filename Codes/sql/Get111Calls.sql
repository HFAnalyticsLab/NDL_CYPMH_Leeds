SELECT
  PSEUDO_NHS_No AS nhs_number,
  Call_Commenced_Date_Time AS call_date,
  Symptom_Type_1_Desc AS symptom_1,
  Symptom_Type_2_Desc AS symptom_2,
  Symptom_Type_3_Desc AS symptom_3
FROM [Warehouse_LDM].[yas].[YAS_111]
WHERE Symptom_Type_1 IN (4044, 4053, 4177, 4178, 4179, 4205, 4206, 4207, 4208, 4209, 4211, 4238, 4244, 4245, 4303);
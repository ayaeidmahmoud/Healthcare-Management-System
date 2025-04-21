
use [Health Care]

--Storage_Procredure

--1 Add a new patient
CREATE OR ALTER PROCEDURE AddPatient
    @Patient_ID INT,
    @first_name NVARCHAR(100),
    @last_name NVARCHAR(100),
    @DOB DATE,
    @Gender NVARCHAR(10),
    @Address NVARCHAR(200),
    @Nurse_ID INT
WITH ENCRYPTION
AS
BEGIN
    INSERT INTO Patients (Patient_ID, first_name, last_name, DOB, Gender, Address, Nurse_ID)
    VALUES (@Patient_ID, @first_name, @last_name, @DOB, @Gender, @Address, @Nurse_ID)
END
EXECUTE AddPatient 26 ,aya,eid, '2002-01-10',Female ,'123sohag' ,3

select* from Patients
--2  Find doctor appointments on a specific date
CREATE or ALTER PROCEDURE GetDoctorAppointments
    @Doctor_ID INT,
    @Date DATE
with encryption
AS
BEGIN
    SELECT 
        a.appointment_id,
        a.time,
        p.first_name + ' ' + p.last_name AS patient_name,
        CASE 
            WHEN a.confirmed = 1 THEN 'Confirmed'
            WHEN a.completed = 1 THEN 'Completed'
            WHEN a.canceled = 1 THEN 'Canceled'
            ELSE 'Not Set'
        END AS status
    FROM Appointments a
    JOIN Patients p ON a.patient_id = p.Patient_ID
    WHERE a.doctor_id = @Doctor_ID AND a.date = @Date
END
Execute GetDoctorAppointments 2, '2025-02-10'
/*select * from Doctors 
select* from Patients
select * from Appointments*/

--3 Update medication prescription data

CREATE OR ALTER PROCEDURE UpdatePrescription
    @prescription_id INT,
    @medication_name VARCHAR(255),
    @dosage VARCHAR(100),
    @instructions TEXT
WITH ENCRYPTION
AS
BEGIN
    UPDATE Prescriptions
    SET medication_name = @medication_name,
        dosage = @dosage,
        instructions = @instructions
    WHERE prescription_id = @prescription_id
END
Execute UpdatePrescription 3, 'Aspirin','500mg' ,'take once a day after meals'

select* from Prescriptions

--4 Cancel an appointment

CREATE OR ALTER PROCEDURE CancelAppointment
    @appointment_id INT
AS
BEGIN
    UPDATE Appointments
    SET canceled = 1, confirmed = 0, completed = 0
    WHERE appointment_id = @appointment_id
END

EXECUTE CancelAppointment 1

--SELECT* FROM Appointments


--5 Doctor Performance Report
CREATE or ALTER PROCEDURE sp_Doctor_Performance_Report
    @Month INT, @Year INT
WITH ENCRYPTION
AS
BEGIN
    SELECT 
        d.Doctor_ID,
        d.first_name + ' ' + d.last_name AS Doctor_Name,
        COUNT(DISTINCT mr.Patient_ID) AS Total_Patients,
        (SELECT COUNT(*) FROM Prescriptions p WHERE p.doctor_id = d.Doctor_ID AND MONTH(p.date_prescribed) = @Month AND YEAR(p.date_prescribed) = @Year) AS Total_Prescriptions,
        (SELECT COUNT(*) FROM Appointments a WHERE a.doctor_id = d.Doctor_ID AND a.completed = 1 AND MONTH(a.date) = @Month AND YEAR(a.date) = @Year) AS Total_Completed_Appointments
    FROM Doctors d
    LEFT JOIN Medic_Doctors md ON d.Doctor_ID = md.Doctor_ID
    LEFT JOIN Medical_Records mr ON mr.Medical_Record_ID = md.Medic_Record_ID
    WHERE MONTH(mr.Visit_Date) = @Month AND YEAR(mr.Visit_Date) = @Year
    GROUP BY d.Doctor_ID, d.first_name, d.last_name
END


EXECUTE sp_Doctor_Performance_Report @Month = 2, @Year = 2025;

--select * from Medical_Records

--6 Patient Feedback Report

CREATE  OR ALTER PROCEDURE sp_Patient_Feedback_Report
WITH ENCRYPTION
AS
BEGIN
    SELECT 
        r.review_id,
        r.date_submitted,
        r.rating,
        r.patient_id,
        p.first_name + ' ' + p.last_name AS Patient_Name,
        rc.comment
    FROM Reviews r
    JOIN Patients p ON p.Patient_ID = r.patient_id
    LEFT JOIN Reviews_Comment rc ON r.review_id = rc.review_id
END

EXECUTE sp_Patient_Feedback_Report

--7 Financial Report

CREATE OR ALTER PROCEDURE sp_Financial_Report
WITH ENCRYPTION
AS
BEGIN
    SELECT 
        COUNT(CASE WHEN cash = 1 THEN 1 END) AS Total_Cash_Payments,
        COUNT(CASE WHEN insurance = 1 THEN 1 END) AS Total_Insurance_Payments,
        COUNT(CASE WHEN credit_card IS NOT NULL THEN 1 END) AS Total_Credit_Payments,
        SUM(amount) AS Total_Revenue,
        COUNT(CASE WHEN failed = 1 THEN 1 END) AS Failed_Transactions,
        COUNT(CASE WHEN completed = 1 THEN 1 END) AS Successful_Transactions
    FROM Payment_Methods
END
EXECUTE sp_Financial_Report

--8 Patient Distribution Report

CREATE OR ALTER PROCEDURE sp_Patient_Distribution_Report
WITH ENCRYPTION
AS
BEGIN
    SELECT 
        d.Department_Name,
        COUNT(DISTINCT p.Patient_ID) AS Total_Patients,
        COUNT(DISTINCT ipp.provider_id) AS Patients_With_Insurance
    FROM Patients p
    LEFT JOIN Nurse n ON p.Nurse_ID = n.id_nurse
    LEFT JOIN Departments d ON n.Department_ID = d.Dept_ID
    LEFT JOIN Insurance_Providers_Patient ipp ON p.Patient_ID = ipp.patient_id
    GROUP BY d.Department_Name
END
EXECUTE sp_Patient_Distribution_Report

--9 Appointment Status Report
CREATE OR ALTER PROCEDURE sp_Appointment_Status_Report
WITH ENCRYPTION
AS
BEGIN
    SELECT 
        d.Doctor_ID,
        d.first_name + ' ' + d.last_name AS Doctor_Name,
        COUNT(*) AS Total_Appointments,
        COUNT(CASE WHEN confirmed = 1 THEN 1 END) AS Confirmed,
        COUNT(CASE WHEN completed = 1 THEN 1 END) AS Completed,
        COUNT(CASE WHEN canceled = 1 THEN 1 END) AS Canceled
    FROM Appointments a
    JOIN Doctors d ON a.doctor_id = d.Doctor_ID
    GROUP BY d.Doctor_ID, d.first_name, d.last_name
END
EXECUTE sp_Appointment_Status_Report
--=====================================================================================================================
 --TRIGGER

 /*1-To automatically update the appointment status when it is confirmed.
Idea: When the user confirms the appointment (confirmed = 1), the remaining statuses (completed, canceled) are set to 0.*/

CREATE  OR ALTER TRIGGER trg_Appointment_Status
ON Appointments
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Appointments
    SET completed = 0, canceled = 0
    WHERE confirmed = 1 AND (completed = 1 OR canceled = 1)
END

 /* 2-To prevent a doctor from being deleted if there are prescriptions or appointments associated with him.
Idea: If a doctor has associated data, it won't be deleted.*/

CREATE  OR ALTER TRIGGER trg_Doctor_Delete
ON Doctors
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM Appointments WHERE doctor_id IN (SELECT Doctor_ID FROM deleted)
        UNION
        SELECT 1 FROM Prescriptions WHERE doctor_id IN (SELECT Doctor_ID FROM deleted)
    )
    BEGIN
        RAISERROR('Cannot delete doctor with existing appointments or prescriptions.', 16, 1)
    END
    ELSE
    BEGIN
        DELETE FROM Doctors WHERE Doctor_ID IN (SELECT Doctor_ID FROM deleted)
    END
END

/*3- To send a notification when a new medical record is added*/

CREATE  OR ALTER TRIGGER trg_New_Medical_Record
ON Medical_Records
AFTER INSERT
AS
BEGIN
    SELECT 'New medical record has been added for patient ID: ' + CAST((SELECT Patient_ID FROM inserted) AS NVARCHAR)
END

/* 4-To prevent more than one payment type from being entered in Payment_Methods
Idea: Prevent the user from specifying, for example, cash = 1 and insurance = 1 together.*/

CREATE  OR ALTER TRIGGER trg_Check_Payment_Type
ON Payment_Methods
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT * FROM inserted
        WHERE 
            (CAST(cash AS INT) + CAST(insurance AS INT)) > 1
    )
    BEGIN
        RAISERROR('Only one payment type (cash or insurance) is allowed.', 16, 1)
        ROLLBACK TRANSACTION
    END
END


/* 5-To update the number of patients associated with each doctor*/
CREATE TABLE Doctor_Stats (
    doctor_id INT PRIMARY KEY,
    patient_count INT DEFAULT 0
);

CREATE  OR ALTER TRIGGER trg_Update_Doctor_Stats
ON Patients_Doctors
AFTER INSERT, DELETE
AS
BEGIN
    -- Recalculate patient count
    MERGE Doctor_Stats AS target
    USING (
        SELECT Doctor_ID, COUNT(*) AS cnt
        FROM Patients_Doctors
        GROUP BY Doctor_ID
    ) AS source
    ON target.doctor_id = source.Doctor_ID
    WHEN MATCHED THEN
        UPDATE SET patient_count = source.cnt
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (doctor_id, patient_count) VALUES (source.Doctor_ID, source.cnt);
END

/* 6-To automatically update performance when a new recipe is added*/

CREATE OR ALTER TRIGGER trg_Update_DoctorPerformance_OnPrescription
ON Prescriptions
AFTER INSERT
AS
BEGIN
    DECLARE @Doctor_ID INT, @Date DATE, @Month INT, @Year INT;

    SELECT 
        @Doctor_ID = doctor_id, 
        @Date = date_prescribed 
    FROM inserted;

    SET @Month = MONTH(@Date);
    SET @Year = YEAR(@Date);

    
    IF EXISTS (
        SELECT 1 FROM Doctor_Performance_Report 
        WHERE doctor_id = @Doctor_ID AND month_year = FORMAT(@Date, 'yyyy-MM')
    )
    BEGIN
        UPDATE Doctor_Performance_Report
        SET total_prescriptions = total_prescriptions + 1
        WHERE doctor_id = @Doctor_ID AND month_year = FORMAT(@Date, 'yyyy-MM')
    END
END
--===========================================================================================================
--FUNCATION---------------- 

----Patient age calculation function


create or alter function _getdate (@Age date)
returns int 
as 
begin
    RETURN DATEDIFF(YEAR, @Age, GETDATE())
end


select  CONCAT(p.first_name,' ',p.last_name) as Fullname ,dbo._getdate(p.DOB) as age
from Patients p


-------------------------------------- Function for each patient with a specific diagnosis

create or alter function get_patient_Diagnosis(@Diagnosis Nvarchar (100))
Returns table 
as 
return 
(
select  p.Patient_ID ,CONCAT(p.first_name,' ',p.last_name) as Fullname
from Patients p inner join Medical_Records MD
on p.Patient_ID=MD.Patient_ID
where MD.Diagnosis=@Diagnosis

)
 
 select *   from dbo.get_patient_Diagnosis ( 'Rheumatoid Arthritis')
 
-------------------------------------------------------- I will do a function if the patient enters, when will he bring the medication and take it? The ID


 create or alter function get_patient_prescription(@id int)
 returns @t table (medication_name nvarchar(100),dosage nvarchar(100),instructions nvarchar(100))
 as
 begin
 insert into @t
 select ps.medication_name ,ps.dosage,ps.instructions
 from Patients p inner join Prescriptions_Patient pp 
 on p.Patient_ID=pp.patient_id inner join Prescriptions ps
 on pp.prescription_id=ps.prescription_id
 where p.Patient_ID=@id 
 return 
 end 

 select * from dbo.get_patient_prescription(20)

-------------------------------------------------------------------- Function: Please provide me with the name of the doctor who wrote this prescription. ---------- I will add the patient's name with the doctor.
 create or alter function get_doc_name (@id int)
 Returns table 
as 
return 
(
select  CONCAT(d.first_name,' ',d.last_name) as Fullname
from Doctors d inner join Prescriptions p
on d.Doctor_ID=p.doctor_id
where p.prescription_id=@id

)
 select * from dbo.get_doc_name(5)
 

------------------------------------------------------- Function brings the name of each nurse responsible for a patient and her phone number in case we need her


 create or alter function get_nurse_name(@id int)
Returns table 
as 
return 
(
select n.name_nurse ,n.phone_number
from Nurse n inner join Patients p
on n.id_nurse=p.Nurse_ID
where p.Patient_ID=@id
)

select * from dbo.get_nurse_name(20)



---------------------------------------------------------- A function that the accountant will use to show him how much each patient paid and receive the total amount paid.
create or alter function get_patient_payment(@id int)
Returns table 
as 
return 
(
select CONCAT(p.first_name,' ',p.last_name) as Fullnam,pm.amount,(select sum (pm1.amount) 
from Payment_Methods pm1 inner join  Patient_Payment pp1 
on pm1.payment_id=pp1.payment_id 
 )as total_payment

from Payment_Methods pm inner join  Patient_Payment pp 
on pm.payment_id=pp.payment_id inner join Patients p
on pp.patient_id=p.Patient_ID
where p.Patient_ID=@id

)

select * from dbo.get_patient_payment(20)


--I will do a function when I give her the patient’s number. It will show me the appointment time.

create or alter function get_appointment (@patient_id int)
returns table 
as
return 
(

select CONCAT(p.first_name,' ',p.last_name) as Fullnam,ap.date,ap.time
from Patients p inner join Appointments ap
on p.Patient_ID=ap.patient_id
where p.Patient_ID=@patient_id
)
select * from get_appointment(25)


--- A function that shows me the names of patients and how many times they were visited. Here, I added data to the medical records table.
create or alter function get_visit()
returns table
as
return 
(
select CONCAT(p.first_name,' ',p.last_name) as Fullnam ,count (mr.Visit_Date) as Visits
from Patients p inner join Medical_Records Mr
on p.Patient_ID=mr.Patient_ID
group by p.first_name,p.last_name

)
select * from get_visit()





--------- I will make a cursor that displays the name of each patient in a separate row.


declare @name varchar(100)
declare patient_cursor cursor for 
select CONCAT(p.first_name,' ',p.last_name)  from Patients p 
open patient_cursor 
fetch next from patient_cursor into @name
while @@FETCH_STATUS=0
begin
print 'Patient '+@name
fetch next from patient_cursor into @name

end
close patient_cursor
deallocate patient_cursor

----Two cursors, one displays the names of the departments and the other the names of the doctors.

declare @table1 table (id int ,name varchar(50))
declare @table2 table (id int ,name varchar(50))

-----first cursor
declare @id int ,@name varchar(50)
declare Doctor_cursor cursor for 
select  d.Doctor_ID,CONCAT(d.first_name,' ',d.last_name)  from Doctors d 
open Doctor_cursor 
fetch next from Doctor_cursor into @id,@name
while @@FETCH_STATUS=0
begin
insert into @table1 values (@id,@name)
fetch next from Doctor_cursor into @id,@name

end
close Doctor_cursor
deallocate Doctor_cursor

------second cursor

declare @id1 int ,@name1 varchar(50)
declare Department_cursor cursor for 
select d.Dept_ID, d.Department_Name  from Departments D
open Department_cursor 
fetch next from Department_cursor into @id1,@name1
while @@FETCH_STATUS=0
begin
insert into @table2 values (@id1,@name1)
fetch next from Department_cursor into @id1,@name1

end
close Department_cursor
deallocate Department_cursor

----tow curser

select * from @table1
union all

select * from @table2


-- I merged the patient's table into a new table so that if any update occurs in the patient's data, it will be updated in the table or added if this is the first time the patient has come.


create table new_patient
(
Patient_ID int ,
first_name varchar(20),
last_name varchar(20),
DOB date ,
Gender varchar (20),
Address varchar(100)


)
drop table new_patient
Merge into new_patient as t
using Patients as s 
on t.Patient_ID=s.Patient_ID

when matched then
update
set t.Patient_ID=s.Patient_ID
when not matched then 
insert (Patient_ID,first_name,last_name,DOB,Gender,Address)
values(s.Patient_ID,s.first_name,s.last_name,s.DOB,s.Gender,s.Address);



--- I merged the new employee's table so that if any update occurs in the employee's data, it will be updated in the table or added if the employee is new.

create table new_satff
(
staff_id int ,
staff_name varchar(50),
Accountant bit ,
Admin bit,
Receptionist bit,
phone_number varchar(20),
)

Merge into new_satff as t
using Staff as s
on t.staff_id=s.staff_id
when matched then 
update
set t.staff_id=s.staff_id
when not matched then 
insert (staff_id,staff_name,Accountant,Admin,Receptionist,phone_number)
values (s.staff_id,s.staff_name,s.Accountant,s.Admin,s.Receptionist,s.phone_number);


select * from new_patient




--===========================================================================================================
--VIEW AND INDEX

create OR Alter view Patient_Information
as
select p.patient_id,p.gender,ph.phone_number AS patient_phone,
concat(p.first_name,p.last_name) AS patient_name,
    mr.Symptoms AS medical_Symptoms
FROM 
    Patients p
join 
    Patient_Phone ph ON p.patient_id = ph.patient_id
join 
    Medical_Records mr ON p.patient_id = mr.patient_id;

	select * from PatientInformation

-----Extract the prescription details and the information of the doctor following it for a specific patient.

create or alter  view patient_Prescriptionswith_doctor
with encryption
as
select concat( p1.first_name,p1.last_name)as full_name,p1.Address as add_patient,
p2.*,concat(d.first_name,d.last_name)as full_name_doctor
from Patients p1 inner join Prescriptions p2 
on p1.Patient_ID=p2.patient_id
inner join Doctors d
on d.Doctor_ID=p2.doctor_id
--where p1.Patient_ID=1

select *  from patient_Prescriptionswith_doctor
--------------------------------------------------------------------------------------

----  retrieves all the records available for all patients — statistics.
create or alter view patient_Recrd(patient_name,Medical_Record_ID,Patient_ID,Visit_Date,Symptoms,Diagnosis)
as
select  concat(s.first_name,s.last_name) as patient_name , m.Medical_Record_ID,m.Patient_ID,Visit_Date,m.Symptoms,m.Diagnosis   
from Patients s inner join Medical_Records m 
on s.Patient_ID=m.Patient_ID
--where s.Patient_ID=4

select patient_name,Medical_Record_ID,Patient_ID,Visit_Date,Symptoms,Diagnosis   from patient_Recrd

----------------------------------------------------------------

--- retrieves comment special patient with name patient and review id
create or alter  view patient_review 
as  
select concat(s.first_name,s.last_name)as full_name_patient , r2.review_id , r2.comment 
from patients s inner join Reviews r1 on s.Patient_ID=r1.Patient_ID 
inner join Reviews_Comment r2 on r1.review_id=r2.review_id 
where s.Patient_ID =4  

select * from patient_review

------------------------------------------------------------------------------------
--retrive number of doctor in each departmet
create or alter  view Num_Docters_in_Departmet
as
select  d3.Department_Name ,  count(d1.Doctor_ID) AS COUNT_DOCTORS
from Doctors d1 inner join Department_doctor d2
on d1.Doctor_ID=d2.Doctor_id
inner join Departments d3
on d3.Dept_ID=d2.Dept_ID
group by d3.Department_Name

select * from Num_Docters_in_Departmet
-----------------------------------------------------------------------------------
----Display the docto's details, their departments, the locations of their departments, and their phone numbers.

create or alter view DoctorDetails 
as
select concat(d.first_name,d.last_name) as Fullname,d.email,d.phone_number, d2.Location AS department_location
FROM 
    Doctors d
join 
    Department_doctor dd ON d.doctor_id = dd.doctor_id
join 
    Departments  d1 ON dd.Dept_ID = d1.Dept_ID
join
    Department_Location d2 on d1.Dept_ID=d2.Dept_ID
	 
	
	select *  from DoctorDetails

---- Only patients with insurance are eligible.
create or alter  view patient_witout_insuranse_provider
as
select p1.first_name
from Patients p1, Insurance_Providers_Patient p2 
where p1.Patient_ID=p2.patient_id and p2.provider_id in
(select p3.provider_ID  from Insurance_Providers p3 
  where p2.provider_ID=p3.provider_ID and p2.provider_id is not null )

  select * from patient_witout_insuranse_provider

---------------------------------------------------------------------------
create nonclustered index CLUSTER_PATIENT
on Patients(address)
--------------------------------------------------------------------------------
create nonclustered index CLUSTER_NURSE
on Nurse(email)
---------------------------------------------------------------------------------
create nonclustered index CLUSTER_PROVIDER
on Insurance_Providers(email)
----------------------------------------------------------------------------------
create nonclustered index CLUSTER_STAFF
on staff(admin)

--=========================================================================================================

--==> CTE (Common Table Expression)
-- Number of staff in each department by role: "Accountant", "Admin", or "Receptionist"

WITH RoleCounts AS (
    SELECT 
        Dept_ID,
        SUM(CAST(Accountant AS INT)) AS Accountants,
        SUM(CAST(Admin AS INT)) AS Admins,
        SUM(CAST(Receptionist AS INT)) AS Receptionists
    FROM Staff
    GROUP BY Dept_ID
)
SELECT 
    d.Department_Name,
    rc.Accountants,
    rc.Admins,
    rc.Receptionists
FROM RoleCounts rc
JOIN Departments d ON rc.Dept_ID = d.Dept_ID;

-- Shows each staff member and their administrative role, along with their department location.

WITH StaffRoles AS (
    SELECT 
        staff_id,
        staff_name,
        Dept_ID,
        phone_number,
        CASE 
            WHEN Accountant = 1 THEN 'Accountant'
            WHEN Admin = 1 THEN 'Admin'
            WHEN Receptionist = 1 THEN 'Receptionist'
        END AS Role
    FROM Staff
)
SELECT 
    sr.staff_id,
    sr.staff_name,
    sr.Role,
    d.Department_Name,
    sr.phone_number
FROM StaffRoles sr
JOIN Departments d ON sr.Dept_ID = d.Dept_ID;
 -- This query generates a detailed report of administrative staff roles.
-- It identifies each staff member’s role (Accountant, Admin, or Receptionist),
-- shows their associated department and phone number,
-- and calculates the total number of staff per role using a window function.

WITH StaffRoles AS (
    SELECT 
        staff_id,
        staff_name,
        Dept_ID,
        phone_number,
        CASE 
            WHEN Accountant = 1 THEN 'Accountant'
            WHEN Admin = 1 THEN 'Admin'
            WHEN Receptionist = 1 THEN 'Receptionist'
        END AS Role
    FROM Staff
)
SELECT 
    sr.staff_id,
    sr.staff_name,
    sr.Role,
    d.Department_Name,
    sr.phone_number,
    COUNT(*) OVER (PARTITION BY sr.Role) AS TotalPerRole
FROM StaffRoles sr
JOIN Departments d ON sr.Dept_ID = d.Dept_ID;

-- The department with the highest number of staff

WITH StaffRoles AS (
    SELECT 
        staff_id,
        staff_name,
        Dept_ID,
        phone_number,
        CASE 
            WHEN Accountant = 1 THEN 'Accountant'
            WHEN Admin = 1 THEN 'Admin'
            WHEN Receptionist = 1 THEN 'Receptionist'
        END AS Role
    FROM Staff
)
SELECT 
    sr.Role,
    d.Department_Name,
    COUNT(*) AS StaffCount
FROM StaffRoles sr
JOIN Departments d ON sr.Dept_ID = d.Dept_ID
GROUP BY sr.Role, d.Department_Name
ORDER BY sr.Role, StaffCount DESC;

-- If a department has more than one branch or location, it's important to know exactly where each doctor is located.


WITH DoctorLocations AS (
    SELECT 
        dd.Doctor_id,
        dl.Location
    FROM Department_doctor dd
    JOIN Department_Location dl ON dd.Dept_ID = dl.Dept_ID
)
SELECT 
    d.first_name + ' ' + d.last_name AS Doctor_Name,
    d.specialization,
    dl.Location
FROM DoctorLocations dl
JOIN Doctors d ON dl.Doctor_id = d.Doctor_ID
ORDER BY d.Doctor_ID;

-- If the hospital has multiple branches, it’s important to know: How many doctors are in each branch, and how many patients are they following up with?


WITH DoctorLocations AS (
    SELECT 
        dd.Doctor_id,
        dl.Location
    FROM Department_doctor dd
    JOIN Department_Location dl ON dd.Dept_ID = dl.Dept_ID
),
DoctorPatients AS (
    SELECT 
        dl.Location,
        dl.Doctor_id,
        pd.Patient_id
    FROM DoctorLocations dl
    JOIN Patients_Doctors pd ON dl.Doctor_id = pd.Doctor_id
)
SELECT 
    Location,
    COUNT(DISTINCT Doctor_id) AS NumberOfDoctors,
    COUNT(DISTINCT Patient_id) AS NumberOfPatients
FROM DoctorPatients
GROUP BY Location
ORDER BY Location;


-- If there are staff members assigned to departments that operate in multiple locations


WITH StaffDetails AS (
    SELECT 
        s.staff_id,
        s.staff_name,
        s.Dept_ID,
        CASE 
            WHEN Accountant = 1 THEN 'Accountant'
            WHEN Admin = 1 THEN 'Admin'
            WHEN Receptionist = 1 THEN 'Receptionist'
        END AS Role
    FROM Staff s
)
SELECT 
    sd.staff_id,
    sd.staff_name,
    sd.Role,
    d.Department_Name,
    dl.Location
FROM StaffDetails sd
JOIN Departments d ON sd.Dept_ID = d.Dept_ID
LEFT JOIN Department_Location dl ON sd.Dept_ID = dl.Dept_ID;

-- Gives a comprehensive view of the patient: Who are they following up with? In which specialty? And at which branch?

WITH PatientDoctorInfo AS (
    SELECT 
        pd.Patient_ID,
        doc.Doctor_ID,
        CONCAT(doc.first_name, ' ', doc.last_name) AS DoctorName,
        doc.specialization,
        dd.Dept_ID,
        dl.Location
    FROM Patients_Doctors pd
    JOIN Doctors doc ON pd.Doctor_ID = doc.Doctor_ID
    JOIN Department_Doctor dd ON doc.Doctor_ID = dd.Doctor_id
    JOIN Department_Location dl ON dd.Dept_ID = dl.Dept_ID
)
SELECT 
    CONCAT(p.First_Name, ' ', p.Last_Name) AS PatientName,
    pdi.DoctorName,
    pdi.specialization,
    pdi.Location
FROM Patients p
JOIN PatientDoctorInfo pdi ON p.Patient_ID = pdi.Patient_ID;

--Synonym

CREATE SYNONYM PD FOR dbo.Patients_Doctors;
SELECT Patient_ID, Doctor_ID
FROM PD;


SELECT 
    CONCAT(p.First_Name, ' ', p.Last_Name) AS PatientName,
    CONCAT(d.First_Name, ' ', d.Last_Name) AS DoctorName
FROM PD pd
JOIN Patients p ON pd.Patient_ID = p.Patient_ID
JOIN Doctors d ON pd.Doctor_ID = d.Doctor_ID;


DROP SYNONYM PD;

--LAG()	
-- The patient's previous visit.
-- Helps identify who follows up regularly or irregularly.


SELECT 
    patient_id,
    doctor_id,
    date,
    time,
    LAG(date) OVER(PARTITION BY patient_id ORDER BY date) AS previous_visit
FROM Appointments;

--LEAD()

-- The patient's next appointment  
-- Useful for scheduling upcoming follow-ups for each patient.
-- Patient Visit Follow-up Report

SELECT 
    patient_id,
    doctor_id,
    date,
    time,
    LEAD(date) OVER(PARTITION BY patient_id ORDER BY date) AS next_visit
FROM Appointments;

--FIRST_VALUE()

SELECT 
    patient_id,
    doctor_id,
    date,
    FIRST_VALUE(date) OVER(PARTITION BY patient_id ORDER BY date) AS first_visit
FROM Appointments;

--LAST_VALUE()
SELECT 
    patient_id,
    doctor_id,
    date,
    LAST_VALUE(date) OVER(
        PARTITION BY patient_id 
        ORDER BY date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_visit
FROM Appointments;

--We want to know if the patient is still following up or has been inactive recently.
--A report of doctor follow-ups and which patients they followed.


--Doctors’ follow-up report and which patients they followed
SELECT 
    a.doctor_id,
    CONCAT(d.First_Name, ' ', d.Last_Name) AS DoctorName,
    a.patient_id,
    CONCAT(p.First_Name, ' ', p.Last_Name) AS PatientName,
    a.date AS VisitDate,

    -- The previous patient seen by a doctor (based on date)
    LAG(CONCAT(p.First_Name, ' ', p.Last_Name)) OVER(PARTITION BY a.doctor_id ORDER BY a.date) AS Previous_Patient,

    -- The next patient for the doctor (based on date)

    LEAD(CONCAT(p.First_Name, ' ', p.Last_Name)) OVER(PARTITION BY a.doctor_id ORDER BY a.date) AS Next_Patient,

    -- The first patient seen by each doctor
    FIRST_VALUE(CONCAT(p.First_Name, ' ', p.Last_Name)) OVER(PARTITION BY a.doctor_id ORDER BY a.date) AS First_Patient,

    -- The last patient seen by each doctor
    LAST_VALUE(CONCAT(p.First_Name, ' ', p.Last_Name)) OVER(
        PARTITION BY a.doctor_id 
        ORDER BY a.date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS Last_Patient

FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors d ON a.doctor_id = d.doctor_id
ORDER BY a.doctor_id, a.date;

-- We want to find out which doctor is under the most workload pressure.
SELECT 
    a.doctor_id,
    CONCAT(d.First_Name, ' ', d.Last_Name) AS DoctorName,
    COUNT(*) AS Total_Visits
FROM Appointments a
JOIN Doctors d ON a.doctor_id = d.doctor_id
GROUP BY a.doctor_id, d.First_Name, d.Last_Name
ORDER BY Total_Visits DESC;
--RANK()
--Ranking doctors by number of visits (appointments)
SELECT *,
       RANK() OVER(ORDER BY Total_Visits DESC) AS DoctorRank
FROM (
    SELECT 
        a.doctor_id,
        CONCAT(d.First_Name, ' ', d.Last_Name) AS DoctorName,
        COUNT(*) AS Total_Visits
    FROM Appointments a
    JOIN Doctors d ON a.doctor_id = d.doctor_id
    GROUP BY a.doctor_id, d.First_Name, d.Last_Name
) AS RankedDoctors;

--DENSE_RANK()

SELECT *,
       DENSE_RANK() OVER(ORDER BY Total_Visits DESC) AS DenseRank
FROM (
    SELECT 
        a.doctor_id,
        CONCAT(d.First_Name, ' ', d.Last_Name) AS DoctorName,
        COUNT(*) AS Total_Visits
    FROM Appointments a
    JOIN Doctors d ON a.doctor_id = d.doctor_id
    GROUP BY a.doctor_id, d.First_Name, d.Last_Name
) AS RankedDoctors;

--ROW_NUMBER()
--Numbering (ranking) patient visits
SELECT 
    a.patient_id,
    CONCAT(p.First_Name, ' ', p.Last_Name) AS PatientName,
    a.date,
    ROW_NUMBER() OVER(PARTITION BY a.patient_id ORDER BY a.date) AS VisitNumber
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id;

--NTILE()
--Which patients started early in the system, and who came later?.
SELECT 
    p.patient_id,
    CONCAT(p.First_Name, ' ', p.Last_Name) AS PatientName,
    MIN(a.date) AS FirstVisitDate,
    NTILE(4) OVER(ORDER BY MIN(a.date)) AS VisitGroup
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
GROUP BY p.patient_id, p.First_Name, p.Last_Name;


--The patient who was prescribed the most prescriptions by the doctor, along with the department name


WITH DoctorPatientPrescriptions AS (
    SELECT 
        d.doctor_id,
        CONCAT(d.first_name, ' ', d.last_name) AS DoctorName,
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
        COUNT(pr.prescription_id) AS TotalPrescriptions,
        ROW_NUMBER() OVER (PARTITION BY d.doctor_id ORDER BY COUNT(pr.prescription_id) DESC) AS rn
    FROM Prescriptions pr
    JOIN Doctors d ON pr.doctor_id = d.doctor_id
    JOIN Patients p ON pr.patient_id = p.patient_id
    GROUP BY d.doctor_id, d.first_name, d.last_name, p.patient_id, p.first_name, p.last_name
),
DoctorDepartments AS (
    SELECT 
        dd.doctor_id,
        dep.department_name
    FROM Department_Doctor dd
    JOIN Departments dep ON dd.dept_id = dep.dept_id
)
SELECT 
    dpp.doctor_id,
    dpp.DoctorName,
    dpp.patient_id,
    dpp.PatientName,
    dpp.TotalPrescriptions,
    dd.department_name
FROM DoctorPatientPrescriptions dpp
LEFT JOIN DoctorDepartments dd ON dpp.doctor_id = dd.doctor_id
WHERE dpp.rn = 1
ORDER BY dpp.TotalPrescriptions DESC;

--The patient with the most prescriptions
SELECT TOP 1
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    COUNT(pr.prescription_id) AS TotalPrescriptions
FROM Prescriptions pr
JOIN Patients p ON pr.patient_id = p.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY TotalPrescriptions DESC;


-- If we want to know the latest transaction that was made
SELECT TOP 1 
    a.appointment_id,
    CONCAT(p.first_name, ' ', p.last_name) AS PatientName,
    CONCAT(d.first_name, ' ', d.last_name) AS DoctorName,
    a.date
FROM Appointments a
JOIN Patients p ON a.patient_id = p.patient_id
JOIN Doctors d ON a.doctor_id = d.doctor_id
ORDER BY a.date DESC;

-- Useful for HR to analyze distribution of roles per department, or overall counts by role or department.
--GROUPING SETS 
WITH StaffRoles AS (
    SELECT 
        staff_id,
        staff_name,
        Dept_ID,
        CASE 
            WHEN Accountant = 1 THEN 'Accountant'
            WHEN Admin = 1 THEN 'Admin'
            WHEN Receptionist = 1 THEN 'Receptionist'
        END AS Role
    FROM Staff
)
SELECT 
    sr.Role,
    d.Department_Name,
    COUNT(*) AS StaffCount
FROM StaffRoles sr
JOIN Departments d ON sr.Dept_ID = d.Dept_ID
GROUP BY GROUPING SETS (
    (sr.Role, d.Department_Name),
    (sr.Role),
    (d.Department_Name),
    ()
);

-- We want to identify the best departments based on patient reviews and number of comments, and also determine the location.


SELECT 
    d.Department_Name,
    dl.Location,
    AVG(r.rating) AS AvgRating,
    COUNT(rc.comment) AS CommentCount
FROM Reviews r
JOIN Patients p ON r.patient_id = p.patient_id
JOIN Appointments a ON p.patient_id = a.patient_id
JOIN Doctors doc ON a.doctor_id = doc.doctor_id
JOIN Department_doctor dd ON doc.doctor_id = dd.Doctor_id
JOIN Departments d ON dd.Dept_ID = d.Dept_ID
JOIN Department_Location dl ON d.Dept_ID = dl.Dept_ID
LEFT JOIN Reviews_Comment rc ON r.review_id = rc.review_id
GROUP BY d.Department_Name, dl.Location
ORDER BY AvgRating DESC, CommentCount DESC;

SELECT 
    p.gender,
    r.rating,
    COUNT(*) AS NumberOfReviews
FROM Reviews r
JOIN Patients p ON r.patient_id = p.patient_id
GROUP BY CUBE(p.gender, r.rating);

--merge
--Payment analysis by payment method and transaction status
SELECT 
    CASE 
        WHEN cash = 1 THEN 'Cash'
        WHEN insurance = 1 THEN 'Insurance'
        WHEN completed = 1 THEN 'Completed'
        WHEN failed = 1 THEN 'Failed'
        WHEN pending = 1 THEN 'Pending'
        ELSE 'Other'
    END AS PaymentStatus,
    COUNT(*) AS TotalPayments
FROM Payment_Methods
GROUP BY ROLLUP(
    CASE 
        WHEN cash = 1 THEN 'Cash'
        WHEN insurance = 1 THEN 'Insurance'
        WHEN completed = 1 THEN 'Completed'
        WHEN failed = 1 THEN 'Failed'
        WHEN pending = 1 THEN 'Pending'
        ELSE 'Other'
    END
);




--1. Let’s assume we are updating patient data from a temporary table (such as new patients or edits to existing patient data).
-- We start by creating a temporary table that contains some new patients or patients whose data needs to be updated.



CREATE TABLE TempPatients (
    Patient_ID INT,
    first_name NVARCHAR(100),
    last_name NVARCHAR(100),
    DOB DATE,
    Gender NVARCHAR(10),
    Address NVARCHAR(200),
    Nurse_ID INT
);


INSERT INTO TempPatients VALUES
(1, 'Ahmed', 'Salah', '1990-05-10', 'Male', 'Cairo', 101),
(2, 'Sara', 'Ali', '1995-09-22', 'Female', 'Giza', 102);


-- 2. MERGE to update or insert patient reviews

CREATE TABLE TempReviews (
    review_id INT,
    date_submitted DATE,
    rating INT,
    patient_id INT
);

INSERT INTO TempReviews VALUES
(101, '2025-04-01', 5, 1),
(102, '2025-04-02', 4, 2);

MERGE Reviews AS Target
USING TempReviews AS Source
ON Target.review_id = Source.review_id
WHEN MATCHED THEN 
    UPDATE SET 
        Target.date_submitted = Source.date_submitted,
        Target.rating = Source.rating,
        Target.patient_id = Source.patient_id
WHEN NOT MATCHED THEN 
    INSERT (review_id, date_submitted, rating, patient_id)
    VALUES (Source.review_id, Source.date_submitted, Source.rating, Source.patient_id);




--Report 1: Number of patients by gender in each department (PIVOT)
--Goal: To understand the distribution of patients by gender within each department.

SELECT *
FROM (
    SELECT 
        d.Department_Name,
        p.Gender
    FROM Patients p
    JOIN Nurse n ON p.Nurse_ID = n.id_nurse
    JOIN Departments d ON n.Department_ID = d.Dept_ID
) AS SourceTable
PIVOT (
    COUNT(Gender)
    FOR Gender IN ([Male], [Female])
) AS PivotTable;

--"We want to see for each patient the number of times they used each payment method, and identify the most frequently used method by patients.".
SELECT *
FROM (
    SELECT 
        p.patient_id,
        CASE 
            WHEN pm.cash = 1 THEN 'Cash'
            WHEN pm.insurance = 1 THEN 'Insurance'
            WHEN pm.credit_card IS NOT NULL THEN 'Credit'
            ELSE 'Other'
        END AS PaymentType
    FROM Patient_Payment p
    JOIN Payment_Methods pm ON p.payment_id = pm.payment_id
) AS SourceTable
PIVOT (
    COUNT(PaymentType)
    FOR PaymentType IN ([Cash], [Insurance], [Credit])
) AS PivotResult;










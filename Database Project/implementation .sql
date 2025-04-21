create database [Health Care]

use [Health Care]


CREATE TABLE Staff (
    staff_id INT PRIMARY KEY,
    staff_name NVARCHAR(100) NOT NULL,
    Accountant BIT DEFAULT 0,
    Admin BIT DEFAULT 0,
    Receptionist BIT DEFAULT 0,
    phone_number NVARCHAR(20),
    Dept_ID INT,
    FOREIGN KEY (Dept_ID) REFERENCES Departments(Dept_ID),

    -- Constraint: Only one role can be true
    CHECK (
        (CAST(Accountant AS INT) + 
         CAST(Admin AS INT) + 
         CAST(Receptionist AS INT)) = 1
    ),

    -- Constraint: phone number must be unique
    UNIQUE (phone_number)
);
-------------------------------------------------------------------------------------------

CREATE TABLE Departments (
    Dept_ID INT PRIMARY KEY,
    Department_Name NVARCHAR(100)
)


-------------------------------------------------------------------------------------------
CREATE TABLE Department_doctor (
    Dept_ID INT ,
    Doctor_id INT ,
	PRIMARY KEY (Dept_ID, Doctor_id),
	FOREIGN KEY (Dept_ID) REFERENCES Departments(Dept_ID)
	FOREIGN KEY (Doctor_id) REFERENCES Doctors(Doctor_id)

)

-------------------------------------------------------------------------------------------

CREATE TABLE Department_Location (
    Dept_ID INT,
    Location NVARCHAR(100),
    PRIMARY KEY (Dept_ID, Location),
    FOREIGN KEY (Dept_ID) REFERENCES Departments(Dept_ID)
)


-------------------------------------------------------------------------------------------

CREATE TABLE Doctors (
    Doctor_ID INT PRIMARY KEY,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    specialization NVARCHAR(100) NOT NULL,
    phone_number BIGINT NOT NULL UNIQUE, 
    email NVARCHAR(100) NOT NULL UNIQUE,

    
    CHECK (email LIKE '%@%')
);


-------------------------------------------------------------------------------------------


CREATE TABLE Patients (
    Patient_ID INT PRIMARY KEY,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    Gender NVARCHAR(10) NOT NULL,
    Address NVARCHAR(200),
    Nurse_ID INT,
    FOREIGN KEY (Nurse_ID) REFERENCES Nurse(id_nurse),

    -- Constraint: Gender must be either 'Male' or 'Female'
    CHECK (Gender IN ('Male', 'Female')),

    -- Constraint: Date of Birth must be in the past
    CHECK (DOB < GETDATE())
);

-------------------------------------------------------------------------------------------

CREATE TABLE Patients_Doctors (
    Patient_ID INT,
    Doctor_ID INT,
    PRIMARY KEY (Patient_ID, Doctor_ID),
    FOREIGN KEY (Patient_ID) REFERENCES Patients(Patient_ID),
    FOREIGN KEY (Doctor_ID) REFERENCES Doctors(Doctor_ID)
)

-------------------------------------------------------------------------------------------


CREATE TABLE Nurse (
    id_nurse INT PRIMARY KEY,
    name_nurse NVARCHAR(100) NOT NULL,
    email NVARCHAR(100) NOT NULL UNIQUE,
    phone_number NVARCHAR(20) NOT NULL UNIQUE,
    gender NVARCHAR(10) NOT NULL,
    DOB DATE NOT NULL,
    Department_ID INT NOT NULL,
    FOREIGN KEY (Department_ID) REFERENCES Departments(Dept_ID),

    -- Constraint: Gender must be either 'Male' or 'Female'
    CHECK (gender IN ('Male', 'Female')),

    -- Constraint: Date of Birth must be in the past
    CHECK (DOB < GETDATE())
);

-------------------------------------------------------------------------------------------


CREATE TABLE Patient_Phone (
    Patient_ID INT,
    phone_number NVARCHAR(20),
    PRIMARY KEY (Patient_ID, phone_number),
    FOREIGN KEY (Patient_ID) REFERENCES Patients(Patient_ID)
)

-------------------------------------------------------------------------------------------  


CREATE TABLE Medical_Records (
    Medical_Record_ID INT PRIMARY KEY,
    Patient_ID INT NOT NULL,
    Visit_Date DATE NOT NULL,
    Symptoms TEXT,
    Diagnosis VARCHAR(255),
        FOREIGN KEY (Patient_ID) REFERENCES Patients(Patient_ID)
)


-------------------------------------------------------------------------------------------

CREATE TABLE Medic_Doctors (
    Medic_Record_ID INT,
    Doctor_ID INT,

    PRIMARY KEY (Medic_Record_ID, Doctor_ID),
    FOREIGN KEY (Medic_Record_ID) REFERENCES Medical_Records(Medical_Record_ID),
    FOREIGN KEY (Doctor_ID) REFERENCES Doctors(Doctor_ID)
)

-------------------------------------------------------------------------------------------

CREATE TABLE Insurance_Providers (
    provider_ID INT PRIMARY KEY,
    Provider_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    insurance_type VARCHAR(50) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,


    -- Constraint: Email must contain '@' (basic validation)
    CHECK (Email LIKE '%@%')
);


-------------------------------------------------------------------------------------------
CREATE TABLE Insurance_Providers_Patient (
    patient_id INT,
    provider_id INT,
    PRIMARY KEY (patient_id, provider_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) ,
    FOREIGN KEY (provider_id) REFERENCES Insurance_Providers(provider_id) 
)

-------------------------------------------------------------------------------------------

CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY,  
    time TIME,                     
    date DATE,                     
    patient_id INT,                 
    doctor_id INT,                  
    confirmed BIT,             
    completed BIT,            
    canceled BIT,              
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id),
    CONSTRAINT chk_status CHECK (
        (CAST(confirmed AS INT) + CAST(completed AS INT) + CAST(canceled AS INT)) <= 1
    )
);
--------------------------------------------------------------------------------

CREATE TABLE Prescriptions (
    prescription_id INT PRIMARY KEY,     
    doctor_id INT,    
    patient_id INT,             
    date_prescribed DATE,                 
    medication_name VARCHAR(255),           
    expiry_date DATE,                
    dosage VARCHAR(100),                   
    instructions TEXT,          
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    CONSTRAINT chk_expiry_date CHECK (expiry_date > date_prescribed),  -- التأكد من أن تاريخ انتهاء الدواء بعد تاريخ الوصفة
    
);
-------------------------------------------------------------------------------------------


CREATE TABLE Prescriptions_Patient (
    prescription_id INT,                   
    patient_id INT,                         
    PRIMARY KEY (prescription_id, patient_id),  
    FOREIGN KEY (prescription_id) REFERENCES Prescriptions(prescription_id) ,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) 
)

-------------------------------------------------------------------------------------------  

CREATE TABLE Payment_Methods (
    payment_id INT PRIMARY KEY,              
    credit_card VARCHAR(20),                
    transaction_date DATE,                     
    amount DECIMAL(10, 2),                      
    pending BIT,                          
    failed BIT,                             
    completed BIT,                          
    cash BIT,                              
    insurance BIT,                          
    
    CONSTRAINT chk_amount CHECK (
        amount > 0   -- Ensure the amount is greater than zero
    ),
    CONSTRAINT chk_credit_card_length CHECK (
        LEN(credit_card) = 16 OR credit_card IS NULL  -- Ensure credit card number is 16 digits or null (for cash or insurance)
    )
);

-------------------------------------------------------------------------------------------

CREATE TABLE Reviews (
    review_id INT PRIMARY KEY,              
    date_submitted DATE,                    
    rating INT CHECK (rating BETWEEN 1 AND 5),  
    patient_id INT,                         
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) 
)

-------------------------------------------------------------------------------------------

CREATE TABLE Reviews_Comment (
    review_id INT,                          
    comment varchar(1000),  
    PRIMARY KEY (review_id, comment),  
    FOREIGN KEY (review_id) REFERENCES Reviews(review_id)  
)

-------------------------------------------------------------------------------------------

CREATE TABLE Patient_Payment (
    payment_id INT PRIMARY KEY,                         
    patient_id INT,                          
    FOREIGN KEY (payment_id) REFERENCES Payment_Methods(payment_id) ,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) 
)

-------------------------------------------------------------------------------------------


---tabelele cu sursele noastre de date

CREATE TABLE timesheets (
    timesheet_id      INT PRIMARY KEY,
    employee_code     VARCHAR(20),
    employee_name     VARCHAR(100),
    work_date         DATE,
    project_code      VARCHAR(20),
    task_name         VARCHAR(100),
    hours_logged      NUMERIC(5,2),
    notes             VARCHAR(255)
);


CREATE TABLE event_calendar (
    event_id          INT PRIMARY KEY,
    emp_ref           VARCHAR(20),
    full_name         VARCHAR(100),
    event_date        DATE,
    event_type        VARCHAR(50),
    duration_hours    NUMERIC(5,2),
    title             VARCHAR(150),
    organizer         VARCHAR(100)
);


CREATE TABLE absence_log (
    absence_id        INT PRIMARY KEY,
    emp_id            VARCHAR(20),
    emp_name          VARCHAR(100),
    absence_date      DATE,
    absence_type      VARCHAR(50),
    hours_absent      NUMERIC(5,2),
    approval_status   VARCHAR(20)
);

---date mock ce trebuie curatate

INSERT INTO timesheets
(timesheet_id, employee_code, employee_name, work_date, project_code, task_name, hours_logged, notes)
VALUES
(1, 'E001', 'Alice Green', DATE '2026-03-16', 'PRJ100', 'Backend Development', 6.50, 'API work'),
(2, 'e001', 'Alice Green', DATE '2026-03-16', 'INT001', 'Team Meeting', 1.50, 'Daily sync'),
(3, 'E002', 'Bob Smith', DATE '2026-03-16', 'PRJ200', 'Data Analysis', 7.00, 'Sales report'),
(4, 'E003', 'Carol White', DATE '2026-03-16', 'PRJ300', 'Testing', 8.00, 'Regression tests'),
(5, 'E-001', 'Alice Green', DATE '2026-03-17', 'PRJ100', 'Backend development', 7.00, 'Bug fixes'),
(6, 'E002', 'Bob Smith', DATE '2026-03-17', 'INT002', 'Training', 2.00, 'SQL training'),
(7, 'E003', 'Carol White', DATE '2026-03-17', 'PRJ300', 'Test Automation', 6.50, 'Selenium scripts'),
(8, 'E004', 'David Black', DATE '2026-03-17', 'PRJ400', 'Documentation', 5.00, 'User guide'),
(9, 'E004', 'David Black', DATE '2026-03-18', 'PRJ400', 'Documentation', 9.00, 'Long working day'),
(10, 'E005', NULL, DATE '2026-03-18', 'PRJ500', 'Support', 4.00, 'Ticket handling');

INSERT INTO event_calendar
(event_id, emp_ref, full_name, event_date, event_type, duration_hours, title, organizer)
VALUES
(101, 'E001', 'Alice Green', DATE '2026-03-16', 'Meeting', 1.00, 'Sprint Planning', 'Manager A'),
(102, 'E002', 'Bob Smith', DATE '2026-03-16', 'meeting', 0.50, '1:1 Check-in', 'Manager B'),
(103, 'E003', 'Carol White', DATE '2026-03-16', 'Workshop', 2.00, 'QA Workshop', 'Lead QA'),
(104, 'E004', 'David Black', DATE '2026-03-17', 'Training', 1.50, 'Documentation Standards', 'HR'),
(105, 'E-001', 'Alice Green', DATE '2026-03-17', 'MEETING', 0.50, 'Tech Sync', 'Architect'),
(106, 'E005', 'Eva Brown', DATE '2026-03-18', 'meeting ', 1.00, 'Support Review', 'Team Lead'),
(107, 'e002', 'Bob Smith', DATE '2026-03-18', 'Workshop', 3.00, 'Data Modeling Session', 'Architect');

INSERT INTO absence_log
(absence_id, emp_id, emp_name, absence_date, absence_type, hours_absent, approval_status)
VALUES
(201, 'E003', 'Carol White', DATE '2026-03-18', 'Vacation', 8.00, 'APPROVED'),
(202, 'E004', 'David Black', DATE '2026-03-18', 'Sick Leave', 4.00, 'APPROVED'),
(203, 'E005', 'Eva Brown', DATE '2026-03-19', 'vacation', 8.00, 'PENDING'),
(204, 'E001', 'Alice Green', DATE '2026-03-19', 'PTO', 8.00, 'APPROVED'),
(205, 'e002', 'Bob Smith', DATE '2026-03-19', 'SICK', 8.00, 'APPROVED');

---curaterea datelor

CREATE VIEW stg_timesheets AS
SELECT
    timesheet_id AS source_record_id,
    UPPER(REPLACE(employee_code, '-', '')) AS employee_code,
    employee_name,
    work_date AS activity_date,
    'WORK' AS activity_category,
    TRIM(task_name) AS activity_type,
    project_code,
    hours_logged AS hours_value,
    notes,
    CAST(NULL AS VARCHAR(100)) AS organizer,
    CAST(NULL AS VARCHAR(20)) AS approval_status,
    CAST(NULL AS VARCHAR(150)) AS activity_title,
    'TIMESHEET' AS source_name
FROM timesheets;

CREATE VIEW stg_event_calendar AS
SELECT
    event_id AS source_record_id,
    UPPER(REPLACE(emp_ref, '-', '')) AS employee_code,
    full_name AS employee_name,
    event_date AS activity_date,
    'EVENT' AS activity_category,
    INITCAP(TRIM(event_type)) AS activity_type,
    CAST(NULL AS VARCHAR(20)) AS project_code,
    duration_hours AS hours_value,
    CAST(NULL AS VARCHAR(255)) AS notes,
    organizer,
    CAST(NULL AS VARCHAR(20)) AS approval_status,
    title AS activity_title,
    'EVENT_CALENDAR' AS source_name
FROM event_calendar;

CREATE VIEW stg_absence_log AS
SELECT
    absence_id AS source_record_id,
    UPPER(REPLACE(emp_id, '-', '')) AS employee_code,
    emp_name AS employee_name,
    absence_date AS activity_date,
    'ABSENCE' AS activity_category,
    CASE
        WHEN UPPER(TRIM(absence_type)) = 'SICK' THEN 'Sick Leave'
        WHEN UPPER(TRIM(absence_type)) = 'VACATION' THEN 'Vacation'
        WHEN UPPER(TRIM(absence_type)) = 'PTO' THEN 'PTO'
        ELSE INITCAP(TRIM(absence_type))
    END AS activity_type,
    CAST(NULL AS VARCHAR(20)) AS project_code,
    hours_absent AS hours_value,
    CAST(NULL AS VARCHAR(255)) AS notes,
    CAST(NULL AS VARCHAR(100)) AS organizer,
    UPPER(TRIM(approval_status)) AS approval_status,
    CAST(NULL AS VARCHAR(150)) AS activity_title,
    'ABSENCE_LOG' AS source_name
FROM absence_log;

SELECT * FROM stg_timesheets;
SELECT * FROM stg_event_calendar;
SELECT * FROM stg_absence_log;

CREATE VIEW stg_employee_activity AS
SELECT * FROM stg_timesheets
UNION ALL
SELECT * FROM stg_event_calendar
UNION ALL
SELECT * FROM stg_absence_log;

select * from stg_employee_activity
ORDER BY employee_code, activity_date, source_name;

--- dimneison tables pentru star schema

CREATE TABLE dim_employee (
    employee_key   INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_code  VARCHAR(20) UNIQUE,
    employee_name  VARCHAR(100)
);

INSERT INTO dim_employee (employee_code, employee_name)
SELECT
    employee_code,
    MAX(employee_name) AS employee_name
FROM stg_employee_activity
GROUP BY employee_code;

select * from dim_employee;
----
CREATE TABLE dim_date (
    date_key      INT PRIMARY KEY,
    full_date     DATE UNIQUE,
    day_number    INT,
    month_number  INT,
    year_number   INT,
    day_name      VARCHAR(20)
);

INSERT INTO dim_date (
    date_key,
    full_date,
    day_number,
    month_number,
    year_number,
    day_name
)
SELECT DISTINCT
    EXTRACT(YEAR FROM activity_date) * 10000
      + EXTRACT(MONTH FROM activity_date) * 100
      + EXTRACT(DAY FROM activity_date) AS date_key,
    activity_date,
    EXTRACT(DAY FROM activity_date),
    EXTRACT(MONTH FROM activity_date),
    EXTRACT(YEAR FROM activity_date),
    TO_CHAR(activity_date, 'Day')
FROM stg_employee_activity;

select * from dim_date;
----

CREATE TABLE dim_activity_type (
    activity_type_key INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    activity_category VARCHAR(30),
    activity_type     VARCHAR(50)
);

INSERT INTO dim_activity_type (activity_category, activity_type)
SELECT DISTINCT
    activity_category,
    activity_type
FROM stg_employee_activity;

select * from dim_activity_type;

----

CREATE TABLE fact_employee_activity (
    activity_key        INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employee_key        INT NOT NULL,
    date_key            INT NOT NULL,
    activity_type_key   INT NOT NULL,

    source_record_id    INT NOT NULL,
    source_name         VARCHAR(30),

    hours_value         NUMERIC(5,2) NOT NULL,

    project_code        VARCHAR(20),
    activity_title      VARCHAR(150),
    organizer           VARCHAR(100),
    approval_status     VARCHAR(20),
    notes               VARCHAR(255),

    FOREIGN KEY (employee_key) REFERENCES dim_employee(employee_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (activity_type_key) REFERENCES dim_activity_type(activity_type_key)
);

INSERT INTO fact_employee_activity (
    employee_key,
    date_key,
    activity_type_key,
    source_record_id,
    source_name,
    hours_value,
    project_code,
    activity_title,
    organizer,
    approval_status,
    notes
)
SELECT
    e.employee_key,
    d.date_key,
    a.activity_type_key,
    s.source_record_id,
    s.source_name,
    s.hours_value,
    s.project_code,
    s.activity_title,
    s.organizer,
    s.approval_status,
    s.notes
FROM stg_employee_activity s
JOIN dim_employee e
    ON s.employee_code = e.employee_code
JOIN dim_date d
    ON s.activity_date = d.full_date
JOIN dim_activity_type a
    ON s.activity_category = a.activity_category
   AND s.activity_type = a.activity_type;


select * from fact_employee_activity
ORDER BY employee_key, date_key, activity_type_key;

---verificare ca numerele sa fie la fel in staging si in fact
SELECT COUNT(*) FROM stg_employee_activity;

SELECT COUNT(*) FROM fact_employee_activity;

---query pentru a vedea total ore pe zi, angajat, categorie si tip activitate
SELECT
    d.full_date,
    e.employee_code,
    e.employee_name,
    a.activity_category,
    a.activity_type,
    f.hours_value
FROM fact_employee_activity f
JOIN dim_date d
    ON f.date_key = d.date_key
JOIN dim_employee e
    ON f.employee_key = e.employee_key
JOIN dim_activity_type a
    ON f.activity_type_key = a.activity_type_key
ORDER BY
    d.full_date,
    e.employee_code,
    a.activity_category,
    a.activity_type;

---query "to show activities by day, by employees"
SELECT
    d.full_date,
    e.employee_code,
    e.employee_name,
    SUM(CASE WHEN a.activity_category = 'WORK' THEN f.hours_value ELSE 0 END) AS work_hours,
    SUM(CASE WHEN a.activity_category = 'EVENT' THEN f.hours_value ELSE 0 END) AS event_hours,
    SUM(CASE WHEN a.activity_category = 'ABSENCE' THEN f.hours_value ELSE 0 END) AS absence_hours,
    SUM(f.hours_value) AS total_hours
FROM fact_employee_activity f
JOIN dim_date d
    ON f.date_key = d.date_key
JOIN dim_employee e
    ON f.employee_key = e.employee_key
JOIN dim_activity_type a
    ON f.activity_type_key = a.activity_type_key
GROUP BY
    d.full_date,
    e.employee_code,
    e.employee_name
ORDER BY
    d.full_date,
    e.employee_code;

COMMIT;


--Creare tabele
CREATE TABLE departamente (
    departament_id      NUMBER          NOT NULL,
    cod_departament     VARCHAR2(10)    NOT NULL,
    nume_departament    VARCHAR2(100)   NOT NULL,

    CONSTRAINT pk_departament
        PRIMARY KEY (departament_id),

    CONSTRAINT uq_cod_departament
        UNIQUE (cod_departament)
);
-----------------------
CREATE TABLE angajati (
    angajat_id          NUMBER          NOT NULL,
    departament_id      NUMBER          NOT NULL,
    nume                VARCHAR2(50)    NOT NULL,
    prenume             VARCHAR2(50)    NOT NULL,
    email               VARCHAR2(100)   NOT NULL,
    functie             VARCHAR2(50)    NOT NULL,
    data_angajare       DATE            NOT NULL,
    status_angajat      VARCHAR2(20)    DEFAULT 'ACTIV' NOT NULL,

    CONSTRAINT pk_angajat
        PRIMARY KEY (angajat_id),

    CONSTRAINT fk_departament_angajat
        FOREIGN KEY (departament_id)
        REFERENCES departamente(departament_id),

    CONSTRAINT uq_email_angajat
        UNIQUE (email),

    CONSTRAINT ck_status_angajat
        CHECK (status_angajat IN ('ACTIV', 'INACTIV', 'CONCEDIU'))
);
-----------------------
CREATE TABLE proiecte (
    proiect_id          NUMBER          NOT NULL,
    cod_proiect         VARCHAR2(20)    NOT NULL,
    nume_proiect        VARCHAR2(100)   NOT NULL,
    client              VARCHAR2(100)   NOT NULL,
    data_start          DATE            NOT NULL,
    data_sfarsit        DATE,
    status_proiect      VARCHAR2(20)    DEFAULT 'ACTIV' NOT NULL,
    prioritate          VARCHAR2(10),

    CONSTRAINT pk_proiect
        PRIMARY KEY (proiect_id),

    CONSTRAINT uq_cod_proiect
        UNIQUE (cod_proiect),

    CONSTRAINT ck_perioada_proiect
        CHECK (data_sfarsit IS NULL OR data_sfarsit >= data_start),

    CONSTRAINT ck_proiecte_status
        CHECK (status_proiect IN ('ACTIV', 'INCHIS', 'SUSPENDAT')),

    CONSTRAINT ck_proiecte_prioritate
        CHECK (prioritate IN ('LOW', 'MEDIUM', 'HIGH'))
);
---------------------------
CREATE TABLE pontaje (
    pontaj_id           NUMBER          NOT NULL,
    angajat_id          NUMBER          NOT NULL,
    proiect_id          NUMBER          NOT NULL,
    data_pontaj         DATE            NOT NULL,
    ore_lucrate         NUMBER(4,2)     NOT NULL,
    tip_activitate      VARCHAR2(20)    NOT NULL,
    status_aprobare     VARCHAR2(20)    DEFAULT 'IN_ASTEPTARE' NOT NULL,
    detalii_extra       JSON,
    data_inregistrare   DATE            DEFAULT SYSDATE NOT NULL,

    CONSTRAINT pk_pontaj
        PRIMARY KEY (pontaj_id),

    CONSTRAINT fk_pontaj_angajat
        FOREIGN KEY (angajat_id)
        REFERENCES angajati(angajat_id),

    CONSTRAINT fk_pontaj_proiect
        FOREIGN KEY (proiect_id)
        REFERENCES proiecte(proiect_id),

    CONSTRAINT ck_ore_pontaj
        CHECK (ore_lucrate BETWEEN 4 AND 12),

    CONSTRAINT ck_tip_activitate_pontaj
        CHECK (tip_activitate IN (
            'ANALIZA',
            'DEVELOPMENT',
            'TESTARE',
            'SUPORT',
            'MEETING',
            'ADMINISTRATIV'
        )),

    CONSTRAINT ck_status_aprobare_pontaj
        CHECK (status_aprobare IN (
            'IN_ASTEPTARE',
            'APROBAT',
            'RESPINS'
        )),

    CONSTRAINT uq_pontaj
        UNIQUE (angajat_id, proiect_id, data_pontaj, tip_activitate)
);
--Triggere

CREATE OR REPLACE TRIGGER trg_proiecte_data_start
BEFORE INSERT OR UPDATE ON proiecte
FOR EACH ROW
BEGIN
    IF :NEW.data_start > SYSDATE THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Data de start a proiectului nu poate fi in viitor.'
        );
    END IF;
END;
/
--
CREATE OR REPLACE TRIGGER trg_angajati_data_angajare
BEFORE INSERT OR UPDATE ON angajati
FOR EACH ROW
BEGIN
    IF :NEW.data_angajare > SYSDATE THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Data de angajare nu poate fi in viitor.'
        );
    END IF;
END;
/
--
CREATE OR REPLACE TRIGGER trg_pontaje_date
BEFORE INSERT OR UPDATE ON pontaje
FOR EACH ROW
BEGIN
    IF :NEW.data_pontaj > SYSDATE THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'Data pontajului nu poate fi in viitor.'
        );
    END IF;

    IF :NEW.data_inregistrare > SYSDATE THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'Data inregistrarii nu poate fi in viitor.'
        );
    END IF;
END;
/
-- daca cineva introduce manual data_inregistrare, suntem safe

--NUmerotare/secvente pentru id

CREATE SEQUENCE seq_departamente
    START WITH 1
    INCREMENT BY 1;

CREATE SEQUENCE seq_angajati
    START WITH 1
    INCREMENT BY 1;

CREATE SEQUENCE seq_proiecte
    START WITH 1
    INCREMENT BY 1;

CREATE SEQUENCE seq_pontaje
    START WITH 1
    INCREMENT BY 1;

--Inserare date

INSERT INTO departamente (departament_id, cod_departament, nume_departament)
VALUES (seq_departamente.NEXTVAL, 'DEV', 'Developing Software');

INSERT INTO departamente (departament_id, cod_departament, nume_departament)
VALUES (seq_departamente.NEXTVAL, 'QA', 'Quality Assurance');

INSERT INTO departamente (departament_id, cod_departament, nume_departament)
VALUES (seq_departamente.NEXTVAL, 'DEVOPS', 'DevOps');

--

INSERT INTO angajati (
    angajat_id,
    departament_id,
    nume,
    prenume,
    email,
    functie,
    data_angajare,
    status_angajat
) VALUES (
    seq_angajati.NEXTVAL,
    1,
    'Popescu',
    'Andrei',
    'andrei.popescu@company.ro',
    'Developer',
    DATE '2022-03-15',
    'ACTIV'
);

INSERT INTO angajati (
    angajat_id,
    departament_id,
    nume,
    prenume,
    email,
    functie,
    data_angajare,
    status_angajat
) VALUES (
    seq_angajati.NEXTVAL,
    1,
    'Ionescu',
    'Maria',
    'maria.ionescu@company.ro',
    'Developer',
    DATE '2021-09-10',
    'ACTIV'
);

INSERT INTO angajati (
    angajat_id,
    departament_id,
    nume,
    prenume,
    email,
    functie,
    data_angajare,
    status_angajat
) VALUES (
    seq_angajati.NEXTVAL,
    2,
    'Georgescu',
    'Radu',
    'radu.georgescu@company.ro',
    'QA Engineer',
    DATE '2023-01-20',
    'CONCEDIU'
);

INSERT INTO angajati (
    angajat_id,
    departament_id,
    nume,
    prenume,
    email,
    functie,
    data_angajare,
    status_angajat
) VALUES (
    seq_angajati.NEXTVAL,
    3,
    'Dumitrescu',
    'Elena',
    'elena.dumitrescu@company.ro',
    'Operator',
    DATE '2020-06-01',
    'ACTIV'
);

--

INSERT INTO proiecte (
    proiect_id,
    cod_proiect,
    nume_proiect,
    client,
    data_start,
    data_sfarsit,
    status_proiect,
    prioritate
) VALUES (
    seq_proiecte.NEXTVAL,
    'PRJ001',
    'Platforma Timesheet Web',
    'Endava Internal',
    DATE '2024-01-10',
    NULL,
    'ACTIV',
    'HIGH'
);

INSERT INTO proiecte (
    proiect_id,
    cod_proiect,
    nume_proiect,
    client,
    data_start,
    data_sfarsit,
    status_proiect,
    prioritate
) VALUES (
    seq_proiecte.NEXTVAL,
    'PRJ002',
    'Aplicatie Raportare HR',
    'Tech Solutions SRL',
    DATE '2023-05-01',
    DATE '2024-12-15',
    'INCHIS',
    'MEDIUM'
);

INSERT INTO proiecte (
    proiect_id,
    cod_proiect,
    nume_proiect,
    client,
    data_start,
    data_sfarsit,
    status_proiect,
    prioritate
) VALUES (
    seq_proiecte.NEXTVAL,
    'PRJ003',
    'Sistem Audit Intern',
    'Audit Consulting',
    DATE '2025-02-20',
    NULL,
    'SUSPENDAT',
    'LOW'
);

--

INSERT INTO pontaje (
    pontaj_id,
    angajat_id,
    proiect_id,
    data_pontaj,
    ore_lucrate,
    tip_activitate,
    status_aprobare,
    detalii_extra,
    data_inregistrare
) VALUES (
    seq_pontaje.NEXTVAL,
    1,
    1,
    DATE '2026-03-10',
    8.00,
    'DEVELOPMENT',
    'APROBAT',
    JSON('{"mod_lucru":"remote","ticket":"TS-101"}'),
    SYSDATE
);

INSERT INTO pontaje (
    pontaj_id,
    angajat_id,
    proiect_id,
    data_pontaj,
    ore_lucrate,
    tip_activitate,
    status_aprobare,
    detalii_extra,
    data_inregistrare
) VALUES (
    seq_pontaje.NEXTVAL,
    1,
    1,
    DATE '2026-03-11',
    6.50,
    'MEETING',
    'IN_ASTEPTARE',
    JSON('{"mod_lucru":"office","ticket":"TS-102"}'),
    SYSDATE
);

INSERT INTO pontaje (
    pontaj_id,
    angajat_id,
    proiect_id,
    data_pontaj,
    ore_lucrate,
    tip_activitate,
    status_aprobare,
    detalii_extra,
    data_inregistrare
) VALUES (
    seq_pontaje.NEXTVAL,
    2,
    2,
    DATE '2026-03-10',
    7.00,
    'ANALIZA',
    'RESPINS',
    JSON('{"mod_lucru":"remote","ticket":"HR-205"}'),
    SYSDATE
);

INSERT INTO pontaje (
    pontaj_id,
    angajat_id,
    proiect_id,
    data_pontaj,
    ore_lucrate,
    tip_activitate,
    status_aprobare,
    detalii_extra,
    data_inregistrare
) VALUES (
    seq_pontaje.NEXTVAL,
    3,
    1,
    DATE '2026-03-12',
    4.00,
    'TESTARE',
    'APROBAT',
    JSON('{"mod_lucru":"office","ticket":"QA-310"}'),
    SYSDATE
);

INSERT INTO pontaje (
    pontaj_id,
    angajat_id,
    proiect_id,
    data_pontaj,
    ore_lucrate,
    tip_activitate,
    status_aprobare,
    detalii_extra,
    data_inregistrare
) VALUES (
    seq_pontaje.NEXTVAL,
    4,
    3,
    DATE '2026-03-13',
    5.50,
    'SUPORT',
    'IN_ASTEPTARE',
    JSON('{"mod_lucru":"office","ticket":"AUD-404"}'),
    SYSDATE
);

--popularea datelor
COMMIT;

---indexi

CREATE INDEX idx_proiecte_status
    ON proiecte(status_proiect);

CREATE INDEX idx_pontaje_data_pontaj
    ON pontaje(data_pontaj);

CREATE INDEX idx_pontaje_tip_activitate
    ON pontaje(tip_activitate);

--indexi pe fk(best pratice pentru ca in oracle se pun automat doar pe pk si unique)
CREATE INDEX idx_angajati_departament
    ON angajati(departament_id);

CREATE INDEX idx_pontaje_angajat
    ON pontaje(angajat_id);

CREATE INDEX idx_pontaje_proiect
    ON pontaje(proiect_id);

---use case pentru indexi

--verifica proiectele active sibenificiaza de indexul pe status_proiect
SELECT *
FROM proiecte
WHERE status_proiect = 'ACTIV';

--afiseaza pontajele din luna martie 2026 si benificiaza de indexul pe data_pontaj
SELECT *
FROM pontaje
WHERE data_pontaj BETWEEN DATE '2026-03-01' AND DATE '2026-03-31';

--afiseaza pontajele de tip DEVELOPMENT beneficiaza de indexul pe tip_activitate
SELECT *
FROM pontaje
WHERE tip_activitate = 'DEVELOPMENT';

---view & materialized view

CREATE OR REPLACE VIEW vw_raport_pontaje AS
SELECT
    p.pontaj_id,
    a.angajat_id,
    a.nume,
    a.prenume,
    d.nume_departament,
    pr.cod_proiect,
    pr.nume_proiect,
    p.data_pontaj,
    p.ore_lucrate,
    p.tip_activitate,
    p.status_aprobare,
    p.detalii_extra,
    p.data_inregistrare
FROM pontaje p
JOIN angajati a
    ON p.angajat_id = a.angajat_id
JOIN departamente d
    ON a.departament_id = d.departament_id
JOIN proiecte pr
    ON p.proiect_id = pr.proiect_id;

CREATE MATERIALIZED VIEW mv_total_ore_angajat_proiect
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    a.angajat_id,
    a.nume,
    a.prenume,
    pr.proiect_id,
    pr.nume_proiect,
    SUM(p.ore_lucrate) AS total_ore_lucrate
FROM pontaje p
JOIN angajati a
    ON p.angajat_id = a.angajat_id
JOIN proiecte pr
    ON p.proiect_id = pr.proiect_id
GROUP BY
    a.angajat_id,
    a.nume,
    a.prenume,
    pr.proiect_id,
    pr.nume_proiect;


--refresh manual - reface manual materialized view cu totalul orelor lucrate pe angajat si proiect
BEGIN
    DBMS_MVIEW.REFRESH('MV_TOTAL_ORE_ANGAJAT_PROIECT');
END;
/

----cerinte legate de select

--group by
-- Aceasta interogare calculeaza numarul total de ore lucrate de fiecare angajat pe fiecare proiect.
SELECT
    a.nume,
    a.prenume,
    pr.nume_proiect,
    SUM(p.ore_lucrate) AS total_ore_lucrate
FROM pontaje p
JOIN angajati a
    ON p.angajat_id = a.angajat_id
JOIN proiecte pr
    ON p.proiect_id = pr.proiect_id
GROUP BY
    a.angajat_id,
    a.nume,
    a.prenume,
    pr.nume_proiect
ORDER BY
    a.nume,
    a.prenume,
    pr.nume_proiect;

--left join
-- afiseaza toate proiectele si pontajele asociate
SELECT
    pr.nume_proiect,
    pr.status_proiect,
    p.pontaj_id,
    p.data_pontaj,
    p.ore_lucrate
FROM proiecte pr
LEFT JOIN pontaje p
    ON pr.proiect_id = p.proiect_id
ORDER BY
    pr.nume_proiect,
    p.data_pontaj;

--functia analitica

--clasifica angajatii in functie de totalul orelor lucrate folosind RANK
SELECT
    nume,
    prenume,
    total_ore_lucrate,
    RANK() OVER (ORDER BY total_ore_lucrate DESC) AS clasament
FROM (
    SELECT
        a.nume,
        a.prenume,
        SUM(p.ore_lucrate) AS total_ore_lucrate
    FROM pontaje p
    JOIN angajati a
        ON p.angajat_id = a.angajat_id
    GROUP BY
        a.angajat_id,
        a.nume,
        a.prenume
) rezultat
ORDER BY
    clasament,
    nume,
    prenume;

--bonus

--afiseaza pontajele pentru care modul de lucru este remote
SELECT
    pontaj_id,
    data_pontaj,
    ore_lucrate,
    tip_activitate,
    detalii_extra
FROM pontaje
WHERE JSON_VALUE(detalii_extra, '$.mod_lucru') = 'remote';


---test trigger - trebuie sa dea eroare

INSERT INTO proiecte (
    proiect_id,
    cod_proiect,
    nume_proiect,
    client,
    data_start,
    data_sfarsit,
    status_proiect,
    prioritate
) VALUES (
    seq_proiecte.NEXTVAL,
    'PRJ999',
    'Proiect Test Viitor',
    'Client Demo',
    DATE '2030-01-01',
    NULL,
    'ACTIV',
    'HIGH'
);

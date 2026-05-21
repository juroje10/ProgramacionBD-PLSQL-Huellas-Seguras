-- ============================================================
--  SISTEMA "HUELLAS SEGURAS" — DDL COMPLETO
--  Tablas, Constraints, Secuencias y Triggers
--  Base de datos: Oracle Database
--  Fecha: Mayo 2026
-- ============================================================


-- ============================================================
--  0. LIMPIEZA PREVIA (ejecutar si ya existen los objetos)
--     Descomentar solo si se quiere reinstalar desde cero
-- ============================================================

-- DROP TRIGGER TRG_FECHA_ACTUALIZACION;
-- DROP TRIGGER TRG_AUDITORIA_ESTADO;
-- DROP TABLE LOG_ANIMALES       CASCADE CONSTRAINTS;
-- DROP TABLE HISTORIAL_MEDICO   CASCADE CONSTRAINTS;
-- DROP TABLE ADOPCIONES         CASCADE CONSTRAINTS;
-- DROP TABLE ADOPTANTES         CASCADE CONSTRAINTS;
-- DROP TABLE ANIMALES           CASCADE CONSTRAINTS;
-- DROP SEQUENCE SEQ_LOG;
-- DROP SEQUENCE SEQ_HISTORIAL;
-- DROP SEQUENCE SEQ_ADOPCIONES;
-- DROP SEQUENCE SEQ_ADOPTANTES;
-- DROP SEQUENCE SEQ_ANIMALES;


-- ============================================================
--  1. SECUENCIAS
--     Cada tabla usa su propia secuencia para generar
--     claves primarias unicas y consecutivas.
-- ============================================================

CREATE SEQUENCE SEQ_ANIMALES
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_ADOPTANTES
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_ADOPCIONES
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_HISTORIAL
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;

CREATE SEQUENCE SEQ_LOG
    START WITH 1
    INCREMENT BY 1
    NOCACHE
    NOCYCLE;


-- ============================================================
--  2. TABLAS
-- ============================================================

-- ------------------------------------------------------------
--  2.1 ANIMALES
--      Registra todos los animales presentes o que han
--      pasado por la protectora.
-- ------------------------------------------------------------
CREATE TABLE ANIMALES (
    ID_ANIMAL           NUMBER          NOT NULL,
    NOMBRE              VARCHAR2(100)   NOT NULL,
    ESPECIE             VARCHAR2(50)    NOT NULL,
    RAZA                VARCHAR2(100),
    FECHA_ENTRADA       DATE            NOT NULL,
    ESTADO              VARCHAR2(20)    NOT NULL,
    OBSERVACIONES       VARCHAR2(500),
    FECHA_ACTUALIZACION DATE,

    -- Clave primaria
    CONSTRAINT PK_ANIMALES
        PRIMARY KEY (ID_ANIMAL),

    -- El estado solo puede tomar los tres valores definidos
    CONSTRAINT CHK_ESTADO_ANIMAL
        CHECK (ESTADO IN ('DISPONIBLE', 'EN_TRATAMIENTO', 'ADOPTADO'))
);

COMMENT ON TABLE  ANIMALES                    IS 'Animales alojados o que han pasado por la protectora';
COMMENT ON COLUMN ANIMALES.ID_ANIMAL          IS 'Identificador unico generado por SEQ_ANIMALES';
COMMENT ON COLUMN ANIMALES.ESTADO             IS 'Estado del animal: DISPONIBLE, EN_TRATAMIENTO o ADOPTADO';
COMMENT ON COLUMN ANIMALES.FECHA_ACTUALIZACION IS 'Actualizado automaticamente por TRG_FECHA_ACTUALIZACION';


-- ------------------------------------------------------------
--  2.2 ADOPTANTES
--      Personas fisicas registradas para adoptar animales.
-- ------------------------------------------------------------
CREATE TABLE ADOPTANTES (
    ID_ADOPTANTE    NUMBER          NOT NULL,
    NOMBRE          VARCHAR2(100)   NOT NULL,
    DNI             VARCHAR2(15)    NOT NULL,
    EMAIL           VARCHAR2(150)   NOT NULL,
    TELEFONO        VARCHAR2(20)    NOT NULL,
    FECHA_REGISTRO  DATE            NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_ADOPTANTES
        PRIMARY KEY (ID_ADOPTANTE),

    -- El DNI debe ser unico en el sistema
    CONSTRAINT UQ_ADOPTANTES_DNI
        UNIQUE (DNI),

    -- El email debe ser unico en el sistema
    CONSTRAINT UQ_ADOPTANTES_EMAIL
        UNIQUE (EMAIL)
);

COMMENT ON TABLE  ADOPTANTES               IS 'Personas registradas que desean o han adoptado un animal';
COMMENT ON COLUMN ADOPTANTES.ID_ADOPTANTE  IS 'Identificador unico generado por SEQ_ADOPTANTES';
COMMENT ON COLUMN ADOPTANTES.DNI           IS 'Documento de identidad. Valor unico obligatorio';
COMMENT ON COLUMN ADOPTANTES.EMAIL         IS 'Correo electronico. Valor unico obligatorio';


-- ------------------------------------------------------------
--  2.3 ADOPCIONES
--      Registro permanente de cada adopcion formalizada.
--      No debe modificarse manualmente una vez creada.
-- ------------------------------------------------------------
CREATE TABLE ADOPCIONES (
    ID_ADOPCION     NUMBER          NOT NULL,
    ID_ANIMAL       NUMBER          NOT NULL,
    ID_ADOPTANTE    NUMBER          NOT NULL,
    FECHA_ADOPCION  DATE            NOT NULL,
    OBSERVACIONES   VARCHAR2(500),

    -- Clave primaria
    CONSTRAINT PK_ADOPCIONES
        PRIMARY KEY (ID_ADOPCION),

    -- Un animal solo puede aparecer una vez (no puede adoptarse dos veces)
    CONSTRAINT UQ_ADOPCION_ANIMAL
        UNIQUE (ID_ANIMAL),

    -- FK: el animal debe existir en ANIMALES
    -- RESTRICT: no se puede borrar un animal con adopcion asociada
    CONSTRAINT FK_ADOPCION_ANIMAL
        FOREIGN KEY (ID_ANIMAL)
        REFERENCES ANIMALES (ID_ANIMAL),

    -- FK: el adoptante debe existir en ADOPTANTES
    -- RESTRICT: no se puede borrar un adoptante con adopciones
    CONSTRAINT FK_ADOPCION_ADOPTANTE
        FOREIGN KEY (ID_ADOPTANTE)
        REFERENCES ADOPTANTES (ID_ADOPTANTE)
);

COMMENT ON TABLE  ADOPCIONES              IS 'Registro permanente de cada adopcion formalizada';
COMMENT ON COLUMN ADOPCIONES.ID_ADOPCION  IS 'Identificador unico generado por SEQ_ADOPCIONES';
COMMENT ON COLUMN ADOPCIONES.ID_ANIMAL    IS 'FK a ANIMALES. Unico: un animal no puede adoptarse dos veces';


-- ------------------------------------------------------------
--  2.4 HISTORIAL_MEDICO
--      Registro cronologico de visitas veterinarias
--      e intervenciones por animal.
-- ------------------------------------------------------------
CREATE TABLE HISTORIAL_MEDICO (
    ID_HISTORIAL    NUMBER          NOT NULL,
    ID_ANIMAL       NUMBER          NOT NULL,
    FECHA_VISITA    DATE            NOT NULL,
    DESCRIPCION     VARCHAR2(1000)  NOT NULL,
    COSTE           NUMBER(8,2),
    VETERINARIO     VARCHAR2(100),

    -- Clave primaria
    CONSTRAINT PK_HISTORIAL_MEDICO
        PRIMARY KEY (ID_HISTORIAL),

    -- FK: el animal debe existir en ANIMALES
    -- CASCADE: si se borra el animal, su historial se borra tambien
    CONSTRAINT FK_HISTORIAL_ANIMAL
        FOREIGN KEY (ID_ANIMAL)
        REFERENCES ANIMALES (ID_ANIMAL)
        ON DELETE CASCADE
);

COMMENT ON TABLE  HISTORIAL_MEDICO             IS 'Visitas veterinarias e intervenciones de cada animal';
COMMENT ON COLUMN HISTORIAL_MEDICO.ID_HISTORIAL IS 'Identificador unico generado por SEQ_HISTORIAL';
COMMENT ON COLUMN HISTORIAL_MEDICO.COSTE        IS 'Coste de la intervencion en euros. Campo opcional';


-- ------------------------------------------------------------
--  2.5 LOG_ANIMALES
--      Tabla de auditoria. Se rellena exclusivamente
--      mediante el trigger TRG_AUDITORIA_ESTADO.
--      Ningun usuario de aplicacion puede insertar,
--      modificar ni borrar filas directamente.
-- ------------------------------------------------------------
CREATE TABLE LOG_ANIMALES (
    ID_LOG          NUMBER          NOT NULL,
    ID_ANIMAL       NUMBER          NOT NULL,
    ESTADO_ANTERIOR VARCHAR2(20),
    ESTADO_NUEVO    VARCHAR2(20)    NOT NULL,
    FECHA_CAMBIO    DATE            NOT NULL,
    USUARIO_BD      VARCHAR2(50)    NOT NULL,

    -- Clave primaria
    CONSTRAINT PK_LOG_ANIMALES
        PRIMARY KEY (ID_LOG)
);

COMMENT ON TABLE  LOG_ANIMALES               IS 'Auditoria automatica de cambios de estado en ANIMALES. Solo escritura via trigger';
COMMENT ON COLUMN LOG_ANIMALES.ID_LOG        IS 'Identificador unico generado por SEQ_LOG';
COMMENT ON COLUMN LOG_ANIMALES.ESTADO_ANTERIOR IS 'Estado antes del cambio (:OLD.ESTADO)';
COMMENT ON COLUMN LOG_ANIMALES.ESTADO_NUEVO    IS 'Estado despues del cambio (:NEW.ESTADO)';
COMMENT ON COLUMN LOG_ANIMALES.USUARIO_BD      IS 'Usuario de sesion Oracle que realizo la operacion (USER)';


-- ============================================================
--  3. TRIGGERS
-- ============================================================

-- ------------------------------------------------------------
--  3.1 TRG_FECHA_ACTUALIZACION
--      Se dispara BEFORE UPDATE en ANIMALES (nivel fila).
--      Asigna automaticamente SYSDATE al campo
--      FECHA_ACTUALIZACION sin que el programador
--      tenga que recordarlo.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_FECHA_ACTUALIZACION
    BEFORE UPDATE ON ANIMALES
    FOR EACH ROW
BEGIN
    :NEW.FECHA_ACTUALIZACION := SYSDATE;
END TRG_FECHA_ACTUALIZACION;
/


-- ------------------------------------------------------------
--  3.2 TRG_AUDITORIA_ESTADO
--      Se dispara AFTER UPDATE OF ESTADO en ANIMALES
--      (nivel fila) solo cuando el estado realmente cambia.
--      Inserta una fila en LOG_ANIMALES con todos los
--      detalles del cambio.
-- ------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_ESTADO
    AFTER UPDATE OF ESTADO ON ANIMALES
    FOR EACH ROW
    WHEN (OLD.ESTADO <> NEW.ESTADO)
BEGIN
    INSERT INTO LOG_ANIMALES (
        ID_LOG,
        ID_ANIMAL,
        ESTADO_ANTERIOR,
        ESTADO_NUEVO,
        FECHA_CAMBIO,
        USUARIO_BD
    ) VALUES (
        SEQ_LOG.NEXTVAL,
        :OLD.ID_ANIMAL,
        :OLD.ESTADO,
        :NEW.ESTADO,
        SYSDATE,
        USER
    );
END TRG_AUDITORIA_ESTADO;
/


-- ============================================================
--  4. INDICES ADICIONALES
--     Mejoran el rendimiento de las consultas mas habituales
--     en la aplicacion APEX.
-- ============================================================

-- Busquedas de animales por estado (Dashboard, pagina de adopcion)
CREATE INDEX IDX_ANIMALES_ESTADO
    ON ANIMALES (ESTADO);

-- Busquedas de historial por animal
CREATE INDEX IDX_HISTORIAL_ANIMAL
    ON HISTORIAL_MEDICO (ID_ANIMAL);

-- Busquedas de log por animal y fecha
CREATE INDEX IDX_LOG_ANIMAL_FECHA
    ON LOG_ANIMALES (ID_ANIMAL, FECHA_CAMBIO);

-- Busquedas de adoptantes por DNI o email
CREATE INDEX IDX_ADOPTANTES_DNI
    ON ADOPTANTES (DNI);

CREATE INDEX IDX_ADOPTANTES_EMAIL
    ON ADOPTANTES (EMAIL);


-- ============================================================
--  5. DATOS DE PRUEBA
--     Registros minimos para verificar el funcionamiento
--     del sistema y los triggers.
-- ============================================================

-- Animales iniciales
INSERT INTO ANIMALES (ID_ANIMAL, NOMBRE, ESPECIE, RAZA, FECHA_ENTRADA, ESTADO, OBSERVACIONES)
VALUES (SEQ_ANIMALES.NEXTVAL, 'Luna',   'Perro', 'Labrador',       DATE '2026-01-10', 'DISPONIBLE',     'Muy sociable y activa');

INSERT INTO ANIMALES (ID_ANIMAL, NOMBRE, ESPECIE, RAZA, FECHA_ENTRADA, ESTADO, OBSERVACIONES)
VALUES (SEQ_ANIMALES.NEXTVAL, 'Misi',   'Gato',  'Siames',         DATE '2026-02-14', 'DISPONIBLE',     'Tranquila, ideal para piso');

INSERT INTO ANIMALES (ID_ANIMAL, NOMBRE, ESPECIE, RAZA, FECHA_ENTRADA, ESTADO, OBSERVACIONES)
VALUES (SEQ_ANIMALES.NEXTVAL, 'Rocky',  'Perro', 'Pastor Aleman',  DATE '2025-11-03', 'EN_TRATAMIENTO', 'En tratamiento por fractura en pata delantera');

INSERT INTO ANIMALES (ID_ANIMAL, NOMBRE, ESPECIE, RAZA, FECHA_ENTRADA, ESTADO, OBSERVACIONES)
VALUES (SEQ_ANIMALES.NEXTVAL, 'Canela', 'Conejo', NULL,            DATE '2026-03-22', 'DISPONIBLE',     'Raza desconocida, muy curiosa');

-- Adoptantes iniciales
INSERT INTO ADOPTANTES (ID_ADOPTANTE, NOMBRE, DNI, EMAIL, TELEFONO, FECHA_REGISTRO)
VALUES (SEQ_ADOPTANTES.NEXTVAL, 'Maria Garcia Lopez',   '12345678A', 'maria.garcia@email.com',   '600111222', DATE '2026-04-01');

INSERT INTO ADOPTANTES (ID_ADOPTANTE, NOMBRE, DNI, EMAIL, TELEFONO, FECHA_REGISTRO)
VALUES (SEQ_ADOPTANTES.NEXTVAL, 'Carlos Ruiz Moreno',   '87654321B', 'carlos.ruiz@email.com',    '600333444', DATE '2026-04-15');

INSERT INTO ADOPTANTES (ID_ADOPTANTE, NOMBRE, DNI, EMAIL, TELEFONO, FECHA_REGISTRO)
VALUES (SEQ_ADOPTANTES.NEXTVAL, 'Ana Martinez Perez',   '11223344C', 'ana.martinez@email.com',   '600555666', DATE '2026-05-02');

-- Historial medico de Rocky (animal en tratamiento)
INSERT INTO HISTORIAL_MEDICO (ID_HISTORIAL, ID_ANIMAL, FECHA_VISITA, DESCRIPCION, COSTE, VETERINARIO)
VALUES (SEQ_HISTORIAL.NEXTVAL, 3, DATE '2025-11-05', 'Radiografia y diagnostico de fractura en radio izquierdo', 180.00, 'Dr. Fernandez');

INSERT INTO HISTORIAL_MEDICO (ID_HISTORIAL, ID_ANIMAL, FECHA_VISITA, DESCRIPCION, COSTE, VETERINARIO)
VALUES (SEQ_HISTORIAL.NEXTVAL, 3, DATE '2025-11-10', 'Intervencion quirurgica y escayola', 450.00, 'Dr. Fernandez');

INSERT INTO HISTORIAL_MEDICO (ID_HISTORIAL, ID_ANIMAL, FECHA_VISITA, DESCRIPCION, COSTE, VETERINARIO)
VALUES (SEQ_HISTORIAL.NEXTVAL, 3, DATE '2026-01-20', 'Revision post-operatoria. Evolucion favorable', 60.00, 'Dra. Sanchez');

COMMIT;


-- ============================================================
--  6. VERIFICACION RAPIDA
--     Ejecutar tras la instalacion para comprobar
--     que todos los objetos se han creado correctamente.
-- ============================================================

-- Comprobar tablas creadas
SELECT TABLE_NAME, NUM_ROWS
FROM USER_TABLES
WHERE TABLE_NAME IN ('ANIMALES','ADOPTANTES','ADOPCIONES','HISTORIAL_MEDICO','LOG_ANIMALES')
ORDER BY TABLE_NAME;

-- Comprobar constraints
SELECT TABLE_NAME, CONSTRAINT_NAME, CONSTRAINT_TYPE, STATUS
FROM USER_CONSTRAINTS
WHERE TABLE_NAME IN ('ANIMALES','ADOPTANTES','ADOPCIONES','HISTORIAL_MEDICO','LOG_ANIMALES')
ORDER BY TABLE_NAME, CONSTRAINT_TYPE;

-- Comprobar triggers
SELECT TRIGGER_NAME, TABLE_NAME, TRIGGERING_EVENT, TRIGGER_TYPE, STATUS
FROM USER_TRIGGERS
WHERE TABLE_NAME = 'ANIMALES'
ORDER BY TRIGGER_NAME;

-- Comprobar secuencias
SELECT SEQUENCE_NAME, MIN_VALUE, INCREMENT_BY, LAST_NUMBER
FROM USER_SEQUENCES
WHERE SEQUENCE_NAME IN ('SEQ_ANIMALES','SEQ_ADOPTANTES','SEQ_ADOPCIONES','SEQ_HISTORIAL','SEQ_LOG')
ORDER BY SEQUENCE_NAME;

-- Comprobar datos de prueba
SELECT ID_ANIMAL, NOMBRE, ESPECIE, ESTADO FROM ANIMALES ORDER BY ID_ANIMAL;
SELECT ID_ADOPTANTE, NOMBRE, DNI FROM ADOPTANTES ORDER BY ID_ADOPTANTE;
SELECT ID_HISTORIAL, ID_ANIMAL, FECHA_VISITA, COSTE FROM HISTORIAL_MEDICO ORDER BY ID_HISTORIAL;

-- Verificar que el trigger de auditoria funciona:
-- Al ejecutar este UPDATE debe aparecer una fila en LOG_ANIMALES
-- UPDATE ANIMALES SET ESTADO = 'EN_TRATAMIENTO' WHERE ID_ANIMAL = 1;
-- SELECT * FROM LOG_ANIMALES;
-- ROLLBACK; -- deshacer el UPDATE de prueba

-- ============================================================
--  FIN DEL SCRIPT DDL
-- ============================================================

-- ============================================================
--  SISTEMA "HUELLAS SEGURAS" — PACKAGE PL/SQL
--  Package: PKG_PROTECTORA
--  Base de datos: Oracle Database
--  Fecha: Mayo 2026
-- ============================================================

CREATE OR REPLACE PACKAGE PKG_PROTECTORA AS

    -- ==========================================
    --  FUNCIÓN: ES_ADOPTABLE
    --  Verifica si un animal puede ser adoptado (estado DISPONIBLE)
    -- ==========================================
    FUNCTION ES_ADOPTABLE(
        p_id_animal IN NUMBER
    ) RETURN NUMBER;

    -- ==========================================
    --  PROCEDIMIENTO: REALIZAR_ADOPCION
    --  Ejecuta el proceso completo de adopción de forma segura y atómica.
    -- ==========================================
    PROCEDURE REALIZAR_ADOPCION(
        p_id_animal     IN NUMBER,
        p_id_adoptante  IN NUMBER,
        p_observaciones IN VARCHAR2,
        p_resultado     OUT VARCHAR2
    );

    -- ==========================================
    --  PROCEDIMIENTO: DAR_ALTA_ANIMAL
    --  Cambia el estado de un animal de EN_TRATAMIENTO a DISPONIBLE.
    -- ==========================================
    PROCEDURE DAR_ALTA_ANIMAL(
        p_id_animal IN NUMBER,
        p_resultado OUT VARCHAR2
    );

    -- ==========================================
    --  PROCEDIMIENTO: REGISTRAR_VISITA_MEDICA
    --  Añade una nueva entrada al historial médico de un animal.
    -- ==========================================
    PROCEDURE REGISTRAR_VISITA_MEDICA(
        p_id_animal   IN NUMBER,
        p_descripcion IN VARCHAR2,
        p_coste       IN NUMBER,
        p_veterinario IN VARCHAR2
    );

END PKG_PROTECTORA;
/

CREATE OR REPLACE PACKAGE BODY PKG_PROTECTORA AS

    -- ==========================================
    --  FUNCIÓN: ES_ADOPTABLE
    -- ==========================================
    FUNCTION ES_ADOPTABLE(
        p_id_animal IN NUMBER
    ) RETURN NUMBER IS
        v_estado ANIMALES.ESTADO%TYPE;
    BEGIN
        SELECT ESTADO 
        INTO v_estado
        FROM ANIMALES
        WHERE ID_ANIMAL = p_id_animal;
        
        IF v_estado = 'DISPONIBLE' THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
        WHEN OTHERS THEN
            RETURN 0;
    END ES_ADOPTABLE;

    -- ==========================================
    --  PROCEDIMIENTO: REALIZAR_ADOPCION
    -- ==========================================
    PROCEDURE REALIZAR_ADOPCION(
        p_id_animal     IN NUMBER,
        p_id_adoptante  IN NUMBER,
        p_observaciones IN VARCHAR2,
        p_resultado     OUT VARCHAR2
    ) IS
    BEGIN
        -- 1. Verificar si el animal es adoptable
        IF ES_ADOPTABLE(p_id_animal) = 0 THEN
            p_resultado := 'ERROR: El animal no existe, no está disponible o ya fue adoptado.';
            RETURN;
        END IF;
        
        -- 2. Realizar las operaciones en una sola transacción
        INSERT INTO ADOPCIONES (
            ID_ADOPCION, 
            ID_ANIMAL, 
            ID_ADOPTANTE, 
            FECHA_ADOPCION, 
            OBSERVACIONES
        ) VALUES (
            SEQ_ADOPCIONES.NEXTVAL, 
            p_id_animal, 
            p_id_adoptante, 
            SYSDATE, 
            p_observaciones
        );
        
        -- Al hacer un UPDATE sobre la tabla ANIMALES, el trigger 
        -- TRG_FECHA_ACTUALIZACION se ejecutará automáticamente
        UPDATE ANIMALES
        SET ESTADO = 'ADOPTADO'
        WHERE ID_ANIMAL = p_id_animal;
        
        -- 3. Confirmar la transacción si todo ha ido bien
        COMMIT;
        p_resultado := 'OK';
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Deshacer cambios en caso de error para garantizar atomicidad
            ROLLBACK;
            p_resultado := 'ERROR: Ocurrió un fallo al realizar la adopción - ' || SQLERRM;
    END REALIZAR_ADOPCION;

    -- ==========================================
    --  PROCEDIMIENTO: DAR_ALTA_ANIMAL
    -- ==========================================
    PROCEDURE DAR_ALTA_ANIMAL(
        p_id_animal IN NUMBER,
        p_resultado OUT VARCHAR2
    ) IS
        v_estado ANIMALES.ESTADO%TYPE;
    BEGIN
        -- Obtener estado actual del animal
        SELECT ESTADO 
        INTO v_estado
        FROM ANIMALES
        WHERE ID_ANIMAL = p_id_animal;
        
        -- Verificar que está en tratamiento
        IF v_estado = 'EN_TRATAMIENTO' THEN
            UPDATE ANIMALES
            SET ESTADO = 'DISPONIBLE'
            WHERE ID_ANIMAL = p_id_animal;
            
            COMMIT;
            p_resultado := 'OK';
        ELSE
            p_resultado := 'ERROR: El animal no se encuentra en estado EN_TRATAMIENTO.';
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_resultado := 'ERROR: No se encontró ningún animal con el ID especificado.';
        WHEN OTHERS THEN
            ROLLBACK;
            p_resultado := 'ERROR: Ocurrió un fallo al dar de alta al animal - ' || SQLERRM;
    END DAR_ALTA_ANIMAL;

    -- ==========================================
    --  PROCEDIMIENTO: REGISTRAR_VISITA_MEDICA
    -- ==========================================
    PROCEDURE REGISTRAR_VISITA_MEDICA(
        p_id_animal   IN NUMBER,
        p_descripcion IN VARCHAR2,
        p_coste       IN NUMBER,
        p_veterinario IN VARCHAR2
    ) IS
    BEGIN
        -- Insertar el registro en el historial médico
        INSERT INTO HISTORIAL_MEDICO (
            ID_HISTORIAL, 
            ID_ANIMAL, 
            FECHA_VISITA, 
            DESCRIPCION, 
            COSTE, 
            VETERINARIO
        ) VALUES (
            SEQ_HISTORIAL.NEXTVAL, 
            p_id_animal, 
            SYSDATE, 
            p_descripcion, 
            p_coste, 
            p_veterinario
        );
        
        -- Actualizamos la fecha de última modificación del animal (requerimiento 4.4 y 5)
        -- Con realizar cualquier UPDATE en la fila, se disparará el trigger TRG_FECHA_ACTUALIZACION
        UPDATE ANIMALES
        SET FECHA_ACTUALIZACION = SYSDATE
        WHERE ID_ANIMAL = p_id_animal;

        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            -- Se usa RAISE_APPLICATION_ERROR al carecer de un parámetro OUT en la especificación
            RAISE_APPLICATION_ERROR(-20001, 'Error al registrar la visita médica: ' || SQLERRM);
    END REGISTRAR_VISITA_MEDICA;

END PKG_PROTECTORA;
/

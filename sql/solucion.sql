-- ==========================================
-- PRUEBA TÉCNICA - ANALISTA DE TRANSFORMACIÓN DIGITAL JR
-- Solución SQL
-- ==========================================

USE academia;

-- ------------------------------------------
-- PARTE 1: BASE DE DATOS
-- ------------------------------------------

-- Ejercicio 1.a (7 pts)
-- Listar todos los estudiantes (incluso sin matrícula) con conteo de matrículas ACTIVAS en 2026-1.
SELECT 
    e.id_estudiante,
    e.nombre,
    COUNT(m.id_matricula) AS matriculas_activas
FROM estudiante e
LEFT JOIN matricula m 
    ON e.id_estudiante = m.id_estudiante 
    AND m.estado = 'ACTIVA' 
    AND m.periodo = '2026-1'
GROUP BY e.id_estudiante, e.nombre;

-- Ejercicio 1.b (5 pts)
-- Listar cursos sin ninguna matrícula en ningún periodo.
SELECT 
    c.id_curso,
    c.nombre
FROM curso c
LEFT JOIN matricula m ON c.id_curso = m.id_curso
WHERE m.id_matricula IS NULL;


-- Ejercicio 2 (4 pts)
-- Cambiar a CANCELADA las matrículas ACTIVAS del estudiante 3 en 2026-1.
-- (Afecta a 1 fila con los datos iniciales).
START TRANSACTION;
UPDATE matricula
SET estado = 'CANCELADA'
WHERE id_estudiante = 3 
  AND periodo = '2026-1' 
  AND estado = 'ACTIVA';
COMMIT;


-- Ejercicio 3.a (5 pts)
-- Eliminar matrículas CANCELADAS del periodo 2026-1 de forma segura.
-- (Elimina 2 filas con los datos iniciales).
START TRANSACTION;
DELETE FROM matricula
WHERE estado = 'CANCELADA' AND periodo = '2026-1';
-- Si se revisa con SELECT y todo es correcto:
COMMIT;
-- Si hubo un error o no se deseaba borrar:
-- ROLLBACK;


-- Ejercicio 4 (15 pts)
-- Procedimiento almacenado pr_eliminar_matricula
DELIMITER //

CREATE PROCEDURE pr_eliminar_matricula (
    IN p_id_matricula INT,
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE v_estado VARCHAR(12);
    DECLARE v_existe INT DEFAULT 0;

    -- Handler para errores imprevistos
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'Error: Ocurrió un error imprevisto al procesar la solicitud.';
    END;

    START TRANSACTION;

    -- Verificar si existe la matrícula y obtener su estado
    SELECT COUNT(*), MAX(estado) 
    INTO v_existe, v_estado
    FROM matricula 
    WHERE id_matricula = p_id_matricula;

    IF v_existe = 0 THEN
        SET p_resultado = 'Error: La matrícula especificada no existe.';
        ROLLBACK;
    ELSEIF v_estado = 'FINALIZADA' THEN
        SET p_resultado = 'Advertencia: La matrícula se encuentra FINALIZADA y no puede ser eliminada.';
        ROLLBACK;
    ELSE
        DELETE FROM matricula WHERE id_matricula = p_id_matricula;
        SET p_resultado = 'Éxito: La matrícula fue eliminada correctamente.';
        COMMIT;
    END IF;
END //

DELIMITER ;

-- PRUEBAS DEL PROCEDIMIENTO ALMACENADO (CALL):
-- Caso 1: Matrícula eliminable (Ejemplo: ID 100)
-- CALL pr_eliminar_matricula(100, @res1); SELECT @res1;

-- Caso 2: Matrícula FINALIZADA (Ejemplo: ID 105)
-- CALL pr_eliminar_matricula(105, @res2); SELECT @res2;

-- Caso 3: Matrícula inexistente (Ejemplo: ID 999)
-- CALL pr_eliminar_matricula(999, @res3); SELECT @res3;


-- ------------------------------------------
-- PARTE 2: CRITERIO DE INGENIERÍA
-- ------------------------------------------

-- Ejercicio 5.b (4 pts)
-- Versión corregida del procedimiento del Anexo B
DELIMITER //

CREATE PROCEDURE pr_cancelar_matriculas_periodo_corregido (
    IN p_periodo VARCHAR(6),
    IN p_id_estudiante INT,
    OUT p_filas_afectadas INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_filas_afectadas = 0;
    END;

    START TRANSACTION;

    UPDATE matricula
    SET estado = 'CANCELADA'
    WHERE periodo = p_periodo 
      AND id_estudiante = p_id_estudiante
      AND estado != 'CANCELADA';

    SET p_filas_afectadas = ROW_COUNT();

    COMMIT;
END //

DELIMITER ;


-- ------------------------------------------
-- BONUS (10 pts)
-- ------------------------------------------

-- Ejercicio 9: Trigger BEFORE DELETE para auditoría
DELIMITER //

CREATE TRIGGER trg_matricula_before_delete
BEFORE DELETE ON matricula
FOR EACH ROW
BEGIN
    INSERT INTO matricula_log (
        id_matricula,
        id_estudiante,
        id_curso,
        periodo,
        estado,
        fecha_eliminacion,
        usuario
    ) VALUES (
        OLD.id_matricula,
        OLD.id_estudiante,
        OLD.id_curso,
        OLD.periodo,
        OLD.estado,
        NOW(),
        CURRENT_USER()
    );
END //

DELIMITER ;

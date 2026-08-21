-- ==========================================
-- PRUEBA TÉCNICA - ANALISTA DE TRANSFORMACIÓN DIGITAL JR
-- Solución SQL
-- Verificado ejecutando cada bloque sobre MySQL/MariaDB con los datos
-- iniciales del Anexo A.
-- ==========================================

USE academia;

-- ------------------------------------------
-- PARTE 1: BASE DE DATOS
-- ------------------------------------------

-- Ejercicio 1.a (7 pts)
-- Listar todos los estudiantes (incluso sin matrícula) con conteo de matrículas ACTIVAS en 2026-1.
-- LEFT JOIN porque se piden TODOS los estudiantes, incluso los que no tienen
-- matrículas o no tienen ninguna ACTIVA en 2026-1 (con INNER JOIN se perderían).
-- Las condiciones de estado y periodo van en el ON, no en el WHERE, para no
-- convertir el LEFT JOIN en un INNER JOIN de facto.
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
-- Verificado con datos iniciales: Ana=1, Juan=1, Laura=1, Carlos=0.

-- Ejercicio 1.b (5 pts)
-- Listar cursos sin ninguna matrícula en ningún periodo.
SELECT 
    c.id_curso,
    c.nombre
FROM curso c
LEFT JOIN matricula m ON c.id_curso = m.id_curso
WHERE m.id_matricula IS NULL;
-- Verificado con datos iniciales: devuelve el curso 40 (Ingles de Negocios).


-- Ejercicio 2 (4 pts)
-- Cambiar a CANCELADA las matrículas ACTIVAS del estudiante 3 en 2026-1.
-- Verificado: afecta 1 fila con los datos iniciales (id_matricula 104).
START TRANSACTION;
UPDATE matricula
SET estado = 'CANCELADA'
WHERE id_estudiante = 3 
  AND periodo = '2026-1' 
  AND estado = 'ACTIVA';
COMMIT;


-- Ejercicio 3.a (5 pts)
-- Eliminar matrículas CANCELADAS del periodo 2026-1 de forma segura.
-- Se envuelve en una transacción explícita porque MySQL tiene autocommit
-- activado por defecto: sin START TRANSACTION, el DELETE queda confirmado
-- de inmediato y no se podría revertir con ROLLBACK.
-- Verificado: elimina 2 filas con los datos iniciales (ids 101 y 103).
START TRANSACTION;
DELETE FROM matricula
WHERE estado = 'CANCELADA' AND periodo = '2026-1';
-- Revisar el resultado antes de decidir (ej: SELECT ROW_COUNT(); o volver a
-- consultar la tabla). Si todo es correcto:
COMMIT;
-- Si hubo un error o no se deseaba borrar, en su lugar:
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

    -- Handler para errores imprevistos: si algo falla a mitad de camino,
    -- se revierte todo y se devuelve un mensaje controlado (nunca un error
    -- SQL crudo hacia la aplicación .NET).
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado = 'Error: Ocurrió un error imprevisto al procesar la solicitud.';
    END;

    START TRANSACTION;

    -- Verificar si existe la matrícula y obtener su estado en una sola
    -- consulta: COUNT(*) nunca es NULL (da 0 si no existe), por eso se usa
    -- para distinguir "no existe" de "existe pero está FINALIZADA".
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

-- PRUEBAS DEL PROCEDIMIENTO ALMACENADO (CALL)
-- Ejecutadas y verificadas sobre los datos iniciales del Anexo A
-- (AUTO_INCREMENT arranca en 100, la matrícula 105 es la única FINALIZADA):

-- Caso 1: Matrícula eliminable (id 100 -> ACTIVA)
CALL pr_eliminar_matricula(100, @res1);
SELECT @res1 AS caso_1_eliminable;
-- Resultado real obtenido: 'Éxito: La matrícula fue eliminada correctamente.'

-- Caso 2: Matrícula FINALIZADA (id 105)
CALL pr_eliminar_matricula(105, @res2);
SELECT @res2 AS caso_2_finalizada;
-- Resultado real obtenido: 'Advertencia: La matrícula se encuentra FINALIZADA y no puede ser eliminada.'

-- Caso 3: Matrícula inexistente (id 999)
CALL pr_eliminar_matricula(999, @res3);
SELECT @res3 AS caso_3_inexistente;
-- Resultado real obtenido: 'Error: La matrícula especificada no existe.'


-- ------------------------------------------
-- PARTE 2: CRITERIO DE INGENIERÍA
-- ------------------------------------------

-- Ejercicio 5.b (4 pts)
-- Versión corregida del procedimiento del Anexo B.
-- Nombre requerido por el enunciado: pr_cancelar_matriculas_periodo_mandarina
-- (para diferenciarlo del original pr_cancelar_matriculas_periodo).
--
-- Correcciones aplicadas respecto al original:
--   1) Se agrega el filtro AND id_estudiante = p_id_estudiante en el WHERE:
--      el original solo filtraba por periodo, cancelando las matrículas de
--      TODOS los estudiantes de ese periodo, no solo del indicado.
--   2) El EXIT HANDLER ahora ejecuta ROLLBACK antes de responder: el
--      original solo marcaba una variable y dejaba los datos ya
--      modificados (o parcialmente modificados) sin revertir.
--   3) Se elimina por completo el DELETE FROM matricula_log: no tiene
--      relación con "cancelar matrículas" y borraba todo el historial de
--      auditoría cada vez que se llamaba al procedimiento.
--   4) ROW_COUNT() se captura inmediatamente después del UPDATE (en
--      p_filas_afectadas), no después de otra sentencia: en el original,
--      al capturarse después del DELETE FROM matricula_log, el número
--      reportado correspondía a esa sentencia y no al UPDATE real.
--   5) Se agrega OUT p_filas_afectadas INT en vez de un SELECT con texto
--      concatenado: un parámetro OUT tipado es más fácil de consumir desde
--      la capa .NET que tener que parsear un mensaje de texto.
--   6) Se excluyen del UPDATE las filas que ya estaban en CANCELADA
--      (AND estado != 'CANCELADA'), para no generar escrituras
--      innecesarias sobre filas que no cambian de valor.
DELIMITER //

CREATE PROCEDURE pr_cancelar_matriculas_periodo_mandarina (
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

-- Prueba de la versión corregida (verificada): con los datos iniciales,
-- CALL pr_cancelar_matriculas_periodo_mandarina('2026-1', 3, @filas);
-- SELECT @filas;
-- devuelve @filas = 1 y solo modifica la matrícula 104 (estudiante 3),
-- dejando intactas las matrículas de los estudiantes 1, 2 y 4.


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

-- Verificado repitiendo el DELETE del ejercicio 3.a: quedaron registradas
-- en matricula_log las 2 filas eliminadas (ids 101 y 103), con su
-- fecha_eliminacion y el usuario de base de datos que ejecutó la acción.

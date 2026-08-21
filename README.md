# prueba-tecnica-transformacion-digital
Solución a la prueba técnica para el cargo de Analista de Transformación Digital Jr
# Solución Prueba Técnica - Analista de Transformación Digital Jr

Este repositorio contiene la solución a la prueba técnica para el cargo de Analista de Transformación Digital Jr.

## Estructura del repositorio
- `sql/solucion.sql`: Contiene los scripts DDL y DML de los ejercicios prácticos de base de datos y el Bonus.
- `README.md`: Contiene las respuestas teóricas y de análisis situacional.
- `IA.md`: Registro de uso de asistentes de Inteligencia Artificial según la política establecida.

---

## Respuestas Teóricas y de Criterio

### Ejercicio 3.b - Análisis de DELETE con Llaves Foráneas
1. **¿Qué ocurre al ejecutar `DELETE FROM estudiante WHERE id_estudiante = 1`?**
   Lanza un error de restricción de clave foránea (Error SQL 1451). MySQL impide eliminar el registro porque la tabla `matricula` tiene filas asociadas al `id_estudiante = 1`.
2. **Alternativas:**
   - **Eliminación en cascada (`ON DELETE CASCADE`):** Elimina automáticamente las matrículas asociadas al borrar al estudiante.
   - **Borrado Lógico (Soft Delete):** Cambiar la columna `estado` del estudiante a `'INACTIVO'` sin borrar el registro físico.
3. **Elección para producción:**
   Se debe usar **Borrado Lógico (Soft Delete)**. En un sistema académico, borrar físicamente un estudiante destruye el historial institucional y financiero, lo cual viola normativas de auditoría y retención de datos.

### Ejercicio 3.c - Diferencias DELETE vs TRUNCATE
- **Diferencias:**
  1. `DELETE` es una operación DML (se puede envolver en transacción y revertir con `ROLLBACK`); `TRUNCATE` es una operación DDL (ejecuta un `IMPLICIT COMMIT` inmediato).
  2. `DELETE` borra fila por fila y evalúa restricciones `FOREIGN KEY`; `TRUNCATE` destruye y recrea la tabla de golpe (no se permite si hay referencias FK activas).
  3. `DELETE` mantiene el contador del `AUTO_INCREMENT`; `TRUNCATE` lo reinicia a 1.
- **¿Uso en producción?**
  **No.** Utilizar `TRUNCATE` en producción borraría de manera irreversible todo el historial académico de la institución, generando una pérdida catastrófica de datos.

---

### Nota Ejercicio 4 - Transaccionalidad
Se decidió manejar el control transaccional (`START TRANSACTION`, `COMMIT`, `ROLLBACK`) **dentro del procedimiento almacenado**. Esto garantiza encapsulamiento: la base de datos asegura su propia consistencia atómica sin depender de si la capa de .NET abrió o cerró la transacción adecuadamente.

---

### Ejercicio 5 - Revisión de Código Ajeno (Anexo B)

**a) 5 Problemas identificados y su impacto:**
1. **Falta condición `id_estudiante` en la clausula WHERE:** Cancela las matrículas de **TODOS** los estudiantes en ese periodo, borrando masivamente datos de la institución.
2. **Sintaxis incorrecta en WHERE (`periodo p_periodo`):** Falta el operador `=`, lo cual genera un error de sintaxis y la ejecución falla.
3. **Manejo de errores apaga la excepción sin deshacer:** El `EXIT HANDLER` captura el error pero no ejecuta `ROLLBACK`, dejando datos a medio modificar en caso de fallas intermedias.
4. **Instrucción peligrosa `DELETE FROM matricula_log`:** Borra todo el historial de auditoría de la base de datos sin justificación.
5. **Uso de `ROW_COUNT()` posterior al `DELETE`:** Devuelve el número de filas borradas de la tabla de log, no el número de matrículas actualizadas.

**c) Ejecución del procedimiento original:**
- **Mensaje exacto devuelto:** `Se cancelaron 0 matriculas` (o error de sintaxis según el motor).
- **Filas modificadas en `matricula`:** 0 filas modificadas.
- **Explicación de discrepancia:** La consulta `UPDATE` falla debido al error sintáctico (`WHERE periodo p_periodo`). El `EXIT HANDLER` atrapa el error, asigna `@error = 1`, pero el script continúa hasta `DELETE FROM matricula_log`, haciendo que `ROW_COUNT()` mida las filas borradas del log (que eran 0) y no del update.

---

### Ejercicio 6 - Flujo de Aplicación (.NET a MySQL)

1. **[Interfaz]** El usuario hace clic en el botón "Eliminar matrícula" en la UI de la aplicación .NET.
2. **[Aplicación]** La capa de presentación de .NET captura el evento y obtiene el `id_matricula` seleccionado.
3. **[Aplicación]** La capa de acceso a datos de .NET prepara la llamada al Stored Procedure `pr_eliminar_matricula` pasando el parámetro de entrada y registrando el parámetro de salida `@p_resultado`.
4. **[Base de Datos]** MySQL recibe la llamada, inicia la transacción y evalúa las reglas de negocio (existencia y estado del registro).
5. **[Base de Datos]** Al detectar que la matrícula está 'FINALIZADA', asigna a `p_resultado` el mensaje de advertencia, realiza `ROLLBACK` y finaliza.
6. **[Aplicación]** .NET recibe la ejecución exitosa del SP y lee la cadena de texto retornada en el parámetro de salida.
7. **[Aplicación]** La lógica de negocio en .NET evalúa el texto recibido. Al ver la palabra "Advertencia" o "Error", determina que no debe actualizar la vista de la tabla.
8. **[Interfaz]** La aplicación despliega una ventana modal (Toast/Alert) mostrando el mensaje exacto enviado por la BD: *"Advertencia: La matrícula se encuentra FINALIZADA y no puede ser eliminada"*.

---

### Ejercicio 7 - Incidente de Soporte

1. **Causa raíz:** Existe una restricción de clave foránea (`fk_matricula_curso`). No se puede eliminar el curso porque existen matrículas asociadas a él.
2. **Consulta SQL de diagnóstico:**
   ```sql
   SELECT * FROM matricula WHERE id_curso = [ID_DEL_CURSO];

Solución propuesta: Explicar que el curso no se puede borrar porque conserva historial de alumnos. La solución correcta es implementar un estado en la tabla curso (ej. inactivo o cerrado) para deshabilitarlo comercialmente sin perder integridad histórica.

Lo que NO haría: Desactivar temporalmente las claves foráneas (SET FOREIGN_KEY_CHECKS = 0) para forzar el borrado. Riesgo: Genera huérfanos en la base de datos y corrompe la integridad referencial.

Respuesta al usuario:

"Hola [Nombre]. Entiendo la urgencia de depurar el catálogo para la operación de hoy. Sin embargo, el sistema bloquea la eliminación debido a que este curso ya cuenta con estudiantes matriculados en periodos anteriores. Eliminarlo directamente borraría la historia académica de esos alumnos. Para resolver tu necesidad hoy de forma segura, podemos cambiar el estado del curso a 'Inactivo' para que no vuelva a aparecer disponible para nuevas matrículas. Quedo atento a tu confirmación para proceder."

### Ejercicio 8 - Automatización de Proceso Manual

a) Preguntas al dueño del proceso:

¿Cuáles son las reglas exactas para considerar que dos horarios se cruzan? (Para modelar la lógica exacta en código/SQL).

¿Con qué frecuencia o bajo qué disparador se necesita el reporte? (Para saber si automatizar por horario o por evento).

¿Qué acciones toman los coordinadores tras recibir las inconsistencias? (Para evaluar si en lugar de correo se requiere un flujo de aprobación).

b) Priorización:

Automatizar primero: La validación de cruces e inconsistencias mediante consultas automáticas directamente en la base de datos.

Dejar manual (por ahora): El envío final o la decisión de qué hacer con los estudiantes con cruces, dejando el criterio final en manos de los coordinadores.

c) Propuesta técnica a alto nivel:
En lugar de procesar archivos Excel sueltos, la base de datos debe ser la única fuente de la verdad. Se creará una Vista en MySQL o un proceso programado (mediante Python o Power Automate) que ejecute la validación cruzando las tablas matricula, curso y horario. Los resultados con inconsistencias se enviarán automáticamente por correo consolidado en HTML/Excel mediante un script o flujo automatizado.

d) Indicadores y Riesgos:

Indicador (KPI): Reducción del tiempo de procesamiento (de 8 horas a < 5 minutos) y Tasa de inconsistencias no detectadas (Meta: 0).

Riesgo: Generación de falsos positivos por datos mal ingresados en el sistema origen. Mitigación: Incluir una etapa de pre-validación de calidad de datos antes de disparar las alertas a los coordinadores.

Ejercicio 9 (Bonus) - Nota sobre la tabla matricula_log
La tabla matricula_log no debe tener llave foránea hacia matricula porque su propósito es almacenar auditoría de registros eliminados. Si tuviera una restricción FK, al borrar la matrícula original en la tabla principal, el motor de BD impediría la eliminación o borraría también el registro del log en cascada, anulando el propósito de la auditoría.

# Declaración de Uso de Asistentes de Inteligencia Artificial (IA.md)

De acuerdo con las políticas establecidas para esta prueba técnica, se detalla el uso de herramientas de IA durante la resolución de los ejercicios:

## Herramientas utilizadas
- **Asistente de IA (Gemini):** Utilizado para estructuración inicial del código SQL, diseño de procedimientos almacenados y revisión sintáctica.
- **Asistente de IA (Claude):** Utilizado para revisar la solución completa generada con Gemini, verificar su funcionamiento ejecutándola en una base de datos real, y corregir errores detectados antes de la entrega.

## Registro de interacción y criterio aplicado

1. **Ejercicio 4 (Procedimiento Almacenado):**
   - **Sugerencia de la IA:** Gemini sugirió inicialmente manejar la transacción fuera del procedimiento almacenado (en la capa de aplicación .NET).
   - **Decisión / Corrección:** Se descartó esta sugerencia y se implementó el control transaccional (`START TRANSACTION` / `COMMIT` / `ROLLBACK`) directamente dentro del procedimiento de MySQL.
   - **Razón:** Encapsular la transacción dentro de la base de datos garantiza la atomicidad y la seguridad de la información independientemente de qué cliente (aplicación web, script externo, cliente SQL) invoque el procedimiento.

2. **Ejercicio 5 (Revisión de Código Ajeno):**
   - **Uso:** Se utilizó IA como apoyo para analizar el Anexo B y para verificar el comportamiento de `ROW_COUNT()` tras la ejecución de varias sentencias en secuencia.
   - **Sugerencia descartada:** Gemini afirmó inicialmente que el Anexo B tenía un error de sintaxis en la cláusula `WHERE periodo p_periodo` por falta del operador `=`.
   - **Decisión / Corrección:** Al ejecutar el procedimiento original de forma real sobre MySQL (con Claude, como parte de la verificación previa a esta entrega), se comprobó que **no existe tal error de sintaxis**: el procedimiento compila y el `UPDATE` se ejecuta con éxito, modificando datos reales de la tabla `matricula` de estudiantes que no debían verse afectados. Se corrigió el análisis del ejercicio 5.a y la explicación del 5.c en el README para reflejar el comportamiento real y verificado, en lugar de la suposición inicial de la IA.
   - **Razón:** No se puede reportar "carácter por carácter" el resultado de una ejecución sin haberla corrido realmente; aceptar la afirmación de la IA sin verificarla habría dejado una respuesta técnicamente incorrecta en la entrega.

3. **Ejercicio 7 y 8 (Soporte y Automatización):**
   - **Uso:** Redacción preliminar de la respuesta formal de soporte e ideación del flujo de automatización, revisadas y ajustadas manualmente antes de la entrega.

4. **Revisión general y verificación técnica:**
   - **Uso:** Antes de la entrega, se instaló una instancia de MySQL/MariaDB para ejecutar cada ejercicio (consultas, procedimientos y el trigger bonus) contra los datos del Anexo A, confirmando que los resultados reportados en el README coinciden con el comportamiento real de la base de datos, y no solo con lo que la IA asumía que ocurriría.

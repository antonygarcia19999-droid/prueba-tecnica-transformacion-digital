---

### Paso 4: Declaración de Uso de IA (`IA.md`)

Copia este texto en tu archivo `IA.md` para cumplir con la política de la empresa:

```markdown
# Declaración de Uso de Asistentes de Inteligencia Artificial (IA.md)

De acuerdo con las políticas establecidas para esta prueba técnica, se detalla el uso de herramientas de IA durante la resolución de los ejercicios:

## Herramientas utilizadas
- **Asistente de IA (Gemini):** Utilizado para estructuración del código SQL, diseño de procedimientos almacenados y revisión sintáctica.

## Registro de interacción y criterio aplicado

1. **Ejercicio 4 (Procedimiento Almacenado):**
   - **Sugerencia de la IA:** La IA sugirió inicialmente manejar la transacción fuera del procedimiento almacenado (en la capa de aplicación .NET).
   - **Decisión / Corrección:** Se descartó esta sugerencia y se implementó el control transaccional (`START TRANSACTION` / `COMMIT` / `ROLLBACK`) directamente dentro del procedimiento de MySQL. 
   - **Razón:** Encapsular la transacción dentro de la base de datos garantiza la atomicidad y la seguridad de la información independientemente de qué cliente (aplicación web, script externo, cliente SQL) invoque el procedimiento.

2. **Ejercicio 5 (Revisión de Código Ajeno):**
   - **Uso:** Se utilizó la IA como apoyo para verificar el comportamiento de `ROW_COUNT()` tras la ejecución de sentencias de error.
   - **Aceptado:** Se aceptaron los análisis teóricos sobre la falta de la cláusula de igualdad en el `WHERE`.

3. **Ejercicio 7 y 8 (Soporte y Automatización):**
   - **Uso:** Redacción preliminar de la respuesta formal de soporte e ideación del flujo de automatización.

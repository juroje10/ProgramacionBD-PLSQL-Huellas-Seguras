# Especificación de Diseño — Sistema "Huellas Seguras"


**Tecnologías usadas:** Oracle Database (SQL + PL/SQL) + Oracle APEX  
**Tema nº8:** Programación de Bases de Datos — PL/SQL  
**Fecha:** 12 de mayo del 2026  

---

## 1. Descripción General del Sistema

**Huellas Seguras** es un sistema de gestión para una protectora de animales. Su objetivo es digitalizar y controlar los procesos clave de la organización: el registro de animales rescatados, su seguimiento médico, la gestión de adoptantes y la tramitación de adopciones.

El principio de diseño fundamental es que **toda la lógica de negocio reside en el servidor Oracle**, concretamente en un package PL/SQL y en triggers. Esto garantiza que las reglas del negocio se aplican independientemente de la aplicación cliente que acceda a los datos.

### Entidades del sistema

| Entidad | Propósito |
|---|---|
| ANIMALES | Animales alojados en la protectora en cualquier momento |
| ADOPTANTES | Personas registradas que desean o han adoptado un animal |
| ADOPCIONES | Registro permanente de cada adopción formalizada |
| HISTORIAL_MEDICO | Visitas veterinarias e intervenciones de cada animal |
| LOG_ANIMALES | Tabla de auditoría automática de cambios de estado |

---

## 2. Diccionario de Datos

> Este diccionario describe la estructura de cada tabla, sus columnas, los tipos de dato elegidos y las restricciones aplicadas. No contiene código de creación, solo la definición conceptual.

---

### 2.1 Tabla: ANIMALES

Representa cada animal presente o que ha pasado por la protectora.

| Columna | Tipo de dato | Obligatorio | Descripción |
|---|---|---|---|
| ID_ANIMAL | Número entero | Sí (PK) | Identificador único, generado por secuencia automática |
| NOMBRE | Texto (100 car.) | Sí | Nombre del animal |
| ESPECIE | Texto (50 car.) | Sí | Especie del animal: Perro, Gato, Conejo, etc. |
| RAZA | Texto (100 car.) | No | Raza del animal, puede dejarse vacío si es desconocida |
| FECHA_ENTRADA | Fecha | Sí | Fecha en que el animal ingresó a la protectora |
| ESTADO | Texto (20 car.) | Sí | Estado actual del animal. Solo admite tres valores controlados: DISPONIBLE, EN_TRATAMIENTO, ADOPTADO |
| OBSERVACIONES | Texto (500 car.) | No | Notas generales de comportamiento, carácter, etc. |
| FECHA_ACTUALIZACION | Fecha | No | Se actualiza automáticamente cada vez que se modifica el registro |

**Valores permitidos para ESTADO:** `DISPONIBLE`, `EN_TRATAMIENTO`, `ADOPTADO`. Cualquier otro valor debe ser rechazado por la base de datos.

---

### 2.2 Tabla: ADOPTANTES

Personas físicas que se registran en el sistema para adoptar un animal.

| Columna | Tipo de dato | Obligatorio | Descripción |
|---|---|---|---|
| ID_ADOPTANTE | Número entero | Sí (PK) | Identificador único, generado por secuencia automática |
| NOMBRE | Texto (100 car.) | Sí | Nombre completo del adoptante |
| DNI | Texto (15 car.) | Sí | Documento nacional de identidad. Debe ser único en el sistema |
| EMAIL | Texto (150 car.) | Sí | Correo electrónico de contacto. Debe ser único en el sistema |
| TELEFONO | Texto (20 car.) | Sí | Número de teléfono de contacto |
| FECHA_REGISTRO | Fecha | Sí | Fecha en que el adoptante se dio de alta en el sistema |

**Unicidad:** Dos adoptantes no pueden compartir el mismo DNI ni el mismo EMAIL.

---

### 2.3 Tabla: ADOPCIONES

Registra de forma permanente cada adopción completada. Esta tabla es el resultado del proceso de adopción y no debe modificarse manualmente una vez creada.

| Columna | Tipo de dato | Obligatorio | Descripción |
|---|---|---|---|
| ID_ADOPCION | Número entero | Sí (PK) | Identificador único, generado por secuencia automática |
| ID_ANIMAL | Número entero | Sí (FK) | Animal que ha sido adoptado. Referencia a ANIMALES |
| ID_ADOPTANTE | Número entero | Sí (FK) | Persona que adopta. Referencia a ADOPTANTES |
| FECHA_ADOPCION | Fecha | Sí | Fecha en que se formalizó la adopción |
| OBSERVACIONES | Texto (500 car.) | No | Condiciones especiales, compromisos de seguimiento, etc. |

**Restricción clave:** El campo ID_ANIMAL debe ser único en esta tabla. Un animal no puede aparecer en dos filas de ADOPCIONES, es decir, no puede adoptarse dos veces.

---

### 2.4 Tabla: HISTORIAL_MEDICO

Almacena el registro cronológico de todas las visitas veterinarias y tratamientos de cada animal.

| Columna | Tipo de dato | Obligatorio | Descripción |
|---|---|---|---|
| ID_HISTORIAL | Número entero | Sí (PK) | Identificador único, generado por secuencia automática |
| ID_ANIMAL | Número entero | Sí (FK) | Animal al que corresponde esta entrada. Referencia a ANIMALES |
| FECHA_VISITA | Fecha | Sí | Fecha en que se realizó la visita o intervención |
| DESCRIPCION | Texto (1000 car.) | Sí | Diagnóstico, tratamiento o procedimiento realizado |
| COSTE | Número decimal | No | Coste económico de la intervención en euros |
| VETERINARIO | Texto (100 car.) | No | Nombre del veterinario responsable |

---

### 2.5 Tabla: LOG_ANIMALES (Auditoría)

Tabla de solo lectura para el usuario de la aplicación. Se rellena exclusivamente de forma automática mediante un trigger cuando el estado de un animal cambia. No se permite ninguna operación manual de inserción, modificación ni borrado sobre esta tabla desde la aplicación.

| Columna | Tipo de dato | Obligatorio | Descripción |
|---|---|---|---|
| ID_LOG | Número entero | Sí (PK) | Identificador único, generado por secuencia automática |
| ID_ANIMAL | Número entero | Sí | Animal cuyo estado ha cambiado |
| ESTADO_ANTERIOR | Texto (20 car.) | No | Estado que tenía el animal antes del cambio |
| ESTADO_NUEVO | Texto (20 car.) | Sí | Estado al que ha pasado el animal |
| FECHA_CAMBIO | Fecha y hora | Sí | Momento exacto en que se produjo el cambio |
| USUARIO_BD | Texto (50 car.) | Sí | Usuario de base de datos que ejecutó la operación |

---

### 2.6 Secuencias (generadores de clave primaria)

Oracle no tiene AUTO_INCREMENT como MySQL. Para generar claves primarias únicas y consecutivas se utilizan objetos llamados **secuencias**. Cada tabla tiene la suya propia para que los identificadores sean independientes entre tablas.

| Secuencia | Tabla que la usa | Columna que alimenta |
|---|---|---|
| SEQ_ANIMALES | ANIMALES | ID_ANIMAL |
| SEQ_ADOPTANTES | ADOPTANTES | ID_ADOPTANTE |
| SEQ_ADOPCIONES | ADOPCIONES | ID_ADOPCION |
| SEQ_HISTORIAL | HISTORIAL_MEDICO | ID_HISTORIAL |
| SEQ_LOG | LOG_ANIMALES | ID_LOG |

Todas las secuencias empezarán en 1 y se incrementarán de uno en uno.

---

## 3. Relaciones entre Entidades

### Descripción de cada relación

**ANIMALES → ADOPCIONES:** Relación de uno a uno restringida. Un animal puede aparecer como máximo una vez en ADOPCIONES. Si se borra un animal, no se podrá si tiene una adopción asociada (integridad referencial restrictiva).

**ADOPTANTES → ADOPCIONES:** Relación de uno a muchos. Un mismo adoptante podría adoptar diferentes animales en momentos distintos, generando varias filas en ADOPCIONES. Si se intenta borrar un adoptante que tiene adopciones, la operación debe bloquearse.

**ANIMALES → HISTORIAL_MEDICO:** Relación de uno a muchos. Un animal puede tener múltiples entradas en su historial. Si se borra un animal, su historial se borra también en cascada (no tiene sentido conservar el historial sin el animal).

**ANIMALES → LOG_ANIMALES:** Relación de auditoría generada automáticamente por trigger, no por la aplicación.

---

## 4. Lógica de Negocio

### 4.1 Ciclo de vida de un animal

Cada animal tiene un estado que controla qué operaciones se pueden realizar sobre él. Las transiciones entre estados están restringidas por el sistema.

**Estados posibles:**

| Estado | Significado |
|---|---|
| DISPONIBLE | El animal está sano y puede ser adoptado |
| EN_TRATAMIENTO | El animal está recibiendo atención veterinaria y no puede adoptarse |
| ADOPTADO | El animal ha sido entregado a un adoptante y ha salido del sistema |

**Transiciones válidas e inválidas:**

| Desde | Hacia | ¿Permitida? | Condición |
|---|---|---|---|
| DISPONIBLE | EN_TRATAMIENTO | ✅ Sí | El veterinario lo decide desde la interfaz |
| DISPONIBLE | ADOPTADO | ✅ Sí | Solo mediante el proceso formal de adopción |
| EN_TRATAMIENTO | DISPONIBLE | ✅ Sí | Cuando el veterinario da el alta |
| EN_TRATAMIENTO | ADOPTADO | ❌ No | No se puede adoptar un animal en tratamiento |
| ADOPTADO | cualquier estado | ❌ No | Una vez adoptado, el animal no puede volver al sistema |

---

### 4.2 Proceso de adopción

El proceso de adopción es la operación más crítica del sistema. Debe ser atómica, es decir, o se completa todo o no se completa nada. Los pasos son:

1. El usuario selecciona un animal y un adoptante desde la interfaz APEX.
2. El sistema verifica que el animal está en estado **DISPONIBLE**. Si no lo está, el proceso se cancela con un mensaje claro.
3. Si el animal es adoptable, el sistema registra la adopción y cambia el estado del animal a **ADOPTADO** en una misma transacción.
4. Si cualquier paso falla (por ejemplo, un error de base de datos), todos los cambios se deshacen y los datos quedan como estaban.
5. Al cambiar el estado del animal, el trigger de auditoría registra automáticamente el cambio en LOG_ANIMALES.

---

### 4.3 Alta veterinaria

Cuando un animal en estado **EN_TRATAMIENTO** se recupera, el veterinario puede darlo de alta a través de la interfaz. El sistema cambia el estado a **DISPONIBLE**, lo que lo hace elegible para adopción nuevamente. Este cambio también queda registrado automáticamente en el log de auditoría.

---

### 4.4 Registro médico

Cada visita veterinaria se añade al historial del animal como una entrada independiente. Añadir una visita médica no cambia automáticamente el estado del animal; el cambio de estado es siempre una decisión explícita del veterinario.

---

### 4.5 Auditoría automática

Cualquier modificación del campo ESTADO en la tabla ANIMALES debe quedar registrada automáticamente en LOG_ANIMALES sin que el programador tenga que recordar hacerlo. El registro incluye quién hizo el cambio, cuándo y cuáles eran los valores anterior y nuevo. Esta tarea la realiza el trigger, no el package ni la aplicación.

---

## 5. Subprogramas PL/SQL — Package PKG_PROTECTORA

Todo el código de negocio se agrupa en un único package llamado **PKG_PROTECTORA**. Esto permite que cualquier aplicación o usuario que acceda a la base de datos utilice el mismo punto de entrada para las operaciones críticas, garantizando coherencia.

El package tiene dos partes: la **especificación** (qué ofrece al exterior) y el **cuerpo** (cómo lo hace internamente). En esta especificación de diseño solo describimos qué hace cada elemento, no cómo está escrito.

---

### FUNCIÓN: ES_ADOPTABLE

**Propósito:** Verificar si un animal puede ser adoptado en este momento.

**Qué recibe:** El identificador del animal.

**Qué devuelve:** Un valor numérico. El valor 1 significa que el animal existe y está en estado DISPONIBLE. El valor 0 significa que no es adoptable por cualquier motivo (no existe, está en tratamiento o ya fue adoptado).

**Cuándo se usa:** Esta función se llama antes de iniciar cualquier proceso de adopción y también puede usarse desde la interfaz APEX para mostrar u ocultar el botón de adoptar según el estado del animal.

---

### PROCEDIMIENTO: REALIZAR_ADOPCION

**Propósito:** Ejecutar el proceso completo de adopción de forma segura y atómica.

**Qué recibe:** El identificador del animal, el identificador del adoptante y un campo de observaciones opcional.

**Qué devuelve:** Un parámetro de salida con el texto `OK` si la operación fue exitosa, o un mensaje de error descriptivo si algo falló.

**Comportamiento:**
- Primero comprueba si el animal es adoptable usando la función ES_ADOPTABLE.
- Si no es adoptable, informa del motivo y no realiza ningún cambio.
- Si es adoptable, registra la adopción y actualiza el estado del animal en una única transacción.
- Si ocurre cualquier error durante la transacción, deshace todos los cambios.

---

### PROCEDIMIENTO: DAR_ALTA_ANIMAL

**Propósito:** Cambiar el estado de un animal de EN_TRATAMIENTO a DISPONIBLE cuando se recupera.

**Qué recibe:** El identificador del animal.

**Qué devuelve:** Un parámetro de salida con el resultado de la operación.

**Comportamiento:** Verifica que el animal existe y está en EN_TRATAMIENTO antes de cambiar su estado. Si el animal no existe o tiene un estado diferente, informa del error sin hacer cambios.

---

### PROCEDIMIENTO: REGISTRAR_VISITA_MEDICA

**Propósito:** Añadir una nueva entrada al historial médico de un animal.

**Qué recibe:** El identificador del animal, la descripción de la visita, el coste (opcional) y el nombre del veterinario (opcional).

**Comportamiento:** Inserta la visita en HISTORIAL_MEDICO y actualiza la fecha de última modificación del animal.

---

## 6. Triggers de Auditoría

Los triggers son mecanismos automáticos que se activan sin intervención del programador. En este sistema se definen dos triggers sobre la tabla ANIMALES.

---

### TRIGGER: TRG_AUDITORIA_ESTADO

**Tabla vigilada:** ANIMALES  
**Cuándo se activa:** Después de que se ejecute una operación de actualización sobre el campo ESTADO, fila por fila.  
**Condición adicional:** Solo actúa si el valor del estado realmente ha cambiado, es decir, si el estado nuevo es diferente al estado anterior.

**Qué hace:** Inserta una fila en la tabla LOG_ANIMALES con el identificador del animal, el estado anterior al cambio, el estado nuevo, la fecha y hora exactas del cambio y el nombre del usuario de base de datos que realizó la operación.

**Por qué existe:** Para tener trazabilidad completa de todos los cambios de estado sin depender de que los programadores recuerden registrarlo manualmente.

---

### TRIGGER: TRG_FECHA_ACTUALIZACION

**Tabla vigilada:** ANIMALES  
**Cuándo se activa:** Antes de que se ejecute cualquier operación de actualización sobre la tabla, fila por fila.

**Qué hace:** Asigna automáticamente la fecha y hora actuales al campo FECHA_ACTUALIZACION del animal que se está modificando.

**Por qué existe:** Para que ningún programador tenga que recordar actualizar ese campo manualmente en cada operación; el trigger lo hace siempre de forma transparente.

---
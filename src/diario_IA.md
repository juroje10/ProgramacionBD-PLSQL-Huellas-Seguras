# DIARIO DE TRABAJO CON IA: SISTEMA "HUELLAS SEGURAS"

**Entorno de Desarrollo:** Oracle APEX / Oracle Database  
**Proyecto:** Aplicación para la Gestión de Huellas Segura protectora de animales  

---

## 1.- Archivos Utilizados e Instalación

Para montar toda la base de datos de mi aplicación, organicé el proyecto en dos archivos SQL principales. Los ejecuté en orden en el **SQL Workshop** de Oracle APEX antes de ponerme a diseñar las pantallas:

* **`huellas_seguras_ddl.sql`**: Contiene el esquema completo de la base de datos estructurado en un único script. Incluye la creación de las secuencias automáticas (`SEQ_ANIMALES`, etc.), las tablas principales (`ANIMALES`, `ADOPTANTES`, `ADOPCIONES`, `HISTORIAL_MEDICO`), la tabla de auditoría (`LOG_ANIMALES`), sus correspondientes índices para optimizar búsquedas, los disparadores automáticos (`TRG_FECHA_ACTUALIZACION` y `TRG_AUDITORIA_ESTADO`) y un conjunto de datos de prueba iniciales.

* **`huellas_seguras_pkg.sql`**: Contiene la especificación y el cuerpo del paquete PL/SQL `PKG_PROTECTORA`. Aquí se centraliza la lógica de negocio del refugio: la función de disponibilidad `ES_ADOPTABLE` y los procedimientos seguros `REALIZAR_ADOPCION` (con gestión de transacciones/commit/rollback), `DAR_ALTA_ANIMAL` y `REGISTRAR_VISITA_MEDICA`.

---

## 2.- Registro de mis Prompts hacia la IA

Estos son los mensajes reales que le mandé a la IA para que me ayudara a escribir los códigos, solucionar los fallos que me iban saliendo en APEX y mejorar el diseño de las pantallas:

### Paso 1: Crear las tablas y la lógica
> **Prompt 1:** *"Necesito crear un script SQL para una base de datos de una protectora llamada 'Huellas Seguras'. Debe tener una tabla de animales, otra de adoptantes y una de adopciones. Añade una tabla de LOG_ANIMALES y un trigger para auditoría que registre cuándo un animal cambia de estado, qué usuario lo hizo y la fecha. Además, haz un paquete PL/SQL llamado PKG_PROTECTORA con un procedimiento para realizar una adopción, que verifique que el animal esté disponible, inserte la adopción y cambie el estado del animal a 'ADOPTADO'."*

### Paso 2: Arreglar fallos en los formularios de APEX
> **Prompt 2:** *"Ya he creado los informes interactivos (CRUD) en Oracle APEX para animales y adoptantes usando el asistente. El problema es que al intentar insertar un nuevo animal me sale el error: `1 error has occurred ORA-01400: no se puede realizar una inserción NULL en ID_ANIMAL`. ¿Cómo lo soluciono desde el Page Designer?"*

> **Prompt 3:** *"En el formulario de animales de la página 3, no quiero que el usuario escriba a mano el estado del animal ni vea la fecha de actualización del trigger. ¿Cómo puedo ocultar la fecha y transformar el campo de estado en un desplegable cerrado con las opciones Disponible, En Tratamiento y Adoptado?"*

### Paso 3: Conectar la pantalla con el código de la base de datos
> **Prompt 4:** *"Quiero crear una página en blanco (Página 6) para tramitar adopciones. Necesito colocar dos Select Lists (uno para elegir animales disponibles y otro para adoptantes) y un botón de confirmación. ¿Cómo conecto ese botón para que ejecute el código de mi paquete PL/SQL (`PKG_PROTECTORA.REALIZAR_ADOPCION`) inyectando los valores de la pantalla?"*

### Paso 4: Hacer los informes finales y el gráfico
> **Prompt 5:** *"Quiero una pantalla que sirva de Historial de Adopciones. No quiero que salgan los IDs numéricos de las tablas, sino una consulta limpia que junte los nombres del animal, su especie, el nombre del adoptante y su DNI ordenados por fecha. ¿Qué consulta SQL le meto al Interactive Report? Añade también un gráfico de barras en la Home para ver cuántos animales hay en cada estado."*

---

## 3.- Reflexión sobre los Cambios Realizados

Trabajar con la IA me ha ayudado mucho a ir más rápido, pero he tenido que estar muy atento porque la IA no sabe cómo es la pantalla de mi Oracle APEX ni conoce las últimas actualizaciones de la herramienta. Tuve que cambiar y corregir varias cosas a mano:

### A. Solución al error del ID vacío (ORA-01400)
La IA pensaba que APEX pondría los números de los IDs solo, pero me dio error. Tuve que ir yo mismo al Page Designer a cambiar las propiedades de los campos `ID_ANIMAL` e `ID_ADOPTANTE`. Los puse en oculto (*Hidden*), desactivé la opción de valor protegido (*Value Protected = No*) y configuré a mano la secuencia en la sección *Default*. Así ya empezó a funcionar a la primera.

### B. Cambios en las pantallas para que el usuario no se equivoque
La IA me daba códigos para que el usuario escribiera el estado del animal escribiendo texto a mano, lo cual es peligroso porque si alguien escribe mal "Disponible", la base de datos falla. Cambié esos campos por listas desplegables cerradas. Además, en la pantalla de adoptar, modifiqué el código para poner un `WHERE estado = 'DISPONIBLE'`. De esta forma, solo salen en la lista los animales libres y evito que un usuario intente adoptar un perro que ya está con otra familia.

### C. Adaptación a la versión actual de APEX
La IA me decía que buscara una opción llamada "PL/SQL Code" para el proceso del botón, pero en mi versión de APEX esa opción ya no se llama así, sino **`Execute Code`**. Tuve que buscarla por mi cuenta en la pestaña de procesos (el engranaje) y poner el lenguaje en PL/SQL. También añadí una línea de código especial (`g_print_success_message`) para que el mensaje de éxito que genera la base de datos salga arriba en la web con un recuadro verde muy visual.

### D. Comprobación de la seguridad de los datos
Estuve haciendo pruebas con el botón de borrar. Comprobé que si intento borrar a un animal que ya ha sido adoptado, la base de datos salta y me lo prohíbe con un aviso de error (`ORA-02292`). Vi que esto está bien hecho porque la base de datos protege el historial para que nadie borre sin querer los datos de una adopción antigua, dejando la aplicación con datos fantasma.
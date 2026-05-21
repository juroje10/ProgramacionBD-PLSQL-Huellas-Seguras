# Aplicación - Huellas Seguras

Sistema de gestión para una protectora de animales desarrollado con Oracle Database (SQL + PL/SQL) y Oracle APEX.

---

## Esquema de base de datos
Creación de secuencias, tablas, índices, triggers y datos de prueba iniciales.

- [huellas_seguras_ddl.sql](src/huellas_seguras_ddl.sql)

## Package PL/SQL
Lógica de negocio centralizada: gestión de adopciones, altas veterinarias y registro del historial médico.

- [huellas_seguras_pkg.sql](src/huellas_seguras_pkg.sql)

## Aplicación Oracle APEX
Exportación de la aplicación. Importar desde *App Builder → Import* tras ejecutar los scripts anteriores.

- [aplicacion_huellas_seguras.sql](src/aplicacion_huellas_seguras.sql)

## Especificación del sistema
Diccionario de datos, relaciones entre entidades y descripción de la lógica de negocio.

- [especificacion.md](src/especificacion.md)

## Diario de desarrollo con IA
Prompts utilizados durante el desarrollo y adaptaciones manuales realizadas sobre el código generado.

- [diario_IA.md](src/diario_IA.md)
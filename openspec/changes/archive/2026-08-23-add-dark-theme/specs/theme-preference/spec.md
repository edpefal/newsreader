## Purpose

Define cómo el usuario elige y persiste la apariencia (claro/oscuro/sistema) de la app, y qué pasa con la preferencia de un usuario existente cuando se introduce la opción de seguir al sistema operativo.

## ADDED Requirements

### Requirement: Selección de modo de tema
El sistema SHALL ofrecer tres modos de tema: claro, oscuro, y seguir sistema.

#### Scenario: Usuario selecciona modo claro
- **WHEN** el usuario elige "claro" en la preferencia de tema
- **THEN** la app renderiza con el theme claro, sin importar el brightness del sistema operativo

#### Scenario: Usuario selecciona modo oscuro
- **WHEN** el usuario elige "oscuro" en la preferencia de tema
- **THEN** la app renderiza con el theme oscuro, sin importar el brightness del sistema operativo

#### Scenario: Usuario selecciona seguir sistema
- **WHEN** el usuario elige "seguir sistema" en la preferencia de tema
- **THEN** la app renderiza con el theme claro u oscuro según el brightness reportado por el sistema operativo en ese momento

#### Scenario: El sistema operativo cambia de brightness mientras "seguir sistema" está activo
- **WHEN** el usuario tiene seleccionado "seguir sistema" y el sistema operativo cambia su brightness (por ejemplo, dark mode automático al anochecer)
- **THEN** la app actualiza su theme para reflejar el nuevo brightness sin requerir reiniciar la app

### Requirement: Persistencia de la preferencia de tema
El sistema SHALL persistir localmente la preferencia de tema elegida por el usuario y restaurarla al reabrir la app.

#### Scenario: Usuario reabre la app tras elegir un modo
- **WHEN** el usuario eligió un modo de tema (claro, oscuro, o sistema) y luego cierra y reabre la app
- **THEN** la app arranca con el mismo modo elegido previamente, sin requerir que el usuario lo vuelva a seleccionar

### Requirement: Migración de preferencia previa a la introducción de "seguir sistema"
El sistema SHALL migrar a los usuarios que tengan una preferencia de tema explícita guardada de una versión anterior (donde solo existían las opciones claro/oscuro) al modo "seguir sistema" en la primera apertura tras el update que introduce esta capability.

#### Scenario: Usuario con preferencia explícita previa abre la app tras el update
- **WHEN** un usuario tenía guardada una preferencia explícita de "claro" u "oscuro" de una versión anterior de la app, y abre la app por primera vez después del update que agrega la opción "seguir sistema"
- **THEN** la app queda configurada en modo "seguir sistema", reemplazando la preferencia explícita previa

#### Scenario: Usuario nuevo sin preferencia guardada abre la app
- **WHEN** un usuario no tiene ninguna preferencia de tema guardada (instalación nueva)
- **THEN** la app arranca en modo "seguir sistema" por defecto

### Requirement: Acceso a la selección de tema desde la UI
El sistema SHALL exponer una forma de que el usuario cambie manualmente entre las tres opciones de tema (claro, oscuro, sistema) desde algún punto navegable de la app.

#### Scenario: Usuario busca cambiar el tema manualmente
- **WHEN** el usuario quiere forzar el modo claro u oscuro en vez de seguir al sistema
- **THEN** puede acceder a un selector de tema desde la app y elegir cualquiera de las tres opciones, sin necesitar cambiar la configuración del sistema operativo

## Purpose

Permitir activar o desactivar funciones de la app de forma remota, sin publicar una versión nueva, con un comportamiento seguro (apagado) cuando el valor del flag no se puede conocer.

## ADDED Requirements

### Requirement: Un flag no resuelto se considera apagado
El sistema SHALL tratar un feature flag como apagado siempre que su valor no se conozca: sin conexión en el primer arranque, flags aún sin cargar, error del proveedor o flag inexistente. El sistema NO SHALL bloquear ni retrasar la interfaz esperando a que los flags carguen.

#### Scenario: Primer arranque sin conexión
- **WHEN** la app arranca por primera vez sin conexión y nunca se han cargado flags
- **THEN** todo flag consultado se considera apagado y la pantalla se muestra sin demora

#### Scenario: Flag inexistente
- **WHEN** la app consulta un flag que no existe en el proveedor
- **THEN** el sistema lo considera apagado

#### Scenario: Flags todavía cargando
- **WHEN** la pantalla se muestra antes de que terminen de cargar los flags
- **THEN** el sistema usa el último valor conocido o, si no hay, el valor apagado, sin mostrar un indicador de carga

### Requirement: Los cambios de flags llegan a la interfaz sin reiniciar
El sistema SHALL notificar a la interfaz cuando los flags terminan de cargar o cambian de valor, de modo que una pantalla ya visible refleje el valor nuevo sin que el usuario deba reiniciar la app ni volver a abrir la pantalla.

#### Scenario: Los flags llegan con la pantalla ya visible
- **WHEN** los flags terminan de cargar mientras una pantalla que depende de uno de ellos está visible
- **THEN** la pantalla se actualiza para reflejar el valor recibido

### Requirement: Persistencia del último valor conocido
El sistema SHALL conservar en el dispositivo el último valor recibido de cada flag, de modo que en los arranques siguientes esté disponible sin esperar a la red. Si el proveedor no responde en un arranque posterior, el sistema SHALL seguir usando ese último valor.

#### Scenario: Arranque posterior con valor guardado
- **WHEN** la app arranca con un valor de flag guardado de una sesión anterior
- **THEN** la interfaz usa ese valor sin esperar a la respuesta de la red

#### Scenario: Proveedor sin respuesta en un arranque posterior
- **WHEN** el proveedor de flags no responde y hay un valor guardado
- **THEN** el sistema sigue usando el valor guardado

### Requirement: Evaluación diferenciada por entorno
El sistema SHALL enviar el entorno de ejecución (desarrollo o producción) al proveedor como dato de evaluación de flags, de modo que un flag pueda activarse en un entorno sin activarse en el otro aunque ambos compartan el mismo proyecto del proveedor.

#### Scenario: Flag activo solo en desarrollo
- **WHEN** un flag está configurado para activarse únicamente en el entorno de desarrollo
- **THEN** una build de desarrollo lo recibe activo y una build de producción lo recibe apagado

#### Scenario: El entorno se conserva al restablecer la identidad
- **WHEN** la identidad del dispositivo se restablece (por ejemplo, al arrancar sin sesión o al cerrar sesión)
- **THEN** el sistema vuelve a enviar el entorno como dato de evaluación, de modo que un flag condicionado por entorno siga evaluándose igual

### Requirement: Ningún dato personal en la evaluación de flags
El sistema NO SHALL enviar al proveedor de flags el correo, el nombre ni contenido del usuario como dato de evaluación. Los datos de evaluación SHALL limitarse a información técnica no personal, como el entorno.

#### Scenario: Evaluación antes del login
- **WHEN** el sistema evalúa flags con el usuario sin sesión
- **THEN** la evaluación usa solo el identificador anónimo del dispositivo y el entorno

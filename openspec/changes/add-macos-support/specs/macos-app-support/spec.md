## Purpose

Define el comportamiento de Reevo como app de escritorio nativa en macOS: que arranque y funcione dentro del sandbox de la Mac App Store, que permita iniciar sesión, y que ofrezca las convenciones de una app de Mac (tamaño mínimo de ventana, barra de menús con atajos, teclado y hover).

## ADDED Requirements

### Requirement: App nativa de macOS con compra universal
El sistema SHALL ofrecer Reevo como app nativa de macOS, distribuida por la Mac App Store, con el mismo bundle ID que la app de iOS para que la compra sea universal. El binario SHALL funcionar en Macs con Apple Silicon y con Intel. La app SHALL ejecutarse dentro del App Sandbox con solo los permisos que necesita: red de salida, acceso a archivos elegidos por el usuario, Sign in with Apple y el llavero que usa el login con Google.

#### Scenario: Usuario con suscripción activa en iPhone abre Reevo en Mac
- **WHEN** un usuario con suscripción activa comprada en iOS inicia sesión con la misma cuenta en la app de Mac
- **THEN** el sistema lo reconoce como suscriptor sin pedirle comprar de nuevo

#### Scenario: La app corre dentro del sandbox
- **WHEN** la app arranca y realiza sincronización, lectura de artículos y login
- **THEN** todas esas operaciones funcionan con el App Sandbox activo, sin permisos adicionales a los declarados

### Requirement: Inicio de sesión con Google y con Apple en macOS
El sistema SHALL permitir en macOS el mismo inicio de sesión que en iOS (Google y Apple, además del correo cuando su feature flag esté activo), y SHALL resolver una misma persona a una misma cuenta sin importar desde qué plataforma inicie sesión.

#### Scenario: Login con Google en macOS
- **WHEN** el usuario toca "Continuar con Google" en la app de Mac y completa el flujo del sistema
- **THEN** el sistema crea una sesión activa y navega al Inbox

#### Scenario: Login con Apple en macOS
- **WHEN** el usuario toca "Continuar con Apple" en la app de Mac y autoriza con su Apple ID
- **THEN** el sistema crea una sesión activa y navega al Inbox

#### Scenario: Misma cuenta desde iOS y macOS
- **WHEN** un usuario que ya tiene cuenta creada desde iOS inicia sesión en macOS con el mismo proveedor y el mismo correo
- **THEN** el sistema abre esa misma cuenta, con sus fuentes, artículos y resúmenes, y no crea una cuenta nueva

#### Scenario: El usuario cancela el login
- **WHEN** el usuario cierra el diálogo de login del sistema sin completarlo
- **THEN** el sistema permanece en la pantalla de login sin mostrar un error

### Requirement: Archivos mediante los diálogos del sistema
El sistema SHALL importar archivos OPML y guardar o compartir las exportaciones de datos en macOS únicamente a través de los diálogos del sistema, de modo que el usuario elige explícitamente cada archivo al que la app accede.

#### Scenario: Importar un OPML
- **WHEN** el usuario elige importar un archivo OPML en macOS
- **THEN** el sistema abre el selector de archivos de macOS y, al elegir un archivo, lo importa igual que en iOS

#### Scenario: Exportar datos
- **WHEN** el usuario exporta sus datos o sus fuentes en macOS
- **THEN** el sistema muestra el diálogo de compartir o guardar del sistema anclado a la ventana de la app, y el archivo exportado tiene el nombre y el contenido correctos

### Requirement: Tamaño mínimo de ventana
El sistema SHALL impedir que la ventana de la app en macOS se redimensione por debajo de un tamaño mínimo en el que la interfaz deja de ser usable, y SHALL abrir la ventana por primera vez con un tamaño inicial en el que se muestra el rail de navegación y el master-detail.

#### Scenario: El usuario achica la ventana al mínimo
- **WHEN** el usuario arrastra el borde de la ventana hacia adentro hasta el límite
- **THEN** la ventana deja de achicarse en el tamaño mínimo y el contenido sigue siendo usable sin recortes ni overflow

#### Scenario: Primera apertura
- **WHEN** el usuario abre la app por primera vez en macOS
- **THEN** la ventana se abre con un tamaño inicial de 840dp de ancho o más

#### Scenario: La ventana cruza el umbral de 840dp
- **WHEN** el usuario redimensiona la ventana de modo que el ancho cruza los 840dp en cualquier dirección
- **THEN** el sistema alterna entre rail y drawer, y entre master-detail y pantalla completa, conservando la tab y el artículo seleccionados

### Requirement: Barra de menús nativa con atajos de teclado
El sistema SHALL mostrar en macOS la barra de menús del sistema con los menús estándar de una app de Mac (la app, Edición, Ver, Ventana y Ayuda) y SHALL ofrecer estos atajos para las acciones de la app: `⌘R` sincroniza, `⌘F` abre la búsqueda de la tab actual, y `⌘,` abre Ajustes. Todos los textos de los menús SHALL estar traducidos a inglés, español y francés.

#### Scenario: Sincronizar con ⌘R
- **WHEN** el usuario presiona `⌘R` con una sesión activa
- **THEN** el sistema inicia la sincronización de fuentes y de datos de la nube, igual que el pull-to-refresh del Inbox, y muestra los mismos avisos de error si falla

#### Scenario: Buscar con ⌘F en una tab con búsqueda
- **WHEN** el usuario presiona `⌘F` estando en Inbox, Favoritos, Leídos o Fuentes
- **THEN** el sistema abre el campo de búsqueda de esa tab con el foco en él

#### Scenario: Buscar con ⌘F en una tab sin búsqueda
- **WHEN** el usuario presiona `⌘F` estando en Resúmenes
- **THEN** el sistema no hace nada

#### Scenario: Abrir Ajustes con ⌘,
- **WHEN** el usuario presiona `⌘,` con una sesión activa
- **THEN** el sistema navega a Ajustes

#### Scenario: Atajos sin sesión
- **WHEN** el usuario presiona `⌘R`, `⌘F` o `⌘,` en la pantalla de login
- **THEN** el sistema no ejecuta ninguna acción y los elementos de menú correspondientes aparecen deshabilitados

#### Scenario: Escribir en un campo de texto
- **WHEN** el usuario tiene el foco en un campo de texto y usa `⌘C`, `⌘V`, `⌘X`, `⌘A` o `⌘Z`
- **THEN** el campo responde con el comportamiento estándar de edición de macOS

### Requirement: Navegación por teclado en las listas
El sistema SHALL permitir en macOS recorrer con el teclado las listas de artículos, fuentes y resúmenes: las flechas arriba y abajo mueven la selección, `Enter` abre el elemento enfocado y `Esc` cierra el detalle o el diálogo abierto. El elemento enfocado SHALL tener un indicador visible.

#### Scenario: Moverse por la lista
- **WHEN** el usuario presiona la flecha abajo con el foco en una lista de artículos
- **THEN** el foco pasa al elemento siguiente y la lista se desplaza para mantenerlo visible

#### Scenario: Abrir con Enter
- **WHEN** el usuario presiona `Enter` sobre un elemento enfocado
- **THEN** el sistema abre ese elemento igual que si lo hubiera tocado con el mouse, y lo marca como seleccionado en el panel master

#### Scenario: Cerrar con Esc
- **WHEN** el usuario presiona `Esc` con un diálogo (por ejemplo el paywall) abierto
- **THEN** el sistema cierra el diálogo

### Requirement: Hover y cursor en elementos clicables
El sistema SHALL mostrar en macOS un estado de hover en los elementos que se pueden activar con el mouse (filas de lista, destinos del rail, botones) y SHALL cambiar el cursor a la mano en los elementos que abren algo, de modo que lo clicable se distinga sin tener que probarlo.

#### Scenario: Pasar el mouse sobre una fila
- **WHEN** el usuario mueve el puntero sobre una fila de artículo
- **THEN** la fila muestra un estado de hover visible, en tema claro y oscuro

#### Scenario: Pasar el mouse sobre un destino del rail
- **WHEN** el usuario mueve el puntero sobre un destino del rail
- **THEN** el cursor cambia a la mano y el destino muestra el estado de hover

### Requirement: Arranque sin pantalla nativa de launch
El sistema SHALL arrancar en macOS sin pantalla nativa de launch: la ventana muestra el primer frame de Flutter cuando está listo, sin imagen de arranque ni parpadeo adicional.

#### Scenario: Primer arranque en macOS
- **WHEN** el usuario abre la app en macOS
- **THEN** la ventana aparece con el primer frame de la app ya pintado, y el arranque no falla por la ausencia de una pantalla nativa de launch

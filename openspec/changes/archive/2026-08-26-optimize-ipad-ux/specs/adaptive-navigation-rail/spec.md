## Purpose

Define el comportamiento de un `NavigationRail` permanente que reemplaza al `NavigationDrawer` modal cuando el ancho de la ventana es suficiente para mostrarlo sin sacrificar espacio de contenido, siguiendo el breakpoint "expanded" de Material 3.

## ADDED Requirements

### Requirement: Umbral de ancho para mostrar el rail
El sistema SHALL mostrar un `NavigationRail` permanente en lugar del `NavigationDrawer` modal cuando el ancho disponible de la ventana sea de 840dp o más, y SHALL mostrar el `NavigationDrawer` modal cuando el ancho sea menor a 840dp.

#### Scenario: Ventana ancha
- **WHEN** el ancho de la ventana es de 840dp o más
- **THEN** el sistema muestra el `NavigationRail` de forma permanente y no muestra el ícono de hamburguesa ni el `NavigationDrawer` modal

#### Scenario: Ventana angosta
- **WHEN** el ancho de la ventana es menor a 840dp
- **THEN** el sistema muestra el `NavigationDrawer` modal existente, sin mostrar el `NavigationRail`

#### Scenario: La ventana cruza el umbral en tiempo real
- **WHEN** el usuario rota el dispositivo o redimensiona la ventana y el ancho cruza el umbral de 840dp en cualquier dirección
- **THEN** el sistema alterna entre `NavigationRail` y `NavigationDrawer` sin requerir reiniciar la app ni perder la tab actualmente seleccionada

### Requirement: Destinos del rail
El `NavigationRail` SHALL mostrar los mismos 5 destinos de navegación que el `NavigationDrawer` (Inbox, Favoritos, Archivo, Fuentes, Resúmenes), con el mismo ícono, label y orden que usa el Drawer.

#### Scenario: Destinos visibles en el rail
- **WHEN** el `NavigationRail` está visible
- **THEN** muestra los 5 destinos de navegación existentes, cada uno con su ícono y label correspondiente

### Requirement: Badge de no leídos en el rail
El `NavigationRail` SHALL mostrar el contador de artículos no leídos del Inbox junto al destino Inbox, con el mismo comportamiento de formato (número exacto hasta 999, "999+" por encima) que usa el `NavigationDrawer`.

#### Scenario: Hay artículos no leídos
- **WHEN** el conteo de artículos no leídos del Inbox es mayor a 0 y el `NavigationRail` está visible
- **THEN** el rail muestra el contador junto al destino Inbox, sin desbordar su contenedor visual

### Requirement: Acceso a Ajustes desde el rail
El `NavigationRail` SHALL mostrar un ícono de acceso a la pantalla de Ajustes fijo al pie del rail, siempre visible independientemente del destino seleccionado.

#### Scenario: Usuario toca el ícono de Ajustes del rail
- **WHEN** el usuario toca el ícono de Ajustes al pie del `NavigationRail`
- **THEN** el sistema navega a la pantalla de Ajustes

### Requirement: Cerrar sesión disponible dentro de Ajustes
El sistema SHALL ofrecer la acción "Cerrar sesión" dentro de la pantalla de Ajustes en lugar de exponerla directamente en el `NavigationRail` o en el `NavigationDrawer`.

#### Scenario: Usuario busca cerrar sesión con el rail visible
- **WHEN** el `NavigationRail` está visible (ancho ≥840dp)
- **THEN** la acción "Cerrar sesión" no aparece en el rail; el usuario debe entrar a Ajustes para encontrarla

#### Scenario: Usuario busca cerrar sesión con el Drawer visible
- **WHEN** el `NavigationDrawer` modal está visible (ancho <840dp)
- **THEN** la acción "Cerrar sesión" no aparece en el Drawer; el usuario debe entrar a Ajustes para encontrarla

### Requirement: Indicador visual del destino seleccionado en el rail
El `NavigationRail` SHALL distinguir el destino actualmente seleccionado con un estilo visualmente sutil, consistente con el criterio usado en el `NavigationDrawer` (sin un color que contraste fuertemente con el fondo general).

#### Scenario: Usuario cambia de destino en el rail
- **WHEN** el usuario selecciona un destino distinto en el `NavigationRail`
- **THEN** el indicador de selección se mueve al nuevo destino con el mismo estilo sutil usado en el resto de la app

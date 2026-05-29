## ADDED Requirements

### Requirement: Drawer muestra identificación del grupo
El drawer de configuración SHALL mostrar una entrada informativa estática con el nombre del equipo `Grupo 5`, incluyendo un ícono representativo y un subtítulo con el contexto académico `UTN FRLP · IA 2026`.

#### Scenario: Drawer abierto muestra "Grupo 5"
- **WHEN** el usuario abre el drawer lateral
- **THEN** el drawer SHALL mostrar un tile con el texto `Grupo 5` y el subtítulo `UTN FRLP · IA 2026` antes de la sección de controles

#### Scenario: Tile de grupo no es interactivo
- **WHEN** el usuario toca el tile de `Grupo 5`
- **THEN** no SHALL ocurrir ninguna acción ni navegación

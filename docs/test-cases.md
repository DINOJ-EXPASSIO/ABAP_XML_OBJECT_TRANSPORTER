# Casos de prueba

## Controles locales

- Ejecutar `npx --yes --package=@abaplint/cli abaplint abaplint.json`.
- Ejecutar `tools/validate-fixtures.ps1`.
- Revisar `git diff --check`.

## Casos SAP de ida y vuelta

| Caso | Resultado esperado |
| --- | --- |
| Programa con includes, dynpro y CUA | Fuente y componentes quedan disponibles; activacion informa dependencias faltantes. |
| Programa con DDIC propio incluido | DDIC se importa antes del programa. |
| Dependencia externa faltante | El objeto queda bloqueado antes de escribir el fuente. |
| Ciclo de dependencias | Se muestran todos los nodos del ciclo y no se importan. |
| OT abierta y package transportable | Se permite la importacion. |
| OT cerrada o inexistente | Se bloquea antes de abrir el ALV de importacion. |
| Mapeo de nombre valido | Se muestra el plan; se importan solo adaptadores que pueden reescribir referencias. |
| Mapeo con referencia dinamica | Se rechaza antes de escribir. |

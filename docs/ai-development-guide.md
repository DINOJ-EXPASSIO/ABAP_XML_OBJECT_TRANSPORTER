# Guia de desarrollo asistido por IA local

La IA se usa para analizar y proponer cambios dentro de este repositorio. No forma parte de la ejecucion SAP ni recibe datos productivos.

## Contexto obligatorio antes de cambiar ABAP

1. Leer `README.md`, `docs/object-support.md`, `docs/xml-format.md` y la validacion de componentes.
2. Mantener los dos reportes autonomos y el formato XML como contrato.
3. Identificar el release SAP objetivo y no inventar APIs no verificadas.
4. Ejecutar `abaplint` y documentar las pruebas SAP necesarias.

## Prohibiciones

- No introducir BTP, HTTP, RFC ni dependencias externas para transportar objetos.
- No declarar soportado un objeto sin exportador, importador y prueba SAP.
- No modificar tablas SAP directamente para evadir una API sin documentar el riesgo y la alternativa.
- No reemplazar masivamente nombres en fuente, XML o payloads.
- No sobrescribir objetos SAP ni objetos de origen desconocido.

## Prompt de revision sugerido

> Revisa este cambio ABAP contra `docs/object-support.md` y `docs/xml-format.md`. Indica incompatibilidades de release, referencias no reescribibles, cambios de contrato XML, riesgos de sobrescritura y pruebas SAP requeridas. No propongas dependencias externas.

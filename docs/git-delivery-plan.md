# Plan de entregables y commits Git

## Decisiones de arquitectura

### Dos programas ABAP autonomos

Se conservan los dos reportes actuales, instalables manualmente en SAP legacy:

- `ZJDR_XML_OBJECTS_EXPORT`: descubre objetos y crea el XML.
- `ZJDR_XML_OBJECTS_IMPORT`: lee el XML y crea o actualiza en destino.

No se requiere BTP, HTTP, RFC, base externa ni framework adicional. El XML local es el contrato entre ambos reportes.

Un unico reporte con modos `Exportar` e `Importar` es tecnicamente posible, pero no se adopta: separar los ejecutables permite instalar solo el que se necesita, reduce cambios cruzados y facilita el arranque manual en un sistema nuevo.

### IA local para desarrollar

La IA es una ayuda de desarrollo, no una dependencia de ejecucion SAP. El repositorio debe aportar Markdown con arquitectura, contrato XML, objetos soportados, limites, reglas para cambios y pruebas. Todo cambio sugerido por IA se revisa, pasa `abaplint` y se prueba en SAP.

## Convenciones

- Cada commit debe compilar y pasar `abaplint`.
- Un objeto se declara soportado solo si tiene exportacion, importacion, orden de dependencias y prueba SAP de ida y vuelta.
- Los objetos no soportados quedan como `SKIPPED` o `ERROR`; nunca como exito.
- Se conserva SAP GUI y el archivo XML local.

### Seleccion y renombrado de objetos

El exportador y el importador deben permitir seleccionar filas individuales del ALV; un objeto seleccionado no obliga a exportar o importar sus dependencias. El usuario podra elegir entre incluir dependencias sugeridas, excluirlas o seleccionarlas individualmente cuando sean objetos de repositorio.

Los componentes internos de un programa —includes, dynpros, CUA, textos, documentacion, transacciones y enhancements— no se tratan como objetos de repositorio independientes: viajan dentro del `PROG` padre y no pueden separarse sin que el programa quede potencialmente incompleto.

El renombrado se implementa como un mapeo `tipo + nombre_origen -> tipo + nombre_destino`. El XML conserva siempre la identidad de origen; el nombre destino es una instruccion de importacion validada, no una alteracion libre del payload. El importador debe propagar el mapeo solo en referencias conocidas y rechazar los casos que no pueda reescribir de forma segura.

---

## Commit 1 — Contrato de objetos y contexto local para IA

**Mensaje del commit**

```text
docs: define object support contract and local AI development context
```

**Tarea**

Documentar el alcance real y el contexto necesario para desarrollar el proyecto con asistencia IA local.

**Especificacion**

- Crear `docs/object-support.md`: estado `soportado`, `parcial`, `pendiente`, `no soportado` por tipo.
- Crear `docs/xml-format.md`: version, nodos, payloads y compatibilidad entre exportador e importador.
- Crear `docs/ai-development-guide.md`: prompts de revision, reglas y prohibiciones.
- Crear `docs/test-cases.md`: pruebas de ida y vuelta y negativas.
- Corregir codificacion UTF-8 de Markdown existente si fuera necesario.

**Puntos a realizar**

- Inventariar `PROG`, DDIC, `FUGR`, `CLAS`, `INTF`, componentes e IDoc.
- Marcar IDoc como no importable hasta tener circuito probado.
- Registrar APIs SAP usadas y releases donde fueron validadas.
- Añadir checklist para cambios generados con IA: no inventar APIs, no sumar dependencias externas y no escribir tablas SAP sin justificacion.

**Alcance**

Documentacion local. Los dos reportes no cambian.

**Limites**

- No agrega objetos.
- No conecta SAP a ningun modelo IA.
- No reemplaza pruebas SAP.

**Se agrega**

- Contrato de soporte, guia local IA y casos de prueba.

**Se quita**

- Ambiguedad sobre objetos exportables pero no importables.

---

## Commit 2 — Dependencias recursivas desde un programa

**Mensaje del commit**

```text
feat(export): collect recursive dependencies for selected programs
```

**Tarea**

Al seleccionar un programa, agregar automaticamente al XML sus dependencias propias conocidas.

**Especificacion**

- Crear una tabla interna con origen, objeto requerido, tipo, motivo y estado.
- Resolver `DOMA`, `DTEL`, `STRU`, `TABL`, `TTYP`, `SHLP`, `CLAS`, `INTF` y `FUGR` desde fuentes y metadatos.
- Resolver recursivamente hasta no encontrar objetos nuevos.
- Evitar duplicados y detectar ciclos.
- Mostrar en ALV objetos agregados y prerequisitos externos.
- Guardar las dependencias como nodos opcionales del XML; importadores antiguos deben ignorarlos.

**Puntos a realizar**

- Distinguir objetos propios, SAP estandar y referencias dinamicas no resolubles.
- Permitir desmarcar una dependencia sugerida antes de exportar.
- Informar si una dependencia no existe en TADIR o no tiene adaptador.

**Alcance**

Programas propios y tipos actualmente manejados por el exportador.

**Limites**

- No resuelve nombres construidos dinamicamente de forma fiable.
- No incluye customizing, datos, RFC, jobs ni autorizaciones.
- No exporta objetos SAP estandar.

**Se agrega**

- XML autocontenido para un desarrollo ABAP clasico, en la medida de dependencias analizables.

**Se quita**

- Seleccion manual de la mayor parte de dependencias tecnicas conocidas.

---

## Commit 3 — Plan de importacion simple y prevalidacion

**Mensaje del commit**

```text
feat(import): validate dependencies and import in safe object order
```

**Tarea**

Validar dependencias y ordenar el lote antes de escribir en destino.

**Especificacion**

- Comprobar que cada dependencia incluida exista en XML o este activa en destino.
- Ordenar: DDIC, interfaces/clases y grupos de funciones, programas, componentes y transacciones.
- Detectar ciclos y bloquear solo sus objetos afectados.
- Mostrar en ALV orden, prerequisitos faltantes y causa de bloqueo.
- Mantener `p_test` sin escrituras.
- Usar la prioridad actual solo como fallback.

**Puntos a realizar**

- No ejecutar `INSERT REPORT` cuando falte un prerequisito obligatorio conocido.
- Mantener importacion de objetos individuales elegidos en ALV.
- Registrar cada decision en el log actual.

**Alcance**

Tipos ya soportados; solo XML local y tablas internas.

**Limites**

- No cubre todas las referencias dinamicas ni autorizaciones funcionales.
- No crea ni libera OT.
- No garantiza rollback global de APIs SAP.

**Se agrega**

- Preflight y orden basado en dependencias reales conocidas.

**Se quita**

- Confianza exclusiva en una prioridad fija por tipo.

---

## Commit 4 — Objetos reutilizables frecuentes

**Mensaje del commit**

```text
feat(objects): transport messages locks and program variants dependencies
```

**Tarea**

Ampliar la cobertura para que programas trasladados puedan ejecutarse con sus artefactos propios frecuentes.

**Especificacion**

- Agregar `MSAG` y textos de clase de mensajes.
- Agregar `ENQU` solo si existe una API probada en el release objetivo.
- Detectar variantes de transaccion y elegir por tipo una politica explicita: exportar datos soportados o declarar prerequisito externo.
- Incluir estado y dependencias en XML y ALV.
- Habilitar cada tipo despues de pruebas SAP de ida y vuelta.

**Puntos a realizar**

- Implementar primero `MSAG`.
- No escribir tablas SAP directamente si existe una API apta.
- Añadir casos: programa con mensajes, lock object y variante.

**Alcance**

Objetos propios recurrentes en ABAP clasico.

**Limites**

- No incluye datos, customizing ni configuracion de negocio.
- No cubre todos los artefactos SAP.
- Variantes sensibles pueden requerir mantenimiento manual.

**Se agrega**

- Cobertura `MSAG` y, si se certifica, `ENQU`; politica de variantes.

**Se quita**

- Fallos silenciosos por clases de mensajes o locks propios ausentes.

---

## Commit 5 — Validacion compacta de OT y log descargable

**Mensaje del commit**

```text
feat(import): verify transport request and log object results
```

**Tarea**

Evitar fallos previsibles de OT sin construir infraestructura CTS adicional.

**Especificacion**

- Comprobar que `p_req` exista, este abierta y sea Workbench para package distinto de `$TMP`.
- Conservar las APIs de registro ya usadas donde correspondan.
- Mostrar si un objeto no pudo asociarse a la OT.
- Mantener log de sesion en memoria y permitir descargarlo localmente.
- Permitir `$TMP` sin OT.

**Puntos a realizar**

- Añadir F4 de OT si es viable.
- Validar antes de abrir ALV.
- Añadir OT, package destino y modo simulacion al log.
- Probar OT valida, cerrada, inexistente y `$TMP`.

**Alcance**

Validacion practica de OT y diagnostico.

**Limites**

- No crea, libera ni transporta OT.
- No agrega auditoria persistente, reanudacion ni motor CTS.

**Se agrega**

- Rechazo temprano de OT inutilizable y log descargable.

**Se quita**

- Errores tardios por OT inexistente o cerrada.

---

## Commit 6 — Fixtures, pruebas SAP y control de calidad local

**Mensaje del commit**

```text
test: add round-trip fixtures and local quality checks
```

**Tarea**

Hacer repetible la validacion de los cambios, incluidos los desarrollados con IA local.

**Especificacion**

- Mantener `abaplint` como control local obligatorio.
- Crear fixtures XML anonimos de programas, DDIC, OO, `FUGR`, mensajes y errores esperados.
- Crear script local que ejecute lint y compruebe estructura de fixtures.
- Actualizar `docs/program-components-validation.md` con evidencia por release.
- Añadir checklist: alcance, dependencias, simulacion, importacion y activacion.

**Puntos a realizar**

- Probar programa completo con dynpro, CUA, transaccion e includes.
- Probar dependencias recursivas, faltantes, ciclos y XML viejo.
- Probar OT valida e invalida.
- Corregir solamente el adaptador que falle en un release.

**Alcance**

Calidad local Git y procedimiento de prueba SAP.

**Limites**

- `abaplint` no valida APIs, autorizaciones ni activacion SAP.
- Requiere sistema SAP origen y destino para pruebas funcionales.

**Se agrega**

- Fixtures, checklist y evidencia de pruebas.

**Se quita**

- Dependencia exclusiva de validaciones manuales no documentadas.

---

## Commit 7 — Seleccion individual y mapeo seguro de nombres destino

**Mensaje del commit**

```text
feat(mapping): select objects individually and map source names to destination names
```

**Tarea**

Permitir decidir que objetos se exportan o importan y, antes de importar, asignar nombres destino distintos a los nombres del sistema origen.

**Entregable**

Una version nueva y compatible del XML con relaciones de objetos y mapeos opcionales de destino, mas ambos ALV actualizados para seleccionar objetos de repositorio, revisar su padre/relacion, editar el nombre destino en importacion y ejecutar una simulacion del plan de renombrado. El importador debe rechazar, antes de escribir, cualquier mapeo que produzca una colision o que no pueda propagarse de forma controlada.

**Especificacion**

- Agregar al manifiesto una identidad inmutable de origen: `source_object_type` y `source_object_name`.
- Agregar una seccion opcional `target_mapping` con tipo/nombre origen y tipo/nombre destino.
- Mostrar en ambos ALV las columnas `Objeto origen`, `Objeto destino`, `Padre`, `Tipo de relacion` y `Incluir`.
- Permitir editar el objeto destino solo en el importador; en el exportador se podra proponer y guardar el mapeo como plantilla, sin cambiar el payload exportado.
- Permitir seleccionar o deseleccionar cualquier objeto de repositorio incluido en el manifiesto.
- Marcar dependencias agregadas automaticamente como `DEPENDENCY`; marcar el objeto solicitado como `ROOT`.
- Para componentes internos del programa, registrar `parent_object = PROG` y `relationship = COMPONENT`, sin ofrecer su importacion aislada.
- Validar colisiones de nombre, limite de longitud, namespace, package, OT y existencia en destino antes de escribir.
- Aplicar el mapeo en dependencias conocidas: DDIC, firmas de modulos, referencias de clase/interfaz, includes, transacciones, dynpros y enhancements cuando la API lo permita.
- Rechazar con mensaje claro cualquier referencia dinamica, payload o componente que no sea seguro renombrar.

**Puntos a realizar**

- Crear tipos internos `ty_object_identity`, `ty_object_relation` y `ty_name_mapping`, duplicados en ambos reportes mientras permanezcan autonomos.
- Extender el exportador para guardar raiz, padre y relacion por objeto en XML.
- Extender el importador para cargar, revisar y editar el mapeo antes de ejecutar.
- Resolver referencias usando el mapeo antes de cada adaptador de importacion, nunca con reemplazo global de texto ABAP/XML.
- Mantener el nombre original para logs, hashes, validacion de payload y trazabilidad.
- Bloquear un programa si se intenta renombrar solo un componente que debe compartir identidad con su padre.
- Añadir modo simulacion que muestre el plan de nombres y todas las referencias que se reescribiran.

**Alcance**

Seleccion individual de objetos de repositorio y renombrado de objetos propios cuyos adaptadores permitan reescritura controlada.

**Limites**

- El usuario ya puede seleccionar filas individuales en los ALV actuales para exportar e importar; este commit amplía esa seleccion a objetos descubiertos como dependencias.
- Actualmente no hay un campo ALV que identifique de forma general `raiz/dependencia/padre`; los includes y componentes se asocian internamente al programa mediante sus payloads, pero no son seleccionables por separado.
- No se permite reemplazo textual global de nombres: podria modificar comentarios, literales, SQL dinamico o referencias no relacionadas.
- No se renombra automaticamente objetos SAP, referencias dinamicas, objetos sin adaptador ni componentes cuyo nombre este generado por SAP.
- Un objeto renombrado puede requerir ajustes manuales de codigo cuando la referencia no sea analizable.

**Se agrega**

- Manifiesto con relacion `ROOT` / `DEPENDENCY` / `COMPONENT` y objeto padre.
- Mapeo trazable origen-destino y vista previa en simulacion.
- Seleccion individual para dependencias de repositorio.

**Se quita**

- Necesidad de conservar obligatoriamente el mismo nombre tecnico para todos los objetos importables de forma segura.

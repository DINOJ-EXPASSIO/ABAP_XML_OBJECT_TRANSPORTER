# Validación en SAP de componentes de programas

Estado: pendiente de ejecución en SAP. La validación local comprueba gramática
ABAP y consistencia estructural; no verifica firmas DDIC, autorizaciones,
bloqueos ni efectos de las APIs del release destino.

Instalar juntos el exportador y el importador actualizados. Exportar de nuevo
los programas: los XML anteriores no contienen `program_payload`.

| Caso | Preparación | Resultado esperado |
| --- | --- | --- |
| Module pool | Programa propio tipo M, dynpro 0100 con campos, table control, PBO, PAI y títulos ES/EN | Se conserva el tipo M, diseño, lógica y títulos por idioma. Sin `p_activ`, no se solicita activación final. |
| Pantalla nativa | Dynpro con splitter y controles especiales | Se usa la representación nativa. Comparar SE51, textos y estado tras guardar; verificar si el release genera la pantalla. Un rechazo se informa como pendiente. |
| CUA | Dos estados GUI, menú, botones, teclas y títulos en dos idiomas | Comparar en SE41 cada idioma y confirmar que no se crean traducciones por fallback de la API. |
| Textos | Textpool ES/EN del principal y de un include propio, con acentos, comillas y símbolos XML | Comparar textos y longitudes en ambos idiomas; no se modifican includes estándar. |
| Documentación | Documentación de reporte e include, activa en ES/EN, con líneas SAPscript | Comparar contenido y formato. No se escribe otro objeto usando un THEAD diferente del nombre validado. |
| Transacción directa | Transacción propia de diálogo y otra de reporte, nuevas en destino | Comparar programa, pantalla, GUI, textos de todos los idiomas y TSTCA en SE93. Verificar package y tarea de transporte. |
| Transacciones indirectas | Transacción de parámetros que llama a la anterior, otra que la llama, y una con variante existente | Se descubren sin ciclos y se importan después de la transacción destino. Comparar parámetros, salto de pantalla y referencia a variante. |
| Sobrescritura | Transacción existente con definición igual; repetir con definición distinta | Sin sobrescritura no se altera. Con sobrescritura, la igual recibe textos/autorizaciones; la distinta queda pendiente y conserva su definición. |
| Enhancement explícito | ENHS de código y ENHO asociados al programa propio, nuevos en destino | Comparar punto/sección, objeto original, fuente del hook y package/OT. Guardado antes de activación final. |
| Enhancement implícito | ENHO de código asociado a un include propio | Se detecta por su objeto original y se recrea mediante Enhancement Framework. Verificar que no se duplica el código del hook. |
| Enhancement existente | Repetir la importación con ENHS/ENHO ya existentes | Se conserva el existente y se informa revisión pendiente. No se declara reemplazo ni importación completa. |
| Dependencias faltantes | Quitar un tipo DDIC usado por fuente, dynpro y hook | El fuente se conserva inactivo. Si una API rechaza metadatos, se informa componente/nombre/idioma y se continúa. No se declara éxito global. |
| Activación | Importar con todos los requisitos y `p_activ` marcado | El lote incluye REPS/REPT/DYNP/CUAD/ENHS/ENHO. Revisar que no quedan versiones inactivas y probar SE93 después de activar. |
| Origen SAP | XML de prueba con TRAN/ENHO/ENHS que ya existen como estándar | Se rechazan esas escrituras, aunque el PROG padre sea propio. |
| Identidad incorrecta | Cambiar programa interno de un dynpro, documento, transacción o enhancement | Se rechaza el componente. No cambia el objeto cuyo nombre se inyectó. |
| Compatibilidad | XML 1.1 original y XML 1.2 sin `program_payload` | El 1.1 permite fuentes y avisa de componentes ausentes. El 1.2 incompleto se rechaza antes de guardar fuentes. |
| Simulación | Ejecutar los anteriores con `p_test` | No se invoca ninguna escritura de componentes ni activación. |

Las llamadas se contrastaron con implementaciones públicas de abapGit:
[programas y pantallas](https://github.com/abapGit/abapGit/blob/main/src/objects/zcl_abapgit_objects_program.clas.abap),
[transacciones](https://github.com/abapGit/abapGit/blob/main/src/objects/zcl_abapgit_object_tran.clas.abap),
[documentación](https://github.com/abapGit/abapGit/blob/main/src/objects/texts/zcl_abapgit_longtexts.clas.abap),
[implementaciones de hooks](https://github.com/abapGit/abapGit/blob/main/src/objects/enh/zcl_abapgit_object_enho_hook.clas.abap)
y [definiciones de hooks](https://github.com/abapGit/abapGit/blob/main/src/objects/enh/zcl_abapgit_object_enhs_hook_d.clas.abap).
El proyecto no requiere instalar abapGit para ejecutar estos reportes.

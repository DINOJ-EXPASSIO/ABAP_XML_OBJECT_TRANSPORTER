# ABAP_XML_OBJECT_TRANSPORTER

Herramienta SAP GUI para mover objetos ABAP mediante XML.

Para exportar objetos individuales, dejá `s_pack` vacío e ingresá los nombres
en `s_obj`. La ayuda F4 no exige package y muestra desarrollos propios.
El filtro `s_req` permite seleccionar órdenes de transporte o tareas, también
sin package. Una OT incluye sus tareas; una tarea sola no incluye sus hermanas.
Los subobjetos LIMU se resuelven al objeto principal R3TR, sin duplicados.
Los filtros de package, nombre y OT se combinan por intersección y se conservan
las casillas de tipos de objeto y la selección final de filas del ALV.
Se puede usar solo OT, solo objeto, solo package o cualquiera de sus
combinaciones; los filtros vacíos no restringen la búsqueda.

«Objetos Z» significa desarrollos propios, sin exigir un prefijo de nombre.
La selección del repositorio usa `TADIR-SRCSYSTEM`: admite un sistema original
informado y distinto de `SAP`. Esto incluye nombres Y, namespaces y otros
nombres propios registrados con ese origen. La clasificación depende de que
el catálogo de objetos esté correctamente mantenido; no se deduce del package.
SAP documenta el significado de `SRCSYSTEM=SAP` en
[Data Loss after the upgrade](https://help.sap.com/docs/SUPPORT_CONTENT/sl/3362917258.html).

El XML incorpora `original_system` por objeto. El importador comprueba primero
el origen declarado y el catálogo local; un objeto SAP existente no se puede
sobrescribir. Para destinos nuevos utiliza el origen del XML. Este metadato
no autentica el archivo: se deben importar XML de origen confiable.
Los XML anteriores sin ese dato admiten objetos identificables en el catálogo
local o nombres Y/Z; para otros objetos nuevos hay que volver a exportar.
Los includes se comprueban por su entrada de catálogo o su objeto propietario;
los componentes técnicos de grupos propios no necesitan comenzar con Z.
Se mantiene la validación de coincidencia de nombres en payloads DDIC y se
impide sustituir un módulo de función que pertenezca a otro grupo.

Se exporta el estado actual de los objetos en el sistema, no una versión
histórica de la OT ni datos de customizing. Se mantienen los tipos soportados
y la exclusión de objetos generados; los objetos inexistentes en TADIR no se
exportan. Las selecciones IDoc conservan sus criterios específicos.
El XML registra el filtro de OT en `transport_selection`.

El formato portable actual es `sap_package_export` versión `1.2`. El
exportador siempre incluye `header/package`, que el importador usa como
package destino por defecto; `p_pack` permite reemplazarlo.
El importador sigue leyendo XML `1.1`. Los importadores anteriores rechazan
`1.2`, evitando que ignoren los componentes nuevos y declaren una importación
completa de un programa del que solo leyeron el fuente.

La importación guarda los programas, sus includes y los fuentes de grupos de
funciones con `STATE 'I'`. La creación de módulos nuevos usa
`SAVE_ACTIVE = space`: no se fuerza la compilación durante el guardado.
Con `p_activ` desmarcado, los fuentes quedan inactivos para corregir referencias
o tipos faltantes en SAP. Si se marca, la activación de fuentes se intenta al
final del lote; un fallo queda como advertencia y conserva los fuentes guardados.
La opción no garantiza crear metadatos que la API de Function Builder rechace:
esos errores se muestran en el botón **Ver log**, y se continúa con los demás
módulos. Los grupos de mantenimiento de tablas siguen requiriendo SE54.

El importador acepta tanto `<includes>` de archivos anteriores como
`<source_includes>`. Omite fuentes estándar incluidas en XML anteriores sin
bloquear el reporte propio. La lectura y escritura del XML usan UTF-8.
Los fuentes se conservan completos, incluidos comentarios y comillas; no se
filtran líneas del cuerpo de los módulos. Los parámetros del payload antiguo
se convierten explícitamente, incluyendo `TYPE`/`LIKE`, tipo y valor por defecto.
Al actualizar módulos existentes se usa su include real de destino y se conserva
su interfaz: el ALV pide revisarla en SE37 y no activa automáticamente ese grupo.

La comprobación local de gramática se ejecuta con
`npx --yes --package=@abaplint/cli abaplint abaplint.json`.
No sustituye la validación de firmas DDIC/APIs ni las pruebas de ejecución en SAP.

El circuito exportar/importar está implementado para `PROG`, `DOMA`, `DTEL`,
`TABL`, `STRU`, `TTYP`, `SHLP`, `FUGR`, `CLAS` e `INTF`. En programas se conservan tanto el
fuente principal como los includes propios detectados. Para `FUGR`, se exportan el
catálogo de módulos, sus interfaces y los includes; al importar se crea el
grupo, se registra en el package destino y se recrean los módulos con las APIs
de Function Builder. Los tipos de tabla se intercambian con las estructuras
`DD40V`, `DD42V` y `DD43V` requeridas por las APIs DDIC.

Los objetos `PROG` incluyen `program_payload`, en base64/asXML con formato
`PROGRAM_COMPONENTS_1`. Se conserva el tipo del programa: un module pool no
se recrea como reporte ejecutable. Los componentes acompañan al programa
seleccionado; no necesitan seleccionarse como objetos independientes.

| Componente del programa | Exportación e importación implementadas |
| --- | --- |
| Dynpros | Cabecera, contenedores, campos, lógica de flujo, textos de campos y títulos por idioma. Se conserva también la representación nativa de campos para pantallas con splitters. Se usan `RPY_DYNPRO_READ`/`INSERT` y sus variantes nativas. Las pantallas de selección generadas se regeneran desde el fuente. |
| Interfaz GUI | Estados, funciones, menús, teclas, botones y títulos CUA, consultando los idiomas de SAP y omitiendo aquellos para los que la API devuelve `NOT_FOUND`. Se guarda con `RS_CUA_INTERNAL_WRITE`, estado inactivo. |
| Elementos de texto | Textpools activos de todos los idiomas registrados en `D010TINF`, tanto del programa como de sus includes propios. |
| Documentación | Documentación activa `RE` del programa y de sus includes, con cabecera, formato SAPscript y líneas, en cada idioma registrado en `DOKIL`. Se lee/escribe con `DOCU_READ`/`DOCU_UPDATE`. |
| Transacciones | Transacciones propias que apuntan al programa y cadenas de transacciones propias de parámetros/variantes que las llaman. Incluye configuración GUI, textos traducidos y autorizaciones de inicio `TSTCA`. Las nuevas se crean con `RPY_TRANSACTION_INSERT`. |
| Enhancements de código | Definiciones `ENHS` de puntos/secciones y sus implementaciones `ENHO`, asociadas mediante Enhancement Framework al programa o a sus includes propios. Incluye los fuentes de los hooks; se crean mediante `CL_ENH_FACTORY`. |

Se valida por separado el origen de cada transacción, `ENHS` y `ENHO`.
Las identidades internas de pantallas, textos, documentación y enhancements
se contrastan con los fuentes del programa importado. Los objetos asociados
no pueden usar el nombre de otro programa como destino de escritura.
Los nuevos objetos independientes se registran en el package y la OT destino.

Con `p_activ` marcado, el lote final incluye `REPS`, `REPT`, `DYNP`, `CUAD`,
`ENHS` y `ENHO`. Se guarda primero el fuente; un error en un componente se
registra individualmente en **Ver log**, deja el programa con advertencia y
evita su activación automática. El fallo de un componente no impide intentar
los siguientes. Los XML `1.1` siguen permitiendo guardar y activar fuentes,
pero conservan una advertencia de que no contienen los componentes nuevos.

La opción de activación controla las solicitudes de activación de Workbench.
Las transacciones, documentación y traducciones de textpool adicionales se
guardan directamente según sus APIs; no tienen el mismo ciclo inactivo del
fuente ABAP. Las pantallas especiales usan la API nativa y su comportamiento
de guardado/generación debe validarse en el release destino.

El alcance tiene límites explícitos: no se reemplazan definiciones distintas
de transacciones existentes ni `ENHS`/`ENHO` existentes; quedan pendientes en
el log. Con sobrescritura habilitada, una transacción cuya definición coincide
puede recibir los textos y autorizaciones del XML. Las variantes referenciadas
por transacciones deben existir en destino; no se exportan sus valores ni
las variantes de pantalla SHD0. Los enhancements cubiertos son los de código
(hooks), no BAdIs, ampliaciones OO, Web Dynpro ni ampliaciones compuestas.
No se incluyen SOTR, historial de traducción SE63 ni documentación de otros
tipos de objeto. Las traducciones de dynpro cubren los textos de campos de
`D021T` y títulos de `D020T`; una estructura de claves no reconocida en el
release se informa como pendiente. No hay rollback
global: un fallo de API puede dejar componentes ya guardados o una definición
parcial. **No equivale a un respaldo exhaustivo de cualquier programa SAP.**

Las pruebas pendientes en SAP y los resultados esperados están en
[Validación de componentes de programas](docs/program-components-validation.md).

Para clases e interfaces se utiliza `seo_payload` con formato interno
`OO_SOURCE_1`: contiene propiedades y fuente completo obtenido mediante
`CL_OO_FACTORY`. Las clases incluyen definiciones e implementaciones locales,
macros, clases de prueba y textpool del idioma de exportación. Los includes
técnicos se determinan en destino mediante las APIs OO, sin reutilizar números
de includes de métodos del sistema origen. Para `CLAS`/`INTF` no se incluyen documentación,
traducciones adicionales, textos SOTR ni objetos de enhancement asociados.

El importador valida la identidad y el formato del payload antes de modificar
el repositorio. Primero crea las definiciones con
`SEO_CLASS_CREATE_COMPLETE` / `SEO_INTERFACE_CREATE_COMPLETE`, versión inactiva;
luego guarda el fuente con `IF_OO_CLIF_SOURCE`, también en versión inactiva.
Se respetan el package, la OT y la opción de sobrescritura. Con `p_activ` vacío
no se solicita activación. Si se marca, se agregan al lote de activación final.
Si la API OO rechaza el guardado por sintaxis, dependencias o incompatibilidad
del release, el objeto queda informado como error, puede quedar una definición
parcial inactiva y se continúa con los demás objetos; no se declara importación
completa de ese objeto. Debe comprobarse en SE24/SE80 y en **Ver log**.

Las clases/interfaces deben volver a exportarse con esta versión: los XML
anteriores con fragmentos `SEOCLASS`/`SEOCOMPO` o estado `ERROR` no contienen el
fuente OO completo y se rechazan antes de crear el objeto. El XML de ejemplo
`OBJECTS_S4D_20260915.xml` no contiene clases ni interfaces y no permite probar
este nuevo circuito.

Los IDocs siguen sin declararse como exportaciones portables: el exportador
los registra con estado `ERROR` en el manifiesto.

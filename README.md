# ABAP_XML_OBJECT_TRANSPORTER

Herramienta SAP GUI para mover objetos ABAP mediante XML.

El formato portable actual es `sap_package_export` versión `1.1`. El
exportador siempre incluye `header/package`, que el importador usa como
package destino por defecto; `p_pack` permite reemplazarlo.

El circuito exportar/importar está soportado para `PROG`, `DOMA`, `DTEL`,
`TABL`, `STRU`, `TTYP`, `SHLP` y `FUGR`. En programas se conservan tanto el
fuente principal como los includes detectados. Para `FUGR`, se exportan el
catálogo de módulos, sus interfaces y los includes; al importar se crea el
grupo, se registra en el package destino y se recrean los módulos con las APIs
de Function Builder. Los tipos de tabla se intercambian con las estructuras
`DD40V`, `DD42V` y `DD43V` requeridas por las APIs DDIC.

Las clases, interfaces e IDocs no se declaran como exportaciones portables: el
exportador los registra con estado `ERROR` en el manifiesto. Sus payloads
actuales son fragmentos técnicos que no permiten recrearlos de forma segura en
otro release SAP.

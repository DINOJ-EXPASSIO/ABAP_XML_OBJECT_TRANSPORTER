# Soporte de objetos

## Regla de soporte

Un tipo se considera soportado solo cuando el exportador lo serializa, el importador lo valida y crea, y existe una prueba SAP de ida y vuelta para el release destino. Un XML puede incluir prerequisitos externos, pero no los declara transportados.

| Tipo | Estado | Alcance actual | Restricciones |
| --- | --- | --- | --- |
| `PROG` | Soportado | Fuente, includes propios y componentes del bundle de programa | No se separan componentes internos del programa padre. |
| `DOMA`, `DTEL`, `TABL`, `STRU`, `TTYP`, `SHLP` | Soportado | Payload DDIC y activacion opcional | Las dependencias externas deben existir o incluirse. |
| `FUGR` | Soportado | Grupo, modulos, interfaces e includes propios | Las APIs Function Builder pueden diferir por release. |
| `CLAS`, `INTF` | Soportado | Definicion y fuente OO inactivo | Validar sintaxis y dependencias en destino. |
| Transacciones de un `PROG` | Parcial | Transacciones propias asociadas al bundle | Una variante de reporte debe existir para el programa destino; variantes SHD0 son prerequisitos manuales. |
| Dynpro, CUA, textos, documentacion, enhancements de codigo | Parcial | Componentes internos de `PROG` | Requieren validacion en SAP por release. |
| `MSAG`, `ENQU` | No soportado | Se declaran como prerequisito externo cuando se detecten | Excluidos por decision funcional actual. |
| IDoc | No soportado | El manifiesto los marca con error | No hay importador portable. |

## Dependencias y nombres destino

- `PROG`, `CLAS`, `INTF` y `FUGR` se inspeccionan recursivamente para localizar
  referencias estáticas a objetos propios presentes en TADIR.
- Cada relación se conserva aunque un mismo objeto dependa de varios padres.
- Las dependencias pueden excluirse del archivo o de la importación si ya
  existen en destino; si no existen, se aplica la política según el tipo padre.
- Una dependencia estructural DDIC faltante bloquea la creación. Para `PROG`,
  `CLAS`, `INTF` y `FUGR`, el importador intenta guardar el objeto inactivo,
  informa `WARNING` y omite su activación automática.
- El mapeo origen-destino está soportado para los tipos importables de la tabla.
  Las referencias DDIC conocidas se cambian en sus estructuras y las referencias
  ABAP se cambian solo como identificadores fuera de comentarios y literales.
- Includes y demás componentes internos siguen perteneciendo al objeto padre y
  no aparecen como objetos de repositorio seleccionables por separado.

## Compatibilidad entre releases

El archivo debe declarar `source_environment` y las capacidades usadas. El importador acepta solo capacidades que conoce; una capacidad desconocida se informa y bloquea el objeto afectado, sin modificarlo.

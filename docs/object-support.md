# Soporte de objetos

## Regla de soporte

Un tipo se considera soportado solo cuando el exportador lo serializa, el importador lo valida y crea, y existe una prueba SAP de ida y vuelta para el release destino. Un XML puede incluir prerequisitos externos, pero no los declara transportados.

| Tipo | Estado | Alcance actual | Restricciones |
| --- | --- | --- | --- |
| `PROG` | Soportado | Fuente, includes propios y componentes del bundle de programa | No se separan componentes internos del programa padre. |
| `DOMA`, `DTEL`, `TABL`, `STRU`, `TTYP`, `SHLP` | Soportado | Payload DDIC y activacion opcional | Las dependencias externas deben existir o incluirse. |
| `FUGR` | Soportado | Grupo, modulos, interfaces e includes propios | Las APIs Function Builder pueden diferir por release. |
| `CLAS`, `INTF` | Soportado | Definicion y fuente OO inactivo | Validar sintaxis y dependencias en destino. |
| Transacciones de un `PROG` | Parcial | Transacciones propias asociadas al bundle | Variantes referenciadas no viajan. |
| Dynpro, CUA, textos, documentacion, enhancements de codigo | Parcial | Componentes internos de `PROG` | Requieren validacion en SAP por release. |
| `MSAG`, `ENQU` | No soportado | Se declaran como prerequisito externo cuando se detecten | Excluidos por decision funcional actual. |
| IDoc | No soportado | El manifiesto los marca con error | No hay importador portable. |

## Compatibilidad entre releases

El archivo debe declarar `source_environment` y las capacidades usadas. El importador acepta solo capacidades que conoce; una capacidad desconocida se informa y bloquea el objeto afectado, sin modificarlo.

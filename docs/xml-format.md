# Contrato XML

## Versiones

- `1.1`: fuentes y payloads historicos compatibles.
- `1.2`: agrega `original_system` y `program_payload`.
- `1.3`: agrega relaciones, capacidades y mapeos de destino opcionales.

El exportador genera la version mas reciente. El importador conserva lectura de versiones anteriores cuando no contienen capacidades que requieran interpretacion nueva.

## Identidad y relaciones

Cada `object` conserva el atributo `type` y `name` de origen. La version 1.3 agrega nodos opcionales:

```xml
<source_identity type="PROG" name="ZDEMO" />
<relationship kind="ROOT" />
<relationship kind="DEPENDENCY" parent_type="PROG" parent_name="ZDEMO" reason="STATIC_REFERENCE" />
<target_mapping type="PROG" source_name="ZDEMO" target_name="ZDEMO_DEST" />
```

`target_mapping` no altera el payload de origen. Solo el importador lo aplica mediante adaptadores que conocen la referencia. Los componentes de programa usan `COMPONENT` y conservan el nombre derivado de su padre.

## Reglas de seguridad

- Nunca se hace reemplazo textual global de nombres.
- El importador valida colisiones, namespace, longitud y objeto SAP antes de escribir.
- Una referencia dinamica o desconocida bloquea el mapeo solicitado para ese objeto.
- Los prerequisitos no exportables se registran como relaciones externas y no se cuentan como exito.

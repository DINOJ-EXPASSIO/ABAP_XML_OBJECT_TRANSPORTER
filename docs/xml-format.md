# Contrato XML

## Versiones

- `1.1`: fuentes y payloads historicos compatibles.
- `1.2`: agrega `original_system` y `program_payload`.
- `1.3`: agrega relaciones, capacidades y mapeos de destino opcionales.

El exportador genera la version mas reciente. El importador conserva lectura de versiones anteriores cuando no contienen capacidades que requieran interpretacion nueva.

## Identidad y relaciones

Cada `object` conserva los atributos `type` y `name` de origen. La version 1.3 agrega nodos opcionales:

```xml
<source_object_type>PROG</source_object_type>
<source_object_name>ZDEMO</source_object_name>
<target_object_name>ZDEMO_DEST</target_object_name>
<relationship>ROOT</relationship>
<parent_type></parent_type>
<parent_name></parent_name>
<relation_reason>USER_SELECTION</relation_reason>
<dependencies>
  <dependency type="DTEL" name="ZDEMO_ELEMENT"
              included="X" source="TADIR" />
</dependencies>
```

`target_object_name` no altera el payload de origen. El importador valida la
identidad original y aplica el destino durante cada adaptador. La lista
`dependencies` conserva todas las aristas del grafo, incluso cuando un objeto
ya habia sido descubierto por otro padre. `included` indica si el objeto fue
seleccionado para ese archivo; un valor vacio significa que debe existir en el
destino para poder importar el padre.

## Reglas de seguridad

- En estructuras DDIC se cambian solo campos conocidos. En fuente ABAP se
  reemplazan identificadores completos fuera de comentarios y literales.
- El importador valida colisiones, namespace, longitud y objeto SAP antes de escribir.
- Una referencia dinamica o desconocida bloquea el mapeo solicitado para ese objeto.
- Los prerequisitos no exportables se registran como relaciones externas y no se cuentan como exito.

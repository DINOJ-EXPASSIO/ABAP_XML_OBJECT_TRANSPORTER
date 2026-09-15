*&---------------------------------------------------------------------*
*& Reporte - ZJDR_XML_OBJECTS_IMPORT
*&---------------------------------------------------------------------*
*& Proyecto...: Importador XML de objetos ABAP
*& Autor......: <Nombre Apellido> (<Usuario SAP>)
*& Fecha......: <DD/Mes/YYYY>
*& Código Des.: BC0001
*& REQ........: <REQ>
*& Descripción: Importa objetos ABAP desde XML generado por
*&              ZJDR_XML_OBJECTS_EXPORT.
*&---------------------------------------------------------------------*
*& Historial de modificaciones
*&---------------------------------------------------------------------*
*& Descripción....: Versión ALV Grid + registro package para PROG
*& Requerimiento..: <REQ>
*& Autor..........: <Nombre Apellido> (<Usuario SAP>)
*& Fecha..........: <DD/Mes/YYYY>
*& Referencia.....: 0001
*& Request........: <DESKXXXXXX>
*&---------------------------------------------------------------------*

REPORT zjdr_xml_objects_import
  NO STANDARD PAGE HEADING
  LINE-SIZE 255.

*&---------------------------------------------------------------------*
*& INCLUDES
*&---------------------------------------------------------------------*
INCLUDE <icon>.

*&---------------------------------------------------------------------*
*& TABLES
*&---------------------------------------------------------------------*
TABLES: tadir.

*&---------------------------------------------------------------------*
*& CONSTANTS
*&---------------------------------------------------------------------*
CONSTANTS:
  cg_xml_version  TYPE string VALUE '1.1',
  cg_root_node    TYPE string VALUE 'sap_package_export',
  cg_status_ok    TYPE string VALUE 'SUCCESS',
  cg_status_warn  TYPE string VALUE 'WARNING',
  cg_status_err   TYPE string VALUE 'ERROR',
  cg_status_skip  TYPE string VALUE 'SKIPPED',
  cg_status_ready TYPE string VALUE 'READY'.

CONSTANTS:
  cg_icon_green  TYPE icon_d VALUE icon_led_green,
  cg_icon_yellow TYPE icon_d VALUE icon_led_yellow,
  cg_icon_red    TYPE icon_d VALUE icon_led_red,
  cg_icon_gray   TYPE icon_d VALUE icon_led_inactive.

CONSTANTS:
  cg_button_import TYPE syucomm VALUE 'ZIMP_XML'.

*&---------------------------------------------------------------------*
*& TYPES
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_xml_header,
         package                TYPE devclass,
         object_count           TYPE i,
         count_prog             TYPE i,
         count_tabl             TYPE i,
         count_stru             TYPE i,
         count_ttyp             TYPE i,
         count_doma             TYPE i,
         count_dtel             TYPE i,
         count_shlp             TYPE i,
         count_clas             TYPE i,
         count_intf             TYPE i,
         count_fugr             TYPE i,
         export_user            TYPE syuname,
         export_date            TYPE sy-datum,
         export_time            TYPE sy-uzeit,
         source_system_id       TYPE sy-sysid,
         source_client          TYPE sy-mandt,
         source_environment     TYPE string,
         export_program         TYPE sy-repid,
         export_program_version TYPE string,
       END OF ty_xml_header.

TYPES: BEGIN OF ty_import_object,
         selected        TYPE abap_bool,
         light           TYPE icon_d,
         object_type     TYPE string,
         object_name     TYPE tadir-obj_name,
         short_text      TYPE string,
         original_lang   TYPE sylangu,
         last_change     TYPE sy-datum,
         export_status   TYPE string,
         exists_dest     TYPE abap_bool,
         action          TYPE string,
         import_status   TYPE string,
         import_message  TYPE string,
         import_priority TYPE i,
         activated       TYPE abap_bool,
       END OF ty_import_object.

TYPES: tyt_import_object TYPE STANDARD TABLE OF ty_import_object WITH EMPTY KEY.

TYPES: BEGIN OF ty_object_payload,
         object_type TYPE string,
         object_name TYPE tadir-obj_name,
         payload_tag TYPE string,
         encoding    TYPE string,
         transform   TYPE string,
         content     TYPE string,
       END OF ty_object_payload.

TYPES: tyt_object_payload TYPE STANDARD TABLE OF ty_object_payload WITH EMPTY KEY.

TYPES: BEGIN OF ty_source_line,
         object_type TYPE string,
         object_name TYPE tadir-obj_name,
         include     TYPE progname,
         line_number TYPE i,
         source_line TYPE string,
       END OF ty_source_line.

TYPES: tyt_source_line TYPE STANDARD TABLE OF ty_source_line WITH EMPTY KEY.

TYPES: BEGIN OF ty_import_log,
         object_type TYPE string,
         object_name TYPE tadir-obj_name,
         step        TYPE string,
         status      TYPE string,
         message     TYPE string,
       END OF ty_import_log.

TYPES: tyt_import_log TYPE STANDARD TABLE OF ty_import_log WITH EMPTY KEY.

TYPES: ty_report_line TYPE c LENGTH 255.
TYPES: tyt_report_line TYPE STANDARD TABLE OF ty_report_line WITH EMPTY KEY.

*&---------------------------------------------------------------------*
*& DATA
*&---------------------------------------------------------------------*
DATA:
  wag_header    TYPE ty_xml_header,
  tg_objects    TYPE tyt_import_object,
  tg_payloads   TYPE tyt_object_payload,
  tg_source     TYPE tyt_source_line,
  tg_log        TYPE tyt_import_log,
  vg_xml_string TYPE string,
  vg_package    TYPE devclass.

DATA:
  go_container TYPE REF TO cl_gui_docking_container,
  go_grid      TYPE REF TO cl_gui_alv_grid.

DATA:
  gv_okcode          TYPE syucomm,
  gv_import_executed TYPE abap_bool.

*&---------------------------------------------------------------------*
*& LOCAL CLASS
*&---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
      handle_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handle_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,

      handle_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id.
ENDCLASS. " lcl_event_handler

CLASS lcl_event_handler IMPLEMENTATION.

  METHOD handle_toolbar.

    DATA wal_toolbar TYPE stb_button.

    CLEAR wal_toolbar.
    wal_toolbar-butn_type = 3.
    APPEND wal_toolbar TO e_object->mt_toolbar.

    CLEAR wal_toolbar.
    wal_toolbar-function  = cg_button_import.
    wal_toolbar-icon      = icon_import.
    wal_toolbar-quickinfo = 'Importar objetos seleccionados'.
    wal_toolbar-text      = 'Importar'.
    wal_toolbar-butn_type = 0.
    APPEND wal_toolbar TO e_object->mt_toolbar.

  ENDMETHOD. " handle_toolbar

  METHOD handle_user_command.

    CASE e_ucomm.

      WHEN cg_button_import.
        PERFORM f_import_selected_objects.

    ENDCASE.

  ENDMETHOD. " handle_user_command

  METHOD handle_hotspot_click.

    READ TABLE tg_objects INTO DATA(wal_object) INDEX e_row_id-index.

    IF sy-subrc NE 0.
      RETURN.
    ENDIF.

    IF e_column_id-fieldname NE 'OBJECT_NAME'.
      RETURN.
    ENDIF.

    PERFORM f_navigate_to_object
      USING wal_object-object_type
            wal_object-object_name.

  ENDMETHOD. " handle_hotspot_click

ENDCLASS. " lcl_event_handler

DATA go_event_handler TYPE REF TO lcl_event_handler.

*&---------------------------------------------------------------------*
*& SELECTION-SCREEN
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_file TYPE localfile OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_test  AS CHECKBOX DEFAULT abap_true,
              p_overw AS CHECKBOX DEFAULT abap_false,
              p_activ AS CHECKBOX DEFAULT abap_false,
              p_pack  TYPE devclass,
              p_req   TYPE trkorr.
SELECTION-SCREEN END OF BLOCK b02.

*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN ON VALUE-REQUEST
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM f_get_file_path.

*&---------------------------------------------------------------------*
*& START-OF-SELECTION
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  CLEAR gv_import_executed.

  PERFORM f_upload_xml.
  PERFORM f_parse_xml.
  PERFORM f_validate_xml.
  PERFORM f_validate_package.
  PERFORM f_prepare_import_plan.

  IF tg_objects IS INITIAL.
    MESSAGE 'No se encontraron objetos importables en el XML.' TYPE 'I'.
    RETURN.
  ENDIF.

  CALL SCREEN 0100.

  IF p_test EQ abap_true.
    MESSAGE 'Simulación finalizada. No se modificaron objetos.' TYPE 'S'.
    RETURN.
  ENDIF.

  IF gv_import_executed IS INITIAL.
    MESSAGE 'No se ejecutó importación.' TYPE 'S' DISPLAY LIKE 'W'.
  ENDIF.

*&---------------------------------------------------------------------*
*& MODULES
*&---------------------------------------------------------------------*
MODULE mb_status_0100 OUTPUT.
ENDMODULE. " mb_status_0100

MODULE mb_create_alv OUTPUT.

  IF go_grid IS BOUND.
    RETURN.
  ENDIF.

  CREATE OBJECT go_container
    EXPORTING
      side      = cl_gui_docking_container=>dock_at_left
      extension = 9999.

  CREATE OBJECT go_grid
    EXPORTING
      i_parent = go_container.

  CREATE OBJECT go_event_handler.

  SET HANDLER go_event_handler->handle_toolbar       FOR go_grid.
  SET HANDLER go_event_handler->handle_user_command  FOR go_grid.
  SET HANDLER go_event_handler->handle_hotspot_click FOR go_grid.

  PERFORM f_display_alv.

ENDMODULE. " mb_create_alv

MODULE ma_user_command_0100 INPUT.

  gv_okcode = sy-ucomm.

  CASE gv_okcode.
    WHEN 'BACK'.
      BACK.
    WHEN 'EXIT' OR 'CANC'.
      LEAVE PROGRAM.
  ENDCASE.

ENDMODULE. " ma_user_command_0100

*&---------------------------------------------------------------------*
*& FORMS
*&---------------------------------------------------------------------*

FORM f_get_file_path.

  DATA: tl_filetable TYPE filetable,
        vl_rc        TYPE i,
        wal_file     TYPE file_table.

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      file_filter = 'XML Files (*.xml)|*.xml|'
    CHANGING
      file_table  = tl_filetable
      rc          = vl_rc
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc NE 0 OR vl_rc IS INITIAL.
    RETURN.
  ENDIF.

  READ TABLE tl_filetable INTO wal_file INDEX 1.
  IF sy-subrc EQ 0.
    p_file = wal_file-filename.
  ENDIF.

ENDFORM. " f_get_file_path

*&---------------------------------------------------------------------*
*& FORM f_upload_xml
*&---------------------------------------------------------------------*
* [Título: Lee el XML local como texto]
*&---------------------------------------------------------------------*
FORM f_upload_xml.

  DATA: tl_file_lines TYPE STANDARD TABLE OF string,
        vl_line       TYPE string.

  CLEAR vg_xml_string.

  CALL METHOD cl_gui_frontend_services=>gui_upload
    EXPORTING
      filename                = CONV string( p_file )
      filetype                = 'ASC'
    CHANGING
      data_tab                = tl_file_lines
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      OTHERS                  = 17.

  IF sy-subrc NE 0.
    MESSAGE 'No se pudo leer el archivo XML seleccionado.' TYPE 'E'.
  ENDIF.

  LOOP AT tl_file_lines INTO vl_line.
    CONCATENATE vg_xml_string vl_line cl_abap_char_utilities=>newline
      INTO vg_xml_string.
  ENDLOOP.

  IF vg_xml_string IS INITIAL.
    MESSAGE 'El archivo XML está vacío.' TYPE 'E'.
  ENDIF.

ENDFORM. " f_upload_xml

*&---------------------------------------------------------------------*
*& FORM f_parse_xml
*&---------------------------------------------------------------------*
* [Título: Parsea el XML y carga cabecera, objetos, payloads y fuentes]
*&---------------------------------------------------------------------*
FORM f_parse_xml.

  DATA: lo_ixml           TYPE REF TO if_ixml,
        lo_document       TYPE REF TO if_ixml_document,
        lo_stream_factory TYPE REF TO if_ixml_stream_factory,
        lo_istream        TYPE REF TO if_ixml_istream,
        lo_parser         TYPE REF TO if_ixml_parser,
        lo_root           TYPE REF TO if_ixml_element,
        lo_root_node      TYPE REF TO if_ixml_node,
        lo_child          TYPE REF TO if_ixml_node,
        vl_rc             TYPE i,
        vl_root_name      TYPE string,
        vl_version        TYPE string.

  CLEAR: wag_header, tg_objects, tg_payloads, tg_source, tg_log.

  lo_ixml           = cl_ixml=>create( ).
  lo_document       = lo_ixml->create_document( ).
  lo_stream_factory = lo_ixml->create_stream_factory( ).
  lo_istream        = lo_stream_factory->create_istream_string( string = vg_xml_string ).

  lo_parser = lo_ixml->create_parser(
                stream_factory = lo_stream_factory
                istream        = lo_istream
                document       = lo_document ).

  vl_rc = lo_parser->parse( ).

  IF vl_rc NE 0.
    MESSAGE 'El XML no está bien formado o no pudo parsearse.' TYPE 'E'.
  ENDIF.

  lo_root = lo_document->get_root_element( ).

  IF lo_root IS INITIAL.
    MESSAGE 'El XML no tiene nodo raíz.' TYPE 'E'.
  ENDIF.

  lo_root_node ?= lo_root.
  vl_root_name = lo_root->get_name( ).

  IF vl_root_name NE cg_root_node.
    MESSAGE 'Nodo raíz inválido. Se esperaba sap_package_export.' TYPE 'E'.
  ENDIF.

  PERFORM f_get_attribute_value
    USING lo_root_node 'version'
    CHANGING vl_version.

  IF vl_version NE cg_xml_version.
    MESSAGE 'Versión XML no soportada.' TYPE 'E'.
  ENDIF.

  lo_child = lo_root->get_first_child( ).

  WHILE lo_child IS BOUND.

    CASE lo_child->get_name( ).
      WHEN 'header'.
        PERFORM f_parse_header USING lo_child.
      WHEN 'objects'.
        PERFORM f_parse_objects USING lo_child.
    ENDCASE.

    lo_child = lo_child->get_next( ).

  ENDWHILE.

ENDFORM. " f_parse_xml

*&---------------------------------------------------------------------*
*& FORM f_parse_header
*&---------------------------------------------------------------------*
* [Título: Lee la cabecera del XML]
*&---------------------------------------------------------------------*
* -> io_header_node " Nodo header del XML
*&---------------------------------------------------------------------*
FORM f_parse_header
  USING io_header_node TYPE REF TO if_ixml_node.

  DATA: vl_value TYPE string.

  PERFORM f_get_child_value USING io_header_node 'package' CHANGING vl_value.
  wag_header-package = vl_value.

  PERFORM f_get_child_value USING io_header_node 'object_count' CHANGING vl_value.
  wag_header-object_count = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_prog' CHANGING vl_value.
  wag_header-count_prog = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_tabl' CHANGING vl_value.
  wag_header-count_tabl = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_stru' CHANGING vl_value.
  wag_header-count_stru = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_ttyp' CHANGING vl_value.
  wag_header-count_ttyp = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_doma' CHANGING vl_value.
  wag_header-count_doma = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_dtel' CHANGING vl_value.
  wag_header-count_dtel = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_shlp' CHANGING vl_value.
  wag_header-count_shlp = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_clas' CHANGING vl_value.
  wag_header-count_clas = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_intf' CHANGING vl_value.
  wag_header-count_intf = vl_value.

  PERFORM f_get_child_value USING io_header_node 'count_fugr' CHANGING vl_value.
  wag_header-count_fugr = vl_value.

  PERFORM f_get_child_value USING io_header_node 'export_user' CHANGING vl_value.
  wag_header-export_user = vl_value.

  PERFORM f_get_child_value USING io_header_node 'export_date' CHANGING vl_value.
  wag_header-export_date = vl_value.

  PERFORM f_get_child_value USING io_header_node 'export_time' CHANGING vl_value.
  wag_header-export_time = vl_value.

  PERFORM f_get_child_value USING io_header_node 'source_system_id' CHANGING vl_value.
  wag_header-source_system_id = vl_value.

  PERFORM f_get_child_value USING io_header_node 'source_client' CHANGING vl_value.
  wag_header-source_client = vl_value.

  PERFORM f_get_child_value USING io_header_node 'source_environment' CHANGING vl_value.
  wag_header-source_environment = vl_value.

  PERFORM f_get_child_value USING io_header_node 'export_program' CHANGING vl_value.
  wag_header-export_program = vl_value.

  PERFORM f_get_child_value USING io_header_node 'export_program_version' CHANGING vl_value.
  wag_header-export_program_version = vl_value.

ENDFORM. " f_parse_header

*&---------------------------------------------------------------------*
*& FORM f_parse_objects
*&---------------------------------------------------------------------*
* [Título: Lee los objetos del XML]
*&---------------------------------------------------------------------*
* -> io_objects_node " Nodo objects del XML
*&---------------------------------------------------------------------*
FORM f_parse_objects
  USING io_objects_node TYPE REF TO if_ixml_node.

  DATA: lo_object TYPE REF TO if_ixml_node.

  lo_object = io_objects_node->get_first_child( ).

  WHILE lo_object IS BOUND.

    IF lo_object->get_name( ) EQ 'object'.
      PERFORM f_parse_object USING lo_object.
    ENDIF.

    lo_object = lo_object->get_next( ).

  ENDWHILE.

ENDFORM. " f_parse_objects

*&---------------------------------------------------------------------*
*& FORM f_parse_object
*&---------------------------------------------------------------------*
* [Título: Lee un objeto individual del XML]
*&---------------------------------------------------------------------*
* -> io_object_node " Nodo object del XML
*&---------------------------------------------------------------------*
FORM f_parse_object
  USING io_object_node TYPE REF TO if_ixml_node.

  DATA: wal_object TYPE ty_import_object,
        vl_value   TYPE string.

  CLEAR wal_object.

  PERFORM f_get_attribute_value USING io_object_node 'type'
    CHANGING wal_object-object_type.

  PERFORM f_get_attribute_value USING io_object_node 'name'
    CHANGING vl_value.
  wal_object-object_name = vl_value.

  PERFORM f_get_child_value USING io_object_node 'short_text'
    CHANGING wal_object-short_text.

  PERFORM f_get_child_value USING io_object_node 'original_language'
    CHANGING vl_value.
  wal_object-original_lang = vl_value.

  PERFORM f_get_child_value USING io_object_node 'last_change'
    CHANGING vl_value.
  wal_object-last_change = vl_value.

  PERFORM f_get_child_value USING io_object_node 'export_status'
    CHANGING wal_object-export_status.

  wal_object-selected      = abap_false.
  wal_object-light         = cg_icon_gray.
  wal_object-import_status = 'PENDING'.
  wal_object-import_message = 'Objeto leído. Pendiente de validación.'.

  PERFORM f_set_import_priority
    CHANGING wal_object.

  APPEND wal_object TO tg_objects.

  PERFORM f_collect_payloads USING io_object_node wal_object.
  PERFORM f_collect_source USING io_object_node wal_object.

ENDFORM. " f_parse_object

*&---------------------------------------------------------------------*
*& FORM f_collect_payloads
*&---------------------------------------------------------------------*
* [Título: Extrae payloads técnicos del objeto XML]
*&---------------------------------------------------------------------*
* -> io_object_node " Nodo object del XML
* -> is_object      " Objeto leído
*&---------------------------------------------------------------------*
FORM f_collect_payloads
  USING io_object_node TYPE REF TO if_ixml_node
        is_object      TYPE ty_import_object.

  DATA: lo_child    TYPE REF TO if_ixml_node,
        wal_payload TYPE ty_object_payload.

  lo_child = io_object_node->get_first_child( ).

  WHILE lo_child IS BOUND.

    IF lo_child->get_name( ) EQ 'ddic_payload'
    OR lo_child->get_name( ) EQ 'seo_payload'
    OR lo_child->get_name( ) EQ 'function_group_payload'.

      CLEAR wal_payload.

      wal_payload-object_type = is_object-object_type.
      wal_payload-object_name = is_object-object_name.
      wal_payload-payload_tag = lo_child->get_name( ).

      PERFORM f_get_attribute_value USING lo_child 'encoding'
        CHANGING wal_payload-encoding.

      PERFORM f_get_attribute_value USING lo_child 'transformation'
        CHANGING wal_payload-transform.

      PERFORM f_get_node_text USING lo_child
        CHANGING wal_payload-content.

      CONDENSE wal_payload-content NO-GAPS.

      APPEND wal_payload TO tg_payloads.

    ENDIF.

    lo_child = lo_child->get_next( ).

  ENDWHILE.

ENDFORM. " f_collect_payloads

*&---------------------------------------------------------------------*
*& FORM f_collect_source
*&---------------------------------------------------------------------*
* [Título: Extrae código fuente directo e includes del XML]
*&---------------------------------------------------------------------*
* -> io_object_node " Nodo object del XML
* -> is_object      " Objeto leído
*&---------------------------------------------------------------------*
FORM f_collect_source
  USING io_object_node TYPE REF TO if_ixml_node
        is_object      TYPE ty_import_object.

  DATA: lo_child TYPE REF TO if_ixml_node.

  lo_child = io_object_node->get_first_child( ).

  WHILE lo_child IS BOUND.

    CASE lo_child->get_name( ).
      WHEN 'source_code'.
        PERFORM f_collect_source_code
          USING lo_child is_object is_object-object_name.

      WHEN 'source_includes'.
        PERFORM f_collect_source_includes
          USING lo_child is_object.
    ENDCASE.

    lo_child = lo_child->get_next( ).

  ENDWHILE.

ENDFORM. " f_collect_source

*&---------------------------------------------------------------------*
*& FORM f_collect_source_includes
*&---------------------------------------------------------------------*
* [Título: Extrae includes de código fuente]
*&---------------------------------------------------------------------*
* -> io_source_includes " Nodo source_includes
* -> is_object          " Objeto leído
*&---------------------------------------------------------------------*
FORM f_collect_source_includes
  USING io_source_includes TYPE REF TO if_ixml_node
        is_object          TYPE ty_import_object.

  DATA: lo_include TYPE REF TO if_ixml_node,
        lo_child   TYPE REF TO if_ixml_node,
        vl_include TYPE progname.

  lo_include = io_source_includes->get_first_child( ).

  WHILE lo_include IS BOUND.

    IF lo_include->get_name( ) EQ 'include'.

      CLEAR vl_include.

      PERFORM f_get_attribute_value USING lo_include 'name'
        CHANGING vl_include.

      lo_child = lo_include->get_first_child( ).

      WHILE lo_child IS BOUND.

        IF lo_child->get_name( ) EQ 'source_code'.
          PERFORM f_collect_source_code
            USING lo_child is_object vl_include.
        ENDIF.

        lo_child = lo_child->get_next( ).

      ENDWHILE.

    ENDIF.

    lo_include = lo_include->get_next( ).

  ENDWHILE.

ENDFORM. " f_collect_source_includes

*&---------------------------------------------------------------------*
*& FORM f_collect_source_code
*&---------------------------------------------------------------------*
* [Título: Extrae líneas de código fuente]
*&---------------------------------------------------------------------*
* -> io_source_code " Nodo source_code
* -> is_object      " Objeto leído
* -> iv_include     " Include o programa destino
*&---------------------------------------------------------------------*
FORM f_collect_source_code
  USING io_source_code TYPE REF TO if_ixml_node
        is_object      TYPE ty_import_object
        iv_include     TYPE progname.

  DATA: lo_line       TYPE REF TO if_ixml_node,
        wal_source    TYPE ty_source_line,
        vl_line_no    TYPE string,
        vl_source_txt TYPE string.

  lo_line = io_source_code->get_first_child( ).

  WHILE lo_line IS BOUND.

    IF lo_line->get_name( ) EQ 'line'.

      CLEAR: wal_source, vl_line_no, vl_source_txt.

      PERFORM f_get_attribute_value USING lo_line 'number'
        CHANGING vl_line_no.

      PERFORM f_get_node_text USING lo_line
        CHANGING vl_source_txt.

      wal_source-object_type = is_object-object_type.
      wal_source-object_name = is_object-object_name.
      wal_source-include     = iv_include.
      wal_source-line_number = vl_line_no.
      wal_source-source_line = vl_source_txt.

      APPEND wal_source TO tg_source.

    ENDIF.

    lo_line = lo_line->get_next( ).

  ENDWHILE.

ENDFORM. " f_collect_source_code

*&---------------------------------------------------------------------*
*& FORM f_get_child_value
*&---------------------------------------------------------------------*
* [Título: Obtiene el texto de un nodo hijo por nombre]
*&---------------------------------------------------------------------*
* -> io_parent " Nodo padre
* -> iv_name   " Nombre del nodo hijo
* <- cv_value  " Valor leído
*&---------------------------------------------------------------------*
FORM f_get_child_value
  USING io_parent TYPE REF TO if_ixml_node
        iv_name   TYPE string
  CHANGING cv_value TYPE any.

  DATA: lo_child TYPE REF TO if_ixml_node,
        vl_value TYPE string.

  CLEAR: cv_value, vl_value.

  lo_child = io_parent->get_first_child( ).

  WHILE lo_child IS BOUND.

    IF lo_child->get_name( ) EQ iv_name.
      PERFORM f_get_node_text USING lo_child CHANGING vl_value.
      cv_value = vl_value.
      RETURN.
    ENDIF.

    lo_child = lo_child->get_next( ).

  ENDWHILE.

ENDFORM. " f_get_child_value

*&---------------------------------------------------------------------*
*& FORM f_get_node_text
*&---------------------------------------------------------------------*
* [Título: Obtiene el texto contenido dentro de un nodo XML]
*&---------------------------------------------------------------------*
* -> io_node  " Nodo XML
* <- cv_value " Texto del nodo
*&---------------------------------------------------------------------*
FORM f_get_node_text
  USING io_node TYPE REF TO if_ixml_node
  CHANGING cv_value TYPE string.

  DATA: lo_child TYPE REF TO if_ixml_node,
        vl_text  TYPE string.

  CLEAR cv_value.

  lo_child = io_node->get_first_child( ).

  WHILE lo_child IS BOUND.

    vl_text = lo_child->get_value( ).

    IF vl_text IS NOT INITIAL.
      CONCATENATE cv_value vl_text INTO cv_value.
    ENDIF.

    lo_child = lo_child->get_next( ).

  ENDWHILE.

  IF cv_value IS INITIAL.
    cv_value = io_node->get_value( ).
  ENDIF.

ENDFORM. " f_get_node_text

*&---------------------------------------------------------------------*
*& FORM f_get_attribute_value
*&---------------------------------------------------------------------*
* [Título: Obtiene el valor de un atributo XML]
*&---------------------------------------------------------------------*
* -> io_node  " Nodo XML
* -> iv_name  " Nombre del atributo
* <- cv_value " Valor del atributo
*&---------------------------------------------------------------------*
FORM f_get_attribute_value
  USING io_node TYPE REF TO if_ixml_node
        iv_name TYPE string
  CHANGING cv_value TYPE any.

  DATA: lo_attrs TYPE REF TO if_ixml_named_node_map,
        lo_attr  TYPE REF TO if_ixml_node,
        vl_value TYPE string.

  CLEAR cv_value.

  lo_attrs = io_node->get_attributes( ).

  IF lo_attrs IS INITIAL.
    RETURN.
  ENDIF.

  lo_attr = lo_attrs->get_named_item( iv_name ).

  IF lo_attr IS INITIAL.
    RETURN.
  ENDIF.

  vl_value = lo_attr->get_value( ).
  cv_value = vl_value.

ENDFORM. " f_get_attribute_value

*&---------------------------------------------------------------------*
*& FORM f_validate_xml
*&---------------------------------------------------------------------*
* [Título: Valida cabecera y cantidad de objetos]
*&---------------------------------------------------------------------*
FORM f_validate_xml.

  DATA: vl_count TYPE i.

  IF wag_header-package IS INITIAL.
    MESSAGE 'El XML no contiene package en la cabecera.' TYPE 'E'.
  ENDIF.

  DESCRIBE TABLE tg_objects LINES vl_count.

  IF wag_header-object_count NE vl_count.
    MESSAGE 'La cantidad de objetos no coincide con object_count.' TYPE 'E'.
  ENDIF.

ENDFORM. " f_validate_xml

*&---------------------------------------------------------------------*
*& FORM f_validate_package
*&---------------------------------------------------------------------*
* [Título: Valida el package destino]
*&---------------------------------------------------------------------*
FORM f_validate_package.

  DATA: vl_devclass TYPE tdevc-devclass.

  IF p_pack IS NOT INITIAL.
    vg_package = p_pack.
  ELSE.
    vg_package = wag_header-package.
  ENDIF.

  IF vg_package IS INITIAL.
    MESSAGE 'No se pudo determinar el package destino.' TYPE 'E'.
  ENDIF.

  IF vg_package EQ '$TMP'.
    RETURN.
  ENDIF.

  SELECT SINGLE devclass
    FROM tdevc
    INTO vl_devclass
    WHERE devclass EQ vg_package.

  IF sy-subrc NE 0.
    MESSAGE 'El package destino no existe.' TYPE 'E'.
  ENDIF.

  IF p_req IS INITIAL.
    MESSAGE 'Para package no local debe informar una orden de transporte.' TYPE 'E'.
  ENDIF.

ENDFORM. " f_validate_package

*&---------------------------------------------------------------------*
*& FORM f_prepare_import_plan
*&---------------------------------------------------------------------*
* [Título: Valida existencia destino y define acción propuesta]
*&---------------------------------------------------------------------*
FORM f_prepare_import_plan.

  FIELD-SYMBOLS: <fsl_object> TYPE ty_import_object.

  LOOP AT tg_objects ASSIGNING <fsl_object>.

    PERFORM f_check_object_exists
      CHANGING <fsl_object>.

    PERFORM f_validate_object_complete
      CHANGING <fsl_object>.

    IF <fsl_object>-import_status EQ cg_status_err.
      CONTINUE.
    ENDIF.

    IF <fsl_object>-export_status NE cg_status_ok.
      <fsl_object>-light          = cg_icon_red.
      <fsl_object>-action         = 'Omitir'.
      <fsl_object>-import_status  = cg_status_err.
      <fsl_object>-import_message = 'Lectura de objeto en XML incompleta o export_status distinto de SUCCESS.'.
      CONTINUE.
    ENDIF.

    IF <fsl_object>-exists_dest EQ abap_true AND p_overw IS INITIAL.
      <fsl_object>-light          = cg_icon_yellow.
      <fsl_object>-action         = 'Omitir'.
      <fsl_object>-import_status  = cg_status_warn.
      <fsl_object>-import_message = 'El objeto existe en destino y no se permite sobrescribir.'.
      CONTINUE.
    ENDIF.

    IF <fsl_object>-exists_dest EQ abap_true.
      <fsl_object>-action = 'Actualizar'.
    ELSE.
      <fsl_object>-action = 'Crear'.
    ENDIF.

    <fsl_object>-light          = cg_icon_gray.
    <fsl_object>-import_status  = cg_status_ready.
    <fsl_object>-import_message = 'Objeto listo para importar. Seleccione la fila y presione Importar.'.

  ENDLOOP.

  SORT tg_objects BY import_priority object_type object_name.

ENDFORM. " f_prepare_import_plan

*&---------------------------------------------------------------------*
*& FORM f_validate_object_complete
*&---------------------------------------------------------------------*
* [Título: Valida que el objeto tenga información mínima importable]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto de importación
*&---------------------------------------------------------------------*
FORM f_validate_object_complete
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_payload TYPE string,
        vl_has_source TYPE abap_bool.

  CLEAR: vl_payload, vl_has_source.

  IF cs_object-object_type IS INITIAL OR cs_object-object_name IS INITIAL.
    cs_object-light          = cg_icon_red.
    cs_object-action         = 'Omitir'.
    cs_object-import_status  = cg_status_err.
    cs_object-import_message = 'Lectura de objeto en XML incompleta: falta tipo o nombre.'.
    RETURN.
  ENDIF.

  CASE cs_object-object_type.
    WHEN 'DOMA' OR 'DTEL' OR 'TABL' OR 'STRU' OR 'TTYP' OR 'SHLP'.
      PERFORM f_get_payload USING cs_object 'ddic_payload'
        CHANGING vl_payload.

      IF vl_payload IS INITIAL.
        cs_object-light          = cg_icon_red.
        cs_object-action         = 'Omitir'.
        cs_object-import_status  = cg_status_err.
        cs_object-import_message = 'Lectura de objeto en XML incompleta: falta ddic_payload.'.
      ENDIF.

    WHEN 'PROG'.
      PERFORM f_has_source_code USING cs_object
        CHANGING vl_has_source.

      IF vl_has_source IS INITIAL.
        cs_object-light          = cg_icon_red.
        cs_object-action         = 'Omitir'.
        cs_object-import_status  = cg_status_err.
        cs_object-import_message = 'Lectura de objeto en XML incompleta: falta source_code.'.
      ENDIF.

    WHEN 'CLAS' OR 'INTF'.
      PERFORM f_get_payload USING cs_object 'seo_payload'
        CHANGING vl_payload.

      IF vl_payload IS INITIAL.
        cs_object-light          = cg_icon_red.
        cs_object-action         = 'Omitir'.
        cs_object-import_status  = cg_status_err.
        cs_object-import_message = 'Lectura de objeto en XML incompleta: falta seo_payload.'.
      ENDIF.

    WHEN 'FUGR'.
      PERFORM f_get_payload USING cs_object 'function_group_payload'
        CHANGING vl_payload.

      IF vl_payload IS INITIAL.
        cs_object-light          = cg_icon_red.
        cs_object-action         = 'Omitir'.
        cs_object-import_status  = cg_status_err.
        cs_object-import_message = 'Lectura de objeto en XML incompleta: falta function_group_payload.'.
      ENDIF.

    WHEN 'IDSG' OR 'IDBT' OR 'IDEX' OR 'IDMS' OR 'IDAS'.
      "IDoc payloads are nested below idoc_definition. They are parsed
      "separately by the IDoc importer and therefore do not use one payload.
      cs_object-light          = cg_icon_red.
      cs_object-action         = 'Omitir'.
      cs_object-import_status  = cg_status_err.
      cs_object-import_message = 'La importación de definiciones IDoc requiere la API IDoc del release destino.' .

    WHEN OTHERS.
      cs_object-light          = cg_icon_red.
      cs_object-action         = 'Omitir'.
      cs_object-import_status  = cg_status_err.
      cs_object-import_message = 'Tipo de objeto no soportado por el importador.'.
  ENDCASE.

ENDFORM. " f_validate_object_complete

*&---------------------------------------------------------------------*
*& FORM f_has_source_code
*&---------------------------------------------------------------------*
* [Título: Valida si existe código fuente para un objeto]
*&---------------------------------------------------------------------*
* -> is_object     " Objeto de importación
* <- cv_has_source " Indicador de código existente
*&---------------------------------------------------------------------*
FORM f_has_source_code
  USING is_object TYPE ty_import_object
  CHANGING cv_has_source TYPE abap_bool.

  DATA: wal_source TYPE ty_source_line.

  CLEAR cv_has_source.

  READ TABLE tg_source INTO wal_source
    WITH KEY object_type = is_object-object_type
             object_name = is_object-object_name.

  IF sy-subrc EQ 0.
    cv_has_source = abap_true.
  ENDIF.

ENDFORM. " f_has_source_code

*&---------------------------------------------------------------------*
*& FORM f_check_object_exists
*&---------------------------------------------------------------------*
* [Título: Verifica si el objeto ya existe en destino]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto de importación
*&---------------------------------------------------------------------*
FORM f_check_object_exists
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_obj_name TYPE tadir-obj_name,
        vl_pgmid    TYPE tadir-pgmid,
        vl_object   TYPE tadir-object.

  CLEAR cs_object-exists_dest.

  vl_pgmid    = 'R3TR'.
  vl_obj_name = cs_object-object_name.

  CASE cs_object-object_type.
    WHEN 'DOMA'.
      vl_object = 'DOMA'.
    WHEN 'DTEL'.
      vl_object = 'DTEL'.
    WHEN 'TABL' OR 'STRU'.
      vl_object = 'TABL'.
    WHEN 'TTYP'.
      vl_object = 'TTYP'.
    WHEN 'SHLP'.
      vl_object = 'SHLP'.
    WHEN 'PROG'.
      vl_object = 'PROG'.
    WHEN 'CLAS'.
      vl_object = 'CLAS'.
    WHEN 'INTF'.
      vl_object = 'INTF'.
    WHEN 'FUGR'.
      vl_object = 'FUGR'.
    WHEN OTHERS.
      RETURN.
  ENDCASE.

  SELECT SINGLE obj_name
    FROM tadir
    INTO vl_obj_name
    WHERE pgmid    EQ vl_pgmid
      AND object   EQ vl_object
      AND obj_name EQ cs_object-object_name.

  IF sy-subrc EQ 0.
    cs_object-exists_dest = abap_true.
  ENDIF.

ENDFORM. " f_check_object_exists

*&---------------------------------------------------------------------*
*& FORM f_set_import_priority
*&---------------------------------------------------------------------*
* [Título: Define prioridad técnica de importación]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto de importación
*&---------------------------------------------------------------------*
FORM f_set_import_priority
  CHANGING cs_object TYPE ty_import_object.

  CASE cs_object-object_type.
    WHEN 'DOMA'.
      cs_object-import_priority = 10.
    WHEN 'DTEL'.
      cs_object-import_priority = 20.
    WHEN 'TTYP'.
      cs_object-import_priority = 30.
    WHEN 'STRU'.
      cs_object-import_priority = 40.
    WHEN 'TABL'.
      cs_object-import_priority = 50.
    WHEN 'SHLP'.
      cs_object-import_priority = 60.
    WHEN 'PROG'.
      cs_object-import_priority = 70.
    WHEN 'INTF'.
      cs_object-import_priority = 80.
    WHEN 'CLAS'.
      cs_object-import_priority = 90.
    WHEN 'FUGR'.
      cs_object-import_priority = 100.
    WHEN OTHERS.
      cs_object-import_priority = 999.
  ENDCASE.

ENDFORM. " f_set_import_priority

*&---------------------------------------------------------------------*
*& FORM f_display_alv
*&---------------------------------------------------------------------*
* [Título: Muestra el ALV usando la misma estructura que el exportador]
*&---------------------------------------------------------------------*
FORM f_display_alv.

  DATA:
    tl_fieldcat TYPE lvc_t_fcat,
    wal_layout  TYPE lvc_s_layo.

  PERFORM f_build_fieldcat CHANGING tl_fieldcat.

  wal_layout-zebra      = abap_true.
  wal_layout-cwidth_opt = abap_true.
  wal_layout-sel_mode   = 'A'.

  go_grid->set_table_for_first_display(
    EXPORTING
      is_layout       = wal_layout
    CHANGING
      it_outtab       = tg_objects
      it_fieldcatalog = tl_fieldcat ).

  go_grid->set_toolbar_interactive( ).

ENDFORM. " f_display_alv

*&---------------------------------------------------------------------*
*& FORM f_build_fieldcat
*&---------------------------------------------------------------------*
* [Título: Construye catálogo LVC del ALV]
*&---------------------------------------------------------------------*
* <-> ct_fieldcat " Catálogo ALV Grid
*&---------------------------------------------------------------------*
FORM f_build_fieldcat
  CHANGING ct_fieldcat TYPE lvc_t_fcat.

  CLEAR ct_fieldcat.

  PERFORM f_add_fieldcat USING 'LIGHT'          'Estado'         1 6  abap_true  abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'OBJECT_TYPE'    'Tipo'           2 10 abap_false abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'OBJECT_NAME'    'Objeto'         3 40 abap_false abap_true  CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'SHORT_TEXT'     'Descripción'    4 50 abap_false abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'ORIGINAL_LANG'  'Idioma'         5 8  abap_false abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'LAST_CHANGE'    'Último Cambio'  6 12 abap_false abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'EXISTS_DEST'    'Existe destino' 7 15 abap_false abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'ACTIVATED'      'Activado'       8 10 abap_false abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'IMPORT_MESSAGE' 'Mensaje'        9 80 abap_false abap_false CHANGING ct_fieldcat.

ENDFORM. " f_build_fieldcat

*&---------------------------------------------------------------------*
*& FORM f_add_fieldcat
*&---------------------------------------------------------------------*
* [Título: Agrega una columna al catálogo LVC]
*&---------------------------------------------------------------------*
* -> iv_fieldname " Campo interno
* -> iv_text      " Texto visible
* -> iv_position  " Posición visible
* -> iv_outputlen " Ancho de salida
* -> iv_icon      " Indicador de icono
* -> iv_hotspot   " Indicador hotspot
* <-> ct_fieldcat " Catálogo ALV Grid
*&---------------------------------------------------------------------*
FORM f_add_fieldcat
  USING iv_fieldname TYPE lvc_fname
        iv_text      TYPE string
        iv_position  TYPE i
        iv_outputlen TYPE i
        iv_icon      TYPE abap_bool
        iv_hotspot   TYPE abap_bool
  CHANGING ct_fieldcat TYPE lvc_t_fcat.

  DATA wal_fieldcat TYPE lvc_s_fcat.

  CLEAR wal_fieldcat.

  wal_fieldcat-fieldname = iv_fieldname.
  wal_fieldcat-coltext   = iv_text.
  wal_fieldcat-scrtext_l = iv_text.
  wal_fieldcat-scrtext_m = iv_text.
  wal_fieldcat-scrtext_s = iv_text.
  wal_fieldcat-col_pos   = iv_position.
  wal_fieldcat-outputlen = iv_outputlen.
  wal_fieldcat-icon      = iv_icon.
  wal_fieldcat-hotspot   = iv_hotspot.

  APPEND wal_fieldcat TO ct_fieldcat.

ENDFORM. " f_add_fieldcat

*&---------------------------------------------------------------------*
*& FORM f_import_selected_objects
*&---------------------------------------------------------------------*
* [Título: Importa únicamente los objetos seleccionados en el ALV]
*&---------------------------------------------------------------------*
FORM f_import_selected_objects.

  DATA:
    tl_rows      TYPE lvc_t_row,
    wal_row      TYPE lvc_s_row,
    vl_answer    TYPE c LENGTH 1,
    vl_count     TYPE i,
    vl_count_txt TYPE string,
    vl_question  TYPE string,
    vl_imported  TYPE i.

  FIELD-SYMBOLS <fsl_object> TYPE ty_import_object.

  IF p_test EQ abap_true.
    MESSAGE 'Modo simulación activo. No se modificaron objetos.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  IF go_grid IS BOUND.
    go_grid->get_selected_rows(
      IMPORTING
        et_index_rows = tl_rows ).
  ENDIF.

  IF tl_rows IS INITIAL.
    MESSAGE 'Debe seleccionar al menos un registro del ALV.' TYPE 'I'.
    RETURN.
  ENDIF.

  LOOP AT tg_objects ASSIGNING <fsl_object>.
    CLEAR <fsl_object>-selected.
  ENDLOOP.

  LOOP AT tl_rows INTO wal_row.

    READ TABLE tg_objects ASSIGNING <fsl_object> INDEX wal_row-index.

    IF sy-subrc = 0.
      <fsl_object>-selected = abap_true.
      vl_count = vl_count + 1.
    ENDIF.

  ENDLOOP.

  vl_count_txt = vl_count.

  CONCATENATE '¿Importar' vl_count_txt 'objetos seleccionados?'
    INTO vl_question SEPARATED BY space.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Confirmar importación'
      text_question         = vl_question
      text_button_1         = 'Sí'
      text_button_2         = 'No'
      default_button        = '2'
      display_cancel_button = abap_true
    IMPORTING
      answer                = vl_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.

  IF sy-subrc NE 0 OR vl_answer NE '1'.
    MESSAGE 'Importación cancelada por el usuario.' TYPE 'S'.
    RETURN.
  ENDIF.

  LOOP AT tg_objects ASSIGNING <fsl_object>.

    IF <fsl_object>-selected NE abap_true.
      CONTINUE.
    ENDIF.

    IF <fsl_object>-import_status NE cg_status_ready.
      CONTINUE.
    ENDIF.

    CASE <fsl_object>-object_type.
      WHEN 'DOMA'.
        PERFORM f_import_doma CHANGING <fsl_object>.

      WHEN 'DTEL'.
        PERFORM f_import_dtel CHANGING <fsl_object>.

      WHEN 'TABL' OR 'STRU'.
        PERFORM f_import_tabl CHANGING <fsl_object>.

      WHEN 'SHLP'.
        PERFORM f_import_shlp CHANGING <fsl_object>.

      WHEN 'PROG'.
        PERFORM f_import_prog CHANGING <fsl_object>.

      WHEN 'TTYP'.
        PERFORM f_import_ttyp CHANGING <fsl_object>.

      WHEN 'CLAS' OR 'INTF'.
        PERFORM f_mark_not_implemented CHANGING <fsl_object>.

      WHEN 'FUGR'.
        PERFORM f_import_fugr CHANGING <fsl_object>.

      WHEN OTHERS.
        PERFORM f_set_object_error
          USING 'Tipo de objeto no soportado.'
          CHANGING <fsl_object>.
    ENDCASE.

    vl_imported = vl_imported + 1.

    PERFORM f_add_log
      USING <fsl_object>-object_type
            <fsl_object>-object_name
            'IMPORT'
            <fsl_object>-import_status
            <fsl_object>-import_message.

  ENDLOOP.

  IF go_grid IS BOUND.
    go_grid->refresh_table_display( ).
  ENDIF.

  IF vl_imported IS INITIAL.
    MESSAGE 'No se importaron objetos. Verifique que los seleccionados estén listos para importar.' TYPE 'S' DISPLAY LIKE 'W'.
  ELSE.
    gv_import_executed = abap_true.
    MESSAGE 'Proceso de importación finalizado. Revise el estado en el ALV.' TYPE 'S'.
  ENDIF.

ENDFORM. " f_import_selected_objects

*&---------------------------------------------------------------------*
*& FORM f_navigate_to_object
*&---------------------------------------------------------------------*
* [Título: Navega al objeto seleccionado desde el ALV]
*&---------------------------------------------------------------------*
* -> iv_object_type " Tipo de objeto
* -> iv_object_name " Nombre técnico
*&---------------------------------------------------------------------*
FORM f_navigate_to_object
  USING iv_object_type TYPE string
        iv_object_name TYPE tadir-obj_name.

  DATA:
    vl_operation   TYPE c LENGTH 4,
    vl_object_type TYPE tadir-object,
    vl_object_name TYPE tadir-obj_name.

  vl_operation   = 'SHOW'.
  vl_object_name = iv_object_name.

  CASE iv_object_type.
    WHEN 'STRU'.
      vl_object_type = 'TABL'.
    WHEN OTHERS.
      vl_object_type = iv_object_type.
  ENDCASE.

  TRY.

      CALL FUNCTION 'RS_TOOL_ACCESS'
        EXPORTING
          operation           = vl_operation
          object_name         = vl_object_name
          object_type         = vl_object_type
        EXCEPTIONS
          not_executed        = 1
          invalid_object_type = 2
          OTHERS              = 3.

    CATCH cx_sy_dyn_call_error.
      sy-subrc = 3.
  ENDTRY.

  IF sy-subrc = 0.
    RETURN.
  ENDIF.

  CASE iv_object_type.

    WHEN 'PROG'.
      SET PARAMETER ID 'RID' FIELD iv_object_name.
      CALL TRANSACTION 'SE38' AND SKIP FIRST SCREEN.

    WHEN 'TABL' OR 'STRU' OR 'TTYP' OR 'DOMA' OR 'DTEL' OR 'SHLP'.
      SET PARAMETER ID 'DTB' FIELD iv_object_name.
      CALL TRANSACTION 'SE11'.

    WHEN 'CLAS' OR 'INTF'.
      SET PARAMETER ID 'CLS' FIELD iv_object_name.
      CALL TRANSACTION 'SE24' AND SKIP FIRST SCREEN.

    WHEN 'FUGR'.
      SET PARAMETER ID 'LIB' FIELD iv_object_name.
      CALL TRANSACTION 'SE37'.

  ENDCASE.

ENDFORM. " f_navigate_to_object

FORM f_get_payload
  USING is_object  TYPE ty_import_object
        iv_tag     TYPE string
  CHANGING cv_payload TYPE string.

  DATA: wal_payload TYPE ty_object_payload.

  CLEAR cv_payload.

  READ TABLE tg_payloads INTO wal_payload
    WITH KEY object_type = is_object-object_type
             object_name = is_object-object_name
             payload_tag = iv_tag.

  IF sy-subrc EQ 0.
    cv_payload = wal_payload-content.
  ENDIF.

ENDFORM. " f_get_payload

*&---------------------------------------------------------------------*
*& FORM f_decode_payload
*&---------------------------------------------------------------------*
* [Título: Decodifica un payload base64 del XML]
*&---------------------------------------------------------------------*
* -> iv_payload " Contenido base64 leído desde XML
* <- cv_xstring " XML interno decodificado como XSTRING
* <- cv_error   " Indicador de error
* <- cv_message " Mensaje técnico
*&---------------------------------------------------------------------*
FORM f_decode_payload
  USING iv_payload TYPE string
  CHANGING cv_xstring TYPE xstring
           cv_error   TYPE abap_bool
           cv_message TYPE string.

  DATA: lo_error TYPE REF TO cx_root.

  CLEAR: cv_xstring, cv_error, cv_message.

  IF iv_payload IS INITIAL.
    cv_error   = abap_true.
    cv_message = 'Payload vacío.' .
    RETURN.
  ENDIF.

  TRY.
      CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
        EXPORTING
          input  = iv_payload
        IMPORTING
          output = cv_xstring.
    CATCH cx_root INTO lo_error.
      cv_error   = abap_true.
      cv_message = lo_error->get_text( ).
  ENDTRY.

ENDFORM. " f_decode_payload

*&---------------------------------------------------------------------*
*& FORM f_import_doma
*&---------------------------------------------------------------------*
* [Título: Importa un dominio DDIC desde payload XML]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto a importar
*&---------------------------------------------------------------------*
FORM f_import_doma
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_payload TYPE string,
        vl_xstring TYPE xstring,
        vl_error   TYPE abap_bool,
        vl_message TYPE string,
        wal_dd01v  TYPE dd01v,
        tl_dd07v   TYPE STANDARD TABLE OF dd07v,
        lo_error   TYPE REF TO cx_root.

  PERFORM f_get_payload USING cs_object 'ddic_payload'
    CHANGING vl_payload.

  PERFORM f_decode_payload USING vl_payload
    CHANGING vl_xstring vl_error vl_message.

  IF vl_error EQ abap_true.
    PERFORM f_set_object_error USING vl_message CHANGING cs_object.
    RETURN.
  ENDIF.

  TRY.
      CALL TRANSFORMATION id
        SOURCE XML vl_xstring
        RESULT dd01v = wal_dd01v
               dd07v = tl_dd07v.

      CALL FUNCTION 'DDIF_DOMA_PUT'
        EXPORTING
          name      = wal_dd01v-domname
          dd01v_wa  = wal_dd01v
        TABLES
          dd07v_tab = tl_dd07v
        EXCEPTIONS
          OTHERS    = 1.

      IF sy-subrc NE 0.
        PERFORM f_set_object_error
          USING 'Error al crear/actualizar dominio con DDIF_DOMA_PUT.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      PERFORM f_activate_doma USING wal_dd01v-domname CHANGING cs_object.

    CATCH cx_root INTO lo_error.
      vl_message = lo_error->get_text( ).
      PERFORM f_set_object_error USING vl_message CHANGING cs_object.
  ENDTRY.

ENDFORM. " f_import_doma

*&---------------------------------------------------------------------*
*& FORM f_import_dtel
*&---------------------------------------------------------------------*
* [Título: Importa un elemento de datos DDIC desde payload XML]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto a importar
*&---------------------------------------------------------------------*
FORM f_import_dtel
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_payload TYPE string,
        vl_xstring TYPE xstring,
        vl_error   TYPE abap_bool,
        vl_message TYPE string,
        wal_dd04v  TYPE dd04v,
        lo_error   TYPE REF TO cx_root.

  PERFORM f_get_payload USING cs_object 'ddic_payload'
    CHANGING vl_payload.

  PERFORM f_decode_payload USING vl_payload
    CHANGING vl_xstring vl_error vl_message.

  IF vl_error EQ abap_true.
    PERFORM f_set_object_error USING vl_message CHANGING cs_object.
    RETURN.
  ENDIF.

  TRY.
      CALL TRANSFORMATION id
        SOURCE XML vl_xstring
        RESULT dd04v = wal_dd04v.

      CALL FUNCTION 'DDIF_DTEL_PUT'
        EXPORTING
          name     = wal_dd04v-rollname
          dd04v_wa = wal_dd04v
        EXCEPTIONS
          OTHERS   = 1.

      IF sy-subrc NE 0.
        PERFORM f_set_object_error
          USING 'Error al crear/actualizar elemento de datos con DDIF_DTEL_PUT.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      PERFORM f_activate_dtel USING wal_dd04v-rollname CHANGING cs_object.

    CATCH cx_root INTO lo_error.
      vl_message = lo_error->get_text( ).
      PERFORM f_set_object_error USING vl_message CHANGING cs_object.
  ENDTRY.

ENDFORM. " f_import_dtel

*&---------------------------------------------------------------------*
*& FORM f_import_tabl
*&---------------------------------------------------------------------*
* [Título: Importa una tabla o estructura DDIC desde payload XML]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto a importar
*&---------------------------------------------------------------------*
FORM f_import_tabl
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_payload TYPE string,
        vl_xstring TYPE xstring,
        vl_error   TYPE abap_bool,
        vl_message TYPE string,
        wal_dd02v  TYPE dd02v,
        tl_dd03p   TYPE STANDARD TABLE OF dd03p,
        tl_dd05m   TYPE STANDARD TABLE OF dd05m,
        tl_dd08v   TYPE STANDARD TABLE OF dd08v,
        tl_dd12v   TYPE STANDARD TABLE OF dd12v,
        tl_dd17v   TYPE STANDARD TABLE OF dd17v,
        tl_dd35v   TYPE STANDARD TABLE OF dd35v,
        tl_dd36m   TYPE STANDARD TABLE OF dd36m,
        lo_error   TYPE REF TO cx_root.

  PERFORM f_get_payload USING cs_object 'ddic_payload'
    CHANGING vl_payload.

  PERFORM f_decode_payload USING vl_payload
    CHANGING vl_xstring vl_error vl_message.

  IF vl_error EQ abap_true.
    PERFORM f_set_object_error USING vl_message CHANGING cs_object.
    RETURN.
  ENDIF.

  TRY.
      CALL TRANSFORMATION id
        SOURCE XML vl_xstring
        RESULT dd02v = wal_dd02v
               dd03p = tl_dd03p
               dd05m = tl_dd05m
               dd08v = tl_dd08v
               dd12v = tl_dd12v
               dd17v = tl_dd17v
               dd35v = tl_dd35v
               dd36m = tl_dd36m.

      CALL FUNCTION 'DDIF_TABL_PUT'
        EXPORTING
          name      = wal_dd02v-tabname
          dd02v_wa  = wal_dd02v
        TABLES
          dd03p_tab = tl_dd03p
          dd05m_tab = tl_dd05m
          dd08v_tab = tl_dd08v
          dd12v_tab = tl_dd12v
          dd17v_tab = tl_dd17v
          dd35v_tab = tl_dd35v
          dd36m_tab = tl_dd36m
        EXCEPTIONS
          OTHERS    = 1.

      IF sy-subrc NE 0.
        PERFORM f_set_object_error
          USING 'Error al crear/actualizar tabla o estructura con DDIF_TABL_PUT.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      PERFORM f_activate_tabl USING wal_dd02v-tabname CHANGING cs_object.

    CATCH cx_root INTO lo_error.
      vl_message = lo_error->get_text( ).
      PERFORM f_set_object_error USING vl_message CHANGING cs_object.
  ENDTRY.

ENDFORM. " f_import_tabl

*&---------------------------------------------------------------------*
*& FORM f_import_shlp
*&---------------------------------------------------------------------*
* [Título: Importa una ayuda de búsqueda desde payload XML]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto a importar
*&---------------------------------------------------------------------*
FORM f_import_shlp
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_payload TYPE string,
        vl_xstring TYPE xstring,
        vl_error   TYPE abap_bool,
        vl_message TYPE string,
        wal_dd30v  TYPE dd30v,
        tl_dd31v   TYPE STANDARD TABLE OF dd31v,
        tl_dd32p   TYPE STANDARD TABLE OF dd32p,
        tl_dd33v   TYPE STANDARD TABLE OF dd33v,
        lo_error   TYPE REF TO cx_root.

  PERFORM f_get_payload USING cs_object 'ddic_payload'
    CHANGING vl_payload.

  PERFORM f_decode_payload USING vl_payload
    CHANGING vl_xstring vl_error vl_message.

  IF vl_error EQ abap_true.
    PERFORM f_set_object_error USING vl_message CHANGING cs_object.
    RETURN.
  ENDIF.

  TRY.
      CALL TRANSFORMATION id
        SOURCE XML vl_xstring
        RESULT dd30v = wal_dd30v
               dd31v = tl_dd31v
               dd32p = tl_dd32p
               dd33v = tl_dd33v.

      CALL FUNCTION 'DDIF_SHLP_PUT'
        EXPORTING
          name      = wal_dd30v-shlpname
          dd30v_wa  = wal_dd30v
        TABLES
          dd31v_tab = tl_dd31v
          dd32p_tab = tl_dd32p
          dd33v_tab = tl_dd33v
        EXCEPTIONS
          OTHERS    = 1.

      IF sy-subrc NE 0.
        PERFORM f_set_object_error
          USING 'Error al crear/actualizar search help con DDIF_SHLP_PUT.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      PERFORM f_activate_shlp USING wal_dd30v-shlpname CHANGING cs_object.

    CATCH cx_root INTO lo_error.
      vl_message = lo_error->get_text( ).
      PERFORM f_set_object_error USING vl_message CHANGING cs_object.
  ENDTRY.

ENDFORM. " f_import_shlp

*&---------------------------------------------------------------------*
*& FORM f_import_prog
*&---------------------------------------------------------------------*
* [Título: Importa un programa fuente ABAP]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto a importar
*&---------------------------------------------------------------------*
FORM f_import_prog
  CHANGING cs_object TYPE ty_import_object.

  DATA: tl_report_source TYPE tyt_report_line,
        tl_include_source TYPE tyt_report_line,
        wal_report_line  TYPE ty_report_line,
        wal_source       TYPE ty_source_line,
        vl_msg           TYPE string,
        vl_line          TYPE c LENGTH 10,
        vl_word          TYPE string,
        vl_program       TYPE progname,
        vl_error         TYPE abap_bool.

  CLEAR tl_report_source.
  vl_program = cs_object-object_name.

  SORT tg_source BY object_type object_name include line_number.

  "Persist the includes before checking and inserting the main report. This
  "makes the XML produced by the exporter self-contained for report sources.
  LOOP AT tg_source INTO wal_source
    WHERE object_type EQ cs_object-object_type
      AND object_name EQ cs_object-object_name
      AND include     NE vl_program.

    APPEND wal_source-source_line TO tl_include_source.

    AT END OF include.
      INSERT REPORT wal_source-include FROM tl_include_source.
      IF sy-subrc NE 0.
        CONCATENATE 'No se pudo insertar el include' wal_source-include
          INTO vl_msg SEPARATED BY space.
        PERFORM f_set_object_error USING vl_msg CHANGING cs_object.
        RETURN.
      ENDIF.
      CLEAR tl_include_source.
    ENDAT.
  ENDLOOP.

  LOOP AT tg_source INTO wal_source
    WHERE object_type EQ cs_object-object_type
      AND object_name EQ cs_object-object_name
      AND include     EQ vl_program.

    wal_report_line = wal_source-source_line.
    APPEND wal_report_line TO tl_report_source.

  ENDLOOP.

  IF tl_report_source IS INITIAL.
    PERFORM f_set_object_error
      USING 'El programa no contiene source_code en el XML.'
      CHANGING cs_object.
    RETURN.
  ENDIF.

  SYNTAX-CHECK FOR tl_report_source
    MESSAGE vl_msg
    LINE vl_line
    WORD vl_word
    PROGRAM vl_program.

  IF sy-subrc NE 0.
    CONCATENATE 'Error de sintaxis. Línea:' vl_line 'Palabra:' vl_word 'Mensaje:' vl_msg
      INTO vl_msg SEPARATED BY space.

    PERFORM f_set_object_error USING vl_msg CHANGING cs_object.
    RETURN.
  ENDIF.

  INSERT REPORT vl_program FROM tl_report_source.

  IF sy-subrc NE 0.
    PERFORM f_set_object_error
      USING 'Error al insertar el programa con INSERT REPORT.'
      CHANGING cs_object.
    RETURN.
  ENDIF.

  PERFORM f_register_program_package
    USING vl_program
    CHANGING vl_error
             vl_msg.

  IF vl_error EQ abap_true.
    PERFORM f_set_object_warning
      USING vl_msg
      CHANGING cs_object.
    RETURN.
  ENDIF.

  cs_object-activated = abap_true.
  PERFORM f_set_object_success
    USING 'Programa importado correctamente en el package destino.'
    CHANGING cs_object.

ENDFORM. " f_import_prog

*&---------------------------------------------------------------------*
*& FORM f_import_ttyp
*&---------------------------------------------------------------------*
* [Título: Importa un tipo de tabla DDIC desde payload XML]
*&---------------------------------------------------------------------*
FORM f_import_ttyp
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_payload TYPE string,
        vl_xstring TYPE xstring,
        vl_error   TYPE abap_bool,
        vl_message TYPE string,
        wal_dd40v  TYPE dd40v,
        tl_dd42v   TYPE STANDARD TABLE OF dd42v,
        tl_dd43v   TYPE STANDARD TABLE OF dd43v,
        lo_error   TYPE REF TO cx_root.

  PERFORM f_get_payload USING cs_object 'ddic_payload'
    CHANGING vl_payload.
  PERFORM f_decode_payload USING vl_payload
    CHANGING vl_xstring vl_error vl_message.

  IF vl_error EQ abap_true.
    PERFORM f_set_object_error USING vl_message CHANGING cs_object.
    RETURN.
  ENDIF.

  TRY.
      CALL TRANSFORMATION id
        SOURCE XML vl_xstring
        RESULT dd40v = wal_dd40v
               dd42v = tl_dd42v
               dd43v = tl_dd43v.

      CALL FUNCTION 'DDIF_TTYP_PUT'
        EXPORTING
          name      = wal_dd40v-typename
          dd40v_wa  = wal_dd40v
        TABLES
          dd42v_tab = tl_dd42v
          dd43v_tab = tl_dd43v
        EXCEPTIONS
          OTHERS    = 1.

      IF sy-subrc NE 0.
        PERFORM f_set_object_error
          USING 'Error al crear/actualizar tipo de tabla con DDIF_TTYP_PUT.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      IF p_activ EQ abap_true.
        CALL FUNCTION 'DDIF_TTYP_ACTIVATE'
          EXPORTING name = wal_dd40v-typename
          EXCEPTIONS OTHERS = 1.
      ENDIF.

      IF p_activ EQ abap_true AND sy-subrc NE 0.
        PERFORM f_set_object_warning
          USING 'Tipo de tabla importado, pero no activado.'
          CHANGING cs_object.
      ELSEIF p_activ EQ abap_true.
        cs_object-activated = abap_true.
        PERFORM f_set_object_success
          USING 'Tipo de tabla importado y activado correctamente.'
          CHANGING cs_object.
      ELSE.
        PERFORM f_set_object_warning
          USING 'Tipo de tabla importado correctamente, pero no activado.'
          CHANGING cs_object.
      ENDIF.

    CATCH cx_root INTO lo_error.
      vl_message = lo_error->get_text( ).
      PERFORM f_set_object_error USING vl_message CHANGING cs_object.
  ENDTRY.

ENDFORM. " f_import_ttyp

*&---------------------------------------------------------------------*
*& FORM f_import_fugr
*&---------------------------------------------------------------------*
* [Título: Recrea un grupo de funciones y sus módulos de función]
*&---------------------------------------------------------------------*
FORM f_import_fugr
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_payload     TYPE string,
        vl_xstring     TYPE xstring,
        vl_error       TYPE abap_bool,
        vl_message     TYPE string,
        vl_include     TYPE progname,
        vl_short_text  TYPE string,
        tl_tfdir       TYPE STANDARD TABLE OF tfdir,
        tl_tftit       TYPE STANDARD TABLE OF tftit,
        tl_enlfdir     TYPE STANDARD TABLE OF enlfdir,
        tl_fupararef   TYPE STANDARD TABLE OF fupararef,
        tl_import      TYPE STANDARD TABLE OF rsimp,
        tl_export      TYPE STANDARD TABLE OF rsexp,
        tl_changing    TYPE STANDARD TABLE OF rscha,
        tl_tables      TYPE STANDARD TABLE OF rstbl,
        tl_exceptions  TYPE STANDARD TABLE OF rsexc,
        tl_source      TYPE STANDARD TABLE OF rssource,
        tl_report_source TYPE tyt_report_line,
        vl_prefix      TYPE progname,
        lo_error       TYPE REF TO cx_root.

  PERFORM f_get_payload USING cs_object 'function_group_payload'
    CHANGING vl_payload.
  PERFORM f_decode_payload USING vl_payload
    CHANGING vl_xstring vl_error vl_message.
  IF vl_error EQ abap_true.
    PERFORM f_set_object_error USING vl_message CHANGING cs_object.
    RETURN.
  ENDIF.

  TRY.
      CALL TRANSFORMATION id
        SOURCE XML vl_xstring
        RESULT tfdir     = tl_tfdir
               tftit     = tl_tftit
               enlfdir   = tl_enlfdir
               fupararef = tl_fupararef.

      "Create the function pool before inserting its function modules. The
      "standard API owns TFDIR/ENLFDIR and the generated Uxx includes.
      IF cs_object-exists_dest IS INITIAL.
        vl_short_text = cs_object-short_text.
        IF vl_short_text IS INITIAL.
          vl_short_text = |Grupo de funciones { cs_object-object_name }|.
        ENDIF.

        CALL FUNCTION 'FUNCTION_POOL_CREATE'
          EXPORTING
            pool_name = cs_object-object_name
            short_text = vl_short_text
          EXCEPTIONS
            OTHERS = 1.
        IF sy-subrc NE 0.
          PERFORM f_set_object_error
            USING 'No se pudo crear el grupo de funciones.'
            CHANGING cs_object.
          RETURN.
        ENDIF.
      ENDIF.

      "FUNCTION_POOL_CREATE creates the pool; register a new pool in the
      "requested package/transport before its function modules are inserted.
      IF cs_object-exists_dest IS INITIAL.
        CALL FUNCTION 'TR_TADIR_INTERFACE'
          EXPORTING
            wi_test_modus      = abap_false
            wi_tadir_pgmid     = 'R3TR'
            wi_tadir_object    = 'FUGR'
            wi_tadir_obj_name  = cs_object-object_name
            wi_tadir_srcsystem = sy-sysid
            wi_tadir_author    = sy-uname
            wi_tadir_devclass  = vg_package
            wi_set_genflag     = abap_false
          EXCEPTIONS
            OTHERS             = 1.
        IF sy-subrc NE 0.
          PERFORM f_set_object_error
            USING 'No se pudo asignar el grupo de funciones al package destino.'
            CHANGING cs_object.
          RETURN.
        ENDIF.
      ENDIF.

      LOOP AT tl_tfdir INTO DATA(wal_tfdir).
        CLEAR: tl_import, tl_export, tl_changing, tl_tables,
               tl_exceptions, tl_source.

        LOOP AT tl_fupararef INTO DATA(wal_parameter)
          WHERE funcname = wal_tfdir-funcname.
          CASE wal_parameter-paramtype.
            WHEN 'I'.
              APPEND CORRESPONDING #( wal_parameter ) TO tl_import.
            WHEN 'E'.
              APPEND CORRESPONDING #( wal_parameter ) TO tl_export.
            WHEN 'C'.
              APPEND CORRESPONDING #( wal_parameter ) TO tl_changing.
            WHEN 'T'.
              APPEND CORRESPONDING #( wal_parameter ) TO tl_tables.
            WHEN 'X'.
              APPEND CORRESPONDING #( wal_parameter ) TO tl_exceptions.
          ENDCASE.
        ENDLOOP.

        "TFDIR-INCLUDE contains the Uxx suffix; it is the source include
        "captured by the exporter for this function module.
        CONCATENATE 'L' cs_object-object_name wal_tfdir-include INTO vl_include.
        LOOP AT tg_source INTO DATA(wal_source)
          WHERE object_type = cs_object-object_type
            AND object_name = cs_object-object_name
            AND include     = vl_include.
          IF wal_source-source_line CP 'FUNCTION *'
          OR wal_source-source_line CP 'ENDFUNCTION*'
          OR wal_source-source_line CP '*"*'.
            CONTINUE.
          ENDIF.
          APPEND VALUE #( line = wal_source-source_line ) TO tl_source.
        ENDLOOP.

        READ TABLE tl_tftit INTO DATA(wal_tftit)
          WITH KEY funcname = wal_tfdir-funcname spras = sy-langu.
        IF sy-subrc NE 0.
          READ TABLE tl_tftit INTO wal_tftit WITH KEY funcname = wal_tfdir-funcname.
        ENDIF.

        CALL FUNCTION 'RS_FUNCTIONMODULE_INSERT'
          EXPORTING
            funcname            = wal_tfdir-funcname
            function_pool       = cs_object-object_name
            short_text          = wal_tftit-stext
            remote_call         = wal_tfdir-fmode
            update_task         = wal_tfdir-utask
            corrnum             = p_req
            suppress_corr_check = abap_true
            save_active         = abap_true
          TABLES
            import_parameter    = tl_import
            export_parameter    = tl_export
            changing_parameter  = tl_changing
            tables_parameter    = tl_tables
            exception_list      = tl_exceptions
            source              = tl_source
          EXCEPTIONS
            OTHERS              = 1.
        IF sy-subrc NE 0.
          CONCATENATE 'No se pudo crear el módulo de función' wal_tfdir-funcname
            INTO vl_message SEPARATED BY space.
          PERFORM f_set_object_error USING vl_message CHANGING cs_object.
          RETURN.
        ENDIF.
      ENDLOOP.

      "The Function Builder generates SAPL... and LUxx includes itself. The
      "remaining L... includes carry global data, FORM routines and PBO/PAI
      "modules, so restore them after all function modules exist.
      SORT tg_source BY object_type object_name include line_number.
      CONCATENATE 'L' cs_object-object_name INTO vl_prefix.
      LOOP AT tg_source INTO DATA(wal_aux_source)
        WHERE object_type = cs_object-object_type
          AND object_name = cs_object-object_name.

        IF wal_aux_source-include NP |{ vl_prefix }*|
        OR wal_aux_source-include CP |{ vl_prefix }U*|.
          CONTINUE.
        ENDIF.

        APPEND wal_aux_source-source_line TO tl_report_source.
        AT END OF include.
          INSERT REPORT wal_aux_source-include FROM tl_report_source.
          IF sy-subrc NE 0.
            CONCATENATE 'No se pudo restaurar el include' wal_aux_source-include
              INTO vl_message SEPARATED BY space.
            PERFORM f_set_object_error USING vl_message CHANGING cs_object.
            RETURN.
          ENDIF.
          CLEAR tl_report_source.
        ENDAT.
      ENDLOOP.

      IF p_activ EQ abap_true.
        DATA tl_activation TYPE STANDARD TABLE OF dwinactiv.
        APPEND VALUE #( object = 'FUGR' obj_name = cs_object-object_name ) TO tl_activation.
        CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
          TABLES objects = tl_activation
          EXCEPTIONS OTHERS = 1.
      ENDIF.

      IF p_activ EQ abap_true AND sy-subrc NE 0.
        PERFORM f_set_object_warning
          USING 'Grupo y módulos importados, pero no activados.'
          CHANGING cs_object.
      ELSEIF p_activ EQ abap_true.
        cs_object-activated = abap_true.
        PERFORM f_set_object_success
          USING 'Grupo de funciones y módulos importados correctamente.'
          CHANGING cs_object.
      ELSE.
        PERFORM f_set_object_warning
          USING 'Grupo y módulos importados correctamente, pero no activados.'
          CHANGING cs_object.
      ENDIF.

    CATCH cx_root INTO lo_error.
      vl_message = lo_error->get_text( ).
      PERFORM f_set_object_error USING vl_message CHANGING cs_object.
  ENDTRY.

ENDFORM. " f_import_fugr

*&---------------------------------------------------------------------*
*& FORM f_register_program_package
*&---------------------------------------------------------------------*
* [Título: Registra el programa en el package destino]
*&---------------------------------------------------------------------*
* -> iv_program " Nombre técnico del programa
* <- cv_error   " Indicador de error
* <- cv_message " Mensaje técnico
*&---------------------------------------------------------------------*
FORM f_register_program_package
  USING iv_program TYPE progname
  CHANGING cv_error   TYPE abap_bool
           cv_message TYPE string.

  DATA:
    vl_korrnum     TYPE trkorr,
    vl_devclass    TYPE devclass,
    vl_subrc       TYPE sy-subrc,
    vl_subrc_text  TYPE string,
    lo_error       TYPE REF TO cx_root.

  CLEAR:
    cv_error,
    cv_message,
    vl_korrnum,
    vl_devclass,
    vl_subrc,
    vl_subrc_text.

  vl_devclass = vg_package.
  vl_korrnum  = p_req.

  IF iv_program IS INITIAL.
    cv_error   = abap_true.
    cv_message = 'No se pudo registrar el programa: nombre de programa vacío.'.
    RETURN.
  ENDIF.

  IF vl_devclass IS INITIAL.
    cv_error   = abap_true.
    cv_message = 'No se pudo registrar el programa: package destino vacío.'.
    RETURN.
  ENDIF.

  IF vl_devclass NE '$TMP' AND vl_korrnum IS INITIAL.
    cv_error   = abap_true.
    cv_message = 'No se pudo registrar el programa: falta orden de transporte para package no local.'.
    RETURN.
  ENDIF.

  TRY.

      CALL FUNCTION 'RS_CORR_INSERT'
        EXPORTING
          object              = iv_program
          object_class        = 'ABAP'
          mode                = 'INSERT'
          global_lock         = abap_true
          devclass            = vl_devclass
          korrnum             = vl_korrnum
        EXCEPTIONS
          cancelled           = 1
          permission_failure  = 2
          unknown_objectclass = 3
          OTHERS              = 4.

      IF sy-subrc NE 0.
        vl_subrc = sy-subrc.
        vl_subrc_text = vl_subrc.

        cv_error = abap_true.
        CONCATENATE 'No se pudo registrar el programa en el package destino.'
                    'SY-SUBRC:'
                    vl_subrc_text
          INTO cv_message SEPARATED BY space.
        RETURN.
      ENDIF.

      cv_message = 'Programa registrado correctamente en el package destino.'.

    CATCH cx_root INTO lo_error.
      cv_error   = abap_true.
      cv_message = lo_error->get_text( ).
  ENDTRY.

ENDFORM. " f_register_program_package

*&---------------------------------------------------------------------*
*& FORM f_activate_doma
*&---------------------------------------------------------------------*
* [Título: Activa un dominio o marca importación parcial]
*&---------------------------------------------------------------------*
* -> iv_name   " Nombre del dominio
* <-> cs_object " Objeto importado
*&---------------------------------------------------------------------*
FORM f_activate_doma
  USING iv_name TYPE dd01v-domname
  CHANGING cs_object TYPE ty_import_object.

  IF p_activ IS INITIAL.
    PERFORM f_set_object_warning
      USING 'Dominio importado correctamente, pero no activado.'
      CHANGING cs_object.
    RETURN.
  ENDIF.

  CALL FUNCTION 'DDIF_DOMA_ACTIVATE'
    EXPORTING
      name   = iv_name
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc EQ 0.
    cs_object-activated = abap_true.
    PERFORM f_set_object_success USING 'Dominio importado y activado correctamente.' CHANGING cs_object.
  ELSE.
    PERFORM f_set_object_warning USING 'Dominio importado, pero no activado.' CHANGING cs_object.
  ENDIF.

ENDFORM. " f_activate_doma

*&---------------------------------------------------------------------*
*& FORM f_activate_dtel
*&---------------------------------------------------------------------*
* [Título: Activa un elemento de datos o marca importación parcial]
*&---------------------------------------------------------------------*
* -> iv_name   " Nombre del elemento de datos
* <-> cs_object " Objeto importado
*&---------------------------------------------------------------------*
FORM f_activate_dtel
  USING iv_name TYPE dd04v-rollname
  CHANGING cs_object TYPE ty_import_object.

  IF p_activ IS INITIAL.
    PERFORM f_set_object_warning
      USING 'Elemento de datos importado correctamente, pero no activado.'
      CHANGING cs_object.
    RETURN.
  ENDIF.

  CALL FUNCTION 'DDIF_DTEL_ACTIVATE'
    EXPORTING
      name   = iv_name
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc EQ 0.
    cs_object-activated = abap_true.
    PERFORM f_set_object_success USING 'Elemento de datos importado y activado correctamente.' CHANGING cs_object.
  ELSE.
    PERFORM f_set_object_warning USING 'Elemento de datos importado, pero no activado.' CHANGING cs_object.
  ENDIF.

ENDFORM. " f_activate_dtel

*&---------------------------------------------------------------------*
*& FORM f_activate_tabl
*&---------------------------------------------------------------------*
* [Título: Activa una tabla/estructura o marca importación parcial]
*&---------------------------------------------------------------------*
* -> iv_name   " Nombre de tabla/estructura
* <-> cs_object " Objeto importado
*&---------------------------------------------------------------------*
FORM f_activate_tabl
  USING iv_name TYPE dd02v-tabname
  CHANGING cs_object TYPE ty_import_object.

  IF p_activ IS INITIAL.
    PERFORM f_set_object_warning
      USING 'Tabla/Estructura importada correctamente, pero no activada.'
      CHANGING cs_object.
    RETURN.
  ENDIF.

  CALL FUNCTION 'DDIF_TABL_ACTIVATE'
    EXPORTING
      name   = iv_name
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc EQ 0.
    cs_object-activated = abap_true.
    PERFORM f_set_object_success USING 'Tabla/Estructura importada y activada correctamente.' CHANGING cs_object.
  ELSE.
    PERFORM f_set_object_warning USING 'Tabla/Estructura importada, pero no activada.' CHANGING cs_object.
  ENDIF.

ENDFORM. " f_activate_tabl

*&---------------------------------------------------------------------*
*& FORM f_activate_shlp
*&---------------------------------------------------------------------*
* [Título: Activa una ayuda de búsqueda o marca importación parcial]
*&---------------------------------------------------------------------*
* -> iv_name   " Nombre de search help
* <-> cs_object " Objeto importado
*&---------------------------------------------------------------------*
FORM f_activate_shlp
  USING iv_name TYPE dd30v-shlpname
  CHANGING cs_object TYPE ty_import_object.

  IF p_activ IS INITIAL.
    PERFORM f_set_object_warning
      USING 'Search Help importada correctamente, pero no activada.'
      CHANGING cs_object.
    RETURN.
  ENDIF.

  CALL FUNCTION 'DDIF_SHLP_ACTIVATE'
    EXPORTING
      name   = iv_name
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc EQ 0.
    cs_object-activated = abap_true.
    PERFORM f_set_object_success USING 'Search Help importada y activada correctamente.' CHANGING cs_object.
  ELSE.
    PERFORM f_set_object_warning USING 'Search Help importada, pero no activada.' CHANGING cs_object.
  ENDIF.

ENDFORM. " f_activate_shlp

*&---------------------------------------------------------------------*
*& FORM f_mark_not_implemented
*&---------------------------------------------------------------------*
* [Título: Marca objetos complejos como no implementados en esta fase]
*&---------------------------------------------------------------------*
* <-> cs_object " Objeto de importación
*&---------------------------------------------------------------------*
FORM f_mark_not_implemented
  CHANGING cs_object TYPE ty_import_object.

  cs_object-light          = cg_icon_yellow.
  cs_object-import_status  = cg_status_warn.
  cs_object-import_message = 'Tipo leído pero no importado en esta versión. Requiere API específica validada por release.'.
  cs_object-activated      = abap_false.

ENDFORM. " f_mark_not_implemented

*&---------------------------------------------------------------------*
*& FORM f_set_object_success
*&---------------------------------------------------------------------*
* [Título: Marca un objeto como importado correctamente]
*&---------------------------------------------------------------------*
* -> iv_message " Mensaje final
* <-> cs_object " Objeto de importación
*&---------------------------------------------------------------------*
FORM f_set_object_success
  USING iv_message TYPE string
  CHANGING cs_object TYPE ty_import_object.

  DATA: vl_message TYPE string.

  vl_message = iv_message.

  IF cs_object-exists_dest EQ abap_true.
    CONCATENATE vl_message 'Sobreescritura exitosa.'
      INTO vl_message SEPARATED BY space.
  ENDIF.

  cs_object-light          = cg_icon_green.
  cs_object-import_status  = cg_status_ok.
  cs_object-import_message = vl_message.

ENDFORM. " f_set_object_success

*&---------------------------------------------------------------------*
*& FORM f_set_object_warning
*&---------------------------------------------------------------------*
* [Título: Marca un objeto con advertencia]
*&---------------------------------------------------------------------*
* -> iv_message " Mensaje de advertencia
* <-> cs_object " Objeto de importación
*&---------------------------------------------------------------------*
FORM f_set_object_warning
  USING iv_message TYPE string
  CHANGING cs_object TYPE ty_import_object.

  cs_object-light          = cg_icon_yellow.
  cs_object-import_status  = cg_status_warn.
  cs_object-import_message = iv_message.
  cs_object-activated      = abap_false.

ENDFORM. " f_set_object_warning

*&---------------------------------------------------------------------*
*& FORM f_set_object_error
*&---------------------------------------------------------------------*
* [Título: Marca un objeto con error]
*&---------------------------------------------------------------------*
* -> iv_message " Mensaje de error
* <-> cs_object " Objeto de importación
*&---------------------------------------------------------------------*
FORM f_set_object_error
  USING iv_message TYPE string
  CHANGING cs_object TYPE ty_import_object.

  cs_object-light          = cg_icon_red.
  cs_object-import_status  = cg_status_err.
  cs_object-import_message = iv_message.
  cs_object-activated      = abap_false.

ENDFORM. " f_set_object_error

*&---------------------------------------------------------------------*
*& FORM f_add_log
*&---------------------------------------------------------------------*
* [Título: Agrega una entrada al log técnico]
*&---------------------------------------------------------------------*
* -> iv_object_type " Tipo de objeto
* -> iv_object_name " Nombre de objeto
* -> iv_step        " Paso procesado
* -> iv_status      " Estado del paso
* -> iv_message     " Mensaje técnico
*&---------------------------------------------------------------------*
FORM f_add_log
  USING iv_object_type TYPE string
        iv_object_name TYPE tadir-obj_name
        iv_step        TYPE string
        iv_status      TYPE string
        iv_message     TYPE string.

  DATA: wal_log TYPE ty_import_log.

  wal_log-object_type = iv_object_type.
  wal_log-object_name = iv_object_name.
  wal_log-step        = iv_step.
  wal_log-status      = iv_status.
  wal_log-message     = iv_message.

  APPEND wal_log TO tg_log.

ENDFORM. " f_add_log

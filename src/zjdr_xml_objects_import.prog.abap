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
  cg_xml_version  TYPE string VALUE '1.3',
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
  cg_button_import TYPE syucomm VALUE 'ZIMP_XML',
  cg_button_log TYPE syucomm VALUE 'ZLOG_XML',
  cg_button_log_download TYPE syucomm VALUE 'ZDL_LOG'.

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
         components_incomplete TYPE abap_bool,
         light           TYPE icon_d,
         object_type     TYPE string,
         object_name     TYPE tadir-obj_name,
         source_object_type TYPE string,
         source_object_name TYPE tadir-obj_name,
         target_object_name TYPE tadir-obj_name,
         relationship    TYPE string,
         parent_type     TYPE string,
         parent_name     TYPE tadir-obj_name,
         relation_reason TYPE string,
         short_text      TYPE string,
         original_lang   TYPE sylangu,
         original_system TYPE tadir-srcsystem,
         last_change     TYPE sy-datum,
         export_status   TYPE string,
         exists_dest     TYPE abap_bool,
         action          TYPE string,
         import_status   TYPE string,
         import_message  TYPE string,
         import_priority TYPE i,
         activated       TYPE abap_bool,
         activation_pending TYPE abap_bool,
         oo_prepared TYPE abap_bool,
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

TYPES: ty_report_line TYPE string.
TYPES: tyt_report_line TYPE STANDARD TABLE OF ty_report_line WITH EMPTY KEY.


* Source-based OO interchange; generated method include names are not portable.
* Shared wire types. Mirrored in both standalone reports by the local check.
TYPES: BEGIN OF ty_prog_component,
         kind TYPE string,
         name TYPE tadir-obj_name,
         language TYPE sylangu,
         original_system TYPE tadir-srcsystem,
         content TYPE xstring,
         error TYPE string,
       END OF ty_prog_component.
TYPES: BEGIN OF ty_prog_bundle,
         format TYPE string,
         program TYPE progname,
         program_type TYPE trdir-subc,
         components TYPE STANDARD TABLE OF ty_prog_component WITH EMPTY KEY,
       END OF ty_prog_bundle.
TYPES: BEGIN OF ty_prog_screen,
         header TYPE rpy_dyhead,
         containers TYPE dycatt_tab,
         fields TYPE dyfatc_tab,
         flow TYPE swydyflow,
         native_header TYPE d020s,
         native_fields TYPE STANDARD TABLE OF d021s WITH DEFAULT KEY,
         texts TYPE STANDARD TABLE OF d021t WITH EMPTY KEY,
       END OF ty_prog_screen.
TYPES: BEGIN OF ty_prog_cua,
         adm TYPE rsmpe_adm,
         sta TYPE STANDARD TABLE OF rsmpe_stat WITH DEFAULT KEY,
         fun TYPE STANDARD TABLE OF rsmpe_funt WITH DEFAULT KEY,
         men TYPE STANDARD TABLE OF rsmpe_men WITH DEFAULT KEY,
         mtx TYPE STANDARD TABLE OF rsmpe_mnlt WITH DEFAULT KEY,
         act TYPE STANDARD TABLE OF rsmpe_act WITH DEFAULT KEY,
         but TYPE STANDARD TABLE OF rsmpe_but WITH DEFAULT KEY,
         pfk TYPE STANDARD TABLE OF rsmpe_pfk WITH DEFAULT KEY,
         set TYPE STANDARD TABLE OF rsmpe_staf WITH DEFAULT KEY,
         doc TYPE STANDARD TABLE OF rsmpe_atrt WITH DEFAULT KEY,
         tit TYPE STANDARD TABLE OF rsmpe_titt WITH DEFAULT KEY,
         biv TYPE STANDARD TABLE OF rsmpe_buts WITH DEFAULT KEY,
       END OF ty_prog_cua.
TYPES: BEGIN OF ty_prog_doc,
         info TYPE dokil,
         head TYPE thead,
         lines TYPE STANDARD TABLE OF tline WITH DEFAULT KEY,
       END OF ty_prog_doc.
TYPES: BEGIN OF ty_prog_tran,
         definition TYPE tstc,
         gui TYPE tstcc,
         parameters TYPE tstcp,
         texts TYPE STANDARD TABLE OF tstct WITH DEFAULT KEY,
         auth TYPE STANDARD TABLE OF tstca WITH DEFAULT KEY,
       END OF ty_prog_tran.
TYPES: BEGIN OF ty_prog_tran_config,
         kind TYPE rglif-docutype,
         called TYPE tcode,
         skip TYPE abap_bool,
         independent TYPE abap_bool,
         variant TYPE rsstcd-variant,
         values TYPE STANDARD TABLE OF rsparam WITH DEFAULT KEY,
       END OF ty_prog_tran_config.
TYPES: BEGIN OF ty_prog_enho,
         original TYPE enh_hook_admin,
         shorttext TYPE string,
         hooks TYPE enh_hook_impl_it,
       END OF ty_prog_enho.
TYPES: BEGIN OF ty_prog_enhs,
         pgmid TYPE tadir-pgmid,
         obj_name TYPE trobj_name,
         obj_type TYPE trobjtype,
         main_type TYPE trobjtype,
         main_name TYPE eu_aname,
         program TYPE progname,
         shorttext TYPE string,
         definitions TYPE enh_hook_def_ext_it,
       END OF ty_prog_enhs.

TYPES: BEGIN OF ty_oo_payload,
         format TYPE string,
         object_type TYPE string,
         object_name TYPE seoclsname,
         class_properties TYPE vseoclass,
         interface_properties TYPE vseointerf,
         source TYPE seop_source_string,
         locals_def TYPE seop_source_string,
         locals_imp TYPE seop_source_string,
         macros TYPE seop_source_string,
         testclasses TYPE seop_source_string,
         textpool_language TYPE sylangu,
         textpool TYPE STANDARD TABLE OF textpool WITH EMPTY KEY,
       END OF ty_oo_payload.

*&---------------------------------------------------------------------*
*& DATA
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_saved_source,
         object_type TYPE string,
         object_name TYPE tadir-obj_name,
         program TYPE progname,
       END OF ty_saved_source.
TYPES: BEGIN OF ty_component_activation,
         owner TYPE tadir-obj_name,
         key TYPE dwinactiv,
       END OF ty_component_activation.
DATA tg_component_activation TYPE STANDARD TABLE OF ty_component_activation WITH EMPTY KEY.
DATA tg_saved_source TYPE STANDARD TABLE OF ty_saved_source WITH EMPTY KEY.

DATA:
  wag_header    TYPE ty_xml_header,
  tg_objects    TYPE tyt_import_object,
  tg_payloads   TYPE tyt_object_payload,
  tg_source     TYPE tyt_source_line,
  tg_log        TYPE tyt_import_log,
  vg_xml_string TYPE string,
  vg_input_version TYPE string,
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

    CLEAR wal_toolbar.
    wal_toolbar-function = cg_button_log.
    wal_toolbar-icon = icon_information.
    wal_toolbar-text = 'Ver log'.
    wal_toolbar-quickinfo = 'Detalle de fuentes, interfaces y activacion'.
    APPEND wal_toolbar TO e_object->mt_toolbar.

    CLEAR wal_toolbar.
    wal_toolbar-function = cg_button_log_download.
    wal_toolbar-icon = icon_export.
    wal_toolbar-text = 'Descargar log'.
    wal_toolbar-quickinfo = 'Descargar el log de la sesion como archivo local'.
    APPEND wal_toolbar TO e_object->mt_toolbar.

  ENDMETHOD. " handle_toolbar

  METHOD handle_user_command.

    CASE e_ucomm.

      WHEN cg_button_import.
        PERFORM f_import_selected_objects.
      WHEN cg_button_log.
        PERFORM f_display_log.
      WHEN cg_button_log_download.
        PERFORM f_download_log.

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

  CLEAR: gv_import_executed, tg_saved_source.

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
      codepage                = '4110'
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

  IF vl_version NE cg_xml_version AND vl_version NE '1.2' AND vl_version NE '1.1'.
    MESSAGE 'Versión XML no soportada.' TYPE 'E'.
  ENDIF.
  vg_input_version = vl_version.

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

  PERFORM f_get_child_value USING io_object_node 'source_object_type'
    CHANGING wal_object-source_object_type.
  PERFORM f_get_child_value USING io_object_node 'source_object_name'
    CHANGING wal_object-source_object_name.
  PERFORM f_get_child_value USING io_object_node 'relationship'
    CHANGING wal_object-relationship.
  PERFORM f_get_child_value USING io_object_node 'parent_type'
    CHANGING wal_object-parent_type.
  PERFORM f_get_child_value USING io_object_node 'parent_name'
    CHANGING wal_object-parent_name.
  PERFORM f_get_child_value USING io_object_node 'relation_reason'
    CHANGING wal_object-relation_reason.

  IF wal_object-source_object_type IS INITIAL.
    wal_object-source_object_type = wal_object-object_type.
  ENDIF.
  IF wal_object-source_object_name IS INITIAL.
    wal_object-source_object_name = wal_object-object_name.
  ENDIF.
  wal_object-target_object_name = wal_object-object_name.

  PERFORM f_get_child_value USING io_object_node 'original_system'
    CHANGING wal_object-original_system.

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
    OR lo_child->get_name( ) EQ 'program_payload'
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

      WHEN 'source_includes' OR 'includes'.
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
        vl_include TYPE progname,
        vl_customer TYPE abap_bool,
        vl_message TYPE string.

  lo_include = io_source_includes->get_first_child( ).

  WHILE lo_include IS BOUND.

    IF lo_include->get_name( ) EQ 'include'.

      CLEAR vl_include.

      PERFORM f_get_attribute_value USING lo_include 'name'
        CHANGING vl_include.

      IF is_object-object_type = 'PROG'.
        PERFORM f_is_customer_object USING 'PROG' vl_include is_object-original_system
          CHANGING vl_customer.
        IF vl_customer IS INITIAL OR CONV string( vl_include ) CS space.
          vl_message = |Include { vl_include } omitido: estandar o nombre no importable.|.
          PERFORM f_add_log USING is_object-object_type is_object-object_name
            'SOURCE_SKIP' cg_status_skip vl_message.
          lo_include = lo_include->get_next( ).
          CONTINUE.
        ENDIF.
      ENDIF.

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
      CONCATENATE cv_value vl_text INTO cv_value RESPECTING BLANKS.
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

  DATA: vl_devclass TYPE tdevc-devclass,
        wal_request TYPE e070.

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

  SELECT SINGLE * FROM e070 INTO wal_request WHERE trkorr EQ p_req.
  IF sy-subrc NE 0.
    MESSAGE 'La orden o tarea de transporte indicada no existe.' TYPE 'E'.
  ENDIF.

  IF wal_request-trfunction NE 'K' AND wal_request-trfunction NE 'W'.
    MESSAGE 'La orden indicada no es una orden o tarea Workbench.' TYPE 'E'.
  ENDIF.

  IF wal_request-trstatus NE 'D'.
    MESSAGE 'La orden o tarea de transporte no esta modificable.' TYPE 'E'.
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

    "A warning means that the exported object is usable but incomplete (for
    "example, a report with unavailable includes). Only an explicit export
    "error blocks the requested import.
    IF <fsl_object>-export_status EQ cg_status_err.
      <fsl_object>-light          = cg_icon_red.
      <fsl_object>-action         = 'Omitir'.
      <fsl_object>-import_status  = cg_status_err.
      <fsl_object>-import_message = 'El exportador informó un error para este objeto.'.
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
        wal_oo TYPE ty_oo_payload,
        wal_program_bundle TYPE ty_prog_bundle,
        vl_oo_error TYPE abap_bool,
        vl_oo_message TYPE string,
        vl_has_source TYPE abap_bool,
        vl_customer TYPE abap_bool.

  CLEAR: vl_payload, vl_has_source.

  IF cs_object-object_type IS INITIAL OR cs_object-object_name IS INITIAL.
    cs_object-light          = cg_icon_red.
    cs_object-action         = 'Omitir'.
    cs_object-import_status  = cg_status_err.
    cs_object-import_message = 'Lectura de objeto en XML incompleta: falta tipo o nombre.'.
    RETURN.
  ENDIF.

  PERFORM f_is_customer_object
    USING cs_object-object_type cs_object-object_name cs_object-original_system
    CHANGING vl_customer.
  IF vl_customer IS INITIAL.
    cs_object-action = 'Omitir'.
    PERFORM f_set_object_error
      USING 'Objeto SAP o sin datos suficientes para identificarlo como desarrollo propio.'
      CHANGING cs_object.
    RETURN.
  ENDIF.

  "Validate every source destination before any INSERT REPORT.
  LOOP AT tg_source INTO DATA(wal_namespace_source)
    WHERE object_type = cs_object-object_type
      AND object_name = cs_object-object_name.
    vl_customer = abap_true.
    IF cs_object-object_type = 'PROG'.
      PERFORM f_is_customer_object
        USING 'PROG' wal_namespace_source-include cs_object-original_system
        CHANGING vl_customer.
    ENDIF.
    IF vl_customer IS INITIAL.
      PERFORM f_set_object_error
        USING 'El XML contiene un destino de fuente SAP o de origen desconocido.'
        CHANGING cs_object.
      cs_object-action = 'Omitir'.
      RETURN.
    ELSEIF cs_object-object_type = 'FUGR'.
      IF wal_namespace_source-include <> |SAPL{ cs_object-object_name }|
      AND wal_namespace_source-include NP |L{ cs_object-object_name }*|.
        PERFORM f_set_object_error
          USING 'El XML contiene fuentes ajenas al grupo de funciones propio.'
          CHANGING cs_object.
        cs_object-action = 'Omitir'.
        RETURN.
      ENDIF.
    ENDIF.
  ENDLOOP.

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
      PERFORM f_read_prog_bundle USING cs_object
        CHANGING wal_program_bundle vl_oo_error vl_oo_message.
      IF vl_oo_error = abap_true.
        cs_object-action = 'Omitir'.
        PERFORM f_set_object_error USING vl_oo_message CHANGING cs_object.
        RETURN.
      ENDIF.
      PERFORM f_has_source_code USING cs_object
        CHANGING vl_has_source.

      IF vl_has_source IS INITIAL.
        cs_object-light          = cg_icon_red.
        cs_object-action         = 'Omitir'.
        cs_object-import_status  = cg_status_err.
        cs_object-import_message = 'Lectura de objeto en XML incompleta: falta source_code.'.
      ENDIF.

    WHEN 'CLAS' OR 'INTF'.
      PERFORM f_read_oo_payload USING cs_object
        CHANGING wal_oo vl_oo_error vl_oo_message.
      IF vl_oo_error = abap_true.
        cs_object-action = 'Omitir'.
        PERFORM f_set_object_error USING vl_oo_message CHANGING cs_object.
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
             object_name = is_object-object_name
             include = is_object-object_name.

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
        vl_object   TYPE tadir-object,
        vl_area     TYPE tlibg-area.

  CLEAR cs_object-exists_dest.

  vl_pgmid    = 'R3TR'.
  vl_obj_name = cs_object-target_object_name.
  IF vl_obj_name IS INITIAL.
    vl_obj_name = cs_object-object_name.
  ENDIF.

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
      "A deleted function group can leave a stale TADIR entry. TLIBG is
      "the authoritative runtime definition used by Function Builder.
      SELECT SINGLE area
        FROM tlibg
        INTO vl_area
        WHERE area EQ cs_object-object_name.
      IF sy-subrc EQ 0.
        cs_object-exists_dest = abap_true.
      ENDIF.
      RETURN.
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
      cs_object-import_priority = 55.
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
  PERFORM f_add_fieldcat USING 'TARGET_OBJECT_NAME' 'Nombre destino' 4 40 abap_false abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'RELATIONSHIP'   'Relacion'       4 12 abap_false abap_false CHANGING ct_fieldcat.
  PERFORM f_add_fieldcat USING 'PARENT_NAME'    'Objeto padre'   5 40 abap_false abap_false CHANGING ct_fieldcat.
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
  IF iv_fieldname = 'TARGET_OBJECT_NAME'.
    wal_fieldcat-edit = abap_true.
  ENDIF.

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

  IF go_grid IS BOUND.
    go_grid->check_changed_data( ).
  ENDIF.

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

  PERFORM f_validate_selected_dependencies.

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

  CLEAR: tg_saved_source, tg_component_activation.
  LOOP AT tg_objects ASSIGNING <fsl_object>.
    CLEAR: <fsl_object>-activation_pending, <fsl_object>-oo_prepared.
  ENDLOOP.

  LOOP AT tg_objects ASSIGNING <fsl_object>
    WHERE selected = abap_true AND import_status = cg_status_ready.
    IF <fsl_object>-object_type = 'CLAS' OR <fsl_object>-object_type = 'INTF'.
      PERFORM f_import_oo USING abap_true CHANGING <fsl_object>.
      IF <fsl_object>-import_status = cg_status_err.
        vl_imported = vl_imported + 1.
        PERFORM f_add_log USING <fsl_object>-object_type <fsl_object>-object_name
          'OO_CREATE' cg_status_err <fsl_object>-import_message.
      ENDIF.
    ENDIF.
  ENDLOOP.

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
        PERFORM f_import_oo USING abap_false CHANGING <fsl_object>.

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

  COMMIT WORK AND WAIT.
  PERFORM f_activate_saved_sources.

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

* A root must not be imported while an explicitly exported dependency of that
* root was left out of the current ALV selection.
FORM f_validate_selected_dependencies.
  FIELD-SYMBOLS: <root> TYPE ty_import_object,
                 <dependency> TYPE ty_import_object.
  LOOP AT tg_objects ASSIGNING <root>
    WHERE selected = abap_true AND relationship = 'ROOT'.
    LOOP AT tg_objects ASSIGNING <dependency>
      WHERE relationship = 'DEPENDENCY'
        AND parent_type = <root>-object_type
        AND parent_name = <root>-object_name.
      IF <dependency>-selected IS INITIAL.
        <root>-selected = abap_false.
        PERFORM f_set_object_error
          USING |Falta seleccionar dependencia { <dependency>-object_type } { <dependency>-object_name }.|
          CHANGING <root>.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.

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

      IF wal_dd01v-domname <> cs_object-object_name.
        PERFORM f_set_object_error
          USING 'El nombre del payload debe coincidir con el objeto del XML.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      IF cs_object-target_object_name IS NOT INITIAL.
        wal_dd01v-domname = cs_object-target_object_name.
      ENDIF.

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

      IF wal_dd04v-rollname <> cs_object-object_name.
        PERFORM f_set_object_error
          USING 'El nombre del payload debe coincidir con el objeto del XML.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      IF cs_object-target_object_name IS NOT INITIAL.
        wal_dd04v-rollname = cs_object-target_object_name.
      ENDIF.
      PERFORM f_map_ddic_reference USING 'DOMA' wal_dd04v-domname
        CHANGING wal_dd04v-domname.

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

      IF wal_dd02v-tabname <> cs_object-object_name.
        PERFORM f_set_object_error
          USING 'El nombre del payload debe coincidir con el objeto del XML.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      IF cs_object-target_object_name IS NOT INITIAL.
        wal_dd02v-tabname = cs_object-target_object_name.
      ENDIF.
      LOOP AT tl_dd03p ASSIGNING FIELD-SYMBOL(<field>). 
        PERFORM f_map_ddic_reference USING 'DTEL' <field>-rollname CHANGING <field>-rollname.
      ENDLOOP.

      CALL FUNCTION 'DDIF_TABL_PUT'
        EXPORTING
          name      = wal_dd02v-tabname
          dd02v_wa  = wal_dd02v
        TABLES
          dd03p_tab = tl_dd03p
          dd05m_tab = tl_dd05m
          dd08v_tab = tl_dd08v
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

FORM f_map_ddic_reference
  USING iv_type TYPE string iv_source TYPE tadir-obj_name
  CHANGING cv_target TYPE tadir-obj_name.
  READ TABLE tg_objects INTO DATA(wal_mapping)
    WITH KEY object_type = iv_type source_object_name = iv_source.
  IF sy-subrc = 0 AND wal_mapping-target_object_name IS NOT INITIAL.
    cv_target = wal_mapping-target_object_name.
  ENDIF.
ENDFORM.

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

      IF wal_dd30v-shlpname <> cs_object-object_name.
        PERFORM f_set_object_error
          USING 'El nombre del payload debe coincidir con el objeto del XML.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      IF cs_object-target_object_name IS NOT INITIAL.
        wal_dd30v-shlpname = cs_object-target_object_name.
      ENDIF.

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
  DATA: tl_source TYPE tyt_report_line,
        vl_program TYPE progname,
        vl_message TYPE string,
        vl_error TYPE abap_bool,
        vl_package_warning TYPE string,
        wal_bundle TYPE ty_prog_bundle,
        vl_program_type TYPE trdir-subc VALUE '1'.

  PERFORM f_read_prog_bundle USING cs_object
    CHANGING wal_bundle vl_error vl_message.
  IF vl_error = abap_true.
    PERFORM f_set_object_error USING vl_message CHANGING cs_object.
    RETURN.
  ENDIF.
  IF wal_bundle-format IS NOT INITIAL.
    vl_program_type = wal_bundle-program_type.
  ENDIF.

  vl_program = cs_object-object_name.
  SORT tg_source BY object_type object_name include line_number.
  LOOP AT tg_source INTO DATA(wal_source)
    WHERE object_type = cs_object-object_type
      AND object_name = cs_object-object_name.
    APPEND wal_source-source_line TO tl_source.
    AT END OF include.
      IF wal_source-include = vl_program.
        PERFORM f_save_inactive_source USING wal_source-include vl_program_type tl_source
          CHANGING cs_object.
      ELSE.
        PERFORM f_save_inactive_source USING wal_source-include 'I' tl_source
          CHANGING cs_object.
      ENDIF.
      IF cs_object-import_status = cg_status_err.
        RETURN.
      ENDIF.
      PERFORM f_register_program_package USING wal_source-include
        CHANGING vl_error vl_message.
      IF vl_error = abap_true.
        vl_package_warning = vl_message.
      ENDIF.
      CLEAR tl_source.
    ENDAT.
  ENDLOOP.

  PERFORM f_import_prog_bundle USING wal_bundle CHANGING cs_object.
  IF cs_object-components_incomplete = abap_true.
    IF wal_bundle-format IS INITIAL.
      cs_object-activation_pending = abap_true. "Keep source-only 1.1 activation compatible.
    ENDIF.
    PERFORM f_set_object_warning
      USING 'Fuentes guardados; hay componentes pendientes. Revise Ver log.' CHANGING cs_object.
    RETURN.
  ENDIF.
  IF vl_package_warning IS NOT INITIAL.
    PERFORM f_set_object_warning USING vl_package_warning CHANGING cs_object.
  ELSE.
    cs_object-activation_pending = abap_true.
    PERFORM f_set_object_warning
      USING 'Programa e includes guardados inactivos. Pendiente de activacion y validacion de dependencias.'
      CHANGING cs_object.
  ENDIF.

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

      IF wal_dd40v-typename <> cs_object-object_name.
        PERFORM f_set_object_error
          USING 'El nombre del payload debe coincidir con el objeto del XML.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      IF cs_object-target_object_name IS NOT INITIAL.
        wal_dd40v-typename = cs_object-target_object_name.
      ENDIF.

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
        wal_existing_function TYPE tfdir,
        vl_target_include TYPE progname,
        vl_interface_warning TYPE abap_bool,
        vl_tadir_function TYPE tadir-obj_name,
        vl_pool_name   TYPE tlibg-area,
        vl_function_pool TYPE rs38l-area,
        vl_srcsystem   TYPE tadir-srcsystem,
        vl_short_text  TYPE string,
        vl_is_tmg_group TYPE abap_bool,
        vl_incomplete_source TYPE abap_bool,
        vl_master_program TYPE progname,
        tl_tfdir       TYPE STANDARD TABLE OF tfdir,
        tl_tftit       TYPE STANDARD TABLE OF tftit,
        tl_enlfdir     TYPE STANDARD TABLE OF enlfdir,
        tl_fupararef   TYPE STANDARD TABLE OF fupararef,
        tl_import      TYPE STANDARD TABLE OF rsimp,
        tl_export      TYPE STANDARD TABLE OF rsexp,
        tl_changing    TYPE STANDARD TABLE OF rscha,
        tl_tables      TYPE STANDARD TABLE OF rstbl,
        tl_exceptions  TYPE STANDARD TABLE OF rsexc,
        wal_import TYPE rsimp,
        wal_export TYPE rsexp,
        wal_changing TYPE rscha,
        wal_tables TYPE rstbl,
        wal_exception TYPE rsexc,
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

      "The Uxx number is assigned by Function Builder in insertion order.
      "Use the exported sequence so each source body stays with its module.
      SORT tl_tfdir BY include funcname.

      "Table Maintenance Generator owns groups with TABLEFRAME_/TABLEPROC_
      "modules. Their generated metadata cannot be reconstructed safely as a
      "regular function group; regenerate them from SE54 after the table.
      LOOP AT tl_tfdir INTO DATA(wal_tmg_function).
        IF wal_tmg_function-funcname CP 'TABLEFRAME_*'
        OR wal_tmg_function-funcname CP 'TABLEPROC_*'.
          vl_is_tmg_group = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF vl_is_tmg_group EQ abap_true.
        PERFORM f_set_object_warning
          USING 'Grupo generado por mantenimiento de tablas. Active la tabla y regenere el mantenimiento en SE54; no se importa como FUGR.'
          CHANGING cs_object.
        RETURN.
      ENDIF.

      "Check all module destinations before creating the pool or includes.
      LOOP AT tl_tfdir INTO DATA(wal_namespace_function).
        IF wal_namespace_function-pname <> |SAPL{ cs_object-object_name }|.
          PERFORM f_set_object_error
            USING 'El payload contiene modulos ajenos al grupo.'
            CHANGING cs_object.
          RETURN.
        ENDIF.
        SELECT SINGLE pname FROM tfdir INTO @DATA(vl_existing_pool)
          WHERE funcname = @wal_namespace_function-funcname.
        IF sy-subrc = 0 AND vl_existing_pool <> wal_namespace_function-pname.
          PERFORM f_set_object_error
            USING 'El modulo existente pertenece a otro grupo; no se sobrescribe.'
            CHANGING cs_object.
          RETURN.
        ENDIF.
        IF wal_namespace_function-include CP 'L*'
        AND wal_namespace_function-include NP |L{ cs_object-object_name }U*|.
          PERFORM f_set_object_error
            USING 'El include del modulo no pertenece al grupo propio.'
            CHANGING cs_object.
          RETURN.
        ENDIF.
      ENDLOOP.

      "Create the function pool before inserting its function modules. The
      "standard API owns TFDIR/ENLFDIR and the generated Uxx includes.
      IF cs_object-exists_dest IS INITIAL.
        vl_pool_name  = cs_object-object_name.
        vl_short_text = cs_object-short_text.
        IF vl_short_text IS INITIAL.
          vl_short_text = |Grupo de funciones { cs_object-object_name }|.
        ENDIF.

        CALL FUNCTION 'FUNCTION_POOL_CREATE'
          EXPORTING
            pool_name = vl_pool_name
            short_text = vl_short_text
          EXCEPTIONS
            name_already_exists = 1
            name_not_correct    = 2
            OTHERS              = 3.
        IF sy-subrc NE 0 AND sy-subrc NE 1.
          PERFORM f_set_object_error
            USING 'No se pudo crear el grupo de funciones.'
            CHANGING cs_object.
          RETURN.
        ENDIF.
      ENDIF.

      "FUNCTION_POOL_CREATE creates the pool; register a new pool in the
      "requested package/transport before its function modules are inserted.
      IF cs_object-exists_dest IS INITIAL.
        SELECT SINGLE obj_name
          FROM tadir
          INTO vl_tadir_function
          WHERE pgmid    EQ 'R3TR'
            AND object   EQ 'FUGR'
            AND obj_name EQ cs_object-object_name.

        IF sy-subrc NE 0.
          vl_srcsystem = sy-sysid.
          CALL FUNCTION 'TR_TADIR_INTERFACE'
            EXPORTING
              wi_test_modus      = abap_false
              wi_tadir_pgmid     = 'R3TR'
              wi_tadir_object    = 'FUGR'
              wi_tadir_obj_name  = cs_object-object_name
              wi_tadir_srcsystem = vl_srcsystem
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
      ENDIF.

      SORT tg_source BY object_type object_name include line_number.
      SORT tl_fupararef BY funcname paramtype pposition.
      CONCATENATE 'L' cs_object-object_name INTO vl_prefix.

      LOOP AT tl_tfdir INTO DATA(wal_tfdir).
        CLEAR: tl_import, tl_export, tl_changing, tl_tables,
               tl_exceptions, tl_report_source, wal_existing_function,
               vl_target_include.
        LOOP AT tl_fupararef INTO DATA(wal_parameter)
          WHERE funcname = wal_tfdir-funcname AND r3state = 'A'.
          CASE wal_parameter-paramtype.
            WHEN 'I'.
              PERFORM f_map_function_parameter USING wal_parameter CHANGING wal_import.
              APPEND wal_import TO tl_import.
            WHEN 'E'.
              PERFORM f_map_function_parameter USING wal_parameter CHANGING wal_export.
              APPEND wal_export TO tl_export.
            WHEN 'C'.
              PERFORM f_map_function_parameter USING wal_parameter CHANGING wal_changing.
              APPEND wal_changing TO tl_changing.
            WHEN 'T'.
              PERFORM f_map_function_parameter USING wal_parameter CHANGING wal_tables.
              APPEND wal_tables TO tl_tables.
            WHEN 'X'.
              CLEAR wal_exception.
              wal_exception-exception = wal_parameter-parameter.
              APPEND wal_exception TO tl_exceptions.
          ENDCASE.
        ENDLOOP.

        IF wal_tfdir-include CP 'L*'.
          vl_include = wal_tfdir-include.
        ELSEIF wal_tfdir-include CP 'U*'.
          vl_include = |{ vl_prefix }{ wal_tfdir-include }|.
        ELSE.
          vl_include = |{ vl_prefix }U{ wal_tfdir-include }|.
        ENDIF.
        LOOP AT tg_source INTO DATA(wal_source)
          WHERE object_type = cs_object-object_type
            AND object_name = cs_object-object_name
            AND include = vl_include.
          "Keep the entire source, including FUNCTION/ENDFUNCTION and comments.
          APPEND wal_source-source_line TO tl_report_source.
        ENDLOOP.
        IF tl_report_source IS INITIAL.
          vl_incomplete_source = abap_true.
          vl_message = |Sin fuente XML para { wal_tfdir-funcname }.|.
          PERFORM f_add_log USING cs_object-object_type cs_object-object_name
            'FUNCTION' cg_status_err vl_message.
          CONTINUE.
        ENDIF.

        SELECT SINGLE * FROM tfdir INTO wal_existing_function
          WHERE funcname = wal_tfdir-funcname.
        IF sy-subrc = 0.
          "Use the destination include, never the source system's Uxx number.
          IF wal_existing_function-include CP 'U*'.
            vl_target_include = |{ vl_prefix }{ wal_existing_function-include }|.
          ELSEIF wal_existing_function-include CP 'L*'.
            vl_target_include = wal_existing_function-include.
          ELSE.
            vl_target_include = |{ vl_prefix }U{ wal_existing_function-include }|.
          ENDIF.
          vl_interface_warning = abap_true.
          vl_message = |{ wal_tfdir-funcname }: fuente actualizado; revisar interfaz existente en SE37.|.
          PERFORM f_add_log USING cs_object-object_type cs_object-object_name
            'INTERFACE' cg_status_warn vl_message.
        ELSE.
          READ TABLE tl_tftit INTO DATA(wal_tftit)
            WITH KEY funcname = wal_tfdir-funcname spras = sy-langu.
          IF sy-subrc <> 0.
            CLEAR wal_tftit.
            READ TABLE tl_tftit INTO wal_tftit WITH KEY funcname = wal_tfdir-funcname.
          ENDIF.
          vl_function_pool = cs_object-object_name.
          "Create metadata without compiling. Save the complete source below.
          CALL FUNCTION 'RS_FUNCTIONMODULE_INSERT'
            EXPORTING
              funcname = wal_tfdir-funcname
              function_pool = vl_function_pool
              short_text = wal_tftit-stext
              remote_call = wal_tfdir-fmode
              update_task = wal_tfdir-utask
              corrnum = p_req
              suppress_corr_check = abap_true
              save_active = abap_false
            IMPORTING
              function_include = vl_target_include
            TABLES
              import_parameter = tl_import
              export_parameter = tl_export
              changing_parameter = tl_changing
              tables_parameter = tl_tables
              exception_list = tl_exceptions
            EXCEPTIONS
              error_message = 1
              OTHERS = 2.
          IF sy-subrc <> 0 OR vl_target_include IS INITIAL.
            vl_incomplete_source = abap_true.
            CLEAR vl_message.
            IF sy-msgid IS NOT INITIAL.
              MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO vl_message.
            ENDIF.
            vl_message = |{ wal_tfdir-funcname }: no se pudo crear la interfaz. { vl_message }|.
            PERFORM f_add_log USING cs_object-object_type cs_object-object_name
              'FUNCTION' cg_status_err vl_message.
            CONTINUE.
          ENDIF.
        ENDIF.

        PERFORM f_save_inactive_source USING vl_target_include 'I' tl_report_source
          CHANGING cs_object.
        IF cs_object-import_status = cg_status_err.
          RETURN.
        ENDIF.
      ENDLOOP.

      "Restore auxiliary includes after Function Builder has created metadata.
      "Uxx/UXX are owned by Function Builder; module sources were saved above.
      CLEAR tl_report_source.
      LOOP AT tg_source INTO DATA(wal_aux_source)
        WHERE object_type = cs_object-object_type
          AND object_name = cs_object-object_name.
        IF wal_aux_source-include NP |{ vl_prefix }*|
        OR wal_aux_source-include CP |{ vl_prefix }U*|
        OR wal_aux_source-include CP |{ vl_prefix }$*|.
          CONTINUE.
        ENDIF.
        APPEND wal_aux_source-source_line TO tl_report_source.
        AT END OF include.
          PERFORM f_save_inactive_source USING wal_aux_source-include 'I' tl_report_source
            CHANGING cs_object.
          IF cs_object-import_status = cg_status_err.
            RETURN.
          ENDIF.
          CLEAR tl_report_source.
        ENDAT.
      ENDLOOP.

      vl_master_program = |SAPL{ cs_object-object_name }|.
      CLEAR tl_report_source.
      LOOP AT tg_source INTO DATA(wal_master_source)
        WHERE object_type = cs_object-object_type
          AND object_name = cs_object-object_name
          AND include = vl_master_program.
        APPEND wal_master_source-source_line TO tl_report_source.
      ENDLOOP.
      IF tl_report_source IS INITIAL.
        PERFORM f_set_object_error
          USING 'El XML no contiene el programa maestro SAPL del grupo.' CHANGING cs_object.
        RETURN.
      ENDIF.
      PERFORM f_save_inactive_source USING vl_master_program 'F' tl_report_source
        CHANGING cs_object.
      IF cs_object-import_status = cg_status_err.
        RETURN.
      ENDIF.
      IF vl_incomplete_source = abap_true.
        PERFORM f_set_object_warning
          USING 'Grupo guardado inactivo, pero hay modulos no creados o sin fuente. Revise el log.'
          CHANGING cs_object.
      ELSEIF vl_interface_warning = abap_true.
        PERFORM f_set_object_warning
          USING 'Fuentes guardados inactivos. Se conservaron interfaces existentes; revisarlas en SE37 antes de activar.'
          CHANGING cs_object.
      ELSE.
        cs_object-activation_pending = abap_true.
        PERFORM f_set_object_warning
          USING 'Grupo y modulos guardados inactivos. Pendiente de activacion y validacion de dependencias.'
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

* Repository ownership takes precedence over naming conventions.
FORM f_is_customer_object
  USING iv_type TYPE csequence
        iv_name TYPE csequence
        iv_origin TYPE csequence
  CHANGING cv_customer TYPE abap_bool.
  DATA: wal_tadir TYPE tadir,
        wal_entry TYPE e071,
        vl_type TYPE tadir-object.
  CLEAR cv_customer.
  IF iv_origin = 'SAP' OR iv_name IS INITIAL.
    RETURN.
  ENDIF.
  vl_type = iv_type.
  IF vl_type = 'STRU'.
    vl_type = 'TABL'.
  ENDIF.
  SELECT SINGLE * FROM tadir INTO wal_tadir
    WHERE pgmid = 'R3TR' AND object = vl_type AND obj_name = iv_name.
  IF sy-subrc <> 0 AND vl_type = 'PROG'.
    "Resolve includes without their own TADIR entry to the owning object.
    wal_entry-pgmid = 'LIMU'.
    wal_entry-object = 'REPS'.
    wal_entry-obj_name = iv_name.
    CALL FUNCTION 'TR_CHECK_TYPE'
      EXPORTING wi_e071 = wal_entry
      IMPORTING we_tadir = wal_tadir
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      CLEAR wal_tadir.
    ENDIF.
  ENDIF.
  IF wal_tadir-srcsystem IS NOT INITIAL.
    IF wal_tadir-srcsystem <> 'SAP'.
      cv_customer = abap_true.
    ENDIF.
    RETURN.
  ENDIF.
  IF iv_origin IS NOT INITIAL.
    IF iv_origin <> 'SAP'.
      cv_customer = abap_true.
    ENDIF.
  ELSEIF iv_name CP 'Z*' OR iv_name CP 'Y*'.
    "Compatibility with older XML lacking original_system.
    cv_customer = abap_true.
  ENDIF.
ENDFORM. " f_is_customer_object

* Preserve interface semantics when converting the legacy FUPARAREF payload.
FORM f_map_function_parameter
  USING is_parameter TYPE fupararef
  CHANGING cs_parameter TYPE any.
  FIELD-SYMBOLS <value> TYPE any.
  CLEAR cs_parameter.
  MOVE-CORRESPONDING is_parameter TO cs_parameter.
  ASSIGN COMPONENT 'TYPES' OF STRUCTURE cs_parameter TO <value>.
  IF sy-subrc = 0.
    <value> = is_parameter-type.
  ENDIF.
  ASSIGN COMPONENT 'DEFAULT' OF STRUCTURE cs_parameter TO <value>.
  IF sy-subrc = 0.
    <value> = is_parameter-defaultval.
  ENDIF.
  IF is_parameter-type = abap_true.
    ASSIGN COMPONENT 'TYP' OF STRUCTURE cs_parameter TO <value>.
  ELSEIF is_parameter-paramtype = 'T'.
    ASSIGN COMPONENT 'DBSTRUCT' OF STRUCTURE cs_parameter TO <value>.
  ELSE.
    ASSIGN COMPONENT 'DBFIELD' OF STRUCTURE cs_parameter TO <value>.
  ENDIF.
  IF sy-subrc = 0.
    <value> = is_parameter-structure.
  ENDIF.
ENDFORM.

* Never compile or replace an active source during the creation phase.
FORM f_save_inactive_source
  USING iv_program TYPE progname
        iv_program_type TYPE c
        it_source TYPE tyt_report_line
  CHANGING cs_object TYPE ty_import_object.
  DATA: vl_message TYPE string,
        lo_error TYPE REF TO cx_root.
  TRY.
      INSERT REPORT iv_program FROM it_source
        STATE 'I' PROGRAM TYPE iv_program_type.
      IF sy-subrc <> 0.
        vl_message = |No se pudo guardar inactivo { iv_program }. SY-SUBRC: { sy-subrc }|.
        PERFORM f_set_object_error USING vl_message CHANGING cs_object.
        RETURN.
      ENDIF.
      APPEND VALUE #( object_type = cs_object-object_type
                      object_name = cs_object-object_name
                      program = iv_program ) TO tg_saved_source.
      vl_message = |Fuente guardado inactivo: { iv_program }|.
      PERFORM f_add_log USING cs_object-object_type cs_object-object_name
        'SAVE_INACTIVE' cg_status_ok vl_message.
    CATCH cx_root INTO lo_error.
      vl_message = lo_error->get_text( ).
      PERFORM f_set_object_error USING vl_message CHANGING cs_object.
  ENDTRY.
ENDFORM.

* Activation is optional and starts only after all selected objects were saved.
FORM f_activate_saved_sources.
  DATA: tl_activation TYPE STANDARD TABLE OF dwinactiv,
        tl_inactive TYPE tyt_report_line,
        vl_subrc TYPE sy-subrc,
        vl_message TYPE string,
        vl_pending TYPE abap_bool,
        vl_result_message TYPE string,
        lo_error TYPE REF TO cx_root.
  FIELD-SYMBOLS <object> TYPE ty_import_object.
  IF p_activ IS INITIAL OR tg_saved_source IS INITIAL.
    RETURN.
  ENDIF.
  LOOP AT tg_saved_source INTO DATA(wal_saved).
    READ TABLE tg_objects ASSIGNING <object>
      WITH KEY object_type = wal_saved-object_type object_name = wal_saved-object_name.
    IF sy-subrc <> 0 OR <object>-activation_pending IS INITIAL.
      CONTINUE.
    ENDIF.
    IF <object>-object_type = 'CLAS' OR <object>-object_type = 'INTF'.
      APPEND VALUE #( object = <object>-object_type obj_name = <object>-object_name ) TO tl_activation.
    ENDIF.
    IF wal_saved-program IS NOT INITIAL.
      APPEND VALUE #( object = 'REPS' obj_name = wal_saved-program ) TO tl_activation.
    ENDIF.
    IF <object>-object_type = 'FUGR'.
      APPEND VALUE #( object = 'FUGR' obj_name = <object>-object_name ) TO tl_activation.
    ENDIF.
  ENDLOOP.
  LOOP AT tg_component_activation INTO DATA(wal_component_activation).
    READ TABLE tg_objects ASSIGNING <object>
      WITH KEY object_type = 'PROG' object_name = wal_component_activation-owner.
    IF sy-subrc = 0 AND <object>-activation_pending = abap_true.
      APPEND wal_component_activation-key TO tl_activation.
    ENDIF.
  ENDLOOP.
  IF tl_activation IS INITIAL.
    RETURN.
  ENDIF.
  SORT tl_activation BY object obj_name.
  DELETE ADJACENT DUPLICATES FROM tl_activation COMPARING object obj_name.
  TRY.
      CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
        TABLES objects = tl_activation
        EXCEPTIONS error_message = 1 OTHERS = 2.
      vl_subrc = sy-subrc.
      IF vl_subrc <> 0 AND sy-msgid IS NOT INITIAL.
        MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO vl_message.
      ENDIF.
    CATCH cx_root INTO lo_error.
      vl_subrc = 2.
      vl_message = lo_error->get_text( ).
  ENDTRY.
  COMMIT WORK AND WAIT.
  LOOP AT tg_objects ASSIGNING <object> WHERE activation_pending = abap_true.
    CLEAR vl_pending.
    LOOP AT tg_saved_source INTO wal_saved
      WHERE object_type = <object>-object_type AND object_name = <object>-object_name.
      IF wal_saved-program IS INITIAL.
        SELECT SINGLE obj_name FROM dwinactiv INTO @DATA(vl_pending_oo)
          WHERE object = @wal_saved-object_type AND obj_name = @wal_saved-object_name.
        IF sy-subrc = 0.
          vl_pending = abap_true.
          EXIT.
        ENDIF.
        CONTINUE.
      ENDIF.
      CLEAR tl_inactive.
      READ REPORT wal_saved-program INTO tl_inactive STATE 'I'.
      IF sy-subrc = 0.
        vl_pending = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
    LOOP AT tg_component_activation INTO wal_component_activation
      WHERE owner = <object>-object_name.
      SELECT SINGLE obj_name FROM dwinactiv INTO @DATA(vl_pending_component)
        WHERE object = @wal_component_activation-key-object
          AND obj_name = @wal_component_activation-key-obj_name.
      IF sy-subrc = 0.
        vl_pending = abap_true.
      ENDIF.
    ENDLOOP.
    IF vl_subrc <> 0 OR vl_pending = abap_true.
      vl_result_message = |Fuentes guardados; activacion incompleta. Revise sintaxis y dependencias en SAP. { vl_message }|.
      PERFORM f_set_object_warning USING vl_result_message CHANGING <object>.
    ELSEIF <object>-components_incomplete = abap_true.
      PERFORM f_set_object_warning
        USING 'Fuentes activados; XML anterior sin componentes adicionales. Vuelva a exportar.'
        CHANGING <object>.
    ELSE.
      <object>-activated = abap_true.
      PERFORM f_set_object_success USING 'Objeto importado y activado.' CHANGING <object>.
    ENDIF.
    PERFORM f_add_log USING <object>-object_type <object>-object_name
      'ACTIVATION' <object>-import_status <object>-import_message.
    CLEAR <object>-activation_pending.
  ENDLOOP.
ENDFORM.

FORM f_display_log.
  DATA: lo_log TYPE REF TO cl_salv_table,
        lo_error TYPE REF TO cx_salv_msg,
        vl_message TYPE string.
  IF tg_log IS INITIAL.
    MESSAGE 'No hay entradas en el log.' TYPE 'I'.
    RETURN.
  ENDIF.
  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = lo_log
                             CHANGING t_table = tg_log ).
      lo_log->get_columns( )->set_optimize( abap_true ).
      lo_log->set_screen_popup( start_column = 2 end_column = 150
                               start_line = 2 end_line = 25 ).
      lo_log->display( ).
    CATCH cx_salv_msg INTO lo_error.
      vl_message = lo_error->get_text( ).
      MESSAGE vl_message TYPE 'I'.
  ENDTRY.
ENDFORM.

FORM f_download_log.
  DATA: tl_file TYPE STANDARD TABLE OF string WITH EMPTY KEY,
        vl_file TYPE string,
        vl_path TYPE string,
        vl_fullpath TYPE string,
        vl_action TYPE i.
  IF tg_log IS INITIAL.
    MESSAGE 'No hay entradas en el log para descargar.' TYPE 'I'.
    RETURN.
  ENDIF.
  APPEND 'OBJECT_TYPE;OBJECT_NAME;STEP;STATUS;MESSAGE' TO tl_file.
  LOOP AT tg_log INTO DATA(wal_log).
    APPEND |{ wal_log-object_type };{ wal_log-object_name };{ wal_log-step };{ wal_log-status };{ wal_log-message }| TO tl_file.
  ENDLOOP.
  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING default_extension = 'csv'
              default_file_name = |XML_IMPORT_LOG_{ sy-datum }_{ sy-uzeit }.csv|
              file_filter = 'CSV Files (*.csv)|*.csv|All Files (*.*)|*.*|'
    CHANGING filename = vl_file path = vl_path fullpath = vl_fullpath user_action = vl_action
    EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc <> 0 OR vl_action = cl_gui_frontend_services=>action_cancel.
    RETURN.
  ENDIF.
  cl_gui_frontend_services=>gui_download(
    EXPORTING filename = vl_fullpath filetype = 'ASC' codepage = '4110'
    CHANGING data_tab = tl_file
    EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc <> 0.
    MESSAGE 'No se pudo descargar el log de importacion.' TYPE 'I' DISPLAY LIKE 'E'.
  ELSE.
    MESSAGE |Log descargado: { vl_fullpath }| TYPE 'S'.
  ENDIF.
ENDFORM.

* Validate source-based payloads before any repository change.
FORM f_read_oo_payload
  USING is_object TYPE ty_import_object
  CHANGING cs_oo TYPE ty_oo_payload
           cv_error TYPE abap_bool
           cv_message TYPE string.
  DATA: vl_payload TYPE string,
        vl_xml TYPE xstring,
        lo_error TYPE REF TO cx_root.
  CLEAR: cs_oo, cv_error, cv_message.
  PERFORM f_get_payload USING is_object 'seo_payload' CHANGING vl_payload.
  PERFORM f_decode_payload USING vl_payload CHANGING vl_xml cv_error cv_message.
  IF cv_error = abap_true.
    RETURN.
  ENDIF.
  TRY.
      CALL TRANSFORMATION id SOURCE XML vl_xml RESULT oo = cs_oo.
      IF cs_oo-format <> 'OO_SOURCE_1' OR cs_oo-source IS INITIAL.
        cv_error = abap_true.
        cv_message = 'Payload OO antiguo o incompleto. Vuelva a exportar la clase/interfaz.'.
      ELSEIF cs_oo-object_name <> is_object-object_name
          OR cs_oo-object_type <> is_object-object_type.
        cv_error = abap_true.
        cv_message = 'La identidad del payload OO no coincide con el objeto XML.'.
      ELSEIF is_object-object_type = 'CLAS'
         AND cs_oo-class_properties-clsname <> is_object-object_name.
        cv_error = abap_true.
        cv_message = 'Nombre de clase inconsistente en las propiedades OO.'.
      ELSEIF is_object-object_type = 'INTF'
         AND cs_oo-interface_properties-clsname <> is_object-object_name.
        cv_error = abap_true.
        cv_message = 'Nombre de interfaz inconsistente en las propiedades OO.'.
      ENDIF.
    CATCH cx_root INTO lo_error.
      cv_error = abap_true.
      cv_message = |Payload OO no compatible; vuelva a exportar. { lo_error->get_text( ) }|.
  ENDTRY.
ENDFORM.

FORM f_import_oo
  USING iv_shell_only TYPE abap_bool
  CHANGING cs_object TYPE ty_import_object.
  DATA: wal_oo TYPE ty_oo_payload,
        wal_key TYPE seoclskey,
        vl_error TYPE abap_bool,
        vl_message TYPE string,
        vl_include TYPE progname,
        tl_local TYPE tyt_report_line,
        lo_factory TYPE REF TO object,
        lo_source TYPE REF TO object,
        lo_error TYPE REF TO cx_root,
        vl_locked TYPE abap_bool,
        vl_saved TYPE abap_bool.
  PERFORM f_read_oo_payload USING cs_object CHANGING wal_oo vl_error vl_message.
  IF vl_error = abap_true.
    PERFORM f_set_object_error USING vl_message CHANGING cs_object.
    RETURN.
  ENDIF.
  wal_key-clsname = wal_oo-object_name.
  TRY.
      IF cs_object-oo_prepared IS INITIAL.
        IF cs_object-object_type = 'CLAS'.
          wal_oo-class_properties-version = '0'.
          wal_oo-class_properties-state = '1'.
          CALL FUNCTION 'SEO_CLASS_CREATE_COMPLETE'
            EXPORTING devclass = vg_package corrnr = p_req
                      version = '0' overwrite = p_overw suppress_dialog = abap_true
            CHANGING class = wal_oo-class_properties
            EXCEPTIONS error_message = 1 OTHERS = 2.
        ELSE.
          wal_oo-interface_properties-version = '0'.
          wal_oo-interface_properties-state = '1'.
          CALL FUNCTION 'SEO_INTERFACE_CREATE_COMPLETE'
            EXPORTING devclass = vg_package corrnr = p_req
                      version = '0' overwrite = p_overw suppress_dialog = abap_true
            CHANGING interface = wal_oo-interface_properties
            EXCEPTIONS error_message = 1 OTHERS = 2.
        ENDIF.
        IF sy-subrc <> 0.
          vl_message = |No se pudo crear la definicion OO inactiva. SY-SUBRC: { sy-subrc }|.
          IF sy-msgid IS NOT INITIAL.
            MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO vl_message.
          ENDIF.
          PERFORM f_set_object_error USING vl_message CHANGING cs_object.
          RETURN.
        ENDIF.
        cs_object-oo_prepared = abap_true.
      ENDIF.
      IF iv_shell_only = abap_true.
        RETURN.
      ENDIF.

      CALL FUNCTION 'SEO_BUFFER_REFRESH' EXPORTING cifkey = wal_key version = '0'.
      CALL METHOD ('CL_OO_FACTORY')=>('CREATE_INSTANCE') RECEIVING result = lo_factory.
      CALL METHOD lo_factory->('CREATE_CLIF_SOURCE')
        EXPORTING clif_name = wal_key-clsname version = 'I'
        RECEIVING result = lo_source.
      CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~LOCK').
      vl_locked = abap_true.

      IF cs_object-object_type = 'CLAS'.
        "These four destinations are derived by SAP, never taken from XML.
        vl_include = cl_oo_classname_service=>get_ccdef_name( wal_key-clsname ).
        tl_local = wal_oo-locals_def.
        PERFORM f_save_inactive_source USING vl_include 'I' tl_local CHANGING cs_object.
        IF cs_object-import_status = cg_status_err.
          CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~UNLOCK').
          RETURN.
        ENDIF.
        vl_include = cl_oo_classname_service=>get_ccimp_name( wal_key-clsname ).
        tl_local = wal_oo-locals_imp.
        PERFORM f_save_inactive_source USING vl_include 'I' tl_local CHANGING cs_object.
        IF cs_object-import_status = cg_status_err.
          CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~UNLOCK').
          RETURN.
        ENDIF.
        vl_include = cl_oo_classname_service=>get_ccmac_name( wal_key-clsname ).
        tl_local = wal_oo-macros.
        PERFORM f_save_inactive_source USING vl_include 'I' tl_local CHANGING cs_object.
        IF cs_object-import_status = cg_status_err.
          CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~UNLOCK').
          RETURN.
        ENDIF.
        vl_include = cl_oo_classname_service=>get_ccau_name( wal_key-clsname ).
        tl_local = wal_oo-testclasses.
        PERFORM f_save_inactive_source USING vl_include 'I' tl_local CHANGING cs_object.
        IF cs_object-import_status = cg_status_err.
          CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~UNLOCK').
          RETURN.
        ENDIF.
      ENDIF.

      CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~SET_SOURCE') EXPORTING source = wal_oo-source.
      CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~SAVE').
      vl_saved = abap_true.
      CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~UNLOCK').
      vl_locked = abap_false.
      IF cs_object-object_type = 'CLAS'.
        vl_include = cl_oo_classname_service=>get_classpool_name( wal_key-clsname ).
        INSERT TEXTPOOL vl_include FROM wal_oo-textpool
          LANGUAGE wal_oo-textpool_language STATE 'I'.
        IF sy-subrc <> 0.
          PERFORM f_set_object_warning
            USING 'Fuente OO guardado inactivo, pero no se pudo guardar el textpool.'
            CHANGING cs_object.
          RETURN.
        ENDIF.
      ENDIF.
      APPEND VALUE #( object_type = cs_object-object_type
                      object_name = cs_object-object_name ) TO tg_saved_source.
      cs_object-activation_pending = abap_true.
      PERFORM f_set_object_warning
        USING 'Clase/interfaz guardada inactiva. Activacion pendiente de sintaxis y dependencias.'
        CHANGING cs_object.
    CATCH cx_root INTO lo_error.
      vl_message = lo_error->get_text( ).
      IF vl_locked = abap_true AND lo_source IS BOUND.
        TRY.
            CALL METHOD lo_source->('IF_OO_CLIF_SOURCE~UNLOCK').
          CATCH cx_root.
            "Retain the original save error in the log.
        ENDTRY.
      ENDIF.
      CLEAR cs_object-activation_pending.
      IF vl_saved = abap_true.
        PERFORM f_set_object_warning USING vl_message CHANGING cs_object.
      ELSE.
        vl_message = |No se completo el guardado OO; revise la definicion inactiva. { vl_message }|.
        PERFORM f_set_object_error USING vl_message CHANGING cs_object.
      ENDIF.
  ENDTRY.
ENDFORM.

FORM f_read_prog_bundle
  USING is_object TYPE ty_import_object
  CHANGING cs_bundle TYPE ty_prog_bundle cv_error TYPE abap_bool cv_message TYPE string.
  DATA: vl_payload TYPE string, vl_xml TYPE xstring.
  CLEAR: cs_bundle, cv_error, cv_message.
  PERFORM f_get_payload USING is_object 'program_payload' CHANGING vl_payload.
  IF vl_payload IS INITIAL.
    IF vg_input_version = '1.2'.
      cv_error = abap_true.
      cv_message = 'El XML 1.2 requiere program_payload para cada PROG.'.
    ENDIF.
    RETURN. "Compatibility with source-only 1.1 exports.
  ENDIF.
  PERFORM f_decode_payload USING vl_payload CHANGING vl_xml cv_error cv_message.
  IF cv_error = abap_true.
    RETURN.
  ENDIF.
  TRY.
      CALL TRANSFORMATION id SOURCE XML vl_xml RESULT bundle = cs_bundle.
      IF cs_bundle-format <> 'PROGRAM_COMPONENTS_1'
        OR cs_bundle-program <> is_object-object_name
        OR cs_bundle-program_type IS INITIAL
        OR cs_bundle-program_type CN '1IMSFJK'.
        cv_error = abap_true.
        cv_message = 'Formato, identidad o tipo de programa invalido en program_payload.'.
      ENDIF.
    CATCH cx_root INTO DATA(lo_error).
      cv_error = abap_true.
      cv_message = lo_error->get_text( ).
  ENDTRY.
ENDFORM.

FORM f_component_log
  USING is_part TYPE ty_prog_component iv_error TYPE string
  CHANGING cs_object TYPE ty_import_object.
  DATA: vl_message TYPE string, vl_status TYPE string.
  IF iv_error IS INITIAL.
    vl_status = cg_status_ok.
    vl_message = |{ is_part-name } { is_part-language }: componente guardado.|.
  ELSE.
    cs_object-components_incomplete = abap_true.
    vl_status = cg_status_warn.
    vl_message = |{ is_part-name } { is_part-language }: { iv_error }|.
  ENDIF.
  PERFORM f_add_log USING cs_object-object_type cs_object-object_name
    is_part-kind vl_status vl_message.
ENDFORM.

FORM f_queue_component
  USING iv_owner TYPE tadir-obj_name iv_type TYPE dwinactiv-object
        iv_name TYPE dwinactiv-obj_name.
  APPEND VALUE #( owner = iv_owner key-object = iv_type key-obj_name = iv_name )
    TO tg_component_activation.
ENDFORM.

FORM f_import_prog_bundle
  USING is_bundle TYPE ty_prog_bundle
  CHANGING cs_object TYPE ty_import_object.
  DATA: wal_screen TYPE ty_prog_screen,
        wal_cua TYPE ty_prog_cua,
        wal_doc TYPE ty_prog_doc,
        tl_textpool TYPE STANDARD TABLE OF textpool WITH DEFAULT KEY,
        wal_tr_key TYPE trkey,
        tl_screen_parameters TYPE STANDARD TABLE OF d023s WITH DEFAULT KEY,
        vl_name TYPE dwinactiv-obj_name,
        vl_program TYPE progname,
        vl_message TYPE string,
        vl_state TYPE c LENGTH 1,
        vl_main_language TYPE sylangu,
        vl_original_tcode TYPE sy-tcode,
        vl_subrc TYPE sy-subrc.
  CLEAR cs_object-components_incomplete.
  IF is_bundle-format IS INITIAL.
    cs_object-components_incomplete = abap_true.
    PERFORM f_add_log USING 'PROG' cs_object-object_name 'COMPONENTS' cg_status_warn
      'XML anterior: solo fuentes; vuelva a exportar para obtener componentes del programa.'.
    RETURN.
  ENDIF.
  SELECT SINGLE masterlang FROM tadir INTO vl_main_language
    WHERE pgmid = 'R3TR' AND object = 'PROG' AND obj_name = cs_object-object_name.
  IF vl_main_language IS INITIAL.
    vl_main_language = cs_object-original_lang.
  ENDIF.
  LOOP AT is_bundle-components INTO DATA(wal_part).
    CLEAR: vl_message, wal_screen, wal_cua, wal_doc, tl_textpool.
    CLEAR: sy-msgid, sy-msgno, sy-msgv1, sy-msgv2, sy-msgv3, sy-msgv4.
    IF wal_part-error IS NOT INITIAL.
      PERFORM f_component_log USING wal_part wal_part-error CHANGING cs_object.
      CONTINUE.
    ENDIF.
    TRY.
        IF wal_part-content IS INITIAL.
          vl_message = 'Payload de componente vacio.'.
        ELSE.
          CASE wal_part-kind.
            WHEN 'TEXTPOOL' OR 'DOCU'.
              "Only programs actually saved for this owner may receive texts.
              READ TABLE tg_saved_source TRANSPORTING NO FIELDS
                WITH KEY object_type = 'PROG' object_name = cs_object-object_name
                         program = wal_part-name.
              IF sy-subrc <> 0 OR wal_part-language IS INITIAL.
                vl_message = 'El texto no pertenece a un fuente guardado o falta idioma.'.
              ELSEIF wal_part-kind = 'TEXTPOOL'.
                CALL TRANSFORMATION id SOURCE XML wal_part-content RESULT texts = tl_textpool.
                vl_program = wal_part-name.
                vl_state = 'I'.
                IF wal_part-language <> vl_main_language.
                  vl_state = 'A'. "SAP stores translations independently of source activation.
                ENDIF.
                INSERT TEXTPOOL vl_program FROM tl_textpool LANGUAGE wal_part-language STATE vl_state.
                IF sy-subrc <> 0.
                  vl_message = 'INSERT TEXTPOOL fallo.'.
                ELSEIF vl_state = 'I'.
                  vl_name = vl_program.
                  PERFORM f_queue_component USING cs_object-object_name 'REPT' vl_name.
                ENDIF.
              ELSE.
                CALL TRANSFORMATION id SOURCE XML wal_part-content RESULT document = wal_doc.
                IF wal_doc-info-id <> 'RE' OR wal_doc-info-object <> wal_part-name
                  OR wal_doc-info-langu <> wal_part-language.
                  vl_message = 'Identidad de documentacion incompatible.'.
                ELSE.
                  "Derive the write key from validated identity, never from XML THEAD.
                  wal_doc-head-tdobject = 'DOKU'.
                  wal_doc-head-tdid = 'RE'.
                  wal_doc-head-tdname = wal_part-name.
                  wal_doc-head-tdspras = wal_part-language.
                  CALL FUNCTION 'DOCU_UPDATE'
                    EXPORTING head = wal_doc-head state = 'A' typ = wal_doc-info-typ
                              version = wal_doc-info-version
                              no_masterlang = xsdbool( wal_doc-info-masterlang IS INITIAL )
                    TABLES line = wal_doc-lines
                    EXCEPTIONS error_message = 1 OTHERS = 2.
                  IF sy-subrc <> 0.
                    vl_message = 'DOCU_UPDATE fallo.'.
                  ENDIF.
                ENDIF.
              ENDIF.
            WHEN 'DYNP'.
              CALL TRANSFORMATION id SOURCE XML wal_part-content RESULT screen = wal_screen.
              IF wal_screen-header-program <> is_bundle-program
                OR wal_screen-header-screen <> wal_part-name
                OR wal_screen-header-screen IS INITIAL.
                vl_message = 'Identidad de dynpro incompatible.'.
              ELSE.
                "Do not generate screens while dependent types may still be missing.
                READ TABLE wal_screen-native_fields TRANSPORTING NO FIELDS WITH KEY fill = 'X'.
                IF sy-subrc = 0 AND wal_screen-header-type CA 'IN'.
                  wal_screen-native_header-prog = is_bundle-program.
                  wal_screen-native_header-dnum = wal_screen-header-screen.
                  wal_screen-native_header-dgen = sy-datum.
                  wal_screen-native_header-tgen = sy-uzeit.
                  CALL FUNCTION 'RPY_DYNPRO_INSERT_NATIVE'
                    EXPORTING header = wal_screen-native_header dynprotext = wal_screen-header-descript
                    TABLES fieldlist = wal_screen-native_fields flowlogic = wal_screen-flow
                           params = tl_screen_parameters
                    EXCEPTIONS error_message = 1 OTHERS = 2.
                ELSE.
                  LOOP AT wal_screen-fields ASSIGNING FIELD-SYMBOL(<screen_field>).
                    IF <screen_field>-param_id IS NOT INITIAL AND <screen_field>-from_dict = abap_true.
                      IF <screen_field>-set_param IS INITIAL.
                        <screen_field>-set_param = '/'.
                      ENDIF.
                      IF <screen_field>-get_param IS INITIAL.
                        <screen_field>-get_param = '/'.
                      ENDIF.
                    ENDIF.
                    IF <screen_field>-foreignkey IS INITIAL.
                      <screen_field>-foreignkey = '/'.
                    ENDIF.
                  ENDLOOP.
                  CALL FUNCTION 'RPY_DYNPRO_INSERT'
                    EXPORTING header = wal_screen-header suppress_exist_checks = abap_true
                              suppress_generate = abap_true
                    TABLES containers = wal_screen-containers
                           fields_to_containers = wal_screen-fields flow_logic = wal_screen-flow
                    EXCEPTIONS error_message = 1 OTHERS = 2.
                ENDIF.
                IF sy-subrc <> 0.
                  vl_message = 'RPY_DYNPRO_INSERT fallo; dynpro pendiente.'.
                ELSE.
                  LOOP AT wal_screen-texts ASSIGNING FIELD-SYMBOL(<screen_text>).
                    <screen_text>-prog = is_bundle-program.
                    <screen_text>-dynr = wal_screen-header-screen.
                  ENDLOOP.
                  IF wal_screen-texts IS NOT INITIAL.
                    MODIFY d021t FROM TABLE wal_screen-texts.
                    IF sy-subrc <> 0.
                      vl_message = 'No se pudieron guardar las traducciones del dynpro.'.
                    ENDIF.
                  ENDIF.
                  CONCATENATE wal_screen-header-program wal_screen-header-screen
                    INTO vl_name RESPECTING BLANKS.
                  PERFORM f_queue_component USING cs_object-object_name 'DYNP' vl_name.
                ENDIF.
              ENDIF.
            WHEN 'CUAD'.
              IF wal_part-name <> is_bundle-program OR wal_part-language IS INITIAL.
                vl_message = 'Identidad o idioma CUA incompatible.'.
              ELSE.
                CALL TRANSFORMATION id SOURCE XML wal_part-content RESULT cua = wal_cua.
                CLEAR wal_tr_key.
                wal_tr_key-devclass = vg_package.
                wal_tr_key-obj_type = 'PROG'.
                wal_tr_key-obj_name = cs_object-object_name.
                wal_tr_key-sub_type = 'CUAD'.
                wal_tr_key-sub_name = is_bundle-program.
                vl_original_tcode = sy-tcode.
                sy-tcode = 'SE41'.
                TRY.
                    CALL FUNCTION 'RS_CUA_INTERNAL_WRITE'
                      EXPORTING program = is_bundle-program language = wal_part-language
                                tr_key = wal_tr_key adm = wal_cua-adm state = 'I'
                      TABLES sta = wal_cua-sta fun = wal_cua-fun men = wal_cua-men
                             mtx = wal_cua-mtx act = wal_cua-act but = wal_cua-but
                             pfk = wal_cua-pfk set = wal_cua-set doc = wal_cua-doc
                             tit = wal_cua-tit biv = wal_cua-biv
                      EXCEPTIONS error_message = 1 OTHERS = 2.
                    vl_subrc = sy-subrc.
                  CLEANUP.
                    sy-tcode = vl_original_tcode.
                ENDTRY.
                sy-tcode = vl_original_tcode.
                IF vl_subrc <> 0.
                  vl_message = 'RS_CUA_INTERNAL_WRITE fallo.'.
                ELSE.
                  vl_name = is_bundle-program.
                  PERFORM f_queue_component USING cs_object-object_name 'CUAD' vl_name.
                ENDIF.
              ENDIF.
            WHEN 'DYNTEXT'.
              PERFORM f_import_dynpro_titles USING wal_part is_bundle CHANGING vl_message.
            WHEN 'TRAN'.
              PERFORM f_import_program_transaction USING wal_part is_bundle-program
                CHANGING vl_message.
            WHEN 'ENHO'.
              PERFORM f_import_program_enhancement USING wal_part
                CHANGING cs_object vl_message.
            WHEN 'ENHS'.
              PERFORM f_import_program_spot USING wal_part
                CHANGING cs_object vl_message.
            WHEN OTHERS.
              vl_message = 'Clase de componente no soportada; no se modifico el repositorio.'.
          ENDCASE.
        ENDIF.
        IF vl_message IS NOT INITIAL AND sy-msgid IS NOT INITIAL.
          "Do not replace the component identity with a generic SAP error.
          vl_message = |{ vl_message } { sy-msgid }-{ sy-msgno } { sy-msgv1 } { sy-msgv2 } { sy-msgv3 } { sy-msgv4 }|.
        ENDIF.
      CATCH cx_root INTO DATA(lo_error).
        vl_message = lo_error->get_text( ).
    ENDTRY.
    PERFORM f_component_log USING wal_part vl_message CHANGING cs_object.
  ENDLOOP.
ENDFORM.

FORM f_import_dynpro_titles
  USING is_part TYPE ty_prog_component is_bundle TYPE ty_prog_bundle
  CHANGING cv_message TYPE string.
  DATA: lr_titles TYPE REF TO data,
        vl_table TYPE tabname VALUE 'D020T',
        vl_screen TYPE sy-dynnr.
  FIELD-SYMBOLS: <titles> TYPE STANDARD TABLE, <title> TYPE any,
                 <program> TYPE any, <number> TYPE any.
  CLEAR cv_message.
  IF is_part-name <> is_bundle-program.
    cv_message = 'Los titulos de pantalla no pertenecen al programa.'.
    RETURN.
  ENDIF.
  CREATE DATA lr_titles TYPE STANDARD TABLE OF (vl_table).
  ASSIGN lr_titles->* TO <titles>.
  CALL TRANSFORMATION id SOURCE XML is_part-content RESULT titles = <titles>.
  LOOP AT <titles> ASSIGNING <title>.
    ASSIGN COMPONENT 'PROG' OF STRUCTURE <title> TO <program>.
    IF sy-subrc <> 0.
      cv_message = 'Clave de programa desconocida en D020T.'.
      RETURN.
    ENDIF.
    <program> = is_bundle-program.
    ASSIGN COMPONENT 'DYNR' OF STRUCTURE <title> TO <number>.
    IF sy-subrc <> 0.
      ASSIGN COMPONENT 'DNUM' OF STRUCTURE <title> TO <number>.
    ENDIF.
    IF sy-subrc <> 0.
      cv_message = 'Clave de dynpro desconocida en D020T.'.
      RETURN.
    ENDIF.
    vl_screen = <number>.
    READ TABLE is_bundle-components TRANSPORTING NO FIELDS WITH KEY kind = 'DYNP' name = vl_screen.
    IF sy-subrc <> 0.
      cv_message = 'Titulo asociado a un dynpro no incluido en el XML.'.
      RETURN.
    ENDIF.
  ENDLOOP.
  IF <titles> IS NOT INITIAL.
    MODIFY (vl_table) FROM TABLE <titles>.
    IF sy-subrc <> 0.
      cv_message = 'No se pudieron guardar los titulos traducidos de los dynpros.'.
    ENDIF.
  ENDIF.
ENDFORM.

FORM f_import_program_spot
  USING is_part TYPE ty_prog_component
  CHANGING cs_object TYPE ty_import_object cv_message TYPE string.
  DATA: wal_spot TYPE ty_prog_enhs,
        vl_customer TYPE abap_bool,
        vl_name TYPE enhspotname,
        vl_package TYPE devclass,
        vl_activation_name TYPE dwinactiv-obj_name,
        li_spot TYPE REF TO if_enh_spot_tool,
        li_object TYPE REF TO if_enh_object,
        li_docu TYPE REF TO if_enh_object_docu,
        lo_definition TYPE REF TO cl_enh_tool_hook_def,
        wal_definition TYPE enh_hook_def.
  CLEAR cv_message.
  PERFORM f_is_customer_object USING 'ENHS' is_part-name is_part-original_system
    CHANGING vl_customer.
  IF vl_customer IS INITIAL.
    cv_message = 'Enhancement spot no identificado como desarrollo del cliente.'.
    RETURN.
  ENDIF.
  CALL TRANSFORMATION id SOURCE XML is_part-content RESULT spot = wal_spot.
  IF ( wal_spot-pgmid <> 'R3TR' AND wal_spot-pgmid <> 'LIMU' )
    OR ( wal_spot-main_type <> 'PROG' AND wal_spot-main_type <> 'REPS' )
    OR ( wal_spot-obj_type <> 'PROG' AND wal_spot-obj_type <> 'REPS' ).
    cv_message = 'Tipo de objeto original incompatible en ENHS.'.
    RETURN.
  ENDIF.
  READ TABLE tg_saved_source TRANSPORTING NO FIELDS
    WITH KEY object_type = 'PROG' object_name = cs_object-object_name program = wal_spot-program.
  IF sy-subrc <> 0.
    cv_message = 'Programa del enhancement spot fuera de los fuentes importados.'.
    RETURN.
  ENDIF.
  READ TABLE tg_saved_source TRANSPORTING NO FIELDS
    WITH KEY object_type = 'PROG' object_name = cs_object-object_name program = wal_spot-obj_name.
  IF sy-subrc <> 0.
    cv_message = 'Objeto original del enhancement spot fuera de los fuentes importados.'.
    RETURN.
  ENDIF.
  READ TABLE tg_saved_source TRANSPORTING NO FIELDS
    WITH KEY object_type = 'PROG' object_name = cs_object-object_name program = wal_spot-main_name.
  IF sy-subrc <> 0.
    cv_message = 'Objeto principal del enhancement spot fuera de los fuentes importados.'.
    RETURN.
  ENDIF.
  vl_name = is_part-name.
  TRY.
      li_spot = cl_enh_factory=>get_enhancement_spot( spot_name = vl_name run_dark = abap_true ).
    CATCH cx_enh_root.
      CLEAR li_spot.
  ENDTRY.
  IF li_spot IS BOUND.
    cv_message = 'Enhancement spot existente: se conserva; revisar diferencias en SE80.'.
    RETURN.
  ENDIF.
  PERFORM f_register_prog_related USING 'ENHS' is_part-name CHANGING cv_message.
  IF cv_message IS NOT INITIAL.
    RETURN.
  ENDIF.
  TRY.
      vl_package = vg_package.
      cl_enh_factory=>create_enhancement_spot(
        EXPORTING spot_name = vl_name tooltype = cl_enh_tool_hook_def=>tool_type
                  dark = abap_true
        IMPORTING spot = li_spot CHANGING devclass = vl_package ).
      li_object ?= li_spot.
      li_docu ?= li_spot.
      lo_definition ?= li_spot.
      li_docu->set_shorttext( wal_spot-shorttext ).
      lo_definition->set_original_object(
        pgmid = wal_spot-pgmid obj_name = wal_spot-obj_name obj_type = wal_spot-obj_type
        program = wal_spot-program main_type = wal_spot-main_type main_name = wal_spot-main_name ).
      LOOP AT wal_spot-definitions INTO DATA(wal_source_definition).
        CLEAR wal_definition.
        MOVE-CORRESPONDING wal_source_definition TO wal_definition.
        lo_definition->add_hook_def( wal_definition ).
      ENDLOOP.
      li_object->save( run_dark = abap_true ).
      li_object->unlock( ).
      vl_activation_name = is_part-name.
      PERFORM f_queue_component USING cs_object-object_name 'ENHS' vl_activation_name.
    CATCH cx_root INTO DATA(lo_error).
      cv_message = lo_error->get_text( ).
      IF li_object IS BOUND.
        TRY.
            li_object->unlock( ).
          CATCH cx_root.
        ENDTRY.
      ENDIF.
  ENDTRY.
ENDFORM.

FORM f_import_program_transaction
  USING is_part TYPE ty_prog_component iv_program TYPE progname
  CHANGING cv_message TYPE string.
  DATA: wal_tran TYPE ty_prog_tran,
        wal_config TYPE ty_prog_tran_config,
        wal_target_config TYPE ty_prog_tran_config,
        wal_target_parameters TYPE tstcp,
        vl_target TYPE tcode,
        vl_target_ok TYPE abap_bool,
        tl_visited TYPE SORTED TABLE OF tcode WITH UNIQUE KEY table_line,
        vl_customer TYPE abap_bool,
        vl_type TYPE rglif-docutype,
        vl_transport TYPE trkorr,
        vl_text TYPE tstct-ttext,
        vl_language TYPE sylangu,
        vl_object TYPE tadir-obj_name.
  CLEAR cv_message.
  PERFORM f_is_customer_object USING 'TRAN' is_part-name is_part-original_system
    CHANGING vl_customer.
  IF vl_customer IS INITIAL.
    cv_message = 'Transaccion no identificada como desarrollo del cliente.'.
    RETURN.
  ENDIF.
  CALL TRANSFORMATION id SOURCE XML is_part-content RESULT transaction = wal_tran.
  IF wal_tran-definition-tcode <> is_part-name.
    cv_message = 'La transaccion no pertenece al programa del payload.'.
    RETURN.
  ENDIF.
  PERFORM f_program_transaction_config USING wal_tran-definition wal_tran-parameters
    CHANGING wal_config cv_message.
  IF cv_message IS NOT INITIAL.
    RETURN.
  ENDIF.
  vl_target_ok = xsdbool( wal_config-called IS INITIAL AND wal_tran-definition-pgmna = iv_program ).
  vl_target = wal_config-called.
  WHILE vl_target_ok = abap_false AND vl_target IS NOT INITIAL.
    INSERT vl_target INTO TABLE tl_visited.
    IF sy-subrc <> 0.
      EXIT. "Cycle in a transaction chain.
    ENDIF.
    SELECT SINGLE * FROM tstc INTO @DATA(wal_target) WHERE tcode = @vl_target.
    IF sy-subrc <> 0.
      EXIT.
    ENDIF.
    IF wal_target-pgmna = iv_program.
      vl_target_ok = abap_true.
      EXIT.
    ENDIF.
    CLEAR wal_target_parameters.
    SELECT SINGLE * FROM tstcp INTO wal_target_parameters WHERE tcode = vl_target.
    PERFORM f_program_transaction_config USING wal_target wal_target_parameters
      CHANGING wal_target_config cv_message.
    IF cv_message IS NOT INITIAL.
      RETURN.
    ENDIF.
    vl_target = wal_target_config-called.
  ENDWHILE.
  IF vl_target_ok = abap_false.
    cv_message = 'La transaccion llamada no existe o no conduce al programa importado.'.
    RETURN.
  ENDIF.
  SELECT SINGLE * FROM tstc INTO @DATA(wal_existing) WHERE tcode = @wal_tran-definition-tcode.
  IF sy-subrc = 0.
    IF p_overw IS INITIAL.
      cv_message = 'La transaccion ya existe; sobrescritura desmarcada.'.
      RETURN.
    ENDIF.
    SELECT SINGLE * FROM tstcp INTO @DATA(wal_existing_params) WHERE tcode = @wal_tran-definition-tcode.
    SELECT SINGLE * FROM tstcc INTO @DATA(wal_existing_gui) WHERE tcode = @wal_tran-definition-tcode.
    IF wal_existing <> wal_tran-definition OR wal_existing_params <> wal_tran-parameters
      OR wal_existing_gui <> wal_tran-gui.
      cv_message = 'Transaccion existente con definicion distinta; revisar en SE93 antes de reemplazarla.'.
      RETURN.
    ENDIF.
  ENDIF.
  vl_transport = p_req.
  vl_object = is_part-name.
  CALL FUNCTION 'RS_CORR_INSERT'
    EXPORTING object = vl_object object_class = 'TRAN' mode = 'INSERT'
              devclass = vg_package korrnum = vl_transport global_lock = abap_true
    EXCEPTIONS error_message = 1 OTHERS = 2.
  IF sy-subrc <> 0.
    cv_message = 'No se pudo registrar la transaccion en package/OT.'.
    RETURN.
  ENDIF.
  IF wal_existing IS INITIAL.
    vl_type = wal_config-kind.
    READ TABLE wal_tran-texts INTO DATA(wal_text) WITH KEY sprsl = sy-langu.
    IF sy-subrc <> 0.
      READ TABLE wal_tran-texts INTO wal_text INDEX 1.
    ENDIF.
    vl_text = wal_text-ttext.
    vl_language = wal_text-sprsl.
    IF vl_language IS INITIAL.
      vl_language = sy-langu.
    ENDIF.
    CALL FUNCTION 'RPY_TRANSACTION_INSERT'
      EXPORTING transaction = wal_tran-definition-tcode program = wal_tran-definition-pgmna
                dynpro = wal_tran-definition-dypno language = vl_language
                development_class = vg_package transaction_type = vl_type shorttext = vl_text
                called_transaction = wal_config-called called_transaction_skip = wal_config-skip
                variant = wal_config-variant cl_independend = wal_config-independent
                html_enabled = wal_tran-gui-s_webgui java_enabled = wal_tran-gui-s_platin
                wingui_enabled = wal_tran-gui-s_win32 suppress_corr_insert = abap_true
      TABLES param_values = wal_config-values
      EXCEPTIONS error_message = 1 OTHERS = 2.
    IF sy-subrc <> 0.
      cv_message = 'RPY_TRANSACTION_INSERT fallo.'.
      RETURN.
    ENDIF.
  ENDIF.
  "Only the validated transaction key can be written, including translations.
  LOOP AT wal_tran-texts ASSIGNING FIELD-SYMBOL(<text>).
    <text>-tcode = wal_tran-definition-tcode.
  ENDLOOP.
  MODIFY tstct FROM TABLE wal_tran-texts.
  IF sy-subrc <> 0.
    cv_message = 'No se pudieron guardar las traducciones de la transaccion.'.
  ENDIF.
  LOOP AT wal_tran-auth ASSIGNING FIELD-SYMBOL(<auth>).
    <auth>-tcode = wal_tran-definition-tcode.
  ENDLOOP.
  DELETE FROM tstca WHERE tcode = wal_tran-definition-tcode.
  IF wal_tran-auth IS NOT INITIAL.
    INSERT tstca FROM TABLE wal_tran-auth.
    IF sy-subrc <> 0.
      cv_message = 'No se pudieron guardar las autorizaciones de inicio de la transaccion.'.
      RETURN.
    ENDIF.
  ENDIF.
  "Preserve report-variant and authorization flags not fully restored by RPY.
  UPDATE tstc SET cinfo = wal_tran-definition-cinfo WHERE tcode = wal_tran-definition-tcode.
  IF sy-subrc <> 0.
    cv_message = 'No se pudieron guardar los indicadores de la transaccion.'.
  ENDIF.
ENDFORM.

FORM f_import_program_enhancement
  USING is_part TYPE ty_prog_component
  CHANGING cs_object TYPE ty_import_object cv_message TYPE string.
  DATA: wal_enho TYPE ty_prog_enho,
        vl_customer TYPE abap_bool,
        vl_name TYPE enhname,
        vl_package TYPE devclass,
        vl_transport TYPE trkorr,
        vl_activation_name TYPE dwinactiv-obj_name,
        li_tool TYPE REF TO if_enh_tool,
        lo_hook TYPE REF TO cl_enh_tool_hook_impl.
  CLEAR cv_message.
  PERFORM f_is_customer_object USING 'ENHO' is_part-name is_part-original_system
    CHANGING vl_customer.
  IF vl_customer IS INITIAL.
    cv_message = 'Enhancement no identificado como desarrollo del cliente.'.
    RETURN.
  ENDIF.
  CALL TRANSFORMATION id SOURCE XML is_part-content RESULT enhancement = wal_enho.
  READ TABLE tg_saved_source TRANSPORTING NO FIELDS
    WITH KEY object_type = 'PROG' object_name = cs_object-object_name
             program = wal_enho-original-programname.
  IF sy-subrc <> 0
    OR ( wal_enho-original-pgmid <> 'R3TR' AND wal_enho-original-pgmid <> 'LIMU' )
    OR ( wal_enho-original-org_main_type <> 'PROG' AND wal_enho-original-org_main_type <> 'REPS' )
    OR ( wal_enho-original-org_obj_type <> 'PROG' AND wal_enho-original-org_obj_type <> 'REPS' ).
    cv_message = 'El enhancement no pertenece a los fuentes del programa importado.'.
    RETURN.
  ENDIF.
  "All original-object identities must stay within this imported source set.
  READ TABLE tg_saved_source TRANSPORTING NO FIELDS
    WITH KEY object_type = 'PROG' object_name = cs_object-object_name
             program = wal_enho-original-org_obj_name.
  IF sy-subrc <> 0.
    cv_message = 'Objeto original del enhancement fuera de los fuentes importados.'.
    RETURN.
  ENDIF.
  READ TABLE tg_saved_source TRANSPORTING NO FIELDS
    WITH KEY object_type = 'PROG' object_name = cs_object-object_name
             program = wal_enho-original-org_main_name.
  IF sy-subrc <> 0.
    cv_message = 'Objeto principal del enhancement fuera de los fuentes importados.'.
    RETURN.
  ENDIF.
  vl_name = is_part-name.
  TRY.
      li_tool = cl_enh_factory=>get_enhancement(
        enhancement_id = vl_name run_dark = abap_true bypassing_buffer = abap_true ).
    CATCH cx_enh_root.
      CLEAR li_tool.
  ENDTRY.
  IF li_tool IS BOUND.
    cv_message = 'Enhancement existente: se conserva; revisar diferencias en SE80.'.
    RETURN.
  ENDIF.
  PERFORM f_register_prog_related USING 'ENHO' is_part-name CHANGING cv_message.
  IF cv_message IS NOT INITIAL.
    RETURN.
  ENDIF.
  TRY.
      vl_package = vg_package.
      vl_transport = p_req.
      cl_enh_factory=>create_enhancement(
        EXPORTING enhname = vl_name enhtype = cl_abstract_enh_tool_redef=>credefinition
                  enhtooltype = cl_enh_tool_hook_impl=>tooltype
        IMPORTING enhancement = li_tool CHANGING devclass = vl_package ).
      lo_hook ?= li_tool.
      lo_hook->if_enh_object_docu~set_shorttext( wal_enho-shorttext ).
      lo_hook->set_original_object(
        pgmid = wal_enho-original-pgmid obj_name = wal_enho-original-org_obj_name
        obj_type = wal_enho-original-org_obj_type program = wal_enho-original-programname
        main_type = wal_enho-original-org_main_type main_name = wal_enho-original-org_main_name ).
      lo_hook->set_include_bound( wal_enho-original-include_bound ).
      LOOP AT wal_enho-hooks INTO DATA(wal_hook).
        lo_hook->add_hook_impl(
          overwrite = wal_hook-overwrite method = wal_hook-method enhmode = wal_hook-enhmode
          full_name = wal_hook-full_name source = wal_hook-source spot = wal_hook-spotname
          parent_full_name = wal_hook-parent_full_name ).
      ENDLOOP.
      lo_hook->if_enh_object~save( run_dark = abap_true ).
      lo_hook->if_enh_object~unlock( ).
      vl_activation_name = is_part-name.
      PERFORM f_queue_component USING cs_object-object_name 'ENHO' vl_activation_name.
    CATCH cx_root INTO DATA(lo_error).
      cv_message = lo_error->get_text( ).
      IF lo_hook IS BOUND.
        TRY.
            lo_hook->if_enh_object~unlock( ).
          CATCH cx_root.
        ENDTRY.
      ENDIF.
  ENDTRY.
ENDFORM.

FORM f_register_prog_related
  USING iv_type TYPE tadir-object iv_name TYPE tadir-obj_name
  CHANGING cv_message TYPE string.
  CLEAR cv_message.
  CALL FUNCTION 'RS_CORR_INSERT'
    EXPORTING object = iv_name object_class = iv_type mode = 'INSERT'
              devclass = vg_package korrnum = p_req global_lock = abap_true
    EXCEPTIONS error_message = 1 OTHERS = 2.
  IF sy-subrc <> 0.
    cv_message = |No se pudo registrar { iv_type } { iv_name } en package/OT.|.
  ENDIF.
ENDFORM.

FORM f_program_transaction_config
  USING is_definition TYPE tstc is_parameters TYPE tstcp
  CHANGING cs_config TYPE ty_prog_tran_config cv_error TYPE string.
  CONSTANTS: lc_report TYPE x VALUE '80', lc_parameter TYPE x VALUE '02', lc_oo TYPE x VALUE '08'.
  DATA: vl_parameters TYPE string,
        vl_token TYPE string,
        vl_rest TYPE string,
        vl_offset TYPE i,
        wal_value TYPE rsparam.
  CLEAR: cs_config, cv_error.
  vl_parameters = is_parameters-param.
  IF is_definition-cinfo O lc_oo.
    cv_error = 'Transaccion OO: requiere el objeto CLAS y configuracion SE93; no es una transaccion de programa.'.
    RETURN.
  ELSEIF is_definition-cinfo O lc_report.
    cs_config-kind = 'R'.
    cs_config-variant = vl_parameters.
    RETURN.
  ELSEIF is_definition-cinfo O lc_parameter.
    IF vl_parameters CP '@*'.
      cs_config-kind = 'V'.
      IF vl_parameters CP '@@*'.
        cs_config-independent = abap_true.
        vl_parameters = substring( val = vl_parameters off = 2 ).
      ELSE.
        vl_parameters = substring( val = vl_parameters off = 1 ).
      ENDIF.
      SPLIT vl_parameters AT space INTO cs_config-called cs_config-variant.
      IF cs_config-called IS INITIAL OR cs_config-variant IS INITIAL.
        cv_error = 'Definicion de transaccion con variante incompleta.'.
      ENDIF.
      RETURN.
    ELSEIF vl_parameters CP '/?*'.
      cs_config-kind = 'P'.
      cs_config-skip = xsdbool( vl_parameters+1(1) = '*' ).
      vl_parameters = substring( val = vl_parameters off = 2 ).
      SPLIT vl_parameters AT space INTO cs_config-called vl_rest.
      vl_parameters = vl_rest.
    ELSE.
      cv_error = 'Formato TSTCP desconocido para transaccion de parametros.'.
      RETURN.
    ENDIF.
  ELSE.
    cs_config-kind = 'D'.
    RETURN.
  ENDIF.
  IF cs_config-called IS INITIAL.
    cv_error = 'Falta transaccion llamada.'.
    RETURN.
  ENDIF.
  WHILE vl_parameters IS NOT INITIAL.
    CLEAR: wal_value, vl_token, vl_rest.
    SPLIT vl_parameters AT ';' INTO vl_token vl_rest.
    vl_parameters = vl_rest.
    FIND FIRST OCCURRENCE OF '=' IN vl_token MATCH OFFSET vl_offset.
    IF sy-subrc <> 0 OR vl_offset = 0.
      cv_error = 'Parametro TSTCP sin nombre o separador igual.'.
      RETURN.
    ENDIF.
    wal_value-field = vl_token(vl_offset).
    CONDENSE wal_value-field.
    vl_offset = vl_offset + 1.
    wal_value-value = substring( val = vl_token off = vl_offset ).
    APPEND wal_value TO cs_config-values.
  ENDWHILE.
ENDFORM.

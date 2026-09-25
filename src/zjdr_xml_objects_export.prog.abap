*&---------------------------------------------------------------------*
*& Report - ZJDR_XML_OBJECTS_EXPORT
*&---------------------------------------------------------------------*
*& Proyecto...: Exportador XML de objetos ABAP
*& Autor......: Juan Dino (DINOJ)
*& Fecha......: 01/Jun/2026
*& Código Des.:
*& REQ........: EXPPC-108
*& Descripción: Exporta objetos ABAP/IDoc a XML
*&---------------------------------------------------------------------*

REPORT zjdr_xml_objects_export
  NO STANDARD PAGE HEADING
  LINE-SIZE 255.

*&---------------------------------------------------------------------*
*& INCLUDES
*&---------------------------------------------------------------------*
INCLUDE <icon>.

*&---------------------------------------------------------------------*
*& TABLES
*&---------------------------------------------------------------------*
TABLES: tadir, e070.

*&---------------------------------------------------------------------*
*& CONSTANTS
*&---------------------------------------------------------------------*
CONSTANTS:
  cg_status_not_exported TYPE icon_d VALUE icon_led_inactive,
  cg_status_success      TYPE icon_d VALUE icon_led_green,
  cg_status_warning      TYPE icon_d VALUE icon_led_yellow,
  cg_status_error        TYPE icon_d VALUE icon_led_red.

CONSTANTS:
  cg_button_export TYPE syucomm VALUE 'ZEXP_XML'.

CONSTANTS:
  cg_xml_version TYPE string VALUE '1.3'.

CONSTANTS:
  cg_type_prog TYPE string VALUE 'PROG',
  cg_type_tabl TYPE string VALUE 'TABL',
  cg_type_stru TYPE string VALUE 'STRU',
  cg_type_ttyp TYPE string VALUE 'TTYP',
  cg_type_doma TYPE string VALUE 'DOMA',
  cg_type_dtel TYPE string VALUE 'DTEL',
  cg_type_shlp TYPE string VALUE 'SHLP',
  cg_type_clas TYPE string VALUE 'CLAS',
  cg_type_intf TYPE string VALUE 'INTF',
  cg_type_fugr TYPE string VALUE 'FUGR',
  cg_type_idsg TYPE string VALUE 'IDSG',
  cg_type_idbt TYPE string VALUE 'IDBT',
  cg_type_idex TYPE string VALUE 'IDEX',
  cg_type_idms TYPE string VALUE 'IDMS',
  cg_type_idas TYPE string VALUE 'IDAS'.

*&---------------------------------------------------------------------*
*& TYPES
*&---------------------------------------------------------------------*
TYPES:
  ty_t_source  TYPE STANDARD TABLE OF string WITH EMPTY KEY,
  ty_t_xml     TYPE STANDARD TABLE OF string WITH EMPTY KEY,
  tyt_tadir    TYPE STANDARD TABLE OF tadir WITH EMPTY KEY,
  tyt_progname TYPE STANDARD TABLE OF progname WITH DEFAULT KEY,
  tyt_string   TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

TYPES:
  BEGIN OF ty_alv_object,
    selected_for_export TYPE abap_bool,
    light       TYPE icon_d,
    package     TYPE devclass,
    original_system TYPE tadir-srcsystem,
    object_type TYPE string,
    object_name TYPE tadir-obj_name,
    target_object_name TYPE tadir-obj_name,
    short_text  TYPE string,
    masterlang  TYPE tadir-masterlang,
    last_change TYPE sy-datum,
    source_type TYPE string,
    relationship TYPE string,
    parent_type TYPE string,
    parent_name TYPE tadir-obj_name,
    relation_reason TYPE string,
    status_text TYPE string,
  END OF ty_alv_object.

TYPES:
  tyt_alv_object TYPE STANDARD TABLE OF ty_alv_object WITH EMPTY KEY.

TYPES: BEGIN OF ty_dependency_ref,
         parent_type TYPE string,
         parent_name TYPE tadir-obj_name,
         object_type TYPE string,
         object_name TYPE tadir-obj_name,
       END OF ty_dependency_ref.
TYPES tyt_dependency_ref TYPE STANDARD TABLE OF ty_dependency_ref WITH EMPTY KEY.

TYPES:
  BEGIN OF ty_include,
    parent_object TYPE tadir-obj_name,
    include_name  TYPE progname,
    found         TYPE abap_bool,
    line_count    TYPE i,
    message       TYPE string,
  END OF ty_include.

TYPES:
  tyt_include TYPE STANDARD TABLE OF ty_include WITH DEFAULT KEY.

TYPES:
  BEGIN OF ty_f4_object,
    obj_name TYPE tadir-obj_name,
    object   TYPE tadir-object,
    devclass TYPE tadir-devclass,
  END OF ty_f4_object.

TYPES:
  tyt_f4_object TYPE STANDARD TABLE OF ty_f4_object WITH EMPTY KEY.


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
DATA:
  tg_alv_object TYPE tyt_alv_object,
  tg_dependencies TYPE tyt_dependency_ref,
  tg_xml        TYPE ty_t_xml.

DATA:
  go_container TYPE REF TO cl_gui_docking_container,
  go_grid      TYPE REF TO cl_gui_alv_grid.

DATA:
  gv_export_scope TYPE string,
  gv_okcode       TYPE syucomm.

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
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.

  METHOD handle_toolbar.

    DATA wal_toolbar TYPE stb_button.

    CLEAR wal_toolbar.
    wal_toolbar-butn_type = 3.
    APPEND wal_toolbar TO e_object->mt_toolbar.

    CLEAR wal_toolbar.
    wal_toolbar-function  = cg_button_export.
    wal_toolbar-icon      = icon_export.
    wal_toolbar-quickinfo = 'Exportar XML'.
    wal_toolbar-text      = 'Exportar XML'.
    wal_toolbar-butn_type = 0.
    APPEND wal_toolbar TO e_object->mt_toolbar.

  ENDMETHOD.

  METHOD handle_user_command.

    CASE e_ucomm.

      WHEN cg_button_export.
        PERFORM f_export_selected_objects.

    ENDCASE.

  ENDMETHOD.

  METHOD handle_hotspot_click.

    READ TABLE tg_alv_object INTO DATA(wal_object) INDEX e_row_id-index.

    IF sy-subrc NE 0.
      RETURN.
    ENDIF.

    IF e_column_id-fieldname NE 'OBJECT_NAME'.
      RETURN.
    ENDIF.

    PERFORM f_navigate_to_object
      USING wal_object-object_type
            wal_object-object_name.

  ENDMETHOD.

ENDCLASS.

DATA go_event_handler TYPE REF TO lcl_event_handler.

*&---------------------------------------------------------------------*
*& SELECTION-SCREEN
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS:
    s_pack FOR tadir-devclass,
    s_obj  FOR tadir-obj_name,
    s_req  FOR e070-trkorr.

SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-002.

  PARAMETERS cb_prog AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_tabl AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_doma AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_dtel AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_stru AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_ttyp AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_shlp AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_clas AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_intf AS CHECKBOX DEFAULT 'X'.
  PARAMETERS cb_fugr AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b02.

SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-003.

  PARAMETERS cb_idoc AS CHECKBOX DEFAULT space.

  SELECT-OPTIONS:
    s_idseg FOR tadir-obj_name,
    s_idoct FOR tadir-obj_name,
    s_mesty FOR tadir-obj_name.

SELECTION-SCREEN END OF BLOCK b03.

*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN ON VALUE-REQUEST
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_obj-low.

  PERFORM f_f4_object_selection
    USING 'S_OBJ-LOW'.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_obj-high.

  PERFORM f_f4_object_selection
    USING 'S_OBJ-HIGH'.

*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.

  PERFORM f_validate_selection.

*&---------------------------------------------------------------------*
*& START-OF-SELECTION
*&---------------------------------------------------------------------*
START-OF-SELECTION.

  CLEAR:
    tg_alv_object,
    tg_dependencies,
    tg_xml.

  PERFORM f_build_export_scope
    CHANGING gv_export_scope.

  PERFORM f_select_objects.
  PERFORM f_select_idoc_definitions.
  PERFORM f_filter_customer_objects.
  PERFORM f_expand_program_dependencies.


  IF tg_alv_object IS INITIAL.
    MESSAGE 'No se encontraron objetos para los criterios seleccionados.' TYPE 'I'.
    RETURN.
  ENDIF.

  SORT tg_alv_object BY package object_type object_name source_type.
  DELETE ADJACENT DUPLICATES FROM tg_alv_object
    COMPARING package object_type object_name source_type.

  CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*& MODULES
*&---------------------------------------------------------------------*
MODULE mb_status_0100 OUTPUT.
ENDMODULE.

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

ENDMODULE.

MODULE ma_user_command_0100 INPUT.

  gv_okcode = sy-ucomm.

  CASE gv_okcode.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0.
    WHEN 'EXIT' OR 'CANC'.
      LEAVE PROGRAM.
  ENDCASE.

ENDMODULE.

*&---------------------------------------------------------------------*
*& FORMS
*&---------------------------------------------------------------------*
FORM f_validate_selection.

  IF cb_prog IS INITIAL
 AND cb_tabl IS INITIAL
 AND cb_doma IS INITIAL
 AND cb_dtel IS INITIAL
 AND cb_stru IS INITIAL
 AND cb_ttyp IS INITIAL
 AND cb_shlp IS INITIAL
 AND cb_clas IS INITIAL
 AND cb_intf IS INITIAL
 AND cb_fugr IS INITIAL
 AND cb_idoc IS INITIAL.
    MESSAGE 'Debe seleccionar al menos un tipo de objeto.' TYPE 'E'.
  ENDIF.

  IF s_pack[] IS INITIAL
 AND s_obj[]  IS INITIAL
 AND s_req[] IS INITIAL.
    MESSAGE 'Debe informar al menos un package, objeto u orden de transporte.' TYPE 'E'.
  ENDIF.

  IF cb_idoc IS INITIAL
 AND ( s_idseg[] IS NOT INITIAL
    OR s_idoct[] IS NOT INITIAL
    OR s_mesty[] IS NOT INITIAL ).
    MESSAGE 'Para usar criterios IDoc debe marcar Exportar definiciones IDoc.' TYPE 'E'.
  ENDIF.

ENDFORM. " f_validate_selection

FORM f_f4_object_selection
  USING iv_dynprofield TYPE dynfnam.

  DATA:
    tl_f4_object TYPE tyt_f4_object,
    tl_return    TYPE STANDARD TABLE OF ddshretval,
    wal_return   TYPE ddshretval.

  PERFORM f_get_f4_objects
    CHANGING tl_f4_object.

  IF tl_f4_object IS INITIAL.
    MESSAGE 'No se encontraron objetos para la ayuda de búsqueda.' TYPE 'I'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'OBJ_NAME'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = iv_dynprofield
      value_org       = 'S'
    TABLES
      value_tab       = tl_f4_object
      return_tab      = tl_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

  READ TABLE tl_return INTO wal_return INDEX 1.

ENDFORM. " f_f4_object_selection

FORM f_get_f4_objects
  CHANGING ct_f4_object TYPE tyt_f4_object.

  DATA tl_tadir TYPE tyt_tadir.

  CLEAR ct_f4_object.
  PERFORM f_read_object_candidates CHANGING tl_tadir.
  LOOP AT tl_tadir INTO DATA(wal_tadir).
    APPEND VALUE #( obj_name = wal_tadir-obj_name
                    object = wal_tadir-object
                    devclass = wal_tadir-devclass ) TO ct_f4_object.
  ENDLOOP.

  SORT ct_f4_object BY devclass object obj_name.
  DELETE ADJACENT DUPLICATES FROM ct_f4_object
    COMPARING devclass object obj_name.

ENDFORM. " f_get_f4_objects

FORM f_build_export_scope
  CHANGING cv_export_scope TYPE string.

  DATA:
    vl_pack_count  TYPE i,
    vl_obj_count   TYPE i,
    vl_req_count   TYPE i,
    vl_idseg_count TYPE i,
    vl_idoct_count TYPE i,
    vl_mesty_count TYPE i.

  CLEAR cv_export_scope.

  vl_pack_count  = lines( s_pack[] ).
  vl_obj_count   = lines( s_obj[] ).
  vl_req_count   = lines( s_req[] ).
  vl_idseg_count = lines( s_idseg[] ).
  vl_idoct_count = lines( s_idoct[] ).
  vl_mesty_count = lines( s_mesty[] ).

  cv_export_scope =
    |PACKAGES:{ vl_pack_count }; OBJECTS:{ vl_obj_count }; TRANSPORTS:{ vl_req_count }; IDOC_SEG:{ vl_idseg_count }; IDOC_TYPES:{ vl_idoct_count }; MESSAGE_TYPES:{ vl_mesty_count }|.

ENDFORM. " f_build_export_scope

* Read the same candidates for execution and object value help.
* Empty package/name ranges impose no restriction; an OT narrows the set.
FORM f_read_object_candidates
  CHANGING ct_tadir TYPE tyt_tadir.

  DATA: tl_entries TYPE STANDARD TABLE OF e071,
        tl_keys    TYPE STANDARD TABLE OF tadir,
        wal_key    TYPE tadir,
        vl_result  TYPE trpari-s_checked,
        vl_unresolved TYPE i.

  CLEAR ct_tadir.

  IF s_req[] IS INITIAL.
    SELECT * FROM tadir
      INTO TABLE @ct_tadir
      WHERE pgmid    = 'R3TR'
        AND devclass IN @s_pack
        AND obj_name IN @s_obj
        AND srcsystem <> 'SAP'
        AND srcsystem <> @space
        AND genflag <> 'X'
        AND object IN ('PROG', 'TABL', 'DOMA', 'DTEL', 'SHLP', 'CLAS', 'INTF', 'FUGR', 'TTYP').
    RETURN.
  ENDIF.

  "Include entries on the request itself and on its immediate tasks.
  "Selecting a task alone does not include sibling tasks.
  SELECT e071~* FROM e071
    INNER JOIN e070 ON e070~trkorr = e071~trkorr
    INTO TABLE @tl_entries
    WHERE ( e070~trkorr IN @s_req OR e070~strkorr IN @s_req )
      AND e071~pgmid IN ('R3TR', 'LIMU').

  LOOP AT tl_entries INTO DATA(wal_entry).
    CLEAR: wal_key, vl_result.
    CASE wal_entry-pgmid.
      WHEN 'R3TR'.
        wal_key-pgmid    = wal_entry-pgmid.
        wal_key-object   = wal_entry-object.
        wal_key-obj_name = wal_entry-obj_name.
      WHEN 'LIMU'.
        "Variants are not repository sources supported by this exporter.
        IF wal_entry-object = 'VARX'.
          CONTINUE.
        ENDIF.
        CALL FUNCTION 'TR_CHECK_TYPE'
          EXPORTING wi_e071 = wal_entry
          IMPORTING we_tadir = wal_key
                    pe_result = vl_result
          EXCEPTIONS OTHERS = 1.
        IF sy-subrc <> 0 OR vl_result NA 'TL'
        OR wal_key-object IS INITIAL OR wal_key-obj_name IS INITIAL.
          vl_unresolved = vl_unresolved + 1.
          CONTINUE.
        ENDIF.
    ENDCASE.
    APPEND wal_key TO tl_keys.
  ENDLOOP.

  IF vl_unresolved > 0.
    MESSAGE 'Hay subobjetos de la OT que no pudieron resolverse y fueron omitidos.'
      TYPE 'S' DISPLAY LIKE 'W'.
  ENDIF.

  "An empty FOR ALL ENTRIES would select the entire repository.
  IF tl_keys IS INITIAL.
    RETURN.
  ENDIF.
  SORT tl_keys BY object obj_name.
  DELETE ADJACENT DUPLICATES FROM tl_keys COMPARING object obj_name.

  SELECT * FROM tadir
    INTO TABLE @ct_tadir
    FOR ALL ENTRIES IN @tl_keys
    WHERE pgmid    = 'R3TR'
      AND object   = @tl_keys-object
      AND obj_name = @tl_keys-obj_name
      AND devclass IN @s_pack
      AND obj_name IN @s_obj
        AND srcsystem <> 'SAP'
        AND srcsystem <> @space
      AND genflag <> 'X'
      AND object IN ('PROG', 'TABL', 'DOMA', 'DTEL', 'SHLP', 'CLAS', 'INTF', 'FUGR', 'TTYP').

ENDFORM. " f_read_object_candidates

FORM f_select_objects.

  DATA:
    tl_tadir               TYPE tyt_tadir,
    wal_alv                TYPE ty_alv_object,
    vl_object_type         TYPE string,
    vl_short_text          TYPE string,
    vl_last_change         TYPE sy-datum,
    vl_table_type_selected TYPE abap_bool,
    vl_is_report           TYPE abap_bool.

  IF s_pack[] IS INITIAL
 AND s_obj[] IS INITIAL
 AND s_req[] IS INITIAL.
    RETURN.
  ENDIF.

  PERFORM f_read_object_candidates CHANGING tl_tadir.

  SORT tl_tadir BY devclass object obj_name.
  DELETE ADJACENT DUPLICATES FROM tl_tadir COMPARING devclass object obj_name.

  LOOP AT tl_tadir INTO DATA(wal_tadir).

    CLEAR:
      vl_object_type,
      vl_short_text,
      vl_last_change,
      vl_table_type_selected,
      vl_is_report.

    vl_object_type = wal_tadir-object.

    IF wal_tadir-object = 'PROG'.

      PERFORM f_is_report
        USING    wal_tadir-obj_name
        CHANGING vl_is_report.

      IF vl_is_report IS INITIAL.
        CONTINUE.
      ENDIF.

      IF cb_prog IS INITIAL.
        CONTINUE.
      ENDIF.

    ENDIF.

    IF wal_tadir-object = 'DOMA' AND cb_doma IS INITIAL.
      CONTINUE.
    ENDIF.

    IF wal_tadir-object = 'DTEL' AND cb_dtel IS INITIAL.
      CONTINUE.
    ENDIF.

    IF wal_tadir-object = 'SHLP' AND cb_shlp IS INITIAL.
      CONTINUE.
    ENDIF.

    IF wal_tadir-object = 'CLAS' AND cb_clas IS INITIAL.
      CONTINUE.
    ENDIF.

    IF wal_tadir-object = 'INTF' AND cb_intf IS INITIAL.
      CONTINUE.
    ENDIF.

    IF wal_tadir-object = 'FUGR' AND cb_fugr IS INITIAL.
      CONTINUE.
    ENDIF.

    IF wal_tadir-object = 'TTYP'.
      IF cb_ttyp IS INITIAL.
        CONTINUE.
      ENDIF.
      vl_object_type = cg_type_ttyp.
    ENDIF.

    IF wal_tadir-object = 'TABL'.

      IF cb_tabl IS INITIAL
     AND cb_stru IS INITIAL.
        CONTINUE.
      ENDIF.

      PERFORM f_get_table_object_type
        USING    wal_tadir-obj_name
        CHANGING vl_object_type
                 vl_table_type_selected.

      IF vl_table_type_selected IS INITIAL.
        CONTINUE.
      ENDIF.

    ENDIF.

    CLEAR wal_alv.

    PERFORM f_get_object_text
      USING    vl_object_type
               wal_tadir-obj_name
      CHANGING vl_short_text
               vl_last_change.

    wal_alv-light       = cg_status_not_exported.
    wal_alv-package     = wal_tadir-devclass.
    wal_alv-original_system = wal_tadir-srcsystem.
    wal_alv-object_type = vl_object_type.
    wal_alv-object_name = wal_tadir-obj_name.
    wal_alv-target_object_name = wal_tadir-obj_name.
    wal_alv-short_text  = vl_short_text.
    wal_alv-masterlang  = wal_tadir-masterlang.
    wal_alv-last_change = vl_last_change.
    wal_alv-source_type = 'TADIR'.
    wal_alv-relationship = 'ROOT'.
    wal_alv-relation_reason = 'USER_SELECTION'.
    wal_alv-status_text = 'No exportado'.

    APPEND wal_alv TO tg_alv_object.

  ENDLOOP.

ENDFORM. " f_select_objects

FORM f_select_idoc_definitions.

  DATA:
    tl_names TYPE tyt_string.

  IF cb_idoc IS INITIAL.
    RETURN.
  ENDIF.

  IF s_idseg[] IS NOT INITIAL.

    CLEAR tl_names.

    PERFORM f_select_dynamic_names
      USING    'EDISEGMENT'
               'SEGTYP'
               s_idseg[]
      CHANGING tl_names.

    IF tl_names IS INITIAL.
      PERFORM f_select_dynamic_names
        USING    'EDISEG'
                 'SEGTYP'
                 s_idseg[]
        CHANGING tl_names.
    ENDIF.

    PERFORM f_append_idoc_objects
      USING    cg_type_idsg
               'IDOC_SEGMENT'
               tl_names
               s_idseg[].

  ENDIF.

  IF s_idoct[] IS NOT INITIAL.

    CLEAR tl_names.

    PERFORM f_select_dynamic_names
      USING    'EDIMSG'
               'IDOCTYP'
               s_idoct[]
      CHANGING tl_names.

    PERFORM f_append_idoc_objects
      USING    cg_type_idbt
               'IDOC_BASIC_TYPE'
               tl_names
               s_idoct[].

    CLEAR tl_names.

    PERFORM f_select_dynamic_names
      USING    'EDIMSG'
               'CIMTYP'
               s_idoct[]
      CHANGING tl_names.

    PERFORM f_append_idoc_objects
      USING    cg_type_idex
               'IDOC_EXTENSION'
               tl_names
               s_idoct[].

  ENDIF.

  IF s_mesty[] IS NOT INITIAL.

    CLEAR tl_names.

    PERFORM f_select_dynamic_names
      USING    'EDMSG'
               'MESTYP'
               s_mesty[]
      CHANGING tl_names.

    IF tl_names IS INITIAL.
      PERFORM f_select_dynamic_names
        USING    'EDIMSG'
                 'MESTYP'
                 s_mesty[]
        CHANGING tl_names.
    ENDIF.

    PERFORM f_append_idoc_objects
      USING    cg_type_idms
               'IDOC_MESSAGE_TYPE'
               tl_names
               s_mesty[].

    PERFORM f_append_idoc_objects
      USING    cg_type_idas
               'IDOC_ASSIGNMENT'
               tl_names
               s_mesty[].

  ENDIF.

ENDFORM. " f_select_idoc_definitions

FORM f_select_dynamic_names
  USING    iv_tabname   TYPE tabname
           iv_fieldname TYPE fieldname
           it_range     LIKE s_obj[]
  CHANGING ct_names     TYPE tyt_string.

  DATA:
    vl_where TYPE string.

  CLEAR ct_names.

  PERFORM f_build_dynamic_where
    USING    iv_fieldname
             it_range
    CHANGING vl_where.

  IF vl_where IS INITIAL.
    RETURN.
  ENDIF.

  TRY.

      SELECT DISTINCT (iv_fieldname)
        FROM (iv_tabname)
        INTO TABLE @ct_names
        WHERE (vl_where).

    CATCH cx_sy_dynamic_osql_error.
      CLEAR ct_names.

    CATCH cx_sy_open_sql_db.
      CLEAR ct_names.

  ENDTRY.

  SORT ct_names.
  DELETE ADJACENT DUPLICATES FROM ct_names.

ENDFORM. " f_select_dynamic_names

FORM f_append_idoc_objects
  USING iv_object_type TYPE string
        iv_source_type TYPE string
        it_names       TYPE tyt_string
        it_range       LIKE s_obj[].

  DATA:
    wal_alv  TYPE ty_alv_object,
    vl_name  TYPE tadir-obj_name,
    tl_names TYPE tyt_string.

  tl_names = it_names.

  IF tl_names IS INITIAL.

    LOOP AT it_range INTO DATA(wal_range)
      WHERE sign   = 'I'
        AND option = 'EQ'
        AND low    IS NOT INITIAL.

      APPEND wal_range-low TO tl_names.

    ENDLOOP.

  ENDIF.

  LOOP AT tl_names INTO DATA(vl_string_name).

    IF vl_string_name IS INITIAL.
      CONTINUE.
    ENDIF.

    vl_name = vl_string_name.

    CLEAR wal_alv.
    wal_alv-light       = cg_status_not_exported.
    wal_alv-package     = space.
    wal_alv-object_type = iv_object_type.
    wal_alv-object_name = vl_name.
    wal_alv-short_text  = iv_source_type.
    wal_alv-masterlang  = sy-langu.
    wal_alv-last_change = sy-datum.
    wal_alv-source_type = iv_source_type.
    wal_alv-status_text = 'No exportado'.

    APPEND wal_alv TO tg_alv_object.

  ENDLOOP.

ENDFORM. " f_append_idoc_objects

FORM f_build_dynamic_where
  USING    iv_fieldname TYPE fieldname
           it_range     LIKE s_obj[]
  CHANGING cv_where     TYPE string.

  DATA:
    vl_cond    TYPE string,
    vl_low     TYPE string,
    vl_high    TYPE string,
    vl_pattern TYPE string.

  CLEAR cv_where.

  LOOP AT it_range INTO DATA(wal_range)
    WHERE sign = 'I'.

    CLEAR:
      vl_cond,
      vl_low,
      vl_high,
      vl_pattern.

    vl_low  = wal_range-low.
    vl_high = wal_range-high.

    PERFORM f_escape_sql_value CHANGING vl_low.
    PERFORM f_escape_sql_value CHANGING vl_high.

    CASE wal_range-option.

      WHEN 'EQ'.
        vl_cond = |{ iv_fieldname } = '{ vl_low }'|.

      WHEN 'CP'.
        vl_pattern = vl_low.
        REPLACE ALL OCCURRENCES OF '*' IN vl_pattern WITH '%'.
        REPLACE ALL OCCURRENCES OF '+' IN vl_pattern WITH '_'.
        vl_cond = |{ iv_fieldname } LIKE '{ vl_pattern }'|.

      WHEN 'BT'.
        vl_cond = |{ iv_fieldname } BETWEEN '{ vl_low }' AND '{ vl_high }'|.

      WHEN OTHERS.
        CONTINUE.

    ENDCASE.

    IF cv_where IS INITIAL.
      cv_where = vl_cond.
    ELSE.
      CONCATENATE cv_where 'OR' vl_cond INTO cv_where SEPARATED BY space.
    ENDIF.

  ENDLOOP.

  IF cv_where IS NOT INITIAL.
    CONCATENATE '(' cv_where ')' INTO cv_where SEPARATED BY space.
  ENDIF.

ENDFORM. " f_build_dynamic_where

FORM f_escape_sql_value
  CHANGING cv_value TYPE string.

  REPLACE ALL OCCURRENCES OF '''' IN cv_value WITH ''''''.

ENDFORM. " f_escape_sql_value

FORM f_is_report
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING cv_is_report   TYPE abap_bool.

  DATA vl_subc TYPE trdir-subc.

  CLEAR cv_is_report.

  SELECT SINGLE subc
    FROM trdir
    INTO @vl_subc
    WHERE name = @iv_object_name.

  IF sy-subrc = 0 AND vl_subc = '1'.
    cv_is_report = abap_true.
  ENDIF.

ENDFORM. " f_is_report

FORM f_get_table_object_type
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING cv_object_type TYPE string
           cv_selected    TYPE abap_bool.

  DATA vl_tabclass TYPE dd02l-tabclass.

  CLEAR:
    cv_object_type,
    cv_selected.

  SELECT SINGLE tabclass
    FROM dd02l
    INTO @vl_tabclass
    WHERE tabname  = @iv_object_name
      AND as4local = 'A'.

  IF sy-subrc NE 0.
    RETURN.
  ENDIF.

  CASE vl_tabclass.

    WHEN 'TRANSP'.
      IF cb_tabl = abap_true.
        cv_object_type = cg_type_tabl.
        cv_selected    = abap_true.
      ENDIF.

    WHEN 'INTTAB'.
      IF cb_stru = abap_true.
        cv_object_type = cg_type_stru.
        cv_selected    = abap_true.
      ENDIF.

  ENDCASE.

ENDFORM. " f_get_table_object_type

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
      it_outtab       = tg_alv_object
      it_fieldcatalog = tl_fieldcat ).

ENDFORM. " f_display_alv

FORM f_build_fieldcat
  CHANGING ct_fieldcat TYPE lvc_t_fcat.

  DATA wal_fieldcat TYPE lvc_s_fcat.

  CLEAR ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'LIGHT'.
  wal_fieldcat-coltext   = 'Estado'.
  wal_fieldcat-icon      = abap_true.
  wal_fieldcat-outputlen = 6.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'PACKAGE'.
  wal_fieldcat-coltext   = 'Package'.
  wal_fieldcat-outputlen = 20.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'OBJECT_TYPE'.
  wal_fieldcat-coltext   = 'Tipo Objeto'.
  wal_fieldcat-outputlen = 12.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'OBJECT_NAME'.
  wal_fieldcat-coltext   = 'Nombre Objeto'.
  wal_fieldcat-hotspot   = abap_true.
  wal_fieldcat-outputlen = 40.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'TARGET_OBJECT_NAME'.
  wal_fieldcat-coltext   = 'Nombre destino'.
  wal_fieldcat-outputlen = 40.
  wal_fieldcat-edit      = abap_true.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'SHORT_TEXT'.
  wal_fieldcat-coltext   = 'Short Text'.
  wal_fieldcat-outputlen = 60.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'SOURCE_TYPE'.
  wal_fieldcat-coltext   = 'Origen técnico'.
  wal_fieldcat-outputlen = 18.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'RELATIONSHIP'.
  wal_fieldcat-coltext   = 'Relacion'.
  wal_fieldcat-outputlen = 14.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'PARENT_NAME'.
  wal_fieldcat-coltext   = 'Objeto padre'.
  wal_fieldcat-outputlen = 40.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'MASTERLANG'.
  wal_fieldcat-coltext   = 'Original Language'.
  wal_fieldcat-outputlen = 15.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'LAST_CHANGE'.
  wal_fieldcat-coltext   = 'Last Change'.
  wal_fieldcat-outputlen = 12.
  APPEND wal_fieldcat TO ct_fieldcat.

  CLEAR wal_fieldcat.
  wal_fieldcat-fieldname = 'STATUS_TEXT'.
  wal_fieldcat-coltext   = 'Estado detall.'.
  wal_fieldcat-outputlen = 70.
  APPEND wal_fieldcat TO ct_fieldcat.

ENDFORM. " f_build_fieldcat

FORM f_export_selected_objects.

  DATA:
    tl_selected TYPE tyt_alv_object,
    tl_xml      TYPE ty_t_xml,
    tl_rows     TYPE lvc_t_row,
    vl_file     TYPE string,
    vl_action   TYPE i,
    vl_filename TYPE string,
    vl_path     TYPE string,
    vl_fullpath TYPE string.

  CLEAR:
    tl_selected,
    tl_xml,
    tl_rows.

  LOOP AT tg_alv_object ASSIGNING FIELD-SYMBOL(<object_selection>).
    CLEAR <object_selection>-selected_for_export.
  ENDLOOP.

  IF go_grid IS BOUND.

    go_grid->check_changed_data( ).

    go_grid->get_selected_rows(
      IMPORTING
        et_index_rows = tl_rows ).

  ENDIF.

  LOOP AT tl_rows INTO DATA(wal_row).

    READ TABLE tg_alv_object INTO DATA(wal_object) INDEX wal_row-index.

    IF sy-subrc = 0.
      APPEND wal_object TO tl_selected.
      READ TABLE tg_alv_object ASSIGNING FIELD-SYMBOL(<selected>) INDEX wal_row-index.
      IF sy-subrc = 0.
        <selected>-selected_for_export = abap_true.
      ENDIF.
    ENDIF.

  ENDLOOP.

  IF tl_selected IS INITIAL.
    MESSAGE 'Debe seleccionar al menos un registro del ALV.' TYPE 'I'.
    RETURN.
  ENDIF.

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_extension = 'xml'
      default_file_name = |OBJECTS_{ sy-sysid }_{ sy-datum }.xml|
      file_filter       = 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*|'
    CHANGING
      filename          = vl_filename
      path              = vl_path
      fullpath          = vl_fullpath
      user_action       = vl_action
    EXCEPTIONS
      OTHERS            = 1 ).

  IF sy-subrc NE 0
  OR vl_action = cl_gui_frontend_services=>action_cancel.
    RETURN.
  ENDIF.

  vl_file = vl_fullpath.

  PERFORM f_build_package_xml
    USING    tl_selected
    CHANGING tl_xml.

  PERFORM f_download_xml
    USING vl_file
          tl_xml.

  IF go_grid IS BOUND.
    go_grid->refresh_table_display( ).
  ENDIF.

  MESSAGE |XML exportado correctamente: { vl_fullpath }| TYPE 'S'.

ENDFORM. " f_export_selected_objects


*&---------------------------------------------------------------------*
*& FORM f_build_package_xml
*&---------------------------------------------------------------------*
* [Título: Construye XML completo de exportación]
*&---------------------------------------------------------------------*
* -> it_selected       " Objetos seleccionados para exportar
* <- ct_xml            " XML generado
*&---------------------------------------------------------------------*
FORM f_build_package_xml
  USING    it_selected TYPE tyt_alv_object
  CHANGING ct_xml      TYPE ty_t_xml.

  DATA:
    vl_escaped      TYPE string,
    vl_default_package TYPE devclass,
    vl_object_count TYPE i,
    vl_prog_count   TYPE i,
    vl_tabl_count   TYPE i,
    vl_stru_count   TYPE i,
    vl_ttyp_count   TYPE i,
    vl_doma_count   TYPE i,
    vl_dtel_count   TYPE i,
    vl_shlp_count   TYPE i,
    vl_clas_count   TYPE i,
    vl_intf_count   TYPE i,
    vl_fugr_count   TYPE i,
    vl_idsg_count   TYPE i,
    vl_idbt_count   TYPE i,
    vl_idex_count   TYPE i,
    vl_idms_count   TYPE i,
    vl_idas_count   TYPE i.

  CLEAR ct_xml.

  vl_object_count = lines( it_selected ).

  "The header package is the default proposed by the importer.  Objects
  "still carry their own package, so mixed-package exports remain valid.
  READ TABLE it_selected INTO DATA(wal_first_object) INDEX 1.
  IF sy-subrc = 0.
    vl_default_package = wal_first_object-package.
  ENDIF.

  LOOP AT it_selected INTO DATA(wal_count).

    CASE wal_count-object_type.
      WHEN cg_type_prog.
        vl_prog_count = vl_prog_count + 1.
      WHEN cg_type_tabl.
        vl_tabl_count = vl_tabl_count + 1.
      WHEN cg_type_stru.
        vl_stru_count = vl_stru_count + 1.
      WHEN cg_type_ttyp.
        vl_ttyp_count = vl_ttyp_count + 1.
      WHEN cg_type_doma.
        vl_doma_count = vl_doma_count + 1.
      WHEN cg_type_dtel.
        vl_dtel_count = vl_dtel_count + 1.
      WHEN cg_type_shlp.
        vl_shlp_count = vl_shlp_count + 1.
      WHEN cg_type_clas.
        vl_clas_count = vl_clas_count + 1.
      WHEN cg_type_intf.
        vl_intf_count = vl_intf_count + 1.
      WHEN cg_type_fugr.
        vl_fugr_count = vl_fugr_count + 1.
      WHEN cg_type_idsg.
        vl_idsg_count = vl_idsg_count + 1.
      WHEN cg_type_idbt.
        vl_idbt_count = vl_idbt_count + 1.
      WHEN cg_type_idex.
        vl_idex_count = vl_idex_count + 1.
      WHEN cg_type_idms.
        vl_idms_count = vl_idms_count + 1.
      WHEN cg_type_idas.
        vl_idas_count = vl_idas_count + 1.
    ENDCASE.

  ENDLOOP.

  APPEND '<?xml version="1.0" encoding="UTF-8"?>' TO ct_xml.
  APPEND |<sap_package_export version="{ cg_xml_version }">| TO ct_xml.

  APPEND '  <header>' TO ct_xml.

  PERFORM f_escape_xml USING vl_default_package CHANGING vl_escaped.
  APPEND |    <package>{ vl_escaped }</package>| TO ct_xml.

  PERFORM f_escape_xml USING gv_export_scope CHANGING vl_escaped.
  APPEND |    <export_scope>{ vl_escaped }</export_scope>| TO ct_xml.

  PERFORM f_append_range_xml USING 'transport_selection'    s_req[]   CHANGING ct_xml.
  PERFORM f_append_range_xml USING 'package_selection'      s_pack[]  CHANGING ct_xml.
  PERFORM f_append_range_xml USING 'object_selection'       s_obj[]   CHANGING ct_xml.
  PERFORM f_append_range_xml USING 'idoc_segment_selection' s_idseg[] CHANGING ct_xml.
  PERFORM f_append_range_xml USING 'idoc_type_selection'    s_idoct[] CHANGING ct_xml.
  PERFORM f_append_range_xml USING 'message_type_selection' s_mesty[] CHANGING ct_xml.

  APPEND |    <object_count>{ vl_object_count }</object_count>| TO ct_xml.
  APPEND |    <count_prog>{ vl_prog_count }</count_prog>| TO ct_xml.
  APPEND |    <count_tabl>{ vl_tabl_count }</count_tabl>| TO ct_xml.
  APPEND |    <count_stru>{ vl_stru_count }</count_stru>| TO ct_xml.
  APPEND |    <count_ttyp>{ vl_ttyp_count }</count_ttyp>| TO ct_xml.
  APPEND |    <count_doma>{ vl_doma_count }</count_doma>| TO ct_xml.
  APPEND |    <count_dtel>{ vl_dtel_count }</count_dtel>| TO ct_xml.
  APPEND |    <count_shlp>{ vl_shlp_count }</count_shlp>| TO ct_xml.
  APPEND |    <count_clas>{ vl_clas_count }</count_clas>| TO ct_xml.
  APPEND |    <count_intf>{ vl_intf_count }</count_intf>| TO ct_xml.
  APPEND |    <count_fugr>{ vl_fugr_count }</count_fugr>| TO ct_xml.
  APPEND |    <count_idsg>{ vl_idsg_count }</count_idsg>| TO ct_xml.
  APPEND |    <count_idbt>{ vl_idbt_count }</count_idbt>| TO ct_xml.
  APPEND |    <count_idex>{ vl_idex_count }</count_idex>| TO ct_xml.
  APPEND |    <count_idms>{ vl_idms_count }</count_idms>| TO ct_xml.
  APPEND |    <count_idas>{ vl_idas_count }</count_idas>| TO ct_xml.
  APPEND |    <export_user>{ sy-uname }</export_user>| TO ct_xml.
  APPEND |    <export_date>{ sy-datum }</export_date>| TO ct_xml.
  APPEND |    <export_time>{ sy-uzeit }</export_time>| TO ct_xml.
  APPEND |    <source_system_id>{ sy-sysid }</source_system_id>| TO ct_xml.
  APPEND |    <source_client>{ sy-mandt }</source_client>| TO ct_xml.
  APPEND |    <source_environment>{ sy-saprl }</source_environment>| TO ct_xml.
  APPEND |    <export_program>{ sy-repid }</export_program>| TO ct_xml.
  APPEND |    <export_program_version>{ cg_xml_version }</export_program_version>| TO ct_xml.

  APPEND '  </header>' TO ct_xml.
  APPEND '  <objects>' TO ct_xml.

  LOOP AT it_selected INTO DATA(wal_object).

    PERFORM f_export_object_to_xml
      USING    wal_object
      CHANGING ct_xml.

  ENDLOOP.

  APPEND '  </objects>' TO ct_xml.
  APPEND '</sap_package_export>' TO ct_xml.

ENDFORM. " f_build_package_xml

*&---------------------------------------------------------------------*
*& FORM f_append_range_xml
*&---------------------------------------------------------------------*
* [Título: Agrega un rango de selección al header XML]
*&---------------------------------------------------------------------*
* -> iv_node_name      " Nombre del nodo XML
* -> it_range          " Rango de selección genérico
* <- ct_xml            " XML acumulado
*&---------------------------------------------------------------------*
FORM f_append_range_xml
  USING    iv_node_name TYPE string
           it_range     TYPE ANY TABLE
  CHANGING ct_xml       TYPE ty_t_xml.

  DATA:
    vl_sign   TYPE string,
    vl_option TYPE string,
    vl_low    TYPE string,
    vl_high   TYPE string.

  FIELD-SYMBOLS:
    <fsl_range> TYPE any,
    <fsl_value> TYPE any.

  APPEND |    <{ iv_node_name }>| TO ct_xml.

  LOOP AT it_range ASSIGNING <fsl_range>.

    CLEAR:
      vl_sign,
      vl_option,
      vl_low,
      vl_high.

    ASSIGN COMPONENT 'SIGN' OF STRUCTURE <fsl_range> TO <fsl_value>.
    IF sy-subrc = 0.
      vl_sign = <fsl_value>.
    ENDIF.

    ASSIGN COMPONENT 'OPTION' OF STRUCTURE <fsl_range> TO <fsl_value>.
    IF sy-subrc = 0.
      vl_option = <fsl_value>.
    ENDIF.

    ASSIGN COMPONENT 'LOW' OF STRUCTURE <fsl_range> TO <fsl_value>.
    IF sy-subrc = 0.
      vl_low = <fsl_value>.
    ENDIF.

    ASSIGN COMPONENT 'HIGH' OF STRUCTURE <fsl_range> TO <fsl_value>.
    IF sy-subrc = 0.
      vl_high = <fsl_value>.
    ENDIF.

    PERFORM f_escape_xml USING vl_sign   CHANGING vl_sign.
    PERFORM f_escape_xml USING vl_option CHANGING vl_option.
    PERFORM f_escape_xml USING vl_low    CHANGING vl_low.
    PERFORM f_escape_xml USING vl_high   CHANGING vl_high.

    APPEND |      <range sign="{ vl_sign }" option="{ vl_option }" low="{ vl_low }" high="{ vl_high }" />| TO ct_xml.

  ENDLOOP.

  APPEND |    </{ iv_node_name }>| TO ct_xml.

ENDFORM. " f_append_range_xml

FORM f_export_object_to_xml
  USING    is_object TYPE ty_alv_object
  CHANGING ct_xml    TYPE ty_t_xml.

  DATA:
    vl_package TYPE string,
    vl_name    TYPE string,
    vl_text    TYPE string,
    vl_status  TYPE string,
    vl_warning TYPE abap_bool,
    vl_error   TYPE abap_bool.

  CLEAR:
    vl_warning,
    vl_error.

  PERFORM f_escape_xml USING is_object-package     CHANGING vl_package.
  PERFORM f_escape_xml USING is_object-object_name CHANGING vl_name.
  PERFORM f_escape_xml USING is_object-short_text  CHANGING vl_text.

  APPEND |    <object package="{ vl_package }" type="{ is_object-object_type }" name="{ vl_name }">| TO ct_xml.
  APPEND |      <package>{ vl_package }</package>| TO ct_xml.
  APPEND |      <short_text>{ vl_text }</short_text>| TO ct_xml.
  PERFORM f_escape_xml USING is_object-original_system CHANGING vl_text.
  APPEND |      <original_system>{ vl_text }</original_system>| TO ct_xml.
  APPEND |      <original_language>{ is_object-masterlang }</original_language>| TO ct_xml.
  APPEND |      <last_change>{ is_object-last_change }</last_change>| TO ct_xml.
  APPEND |      <source_type>{ is_object-source_type }</source_type>| TO ct_xml.
  APPEND |      <source_object_type>{ is_object-object_type }</source_object_type>| TO ct_xml.
  APPEND |      <source_object_name>{ vl_name }</source_object_name>| TO ct_xml.
  PERFORM f_escape_xml USING is_object-target_object_name CHANGING vl_text.
  APPEND |      <target_object_name>{ vl_text }</target_object_name>| TO ct_xml.
  APPEND |      <relationship>{ is_object-relationship }</relationship>| TO ct_xml.
  PERFORM f_escape_xml USING is_object-parent_type CHANGING vl_text.
  APPEND |      <parent_type>{ vl_text }</parent_type>| TO ct_xml.
  PERFORM f_escape_xml USING is_object-parent_name CHANGING vl_text.
  APPEND |      <parent_name>{ vl_text }</parent_name>| TO ct_xml.
  PERFORM f_escape_xml USING is_object-relation_reason CHANGING vl_text.
  APPEND |      <relation_reason>{ vl_text }</relation_reason>| TO ct_xml.
  APPEND '      <dependencies>' TO ct_xml.
  LOOP AT tg_dependencies INTO DATA(wal_relation)
    WHERE parent_type = is_object-object_type
      AND parent_name = is_object-object_name.
    READ TABLE tg_alv_object INTO DATA(wal_dependency)
      WITH KEY object_type = wal_relation-object_type object_name = wal_relation-object_name.
    PERFORM f_escape_xml USING wal_relation-object_name CHANGING vl_name.
    APPEND |        <dependency type="{ wal_relation-object_type }" name="{ vl_name }" included="{ wal_dependency-selected_for_export }" source="{ wal_dependency-source_type }" />| TO ct_xml.
  ENDLOOP.
  APPEND '      </dependencies>' TO ct_xml.

  CASE is_object-object_type.

    WHEN cg_type_prog.
      PERFORM f_export_prog
        USING    is_object-object_name
        CHANGING ct_xml
                 vl_warning
                 vl_error.

    WHEN cg_type_tabl OR cg_type_stru.
      PERFORM f_export_tabl
        USING    is_object-object_name
        CHANGING ct_xml
                 vl_warning
                 vl_error.

    WHEN cg_type_ttyp.
      PERFORM f_export_ttyp
        USING    is_object-object_name
        CHANGING ct_xml
                 vl_warning
                 vl_error.

    WHEN cg_type_doma.
      PERFORM f_export_doma
        USING    is_object-object_name
        CHANGING ct_xml
                 vl_warning
                 vl_error.

    WHEN cg_type_dtel.
      PERFORM f_export_dtel
        USING    is_object-object_name
        CHANGING ct_xml
                 vl_warning
                 vl_error.

    WHEN cg_type_shlp.
      PERFORM f_export_shlp
        USING    is_object-object_name
        CHANGING ct_xml
                 vl_warning
                 vl_error.

    WHEN cg_type_fugr.
      PERFORM f_export_fugr
        USING    is_object-object_name
        CHANGING ct_xml
                 vl_warning
                 vl_error.

    WHEN cg_type_clas OR cg_type_intf.
      PERFORM f_export_class_or_intf
        USING is_object-object_type is_object-object_name
        CHANGING ct_xml vl_warning vl_error.

    WHEN cg_type_idsg OR cg_type_idbt OR cg_type_idex OR cg_type_idms OR cg_type_idas.
      "The former payloads only contained technical fragments.  Marking them
      "as successful made an exported file look portable when it could not be
      "recreated by the importer. Keep the object in the manifest as ERROR so
      "the round-trip contract is explicit and the importer will not change it.
      vl_error = abap_true.
      APPEND '      <message>Tipo no incluido en el formato XML portable 1.1.</message>' TO ct_xml.

    WHEN OTHERS.
      vl_error = abap_true.
      APPEND '      <message>Tipo de objeto no soportado.</message>' TO ct_xml.

  ENDCASE.

  IF vl_error = abap_true.
    vl_status = 'ERROR'.
    PERFORM f_set_object_status USING is_object-package is_object-object_type is_object-object_name cg_status_error 'No exportado por error'.
  ELSEIF vl_warning = abap_true.
    vl_status = 'WARNING'.
    PERFORM f_set_object_status USING is_object-package is_object-object_type is_object-object_name cg_status_warning 'Exportado con advertencias'.
  ELSE.
    vl_status = 'SUCCESS'.
    PERFORM f_set_object_status USING is_object-package is_object-object_type is_object-object_name cg_status_success 'Exportado correctamente'.
  ENDIF.

  APPEND |      <export_status>{ vl_status }</export_status>| TO ct_xml.
  APPEND '    </object>' TO ct_xml.

ENDFORM. " f_export_object_to_xml

FORM f_export_prog
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml         TYPE ty_t_xml
           cv_warning     TYPE abap_bool
           cv_error       TYPE abap_bool.

  DATA:
    tl_source   TYPE ty_t_source,
    tl_include  TYPE tyt_include,
    tl_nested TYPE tyt_include,
    tl_nested_source TYPE ty_t_source,
    vl_index TYPE i,
    wal_nested TYPE ty_include,
    vl_escaped  TYPE string,
    vl_line_num TYPE i,
    vl_customer TYPE abap_bool.

  CLEAR:
    cv_warning,
    cv_error,
    tl_source,
    tl_include.

  READ REPORT iv_object_name INTO tl_source.

  IF sy-subrc NE 0.
    cv_error = abap_true.
    APPEND '      <message>No se pudo leer el código fuente del reporte.</message>' TO ct_xml.
    RETURN.
  ENDIF.

  APPEND '      <source_code>' TO ct_xml.

  LOOP AT tl_source INTO DATA(vl_line).

    vl_line_num = sy-tabix.

    PERFORM f_escape_xml
      USING    vl_line
      CHANGING vl_escaped.

    APPEND |        <line number="{ vl_line_num }">{ vl_escaped }</line>| TO ct_xml.

  ENDLOOP.

  APPEND '      </source_code>' TO ct_xml.

  PERFORM f_detect_includes
    USING    iv_object_name
             tl_source
    CHANGING tl_include.

  vl_index = 1.
  WHILE vl_index <= lines( tl_include ).
    READ TABLE tl_include INTO DATA(wal_pending) INDEX vl_index.
    CLEAR tl_nested_source.
    READ REPORT wal_pending-include_name INTO tl_nested_source.
    IF sy-subrc = 0.
      PERFORM f_detect_includes USING iv_object_name tl_nested_source CHANGING tl_nested.
      LOOP AT tl_nested INTO wal_nested.
        READ TABLE tl_include TRANSPORTING NO FIELDS
          WITH KEY include_name = wal_nested-include_name.
        IF sy-subrc <> 0 AND wal_nested-include_name <> iv_object_name.
          APPEND wal_nested TO tl_include.
        ENDIF.
      ENDLOOP.
    ENDIF.
    vl_index = vl_index + 1.
  ENDWHILE.

  APPEND '      <source_includes>' TO ct_xml.

  LOOP AT tl_include INTO DATA(wal_include).
    PERFORM f_is_customer_object USING 'PROG' wal_include-include_name space
      CHANGING vl_customer.
    IF vl_customer IS INITIAL.
      CONTINUE.
    ENDIF.

    PERFORM f_export_include
      USING    wal_include-include_name
      CHANGING ct_xml
               cv_warning.

  ENDLOOP.

  APPEND '      </source_includes>' TO ct_xml.

  PERFORM f_export_prog_bundle USING iv_object_name tl_include
    CHANGING ct_xml cv_warning.
ENDFORM. " f_export_prog

FORM f_export_include
  USING    iv_include_name TYPE progname
  CHANGING ct_xml          TYPE ty_t_xml
           cv_warning      TYPE abap_bool.

  DATA:
    tl_source   TYPE ty_t_source,
    vl_name     TYPE string,
    vl_escaped  TYPE string,
    vl_line_num TYPE i.

  PERFORM f_escape_xml
    USING    iv_include_name
    CHANGING vl_name.

  APPEND |        <include name="{ vl_name }">| TO ct_xml.

  READ REPORT iv_include_name INTO tl_source.

  IF sy-subrc NE 0.
    cv_warning = abap_true.
    APPEND '          <warning>No se pudo leer el include.</warning>' TO ct_xml.
    APPEND '        </include>' TO ct_xml.
    RETURN.
  ENDIF.

  APPEND '          <source_code>' TO ct_xml.

  LOOP AT tl_source INTO DATA(vl_line).

    vl_line_num = sy-tabix.

    PERFORM f_escape_xml
      USING    vl_line
      CHANGING vl_escaped.

    APPEND |            <line number="{ vl_line_num }">{ vl_escaped }</line>| TO ct_xml.

  ENDLOOP.

  APPEND '          </source_code>' TO ct_xml.
  APPEND '        </include>' TO ct_xml.

ENDFORM. " f_export_include

FORM f_export_tabl
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml         TYPE ty_t_xml
           cv_warning     TYPE abap_bool
           cv_error       TYPE abap_bool.

  DATA:
    vl_tabname TYPE dd02l-tabname,
    wal_dd02v  TYPE dd02v,
    tl_dd03p   TYPE STANDARD TABLE OF dd03p,
    tl_dd05m   TYPE STANDARD TABLE OF dd05m,
    tl_dd08v   TYPE STANDARD TABLE OF dd08v,
    tl_dd12v   TYPE STANDARD TABLE OF dd12v,
    tl_dd17v   TYPE STANDARD TABLE OF dd17v,
    tl_dd35v   TYPE STANDARD TABLE OF dd35v,
    tl_dd36m   TYPE STANDARD TABLE OF dd36m,
    vl_xml     TYPE xstring,
    vl_payload TYPE string.

  CLEAR:
    cv_warning,
    cv_error.

  vl_tabname = iv_object_name.

  TRY.

      CALL FUNCTION 'DDIF_TABL_GET'
        EXPORTING
          name          = vl_tabname
          langu         = sy-langu
        IMPORTING
          dd02v_wa      = wal_dd02v
        TABLES
          dd03p_tab     = tl_dd03p
          dd05m_tab     = tl_dd05m
          dd08v_tab     = tl_dd08v
          dd12v_tab     = tl_dd12v
          dd17v_tab     = tl_dd17v
          dd35v_tab     = tl_dd35v
          dd36m_tab     = tl_dd36m
        EXCEPTIONS
          illegal_input = 1
          OTHERS        = 2.

    CATCH cx_sy_dyn_call_error.
      cv_error = abap_true.
      APPEND '      <message>Error técnico al llamar DDIF_TABL_GET.</message>' TO ct_xml.
      RETURN.
  ENDTRY.

  IF sy-subrc NE 0.
    cv_error = abap_true.
    APPEND '      <message>No se pudo obtener metadata DDIC de TABL/STRU.</message>' TO ct_xml.
    RETURN.
  ENDIF.

  CALL TRANSFORMATION id
    SOURCE dd02v = wal_dd02v
           dd03p = tl_dd03p
           dd05m = tl_dd05m
           dd08v = tl_dd08v
           dd12v = tl_dd12v
           dd17v = tl_dd17v
           dd35v = tl_dd35v
           dd36m = tl_dd36m
    RESULT XML vl_xml.

  PERFORM f_xstring_to_base64
    USING    vl_xml
    CHANGING vl_payload.

  APPEND '      <ddic_payload encoding="base64" transformation="id">' TO ct_xml.
  APPEND |        { vl_payload }| TO ct_xml.
  APPEND '      </ddic_payload>' TO ct_xml.

ENDFORM. " f_export_tabl

FORM f_export_ttyp
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml         TYPE ty_t_xml
           cv_warning     TYPE abap_bool
           cv_error       TYPE abap_bool.

  DATA:
    vl_typename TYPE dd40l-typename,
    wal_dd40v   TYPE dd40v,
    tl_dd42v    TYPE STANDARD TABLE OF dd42v,
    tl_dd43v    TYPE STANDARD TABLE OF dd43v,
    vl_xml      TYPE xstring,
    vl_payload  TYPE string.

  CLEAR:
    cv_warning,
    cv_error.

  vl_typename = iv_object_name.

  CALL FUNCTION 'DDIF_TTYP_GET'
    EXPORTING
      name          = vl_typename
      langu         = sy-langu
    IMPORTING
      dd40v_wa      = wal_dd40v
    TABLES
      dd42v_tab     = tl_dd42v
      dd43v_tab     = tl_dd43v
    EXCEPTIONS
      illegal_input = 1
      OTHERS        = 2.

  IF sy-subrc NE 0.
    cv_error = abap_true.
    APPEND '      <message>No se pudo obtener metadata DDIC de TTYP.</message>' TO ct_xml.
    RETURN.
  ENDIF.

  CALL TRANSFORMATION id
    SOURCE dd40v = wal_dd40v
           dd42v = tl_dd42v
           dd43v = tl_dd43v
    RESULT XML vl_xml.

  PERFORM f_xstring_to_base64
    USING    vl_xml
    CHANGING vl_payload.

  APPEND '      <ddic_payload encoding="base64" transformation="id">' TO ct_xml.
  APPEND |        { vl_payload }| TO ct_xml.
  APPEND '      </ddic_payload>' TO ct_xml.

ENDFORM. " f_export_ttyp

FORM f_export_doma
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml         TYPE ty_t_xml
           cv_warning     TYPE abap_bool
           cv_error       TYPE abap_bool.

  DATA:
    vl_domname TYPE dd01l-domname,
    wal_dd01v  TYPE dd01v,
    tl_dd07v   TYPE STANDARD TABLE OF dd07v,
    vl_xml     TYPE xstring,
    vl_payload TYPE string.

  CLEAR:
    cv_warning,
    cv_error.

  vl_domname = iv_object_name.

  TRY.

      CALL FUNCTION 'DDIF_DOMA_GET'
        EXPORTING
          name          = vl_domname
          langu         = sy-langu
        IMPORTING
          dd01v_wa      = wal_dd01v
        TABLES
          dd07v_tab     = tl_dd07v
        EXCEPTIONS
          illegal_input = 1
          OTHERS        = 2.

    CATCH cx_sy_dyn_call_error.
      cv_error = abap_true.
      APPEND '      <message>Error técnico al llamar DDIF_DOMA_GET.</message>' TO ct_xml.
      RETURN.
  ENDTRY.

  IF sy-subrc NE 0.
    cv_error = abap_true.
    APPEND '      <message>No se pudo obtener metadata DDIC de DOMA.</message>' TO ct_xml.
    RETURN.
  ENDIF.

  CALL TRANSFORMATION id
    SOURCE dd01v = wal_dd01v
           dd07v = tl_dd07v
    RESULT XML vl_xml.

  PERFORM f_xstring_to_base64
    USING    vl_xml
    CHANGING vl_payload.

  APPEND '      <ddic_payload encoding="base64" transformation="id">' TO ct_xml.
  APPEND |        { vl_payload }| TO ct_xml.
  APPEND '      </ddic_payload>' TO ct_xml.

ENDFORM. " f_export_doma

FORM f_export_dtel
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml         TYPE ty_t_xml
           cv_warning     TYPE abap_bool
           cv_error       TYPE abap_bool.

  DATA:
    vl_rollname TYPE dd04l-rollname,
    wal_dd04v   TYPE dd04v,
    vl_xml      TYPE xstring,
    vl_payload  TYPE string.

  CLEAR:
    cv_warning,
    cv_error.

  vl_rollname = iv_object_name.

  TRY.

      CALL FUNCTION 'DDIF_DTEL_GET'
        EXPORTING
          name          = vl_rollname
          langu         = sy-langu
        IMPORTING
          dd04v_wa      = wal_dd04v
        EXCEPTIONS
          illegal_input = 1
          OTHERS        = 2.

    CATCH cx_sy_dyn_call_error.
      cv_error = abap_true.
      APPEND '      <message>Error técnico al llamar DDIF_DTEL_GET.</message>' TO ct_xml.
      RETURN.
  ENDTRY.

  IF sy-subrc NE 0.
    cv_error = abap_true.
    APPEND '      <message>No se pudo obtener metadata DDIC de DTEL.</message>' TO ct_xml.
    RETURN.
  ENDIF.

  CALL TRANSFORMATION id
    SOURCE dd04v = wal_dd04v
    RESULT XML vl_xml.

  PERFORM f_xstring_to_base64
    USING    vl_xml
    CHANGING vl_payload.

  APPEND '      <ddic_payload encoding="base64" transformation="id">' TO ct_xml.
  APPEND |        { vl_payload }| TO ct_xml.
  APPEND '      </ddic_payload>' TO ct_xml.

ENDFORM. " f_export_dtel

FORM f_export_shlp
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml         TYPE ty_t_xml
           cv_warning     TYPE abap_bool
           cv_error       TYPE abap_bool.

  DATA:
    vl_shlpname TYPE dd30l-shlpname,
    wal_dd30v   TYPE dd30v,
    tl_dd31v    TYPE STANDARD TABLE OF dd31v,
    tl_dd32p    TYPE STANDARD TABLE OF dd32p,
    tl_dd33v    TYPE STANDARD TABLE OF dd33v,
    vl_xml      TYPE xstring,
    vl_payload  TYPE string.

  CLEAR:
    cv_warning,
    cv_error.

  vl_shlpname = iv_object_name.

  TRY.

      CALL FUNCTION 'DDIF_SHLP_GET'
        EXPORTING
          name          = vl_shlpname
          langu         = sy-langu
        IMPORTING
          dd30v_wa      = wal_dd30v
        TABLES
          dd31v_tab     = tl_dd31v
          dd32p_tab     = tl_dd32p
          dd33v_tab     = tl_dd33v
        EXCEPTIONS
          illegal_input = 1
          OTHERS        = 2.

    CATCH cx_sy_dyn_call_error.
      cv_error = abap_true.
      APPEND '      <message>Error técnico al llamar DDIF_SHLP_GET.</message>' TO ct_xml.
      RETURN.
  ENDTRY.

  IF sy-subrc NE 0.
    cv_error = abap_true.
    APPEND '      <message>No se pudo obtener metadata DDIC de SHLP.</message>' TO ct_xml.
    RETURN.
  ENDIF.

  CALL TRANSFORMATION id
    SOURCE dd30v = wal_dd30v
           dd31v = tl_dd31v
           dd32p = tl_dd32p
           dd33v = tl_dd33v
    RESULT XML vl_xml.

  PERFORM f_xstring_to_base64
    USING    vl_xml
    CHANGING vl_payload.

  APPEND '      <ddic_payload encoding="base64" transformation="id">' TO ct_xml.
  APPEND |        { vl_payload }| TO ct_xml.
  APPEND '      </ddic_payload>' TO ct_xml.

ENDFORM. " f_export_shlp

FORM f_export_class_or_intf
  USING iv_object_type TYPE string
        iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml TYPE ty_t_xml
           cv_warning TYPE abap_bool
           cv_error TYPE abap_bool.
  DATA: wal_oo TYPE ty_oo_payload,
        wal_key TYPE seoclskey,
        lo_factory TYPE REF TO object,
        lo_source TYPE REF TO object,
        lo_error TYPE REF TO cx_root,
        vl_include TYPE progname,
        vl_xml TYPE xstring,
        vl_payload TYPE string,
        vl_message TYPE string.
  CLEAR: cv_warning, cv_error.
  wal_key-clsname = iv_object_name.
  wal_oo-format = 'OO_SOURCE_1'.
  wal_oo-textpool_language = sy-langu.
  wal_oo-object_type = iv_object_type.
  wal_oo-object_name = iv_object_name.
  TRY.
      CALL FUNCTION 'SEO_CLIF_GET'
        EXPORTING cifkey = wal_key version = '1'
        IMPORTING class = wal_oo-class_properties
                  interface = wal_oo-interface_properties
        EXCEPTIONS OTHERS = 1.
      IF sy-subrc <> 0.
        cv_error = abap_true.
        APPEND '      <message>No se pudieron leer las propiedades OO activas.</message>' TO ct_xml.
        RETURN.
      ENDIF.
      CALL METHOD ('CL_OO_FACTORY')=>('CREATE_INSTANCE') RECEIVING result = lo_factory.
      CALL METHOD lo_factory->('CREATE_CLIF_SOURCE')
        EXPORTING clif_name = wal_key-clsname version = 'A'
        RECEIVING result = lo_source.
      CALL METHOD lo_source->('GET_SOURCE') IMPORTING source = wal_oo-source.
      IF wal_oo-source IS INITIAL.
        cv_error = abap_true.
        APPEND '      <message>La API OO no devolvio el fuente completo.</message>' TO ct_xml.
        RETURN.
      ENDIF.
      IF iv_object_type = 'CLAS'.
        vl_include = cl_oo_classname_service=>get_ccdef_name( wal_key-clsname ).
        READ REPORT vl_include INTO wal_oo-locals_def STATE 'A'.
        vl_include = cl_oo_classname_service=>get_ccimp_name( wal_key-clsname ).
        READ REPORT vl_include INTO wal_oo-locals_imp STATE 'A'.
        vl_include = cl_oo_classname_service=>get_ccmac_name( wal_key-clsname ).
        READ REPORT vl_include INTO wal_oo-macros STATE 'A'.
        vl_include = cl_oo_classname_service=>get_ccau_name( wal_key-clsname ).
        READ REPORT vl_include INTO wal_oo-testclasses STATE 'A'.
        vl_include = cl_oo_classname_service=>get_classpool_name( wal_key-clsname ).
        READ TEXTPOOL vl_include INTO wal_oo-textpool LANGUAGE sy-langu STATE 'A'.
      ENDIF.
      CALL TRANSFORMATION id SOURCE oo = wal_oo RESULT XML vl_xml.
      PERFORM f_xstring_to_base64 USING vl_xml CHANGING vl_payload.
      APPEND '      <seo_payload encoding="base64" transformation="id" format="OO_SOURCE_1">' TO ct_xml.
      APPEND vl_payload TO ct_xml.
      APPEND '      </seo_payload>' TO ct_xml.
    CATCH cx_root INTO lo_error.
      cv_error = abap_true.
      vl_message = lo_error->get_text( ).
      PERFORM f_escape_xml USING vl_message CHANGING vl_message.
      APPEND |      <message>{ vl_message }</message>| TO ct_xml.
  ENDTRY.

ENDFORM. " f_export_class_or_intf

FORM f_export_fugr
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml         TYPE ty_t_xml
           cv_warning     TYPE abap_bool
           cv_error       TYPE abap_bool.

  DATA:
    vl_pname       TYPE tfdir-pname,
    tl_tfdir       TYPE STANDARD TABLE OF tfdir,
    tl_tftit       TYPE STANDARD TABLE OF tftit,
    tl_enlfdir     TYPE STANDARD TABLE OF enlfdir,
    tl_fupararef   TYPE STANDARD TABLE OF fupararef,
    tl_includes    TYPE tyt_progname,
    vl_xml         TYPE xstring,
    vl_payload     TYPE string,
    vl_include_cnt TYPE i,
    vl_fm_count    TYPE i,
    vl_fm_include  TYPE progname.

  CLEAR:
    cv_warning,
    cv_error,
    tl_tfdir,
    tl_tftit,
    tl_enlfdir,
    tl_fupararef,
    tl_includes.

  CONCATENATE 'SAPL' iv_object_name INTO vl_pname.

  SELECT *
    FROM tfdir
    INTO TABLE @tl_tfdir
    WHERE pname = @vl_pname.

  vl_fm_count = lines( tl_tfdir ).

  IF tl_tfdir IS INITIAL.
    cv_warning = abap_true.
    APPEND '      <warning>No se encontraron módulos de función en TFDIR para el grupo.</warning>' TO ct_xml.
  ELSE.

    SELECT *
      FROM tftit
      INTO TABLE @tl_tftit
      FOR ALL ENTRIES IN @tl_tfdir
      WHERE funcname = @tl_tfdir-funcname.

    SELECT *
      FROM enlfdir
      INTO TABLE @tl_enlfdir
      FOR ALL ENTRIES IN @tl_tfdir
      WHERE funcname = @tl_tfdir-funcname.

    SELECT *
      FROM fupararef
      INTO TABLE @tl_fupararef
      FOR ALL ENTRIES IN @tl_tfdir
      WHERE funcname = @tl_tfdir-funcname.

  ENDIF.

  CALL TRANSFORMATION id
    SOURCE tfdir     = tl_tfdir
           tftit     = tl_tftit
           enlfdir   = tl_enlfdir
           fupararef = tl_fupararef
    RESULT XML vl_xml.

  PERFORM f_xstring_to_base64
    USING    vl_xml
    CHANGING vl_payload.

  APPEND |      <function_group_payload encoding="base64" transformation="id" function_count="{ vl_fm_count }">| TO ct_xml.
  APPEND |        { vl_payload }| TO ct_xml.
  APPEND '      </function_group_payload>' TO ct_xml.

  PERFORM f_collect_fugr_includes
    USING    iv_object_name
    CHANGING tl_includes.

  "TRDIR does not reliably list inactive generated Uxx includes on every
  "release. TFDIR is the Function Builder authority for those includes.
  LOOP AT tl_tfdir INTO DATA(wal_tfdir).
    CLEAR vl_fm_include.

    IF wal_tfdir-include CP 'L*'.
      vl_fm_include = wal_tfdir-include.
    ELSEIF wal_tfdir-include CP 'U*'.
      CONCATENATE 'L' iv_object_name wal_tfdir-include INTO vl_fm_include.
    ELSEIF wal_tfdir-include IS NOT INITIAL.
      CONCATENATE 'L' iv_object_name 'U' wal_tfdir-include INTO vl_fm_include.
    ENDIF.

    IF vl_fm_include IS INITIAL.
      cv_warning = abap_true.
      APPEND |      <warning>Módulo { wal_tfdir-funcname } sin include en TFDIR.</warning>| TO ct_xml.
      CONTINUE.
    ENDIF.

    READ TABLE tl_includes WITH KEY table_line = vl_fm_include
      TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.
      APPEND vl_fm_include TO tl_includes.
    ENDIF.
  ENDLOOP.

  SORT tl_includes.
  DELETE ADJACENT DUPLICATES FROM tl_includes.

  LOOP AT tl_includes INTO DATA(vl_owned_include).
    IF vl_owned_include <> vl_pname
    AND vl_owned_include NP |L{ iv_object_name }*|.
      DELETE tl_includes.
    ENDIF.
  ENDLOOP.

  vl_include_cnt = lines( tl_includes ).

  IF vl_include_cnt IS INITIAL.
    cv_warning = abap_true.
    APPEND '      <warning>No se encontraron includes del grupo de funciones.</warning>' TO ct_xml.
  ENDIF.

  APPEND |      <source_includes count="{ vl_include_cnt }">| TO ct_xml.

  LOOP AT tl_includes INTO DATA(vl_include).

    PERFORM f_append_source_include_xml
      USING    vl_include
      CHANGING ct_xml
               cv_warning.

  ENDLOOP.

  APPEND '      </source_includes>' TO ct_xml.

ENDFORM. " f_export_fugr

FORM f_export_idoc_definition
  USING    iv_object_type TYPE string
           iv_object_name TYPE tadir-obj_name
  CHANGING ct_xml         TYPE ty_t_xml
           cv_warning     TYPE abap_bool
           cv_error       TYPE abap_bool.

  DATA:
    vl_tab_warning TYPE abap_bool,
    vl_tab_error   TYPE abap_bool.

  CLEAR:
    cv_warning,
    cv_error,
    vl_tab_warning,
    vl_tab_error.

  APPEND '      <idoc_definition>' TO ct_xml.

  CASE iv_object_type.

    WHEN cg_type_idsg.

      PERFORM f_export_dynamic_table_payload USING 'EDISEGMENT' 'SEGTYP' iv_object_name 'idoc_segment_payload' CHANGING ct_xml cv_warning.
      PERFORM f_export_dynamic_table_payload USING 'EDISEG'     'SEGTYP' iv_object_name 'idoc_segment_payload_alt' CHANGING ct_xml cv_warning.
      PERFORM f_export_dynamic_table_payload USING 'EDISEGT'    'SEGTYP' iv_object_name 'idoc_segment_text_payload' CHANGING ct_xml cv_warning.

      CLEAR:
        vl_tab_warning,
        vl_tab_error.

      PERFORM f_export_tabl
        USING    iv_object_name
        CHANGING ct_xml
                 vl_tab_warning
                 vl_tab_error.

      IF vl_tab_warning = abap_true.
        cv_warning = abap_true.
      ENDIF.

      IF vl_tab_error = abap_true.
        cv_warning = abap_true.
        APPEND '        <warning>No se pudo exportar la estructura DDIC asociada al segmento.</warning>' TO ct_xml.
      ENDIF.

    WHEN cg_type_idbt.
      PERFORM f_export_dynamic_table_payload USING 'EDIMSG' 'IDOCTYP' iv_object_name 'idoc_basic_assignment_payload' CHANGING ct_xml cv_warning.
      PERFORM f_export_dynamic_table_payload USING 'EDBAS'  'IDOCTYP' iv_object_name 'idoc_basic_type_payload' CHANGING ct_xml cv_warning.
      PERFORM f_export_dynamic_table_payload USING 'EDIDO'  'IDOCTYP' iv_object_name 'idoc_basic_structure_payload' CHANGING ct_xml cv_warning.

    WHEN cg_type_idex.
      PERFORM f_export_dynamic_table_payload USING 'EDIMSG' 'CIMTYP' iv_object_name 'idoc_extension_assignment_payload' CHANGING ct_xml cv_warning.
      PERFORM f_export_dynamic_table_payload USING 'EDBAS'  'CIMTYP' iv_object_name 'idoc_extension_payload' CHANGING ct_xml cv_warning.
      PERFORM f_export_dynamic_table_payload USING 'EDIDO'  'CIMTYP' iv_object_name 'idoc_extension_structure_payload' CHANGING ct_xml cv_warning.

    WHEN cg_type_idms.
      PERFORM f_export_dynamic_table_payload USING 'EDMSG'  'MESTYP' iv_object_name 'idoc_message_type_payload' CHANGING ct_xml cv_warning.
      PERFORM f_export_dynamic_table_payload USING 'EDMSGT' 'MESTYP' iv_object_name 'idoc_message_type_text_payload' CHANGING ct_xml cv_warning.
      PERFORM f_export_dynamic_table_payload USING 'EDIMSG' 'MESTYP' iv_object_name 'idoc_message_assignment_payload' CHANGING ct_xml cv_warning.

    WHEN cg_type_idas.
      PERFORM f_export_dynamic_table_payload USING 'EDIMSG' 'MESTYP' iv_object_name 'idoc_we82_assignment_payload' CHANGING ct_xml cv_warning.

    WHEN OTHERS.
      cv_error = abap_true.
      APPEND '        <message>Tipo IDoc no soportado.</message>' TO ct_xml.

  ENDCASE.

  APPEND '      </idoc_definition>' TO ct_xml.

ENDFORM. " f_export_idoc_definition

FORM f_export_dynamic_table_payload
  USING    iv_tabname   TYPE tabname
           iv_fieldname TYPE fieldname
           iv_value     TYPE tadir-obj_name
           iv_node_name TYPE string
  CHANGING ct_xml       TYPE ty_t_xml
           cv_warning   TYPE abap_bool.

  DATA:
    lo_data    TYPE REF TO data,
    vl_where   TYPE string,
    vl_value   TYPE string,
    vl_xml     TYPE xstring,
    vl_payload TYPE string.

  FIELD-SYMBOLS:
    <tl_data> TYPE STANDARD TABLE.

  CLEAR:
    vl_xml,
    vl_payload,
    vl_where.

  vl_value = iv_value.
  PERFORM f_escape_sql_value CHANGING vl_value.

  vl_where = |{ iv_fieldname } = '{ vl_value }'|.

  TRY.

      CREATE DATA lo_data TYPE STANDARD TABLE OF (iv_tabname).
      ASSIGN lo_data->* TO <tl_data>.

      SELECT *
        FROM (iv_tabname)
        INTO TABLE @<tl_data>
        WHERE (vl_where).

      IF <tl_data> IS INITIAL.
        cv_warning = abap_true.
        APPEND |        <warning>No se encontraron datos en { iv_tabname } para { iv_fieldname } = { iv_value }.</warning>| TO ct_xml.
        RETURN.
      ENDIF.

      CALL TRANSFORMATION id
        SOURCE data = <tl_data>
        RESULT XML vl_xml.

      PERFORM f_xstring_to_base64
        USING    vl_xml
        CHANGING vl_payload.

      APPEND |        <{ iv_node_name } table="{ iv_tabname }" field="{ iv_fieldname }" encoding="base64" transformation="id">| TO ct_xml.
      APPEND |          { vl_payload }| TO ct_xml.
      APPEND |        </{ iv_node_name }>| TO ct_xml.

    CATCH cx_sy_create_data_error.
      cv_warning = abap_true.
      APPEND |        <warning>No existe o no se pudo tipar la tabla { iv_tabname }.</warning>| TO ct_xml.

    CATCH cx_sy_dynamic_osql_error.
      cv_warning = abap_true.
      APPEND |        <warning>No se pudo leer { iv_tabname } con campo { iv_fieldname }.</warning>| TO ct_xml.

    CATCH cx_sy_open_sql_db.
      cv_warning = abap_true.
      APPEND |        <warning>Error SQL al leer { iv_tabname }.</warning>| TO ct_xml.

    CATCH cx_root INTO DATA(lo_error).
      cv_warning = abap_true.
      APPEND |        <warning>{ lo_error->get_text( ) }</warning>| TO ct_xml.

  ENDTRY.

ENDFORM. " f_export_dynamic_table_payload

FORM f_detect_includes
  USING    iv_parent_object TYPE tadir-obj_name
           it_source        TYPE ty_t_source
  CHANGING ct_include       TYPE tyt_include.

  DATA:
    vl_line         TYPE string,
    vl_upper        TYPE string,
    vl_include_name TYPE string,
    wal_include     TYPE ty_include.

  CLEAR ct_include.

  LOOP AT it_source INTO vl_line.

    vl_upper = vl_line.
    TRANSLATE vl_upper TO UPPER CASE.
    CONDENSE vl_upper.

    IF vl_upper IS INITIAL
    OR vl_upper(1) = '*'
    OR vl_upper(1) = '"'.
      CONTINUE.
    ENDIF.

    CLEAR vl_include_name.
    FIND PCRE '^INCLUDE[ ]+([A-Z0-9_/]+)[ ]*(IF[ ]+FOUND[ ]*)?\.'
      IN vl_upper SUBMATCHES vl_include_name.
    IF sy-subrc = 0 AND vl_include_name <> 'STRUCTURE'
    AND vl_include_name <> 'TYPE'.

      READ TABLE ct_include
        WITH KEY include_name = vl_include_name
        TRANSPORTING NO FIELDS.

      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      CLEAR wal_include.
      wal_include-parent_object = iv_parent_object.
      wal_include-include_name  = vl_include_name.
      wal_include-found         = abap_false.
      wal_include-line_count    = 0.
      wal_include-message       = 'Detectado'.

      APPEND wal_include TO ct_include.

    ENDIF.

  ENDLOOP.

ENDFORM. " f_detect_includes

FORM f_get_object_text
  USING    iv_object_type TYPE string
           iv_object_name TYPE tadir-obj_name
  CHANGING cv_short_text  TYPE string
           cv_last_change TYPE sy-datum.

  DATA:
    vl_include TYPE progname.

  CLEAR:
    cv_short_text,
    cv_last_change.

  CASE iv_object_type.

    WHEN cg_type_prog.
      SELECT SINGLE text FROM trdirt INTO @cv_short_text WHERE name = @iv_object_name AND sprsl = @sy-langu.
      SELECT SINGLE udat FROM trdir INTO @cv_last_change WHERE name = @iv_object_name.

    WHEN cg_type_tabl OR cg_type_stru.
      SELECT SINGLE ddtext FROM dd02t INTO @cv_short_text WHERE tabname = @iv_object_name AND ddlanguage = @sy-langu AND as4local = 'A'.
      SELECT SINGLE as4date FROM dd02l INTO @cv_last_change WHERE tabname = @iv_object_name AND as4local = 'A'.

    WHEN cg_type_ttyp.
      SELECT SINGLE ddtext FROM dd40t INTO @cv_short_text WHERE typename = @iv_object_name AND ddlanguage = @sy-langu AND as4local = 'A'.
      SELECT SINGLE as4date FROM dd40l INTO @cv_last_change WHERE typename = @iv_object_name AND as4local = 'A'.

    WHEN cg_type_doma.
      SELECT SINGLE ddtext FROM dd01t INTO @cv_short_text WHERE domname = @iv_object_name AND ddlanguage = @sy-langu AND as4local = 'A'.
      SELECT SINGLE as4date FROM dd01l INTO @cv_last_change WHERE domname = @iv_object_name AND as4local = 'A'.

    WHEN cg_type_dtel.
      SELECT SINGLE ddtext FROM dd04t INTO @cv_short_text WHERE rollname = @iv_object_name AND ddlanguage = @sy-langu AND as4local = 'A'.
      SELECT SINGLE as4date FROM dd04l INTO @cv_last_change WHERE rollname = @iv_object_name AND as4local = 'A'.

    WHEN cg_type_shlp.
      SELECT SINGLE ddtext FROM dd30t INTO @cv_short_text WHERE shlpname = @iv_object_name AND ddlanguage = @sy-langu AND as4local = 'A'.
      SELECT SINGLE as4date FROM dd30l INTO @cv_last_change WHERE shlpname = @iv_object_name AND as4local = 'A'.

    WHEN cg_type_clas OR cg_type_intf.
      SELECT SINGLE descript FROM seoclasstx INTO @cv_short_text WHERE clsname = @iv_object_name AND langu = @sy-langu.

      PERFORM f_get_class_pool_include
        USING    iv_object_name
        CHANGING vl_include.

      IF vl_include IS NOT INITIAL.
        SELECT SINGLE udat FROM trdir INTO @cv_last_change WHERE name = @vl_include.
      ENDIF.

    WHEN cg_type_fugr.
      SELECT SINGLE areat FROM tlibt INTO @cv_short_text WHERE area = @iv_object_name AND spras = @sy-langu.

    WHEN OTHERS.
      cv_short_text  = iv_object_type.
      cv_last_change = sy-datum.

  ENDCASE.

ENDFORM. " f_get_object_text

FORM f_get_class_pool_include
  USING    iv_classname TYPE tadir-obj_name
  CHANGING cv_include   TYPE progname.

  DATA:
    vl_classname TYPE string,
    vl_length    TYPE i,
    vl_equals    TYPE i.

  CLEAR cv_include.

  vl_classname = iv_classname.
  vl_length    = strlen( vl_classname ).
  vl_equals    = 30 - vl_length.

  IF vl_equals < 0.
    RETURN.
  ENDIF.

  cv_include = vl_classname.

  DO vl_equals TIMES.
    CONCATENATE cv_include '=' INTO cv_include.
  ENDDO.

  CONCATENATE cv_include 'CP' INTO cv_include.

ENDFORM. " f_get_class_pool_include

FORM f_get_class_include_prefix
  USING    iv_classname TYPE tadir-obj_name
  CHANGING cv_prefix    TYPE progname.

  DATA:
    vl_classname TYPE string,
    vl_length    TYPE i,
    vl_equals    TYPE i.

  CLEAR cv_prefix.

  vl_classname = iv_classname.
  vl_length    = strlen( vl_classname ).
  vl_equals    = 30 - vl_length.

  IF vl_equals < 0.
    RETURN.
  ENDIF.

  cv_prefix = vl_classname.

  DO vl_equals TIMES.
    CONCATENATE cv_prefix '=' INTO cv_prefix.
  ENDDO.

ENDFORM. " f_get_class_include_prefix

FORM f_collect_class_includes
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_includes    TYPE tyt_progname.

  DATA:
    vl_prefix  TYPE progname,
    vl_pattern TYPE progname.

  CLEAR ct_includes.

  PERFORM f_get_class_include_prefix
    USING    iv_object_name
    CHANGING vl_prefix.

  IF vl_prefix IS INITIAL.
    RETURN.
  ENDIF.

  CONCATENATE vl_prefix '%' INTO vl_pattern.

  SELECT name
    FROM trdir
    INTO TABLE @ct_includes
    WHERE name LIKE @vl_pattern.

  SORT ct_includes.
  DELETE ADJACENT DUPLICATES FROM ct_includes.

ENDFORM. " f_collect_class_includes

FORM f_collect_fugr_includes
  USING    iv_object_name TYPE tadir-obj_name
  CHANGING ct_includes    TYPE tyt_progname.

  DATA:
    vl_main_program TYPE progname,
    vl_prefix       TYPE progname,
    vl_pattern      TYPE progname.

  CLEAR ct_includes.

  CONCATENATE 'SAPL' iv_object_name INTO vl_main_program.
  CONCATENATE 'L'    iv_object_name INTO vl_prefix.
  CONCATENATE vl_prefix '%' INTO vl_pattern.

  SELECT name
    FROM trdir
    INTO TABLE @ct_includes
    WHERE name = @vl_main_program
       OR name LIKE @vl_pattern.

  SORT ct_includes.
  DELETE ADJACENT DUPLICATES FROM ct_includes.

ENDFORM. " f_collect_fugr_includes

FORM f_append_source_include_xml
  USING    iv_include_name TYPE progname
  CHANGING ct_xml          TYPE ty_t_xml
           cv_warning      TYPE abap_bool.

  DATA:
    tl_source   TYPE ty_t_source,
    vl_name     TYPE string,
    vl_escaped  TYPE string,
    vl_line_num TYPE i.

  CLEAR:
    tl_source,
    vl_name,
    vl_escaped,
    vl_line_num.

  PERFORM f_escape_xml USING iv_include_name CHANGING vl_name.

  APPEND |        <include name="{ vl_name }">| TO ct_xml.

  READ REPORT iv_include_name INTO tl_source.

  IF sy-subrc NE 0.
    cv_warning = abap_true.
    APPEND '          <warning>No se pudo leer el código fuente del include.</warning>' TO ct_xml.
    APPEND '        </include>' TO ct_xml.
    RETURN.
  ENDIF.

  APPEND |          <line_count>{ lines( tl_source ) }</line_count>| TO ct_xml.
  APPEND '          <source_code>' TO ct_xml.

  LOOP AT tl_source INTO DATA(vl_line).

    vl_line_num = sy-tabix.

    PERFORM f_escape_xml USING vl_line CHANGING vl_escaped.

    APPEND |            <line number="{ vl_line_num }">{ vl_escaped }</line>| TO ct_xml.

  ENDLOOP.

  APPEND '          </source_code>' TO ct_xml.
  APPEND '        </include>' TO ct_xml.

ENDFORM. " f_append_source_include_xml

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
    WHEN cg_type_stru.
      vl_object_type = 'TABL'.
    WHEN cg_type_idsg OR cg_type_idbt OR cg_type_idex OR cg_type_idms OR cg_type_idas.
      MESSAGE 'Navegación directa IDoc no implementada. Usar WE30/WE31/WE81/WE82.' TYPE 'I'.
      RETURN.
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

    WHEN cg_type_prog.
      SET PARAMETER ID 'RID' FIELD iv_object_name.
      CALL TRANSACTION 'SE38' AND SKIP FIRST SCREEN.

    WHEN cg_type_tabl OR cg_type_stru OR cg_type_ttyp OR cg_type_doma OR cg_type_dtel OR cg_type_shlp.
      SET PARAMETER ID 'DTB' FIELD iv_object_name.
      CALL TRANSACTION 'SE11'.

    WHEN cg_type_clas OR cg_type_intf.
      SET PARAMETER ID 'CLS' FIELD iv_object_name.
      CALL TRANSACTION 'SE24' AND SKIP FIRST SCREEN.

    WHEN cg_type_fugr.
      SET PARAMETER ID 'LIB' FIELD iv_object_name.
      CALL TRANSACTION 'SE37'.

  ENDCASE.

ENDFORM. " f_navigate_to_object

FORM f_set_object_status
  USING iv_package     TYPE devclass
        iv_object_type TYPE string
        iv_object_name TYPE tadir-obj_name
        iv_light       TYPE icon_d
        iv_text        TYPE string.

  LOOP AT tg_alv_object ASSIGNING FIELD-SYMBOL(<fsl_object>)
    WHERE package     = iv_package
      AND object_type = iv_object_type
      AND object_name = iv_object_name.

    <fsl_object>-light       = iv_light.
    <fsl_object>-status_text = iv_text.

  ENDLOOP.

ENDFORM. " f_set_object_status

FORM f_download_xml
  USING iv_file TYPE string
        it_xml  TYPE ty_t_xml.

  cl_gui_frontend_services=>gui_download(
    EXPORTING
      filename              = iv_file
      filetype              = 'ASC'
      write_field_separator = abap_false
      trunc_trailing_blanks = abap_false
      codepage              = '4110'
    CHANGING
      data_tab              = it_xml
    EXCEPTIONS
      file_write_error        = 1
      no_batch                = 2
      gui_refuse_filetransfer = 3
      invalid_type            = 4
      no_authority            = 5
      unknown_error           = 6
      header_not_allowed      = 7
      separator_not_allowed   = 8
      filesize_not_allowed    = 9
      header_too_long         = 10
      dp_error_create         = 11
      dp_error_send           = 12
      dp_error_write          = 13
      unknown_dp_error        = 14
      access_denied           = 15
      dp_out_of_memory        = 16
      disk_full               = 17
      dp_timeout              = 18
      file_not_found          = 19
      dataprovider_exception  = 20
      control_flush_error     = 21
      not_supported_by_gui    = 22
      error_no_gui            = 23
      OTHERS                  = 24 ).

  IF sy-subrc NE 0.
    MESSAGE |Error al descargar el XML: { sy-subrc }| TYPE 'E'.
  ENDIF.

ENDFORM. " f_download_xml

FORM f_escape_xml
  USING    iv_input  TYPE any
  CHANGING cv_output TYPE string.

  cv_output = iv_input.

  REPLACE ALL OCCURRENCES OF '&'  IN cv_output WITH '&amp;'.
  REPLACE ALL OCCURRENCES OF '<'  IN cv_output WITH '&lt;'.
  REPLACE ALL OCCURRENCES OF '>'  IN cv_output WITH '&gt;'.
  REPLACE ALL OCCURRENCES OF '"'  IN cv_output WITH '&quot;'.
  REPLACE ALL OCCURRENCES OF '''' IN cv_output WITH '&apos;'.

ENDFORM. " f_escape_xml

FORM f_xstring_to_base64
  USING    iv_xstring TYPE xstring
  CHANGING cv_base64  TYPE string.

  CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
    EXPORTING
      input  = iv_xstring
    IMPORTING
      output = cv_base64.

ENDFORM. " f_xstring_to_base64

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

FORM f_filter_customer_objects.
  DATA vl_customer TYPE abap_bool.
  LOOP AT tg_alv_object INTO DATA(wal_object).
    PERFORM f_is_customer_object
      USING wal_object-object_type wal_object-object_name wal_object-original_system
      CHANGING vl_customer.
    IF vl_customer IS INITIAL.
      DELETE tg_alv_object.
    ENDIF.
  ENDLOOP.
ENDFORM.

* Expand statically identifiable repository dependencies before the ALV is
* displayed.  They remain ordinary ALV rows, so the user can deselect them.
FORM f_expand_program_dependencies.
  DATA: vl_index TYPE i VALUE 1,
        wal_parent TYPE ty_alv_object,
        tl_names TYPE tyt_string,
        tl_object_names TYPE STANDARD TABLE OF tadir-obj_name WITH DEFAULT KEY,
        tl_function_names TYPE STANDARD TABLE OF tfdir-funcname WITH DEFAULT KEY,
        tl_tadir TYPE tyt_tadir,
        tl_function_pools TYPE STANDARD TABLE OF tfdir-pname WITH DEFAULT KEY,
        tl_groups TYPE STANDARD TABLE OF tadir-obj_name WITH DEFAULT KEY,
        tl_group_tadir TYPE tyt_tadir,
        wal_dependency TYPE ty_alv_object,
        vl_scan_program TYPE progname,
        vl_object_type TYPE string,
        vl_cycle TYPE abap_bool,
        vl_text TYPE string,
        vl_date TYPE sy-datum.
  WHILE vl_index <= lines( tg_alv_object ).
    READ TABLE tg_alv_object INTO wal_parent INDEX vl_index.
    CLEAR vl_scan_program.
    IF sy-subrc = 0.
      CASE wal_parent-object_type.
        WHEN cg_type_prog.
          vl_scan_program = wal_parent-object_name.
        WHEN cg_type_clas OR cg_type_intf.
          PERFORM f_get_class_pool_include USING wal_parent-object_name
            CHANGING vl_scan_program.
        WHEN cg_type_fugr.
          vl_scan_program = |SAPL{ wal_parent-object_name }|.
      ENDCASE.
    ENDIF.
    IF vl_scan_program IS NOT INITIAL.
      CLEAR: tl_names, tl_object_names, tl_function_names, tl_tadir,
             tl_function_pools, tl_groups, tl_group_tadir.
      PERFORM f_collect_prog_dep_names
        USING vl_scan_program CHANGING tl_names.
      IF tl_names IS NOT INITIAL.
        LOOP AT tl_names INTO DATA(vl_dependency_name).
          APPEND vl_dependency_name TO tl_object_names.
          APPEND vl_dependency_name TO tl_function_names.
        ENDLOOP.
        SELECT * FROM tadir INTO TABLE @tl_tadir
          FOR ALL ENTRIES IN @tl_object_names
          WHERE pgmid = 'R3TR'
            AND obj_name = @tl_object_names-table_line
            AND srcsystem <> 'SAP'
            AND srcsystem <> @space
            AND genflag <> 'X'
            AND object IN ('PROG', 'TABL', 'DOMA', 'DTEL', 'SHLP', 'CLAS', 'INTF', 'FUGR', 'TTYP', 'MSAG', 'ENQU').
        SELECT pname FROM tfdir INTO TABLE @tl_function_pools
          FOR ALL ENTRIES IN @tl_function_names
          WHERE funcname = @tl_function_names-table_line.
        SORT tl_function_pools.
        DELETE ADJACENT DUPLICATES FROM tl_function_pools.
        LOOP AT tl_function_pools INTO DATA(vl_pool).
          IF vl_pool CP 'SAPL*'.
            APPEND substring( val = vl_pool off = 4 ) TO tl_groups.
          ENDIF.
        ENDLOOP.
        IF tl_groups IS NOT INITIAL.
          SELECT * FROM tadir INTO TABLE @tl_group_tadir
            FOR ALL ENTRIES IN @tl_groups
            WHERE pgmid = 'R3TR' AND object = 'FUGR'
              AND obj_name = @tl_groups-table_line
              AND srcsystem <> 'SAP' AND srcsystem <> @space.
          APPEND LINES OF tl_group_tadir TO tl_tadir.
        ENDIF.
      ENDIF.
      LOOP AT tl_tadir INTO DATA(wal_tadir).
        vl_object_type = wal_tadir-object.
        READ TABLE tg_dependencies TRANSPORTING NO FIELDS
          WITH KEY parent_type = wal_parent-object_type
                   parent_name = wal_parent-object_name
                   object_type = wal_tadir-object
                   object_name = wal_tadir-obj_name.
        IF sy-subrc <> 0.
          APPEND VALUE #( parent_type = wal_parent-object_type
                          parent_name = wal_parent-object_name
                          object_type = wal_tadir-object
                          object_name = wal_tadir-obj_name ) TO tg_dependencies.
        ENDIF.
        READ TABLE tg_alv_object TRANSPORTING NO FIELDS
          WITH KEY object_type = wal_tadir-object object_name = wal_tadir-obj_name.
        IF sy-subrc = 0.
          PERFORM f_dependency_creates_cycle
            USING wal_parent-object_type wal_parent-object_name
                  vl_object_type wal_tadir-obj_name
            CHANGING vl_cycle.
          IF vl_cycle = abap_true.
            wal_parent-light = cg_status_warning.
            wal_parent-status_text = |Ciclo detectado con { wal_tadir-object } { wal_tadir-obj_name }|.
            MODIFY tg_alv_object FROM wal_parent INDEX vl_index.
          ENDIF.
          CONTINUE.
        ENDIF.
        CLEAR: wal_dependency, vl_text, vl_date.
        PERFORM f_get_object_text USING vl_object_type wal_tadir-obj_name
          CHANGING vl_text vl_date.
        wal_dependency-light = cg_status_not_exported.
        wal_dependency-package = wal_tadir-devclass.
        wal_dependency-original_system = wal_tadir-srcsystem.
        wal_dependency-object_type = wal_tadir-object.
        wal_dependency-object_name = wal_tadir-obj_name.
        wal_dependency-target_object_name = wal_tadir-obj_name.
        wal_dependency-short_text = vl_text.
        wal_dependency-masterlang = wal_tadir-masterlang.
        wal_dependency-last_change = vl_date.
        wal_dependency-source_type = 'DEPENDENCY'.
        wal_dependency-relationship = 'DEPENDENCY'.
        wal_dependency-parent_type = wal_parent-object_type.
        wal_dependency-parent_name = wal_parent-object_name.
        wal_dependency-relation_reason = 'STATIC_SOURCE_REFERENCE'.
        wal_dependency-status_text = 'Dependencia detectada; seleccione si desea incluirla'.
        IF wal_tadir-object = 'MSAG' OR wal_tadir-object = 'ENQU'.
          wal_dependency-source_type = 'EXTERNAL_PREREQUISITE'.
          wal_dependency-status_text = 'Prerequisito externo no transportado por esta herramienta'.
        ENDIF.
        APPEND wal_dependency TO tg_alv_object.
      ENDLOOP.
    ENDIF.
    vl_index = vl_index + 1.
  ENDWHILE.
ENDFORM.

FORM f_dependency_creates_cycle
  USING iv_parent_type TYPE string iv_parent_name TYPE tadir-obj_name
        iv_child_type TYPE string iv_child_name TYPE tadir-obj_name
  CHANGING cv_cycle TYPE abap_bool.
  DATA: vl_type TYPE string,
        vl_name TYPE tadir-obj_name,
        vl_steps TYPE i.
  CLEAR cv_cycle.
  vl_type = iv_child_type.
  vl_name = iv_child_name.
  WHILE vl_name IS NOT INITIAL AND vl_steps <= lines( tg_alv_object ).
    IF vl_type = iv_parent_type AND vl_name = iv_parent_name.
      cv_cycle = abap_true.
      RETURN.
    ENDIF.
    READ TABLE tg_alv_object INTO DATA(wal_node)
      WITH KEY object_type = vl_type object_name = vl_name.
    IF sy-subrc <> 0 OR wal_node-parent_name IS INITIAL.
      RETURN.
    ENDIF.
    vl_type = wal_node-parent_type.
    vl_name = wal_node-parent_name.
    vl_steps = vl_steps + 1.
  ENDWHILE.
ENDFORM.

FORM f_collect_prog_dep_names
  USING iv_program TYPE progname
  CHANGING ct_names TYPE tyt_string.
  DATA: tl_source TYPE ty_t_source,
        tl_include_source TYPE ty_t_source,
        tl_includes TYPE tyt_include,
        tl_matches TYPE match_result_tab,
        vl_upper TYPE string,
        vl_token TYPE string.
  CLEAR ct_names.
  READ REPORT iv_program INTO tl_source.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.
  PERFORM f_detect_includes USING iv_program tl_source CHANGING tl_includes.
  LOOP AT tl_includes INTO DATA(wal_include).
    CLEAR tl_include_source.
    READ REPORT wal_include-include_name INTO tl_include_source.
    IF sy-subrc = 0.
      APPEND LINES OF tl_include_source TO tl_source.
    ENDIF.
  ENDLOOP.
  LOOP AT tl_source INTO DATA(vl_line).
    vl_upper = to_upper( vl_line ).
    CLEAR tl_matches.
    FIND ALL OCCURRENCES OF PCRE '[A-Z][A-Z0-9_/]{2,}' IN vl_upper RESULTS tl_matches.
    LOOP AT tl_matches INTO DATA(wal_match).
      vl_token = substring( val = vl_upper off = wal_match-offset len = wal_match-length ).
      IF vl_token <> iv_program.
        APPEND vl_token TO ct_names.
        IF vl_token CP 'ENQUEUE_*' OR vl_token CP 'DEQUEUE_*'.
          APPEND substring( val = vl_token off = 8 ) TO ct_names.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
  SORT ct_names.
  DELETE ADJACENT DUPLICATES FROM ct_names.
ENDFORM.

* Versioned bundle: every component carries its own identity and read error.
FORM f_export_prog_bundle
  USING iv_name TYPE tadir-obj_name it_includes TYPE tyt_include
  CHANGING ct_xml TYPE ty_t_xml cv_warning TYPE abap_bool.
  DATA: wal_bundle TYPE ty_prog_bundle,
        wal_part TYPE ty_prog_component,
        wal_screen TYPE ty_prog_screen,
        wal_cua TYPE ty_prog_cua,
        wal_doc TYPE ty_prog_doc,
        wal_tran TYPE ty_prog_tran,
        wal_tran_config TYPE ty_prog_tran_config,
        vl_tran_error TYPE string,
        vl_added TYPE abap_bool,
        wal_enho TYPE ty_prog_enho,
        wal_enhs TYPE ty_prog_enhs,
        li_spot TYPE REF TO if_enh_spot_tool,
        li_docu TYPE REF TO if_enh_object_docu,
        lo_definition TYPE REF TO cl_enh_tool_hook_def,
        vl_spot_name TYPE enhspotname,
        tl_programs TYPE SORTED TABLE OF progname WITH UNIQUE KEY table_line,
        tl_textpool TYPE STANDARD TABLE OF textpool WITH DEFAULT KEY,
        tl_languages TYPE STANDARD TABLE OF sylangu WITH EMPTY KEY,
        tl_gui_languages TYPE STANDARD TABLE OF sylangu WITH EMPTY KEY,
        tl_screens TYPE STANDARD TABLE OF d020s WITH DEFAULT KEY,
        vl_customer TYPE abap_bool,
        vl_xml TYPE xstring,
        vl_base64 TYPE string,
        vl_enhname TYPE enhname,
        li_tool TYPE REF TO if_enh_tool,
        lo_hook TYPE REF TO cl_enh_tool_hook_impl.
  DATA: lr_screen_titles TYPE REF TO data,
        vl_title_table TYPE tabname VALUE 'D020T',
        vl_title_screen TYPE sy-dynnr.
  FIELD-SYMBOLS: <screen_titles> TYPE STANDARD TABLE,
                 <screen_title> TYPE any,
                 <title_number> TYPE any.

  wal_bundle-format = 'PROGRAM_COMPONENTS_1'.
  wal_bundle-program = iv_name.
  SELECT SINGLE subc FROM trdir INTO wal_bundle-program_type WHERE name = iv_name.
  INSERT iv_name INTO TABLE tl_programs.
  LOOP AT it_includes INTO DATA(wal_include).
    PERFORM f_is_customer_object USING 'PROG' wal_include-include_name space
      CHANGING vl_customer.
    IF vl_customer = abap_true.
      INSERT wal_include-include_name INTO TABLE tl_programs.
    ENDIF.
  ENDLOOP.

  LOOP AT tl_programs INTO DATA(vl_program).
    SELECT DISTINCT language FROM d010tinf INTO TABLE @tl_languages
      WHERE prog = @vl_program AND r3state = 'A'.
    LOOP AT tl_languages INTO DATA(vl_language).
      CLEAR: wal_part, tl_textpool.
      wal_part-kind = 'TEXTPOOL'.
      wal_part-name = vl_program.
      wal_part-language = vl_language.
      READ TEXTPOOL vl_program INTO tl_textpool LANGUAGE vl_language STATE 'A'.
      IF sy-subrc = 0.
        CALL TRANSFORMATION id SOURCE texts = tl_textpool RESULT XML wal_part-content.
      ELSE.
        wal_part-error = 'No se pudo leer un textpool registrado en D010TINF.'.
      ENDIF.
      APPEND wal_part TO wal_bundle-components.
    ENDLOOP.
    SELECT * FROM dokil INTO TABLE @DATA(tl_docs)
      WHERE id = 'RE' AND object = @vl_program AND dokstate = 'A'.
    LOOP AT tl_docs INTO DATA(wal_doc_key).
      CLEAR: wal_part, wal_doc.
      wal_part-kind = 'DOCU'.
      wal_part-name = vl_program.
      wal_part-language = wal_doc_key-langu.
      wal_doc-info = wal_doc_key.
      TRY.
          CALL FUNCTION 'DOCU_READ'
            EXPORTING id = wal_doc_key-id langu = wal_doc_key-langu
                      object = wal_doc_key-object typ = wal_doc_key-typ
                      version = wal_doc_key-version
            IMPORTING head = wal_doc-head
            TABLES line = wal_doc-lines
            EXCEPTIONS error_message = 1 OTHERS = 2.
          IF sy-subrc <> 0.
            wal_part-error = 'DOCU_READ no pudo leer la documentacion.'.
          ELSE.
            CALL TRANSFORMATION id SOURCE document = wal_doc RESULT XML wal_part-content.
          ENDIF.
        CATCH cx_root INTO DATA(lo_error).
          wal_part-error = lo_error->get_text( ).
      ENDTRY.
      APPEND wal_part TO wal_bundle-components.
    ENDLOOP.
  ENDLOOP.

  CALL FUNCTION 'RS_SCREEN_LIST'
    EXPORTING progname = wal_bundle-program dynnr = space
    TABLES dynpros = tl_screens
    EXCEPTIONS not_found = 1 error_message = 2 OTHERS = 3.
  IF sy-subrc > 1.
    APPEND VALUE #( kind = 'DYNP' name = iv_name error = 'RS_SCREEN_LIST fallo.' )
      TO wal_bundle-components.
  ENDIF.
  LOOP AT tl_screens INTO DATA(wal_screen_key)
    WHERE type <> 'S' AND type <> 'W' AND type <> 'J' AND dnum IS NOT INITIAL.
    CLEAR: wal_part, wal_screen.
    wal_part-kind = 'DYNP'.
    wal_part-name = wal_screen_key-dnum.
    TRY.
        CALL FUNCTION 'RPY_DYNPRO_READ'
          EXPORTING progname = wal_bundle-program dynnr = wal_screen_key-dnum
          IMPORTING header = wal_screen-header
          TABLES containers = wal_screen-containers
                 fields_to_containers = wal_screen-fields flow_logic = wal_screen-flow
          EXCEPTIONS error_message = 1 OTHERS = 2.
        IF sy-subrc <> 0.
          wal_part-error = 'RPY_DYNPRO_READ fallo.'.
        ELSE.
          SELECT * FROM d021t INTO TABLE wal_screen-texts
            WHERE prog = wal_bundle-program AND dynr = wal_screen_key-dnum.
          wal_screen-native_header = wal_screen_key.
          CALL FUNCTION 'RPY_DYNPRO_READ_NATIVE'
            EXPORTING progname = wal_bundle-program dynnr = wal_screen_key-dnum
            TABLES fieldlist = wal_screen-native_fields
            EXCEPTIONS error_message = 1 OTHERS = 2.
          IF sy-subrc <> 0.
            wal_part-error = 'No se pudo obtener la representacion nativa del dynpro.'.
          ENDIF.
          LOOP AT wal_screen-fields ASSIGNING FIELD-SYMBOL(<screen_field>).
            ASSIGN COMPONENT 'OUTPUTSTYLE' OF STRUCTURE <screen_field> TO FIELD-SYMBOL(<style>).
            IF sy-subrc = 0 AND <style> = space.
              CLEAR <style>.
            ENDIF.
          ENDLOOP.
          CALL TRANSFORMATION id SOURCE screen = wal_screen RESULT XML wal_part-content.
        ENDIF.
      CATCH cx_root INTO lo_error.
        wal_part-error = lo_error->get_text( ).
    ENDTRY.
    APPEND wal_part TO wal_bundle-components.
  ENDLOOP.

  "Screen-title layouts differ across releases; resolve the key dynamically.
  CLEAR wal_part.
  wal_part-kind = 'DYNTEXT'.
  wal_part-name = iv_name.
  TRY.
      CREATE DATA lr_screen_titles TYPE STANDARD TABLE OF (vl_title_table).
      ASSIGN lr_screen_titles->* TO <screen_titles>.
      SELECT * FROM (vl_title_table) INTO TABLE <screen_titles> WHERE prog = iv_name.
      LOOP AT <screen_titles> ASSIGNING <screen_title>.
        ASSIGN COMPONENT 'DYNR' OF STRUCTURE <screen_title> TO <title_number>.
        IF sy-subrc <> 0.
          ASSIGN COMPONENT 'DNUM' OF STRUCTURE <screen_title> TO <title_number>.
        ENDIF.
        IF sy-subrc <> 0.
          wal_part-error = 'Clave de numero de dynpro desconocida en D020T.'.
          EXIT.
        ENDIF.
        vl_title_screen = <title_number>.
        READ TABLE wal_bundle-components TRANSPORTING NO FIELDS
          WITH KEY kind = 'DYNP' name = vl_title_screen.
        IF sy-subrc <> 0.
          DELETE <screen_titles>.
        ENDIF.
      ENDLOOP.
      IF <screen_titles> IS NOT INITIAL AND wal_part-error IS INITIAL.
        CALL TRANSFORMATION id SOURCE titles = <screen_titles> RESULT XML wal_part-content.
      ENDIF.
    CATCH cx_root INTO lo_error.
      wal_part-error = lo_error->get_text( ).
  ENDTRY.
  IF wal_part-content IS NOT INITIAL OR wal_part-error IS NOT INITIAL.
    APPEND wal_part TO wal_bundle-components.
  ENDIF.

  "Fetch only maintained GUI languages; NOT_FOUND is normal for unused languages.
  SELECT spras FROM t002 INTO TABLE @tl_gui_languages.
  LOOP AT tl_gui_languages INTO DATA(vl_gui_language).
    CLEAR: wal_part, wal_cua.
    wal_part-kind = 'CUAD'.
    wal_part-name = iv_name.
    wal_part-language = vl_gui_language.
    TRY.
        CALL FUNCTION 'RS_CUA_INTERNAL_FETCH'
          EXPORTING program = wal_bundle-program language = vl_gui_language state = 'A'
          IMPORTING adm = wal_cua-adm
          TABLES sta = wal_cua-sta fun = wal_cua-fun men = wal_cua-men
                 mtx = wal_cua-mtx act = wal_cua-act but = wal_cua-but
                 pfk = wal_cua-pfk set = wal_cua-set doc = wal_cua-doc
                 tit = wal_cua-tit biv = wal_cua-biv
          EXCEPTIONS not_found = 1 error_message = 2 OTHERS = 3.
        IF sy-subrc = 1.
          CONTINUE.
        ELSEIF sy-subrc <> 0.
          wal_part-error = 'RS_CUA_INTERNAL_FETCH fallo.'.
        ELSE.
          CALL TRANSFORMATION id SOURCE cua = wal_cua RESULT XML wal_part-content.
        ENDIF.
      CATCH cx_root INTO lo_error.
        wal_part-error = lo_error->get_text( ).
    ENDTRY.
    APPEND wal_part TO wal_bundle-components.
  ENDLOOP.

  SELECT * FROM tstc INTO TABLE @DATA(tl_transactions) WHERE pgmna = @iv_name.
  "Find customer parameter/variant transactions that call a selected transaction.
  SELECT c~* FROM tstc AS c INNER JOIN tadir AS t ON t~obj_name = c~tcode
    INTO TABLE @DATA(tl_indirect_transactions)
    WHERE t~pgmid = 'R3TR' AND t~object = 'TRAN'
      AND t~srcsystem <> 'SAP' AND t~srcsystem <> @space.
  DO.
    CLEAR vl_added.
    LOOP AT tl_indirect_transactions INTO DATA(wal_indirect).
      READ TABLE tl_transactions TRANSPORTING NO FIELDS WITH KEY tcode = wal_indirect-tcode.
      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.
      CLEAR wal_tran.
      SELECT SINGLE * FROM tstcp INTO wal_tran-parameters WHERE tcode = wal_indirect-tcode.
      PERFORM f_program_transaction_config USING wal_indirect wal_tran-parameters
        CHANGING wal_tran_config vl_tran_error.
      IF vl_tran_error IS NOT INITIAL OR wal_tran_config-called IS INITIAL.
        CONTINUE.
      ENDIF.
      READ TABLE tl_transactions TRANSPORTING NO FIELDS WITH KEY tcode = wal_tran_config-called.
      IF sy-subrc = 0.
        APPEND wal_indirect TO tl_transactions.
        vl_added = abap_true.
      ENDIF.
    ENDLOOP.
    IF vl_added IS INITIAL.
      EXIT.
    ENDIF.
  ENDDO.
  LOOP AT tl_transactions INTO DATA(wal_tstc).
    PERFORM f_is_customer_object USING 'TRAN' wal_tstc-tcode space CHANGING vl_customer.
    IF vl_customer IS INITIAL.
      CONTINUE.
    ENDIF.
    CLEAR: wal_part, wal_tran.
    wal_part-kind = 'TRAN'.
    wal_part-name = wal_tstc-tcode.
    SELECT SINGLE srcsystem FROM tadir INTO wal_part-original_system
      WHERE pgmid = 'R3TR' AND object = 'TRAN' AND obj_name = wal_part-name.
    wal_tran-definition = wal_tstc.
    SELECT SINGLE * FROM tstcc INTO wal_tran-gui WHERE tcode = wal_tstc-tcode.
    SELECT SINGLE * FROM tstcp INTO wal_tran-parameters WHERE tcode = wal_tstc-tcode.
    SELECT * FROM tstct INTO TABLE wal_tran-texts WHERE tcode = wal_tstc-tcode.
    SELECT * FROM tstca INTO TABLE wal_tran-auth WHERE tcode = wal_tstc-tcode.
    CALL TRANSFORMATION id SOURCE transaction = wal_tran RESULT XML wal_part-content.
    APPEND wal_part TO wal_bundle-components.
  ENDLOOP.

  "Definitions precede implementations so source enhancement points can be restored.
  SELECT obj_name, srcsystem FROM tadir INTO TABLE @DATA(tl_spots)
    WHERE pgmid = 'R3TR' AND object = 'ENHS' AND srcsystem <> 'SAP' AND srcsystem <> @space.
  LOOP AT tl_spots INTO DATA(wal_spot_key).
    CLEAR: wal_enhs, wal_part, li_spot, lo_definition.
    TRY.
        vl_spot_name = wal_spot_key-obj_name.
        li_spot = cl_enh_factory=>get_enhancement_spot( spot_name = vl_spot_name run_dark = abap_true ).
        IF li_spot->get_tool( ) <> cl_enh_tool_hook_def=>tool_type.
          CONTINUE.
        ENDIF.
        lo_definition ?= li_spot.
        lo_definition->get_original_object(
          IMPORTING pgmid = wal_enhs-pgmid obj_name = wal_enhs-obj_name
                    obj_type = wal_enhs-obj_type main_type = wal_enhs-main_type
                    main_name = wal_enhs-main_name program = wal_enhs-program ).
        READ TABLE tl_programs TRANSPORTING NO FIELDS WITH TABLE KEY table_line = wal_enhs-program.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        li_docu ?= li_spot.
        wal_enhs-shorttext = li_docu->get_shorttext( ).
        wal_enhs-definitions = lo_definition->get_hook_defs( ).
        wal_part-kind = 'ENHS'.
        wal_part-name = wal_spot_key-obj_name.
        wal_part-original_system = wal_spot_key-srcsystem.
        CALL TRANSFORMATION id SOURCE spot = wal_enhs RESULT XML wal_part-content.
        APPEND wal_part TO wal_bundle-components.
      CATCH cx_root INTO lo_error.
        APPEND VALUE #( kind = 'DISCOVERY' name = wal_spot_key-obj_name
                        error = lo_error->get_text( ) ) TO wal_bundle-components.
    ENDTRY.
  ENDLOOP.
  "Use Enhancement Framework ownership, not ENHO name prefixes or source regex.
  SELECT obj_name, srcsystem FROM tadir INTO TABLE @DATA(tl_enhancements)
    WHERE pgmid = 'R3TR' AND object = 'ENHO' AND srcsystem <> 'SAP' AND srcsystem <> @space.
  LOOP AT tl_enhancements INTO DATA(wal_enh_key).
    CLEAR: wal_enho, wal_part, lo_hook, li_tool.
    TRY.
        vl_enhname = wal_enh_key-obj_name.
        li_tool = cl_enh_factory=>get_enhancement(
          enhancement_id = vl_enhname run_dark = abap_true bypassing_buffer = abap_true ).
        IF li_tool->get_tool( ) <> cl_enh_tool_hook_impl=>tooltype.
          CONTINUE.
        ENDIF.
        lo_hook ?= li_tool.
        lo_hook->get_original_object(
          IMPORTING pgmid = wal_enho-original-pgmid obj_name = wal_enho-original-org_obj_name
                    obj_type = wal_enho-original-org_obj_type
                    main_type = wal_enho-original-org_main_type
                    main_name = wal_enho-original-org_main_name
                    program = wal_enho-original-programname ).
        READ TABLE tl_programs TRANSPORTING NO FIELDS
          WITH TABLE KEY table_line = wal_enho-original-programname.
        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.
        wal_part-kind = 'ENHO'.
        wal_part-name = wal_enh_key-obj_name.
        wal_part-original_system = wal_enh_key-srcsystem.
        wal_enho-shorttext = lo_hook->if_enh_object_docu~get_shorttext( ).
        wal_enho-hooks = lo_hook->get_hook_impls( ).
        SELECT SINGLE subc FROM trdir INTO @DATA(vl_enh_subc)
          WHERE name = @wal_enho-original-programname.
        wal_enho-original-include_bound = xsdbool( vl_enh_subc = 'I' ).
        LOOP AT wal_enho-hooks ASSIGNING FIELD-SYMBOL(<hook>).
          CLEAR: <hook>-extid, <hook>-id.
        ENDLOOP.
        CALL TRANSFORMATION id SOURCE enhancement = wal_enho RESULT XML wal_part-content.
        APPEND wal_part TO wal_bundle-components.
      CATCH cx_root INTO lo_error.
        "A failed lookup cannot establish association: disclose discovery gap.
        wal_part-kind = 'DISCOVERY'.
        wal_part-name = wal_enh_key-obj_name.
        wal_part-error = lo_error->get_text( ).
        APPEND wal_part TO wal_bundle-components.
    ENDTRY.
  ENDLOOP.
  LOOP AT wal_bundle-components TRANSPORTING NO FIELDS WHERE error IS NOT INITIAL.
    cv_warning = abap_true.
    EXIT.
  ENDLOOP.
  CALL TRANSFORMATION id SOURCE bundle = wal_bundle RESULT XML vl_xml.
  PERFORM f_xstring_to_base64 USING vl_xml CHANGING vl_base64.
  APPEND '      <program_payload encoding="base64" transformation="id" format="PROGRAM_COMPONENTS_1">' TO ct_xml.
  APPEND vl_base64 TO ct_xml.
  APPEND '      </program_payload>' TO ct_xml.
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

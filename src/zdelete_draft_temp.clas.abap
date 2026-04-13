CLASS zdelete_draft_temp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zdelete_draft_temp IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    DELETE FROM zwarehouse_d.
    COMMIT WORK.
    out->write( 'Draft table cleared!' ).

    DELETE FROM zwarehouse.
    COMMIT WORK.
    out->write( 'DB table cleared!' ).

  ENDMETHOD.
ENDCLASS.

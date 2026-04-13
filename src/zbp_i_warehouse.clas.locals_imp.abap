CLASS lhc_warehouse DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS create_warehouse FOR MODIFY
      IMPORTING entities FOR CREATE Warehouse.
    METHODS update_warehouse FOR MODIFY
      IMPORTING entities FOR UPDATE Warehouse.
    METHODS delete_warehouse FOR MODIFY
      IMPORTING entities FOR DELETE Warehouse.
    METHODS read_warehouse FOR READ
      IMPORTING keys FOR READ Warehouse
      RESULT result.
    METHODS lock_warehouse FOR LOCK
      IMPORTING keys FOR LOCK Warehouse.
ENDCLASS.

CLASS lhc_warehouse IMPLEMENTATION.

  METHOD create_warehouse.
  LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
    CHECK <entity>-%is_draft = if_abap_behv=>mk-off.

    " ✅ FIX 1: Check for duplicate key before inserting
    SELECT SINGLE warehouse_id
      FROM zwarehouse
      WHERE warehouse_id = @<entity>-WarehouseId
      INTO @DATA(lv_existing).

    IF sy-subrc = 0.
      " Record already exists — report conflict, skip
      APPEND VALUE #(
        %cid        = <entity>-%cid
        WarehouseId = <entity>-WarehouseId
      ) TO failed-warehouse.
      APPEND VALUE #(
        %cid        = <entity>-%cid
        WarehouseId = <entity>-WarehouseId
        %msg        = new_message_with_text(
                        severity = if_abap_behv_message=>severity-error
                        text     = 'Warehouse already exists' )
      ) TO reported-warehouse.
      CONTINUE.  " ✅ FIX 2: Skip, don't attempt double-insert
    ENDIF.

    DATA ls_warehouse TYPE zwarehouse.
    ls_warehouse-client         = sy-mandt.
    ls_warehouse-warehouse_id   = <entity>-WarehouseId.
    ls_warehouse-warehouse_name = <entity>-WarehouseName.
    ls_warehouse-location       = <entity>-Location.
    ls_warehouse-capacity       = <entity>-Capacity.
    ls_warehouse-used_capacity  = <entity>-UsedCapacity.
    ls_warehouse-manager_id     = <entity>-ManagerId.
    ls_warehouse-status         = <entity>-Status.
    ls_warehouse-created_by     = sy-uname.
    GET TIME STAMP FIELD ls_warehouse-created_at.
    GET TIME STAMP FIELD ls_warehouse-changed_at.

    " ✅ FIX 3: Use INSERT instead of MODIFY to explicitly catch duplicates
    INSERT zwarehouse FROM @ls_warehouse.

    IF sy-subrc <> 0.
      APPEND VALUE #(
        %cid        = <entity>-%cid
        WarehouseId = <entity>-WarehouseId
      ) TO failed-warehouse.
      APPEND VALUE #(
        %cid        = <entity>-%cid
        WarehouseId = <entity>-WarehouseId
        %msg        = new_message_with_text(
                        severity = if_abap_behv_message=>severity-error
                        text     = 'Create failed' )
      ) TO reported-warehouse.
    ENDIF.

  ENDLOOP.
ENDMETHOD.

  METHOD update_warehouse.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      CHECK <entity>-%is_draft = if_abap_behv=>mk-off.
      DATA ls_warehouse TYPE zwarehouse.
      SELECT SINGLE * FROM zwarehouse
        WHERE warehouse_id = @<entity>-WarehouseId
        INTO @ls_warehouse.
      IF sy-subrc <> 0.
        APPEND VALUE #( WarehouseId = <entity>-WarehouseId ) TO failed-warehouse.
        APPEND VALUE #(
          WarehouseId = <entity>-WarehouseId
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Warehouse not found' )
        ) TO reported-warehouse.
        CONTINUE.
      ENDIF.
      IF <entity>-%control-WarehouseName = cl_abap_behv=>flag_changed.
        ls_warehouse-warehouse_name = <entity>-WarehouseName.
      ENDIF.
      IF <entity>-%control-Location = cl_abap_behv=>flag_changed.
        ls_warehouse-location = <entity>-Location.
      ENDIF.
      IF <entity>-%control-Capacity = cl_abap_behv=>flag_changed.
        ls_warehouse-capacity = <entity>-Capacity.
      ENDIF.
      IF <entity>-%control-UsedCapacity = cl_abap_behv=>flag_changed.
        ls_warehouse-used_capacity = <entity>-UsedCapacity.
      ENDIF.
      IF <entity>-%control-ManagerId = cl_abap_behv=>flag_changed.
        ls_warehouse-manager_id = <entity>-ManagerId.
      ENDIF.
      IF <entity>-%control-Status = cl_abap_behv=>flag_changed.
        ls_warehouse-status = <entity>-Status.
      ENDIF.
      GET TIME STAMP FIELD ls_warehouse-changed_at.
      MODIFY zwarehouse FROM @ls_warehouse.
      IF sy-subrc <> 0.
        APPEND VALUE #( WarehouseId = <entity>-WarehouseId ) TO failed-warehouse.
        APPEND VALUE #(
          WarehouseId = <entity>-WarehouseId
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Update failed' )
        ) TO reported-warehouse.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete_warehouse.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      CHECK <entity>-%is_draft = if_abap_behv=>mk-off.
      DELETE FROM zwarehouse
        WHERE warehouse_id = @<entity>-WarehouseId.
      IF sy-subrc <> 0.
        APPEND VALUE #( WarehouseId = <entity>-WarehouseId ) TO failed-warehouse.
        APPEND VALUE #(
          WarehouseId = <entity>-WarehouseId
          %msg        = new_message_with_text(
                          severity = if_abap_behv_message=>severity-error
                          text     = 'Delete failed' )
        ) TO reported-warehouse.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_warehouse.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      SELECT SINGLE * FROM zwarehouse
        WHERE warehouse_id = @<key>-WarehouseId
        INTO @DATA(ls_warehouse).
      IF sy-subrc = 0.
        APPEND VALUE #(
          WarehouseId   = ls_warehouse-warehouse_id
          WarehouseName = ls_warehouse-warehouse_name
          Location      = ls_warehouse-location
          Capacity      = ls_warehouse-capacity
          UsedCapacity  = ls_warehouse-used_capacity
          ManagerId     = ls_warehouse-manager_id
          Status        = ls_warehouse-status
          CreatedBy     = ls_warehouse-created_by
          CreatedAt     = ls_warehouse-created_at
          ChangedAt     = ls_warehouse-changed_at
        ) TO result.
      ELSE.
        APPEND VALUE #( WarehouseId = <key>-WarehouseId ) TO failed-warehouse.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock_warehouse.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      TRY.
          cl_abap_lock_object_factory=>get_instance(
            iv_name = 'EZWAREHOUSE' )->enqueue(
              it_table_mode = VALUE #(
                ( table_name = 'ZWAREHOUSE' ) ) ).
        CATCH cx_abap_lock_failure cx_abap_foreign_lock INTO DATA(lx_lock).
          APPEND VALUE #( WarehouseId = <key>-WarehouseId ) TO failed-warehouse.
          APPEND VALUE #(
            WarehouseId = <key>-WarehouseId
            %msg        = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = lx_lock->get_text( ) )
          ) TO reported-warehouse.
      ENDTRY.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

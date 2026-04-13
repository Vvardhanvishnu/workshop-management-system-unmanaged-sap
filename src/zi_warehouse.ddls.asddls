@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Warehouse Management Interface View'

define root view entity ZI_WAREHOUSE
  as select from zwarehouse
{
  key warehouse_id    as WarehouseId,
      warehouse_name  as WarehouseName,
      location        as Location,
      capacity        as Capacity,
      used_capacity   as UsedCapacity,
      manager_id      as ManagerId,
      status          as Status,
      created_by      as CreatedBy,
      created_at      as CreatedAt,
      changed_at      as ChangedAt
}

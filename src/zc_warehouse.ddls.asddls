@EndUserText.label: 'Warehouse Management Projection View'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define root view entity ZC_WAREHOUSE
  as projection on ZI_WAREHOUSE
{
  key WarehouseId,
      WarehouseName,
      Location,
      Capacity,
      UsedCapacity,
      ManagerId,
      Status,
      CreatedBy,
      CreatedAt,
      ChangedAt
}

USE SHOPEE_CLONE
GO


/********************************************************************
  TRG 1 + 3: RÀNG BUỘC TRÊN BẢNG SHIPMENT
  1. Shipment chỉ được tạo cho đơn có status “Đang giao” hoặc “Đã giao”.
  3. Ngày giao (ở đây dùng cột payment_date) phải >= ngày đặt hàng
     (ở đây dùng ORDER_GROUP.created_at).
********************************************************************/
CREATE OR ALTER TRIGGER trg_SHIPMENT_BusinessRules
ON dbo.SHIPMENT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. Shipment chỉ được tạo cho đơn có status “Đang giao”/“Đã giao”
    --    Lấy trạng thái mới nhất trong ORDER_STATUS cho mỗi đơn hàng.
    ------------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN dbo.[ORDER] o
               ON o.order_id = i.order_id
        OUTER APPLY (
            SELECT TOP (1) os.[status]
            FROM dbo.ORDER_STATUS os
            WHERE os.order_id = o.order_id
            ORDER BY os.status_timestamp DESC, os.order_status_id DESC
        ) cur
        WHERE i.order_id IS NULL              -- shipment không gắn order
           OR o.order_id IS NULL              -- order_id không tồn tại
           OR cur.[status] IS NULL            -- chưa có trạng thái
           OR cur.[status] NOT IN (N'Đang giao', N'Đã giao')
    )
    BEGIN
        RAISERROR (
          N'SHIPMENT vi phạm ràng buộc: Shipment chỉ được tạo cho đơn hàng có trạng thái ''Đang giao'' hoặc ''Đã giao''.',
          16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    ------------------------------------------------------------
    -- 3. Ngày giao (payment_date) phải >= ngày đặt hàng
    --    Ở đây: ORDER_GROUP.created_at chính là ngày đặt hàng.
    --    Cho phép payment_date = NULL (chưa có ngày giao).
    ------------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.[ORDER] o
             ON o.order_id = i.order_id
        JOIN dbo.ORDER_GROUP og
             ON og.order_group_id = o.order_group_id
        WHERE i.payment_date IS NOT NULL
          AND i.payment_date < og.created_at
    )
    BEGIN
        RAISERROR (
          N'SHIPMENT vi phạm ràng buộc: Ngày giao (payment_date) phải lớn hơn hoặc bằng ngày đặt hàng (ORDER_GROUP.created_at).',
          16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO


/********************************************************************
  TRG 2: MỖI SHIPMENT CHỈ CÓ MỘT SHIPMENT_STATUS DUY NHẤT
  - Không cho phép:
      + Insert nhiều bản ghi cùng shipment_id trong một batch
      + Insert thêm status cho shipment đã có status trước đó
********************************************************************/
CREATE OR ALTER TRIGGER trg_SHIPMENT_STATUS_OnePerShipment
ON dbo.SHIPMENT_STATUS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 2.1. Kiểm tra trong batch INSERT: 1 shipment_id xuất hiện > 1 lần
    ------------------------------------------------------------
    IF EXISTS (
        SELECT shipment_id
        FROM inserted
        GROUP BY shipment_id
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR (
          N'Ràng buộc: Mỗi Shipment chỉ được phép có một bản ghi Shipment_Status (không thể thêm nhiều status cùng lúc).',
          16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    ------------------------------------------------------------
    -- 2.2. Kiểm tra shipment đã có status trong bảng SHIPMENT_STATUS
    ------------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.SHIPMENT_STATUS s
             ON s.shipment_id = i.shipment_id
            AND s.status_id <> i.status_id   -- loại trừ chính dòng vừa insert
    )
    BEGIN
        RAISERROR (
          N'Ràng buộc: Mỗi Shipment chỉ được phép có một bản ghi Shipment_Status.',
          16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO


/********************************************************************
  TRG 4: REVIEW CHỈ ĐƯỢC VIẾT SAU KHI ĐƠN HÀNG ĐÃ GIAO THÀNH CÔNG
  Ý tưởng:
  - Review(product_id, customer_id) chỉ hợp lệ nếu tồn tại ít nhất
    một đơn của customer đó mua đúng product đó và đơn có status 'Đã giao'.

  - Liên kết:
      REVIEW (product_id, customer_id)
      -> ORDER_DETAIL.product_id
      -> ORDER.order_id, ORDER.customer_id
      -> ORDER_STATUS.status = 'Đã giao'
********************************************************************/
CREATE OR ALTER TRIGGER trg_REVIEW_OnlyAfterDelivered
ON dbo.REVIEW
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Tìm những review mới/được sửa mà KHÔNG tìm được đơn 'Đã giao' tương ứng
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.ORDER_DETAIL od
            JOIN dbo.[ORDER] o
                 ON o.order_id = od.order_id
            JOIN dbo.ORDER_STATUS os
                 ON os.order_id = o.order_id
            WHERE od.product_id = i.product_id
              AND o.customer_id = i.customer_id
              AND os.[status] = N'Đã giao'
        )
    )
    BEGIN
        RAISERROR (
          N'Review vi phạm ràng buộc: Khách chỉ được đánh giá sản phẩm sau khi đã có ít nhất một đơn hàng ''Đã giao'' với sản phẩm đó.',
          16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO


PRINT N'--- ĐÃ TẠO CÁC TRIGGER RÀNG BUỘC NGHIỆP VỤ (SHIPMENT & REVIEW) ---';
GO

USE SHOPEE_CLONE;
GO

-- Triggers cho các ràng buộc nghiệp vụ 

/********************************************************************
  TRG 1 + 3: RÀNG BUỘC TRÊN BẢNG SHIPMENT
  1. Shipment chỉ được tạo cho đơn có status “Đang giao” hoặc “Đã giao”.
     (status của đơn lấy từ ORDER_STATUS – trạng thái MỚI NHẤT)
  3. Ngày giao (ở đây dùng cột payment_date) phải >= ngày đặt hàng
     (ORDER_GROUP.created_at).
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
        FROM inserted AS i
        LEFT JOIN dbo.[ORDER] AS o
               ON o.order_id = i.order_id
        OUTER APPLY (
            SELECT TOP (1) os.[status]
            FROM dbo.ORDER_STATUS AS os
            WHERE os.order_id = o.order_id
            ORDER BY os.status_timestamp DESC, os.order_status_id DESC
        ) AS cur
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
        RETURN;
    END;

    ------------------------------------------------------------
    -- 3. Ngày giao (payment_date) phải >= ngày đặt hàng
    --    Ở đây: ORDER_GROUP.created_at chính là ngày đặt hàng.
    --    Cho phép payment_date = NULL (chưa cập nhật ngày giao).
    ------------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        JOIN dbo.[ORDER] AS o
             ON o.order_id = i.order_id
        JOIN dbo.ORDER_GROUP AS og
             ON og.order_group_id = o.order_group_id
        WHERE i.payment_date IS NOT NULL
          AND i.payment_date < og.created_at
    )
    BEGIN
        RAISERROR (
          N'SHIPMENT vi phạm ràng buộc: Ngày giao (payment_date) phải lớn hơn hoặc bằng ngày đặt hàng (ORDER_GROUP.created_at).',
          16, 1
        );
        RETURN;
    END;
END;
GO


/********************************************************************
  TRG 2: MỖI SHIPMENT CHỈ CÓ MỘT SHIPMENT_STATUS DUY NHẤT
  - Không cho phép:
      + Insert nhiều bản ghi cùng shipment_id trong một batch
      + Hoặc sau khi insert xong, tổng số status cho shipment đó > 1
********************************************************************/
CREATE OR ALTER TRIGGER trg_SHIPMENT_STATUS_OnePerShipment
ON dbo.SHIPMENT_STATUS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Sau khi insert, nếu bất kỳ shipment_id nào có > 1 dòng status → vi phạm
    IF EXISTS (
        SELECT ss.shipment_id
        FROM dbo.SHIPMENT_STATUS AS ss
        WHERE ss.shipment_id IN (SELECT shipment_id FROM inserted)
        GROUP BY ss.shipment_id
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR (
          N'Ràng buộc: Mỗi Shipment chỉ được phép có một bản ghi Shipment_Status.',
          16, 1
        );
        RETURN;
    END;
END;
GO


/********************************************************************
  TRG 4: REVIEW CHỈ ĐƯỢC VIẾT SAU KHI ĐƠN HÀNG ĐÃ GIAO THÀNH CÔNG

  Ý tưởng:
  - Review(product_id, customer_id, created_at) chỉ hợp lệ nếu tồn tại
    ít nhất một đơn:
      + Customer đó đã mua đúng product đó
      + Đơn có status 'Đã giao'
      + Thời điểm 'Đã giao' <= thời điểm tạo review

  Liên kết:
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
        FROM inserted AS i
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.ORDER_DETAIL AS od
            JOIN dbo.[ORDER] AS o
                 ON o.order_id = od.order_id
            JOIN dbo.ORDER_STATUS AS os
                 ON os.order_id = o.order_id
            WHERE od.product_id      = i.product_id
              AND o.customer_id      = i.customer_id
              AND os.[status]        = N'Đã giao'
              AND (i.created_at IS NULL OR os.status_timestamp <= i.created_at)
        )
    )
    BEGIN
        RAISERROR (
          N'Review vi phạm ràng buộc: Khách chỉ được đánh giá sản phẩm sau khi đã có ít nhất một đơn hàng ''Đã giao'' với sản phẩm đó.',
          16, 1
        );
        RETURN;
    END;
END;
GO


PRINT N'--- ĐÃ TẠO CÁC TRIGGER RÀNG BUỘC NGHIỆP VỤ (SHIPMENT & REVIEW) ---';
GO

-- Triggers cho các thuộc tính dẫn xuất (sửa lại cho đúng logic EERD)

/********************************************************************
1. CUSTOMER.total_spending
   = tổng ORDER_GROUP.total_payment của từng customer.
********************************************************************/
CREATE OR ALTER TRIGGER trg_CUSTOMER_UpdateTotalSpending
ON dbo.ORDER_GROUP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedCustomers AS (
        SELECT customer_id FROM inserted
        UNION
        SELECT customer_id FROM deleted
    ),
    DistinctCustomers AS (
        SELECT DISTINCT customer_id
        FROM ChangedCustomers
        WHERE customer_id IS NOT NULL
    )
    UPDATE c
    SET total_spending = ISNULL(sum_og.SumPayment, 0)
    FROM dbo.CUSTOMER c
    JOIN DistinctCustomers dc
         ON c.customer_id = dc.customer_id
    OUTER APPLY (
        SELECT SUM(ISNULL(og.total_payment, 0)) AS SumPayment
        FROM dbo.ORDER_GROUP og
        WHERE og.customer_id = dc.customer_id
    ) AS sum_og;
END;
GO


/********************************************************************
2. ORDER_DETAIL.total_price = quantity * price
   - Cập nhật mỗi khi INSERT/UPDATE ORDER_DETAIL
********************************************************************/
CREATE OR ALTER TRIGGER trg_ORDER_DETAIL_SetTotalPrice
ON dbo.ORDER_DETAIL
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Tránh trigger tự gọi lại chính nó khi mình UPDATE ORDER_DETAIL
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    UPDATE od
    SET total_price = i.quantity * i.price
    FROM dbo.ORDER_DETAIL od
    JOIN inserted i
         ON od.order_detail_id = i.order_detail_id;
END;
GO


/********************************************************************
3 + 5 + 7. Từ ORDER_DETAIL dẫn xuất:
   - ORDER.total_amount      = SUM(quantity * price) theo order_id
   - PRODUCT_VARIANT.total_sales = SUM(quantity) theo product_id
   - SHOP.Total_sales        = tổng quantity của các sản phẩm thuộc shop đó
********************************************************************/
USE SHOPEE_CLONE;
GO

CREATE OR ALTER TRIGGER trg_ORDER_DETAIL_UpdateAggregates
ON dbo.ORDER_DETAIL
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------
    -- 3. Cập nhật ORDER.total_amount
    --------------------------------------------------------
    ;WITH ChangedOrders AS (
        SELECT order_id FROM inserted
        UNION
        SELECT order_id FROM deleted
    ),
    DistinctOrders AS (
        SELECT DISTINCT order_id
        FROM ChangedOrders
        WHERE order_id IS NOT NULL
    )
    UPDATE o
    SET total_amount = ISNULL(SumOrder.SumAmount, 0)
    FROM dbo.[ORDER] o
    JOIN DistinctOrders d
         ON o.order_id = d.order_id
    OUTER APPLY (
        SELECT SUM(od.quantity * od.price) AS SumAmount
        FROM dbo.ORDER_DETAIL od
        WHERE od.order_id = d.order_id
    ) AS SumOrder;

    --------------------------------------------------------
    -- 5. Cập nhật PRODUCT_VARIANT.total_sales
    --------------------------------------------------------
    ;WITH ChangedProducts AS (
        SELECT product_id FROM inserted
        UNION
        SELECT product_id FROM deleted
    ),
    DistinctProducts AS (
        SELECT DISTINCT product_id
        FROM ChangedProducts
        WHERE product_id IS NOT NULL
    )
    UPDATE pv
    SET total_sales = ISNULL(SumProd.SumQty, 0)
    FROM dbo.PRODUCT_VARIANT pv
    JOIN DistinctProducts dp
         ON pv.prod_id = dp.product_id
    OUTER APPLY (
        SELECT SUM(od.quantity) AS SumQty
        FROM dbo.ORDER_DETAIL od
        WHERE od.product_id = dp.product_id
    ) AS SumProd;

    --------------------------------------------------------
    -- 7. Cập nhật SHOP.Total_sales
    --------------------------------------------------------
    ;WITH ChangedProducts AS (
        SELECT product_id FROM inserted
        UNION
        SELECT product_id FROM deleted
    ),
    DistinctProducts AS (
        SELECT DISTINCT product_id
        FROM ChangedProducts
        WHERE product_id IS NOT NULL
    ),
    ChangedShops AS (
        SELECT DISTINCT it.shop_id
        FROM DistinctProducts dp
        JOIN dbo.PRODUCT_VARIANT pv
             ON pv.prod_id = dp.product_id
        JOIN dbo.ITEM it
             ON it.item_id = pv.item_id
        WHERE it.shop_id IS NOT NULL
    )
    UPDATE s
    SET Total_sales = ISNULL(SumShop.SumQty, 0)
    FROM dbo.SHOP s
    JOIN ChangedShops cs
         ON s.shop_id = cs.shop_id
    OUTER APPLY (
        SELECT SUM(od.quantity) AS SumQty
        FROM dbo.ORDER_DETAIL od
        JOIN dbo.PRODUCT_VARIANT pv
             ON pv.prod_id = od.product_id
        JOIN dbo.ITEM it
             ON it.item_id = pv.item_id
        WHERE it.shop_id = cs.shop_id
    ) AS SumShop;
END;
GO


/********************************************************************
4. CART.total_product, CART.total_payment
   - Dẫn xuất từ CART_ITEM (quantity, sub_total)
********************************************************************/
CREATE OR ALTER TRIGGER trg_CART_ITEM_UpdateCartTotals
ON dbo.CART_ITEM
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedCarts AS (
        SELECT cart_id FROM inserted
        UNION
        SELECT cart_id FROM deleted
    ),
    DistinctCarts AS (
        SELECT DISTINCT cart_id
        FROM ChangedCarts
        WHERE cart_id IS NOT NULL
    )
    UPDATE c
    SET total_product = ISNULL(t.SumQty, 0),
        total_payment = ISNULL(t.SumSubTotal, 0)
    FROM dbo.CART c
    JOIN DistinctCarts d
         ON c.cart_id = d.cart_id
    OUTER APPLY (
        SELECT
            SUM(ci.quantity)   AS SumQty,
            SUM(ci.sub_total)  AS SumSubTotal
        FROM dbo.CART_ITEM ci
        WHERE ci.cart_id = d.cart_id
    ) AS t;
END;
GO


/********************************************************************
6. PRODUCT_VARIANT.rating_avg
   - Dẫn xuất từ REVIEW.rating
********************************************************************/
CREATE OR ALTER TRIGGER trg_REVIEW_UpdateRatingAvg
ON dbo.REVIEW
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedProducts AS (
        SELECT product_id FROM inserted
        UNION
        SELECT product_id FROM deleted
    ),
    DistinctProducts AS (
        SELECT DISTINCT product_id
        FROM ChangedProducts
        WHERE product_id IS NOT NULL
    )
    UPDATE pv
    SET rating_avg = ISNULL(r.AvgRating, 0)
    FROM dbo.PRODUCT_VARIANT pv
    JOIN DistinctProducts dp
         ON pv.prod_id = dp.product_id
    OUTER APPLY (
        SELECT AVG(CAST(rw.rating AS FLOAT)) AS AvgRating
        FROM dbo.REVIEW rw
        WHERE rw.product_id = dp.product_id
    ) AS r;
END;
GO


PRINT N'--- ĐÃ TẠO CÁC TRIGGER CHO CÁC THUỘC TÍNH DẪN XUẤT ---';
GO
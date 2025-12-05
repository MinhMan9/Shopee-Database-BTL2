USE SHOPEE_CLONE;
GO

/* ==========================================================
   TRIGGERS RÀNG BUỘC NGHIỆP VỤ
   ========================================================== */

----------------------------------------------------------------
-- TRG 1 + 3: SHIPMENT – kiểm tra trạng thái đơn & ngày giao dự kiến
-- 1. Shipment chỉ cho đơn có trạng thái “Đang giao” / “Đã giao”
--    (lấy trạng thái MỚI NHẤT từ ORDER_STATUS)
-- 3. Ngày giao dự kiến (estimated_delivery) phải >= ngày đặt hàng
--    (ORDER_GROUP.created_at)
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_SHIPMENT_BusinessRules
ON dbo.SHIPMENT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- 1. Chỉ tạo shipment cho đơn đang giao / đã giao
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
        WHERE i.order_id IS NULL          -- shipment không gắn order
           OR o.order_id IS NULL          -- order_id không tồn tại
           OR cur.[status] IS NULL        -- đơn chưa có trạng thái
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
    -- 3. estimated_delivery phải >= ngày đặt hàng (ORDER_GROUP.created_at)
    --    Cho phép estimated_delivery = NULL (chưa dự kiến ngày giao).
    ------------------------------------------------------------
    IF EXISTS (
        SELECT 1
        FROM inserted AS i
        JOIN dbo.[ORDER] AS o
             ON o.order_id = i.order_id
        JOIN dbo.ORDER_GROUP AS og
             ON og.order_group_id = o.order_group_id
        WHERE i.estimated_delivery IS NOT NULL
          AND i.estimated_delivery < og.created_at
    )
    BEGIN
        RAISERROR (
          N'SHIPMENT vi phạm ràng buộc: Ngày giao dự kiến (estimated_delivery) phải lớn hơn hoặc bằng ngày đặt hàng (ORDER_GROUP.created_at).',
          16, 1
        );
        RETURN;
    END;
END;
GO

----------------------------------------------------------------
-- TRG 2: Mỗi SHIPMENT chỉ có 1 Shipment_Status
--  (theo đúng yêu cầu bài, dù dữ liệu mẫu đang có >1 status/shipment)
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_SHIPMENT_STATUS_OnePerShipment
ON dbo.SHIPMENT_STATUS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT ss.shipment_id
        FROM dbo.SHIPMENT_STATUS AS ss
        WHERE ss.shipment_id IN (SELECT shipment_id FROM inserted)
        GROUP BY ss.shipment_id
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR (
          N'Vi phạm Ràng buộc: Mỗi Shipment chỉ được phép có một bản ghi Shipment_Status.',
          16, 1
        );
        RETURN;
    END;
END;
GO

----------------------------------------------------------------
-- TRG 6: ORDER_STATUS – chỉ được hủy khi chưa xử lý/giao
--  “Đã hủy” chỉ hợp lệ nếu trước đó chưa từng có
--  'Đang xử lý' / 'Đang giao' / 'Đã giao'
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_CheckCancelOrder
ON dbo.ORDER_STATUS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE [status] = N'Đã hủy')
    BEGIN
        IF EXISTS (
            SELECT 1 
            FROM dbo.ORDER_STATUS os
            JOIN inserted i ON os.order_id = i.order_id
            WHERE os.[status] IN (N'Đang xử lý', N'Đang giao', N'Đã giao')
              AND os.order_status_id < i.order_status_id
        )
        BEGIN
            RAISERROR(N'Không thể hủy đơn hàng đang xử lý, đang giao hoặc đã giao.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO

----------------------------------------------------------------
-- TRG 7: ORDER_DETAIL – sản phẩm chỉ bán khi đủ tồn kho
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_CheckStockAvailable
ON dbo.ORDER_DETAIL
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.PRODUCT_VARIANT p ON i.product_id = p.prod_id
        WHERE i.quantity > p.stock_quantity
    )
    BEGIN
        RAISERROR(N'Sản phẩm không đủ số lượng tồn kho để thực hiện giao dịch.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

----------------------------------------------------------------
-- TRG 8: PAYMENT – khi thanh toán Completed -> trừ tồn kho
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_UpdateStockOnPayment
ON dbo.PAYMENT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Tránh trigger lồng nhau quá sâu
    IF TRIGGER_NESTLEVEL() > 1 RETURN;

    ;WITH CompletedOrders AS (
        SELECT DISTINCT order_id
        FROM inserted
        WHERE [status] = N'Completed'
          AND order_id IS NOT NULL
    ),
    QtyByProduct AS (
        SELECT od.product_id,
               SUM(od.quantity) AS TotalQty
        FROM dbo.ORDER_DETAIL od
        JOIN CompletedOrders co
          ON od.order_id = co.order_id
        GROUP BY od.product_id
    )
    UPDATE pv
    SET pv.stock_quantity = pv.stock_quantity - q.TotalQty
    FROM dbo.PRODUCT_VARIANT pv
    JOIN QtyByProduct q
      ON pv.prod_id = q.product_id;
END;
GO

----------------------------------------------------------------
-- TRG 9: ORDER_STATUS – không cho chuyển sang “Chờ xác nhận”
--       nếu tồn kho không đủ
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_PreventConfirmIfNoStock
ON dbo.ORDER_STATUS
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE [status] = N'Chờ xác nhận')
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted i
            JOIN dbo.ORDER_DETAIL od ON i.order_id = od.order_id
            JOIN dbo.PRODUCT_VARIANT p ON od.product_id = p.prod_id
            WHERE od.quantity > p.stock_quantity
        )
        BEGIN
            RAISERROR(N'Không thể xác nhận đơn hàng vì một số sản phẩm đã hết hàng.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO

----------------------------------------------------------------
-- TRG 10: ORDER_GROUP – kiểm tra voucher hợp lệ & min spending
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_ValidateVoucher
ON dbo.ORDER_GROUP
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM inserted WHERE voucher_id IS NOT NULL)
    BEGIN
        DECLARE @CurrentDate DATETIME = GETDATE();

        -- 1. Hạn dùng & số lượng còn lại
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            JOIN dbo.VOUCHER v ON i.voucher_id = v.voucher_id
            WHERE @CurrentDate < v.valid_from
               OR @CurrentDate > v.valid_to
               OR v.quantity_available <= 0
        )
        BEGIN
            RAISERROR(N'Voucher không hợp lệ, đã hết hạn hoặc hết lượt sử dụng.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END;

        -- 2. Điều kiện min spending (min_50k, min_1M, min_0, new_member,...)
        IF EXISTS (
            SELECT 1
            FROM inserted i
            JOIN dbo.VOUCHER v ON i.voucher_id = v.voucher_id
            CROSS APPLY (
                SELECT CASE 
                    -- min_50k -> 50 * 1000
                    WHEN v.[condition] LIKE 'min_%k' THEN
                        TRY_CAST(SUBSTRING(v.[condition],5,LEN(v.[condition]) - 5) AS DECIMAL(18,2)) * 1000
                    -- min_1M -> 1 * 1.000.000
                    WHEN v.[condition] LIKE 'min_%M' THEN
                        TRY_CAST(SUBSTRING(v.[condition],5,LEN(v.[condition]) - 5) AS DECIMAL(18,2)) * 1000000
                    -- min_0, min_500000, ...
                    WHEN v.[condition] LIKE 'min_%'
                         AND v.[condition] NOT LIKE '%k'
                         AND v.[condition] NOT LIKE '%M' THEN
                        TRY_CAST(SUBSTRING(v.[condition],5,LEN(v.[condition]) - 4) AS DECIMAL(18,2))
                    -- new_member, ... -> không ràng buộc số tiền
                    ELSE 0
                END AS MinSpendRequired
            ) AS RuleCalc
            WHERE i.total_amount < RuleCalc.MinSpendRequired
        )
        BEGIN
            RAISERROR(N'Đơn hàng chưa đạt giá trị tối thiểu để áp dụng Voucher này.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO

----------------------------------------------------------------
-- TRG 4: REVIEW – chỉ được viết sau khi có đơn “Đã giao”
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_REVIEW_OnlyAfterDelivered
ON dbo.REVIEW
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

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
            WHERE od.product_id = i.product_id
              AND o.customer_id = i.customer_id
              AND os.[status]   = N'Đã giao'
              AND (i.created_at IS NULL OR os.status_timestamp <= i.created_at)
        )
    )
    BEGIN
        RAISERROR(
          N'Review vi phạm ràng buộc: Khách chỉ được đánh giá sản phẩm sau khi đã có ít nhất một đơn hàng ''Đã giao'' với sản phẩm đó.',
          16, 1
        );
        RETURN;
    END;
END;
GO

PRINT N'--- ĐÃ TẠO CÁC TRIGGER RÀNG BUỘC NGHIỆP VỤ ---';
GO


/* ==========================================================
   TRIGGERS CHO CÁC THUỘC TÍNH DẪN XUẤT
   ========================================================== */

----------------------------------------------------------------
-- 1. CUSTOMER.total_spending = SUM(ORDER_GROUP.total_payment)
----------------------------------------------------------------
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

----------------------------------------------------------------
-- 2. ORDER_DETAIL.total_price = quantity * price
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_ORDER_DETAIL_SetTotalPrice
ON dbo.ORDER_DETAIL
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE od
    SET total_price = i.quantity * i.price
    FROM dbo.ORDER_DETAIL od
    JOIN inserted i
      ON od.order_detail_id = i.order_detail_id;
END;
GO

----------------------------------------------------------------
-- 3 + 5 + 7. ORDER.total_amount, PRODUCT_VARIANT.total_sales, SHOP.Total_sales
----------------------------------------------------------------
CREATE OR ALTER TRIGGER trg_ORDER_DETAIL_UpdateAggregates
ON dbo.ORDER_DETAIL
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------
    -- 3. ORDER.total_amount
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
    -- 5. PRODUCT_VARIANT.total_sales
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
    -- 7. SHOP.Total_sales
    --------------------------------------------------------
    ;WITH ChangedProducts2 AS (
        SELECT product_id FROM inserted
        UNION
        SELECT product_id FROM deleted
    ),
    DistinctProducts2 AS (
        SELECT DISTINCT product_id
        FROM ChangedProducts2
        WHERE product_id IS NOT NULL
    ),
    ChangedShops AS (
        SELECT DISTINCT it.shop_id
        FROM DistinctProducts2 dp
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

----------------------------------------------------------------
-- 4. CART.total_product, CART.total_payment
----------------------------------------------------------------
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
            SUM(ci.quantity)  AS SumQty,
            SUM(ci.sub_total) AS SumSubTotal
        FROM dbo.CART_ITEM ci
        WHERE ci.cart_id = d.cart_id
    ) AS t;
END;
GO

----------------------------------------------------------------
-- 6. PRODUCT_VARIANT.rating_avg = AVG(REVIEW.rating)
----------------------------------------------------------------
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

USE SHOPEE_CLONE
GO



/********************************************************************
  TRG 6: RÀNG BUỘC TRÊN BẢNG ORDER_STATUS
  6. Đơn hàng chỉ được hủy nếu nó còn trước trạng thái “Đang xử lý”
********************************************************************/
CREATE TRIGGER trg_CheckCancelOrder
ON ORDER_STATUS
FOR INSERT
AS
BEGIN
    -- Chỉ kiểm tra nếu trạng thái mới thêm vào là 'Đã hủy'
    IF EXISTS (SELECT 1 FROM inserted WHERE status = N'Đã hủy')
    BEGIN
        -- Kiểm tra xem đơn hàng này đã từng qua trạng thái 'Đang xử lý', 'Đang giao', 'Đã giao' chưa
        IF EXISTS (
            SELECT 1 
            FROM ORDER_STATUS os
            JOIN inserted i ON os.order_id = i.order_id
            WHERE os.status IN (N'Đang xử lý', N'Đang giao', N'Đã giao')
            AND os.order_status_id < i.order_status_id -- Đảm bảo check các trạng thái cũ hơn
        )
        BEGIN
            RAISERROR(N'Không thể hủy đơn hàng đang giao hoặc đã giao.', 16, 1);
            ROLLBACK TRANSACTION;
        END
    END
END;
GO


/********************************************************************
  TRG 7: RÀNG BUỘC TRÊN BẢNG ORDER_DETAIL
  7. Sản phẩm chỉ được bán khi còn hàng và không vượt tồn kho
********************************************************************/
CREATE TRIGGER trg_CheckStockAvailable
ON ORDER_DETAIL
FOR INSERT, UPDATE
AS
BEGIN
    -- Kiểm tra nếu số lượng đặt > số lượng tồn kho
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN PRODUCT_VARIANT p ON i.product_id = p.prod_id
        WHERE i.quantity > p.stock_quantity
    )
    BEGIN
        RAISERROR(N'Sản phẩm không đủ số lượng tồn kho để thực hiện giao dịch.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO


/********************************************************************
  TRG 8: RÀNG BUỘC TRÊN BẢNG PAYMENT
  8. Khi order được thanh toán -> trừ tồn kho
********************************************************************/
CREATE TRIGGER trg_UpdateStockOnPayment
ON PAYMENT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ xử lý khi trạng thái là 'Completed' (Đã thanh toán)
    IF EXISTS (SELECT 1 FROM inserted WHERE status = N'Completed')
    BEGIN
        -- Cập nhật tồn kho
        UPDATE p
        SET p.stock_quantity = p.stock_quantity - od.quantity,
            p.total_sales = ISNULL(p.total_sales, 0) + od.quantity -- Tiện thể cập nhật luôn số đã bán
        FROM PRODUCT_VARIANT p
        JOIN ORDER_DETAIL od ON p.prod_id = od.product_id
        JOIN [ORDER] o ON od.order_id = o.order_id
        JOIN inserted i ON o.order_id = i.order_id
        WHERE i.status = N'Completed';
    END
END;
GO


/********************************************************************
  TRG 9: RÀNG BUỘC TRÊN BẢNG ORDER_STATUS
  9. Nếu tồn kho không đủ, Order không được tạo hoặc xác nhận
********************************************************************/
CREATE TRIGGER trg_PreventConfirmIfNoStock
ON ORDER_STATUS
FOR INSERT
AS
BEGIN
    -- Khi trạng thái chuyển sang 'Chờ xác nhận'
    IF EXISTS (SELECT 1 FROM inserted WHERE status = N'Chờ xác nhận')
    BEGIN
        -- Kiểm tra lại tồn kho của tất cả sản phẩm trong đơn hàng đó
        IF EXISTS (
            SELECT 1
            FROM inserted i
            JOIN ORDER_DETAIL od ON i.order_id = od.order_id
            JOIN PRODUCT_VARIANT p ON od.product_id = p.prod_id
            WHERE od.quantity > p.stock_quantity
        )
        BEGIN
            RAISERROR(N'Không thể xác nhận đơn hàng vì một số sản phẩm đã hết hàng.', 16, 1);
            ROLLBACK TRANSACTION;
        END
    END
END;
GO


/********************************************************************
  TRG 10: RÀNG BUỘC TRÊN BẢNG ORDER_GROUP
  10. Voucher phải còn hiệu lực tại thời điểm sử dụng và đủ điều kiện cần thiết
********************************************************************/
CREATE TRIGGER trg_ValidateVoucher
ON ORDER_GROUP
FOR INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE voucher_id IS NOT NULL)
    BEGIN
        DECLARE @CurrentDate DATETIME = GETDATE();

        -- 1. Kiểm tra ngày hiệu lực và số lượng voucher
        IF EXISTS (
            SELECT 1 
            FROM inserted i
            JOIN VOUCHER v ON i.voucher_id = v.voucher_id
            WHERE (@CurrentDate < v.valid_from OR @CurrentDate > v.valid_to) -- Hết hạn
               OR v.quantity_available <= 0 -- Hết lượt dùng
        )
        BEGIN
            RAISERROR(N'Voucher không hợp lệ, đã hết hạn hoặc hết lượt sử dụng.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- 2. Kiểm tra điều kiện giá trị đơn hàng (Total Amount >= Condition)
        -- Lưu ý: Cần đảm bảo column 'condition' chứa số. Dùng TRY_CAST để an toàn.
        IF EXISTS (
            SELECT 1
            FROM inserted i
            JOIN VOUCHER v ON i.voucher_id = v.voucher_id
            CROSS APPLY (
                -- Logic tách chuỗi để lấy giá trị tối thiểu
                SELECT CASE 
                    -- Trường hợp đuôi 'k' (VD: min_50k -> 50 * 1000)
                    WHEN v.condition LIKE 'min_%k' THEN 
                        TRY_CAST(SUBSTRING(v.condition, 5, LEN(v.condition) - 5) AS DECIMAL(18,2)) * 1000
                    
                    -- Trường hợp đuôi 'M' (VD: min_1M -> 1 * 1.000.000)
                    WHEN v.condition LIKE 'min_%M' THEN 
                        TRY_CAST(SUBSTRING(v.condition, 5, LEN(v.condition) - 5) AS DECIMAL(18,2)) * 1000000
                    
                    -- Trường hợp chỉ có số (VD: min_0)
                    WHEN v.condition LIKE 'min_%' AND v.condition NOT LIKE '%k' AND v.condition NOT LIKE '%M' THEN 
                        TRY_CAST(SUBSTRING(v.condition, 5, LEN(v.condition) - 4) AS DECIMAL(18,2))
                    
                    -- Các trường hợp đặc biệt khác (VD: new_member) -> Coi như điều kiện tiền = 0
                    ELSE 0 
                END AS MinSpendRequired
            ) AS RuleCalc
            WHERE i.total_amount < RuleCalc.MinSpendRequired
        )
        BEGIN
            RAISERROR(N'Đơn hàng chưa đạt giá trị tối thiểu để áp dụng Voucher này.', 16, 1);
            ROLLBACK TRANSACTION;
        END
    END
END;
GO
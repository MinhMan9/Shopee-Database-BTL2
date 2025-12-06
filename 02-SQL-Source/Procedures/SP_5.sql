-- SP_5.sql
-- Yêu cầu: Câu truy vấn đơn giản 2 bảng trở lên có mệnh đề WHERE, ORDER BY
-- Procedure lấy danh sách đơn hàng của Shop (Kèm thông tin khách hàng)

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('sp_GetShopOrderList') IS NOT NULL
    DROP PROCEDURE sp_GetShopOrderList;
GO

CREATE PROCEDURE sp_GetShopOrderList
    @ShopID INT,
    @Limit INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Limit)
        O.order_id,
        OG.created_at AS OrderDate,
        C.customer_id,
        U.username AS CustomerName,
        O.total_amount,
        OS.status AS OrderStatus
    FROM [ORDER] O
    INNER JOIN ORDER_GROUP OG ON O.order_group_id = OG.order_group_id
    INNER JOIN CUSTOMER C ON O.customer_id = C.customer_id
    INNER JOIN [USER] U ON C.customer_id = U.user_id
    LEFT JOIN ORDER_STATUS OS ON O.order_id = OS.order_id
    WHERE O.shop_id = @ShopID
    ORDER BY OG.created_at DESC;
END;
GO

-- Ví dụ gọi Procedure:
-- Lấy 10 đơn hàng mới nhất của Shop ID = 3
EXEC sp_GetShopOrderList @ShopID = 3, @Limit = 10;
-- Lấy 5 đơn hàng mới nhất của Shop ID = 4
EXEC sp_GetShopOrderList @ShopID = 4, @Limit = 5;


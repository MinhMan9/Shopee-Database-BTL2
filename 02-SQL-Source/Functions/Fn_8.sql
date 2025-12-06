-- Fn_8.sql
-- Description: Tính điểm khách hàng thân thiết (Loyalty Score)
-- Yêu cầu: Sử dụng CURSOR để duyệt qua các đơn hàng

-- Kiểm tra và xóa function nếu đã tồn tại
IF OBJECT_ID('fn_CalculateCustomerLoyaltyScore') IS NOT NULL
    DROP FUNCTION fn_CalculateCustomerLoyaltyScore;
GO

CREATE FUNCTION fn_CalculateCustomerLoyaltyScore (@customer_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @TotalScore INT = 0;
    DECLARE @OrderTotal DECIMAL(18,2);
    
    -- Khai báo Cursor
    DECLARE order_cursor CURSOR FOR
    SELECT total_amount 
    FROM ORDER_GROUP 
    WHERE customer_id = @customer_id;
    
    OPEN order_cursor;
    
    FETCH NEXT FROM order_cursor INTO @OrderTotal;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Logic tính điểm: Mỗi 100,000đ = 1 điểm + 10 điểm thưởng mỗi đơn
        SET @TotalScore = @TotalScore + CAST((@OrderTotal / 100000) AS INT) + 10;
        
        FETCH NEXT FROM order_cursor INTO @OrderTotal;
    END;
    
    CLOSE order_cursor;
    DEALLOCATE order_cursor;
    
    RETURN @TotalScore;
END;
GO

-- Ví dụ gọi Hàm:
-- Tính điểm thân thiết cho khách hàng ID = 1
SELECT dbo.fn_CalculateCustomerLoyaltyScore(1) AS LoyaltyScore_Cus1;
-- Tính điểm thân thiết cho khách hàng ID = 2
SELECT dbo.fn_CalculateCustomerLoyaltyScore(2) AS LoyaltyScore_Cus2;


GO
-- =============================================
CREATE FUNCTION fn_CalculateShopRevenue (@shop_id INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @TotalRevenue DECIMAL(18,2);
    
    SELECT @TotalRevenue = SUM(O.total_amount)
    FROM [ORDER] O
    -- Giả sử trạng thái đơn hàng nằm trong bảng ORDER_STATUS và lấy trạng thái mới nhất
    -- Tuy nhiên để đơn giản hóa theo schema, ta tính tổng các đơn hàng thuộc shop đó
    WHERE O.shop_id = @shop_id;

    RETURN ISNULL(@TotalRevenue, 0);
END;
GO

-- =============================================
-- Description: Tính điểm đánh giá trung bình của Shop
-- =============================================
CREATE FUNCTION fn_CalculateShopRating (@shop_id INT)
RETURNS DECIMAL(3,2)
AS
BEGIN
    DECLARE @AvgRating DECIMAL(3,2);
    
    SELECT @AvgRating = AVG(CAST(R.rating AS DECIMAL(3,2)))
    FROM REVIEW R
    INNER JOIN PRODUCT_VARIANT PV ON R.product_id = PV.prod_id
    INNER JOIN ITEM I ON PV.item_id = I.item_id
    WHERE I.shop_id = @shop_id;

    RETURN ISNULL(@AvgRating, 0);
END;
GO

-- =============================================
-- Description: Đếm số lượng sản phẩm sắp hết hàng (Stock <= ngưỡng)
-- =============================================
CREATE FUNCTION fn_CountLowStockProducts (@shop_id INT, @threshold INT)
RETURNS INT
AS
BEGIN
    DECLARE @Count INT;
    
    SELECT @Count = COUNT(PV.prod_id)
    FROM PRODUCT_VARIANT PV
    INNER JOIN ITEM I ON PV.item_id = I.item_id
    WHERE I.shop_id = @shop_id AND PV.stock_quantity <= @threshold;

    RETURN @Count;
END;
GO


-- =============================================
-- Description: Tính điểm khách hàng thân thiết (Loyalty Score)
-- Yêu cầu: Sử dụng CURSOR để duyệt qua các đơn hàng
-- =============================================
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


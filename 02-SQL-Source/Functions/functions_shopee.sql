
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

-- Description: Tính điểm đánh giá trung bình của Shop
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

-- Description: Đếm số lượng sản phẩm sắp hết hàng (Stock <= ngưỡng)
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

-- Description: Tính điểm khách hàng thân thiết (Loyalty Score)
-- Yêu cầu: Sử dụng CURSOR để duyệt qua các đơn hàng
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
GO
-- =============================================
-- [NEW] FUNCTION: Tính doanh thu theo tháng của Shop
-- =============================================
CREATE FUNCTION fn_GetShopMonthlyRevenue (@shop_id INT, @month INT, @year INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @MonthlyRevenue DECIMAL(18,2);
    
    SELECT @MonthlyRevenue = SUM(O.total_amount)
    FROM [ORDER] O
    INNER JOIN ORDER_GROUP OG ON O.order_group_id = OG.order_group_id
    WHERE O.shop_id = @shop_id 
      AND MONTH(OG.created_at) = @month 
      AND YEAR(OG.created_at) = @year;

    RETURN ISNULL(@MonthlyRevenue, 0);
END;
GO

-- =============================================
-- [NEW] FUNCTION: Lấy tên sản phẩm bán chạy nhất của Shop
-- =============================================
CREATE FUNCTION fn_GetShopBestSellingProduct (@shop_id INT)
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @ProdName NVARCHAR(200);
    
    SELECT TOP 1 @ProdName = PV.prod_name
    FROM PRODUCT_VARIANT PV
    INNER JOIN ITEM I ON PV.item_id = I.item_id
    WHERE I.shop_id = @shop_id
    ORDER BY PV.total_sales DESC;

    RETURN @ProdName;
END;
GO

GO
-- =============================================
-- [NEW] FUNCTION: Tính điểm hoạt động của Shop (Dùng Cursor) - Yêu cầu 2.4
-- =============================================
CREATE FUNCTION fn_CalculateShopActivityScore (@ShopID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Score INT = 0;
    DECLARE @OrderTotal DECIMAL(18,2);
    
    -- Khai báo con trỏ để duyệt qua các đơn hàng của Shop
    DECLARE order_cursor CURSOR FOR 
    SELECT total_amount 
    FROM [ORDER] 
    WHERE shop_id = @ShopID;
    
    OPEN order_cursor;
    
    FETCH NEXT FROM order_cursor INTO @OrderTotal;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Logic tính điểm: Đơn > 1tr được 10 điểm, ngược lại 1 điểm
        IF @OrderTotal > 1000000
            SET @Score = @Score + 10;
        ELSE
            SET @Score = @Score + 1;
            
        FETCH NEXT FROM order_cursor INTO @OrderTotal;
    END
    
    CLOSE order_cursor;
    DEALLOCATE order_cursor;
    
    RETURN @Score;
END;
GO

-- =============================================
-- [NEW] FUNCTION: Kiểm tra trạng thái tồn kho (Dùng IF/ELSE) - Yêu cầu 2.4
-- =============================================
CREATE FUNCTION fn_CheckStockStatus (@ProdID INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @Stock INT;
    DECLARE @Status NVARCHAR(50);
    
    SELECT @Stock = stock_quantity FROM PRODUCT_VARIANT WHERE prod_id = @ProdID;
    
    IF @Stock IS NULL
        RETURN N'Không tồn tại';
        
    IF @Stock = 0
        SET @Status = N'Hết hàng';
    ELSE IF @Stock < 10
        SET @Status = N'Sắp hết hàng';
    ELSE
        SET @Status = N'Còn hàng';
        
    RETURN @Status;
END;
GO

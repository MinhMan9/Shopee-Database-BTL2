-- Fn_6.sql
-- Description: Tính điểm đánh giá trung bình của Shop

-- Kiểm tra và xóa function nếu đã tồn tại
IF OBJECT_ID('fn_CalculateShopRating') IS NOT NULL
    DROP FUNCTION fn_CalculateShopRating;
GO

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

-- Ví dụ gọi Hàm:
-- Tính rating trung bình cho Shop có ID = 3
SELECT dbo.fn_CalculateShopRating(3) AS ShopRating_ID3;
-- Tính rating trung bình cho Shop có ID = 4
SELECT dbo.fn_CalculateShopRating(4) AS ShopRating_ID4;

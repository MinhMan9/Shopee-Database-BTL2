-- SP_4.sql
-- Yêu cầu: Liệt kê sản phẩm, lấy dữ liệu trực tiếp từ PRODUCT_VARIANT

-- Kiểm tra và xóa procedure nếu đã tồn tại
IF OBJECT_ID('sp_GetShopProductList') IS NOT NULL
    DROP PROCEDURE sp_GetShopProductList;
GO

CREATE PROCEDURE sp_GetShopProductList
    @ShopID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        I.item_id,
        I.item_name,
        PV.prod_id AS variant_id,
        PV.prod_name AS variant_name,
        PV.price,
        PV.stock_quantity AS stock,
        PV.total_sales
    FROM ITEM I
    INNER JOIN PRODUCT_VARIANT PV ON I.item_id = PV.item_id
    WHERE I.shop_id = @ShopID
    ORDER BY I.item_id DESC;
END;
GO

-- Ví dụ gọi Procedure:
-- Lấy danh sách sản phẩm của Shop ID = 3
EXEC sp_GetShopProductList @ShopID = 3;
-- Lấy danh sách sản phẩm của Shop ID = 4
EXEC sp_GetShopProductList @ShopID = 4;


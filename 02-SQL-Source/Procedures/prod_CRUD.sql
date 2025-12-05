USE SHOPEE_CLONE
GO
------------------------------------------------------------
-- STORED PROCEDURES – PHẦN 2.1: GIỎ HÀNG (CART_ITEM)
-- Mục tiêu: Thêm / Sửa / Xoá dữ liệu cho bảng CART_ITEM
-- Có kiểm tra dữ liệu hợp lệ và thông báo lỗi cụ thể
------------------------------------------------------------



-- 1. Thủ tục thêm sản phẩm vào giỏ hàng
IF OBJECT_ID('sp_AddCartItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_AddCartItem;
GO

CREATE PROCEDURE sp_AddCartItem
    @CartId   INT,
    @ProdId   INT,
    @ShopId   INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra số lượng > 0
    IF (@Quantity <= 0)
    BEGIN
        RAISERROR (N'Số lượng phải lớn hơn 0.', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------
    -- 2. Kiểm tra giỏ hàng tồn tại
    --------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM CART WHERE cart_id = @CartId
    )
    BEGIN
        RAISERROR (N'Giỏ hàng không tồn tại.', 16, 1);
        RETURN;
    END;

    -- 2b. Kiểm tra shop tồn tại
    IF NOT EXISTS (
        SELECT 1 FROM SHOP WHERE shop_id = @ShopId
    )
    BEGIN
        RAISERROR (N'Cửa hàng không tồn tại.', 16, 1);
        RETURN;
    END;


    --------------------------------------------------------
    -- 3. Kiểm tra sản phẩm tồn tại và lấy giá + tồn kho
    --------------------------------------------------------
    DECLARE @Price DECIMAL(18,2), @Stock INT;

    SELECT @Price = price,
           @Stock = stock_quantity
    FROM PRODUCT_VARIANT
    WHERE prod_id = @ProdId;

    IF (@Price IS NULL)
    BEGIN
        RAISERROR (N'Sản phẩm không tồn tại.', 16, 1);
        RETURN;
    END;

    -- 4. Kiểm tra số lượng yêu cầu không vượt quá tồn kho
    IF (@Quantity > @Stock)
    BEGIN
        RAISERROR (N'Số lượng yêu cầu vượt quá tồn kho hiện tại.', 16, 1);
        RETURN;
    END;

    -- 5. Nếu sản phẩm đã có trong giỏ -> cộng dồn số lượng
    IF EXISTS (
        SELECT 1
        FROM CART_ITEM
        WHERE cart_id = @CartId
          AND prod_id = @ProdId
          AND shop_id = @ShopId
    )
    BEGIN
        -- Lấy lại giá hiện tại để tính subtotal mới
        UPDATE CART_ITEM
        SET quantity  = quantity + @Quantity,
            sub_total = (quantity + @Quantity) * @Price
        WHERE cart_id = @CartId
          AND prod_id = @ProdId
          AND shop_id = @ShopId;
    END
    ELSE
    BEGIN
        INSERT INTO CART_ITEM (prod_id, cart_id, shop_id, quantity, sub_total)
        VALUES (@ProdId, @CartId, @ShopId, @Quantity, @Price * @Quantity);
    END;
END;
GO

-- 2. Thủ tục cập nhật số lượng trong giỏ hàng
IF OBJECT_ID('sp_UpdateCartItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_UpdateCartItem;
GO

CREATE PROCEDURE sp_UpdateCartItem
    @CartItemId  INT,
    @NewQuantity INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra số lượng mới > 0
    IF (@NewQuantity <= 0)
    BEGIN
        RAISERROR (N'Số lượng mới phải lớn hơn 0.', 16, 1);
        RETURN;
    END;

    -- 2. Kiểm tra cart_item tồn tại và lấy prod_id
    DECLARE @ProdId INT;

    SELECT @ProdId = prod_id
    FROM CART_ITEM
    WHERE cart_item_id = @CartItemId;

    IF (@ProdId IS NULL)
    BEGIN
        RAISERROR (N'Sản phẩm cần cập nhật không tồn tại trong giỏ hàng.', 16, 1);
        RETURN;
    END;

    -- 3. Lấy tồn kho + giá hiện tại của sản phẩm
    DECLARE @Price DECIMAL(18,2), @Stock INT;

    SELECT @Price = price,
           @Stock = stock_quantity
    FROM PRODUCT_VARIANT
    WHERE prod_id = @ProdId;

    IF (@NewQuantity > @Stock)
    BEGIN
        RAISERROR (N'Số lượng mới vượt quá tồn kho hiện tại.', 16, 1);
        RETURN;
    END;

    -- 4. Cập nhật quantity và sub_total
    UPDATE CART_ITEM
    SET quantity  = @NewQuantity,
        sub_total = @NewQuantity * @Price
    WHERE cart_item_id = @CartItemId;
END;
GO


-- 3. Thủ tục xoá sản phẩm khỏi giỏ hàng
IF OBJECT_ID('sp_DeleteCartItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_DeleteCartItem;
GO

CREATE PROCEDURE sp_DeleteCartItem
    @CartItemId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra sản phẩm có tồn tại trong giỏ không
    IF NOT EXISTS (
        SELECT 1 FROM CART_ITEM WHERE cart_item_id = @CartItemId
    )
    BEGIN
        RAISERROR (N'Sản phẩm cần xoá không tồn tại trong giỏ hàng.', 16, 1);
        RETURN;
    END;

    -- 2.  Xoá sản phẩm khỏi giỏ
    --    (Giỏ hàng là dữ liệu tạm trước khi đặt hàng, cho phép xoá tự do để khách chỉnh sửa giỏ hàng.)
    DELETE FROM CART_ITEM
    WHERE cart_item_id = @CartItemId;
END;
GO

-- CÁC PROCEDURE CRUD CHO SHOP

-- 1. Procedure cập nhật nhanh tồn kho và giá (Dành cho Shop quản lý nhanh)
CREATE OR ALTER PROCEDURE sp_QuickUpdateProduct
    @ProdID INT,
    @ShopID INT, -- Thêm ShopID để bảo mật, chỉ chủ shop mới sửa được
    @NewPrice DECIMAL(18,2),
    @NewStock INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra xem sản phẩm có thuộc Shop này không
    IF EXISTS (
        SELECT 1 
        FROM PRODUCT_VARIANT PV
        INNER JOIN ITEM I ON PV.item_id = I.item_id
        WHERE PV.prod_id = @ProdID AND I.shop_id = @ShopID
    )
    BEGIN
        UPDATE PRODUCT_VARIANT
        SET price = @NewPrice,
            stock_quantity = @NewStock
        WHERE prod_id = @ProdID;
        
        PRINT 'Cập nhật thành công';
    END
    ELSE
    BEGIN
        PRINT 'Lỗi: Sản phẩm không thuộc Shop này hoặc không tồn tại';
        THROW 51000, 'Sản phẩm không thuộc quyền quản lý của Shop.', 1;
    END
END;
GO


GO
-- =============================================
-- [NEW] PROCEDURE: Cập nhật thông tin Shop
-- =============================================
CREATE PROCEDURE sp_UpdateShopInfo
    @ShopID INT,
    @Address NVARCHAR(255),
    @Description NTEXT,
    @AvgTimeResponse VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra Shop tồn tại
    IF NOT EXISTS (SELECT 1 FROM SHOP WHERE shop_id = @ShopID)
    BEGIN
        RAISERROR(N'Shop không tồn tại.', 16, 1);
        RETURN;
    END

    UPDATE SHOP
    SET Address = @Address,
        Shop_description = @Description,
        Avg_time_response = @AvgTimeResponse
    WHERE shop_id = @ShopID;
    
    PRINT N'Cập nhật thông tin Shop thành công.';
END;
GO

GO
-- =============================================
-- [NEW] PROCEDURE: Thêm sản phẩm mới (Item + Variant)
-- =============================================
CREATE PROCEDURE sp_AddProduct
    @ShopID INT,
    @CategoryID INT,
    @ItemName NVARCHAR(200),
    @ProdName NVARCHAR(200),
    @Price DECIMAL(18,2),
    @Stock INT,
    @Description NTEXT,
    @ImageURL VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            -- 1. Insert ITEM
            INSERT INTO ITEM (category_id, item_name, total_item, shop_id)
            VALUES (@CategoryID, @ItemName, 1, @ShopID);
            
            DECLARE @NewItemID INT = SCOPE_IDENTITY();
            
            -- 2. Insert PRODUCT_VARIANT
            INSERT INTO PRODUCT_VARIANT (item_id, prod_name, prod_description, price, stock_quantity, illustration_images, status, total_sales, rating_avg)
            VALUES (@NewItemID, @ProdName, @Description, @Price, @Stock, @ImageURL, N'Còn hàng', 0, 0);
        COMMIT TRANSACTION;
        PRINT N'Thêm sản phẩm thành công';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =============================================
-- [NEW] PROCEDURE: Xóa sản phẩm (Soft Delete - Chuyển trạng thái)
-- =============================================
CREATE PROCEDURE sp_DeleteProduct
    @ProdID INT,
    @ShopID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check ownership
    IF EXISTS (
        SELECT 1 FROM PRODUCT_VARIANT PV
        JOIN ITEM I ON PV.item_id = I.item_id
        WHERE PV.prod_id = @ProdID AND I.shop_id = @ShopID
    )
    BEGIN
        -- Soft delete: Change status
        UPDATE PRODUCT_VARIANT
        SET status = N'Ngừng kinh doanh',
            stock_quantity = 0 -- Optional: Set stock to 0
        WHERE prod_id = @ProdID;
        
        PRINT N'Đã ngừng kinh doanh sản phẩm.';
    END
    ELSE
    BEGIN
        RAISERROR(N'Sản phẩm không thuộc Shop hoặc không tồn tại.', 16, 1);
    END
END;
GO

GO
-- =============================================
-- [NEW] PROCEDURE: Cập nhật sản phẩm (Update) - Yêu cầu 2.1
-- =============================================
CREATE PROCEDURE sp_UpdateProduct
    @ProdID INT,
    @ShopID INT,
    @CategoryID INT,
    @ItemName NVARCHAR(200),
    @ProdName NVARCHAR(200),
    @Price DECIMAL(18,2),
    @Stock INT,
    @Description NTEXT,
    @ImageURL VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- 1. Validate Data (Kiểm tra dữ liệu hợp lệ)
    IF @Price < 0
    BEGIN
        RAISERROR(N'Giá sản phẩm không được âm.', 16, 1);
        RETURN;
    END

    IF @Stock < 0
    BEGIN
        RAISERROR(N'Số lượng tồn kho không được âm.', 16, 1);
        RETURN;
    END

    -- 2. Check Ownership (Kiểm tra quyền sở hữu)
    DECLARE @ItemID INT;
    SELECT @ItemID = item_id FROM PRODUCT_VARIANT WHERE prod_id = @ProdID;

    IF NOT EXISTS (SELECT 1 FROM ITEM WHERE item_id = @ItemID AND shop_id = @ShopID)
    BEGIN
        RAISERROR(N'Sản phẩm không thuộc quyền quản lý của Shop.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;
            -- Update ITEM info
            UPDATE ITEM 
            SET item_name = @ItemName,
                category_id = @CategoryID
            WHERE item_id = @ItemID;

            -- Update VARIANT info
            UPDATE PRODUCT_VARIANT
            SET prod_name = @ProdName,
                price = @Price,
                stock_quantity = @Stock,
                prod_description = @Description,
                illustration_images = @ImageURL
            WHERE prod_id = @ProdID;
            
        COMMIT TRANSACTION;
        PRINT N'Cập nhật sản phẩm thành công.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- =============================================
-- [NEW] TRIGGER: Kiểm tra ràng buộc giá (Constraint) - Yêu cầu 2.2.1
-- =============================================
CREATE TRIGGER trg_CheckProductPrice
ON PRODUCT_VARIANT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM inserted WHERE price <= 0)
    BEGIN
        RAISERROR(N'Lỗi Trigger: Giá sản phẩm phải lớn hơn 0.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- =============================================
-- [NEW] TRIGGER: Cập nhật thuộc tính dẫn xuất (Derived Attribute) - Yêu cầu 2.2.2
-- Tự động cập nhật total_sales của PRODUCT_VARIANT khi có ORDER_DETAIL mới
-- =============================================
CREATE TRIGGER trg_UpdateProductTotalSales
ON ORDER_DETAIL
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Cập nhật total_sales cho các sản phẩm vừa được bán
    UPDATE PV
    SET PV.total_sales = PV.total_sales + I.quantity
    FROM PRODUCT_VARIANT PV
    INNER JOIN inserted I ON PV.prod_id = I.product_id;
END;
GO

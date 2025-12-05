USE SHOPEE_CLONE
GO
------------------------------------------------------------
-- STORED PROCEDURES – PHẦN 2.1: GIỎ HÀNG (CART_ITEM)
-- Mục tiêu: Thêm / Sửa / Xoá dữ liệu cho bảng CART_ITEM
-- Có kiểm tra dữ liệu hợp lệ và thông báo lỗi cụ thể
------------------------------------------------------------



------------------------------------------------------------
-- 1. Thủ tục thêm sản phẩm vào giỏ hàng
------------------------------------------------------------
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

    --------------------------------------------------------
    -- 1. Kiểm tra số lượng > 0
    --------------------------------------------------------
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

    --------------------------------------------------------
    -- 4. Kiểm tra số lượng yêu cầu không vượt quá tồn kho
    --------------------------------------------------------
    IF (@Quantity > @Stock)
    BEGIN
        RAISERROR (N'Số lượng yêu cầu vượt quá tồn kho hiện tại.', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------
    -- 5. Nếu sản phẩm đã có trong giỏ -> cộng dồn số lượng
    --------------------------------------------------------
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


------------------------------------------------------------
-- 2. Thủ tục cập nhật số lượng trong giỏ hàng
------------------------------------------------------------
IF OBJECT_ID('sp_UpdateCartItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_UpdateCartItem;
GO

CREATE PROCEDURE sp_UpdateCartItem
    @CartItemId  INT,
    @NewQuantity INT
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------
    -- 1. Kiểm tra số lượng mới > 0
    --------------------------------------------------------
    IF (@NewQuantity <= 0)
    BEGIN
        RAISERROR (N'Số lượng mới phải lớn hơn 0.', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------
    -- 2. Kiểm tra cart_item tồn tại và lấy prod_id
    --------------------------------------------------------
    DECLARE @ProdId INT;

    SELECT @ProdId = prod_id
    FROM CART_ITEM
    WHERE cart_item_id = @CartItemId;

    IF (@ProdId IS NULL)
    BEGIN
        RAISERROR (N'Sản phẩm cần cập nhật không tồn tại trong giỏ hàng.', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------
    -- 3. Lấy tồn kho + giá hiện tại của sản phẩm
    --------------------------------------------------------
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

    --------------------------------------------------------
    -- 4. Cập nhật quantity và sub_total
    --------------------------------------------------------
    UPDATE CART_ITEM
    SET quantity  = @NewQuantity,
        sub_total = @NewQuantity * @Price
    WHERE cart_item_id = @CartItemId;
END;
GO


------------------------------------------------------------
-- 3. Thủ tục xoá sản phẩm khỏi giỏ hàng
------------------------------------------------------------
IF OBJECT_ID('sp_DeleteCartItem', 'P') IS NOT NULL
    DROP PROCEDURE sp_DeleteCartItem;
GO

CREATE PROCEDURE sp_DeleteCartItem
    @CartItemId INT
AS
BEGIN
    SET NOCOUNT ON;

    --------------------------------------------------------
    -- 1. Kiểm tra sản phẩm có tồn tại trong giỏ không
    --------------------------------------------------------
    IF NOT EXISTS (
        SELECT 1 FROM CART_ITEM WHERE cart_item_id = @CartItemId
    )
    BEGIN
        RAISERROR (N'Sản phẩm cần xoá không tồn tại trong giỏ hàng.', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------
    -- 2. Xoá sản phẩm khỏi giỏ
    --    (Giỏ hàng là dữ liệu tạm trước khi đặt hàng,
    --     nên cho phép xoá tự do để khách chỉnh sửa giỏ hàng.)
    --------------------------------------------------------
    DELETE FROM CART_ITEM
    WHERE cart_item_id = @CartItemId;
END;
GO

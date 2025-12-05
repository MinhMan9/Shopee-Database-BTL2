USE SHOPEE_CLONE;
GO

PRINT N'========== TEST USER CONSTRAINTS ==========';

--------------------------------------------------
-- 1. USER – VALID: tất cả đúng format
--------------------------------------------------
INSERT INTO [USER] (username, [password], email, phone_number, gender, day_of_birth)
VALUES ('chk_user_ok', '123', 'check_ok@example.com', '0911111111', N'Nam', '2000-01-01');
-- -> Phải INSERT thành công

--------------------------------------------------
-- 1.1 Email format (CK_USER_Email_Format)
--------------------------------------------------

-- INVALID: Email sai format (không có @)
INSERT INTO [USER] (username, [password], email, phone_number, gender)
VALUES ('chk_bad_email1', '123', 'invalidemail.com', '0911111112', N'Nam');
-- -> EXPECTED ERROR: CK_USER_Email_Format

-- INVALID: Email sai format (không có . sau @)
INSERT INTO [USER] (username, [password], email, phone_number, gender)
VALUES ('chk_bad_email2', '123', 'invalid@local', '0911111113', N'Nam');
-- -> EXPECTED ERROR: CK_USER_Email_Format

--------------------------------------------------
-- 1.2 Email UNIQUE (UQ_USER_Email)
--------------------------------------------------

-- INVALID: Trùng email với user có sẵn 'a@gmail.com'
INSERT INTO [USER] (username, [password], email, phone_number, gender)
VALUES ('chk_dup_email', '123', 'a@gmail.com', '0911111114', N'Nam');
-- -> EXPECTED ERROR: UQ_USER_Email

--------------------------------------------------
-- 1.3 Gender IN (Nam, Nữ, Khác) (CK_USER_Gender)
--------------------------------------------------

-- INVALID: Gender không thuộc tập cho phép
INSERT INTO [USER] (username, [password], email, phone_number, gender)
VALUES ('chk_bad_gender', '123', 'bad_gender@example.com', '0911111115', N'Giới tính');
-- -> EXPECTED ERROR: CK_USER_Gender

--------------------------------------------------
-- 1.4 Phone format & UNIQUE (CK_USER_Phone_Format, UQ_USER_Phone)
--------------------------------------------------

-- INVALID: Phone có chữ
INSERT INTO [USER] (username, [password], email, phone_number, gender)
VALUES ('chk_bad_phone1', '123', 'bad_phone1@example.com', '09A2345678', N'Nam');
-- -> EXPECTED ERROR: CK_USER_Phone_Format

-- INVALID: Phone không đủ 10 ký tự
INSERT INTO [USER] (username, [password], email, phone_number, gender)
VALUES ('chk_bad_phone2', '123', 'bad_phone2@example.com', '091234567', N'Nam');
-- -> EXPECTED ERROR: CK_USER_Phone_Format

-- INVALID: Trùng số với user_id = 1 ('0901234567')
INSERT INTO [USER] (username, [password], email, phone_number, gender)
VALUES ('chk_dup_phone', '123', 'dup_phone@example.com', '0901234567', N'Nam');
-- -> EXPECTED ERROR: UQ_USER_Phone


PRINT N'========== TEST PRODUCT_VARIANT CONSTRAINTS ==========';

--------------------------------------------------
-- 2. PRODUCT_VARIANT – stock_quantity >= 0, price >= 0
--------------------------------------------------

-- VALID: stock_quantity = 0
INSERT INTO PRODUCT_VARIANT (item_id, prod_name, prod_description, price, stock_quantity,
                             product_specification, illustration_images, [status], total_sales, rating_avg)
VALUES (1, N'Test stock 0', N'SP test stock = 0', 100000, 0,
        N'test', 'test0.jpg', N'Đang bán', 0, 0);
-- -> Phải INSERT được

-- INVALID: stock_quantity âm
INSERT INTO PRODUCT_VARIANT (item_id, prod_name, prod_description, price, stock_quantity,
                             product_specification, illustration_images, [status], total_sales, rating_avg)
VALUES (1, N'Test stock negative', N'SP test stock âm', 100000, -5,
        N'test', 'test-5.jpg', N'Đang bán', 0, 0);
-- -> EXPECTED ERROR: CK_PRODUCT_StockQuantity

-- INVALID: price âm
INSERT INTO PRODUCT_VARIANT (item_id, prod_name, prod_description, price, stock_quantity,
                             product_specification, illustration_images, [status], total_sales, rating_avg)
VALUES (1, N'Test price negative', N'SP test price âm', -1000, 10,
        N'test', 'test-price.jpg', N'Đang bán', 0, 0);
-- -> EXPECTED ERROR: CK_PRODUCT_Price



PRINT N'========== TEST VOUCHER CONSTRAINTS ==========';

--------------------------------------------------
-- 3. VOUCHER – valid_from < valid_to, quantity >= 0
--------------------------------------------------

-- VALID
INSERT INTO VOUCHER (description, discount_type, [condition], valid_from, valid_to, quantity_available)
VALUES (N'Test voucher OK', 'amount', N'min_0', '2025-01-01', '2025-02-01', 10);
-- -> Phải INSERT được

-- INVALID: valid_from >= valid_to
INSERT INTO VOUCHER (description, discount_type, [condition], valid_from, valid_to, quantity_available)
VALUES (N'Voucher bad date', 'amount', N'min_0', '2025-03-01', '2025-02-01', 10);
-- -> EXPECTED ERROR: CK_VOUCHER_ValidDate

-- INVALID: quantity_available âm
INSERT INTO VOUCHER (description, discount_type, [condition], valid_from, valid_to, quantity_available)
VALUES (N'Voucher bad quantity', 'amount', N'min_0', '2025-01-01', '2025-12-31', -5);
-- -> EXPECTED ERROR: CK_VOUCHER_Quantity



PRINT N'========== TEST MEMBERSHIP_TIER CONSTRAINTS ==========';

--------------------------------------------------
-- 4. MEMBERSHIP_TIER – Name, Level, MinSpending, MinOrder, Coin, Discount
--------------------------------------------------

-- VALID
INSERT INTO MEMBERSHIP_TIER (tier_name, tier_lvl, min_spending, max_spending, [description],
                             min_order, max_order, discount_percent, shopee_coin)
VALUES (N'Bạc', 2, 0, 1000000, N'Test tier OK',
        0, 10, 0.1, 50);
-- -> Phải INSERT được

-- INVALID: tier_name không thuộc {Thành Viên, Bạc, Vàng, Kim Cương}
INSERT INTO MEMBERSHIP_TIER (tier_name, tier_lvl, min_spending, max_spending, [description],
                             min_order, max_order, discount_percent, shopee_coin)
VALUES (N'Đồng', 1, 0, 1000000, N'Test name sai',
        0, 10, 0.05, 0);
-- -> EXPECTED ERROR: CK_TIER_Name

-- INVALID: tier_lvl ngoài [1..4]
INSERT INTO MEMBERSHIP_TIER (tier_name, tier_lvl, min_spending, max_spending, [description],
                             min_order, max_order, discount_percent, shopee_coin)
VALUES (N'Vàng', 5, 0, 1000000, N'Test tier_lvl sai',
        0, 10, 0.05, 0);
-- -> EXPECTED ERROR: CK_TIER_Level

-- INVALID: min_spending âm
INSERT INTO MEMBERSHIP_TIER (tier_name, tier_lvl, min_spending, max_spending, [description],
                             min_order, max_order, discount_percent, shopee_coin)
VALUES (N'Vàng', 3, -1000000, 0, N'Test min_spending âm',
        0, 10, 0.05, 0);
-- -> EXPECTED ERROR: CK_TIER_MinSpending

-- INVALID: min_order âm
INSERT INTO MEMBERSHIP_TIER (tier_name, tier_lvl, min_spending, max_spending, [description],
                             min_order, max_order, discount_percent, shopee_coin)
VALUES (N'Vàng', 3, 0, 1000000, N'Test min_order âm',
        -1, 10, 0.05, 0);
-- -> EXPECTED ERROR: CK_TIER_MinOrder

-- INVALID: shopee_coin âm
INSERT INTO MEMBERSHIP_TIER (tier_name, tier_lvl, min_spending, max_spending, [description],
                             min_order, max_order, discount_percent, shopee_coin)
VALUES (N'Kim Cương', 4, 0, 1000000, N'Test coin âm',
        0, 10, 0.05, -10);
-- -> EXPECTED ERROR: CK_TIER_Coin

-- INVALID: discount_percent > 1 (150%)
INSERT INTO MEMBERSHIP_TIER (tier_name, tier_lvl, min_spending, max_spending, [description],
                             min_order, max_order, discount_percent, shopee_coin)
VALUES (N'Kim Cương', 4, 0, 1000000, N'Test discount > 1',
        0, 10, 1.5, 0);
-- -> EXPECTED ERROR: CK_TIER_DiscountPercent

-- INVALID: discount_percent âm
INSERT INTO MEMBERSHIP_TIER (tier_name, tier_lvl, min_spending, max_spending, [description],
                             min_order, max_order, discount_percent, shopee_coin)
VALUES (N'Kim Cương', 4, 0, 1000000, N'Test discount âm',
        0, 10, -0.1, 0);
-- -> EXPECTED ERROR: CK_TIER_DiscountPercent;


PRINT N'========== END OF CHECK TESTS ==========';


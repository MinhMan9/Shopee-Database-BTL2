from flask import Flask, render_template, request, redirect, url_for, flash, session
import pyodbc
import os
from werkzeug.utils import secure_filename
from decimal import Decimal
app = Flask(__name__)
# KHÓA BÍ MẬT LÀ BẮT BUỘC để Session hoạt động ổn định
app.secret_key = 'KEY_BI_MAT_CUA_BAN_ABCXYZ' 
# --- CẤU HÌNH KẾT NỐI CSDL CỦA BẠN ---
DRIVER = '{ODBC Driver 17 for SQL Server}'
SERVER = 'QUANGHUY'
DATABASE = 'SHOPEE_CLONE' 

CONNECTION_STRING = (
    f"DRIVER={DRIVER};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
    f"TrustServerCertificate=yes;"
)

# --- CÁC HÀM XỬ LÝ CSDL CHUNG ---
def execute_select(sql, params=None):
    conn = None
    try:
        conn = pyodbc.connect(CONNECTION_STRING)
        cursor = conn.cursor()
        cursor.execute(sql, params if params else ())
        columns = [column[0] for column in cursor.description]
        data = [dict(zip(columns, row)) for row in cursor.fetchall()]
        return data, columns
    except Exception as e:
        print(f"LỖI SELECT CSDL: {e}")
        flash(f"LỖI KẾT NỐI/TRUY VẤN: {e}", 'error')
        return [], []
    finally:
        if conn:
            conn.close()
def execute_non_query(sql, params=None):
    conn = None
    try:
        conn = pyodbc.connect(CONNECTION_STRING)
        cursor = conn.cursor()
        cursor.execute(sql, params if params else ())
        conn.commit()
        return True
    except Exception as e:
        flash(f"LỖI THAO TÁC CSDL: {e}", 'error')
        print(f"LỖI NON-QUERY CSDL: {e}")
        return False
    finally:
        if conn:
            conn.close()
# --- BỘ LỌC JINJA2 ---
def format_currency(value):
    try:
        return "{:,.0f} VNĐ".format(value).replace(",", "#").replace(".", ",").replace("#", ".")
    except:
        return str(value)
app.jinja_env.filters['format_currency'] = format_currency
# --- ROUTES XÁC THỰC VÀ PHÂN QUYỀN ---
@app.route('/')
def index():
    if 'user_id' not in session: return redirect(url_for('login'))
    if session.get('is_shop'): return redirect(url_for('seller_dashboard'))
    elif session.get('is_customer'): return redirect(url_for('customer_dashboard'))
    return redirect(url_for('logout'))
@app.route('/login', methods=['GET', 'POST'])
def login():
    if 'user_id' in session: return redirect(url_for('index'))
        
    if request.method == 'POST':
        email = request.form.get('email')
        password = request.form.get('password') 
        sql_user = "SELECT user_id, username FROM [USER] WHERE email = ? AND password = ?"
        user_data, _ = execute_select(sql_user, (email, password))
        
        if user_data:
            user_id = user_data[0]['user_id']
            session['user_id'] = user_id
            session['username'] = user_data[0]['username']
            
            sql_shop = "SELECT shop_id FROM SHOP WHERE shop_id = ?"
            sql_customer = "SELECT customer_id FROM CUSTOMER WHERE customer_id = ?"
            session['is_shop'] = len(execute_select(sql_shop, (user_id,))[0]) > 0 
            session['is_customer'] = len(execute_select(sql_customer, (user_id,))[0]) > 0 
            
            if session['is_shop']:
                flash(f'Đăng nhập thành công! Vai trò kép (SHOP & CUSTOMER).', 'success')
                return redirect(url_for('seller_dashboard'))
            elif session['is_customer']:
                flash(f'Đăng nhập thành công! Vai trò CUSTOMER.', 'success')
                return redirect(url_for('customer_dashboard'))
            else:
                flash('Tài khoản không có vai trò (Shop/Customer).', 'error')
                return redirect(url_for('login'))
        else:
            flash('Email hoặc mật khẩu không đúng. Vui lòng thử lại.', 'error')
            return redirect(url_for('login')) 
    return render_template('login.html')
@app.route('/logout')
def logout():
    session.clear()
    flash('Bạn đã đăng xuất.', 'success')
    return redirect(url_for('login'))


# --- 1. ROUTES CHO KHÁCH HÀNG (TÍCH HỢP FUNCTIONS) ---
# --- 1. ROUTES CHO KHÁCH HÀNG (TÍCH HỢP FUNCTIONS & SP) ---

@app.route('/customer/dashboard', methods=['GET'])
def customer_dashboard():
    if 'user_id' not in session: return redirect(url_for('login'))

    user_id = session['user_id']
    search_results = []

    # --- TÍCH HỢP 3 FUNCTIONS ---
    sql_func_cart_total = "SELECT dbo.fn_TinhTongTienGioHang(?)"
    cart_total_result, _ = execute_select(sql_func_cart_total, (user_id,))
    cart_total = cart_total_result[0][list(cart_total_result[0].keys())[0]] if cart_total_result else 0

    # --- TÍCH HỢP 2 FUNCTIONS ---
    sql_func_tier = "SELECT dbo.fn_XacDinhTierKhachHang(?)"
    tier_result, _ = execute_select(sql_func_tier, (user_id,))
    tier_info = tier_result[0] if tier_result else {}

    sql_func_stock = "SELECT dbo.fn_KiemTraTonKhoSanPham(?)"
    stock_result, _ = execute_select(sql_func_stock, (1,))
    stock_status_sp1 = stock_result[0] if stock_result else {}

    # --- TRUY VẤN: THÔNG TIN KHÁCH HÀNG ---
    sql_user = "SELECT * FROM [USER] WHERE user_id = ?"
    user_info, _ = execute_select(sql_user, (user_id,))

    # --- TRUY VẤN: LỊCH SỬ ĐƠN HÀNG ---
    sql_orders = """
    SELECT TOP 10 O.*, C.phone_number, S.shop_id
    FROM [ORDER] O
    INNER JOIN CUSTOMER C ON O.customer_id = C.customer_id
    LEFT JOIN SHOP S ON O.shop_id = S.shop_id
    WHERE O.customer_id = ?
    ORDER BY O.created_at DESC
    """
    order_history, _ = execute_select(sql_orders, (user_id,))

    # --- TRUY VẤN: GIỎ HÀNG ---
    sql_cart = """
    SELECT CI.cart_item_id, CI.product_id, CI.quantity, CI.price, PV.prod_name, PV.stock_quantity
    FROM CART_ITEM CI
    INNER JOIN PRODUCT_VARIANT PV ON CI.product_id = PV.prod_id
    WHERE CI.cart_id = (SELECT cart_id FROM CART WHERE customer_id = ?)
    """
    cart_items, _ = execute_select(sql_cart, (user_id,))

    # --- TRUY VẤN VOUCHER VÀ ÁP DỤNG FUNCTION KIỂM TRA ---    # --- TRUY VẤN VOUCHER VÀ ÁP DỤNG FUNCTION KIỂM TRA ---
    sql_vouchers = """
    SELECT 
        V.voucher_id, V.description, V.discount_type, V.condition, V.valid_to, V.quantity_available
    FROM VOUCHER V
    WHERE V.valid_to >= GETDATE()
    """
    current_vouchers, _ = execute_select(sql_vouchers, (user_id,))

    vouchers_with_status = []
    for voucher in current_vouchers:
        sql_check = "SELECT dbo.fn_KiemTraVoucherHopLe(?, ?, ?)"
        check_result, _ = execute_select(sql_check, (voucher['voucher_id'], cart_total, user_id))

        if check_result:
            status = check_result[0][list(check_result[0].keys())[0]]
        else:
            status = 'Lỗi kết nối kiểm tra'

        voucher['is_valid_for_cart'] = (status == 'Hợp lệ')
        voucher['validation_reason'] = status
        vouchers_with_status.append(voucher)

    # --- TÍCH HỢP SP: sp_ThongKeSanPhamChiTiet (CHO TAB SẢN PHẨM) VÀ SẮP XẾP ---
    ten_dm = request.args.get('ten_dm')
    min_rating = request.args.get('min_rating')
    min_sales = request.args.get('min_sales')
    sort_by = request.args.get('sort_by')
    order = request.args.get('order', 'desc')

    p_min_rating = None
    try:
        if min_rating:
            p_min_rating = float(min_rating)
    except:
        p_min_rating = None

    p_min_sales = None
    try:
        if min_sales:
            p_min_sales = int(min_sales)
    except:
        p_min_sales = None

    params = (None, ten_dm, p_min_sales, p_min_rating)
    sql_sp_search = "EXEC sp_ThongKeSanPhamChiTiet @ShopID = ?, @CategoryName = ?, @MinTotalSales = ?, @MinAvgRating = ?"
    search_results, _ = execute_select(sql_sp_search, params)

    # Áp dụng SẮP XẾP trong Python
    if search_results and sort_by:
        reverse_order = (order == 'desc')

        if sort_by == 'AvgRating':
            sort_key = lambda x: float(x.get('AvgRating') or 0.0)
        elif sort_by == 'TotalUnitsSold':
            sort_key = lambda x: int(x.get('TotalUnitsSold') or 0)
        elif sort_by == 'CurrentPrice':
            sort_key = lambda x: float(x.get('CurrentPrice') or 0.0)
        else:
            sort_key = lambda x: x.get('TotalRevenueGenerated')

        try:
            search_results.sort(key=sort_key, reverse=reverse_order)
        except Exception as e:
            print(f"Lỗi sắp xếp: {e}")
            flash(f"Lỗi sắp xếp dữ liệu: {e}", 'error')

    return render_template('customer_dashboard.html',
                       user_data=user_info[0] if user_info else {},
                       order_history=order_history,
                       cart_items=cart_items,
                       cart_total=cart_total,
                       tier_info=tier_info,
                       stock_status_sp1=stock_status_sp1,
                       vouchers_with_status=vouchers_with_status,
                       search_results=search_results,
                       current_sort_by=sort_by,
                       current_order=order)


# --- 2. ROUTES CHO NGƯỜI BÁN (TÍCH HỢP STORED PROCEDURES) ---
@app.route('/seller/dashboard', methods=['GET'])
def seller_dashboard():
    if 'user_id' not in session: return redirect(url_for('login'))

    # Kiểm tra quyền Shop
    if not session.get('is_shop'):
        flash('Bạn không có quyền truy cập Kênh Người Bán.', 'error')
        return redirect(url_for('index'))

    SHOP_ID = session['user_id']

    # --- [NEW] 1. Lấy Thống kê Dashboard (Sử dụng Procedure mới: sp_GetShopDashboardStats) ---
    sql_stats = "EXEC sp_GetShopDashboardStats @ShopID = ?"
    stats_result, _ = execute_select(sql_stats, (SHOP_ID,))
    stats = stats_result[0] if stats_result else {'TotalRevenue': 0, 'TotalOrders': 0, 'TotalProductsSold': 0, 'RealAvgRating': 0}

    # --- [NEW] 2. Lấy Danh sách Đơn hàng gần đây (Sử dụng Procedure mới: sp_GetShopOrderList) ---
    sql_orders = "EXEC sp_GetShopOrderList @ShopID = ?, @Limit = 5"
    recent_orders, _ = execute_select(sql_orders, (SHOP_ID,))

    # --- 3. Lấy Danh sách Sản phẩm (Logic cũ hoặc Procedure cũ sp_HienThiSanPhamTheoTenVaGia) ---
    # Lấy tham số Tìm kiếm/Lọc
    keyword = request.args.get('keyword', '').lower()
    status_filter = request.args.get('status_filter')

    # Tích hợp SP: sp_HienThiSanPhamTheoTenVaGia
    sql_sp_list = "EXEC sp_HienThiSanPhamTheoTenVaGia @TenSanPham = NULL, @GiaMin = NULL, @GiaMax = NULL"
    all_products_sp, columns = execute_select(sql_sp_list)

    item_names_of_shop = [item['item_name'] for item in execute_select("SELECT item_name FROM ITEM WHERE shop_id = ?", (SHOP_ID,))[0]]
    
    # Áp dụng Lọc trong Python (Filter Logic)
    products = []
    for p in all_products_sp:
        # Lọc theo Shop hiện tại
        if p.get('item_name') in item_names_of_shop:

            # Lọc theo Tên Sản phẩm / Item Name (Keyword)
            name_match = True
            if keyword:
                prod_name = str(p.get('prod_name', '')).lower()
                item_name = str(p.get('item_name', '')).lower()
                if keyword not in prod_name and keyword not in item_name:
                    name_match = False

            # Lọc theo Trạng thái (Dropdown)
            status_match = True
            if status_filter:
                current_status = str(p.get('status', ''))
                if status_filter == 'Còn hàng':
                    if p.get('stock_quantity', 0) <= 0:
                        status_match = False
                elif status_filter != 'Còn hàng' and status_filter != current_status:
                    status_match = False

            if name_match and status_match:
                products.append(p)

    # Lấy thông tin Shop để hiển thị Sidebar
    shop_info_sql = "SELECT username FROM [USER] WHERE user_id = ?"
    shop_info, _ = execute_select(shop_info_sql, (SHOP_ID,))

    return render_template('shop_dashboard.html', 
                           stats=stats,
                           recent_orders=recent_orders,
                           products=products, 
                           shop_id=SHOP_ID,
                           shop_info=shop_info[0] if shop_info else {},
                           current_keyword=keyword,
                           current_status=status_filter) 

@app.route('/seller/reports', methods=['GET'])
def seller_reports():
    if 'user_id' not in session: return redirect(url_for('login'))

    SHOP_ID = session['user_id']

    # 1. SP: Thống kê Doanh số Bán hàng theo Cửa hàng (sp_ThongKeDoanhSoVaRatingShop)
    sql_sp_revenue = "EXEC sp_ThongKeDoanhSoVaRatingShop @NgayBatDau = NULL, @NgayKetThuc = NULL, @RatingShopMin = NULL"
    all_revenue, revenue_cols = execute_select(sql_sp_revenue)
    revenue_data = [r for r in all_revenue if r['shop_id'] == SHOP_ID]

    # 2. SP: Thống kê Chi tiết Sản phẩm (sp_ThongKeSanPhamChiTiet)
    sql_sp_stats = "EXEC sp_ThongKeSanPhamChiTiet @ShopID = ?, @CategoryName = NULL, @MinTotalSales = 1, @MinAvgRating = NULL"
    product_stats, stats_cols = execute_select(sql_sp_stats, (SHOP_ID,))

    return render_template('seller_reports.html', 
                           revenue_data=revenue_data, 
                           product_stats=product_stats,
                           shop_id=SHOP_ID,
                           is_customer_user=session.get('is_customer', False))

# --- Route Chi tiết Sản phẩm ---
@app.route('/product/<int:prod_id>')
def product_detail(prod_id):
    if 'user_id' not in session: 
        flash('Vui lòng đăng nhập để xem chi tiết sản phẩm.', 'error')
        return redirect(url_for('login'))

    # 1. Truy vấn thông tin chi tiết cơ bản (PRODUCT_VARIANT)
    # 1. Truy vấn thông tin chi tiết cơ bản
    sql_detail = """
    SELECT 
        PV.*, I.item_name, C.category_name, U_Shop.username AS ShopName, U_Shop.phone_number AS ShopPhone
    FROM PRODUCT_VARIANT PV
    INNER JOIN ITEM I ON PV.item_id = I.item_id
    SELECT PV.*, PV.rating_avg, PV.total_sales, I.item_name, C.category_name, U_Shop.username AS ShopName, U_Shop.phone_number AS ShopPhone
    FROM PRODUCT_VARIANT PV INNER JOIN ITEM I ON PV.item_id = I.item_id
    INNER JOIN CATEGORY C ON I.category_id = C.category_id
    INNER JOIN [USER] U_Shop ON I.shop_id = U_Shop.user_id
    WHERE PV.prod_id = ?
    """
    detail_data, _ = execute_select(sql_detail, (prod_id,))

    if not detail_data:
        return "Không tìm thấy sản phẩm.", 404

    product = detail_data[0]

    # ----------------------------------------------------------------------
    # 2. TRUY VẤN THÔNG TIN BỔ SUNG YÊU CẦU:
    # ----------------------------------------------------------------------

    # a) Truy vấn Product Specification (Size, Color)
    # 2. TRUY VẤN THÔNG TIN BỔ SUNG:
    sql_spec = "SELECT size, color FROM PRODUCT_SPECIFICATION WHERE prod_id = ?"
    specs_data, _ = execute_select(sql_spec, (prod_id,))

    # b) Truy vấn Product Attribute (Ví dụ: 256GB, Size L)
    sql_attr = "SELECT attribute_size, is_primary FROM PRODUCT_ATTRIBUTE WHERE prod_id = ?"
    attrs_data, _ = execute_select(sql_attr, (prod_id,))

    # c) Tính Total Reviews (Tổng số đánh giá) và Rating Avg (tính lại từ bảng REVIEW)
    # Lấy Total Reviews và Rating Avg thực tế từ bảng REVIEW
    sql_review_stats = """
    SELECT 
        COUNT(review_id) AS total_reviews, 
        AVG(rating) AS calculated_rating_avg
    FROM REVIEW
    WHERE product_id = ?
    """
    review_stats, _ = execute_select(sql_review_stats, (prod_id,))
    total_reviews = review_stats[0]['total_reviews'] if review_stats and review_stats[0]['total_reviews'] is not None else 0
    calculated_rating_avg = review_stats[0]['calculated_rating_avg'] if review_stats and review_stats[0]['calculated_rating_avg'] is not None else 0.0

    # d) Truy vấn Chi tiết Đánh giá (5 đánh giá gần nhất)
    sql_reviews = """
    SELECT TOP 5 
        R.rating, R.comment, R.created_at, U_Cust.username AS CustomerName
    FROM REVIEW R
    INNER JOIN CUSTOMER C ON R.customer_id = C.customer_id
    FROM REVIEW R INNER JOIN CUSTOMER C ON R.customer_id = C.customer_id
    INNER JOIN [USER] U_Cust ON C.customer_id = U_Cust.user_id
    WHERE R.product_id = ?
    ORDER BY R.created_at DESC
    """
    reviews_data, _ = execute_select(sql_reviews, (prod_id,))

    return render_template('product_detail.html', 
                           product=product, 
                           specs=specs_data,
                           attributes=attrs_data,
                           total_reviews=total_reviews,
                           calculated_rating_avg=calculated_rating_avg) # Truyền dữ liệu mới

# --- Các hàm CRUD (add_product, delete_product) cần được chèn vào đây ---
@app.route('/seller/add_product', methods=['GET', 'POST'])
def add_product():
    if 'user_id' not in session or not session.get('is_shop'):
        return redirect(url_for('login'))
        
    SHOP_ID = session['user_id']

    if request.method == 'POST':
        try:
            # Lấy dữ liệu từ form
            item_name = request.form.get('item_name')
            prod_name = request.form.get('prod_name')
            category_id = request.form.get('category_id')
            price = request.form.get('price')
            stock = request.form.get('stock')
            description = request.form.get('description')
            
            # Xử lý upload ảnh
            image_url = ''
            if 'image' in request.files:
                file = request.files['image']
                if file and file.filename != '':
                    filename = secure_filename(file.filename)
                    # Lưu ảnh vào thư mục static/images hoặc uploads (tùy cấu hình)
                    # Ở đây giả sử lưu vào static/images để hiển thị được ngay
                    upload_folder = os.path.join('static', 'images')
                    if not os.path.exists(upload_folder):
                        os.makedirs(upload_folder)
                    file.save(os.path.join(upload_folder, filename))
                    image_url = filename

            # Gọi Stored Procedure sp_AddProduct
            sql_add = """
                EXEC sp_AddProduct 
                @ShopID = ?, 
                @CategoryID = ?, 
                @ItemName = ?, 
                @ProdName = ?, 
                @Price = ?, 
                @Stock = ?, 
                @Description = ?, 
                @ImageURL = ?
            """
            params = (SHOP_ID, category_id, item_name, prod_name, price, stock, description, image_url)
            
            if execute_non_query(sql_add, params):
                flash('Thêm sản phẩm thành công!', 'success')
                return redirect(url_for('seller_dashboard'))
            else:
                flash('Lỗi khi thêm sản phẩm vào CSDL.', 'error')
                
        except Exception as e:
            flash(f'Đã xảy ra lỗi: {str(e)}', 'error')

    # GET: Lấy danh sách Category để hiển thị trong dropdown
    categories, _ = execute_select("SELECT category_id, category_name FROM CATEGORY")
    return render_template('seller_add_product.html', categories=categories)

@app.route('/seller/delete_product/<int:prod_id>', methods=['POST'])
def delete_product(prod_id):
    if 'user_id' not in session or not session.get('is_shop'):
        return redirect(url_for('login'))
        
    SHOP_ID = session['user_id']
    
    try:
        # Gọi Stored Procedure sp_DeleteProduct
        sql_delete = "EXEC sp_DeleteProduct @ProdID = ?, @ShopID = ?"
        if execute_non_query(sql_delete, (prod_id, SHOP_ID)):
            flash('Đã xóa sản phẩm (chuyển trạng thái ngừng kinh doanh).', 'success')
        else:
            flash('Không thể xóa sản phẩm. Vui lòng thử lại.', 'error')
            
    except Exception as e:
        flash(f'Lỗi khi xóa sản phẩm: {str(e)}', 'error')
        
    return redirect(url_for('seller_dashboard'))

if __name__ == '__main__':
    app.run(debug=True)
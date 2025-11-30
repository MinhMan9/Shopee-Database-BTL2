# Shopee-Database-BTL2

Shopee-Database-BTL2/
│
├── .gitignore              # File cấu hình chặn các file rác (log, temp, file cấu hình máy cá nhân)
├── README.md               # Hướng dẫn cấu trúc
│
├── 📁 01-Database-Design   # Chứa tài liệu thiết kế (Phần BTL1 và cập nhật)
│   ├── EERD_Diagram.drawio.png      # Hình ảnh ERD mới nhất
│   └── Mapping_Diagram.drawio.png   # Hình ảnh Mapping mới nhất
│
├── 📁 02-SQL-Source        # Toàn bộ code SQL cho Phần 1 & 2
│   ├── Schema/          # Phần 1.1: Tạo bảng và ràng buộc
│   │   └── create_database_shopee.sql
│   │
│   ├── Data/            # Phần 1.2: Dữ liệu mẫu
│   │   ├── insert_master_data.sql  # Dữ liệu tĩnh (Category, Membership, Provider...)
│   │   └── insert_transaction.sql  # Dữ liệu động (User, Order, Product...)
│   │
│   ├── Procedures/      # Phần 2.1 & 2.3: Thủ tục lưu trữ
│   │   ├── proc_CRUD.sql           # Thủ tục Thêm/Xóa/Sửa (Câu 2.1)
│   │   └── proc_Report.sql         # Thủ tục thống kê/truy vấn (Câu 2.3)
│   │
│   ├── Triggers/        # Phần 2.2: Trigger
│   │   └── triggers_shopee.sql     # Kiểm tra ràng buộc & thuộc tính dẫn xuất
│   │
│   └── Functions/       # Phần 2.4: Hàm
│       └── functions_shopee.sql    # Hàm tính toán
│
├── 📁 03-Application       # Phần 3: Ứng dụng minh họa (Cái này để sau hoặc bỏ qua do AI tạo tui không biết làm)
│   ├── 📁 backend          # (Nếu tách riêng) API xử lý
│   ├── 📁 frontend         # Giao diện Web/App (Màn hình thêm xóa sửa, danh sách)
│   └── app_config.txt      # Hướng dẫn kết nối CSDL (ConnectionString)
│
└── 📁 04-Test-Cases        # Minh họa việc gọi hàm/thủ tục khi báo cáo 
    ├── test_triggers.sql   # Các câu lệnh INSERT/UPDATE để kích hoạt Trigger
    └── test_procedures.sql # Các câu lệnh EXEC để chạy thử Procedure
# Glamira Customer Behaviour Data Warehouse
- - Document:https://docs.google.com/spreadsheets/d/1IqYaNqcgZaPsZ1ywHe8d60lxnZABq6YuH-MJzZRZZvY/edit?gid=1098803270#gid=1098803270

---

## 1. Project
- Chuẩn hóa dữ liệu hành vi khách hàng của Glamira
- Thiết kế Dimension Model (Star Schema)
- Xây dựng pipeline transform dữ liệu bằng dbt
- Phục vụ phân tích và báo cáo

---

## 2. Tổng quan kiến trúc dữ liệu
<img width="530" height="243" alt="image" src="https://github.com/user-attachments/assets/68896f6a-2b82-4132-b120-3ce5de1320d3" />
VM Instance (Raw Data)
  -> GCS (Data Storage)
  -> BigQuery Dataset: glamira_raw_ca
  -> dbt Staging Layer (View)
  -> BigQuery Dataset: glamira_raw_ca_stg
  -> dbt Data Warehouse Layer (Star Schema - View)
  -> BigQuery Dataset: glamira_raw_ca_dwh
---

## 3. BigQuery Datasets và Tables

### 3.1 Dataset: glamira_raw_ca (Raw Layer)
- Chứa dữ liệu ingest trực tiếp từ GCS
- Giữ nguyên cấu trúc raw, không xử lý nghiệp vụ

Tables:
- customer_behaviour
---
### 3.2 Dataset: glamira_raw_ca_stg (Staging Layer)
- Được build bằng dbt
- materialized = 'view'
- Chuẩn hóa tên cột và kiểu dữ liệu
- Không áp dụng logic nghiệp vụ phức tạp

Tables:
- stg_dim_customers
- stg_dim_address
- stg_dim_store
- stg_dim_product
- stg_dim_date
- stg_fact_sales_order
- base_stg_src_raw_ip_location(logic join để lấy surrogate key cho bảng dim_address low cardinality)
---
### 3.3 Dataset: glamira_raw_ca_dwh (Data Warehouse Layer)
- Áp dụng mô hình Star Schema
- materialized = 'table'
- Sử dụng natural key / business key
Dimension tables:
- dim_customers
- dim_address
- dim_store
- dim_product
- dim_date
Fact table:
- fact_sales_order
- Diagram of this model - Starschema: https://dbdiagram.io/d/695ce81339fa3db27b3a99c2
<img width="385" height="306" alt="image" src="https://github.com/user-attachments/assets/ae17db61-c179-4099-bbf3-1c66525461f8" />
---
## 4. Công nghệ sử dụng
- VM Intance
- Google Cloud Storage (GCS)
- BigQuery
- dbt
- SQL
- Git
---
## 5. Dashboard
- Looker Dashboard: https://lookerstudio.google.com/reporting/d8f464ac-e46a-45ae-a707-d6eb6d1ed71f



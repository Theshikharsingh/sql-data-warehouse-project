--  Create database 'datawarehouse'
/*
WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/

USE master;
GO

-- Drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO



use master;

Create database DataWarehouse;

use DataWarehouse;

create schema bronze;
go 
create schema silver;
go 
create schema gold;
go


------ ********    Bronze  Layer   *****   ****

--- check before create and if exist then delete


--    DDL

if OBJECT_ID ('bronze.crm_cust_info','U') is not null
drop table bronze.crm_cust_info;

create table bronze.crm_cust_info (
cst_id int,
cst_key nvarchar(50),
cst_firstname nvarchar(50),
cst_lastname nvarchar(50),
cst_material_status nvarchar(50),
cst_gndr nvarchar(50),
cst_create_date date
)

if OBJECT_ID ('bronze.crm_prd_info','U') is not null
drop table bronze.crm_prd_info

create table bronze.crm_prd_info (
prd_id int,
prd_key nvarchar(50),
prd_nm nvarchar(50),
prd_cost int,
prd_line nvarchar(50),
prd_start_dt datetime,
prd_end_dt datetime
)

if OBJECT_ID ('bronze.crm_sales_details','U') is not null
drop table bronze.crm_sales_details

create table bronze.crm_sales_details (
sls_ord_num nvarchar(50),
sls_prd_key nvarchar(50),
sls_cust_id int,
sls_order_dt int,
sls_ship_dt int,
sls_due_dt int,
sls_sales int,
sls_quantity int,
sls_price int
);

if OBJECT_ID ('bronze.erp_loc_a101','U') is not null
drop table bronze.erp_loc_a101

create table bronze.erp_loc_a101(
cid nvarchar(50),
cntry nvarchar(50)
);

if OBJECT_ID ('bronze.erp_cust_az12','U') is not null
drop table bronze.erp_cust_az12

create table bronze.erp_cust_az12(
cid nvarchar(50),
bdate date,
gen nvarchar(50)
)

if OBJECT_ID ('bronze.erp_px_cat_g1v2','U') is not null
drop table bronze.erp_px_cat_g1v2

create table bronze.erp_px_cat_g1v2(
id nvarchar(50),
cat nvarchar(50),
subcat nvarchar(50),
maintanance nvarchar(5)
);

----   Bulk insert       upload file in table 
/*
Bulk insert bronze.crm_cust_info
from '\\wsl.localhost\docker-desktop\DA database\cust_info.csv'
with(
Firstrow = 2,   -- it means data available in 2 line after header
fieldterminator = ',',
tablock            ---- lock the data of whole table
);
*/

--  Procedure for inserting the data as it should be upto dated

create or alter procedure bronze.load_bronze as
begin

DECLARE @start_time datetime, @end_time datetime;


BEGIN TRY

Print'============'
print'Loading bronze layer'


set @start_time= GETDATE();


Truncate table bronze.crm_cust_info;

BULK INSERT bronze.crm_cust_info
FROM '/var/opt/mssql/data/data warehouse project/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
WITH (
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',',
    TABLOCK
);



Truncate table bronze.crm_prd_info;
BULK INSERT bronze.crm_prd_info
FROM '/var/opt/mssql/data/data warehouse project/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
WITH (
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',',
    TABLOCK
);

Truncate table bronze.crm_sales_details;
BULK INSERT bronze.crm_sales_details
FROM '/var/opt/mssql/data/data warehouse project/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
WITH (
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',',
    TABLOCK
);

Truncate table bronze.erp_loc_a101;
BULK INSERT bronze.erp_loc_a101
FROM '/var/opt/mssql/data/data warehouse project/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
WITH (
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',',
    TABLOCK
);


Truncate table bronze.erp_cust_az12;
BULK INSERT bronze.erp_cust_az12
FROM '/var/opt/mssql/data/data warehouse project/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
WITH (
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',',
    TABLOCK
);

Truncate table bronze.erp__px_cat_g1v2
BULK INSERT bronze.erp_px_cat_g1v2
FROM '/var/opt/mssql/data/data warehouse project/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
WITH (
    FIRSTROW = 2, 
    FIELDTERMINATOR = ',',
    TABLOCK 
);





END TRY

BEGIN CATCH

print'----------------'
print 'Error in code of bronze '+error_message();
print 'Error code ' + cast(error_number() as nvarchar);

END CATCH

set @end_time = GETDATE();

print '------ Load Duration ------'+ cast (datediff(second, @start_time,@end_time) as nvarchar) + ' second';


END

----------------------  Execute procedure


EXEC bronze.load_bronze

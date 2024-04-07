--Login as Admin user from SQL Developer and run below commands

SET SERVEROUTPUT ON;

DECLARE
    userexist NUMBER;
BEGIN
    -- BUSINESS_MANAGER
    SELECT COUNT(*) INTO userexist FROM dba_users WHERE USERNAME = 'BUSINESS_MANAGER';
    IF userexist = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER BUSINESS_MANAGER IDENTIFIED BY ReturnsRefunds#Group3_bm';
    END IF;
    
    -- CUSTOMER_USER
    SELECT COUNT(*) INTO userexist FROM dba_users WHERE USERNAME = 'CUSTOMER_USER';
    IF userexist = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER CUSTOMER_USER IDENTIFIED BY ReturnsRefunds#Group3_customer';
    END IF;
    
    -- STORE_USER
    SELECT COUNT(*) INTO userexist FROM dba_users WHERE USERNAME = 'STORE_USER';
    IF userexist = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER STORE_USER IDENTIFIED BY ReturnsRefunds#Group3_store';
    END IF;
    
    -- SELLER_USER
    SELECT COUNT(*) INTO userexist FROM dba_users WHERE USERNAME = 'SELLER_USER';
    IF userexist = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER SELLER_USER IDENTIFIED BY ReturnsRefunds#Group3_seller';
    END IF;
END;
/

--BUSINESS_MANAGER
-- Granting unlimited storage to business_manager in tablespace users
ALTER USER BUSINESS_MANAGER DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;

-- Granting temporary tablespace to store intermediate results during query processing, sorting, and joining operations.
ALTER USER BUSINESS_MANAGER TEMPORARY TABLESPACE TEMP;

-- granting minimum required permissions to BUSINESS_MANAGER
GRANT CONNECT TO BUSINESS_MANAGER;
GRANT CREATE SESSION, CREATE VIEW, CREATE TABLE, ALTER SESSION, CREATE PROCEDURE TO BUSINESS_MANAGER;

-- CUSTOMER_USER
GRANT CREATE SESSION TO CUSTOMER_USER;

-- STORE_USER
GRANT CREATE SESSION TO STORE_USER;

-- SELLER_USER
GRANT CREATE SESSION TO SELLER_USER;


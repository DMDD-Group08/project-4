-- STORE Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE store CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- SELLER Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE seller CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- RETURN Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE return CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- PRODUCT Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE product CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- ORDER_PRODUCT Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE order_product CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- CUSTOMER_ORDER Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CUSTOMER_ORDER CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- FEEDBACK Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE feedback CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- DISCOUNT Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE discount CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- CUSTOMER Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE customer CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/
 
-- CATEGORY Table
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE category CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN

            RAISE;
        END IF;
END;
/

DROP SEQUENCE CUSTOMER_ID_SEQ;
DROP SEQUENCE CATEGORY_ID_SEQ;
DROP SEQUENCE DISCOUNT_ID_SEQ;
DROP SEQUENCE SELLER_ID_SEQ;
DROP SEQUENCE PRODUCT_ID_SEQ;
DROP SEQUENCE ORDER_ID_SEQ;
DROP SEQUENCE ORDER_PRODUCT_ID_SEQ;
DROP SEQUENCE STORE_ID_SEQ;
DROP SEQUENCE RETURN_ID_SEQ;
DROP SEQUENCE FEEDBACK_ID_SEQ;


SET SERVEROUTPUT ON;
DECLARE
    CNT NUMBER;
BEGIN
    -- CATEGORY ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'CATEGORY';
    IF cnt = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE category (
            ID VARCHAR2(10) CONSTRAINT category_pk PRIMARY KEY,
            name VARCHAR2(20) Unique NOT NULL,
            return_by_days NUMBER(2) NOT NULL CHECK (return_by_days > 0 AND return_by_days < 100)
        )';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table category already exists.');
    END IF;

    -- CUSTOMER ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'CUSTOMER';
    IF CNT = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE customer (
            id VARCHAR2(10) CONSTRAINT customer_pk PRIMARY KEY,
            name VARCHAR2(50) NOT NULL,
            contact_no NUMBER(10) Unique NOT NULL,
            date_of_birth DATE NOT NULL,
            email_id VARCHAR2(30) Unique NOT NULL,
            joined_date DATE NOT NULL,
            address_line VARCHAR2(100) NOT NULL,
            city VARCHAR2(30) NOT NULL,
            state VARCHAR2(30) NOT NULL,
            zip_code VARCHAR2(5) NOT NULL
        )';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table customer already exists.');
    END IF;

    -- SELLER ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'SELLER';
    IF CNT = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE seller (
            id VARCHAR2(10) CONSTRAINT seller_pk PRIMARY KEY,
            name       VARCHAR(20) NOT NULL,
            contact_no NUMBER(10) Unique NOT NULL
        )';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table seller already exists.');
    END IF;

    -- PRODUCT ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'PRODUCT';
    IF CNT = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE product (
            id VARCHAR2(10) CONSTRAINT product_pk PRIMARY KEY,
            name VARCHAR2(20) NOT NULL,
            price NUMBER(10,2) NOT NULL,
            mfg_date DATE NOT NULL,
            exp_date DATE,
            category_id VARCHAR2(10) NOT NULL,
            seller_id VARCHAR2(10) NOT NULL,
            CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES category(id),
            CONSTRAINT fk_product_seller FOREIGN KEY (seller_id) REFERENCES seller(id),
            CONSTRAINT productname_seller_unique UNIQUE (name, seller_id)
        )';
        EXECUTE IMMEDIATE 'ALTER TABLE product
        ADD CONSTRAINT 
        end_date_later_than_start_date_CK CHECK (mfg_date < exp_date)'; 
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table product already exists.');
    END IF;

    -- CUSTOMER_ORDER ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'CUSTOMER_ORDER';
    IF CNT = 0 THEN
       EXECUTE IMMEDIATE 'CREATE TABLE customer_order (
        id VARCHAR2(10) CONSTRAINT order_pk PRIMARY KEY,
        customer_id VARCHAR2(10) NOT NULL,
        order_date DATE NOT NULL,
        status VARCHAR(20) NOT NULL CHECK (status IN (''DELIVERED'', ''IN_TRANSIT'', ''SHIPPED'', ''ORDER_PLACED'')),
        CONSTRAINT fk_order_customer FOREIGN KEY (customer_id) REFERENCES customer(id)
    )';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table customer_order already exists.');
    END IF;

    -- ORDER_PRODUCT ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'ORDER_PRODUCT';
    IF CNT = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE order_product (
            id VARCHAR2(10) CONSTRAINT order_product_pk PRIMARY KEY,
            customer_order_id VARCHAR2(10) NOT NULL,
            product_id VARCHAR2(10) NOT NULL,
            quantity NUMBER(3) NOT NULL  CHECK (quantity > 0 ),
            CONSTRAINT fk_order_product_order FOREIGN KEY (customer_order_id) REFERENCES customer_order(id),
            CONSTRAINT fk_order_product_product FOREIGN KEY (product_id) REFERENCES product(id)
        )';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table order_product already exists.');
    END IF;

    -- DISCOUNT ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'DISCOUNT';
    IF CNT = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE discount (
            id VARCHAR2(10) CONSTRAINT discount_pk PRIMARY KEY,
            category_id VARCHAR2(10) NOT NULL,
            discount_rate NUMBER(3,1) NOT NULL CHECK (discount_rate > 0 AND discount_rate < 100),
            start_date DATE NOT NULL,
            end_date DATE NOT NULL,
            CONSTRAINT fk_discount_category FOREIGN KEY (category_id) REFERENCES category(id)
        )';
         EXECUTE IMMEDIATE 'ALTER TABLE DISCOUNT
         ADD CONSTRAINT 
        disend_date_later_than_start_date_CK CHECK (start_date <= end_date)';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table discount already exists.');
    END IF;

    -- STORE ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'STORE';
    IF CNT = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE store (
            id VARCHAR2(10) CONSTRAINT store_pk PRIMARY KEY,
            name              VARCHAR(20) NOT NULL,
            contact_no        NUMBER(10)unique NOT NULL,
            address_line      VARCHAR(30) NOT NULL,
            city              VARCHAR(30) NOT NULL,
            state             VARCHAR(30) NOT NULL,
            zip_code          VARCHAR(5) NOT NULL,
            accepting_returns NUMBER(1) NOT NULL
        )';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table store already exists.');
    END IF;

    -- FEEDBACK ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'FEEDBACK';
    IF CNT = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE feedback (
            id VARCHAR2(10) CONSTRAINT feedback_pk PRIMARY KEY,
            customer_id VARCHAR2(10) NOT NULL,
            store_id VARCHAR2(10) NOT NULL,
            customer_rating NUMBER(2,1) NOT NULL CHECK (customer_rating >= 1.0 AND customer_rating <= 5.0),
            Review VARCHAR2(500),
            CONSTRAINT fk_feedback_customer FOREIGN KEY (customer_id) REFERENCES customer(id),
            CONSTRAINT fk_feedback_order FOREIGN KEY (store_id) REFERENCES store(id),
            CONSTRAINT customer_store_unique UNIQUE (customer_id, store_id)
        )';
    ELSE
        DBMS_OUTPUT.PUT_LINE('Table feedback already exists.');
    END IF;

    -- RETURN ENTITY CREATION IF DOESNOT EXIST
    SELECT COUNT(*) INTO CNT FROM USER_TABLES WHERE TABLE_NAME = 'RETURN';
    IF CNT = 0 THEN
      EXECUTE IMMEDIATE 'CREATE TABLE return (
        id VARCHAR2(10) CONSTRAINT return_pk PRIMARY KEY,
        reason VARCHAR(500) NOT NULL,
        return_date DATE NOT NULL,
        refund_status VARCHAR(20) CHECK (refund_status IN (''PROCESSING'',''REJECTED'',''COMPLETED'')),
        quantity_returned NUMBER(3) NOT NULL CHECK (quantity_returned > 0 ),
        processing_fee NUMBER(5, 2), -- not all returns will be successful so I put not, null,
        request_accepted NUMBER(1) CHECK (request_accepted IN (0, 1)),
        store_id VARCHAR(10) NOT NULL,
        order_product_id VARCHAR(10) NOT NULL,
        CONSTRAINT fk_return_order_product FOREIGN KEY (order_product_id) REFERENCES order_product(id),
        CONSTRAINT return_store_fk FOREIGN KEY (store_id) REFERENCES store(id)
    )';

    ELSE
        DBMS_OUTPUT.PUT_LINE('Table return already exists.');
    END IF;


END;
/

----------------------------------                          ADDING COMMENTS FOR EACH ATTRIBUTE OF ENTITIES                                    ----------------------------------------

COMMENT ON COLUMN return.id IS 'Unique identifier for each return record(PK)';
COMMENT ON COLUMN return.reason IS 'Description of the reason for the return';
COMMENT ON COLUMN return.return_date IS 'Date when the return was requested';
COMMENT ON COLUMN return.refund_status IS 'Current status of the refund, can be IN_PROGRESS or SUCCESSFUL';
COMMENT ON COLUMN return.quantity_returned IS 'Number of items returned';
COMMENT ON COLUMN return.processing_fee IS 'Fee charged for processing the return, if applicable';
COMMENT ON COLUMN return.request_accepted IS 'Indicates if the return request has been accepted (1) or not (0)';
COMMENT ON COLUMN return.store_id IS 'Identifier of the store from which the item was purchased(FK)';
COMMENT ON COLUMN return.order_product_id IS 'Identifier of the ordered product being returned(FK)';




COMMENT ON COLUMN feedback.id IS 'Unique identifier for each feedback record(PK)';
COMMENT ON COLUMN feedback.customer_id IS 'Identifier of the customer providing feedback';
COMMENT ON COLUMN feedback.store_id IS 'Identifier of the store to which the feedback is directed(FK)';
COMMENT ON COLUMN feedback.customer_rating IS 'Numerical rating given by the customer, ranging from 1.0 to 5.0';
COMMENT ON COLUMN feedback.Review IS 'Textual review provided by the customer describing their experience';



COMMENT ON COLUMN store.id IS 'Unique identifier for each store(PK)';
COMMENT ON COLUMN store.name IS 'Name of the store';
COMMENT ON COLUMN store.contact_no IS 'Contact number for the store, must be unique';
COMMENT ON COLUMN store.address_line IS 'Address line for the store location';
COMMENT ON COLUMN store.city IS 'City where the store is located';
COMMENT ON COLUMN store.state IS 'State where the store is located';
COMMENT ON COLUMN store.zip_code IS 'ZIP code for the store location';
COMMENT ON COLUMN store.accepting_returns IS 'Indicates if the store accepts returns (1) or not (0)';



COMMENT ON COLUMN discount.id IS 'Unique identifier for each discount record(PK)';
COMMENT ON COLUMN discount.category_id IS 'Identifier of the category to which the discount applies(FK)';
COMMENT ON COLUMN discount.discount_rate IS 'Percentage rate of the discount, must be more than 0 and less than 100';
COMMENT ON COLUMN discount.start_date IS 'The start date from which the discount is applicable';
COMMENT ON COLUMN discount.end_date IS 'The end date until which the discount is applicable';
COMMENT ON TABLE discount IS 'Constraints: disend_date_later_than_start_date_CK ensures that the start date is on or before the end date.';


COMMENT ON COLUMN product.id IS 'Unique identifier for each product(PK)';
COMMENT ON COLUMN product.name IS 'Name of the product';
COMMENT ON COLUMN product.price IS 'Price of the product';
COMMENT ON COLUMN product.mfg_date IS 'Manufacturing date of the product';
COMMENT ON COLUMN product.exp_date IS 'Expiration date of the product, if applicable';
COMMENT ON COLUMN product.category_id IS 'Identifier for the category of the product(FK)';
COMMENT ON COLUMN product.seller_id IS 'Identifier for the seller of the product(FK)';
COMMENT ON COLUMN product.exp_date IS 'Ensures the expiration date is later than the manufacturing date, if expiration date is specified';



COMMENT ON COLUMN category.ID IS 'Unique identifier for each category(PK)';
COMMENT ON COLUMN category.name IS 'Name of the category, must be unique';
COMMENT ON COLUMN category.return_by_days IS 'Number of days within which items of this category can be returned, must be between 1 and 99';



COMMENT ON COLUMN customer.id IS 'Unique identifier for each customer(PK)';
COMMENT ON COLUMN customer.name IS 'Full name of the customer';
COMMENT ON COLUMN customer.contact_no IS 'Contact number of the customer, must be unique';
COMMENT ON COLUMN customer.date_of_birth IS 'Date of birth of the customer';
COMMENT ON COLUMN customer.email_id IS 'Email address of the customer, must be unique';
COMMENT ON COLUMN customer.joined_date IS 'Date when the customer joined or was registered';
COMMENT ON COLUMN customer.address_line IS 'Address line for the customers residence';
COMMENT ON COLUMN customer.city IS 'City part of the customers address';
COMMENT ON COLUMN customer.state IS 'State part of the customers address';
COMMENT ON COLUMN customer.zip_code IS 'ZIP code part of the customers address';


COMMENT ON COLUMN seller.id IS 'Unique identifier for each seller(PK)';
COMMENT ON COLUMN seller.name IS 'Name of the seller';
COMMENT ON COLUMN seller.contact_no IS 'Contact number of the seller, must be unique';

COMMENT ON COLUMN customer_order.id IS 'Unique identifier for each customer order(PK)';
COMMENT ON COLUMN customer_order.customer_id IS 'Reference to the customer who placed the order(FK)';
COMMENT ON COLUMN customer_order.order_date IS 'Date when the order was placed';
COMMENT ON COLUMN customer_order.status IS 'Current status of the order, which can be DELIVERED, IN_TRANSIT, SHIPPED, or ORDER_PLACED';


COMMENT ON COLUMN order_product.id IS 'Unique identifier for each order-product relation record(PK)';
COMMENT ON COLUMN order_product.customer_order_id IS 'Reference to the customer order this product is part of(FK)';
COMMENT ON COLUMN order_product.product_id IS 'Reference to the product included in the order(FK)';
COMMENT ON COLUMN order_product.quantity IS 'Quantity of the product ordered';

----------------------------------- SEQUENCE VALDIATION ---------------------------------------------------

DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'CUSTOMER_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE CUSTOMER_ID_SEQ START WITH 1 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'CATEGORY_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE CATEGORY_ID_SEQ START WITH 101 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'DISCOUNT_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE DISCOUNT_ID_SEQ START WITH 901 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'SELLER_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE SELLER_ID_SEQ START WITH 1001 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'PRODUCT_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE PRODUCT_ID_SEQ START WITH 1501 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'ORDER_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ORDER_ID_SEQ START WITH 501 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'ORDER_PRODUCT_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE ORDER_PRODUCT_ID_SEQ START WITH 5501 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'STORE_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE STORE_ID_SEQ START WITH 2001 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'RETURN_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE RETURN_ID_SEQ START WITH 9001 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 
DECLARE
   v_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM user_sequences
   WHERE sequence_name = 'FEEDBACK_ID_SEQ'; -- Make sure the name is in uppercase
 
   IF v_count = 0 THEN
      EXECUTE IMMEDIATE 'CREATE SEQUENCE FEEDBACK_ID_SEQ START WITH 3001 INCREMENT BY 1';
   END IF;
EXCEPTION
   WHEN OTHERS THEN
      RAISE;
END;
/
 


----------------------------------------------------------                           DML STATEMENTS                   ---------------------------------------------------------------------

-- THE FOLLOWING DML STATEMENTS WILL CHECK FOR PRIMARY AND UNIQUE KEY CONSTRAINS(PHONE NO, EMAIL-ID) BEFORE INSERTING ROWNS INTO CORRESPONDING ENTITES. THUS PREVENTING DUPLICATE ENTRIES

-- DML FOR CUSTOMER ENTITY



BEGIN
    BEGIN
        INSERT INTO customer (id, name, contact_no, date_of_birth, email_id, joined_date, address_line, city, state, zip_code)
        VALUES (CUSTOMER_ID_SEQ.NEXTVAL, 'Alice Michel', '9100000001', TO_DATE('1992-06-01', 'YYYY-MM-DD'), 'alice@gmail.com', TO_DATE('2022-01-10', 'YYYY-MM-DD'), '123 Harvard Ave', 'Boston', 'MA', '12345');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for Alice Michel or phone number or email already in use.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer (id, name, contact_no, date_of_birth, email_id, joined_date, address_line, city, state, zip_code)
        VALUES (CUSTOMER_ID_SEQ.NEXTVAL, 'Bob Santos', '9200000002', TO_DATE('1988-08-15', 'YYYY-MM-DD'), 'bob@gmail.com', TO_DATE('2022-02-20', 'YYYY-MM-DD'), '456 Brokkline Rd', 'New York', 'NY', '23456');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for Bob Santos or phone number or email already in use.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer (id, name, contact_no, date_of_birth, email_id, joined_date, address_line, city, state, zip_code)
        VALUES (CUSTOMER_ID_SEQ.NEXTVAL, 'Charlie Heisenberg', '9300000003', TO_DATE('1990-12-25', 'YYYY-MM-DD'), 'charlie@gmail.com', TO_DATE('2022-03-15', 'YYYY-MM-DD'), '789 Cocoa St', 'Chicago', 'IL', '34567');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for Charlie Heisenberg or phone number or email already in use.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
END;
/

-- DML FOR CATEGORY ENTITY


BEGIN
    BEGIN
        INSERT INTO category (id, name, return_by_days)
        VALUES (CATEGORY_ID_SEQ.NEXTVAL, 'Food/Beverages', 7);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for Food/Beverages.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO category (id, name, return_by_days)
        VALUES (CATEGORY_ID_SEQ.NEXTVAL, 'Electronics', 40);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for Electronics.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO category (id, name, return_by_days)
        VALUES (CATEGORY_ID_SEQ.NEXTVAL, 'Clothing/Apparel', 25);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for Clothing/Apparel.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO category (id, name, return_by_days)
        VALUES (CATEGORY_ID_SEQ.NEXTVAL, 'Healthcare', 10);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for Healthcare.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    
END;
/


-- DML FOR DISCOUNT ENTITY


BEGIN
    BEGIN
        INSERT INTO discount (id, category_id, discount_rate, start_date, end_date)
        VALUES (DISCOUNT_ID_SEQ.NEXTVAL, '101', 10.00, TO_DATE('2024-01-01', 'YYYY-MM-DD'), TO_DATE('2024-01-31', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate discount not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO discount (id, category_id, discount_rate, start_date, end_date)
        VALUES (DISCOUNT_ID_SEQ.NEXTVAL, '101', 15.00, TO_DATE('2024-03-10', 'YYYY-MM-DD'), TO_DATE('2024-03-18', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate discount not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO discount (id, category_id, discount_rate, start_date, end_date)
        VALUES (DISCOUNT_ID_SEQ.NEXTVAL, '101', 20.00, TO_DATE('2024-06-01', 'YYYY-MM-DD'), TO_DATE('2024-06-30', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate discount not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

END;
/


-- DML FOR SELLER ENTITY




BEGIN
    BEGIN
        INSERT INTO seller (id, name, contact_no)
        VALUES (SELLER_ID_SEQ.NEXTVAL, 'Apple Inc.', 8006927753);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate seller Apple Inc or phone number in use, not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO seller (id, name, contact_no)
        VALUES (SELLER_ID_SEQ.NEXTVAL, 'Nike', 8008066453);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate seller Nike Inc. not inserted or phone number in use, not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO seller (id, name, contact_no)
        VALUES (SELLER_ID_SEQ.NEXTVAL, 'Vicks', 8003621683);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate seller Nike. not inserted or phone number in use, not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert UPS in Boston due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO seller (id, name, contact_no)
        VALUES (SELLER_ID_SEQ.NEXTVAL, 'Whole Foods', 8005551212);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate seller Whole Foodsor phone number in use, not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

END;
/


-- DML FOR PRODUCT ENTITY



BEGIN
    -- Inserting Milk with mfg_date and exp_date
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date, exp_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'Milk', 2.99, '101', '1004', TO_DATE('2024-03-10', 'YYYY-MM-DD'), TO_DATE('2024-03-29', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product Milk not inserted.');
        WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    -- Inserting Bread with mfg_date and exp_date
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date, exp_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'Bread', 3.49, '101', '1004', TO_DATE('2024-03-10', 'YYYY-MM-DD'), TO_DATE('2024-03-25', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product Bread not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    -- Inserting Cake with mfg_date and exp_date
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date, exp_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'Cake', 15.00, '101', '1004', TO_DATE('2024-03-11', 'YYYY-MM-DD'), TO_DATE('2024-03-25', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product Cake not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
END;
/


BEGIN
    -- Electronics Products
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'iPhone', 999.00, '102', '1001', TO_DATE('2024-02-15', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product iPhone not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'Laptop', 1300.00, '102', '1001', TO_DATE('2024-01-10', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product Laptop not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'Watches', 250.00, '102', '1001', TO_DATE('2024-02-05', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product Watches not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    -- Clothing/Apparel Products
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'Shoes', 120.00, '103', '1002', TO_DATE('2024-03-01', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product Shoes not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'Jacket', 250.00, '103', '1002', TO_DATE('2024-02-20', 'YYYY-MM-DD'));
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product Jacket not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO product (id, name, price, category_id, seller_id, mfg_date)
        VALUES (PRODUCT_ID_SEQ.NEXTVAL, 'Trousers', 85.00, '103', '1002', TO_DATE('2024-01-25', 'YYYY-MM-DD'));
    EXCEPTION WHEN 
        DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate product Trousers not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
END;
/




-- DML FOR CUSTOMER_ORDER ENTITY



BEGIN
    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '1', TO_DATE('2024-03-16', 'YYYY-MM-DD'), 'DELIVERED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '2', TO_DATE('2024-03-12', 'YYYY-MM-DD'), 'DELIVERED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '3', TO_DATE('2024-03-13', 'YYYY-MM-DD'), 'DELIVERED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '1', TO_DATE('2024-03-14', 'YYYY-MM-DD'), 'DELIVERED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order  not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '2', TO_DATE('2024-03-18', 'YYYY-MM-DD'), 'DELIVERED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '3', TO_DATE('2024-03-11', 'YYYY-MM-DD'), 'DELIVERED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '1', TO_DATE('2024-03-17', 'YYYY-MM-DD'), 'DELIVERED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '2', TO_DATE('2024-03-16', 'YYYY-MM-DD'), 'SHIPPED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '3', TO_DATE('2024-03-25', 'YYYY-MM-DD'), 'SHIPPED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO customer_order (id, customer_id, order_date, status)
        VALUES (ORDER_ID_SEQ.NEXTVAL, '1', TO_DATE('2024-03-11', 'YYYY-MM-DD'), 'SHIPPED');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate order not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
END;
/


-- DML FOR ORDER_PRODUCT ENTITY


BEGIN
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '501', '1501', 3);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for  not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '501', '1502', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for  not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    -- Order 2 Product Associations
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '502', '1503', 2);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '502', '1504', 2);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '503', '1505', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '503', '1506', 3);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    -- Order 4 Product Associations
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '504', '1507', 2);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '504', '1508', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    -- Order 5 Product Associations
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '505', '1509', 2);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '505', '1501', 3);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    -- Order 6 Product Associations
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '506', '1505', 2);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '506', '1506', 3);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    -- Order 7 Product Associations
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '507', '1501', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '507', '1502', 2);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    -- Order 8 Product Associations
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '508', '1503', 3);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '508', '1504', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    -- Order 9 Product Associations
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '509', '1505', 2);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '509', '1506', 3);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    -- Order 10 Product Associations
    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '510', '1501', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO order_product (id, customer_order_id, product_id, quantity)
        VALUES (ORDER_PRODUCT_ID_SEQ.NEXTVAL, '510', '1502', 2);
    EXCEPTION  
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate entry for not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
END;
/


-- DML FOR STORE ENTITY




BEGIN
    -- Inserting UPS in Boston
    BEGIN
        INSERT INTO store (id, name, contact_no, address_line, city, state, zip_code, accepting_returns)
        VALUES (STORE_ID_SEQ.NEXTVAL, 'UPS', 8007425877, '1 UPS Way', 'Boston', 'MA', '02101', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate store UPS or phone number in use, not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
        
    END;

    -- Inserting FedEx in New York
    BEGIN
        INSERT INTO store (id, name, contact_no, address_line, city, state, zip_code, accepting_returns)
        VALUES (STORE_ID_SEQ.NEXTVAL, 'FedEx', 8004633339, '2 FedEx Plaza', 'New York', 'NY', '10001', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate store FedEx or phone number in use, not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
       
    END;

    -- Inserting Five Guys in Chicago
    BEGIN
        INSERT INTO store (id, name, contact_no, address_line, city, state, zip_code, accepting_returns)
        VALUES (STORE_ID_SEQ.NEXTVAL, 'Five Guys', 8005551234, '3 Burger Blvd', 'Chicago', 'IL', '60606', 1);
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate store Five Guys or phone number in use, not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
        
    END;
END;
/


-- DML FOR RETURN ENTITY



BEGIN
    BEGIN
        INSERT INTO return (id, reason, return_date, refund_status, quantity_returned, processing_fee, request_accepted, store_id, order_product_id)
        VALUES (RETURN_ID_SEQ.NEXTVAL, 'Alegeric to the product', TO_DATE('2024-03-22', 'YYYY-MM-DD'), 'COMPLETED', 2, 5.00, 1, '2001', '5510');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate return not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO return (id, reason, return_date, refund_status, quantity_returned, processing_fee, request_accepted, store_id, order_product_id)
        VALUES (RETURN_ID_SEQ.NEXTVAL, 'Changed mind', TO_DATE('2024-03-22', 'YYYY-MM-DD'), 'COMPLETED', 1, 0, 1, '2002', '5504');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate return not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
     BEGIN
        INSERT INTO return (id, reason, return_date, refund_status, quantity_returned, processing_fee, request_accepted, store_id, order_product_id)
        VALUES (RETURN_ID_SEQ.NEXTVAL, 'Product defect', TO_DATE('2024-03-21', 'YYYY-MM-DD'), 'COMPLETED', 1, 0, 1, '2003', '5502');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate return not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    BEGIN
        INSERT INTO return (id, reason, return_date, refund_status, quantity_returned, processing_fee, request_accepted, store_id, order_product_id)
        VALUES (RETURN_ID_SEQ.NEXTVAL, 'Late delivery.', TO_DATE('2024-03-22', 'YYYY-MM-DD'), 'COMPLETED', 1, 10.00, 1, '2001', '5506');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate return not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO return (id, reason, return_date, refund_status, quantity_returned, processing_fee, request_accepted, store_id, order_product_id)
        VALUES (RETURN_ID_SEQ.NEXTVAL, 'Tastes bad', TO_DATE('2024-03-30', 'YYYY-MM-DD'), 'COMPLETED', 1, 1.00, 1, '2002', '5510');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate return not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO return (id, reason, return_date, refund_status, quantity_returned, processing_fee, request_accepted, store_id, order_product_id)
        VALUES (RETURN_ID_SEQ.NEXTVAL, 'Not a good fit', TO_DATE('2024-03-20', 'YYYY-MM-DD'), 'COMPLETED', 1, 2.00, 1, '2002', '5509');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate return not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO return (id, reason, return_date, refund_status, quantity_returned, processing_fee, request_accepted, store_id, order_product_id)
        VALUES (RETURN_ID_SEQ.NEXTVAL, 'Broken milk', TO_DATE('2024-03-19', 'YYYY-MM-DD'), 'COMPLETED', 1, 1.00, 1, '2003', '5513');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate return not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;

    BEGIN
        INSERT INTO return (id, reason, return_date, refund_status, quantity_returned, processing_fee, request_accepted, store_id, order_product_id)
        VALUES (RETURN_ID_SEQ.NEXTVAL, 'Wrong flavor', TO_DATE('2024-03-14', 'YYYY-MM-DD'), 'COMPLETED', 1, 2.00, 1, '2003', '5503');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate return not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
    
    
   
END;
/



-- DML FOR FEEDBACK ENTITY




BEGIN
    -- Feedback 1
    BEGIN
        INSERT INTO feedback (id, customer_id, store_id, customer_rating, Review)
        VALUES (FEEDBACK_ID_SEQ.NEXTVAL, '2', '2001', 4.5, 'Great service and staff very helpful.');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate feedback not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
 
    -- Feedback 2
    BEGIN
        INSERT INTO feedback (id, customer_id, store_id, customer_rating, Review)
        VALUES (FEEDBACK_ID_SEQ.NEXTVAL, '2', '2002', 3.0, 'Staffs not helpful.');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate feedback not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
 
    -- Feedback 3
    BEGIN
        INSERT INTO feedback (id, customer_id, store_id, customer_rating, Review)
        VALUES (FEEDBACK_ID_SEQ.NEXTVAL, '1', '2003', 5.0, 'Absolutely love it! Highly recommend.');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate feedback not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
 
    -- Feedback 4
    BEGIN
        INSERT INTO feedback (id, customer_id, store_id, customer_rating, Review)
        VALUES (FEEDBACK_ID_SEQ.NEXTVAL, '3', '2001', 4.0, 'Very-helpful and friendly staff.');
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Duplicate feedback not inserted.');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Failed to insert due to constraint violation or invalid data type.');
    END;
END;
/



COMMIT;
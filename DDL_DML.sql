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
        order_product_id VARCHAR(10) NOT NULL UNIQUE,
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


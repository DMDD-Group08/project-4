-------------------------------- STORED PROCEDURES --------------------------------------------------

--------------------- UPDATE_SELLER_REFUND procedure
CREATE OR REPLACE PROCEDURE UPDATE_SELLER_REFUND (
    return_id IN VARCHAR,
    accept_yes_no IN VARCHAR,
    seller_contact IN VARCHAR  
) AS
    invalid_input_exception EXCEPTION;
    invalid_contact_exception EXCEPTION;
    invalid_return_id_exception EXCEPTION;
    invalid_seller_return_combination_exception EXCEPTION;
    
    return_id_if_exists NUMBER;
    seller_contact_if_exists NUMBER;
    seller_return_combination_if_exists NUMBER;
    s_contact_no NUMBER;
    r_id NUMBER;
    CUSTOMER_RI NUMBER(1);
    PRICE_CHARGED NUMBER(10,2);
BEGIN
    -- Attempt to convert string to NUMBER
    BEGIN
        r_id := TO_NUMBER(return_id);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid return id format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- Attempt to convert string to NUMBER
    BEGIN
        s_contact_no := TO_NUMBER(seller_contact);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid seller contact number format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- IF accept_yes_no IS RANDOM VALUE, RAISE invalid_input_exception
    IF UPPER(accept_yes_no) NOT IN ('YES', 'NO') THEN
        RAISE invalid_input_exception;
        RETURN;
    END IF;
    
    -- if return_id does not exists, raise exception   
    SELECT COUNT(1)INTO return_id_if_exists FROM RETURN WHERE ID=r_id;
    IF return_id_if_exists=0 THEN
        RAISE invalid_return_id_exception;
        RETURN;
    END IF;
    
    -- if seller_contact does not exists, raise exception   
    SELECT COUNT(1)INTO seller_contact_if_exists FROM SELLER WHERE CONTACT_NO = s_contact_no;
    IF seller_contact_if_exists=0 THEN
        RAISE invalid_contact_exception;
        RETURN;
    END IF;  
    
    -- if seller_return_id does not exists, raise exception   
    SELECT COUNT(1) INTO seller_return_combination_if_exists FROM CHECK_APPROVED_RETURNS_BY_SYSTEM WHERE RETURN_ID = r_id AND SELLER_CONTACT = s_contact_no;
    
    IF seller_return_combination_if_exists=0 THEN
        RAISE invalid_seller_return_combination_exception;
        RETURN;
    END IF;    
    
    -- UPDATE REFUND_STATUS BASED ON IF SELLER ACCEPTS/REJECTS THE RETURN
    UPDATE RETURN
    SET REFUND_STATUS = 
        CASE 
            WHEN UPPER(accept_yes_no) = 'YES' THEN 'COMPLETED'
            WHEN UPPER(accept_yes_no) = 'NO' THEN 'REJECTED'
        END
    WHERE
        id = r_id;
    COMMIT;
    dbms_output.put_line('updated refund_status');
    
    -- UPDATE PROCESSING FEE BASED ON CUSTOMER_RI
    IF UPPER(accept_yes_no) = 'YES' THEN
        dbms_output.put_line('return accpeted');
        
        -- FETCHING CUSTOMER_RI OF CUSTOMER BASED ON RETURN_ID
        SELECT CRI.Reliability_Index INTO CUSTOMER_RI
        FROM Customer_Reliability_Index CRI
        JOIN CUSTOMER C ON C.ID = CRI.CUSTOMER_ID
        JOIN CUSTOMER_ORDER CO ON CO.CUSTOMER_ID = C.ID
        JOIN ORDER_PRODUCT OP ON OP.CUSTOMER_ORDER_ID = CO.ID
        JOIN RETURN R ON OP.ID = R.ORDER_PRODUCT_ID
        WHERE R.ID = r_id;
        dbms_output.put_line('1111');

        -- FETCHING PRICE_CHARGED FOR ORDER_PRODUCT ASSOCIATED WITH THE RETURN
        SELECT NVL(RAV.PRICE - (RAV.PRICE * RAV.DISCOUNT_RATE/100), RAV.PRICE) INTO PRICE_CHARGED
        FROM REFUND_AMOUNT_VIEW RAV
        JOIN RETURN R ON R.ORDER_PRODUCT_ID = RAV.ID
        WHERE R.ID = r_id;
        
        dbms_output.put_line('22222');

        -- UPDATE PROCESSING_FEE BASED ON CUSTOMER_RI AND PRICE_CHARGED
        UPDATE RETURN
        SET PROCESSING_FEE = (5-CUSTOMER_RI)*(0.01 * PRICE_CHARGED) -- 1% OF PRICE CHARGED IS CALCULATED AS PROCESSING FEE AND MULTIPLED WITH INVERSE OF CUSTOMER_RI
        WHERE id = r_id;
        
        dbms_output.put_line('processing fee updated');
        
    ELSE
        dbms_output.put_line('return rejected');
        UPDATE RETURN
        SET PROCESSING_FEE = 0 -- IF SELLER REJECTS THE RETURN, PROCESSING FEE IS SET TO ZERO
        WHERE id = r_id;
    END IF;
        
    COMMIT;
    dbms_output.put_line('Seller refund updated successfully.');
EXCEPTION
    WHEN dup_val_on_index THEN
        dbms_output.put_line('Primary/Unique key violation occured. Make sure to enter correct values.');
        return;
    WHEN invalid_input_exception THEN
        dbms_output.put_line('Invalid input. Please enter either YES or NO.');
        return;
    WHEN invalid_return_id_exception THEN
        dbms_output.put_line('Invalid return id. Please check if return_id entered is correct.');
        return;
    WHEN invalid_contact_exception THEN
        dbms_output.put_line('Invalid seller contact no. Please check if seller contact_no entered is correct.');
        return;
    WHEN invalid_seller_return_combination_exception THEN
        dbms_output.put_line('The seller is not asscoisated with the given return');
        return;
    WHEN OTHERS THEN
        dbms_output.put_line('Something else went wrong - '|| sqlcode|| ' : ' || sqlerrm);
        return;
END;
/

------------------------- View the customer's return requests that are accepted -------------------------

CREATE OR REPLACE PROCEDURE show_returns_request(
    p_email VARCHAR2
) AS
    -- Variable to hold customer ID
    v_customer_id VARCHAR2(10);
    

    -- Cursor declaration for retrieving return details
    CURSOR c_return_details IS
        SELECT rt.id AS return_id,
               rt.reason,
               rt.return_date,
               rt.refund_status,
               rt.quantity_returned,
               rt.processing_fee,
               rt.request_accepted,
               op.product_id,
               p.name AS product_name, -- Correct the alias if 'prod' was incorrect
               cst.id AS order_id,
                rt.order_product_id AS ORDER_PRODUCT_ID

        FROM return rt
        JOIN order_product op ON rt.order_product_id = op.id
        JOIN product p ON op.product_id = p.id -- Ensure 'product' is aliased correctly here
        JOIN customer_order cst ON op.customer_order_id = cst.id
        WHERE cst.customer_id = v_customer_id;

    -- Variable to hold each row fetched from the cursor
    v_return_detail c_return_details%ROWTYPE;

BEGIN
    -- Fetch the customer ID based on the email address
    SELECT id INTO v_customer_id FROM customer WHERE email_id = p_email;

    -- Opening cursor to fetch data
    OPEN c_return_details;

    -- Loop through the cursor to fetch and display return details
    LOOP
        FETCH c_return_details INTO v_return_detail;
        EXIT WHEN c_return_details%NOTFOUND;

        -- Displaying return details
        DBMS_OUTPUT.PUT_LINE('Return ID: ' || v_return_detail.return_id);
        DBMS_OUTPUT.PUT_LINE('Order ID: ' || v_return_detail.order_id);
        DBMS_OUTPUT.PUT_LINE('Product ID: ' || v_return_detail.product_id);
        DBMS_OUTPUT.PUT_LINE('Product Name: ' || v_return_detail.product_name);
        DBMS_OUTPUT.PUT_LINE('Reason for Return: ' || v_return_detail.reason);
        DBMS_OUTPUT.PUT_LINE('Return Date: ' || v_return_detail.return_date);
        DBMS_OUTPUT.PUT_LINE('Refund Status: ' || v_return_detail.refund_status);
        DBMS_OUTPUT.PUT_LINE('Quantity Returned: ' || v_return_detail.quantity_returned);
        DBMS_OUTPUT.PUT_LINE('Processing Fee: ' || v_return_detail.processing_fee);
        DBMS_OUTPUT.PUT_LINE('Request Accepted: ' || CASE WHEN v_return_detail.request_accepted = 1 THEN 'Yes' ELSE 'No' END);
        DBMS_OUTPUT.PUT_LINE('-----------------------------------');
    END LOOP;

    -- Close the cursor after use
    CLOSE c_return_details;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No customer found with that email address.');
    WHEN OTHERS THEN
        -- Error handling
        DBMS_OUTPUT.PUT_LINE('Error encountered, check input');
        -- Ensure cursor is closed on error
        IF c_return_details%ISOPEN THEN
            CLOSE c_return_details;
        END IF;
END;
/

------------------------ Procedure to initiate return request for the purchased products ---------------------
CREATE OR REPLACE PROCEDURE create_return (
    qty OUT NUMBER,
    reason            IN return.reason%TYPE,
    quantity_returned IN return.quantity_returned%TYPE,
    store_id          IN return.store_id%TYPE,
    order_product_id  IN return.order_product_id%TYPE
) AS
    l_days_remaining NUMBER;
 
    -- Custom exceptions
    e_invalid_store_id EXCEPTION;
    e_invalid_order_product_id EXCEPTION;
    e_invalid_quantity EXCEPTION;
    e_invalid_reason EXCEPTION;
    e_invalid_quantity_returned EXCEPTION;
    e_invalid_store_id_format EXCEPTION;
    e_invalid_order_product_id_format EXCEPTION;
    e_invalid_reason_format EXCEPTION;
    e_invalid_quantity_returned_format EXCEPTION;
    e_reason_exceeds_limit EXCEPTION;
 
BEGIN
    -- Output debug message
    DBMS_OUTPUT.PUT_LINE('Procedure execution: Initiating return creation.');
    
    -- Check if reason is valid (not a number)
    BEGIN
        IF REGEXP_LIKE(reason, '^[0-9]+$') THEN
            RAISE e_invalid_reason;
        END IF;
    EXCEPTION
        WHEN e_invalid_reason THEN
            RAISE e_invalid_reason_format;
    END;
    
    -- Check if quantity_returned is a number
    BEGIN
        l_days_remaining := TO_NUMBER(quantity_returned);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RAISE e_invalid_quantity_returned_format;
    END;
    
    -- Check if store_id is a number
    BEGIN
        l_days_remaining := TO_NUMBER(store_id);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RAISE e_invalid_store_id_format;
    END;
    
    -- Check if order_product_id is a number
    BEGIN
        l_days_remaining := TO_NUMBER(order_product_id);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            RAISE e_invalid_order_product_id_format;
    END;
    
    -- Check if quantity_returned is less than or equal to Available Quantity in Available Quantity View
    BEGIN
        SELECT Available_Qty INTO qty
        FROM QTY_AVAILABLE_FOR_RETURN
        WHERE Order_product_id_ = order_product_id;
        
        
        IF quantity_returned > qty THEN
            RAISE e_invalid_quantity;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_invalid_order_product_id;
    END;
    
    -- Check if store_id is present in the ID column of STORE entity
    BEGIN
        SELECT id
        INTO l_days_remaining
        FROM STORE
        WHERE id = store_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_invalid_store_id;
    END;
    
    -- Check if order_product_id is present in ID of ORDER_PRODUCT Entity
    BEGIN
        SELECT id
        INTO l_days_remaining
        FROM ORDER_PRODUCT
        WHERE id = order_product_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE e_invalid_order_product_id;
    END;

    -- Check if reason exceeds character limit
    BEGIN
        IF LENGTH(reason) > 500 THEN
            RAISE e_reason_exceeds_limit;
        END IF;
    EXCEPTION
        WHEN e_reason_exceeds_limit THEN
            DBMS_OUTPUT.PUT_LINE('Reason exceeds character limit.');
            RAISE;
    END;
    

-- Check if return is valid based on days remaining to return
    SELECT DAYS_REMAINING_TO_RETURN
    INTO l_days_remaining
    FROM NUMBER_OF_RETURNABLE_DAYS nr
    WHERE nr.ORDER_PRODUCT_ID_ = order_product_id;


    
    IF l_days_remaining > 0 THEN
        -- Proceed with return creation
        INSERT INTO return (
            id,
            reason,
            return_date,
            quantity_returned,
            store_id,
            order_product_id,
            REFUND_STATUS,
            request_accepted
        ) VALUES (
            RETURN_ID_SEQ.NEXTVAL,
            reason,
            SYSDATE,
            quantity_returned,
            store_id,
            order_product_id,
            'PROCESSING',
            1
        );
        
        -- Output debug message
        DBMS_OUTPUT.PUT_LINE(' Return created successfully.');
    ELSE
    INSERT INTO return (
            id,
            reason,
            return_date,
            quantity_returned,
            store_id,
            order_product_id,
            REFUND_STATUS,
            request_accepted
        ) VALUES (
            RETURN_ID_SEQ.NEXTVAL,
            reason,
            SYSDATE,
            quantity_returned,
            store_id,
            order_product_id,
            'REJECTED',
            0
        );
        -- Output debug message
        DBMS_OUTPUT.PUT_LINE(' Return cannot be initiated due to insufficient days remaining.');
    END IF;
    
    -- Output debug message
    DBMS_OUTPUT.PUT_LINE(' Return check completed.');
    
    -- Commit transaction
    COMMIT;
EXCEPTION
    WHEN e_invalid_reason_format THEN
        DBMS_OUTPUT.PUT_LINE('Invalid reason format.');
    WHEN e_invalid_quantity_returned_format THEN
        DBMS_OUTPUT.PUT_LINE('Invalid quantity returned format.');
    WHEN e_invalid_store_id_format THEN
        DBMS_OUTPUT.PUT_LINE('Invalid store ID format.');
    WHEN e_invalid_order_product_id_format THEN
        DBMS_OUTPUT.PUT_LINE('Invalid order product ID format.');
    WHEN e_invalid_quantity THEN
        DBMS_OUTPUT.PUT_LINE('Quantity returned cannot exceed available quantity.');
    WHEN e_invalid_order_product_id THEN
        DBMS_OUTPUT.PUT_LINE('Invalid order product ID.');
    WHEN e_invalid_store_id THEN
        DBMS_OUTPUT.PUT_LINE('Invalid store ID.');
    WHEN e_reason_exceeds_limit THEN
        DBMS_OUTPUT.PUT_LINE('Reason exceeds character limit.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Procedure execution: Error - ' || SQLERRM);
END;
/


-------------------- Allows customer to submit feedback for stores in which they returned the products ------------------

CREATE OR REPLACE PROCEDURE submit_feedback(
    p_store_phone IN VARCHAR2,
    p_customer_email IN VARCHAR2,
    p_customer_rating IN VARCHAR2,
    p_review IN VARCHAR2
) AS
  v_customer_rating NUMBER; 
  v_store_id VARCHAR2(10);
  v_customer_id VARCHAR2(10);
  v_feedback_exists NUMBER;
  v_accepted_return_exists NUMBER;
  v_store_phone NUMBER;

  -- Custom exceptions
  e_invalid_rating EXCEPTION;
  e_invalid_email_format EXCEPTION;
  e_store_name_too_long EXCEPTION;
  e_email_too_long EXCEPTION;
  e_empty_store_name EXCEPTION;
  e_rating_conversion_error EXCEPTION;
  e_PHN_conversion_error EXCEPTION;
  e_rating_empty EXCEPTION;
  e_rev_conversion_error EXCEPTION;
  e_review_format_error EXCEPTION; -- New exception for review format validation
  e_review_too_long EXCEPTION;

BEGIN
  
  BEGIN
    v_customer_rating := TO_NUMBER(p_customer_rating);
  EXCEPTION
    WHEN VALUE_ERROR THEN
      RAISE e_rating_conversion_error;
  END;
  -- Check if rating is empty or null
  IF TRIM(p_customer_rating) IS NULL OR p_customer_rating = '' THEN
    RAISE e_rating_empty;
  END IF;
 
  -- Validate the customer rating is between 1 and 5.
  IF TO_NUMBER(p_customer_rating) < 1 OR TO_NUMBER(p_customer_rating) > 5 THEN
    RAISE e_invalid_rating;
  END IF;

  BEGIN
    v_store_phone := TO_NUMBER(p_store_phone);
  EXCEPTION
    WHEN VALUE_ERROR THEN
      RAISE e_PHN_conversion_error;
  END;


  -- Validate the customer email is not empty, does not exceed expected length, and is in a valid format.
  IF LENGTH(p_customer_email) > 30 THEN -- 30 is the max length for email
    RAISE e_email_too_long;
  ELSIF NOT REGEXP_LIKE(p_customer_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
    RAISE e_invalid_email_format;
  END IF;

  -- Validate the review length.
  IF LENGTH(p_review) > 500 THEN
    RAISE e_review_too_long;
  END IF;

  -- New validation for p_review to check it is not a single integer.
  IF LENGTH(p_review) = 1 AND REGEXP_LIKE(p_review, '^\d$') THEN
    RAISE e_rev_conversion_error;
  END IF;

  -- Lookup the store_id using the store name.
  SELECT id INTO v_store_id
  FROM store
  WHERE contact_no = p_store_phone;
  -- Lookup the customer_id using the customer email address.
  SELECT id INTO v_customer_id
  FROM customer
  WHERE email_id = p_customer_email;

  -- Check for an accepted return for this store and customer.
  SELECT COUNT(*) INTO v_accepted_return_exists
  FROM accepted_returns_view arv
  JOIN order_product op ON arv.order_product_id = op.id
  JOIN customer_order o ON op.customer_order_id = o.id
  WHERE arv.store_id = v_store_id AND o.customer_id = v_customer_id;

  IF v_accepted_return_exists = 0 THEN
    DBMS_OUTPUT.PUT_LINE('No accepted returns for this store and customer.');
    RETURN;
  END IF;

  -- Check if feedback already exists for this store and customer.
  SELECT COUNT(*) INTO v_feedback_exists
  FROM feedback
  WHERE store_id = v_store_id AND customer_id = v_customer_id;

  IF v_feedback_exists = 0 THEN
    -- Insert new feedback if it does not exist.
    INSERT INTO feedback (id, customer_id, store_id, customer_rating, review)
    VALUES (FEEDBACK_ID_SEQ.NEXTVAL, v_customer_id, v_store_id, TO_NUMBER(p_customer_rating), p_review);
    DBMS_OUTPUT.PUT_LINE('Feedback updated successfully.');

  ELSE
    -- Update existing feedback.
    UPDATE feedback
    SET customer_rating = TO_NUMBER(p_customer_rating), review = p_review
    WHERE store_id = v_store_id AND customer_id = v_customer_id;
    DBMS_OUTPUT.PUT_LINE('Feedback updated successfully.');

  END IF;

  COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Store phone number or customer email address not found.');
    ROLLBACK;
  WHEN e_invalid_rating THEN
    DBMS_OUTPUT.PUT_LINE('Customer rating must be between 1 and 5.');
    ROLLBACK;
  WHEN e_invalid_email_format THEN
    DBMS_OUTPUT.PUT_LINE('Invalid customer email address format.');
    ROLLBACK;
  WHEN e_store_name_too_long THEN
    DBMS_OUTPUT.PUT_LINE('Store name exceeds the maximum length allowed.');
    ROLLBACK;
  WHEN e_email_too_long THEN
    DBMS_OUTPUT.PUT_LINE('Email exceeds the maximum length allowed.');
    ROLLBACK;
  WHEN e_empty_store_name THEN
    DBMS_OUTPUT.PUT_LINE('Store name cannot be empty.');
    ROLLBACK;
  WHEN e_review_format_error THEN
    DBMS_OUTPUT.PUT_LINE('Review cannot be a integer.');
  WHEN e_rating_conversion_error THEN
    DBMS_OUTPUT.PUT_LINE('Rating conversion error: Rating must be a numeric value.');
    ROLLBACK;
  WHEN e_PHN_conversion_error THEN
    DBMS_OUTPUT.PUT_LINE('Phone number must be a numeric value.');
    ROLLBACK;
  WHEN e_rev_conversion_error THEN
    DBMS_OUTPUT.PUT_LINE('Feedback cannot be a numeric integer.');
    ROLLBACK;
  WHEN e_rating_empty THEN
    DBMS_OUTPUT.PUT_LINE('Rating cannot be empty.');
    ROLLBACK;
  WHEN e_review_too_long THEN
    DBMS_OUTPUT.PUT_LINE('Review exceeds the maximum length allowed.');
    ROLLBACK;
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Warning Incorrect data entered check the da ');
    ROLLBACK;
    RAISE;
END;
/


----------------- Allows seller to update the availability of their respective stores ----------------

CREATE OR REPLACE PROCEDURE update_store_availability (
    store_contact_no IN VARCHAR,
    accepting_return IN VARCHAR
) AS
    s_contact_no NUMBER;
    accept_return NUMBER;
    store_contact_if_exists NUMBER;
    invalid_store_contact_exception EXCEPTION;
    invalid_accepting_return_input_exception EXCEPTION;
BEGIN
    
    -- Attempt to convert string to NUMBER
    BEGIN
        s_contact_no := TO_NUMBER(store_contact_no);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid store contact number format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- Attempt to convert string to NUMBER
    BEGIN
        accept_return := TO_NUMBER(accepting_return);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid accepting_return format. Please provide either 0(Yes) or 1(No).');
            RETURN;
    END;
    
    -- IF accept_return IS RANDOM VALUE, RAISE invalid_input_exception
    IF accept_return NOT IN (0, 1) THEN
        RAISE invalid_accepting_return_input_exception;
    END IF;
    
    -- if store_contact does not exists, raise exception   
    SELECT COUNT(1) INTO store_contact_if_exists FROM STORE WHERE CONTACT_NO = s_contact_no;
    IF store_contact_if_exists=0 THEN
        RAISE invalid_store_contact_exception;
    END IF;   
    
    -- update availability of store
    UPDATE store
    SET accepting_returns = accept_return
    WHERE contact_no = s_contact_no;

    COMMIT;
    dbms_output.put_line('Store status updated successfully.');
EXCEPTION
    WHEN invalid_accepting_return_input_exception THEN
        dbms_output.put_line('Invalid input. Please enter either 0 or 1.');
    WHEN invalid_store_contact_exception THEN
        dbms_output.put_line('Store with provided contact donnot exist. Enter valid contact.');
    WHEN dup_val_on_index THEN
        dbms_output.put_line('Primary/Unique key violation occured. Make sure to enter correct values.');
    WHEN OTHERS THEN
        dbms_output.put_line('Something else went wrong - '
                             || sqlcode
                             || ' : '
                             || sqlerrm);
END;
/

------------------ Allows seller to add products to the PRODUCT Entity after checking for category ------------
CREATE OR REPLACE PROCEDURE ADD_PRODUCT (
    name             IN product.name%TYPE,
    price            IN varchar,
    mfg_date         IN product.mfg_date%TYPE,
    exp_date         IN product.exp_date%TYPE,
    category_name    IN category.name%TYPE,
    seller_contact   IN varchar
) AS 
    a_price             NUMBER(10,2);
    s_contact_no        NUMBER;
    category_id_        NUMBER;
    category_if_exists NUMBER;
    fetched_seller_id   NUMBER;
    seller_contact_if_exists NUMBER;
    
    invalid_category_exception    EXCEPTION;
    name_length_exceeded          EXCEPTION;
    category_name_length_exceeded EXCEPTION;
    invalid_seller_contact_exception EXCEPTION;
    invalid_name_exception       EXCEPTION;
BEGIN

    -- Attempt to convert string to NUMBER
    BEGIN
        a_price := TO_NUMBER(price);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid price format. Please provide a valid numeric price.');
            RETURN;
    END;
    

    -- Check if name contains only alphabetic characters
    IF NOT REGEXP_LIKE(name, '^[a-zA-Z]+$') THEN
        RAISE invalid_name_exception;
    END IF;
    
    -- Check if name length exceeds the maximum allowed length (assuming 50 characters)
    IF LENGTH(name) > 50 THEN
        RAISE name_length_exceeded;
    END IF;

    -- Check if category_name length exceeds the maximum allowed length (assuming 50 characters)
    IF LENGTH(category_name) > 50 THEN
        RAISE category_name_length_exceeded;
    END IF;

    -- Attempt to convert string to NUMBER
    BEGIN
        s_contact_no := TO_NUMBER(seller_contact);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid contact number format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- if seller_contact does not exist, raise exception   
    SELECT COUNT(1) INTO seller_contact_if_exists FROM SELLER WHERE CONTACT_NO = s_contact_no;
    IF seller_contact_if_exists = 0 THEN
        RAISE invalid_seller_contact_exception;
    END IF;
    
    -- fetch seller_id based on seller_contact
    SELECT ID INTO fetched_seller_id FROM SELLER WHERE CONTACT_NO = s_contact_no;

    -- check if category exists   
    SELECT COUNT(1) INTO category_if_exists FROM CATEGORY WHERE UPPER(name) = UPPER(category_name);
    IF category_if_exists = 0 THEN
        RAISE invalid_category_exception;
    END IF;   
    
    -- if category exists, fetch category_id    
    SELECT id INTO category_id_ FROM category WHERE UPPER(name) = UPPER(category_name);
    
    -- insert product
    INSERT INTO product (
        id,
        name,
        price,
        mfg_date,
        exp_date,
        category_id,
        seller_id
    ) VALUES (
        PRODUCT_ID_SEQ.NEXTVAL, -- NEXT AUTOMATED PRODUCT_ID 
        name,
        a_price,
        mfg_date,
        exp_date,
        category_id_,
        fetched_seller_id
    );

    COMMIT;
EXCEPTION
    WHEN dup_val_on_index THEN
        DBMS_OUTPUT.PUT_LINE('Primary/Unique key violation occurred. Make sure to enter correct values.');
    WHEN invalid_category_exception THEN
        DBMS_OUTPUT.PUT_LINE('Category does not exist. Enter a valid category.');
    WHEN name_length_exceeded THEN
        DBMS_OUTPUT.PUT_LINE('Product name length exceeds the maximum allowed length.');
    WHEN invalid_seller_contact_exception THEN
        DBMS_OUTPUT.PUT_LINE('Invalid seller contact. Please check if the contact entered is correct.');
    WHEN category_name_length_exceeded THEN
        DBMS_OUTPUT.PUT_LINE('Category name length exceeds the maximum allowed length.');
    WHEN invalid_name_exception THEN
        DBMS_OUTPUT.PUT_LINE('Product name must contain only alphabetic characters.');
    WHEN OTHERS THEN -- catch all other exceptions
        IF sqlcode = -2291 THEN -- Handle foreign key constraint violation
            DBMS_OUTPUT.PUT_LINE('Foreign key constraint violation occurred.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Something else went wrong - ' || SQLCODE || ' : ' || SQLERRM);
        END IF;
END;
/


-- Allows store user to check for their feedback ---

CREATE OR REPLACE PROCEDURE Get_Feedback_For_Store(
    p_contact_no_str IN VARCHAR2)
AS
    v_contact_no NUMBER;
BEGIN
    -- Attempt to convert string to NUMBER for contact_no validation
    BEGIN
        v_contact_no := TO_NUMBER(p_contact_no_str);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid contact number format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- Validate the converted contact number length (assuming 10 digits for simplicity)
    IF LENGTH(TRIM(TO_CHAR(v_contact_no))) != 10 THEN
        DBMS_OUTPUT.PUT_LINE('Invalid contact number. Please provide a 10-digit contact number.');
        RETURN; -- Exit the procedure without executing the query
    END IF;

    -- Fetch and display feedback for the store matching the validated contact number
    DECLARE
        feedback_found BOOLEAN := FALSE;
    BEGIN
        FOR rec IN (SELECT f.customer_rating, f.review
                    FROM Feedback f
                    JOIN Store s ON f.store_id = s.id
                    WHERE s.contact_no = v_contact_no)
        LOOP
            feedback_found := TRUE;
            DBMS_OUTPUT.PUT_LINE('Rating: ' || rec.customer_rating || ', Review: ' || rec.review);
        END LOOP;
        
        IF NOT feedback_found THEN
            DBMS_OUTPUT.PUT_LINE('No feedback found for the specified contact number.');
        END IF;
    END;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END;
/


-- PROCEDURE WHICH ALLOWS CUSTOMER TO VIEW SUCCESSFUL RETURNS TO GIVE FEEDBACK TO STORE

CREATE OR REPLACE PROCEDURE get_returned_products (
    p_email IN VARCHAR2
) AS
BEGIN
    -- Input validation
    IF p_email IS NULL OR TRIM(p_email) = '' THEN
        DBMS_OUTPUT.PUT_LINE('Email address cannot be null or empty.');
    END IF;
    
    -- Simple format check; could be expanded for more rigorous pattern matching
    IF NOT REGEXP_LIKE(p_email, '^[a-zA-Z0-9._%-]+@[a-zA-Z0-9._%-]+\.[a-zA-Z]{2,4}$') THEN
        DBMS_OUTPUT.PUT_LINE('Email address format is not valid.');
    END IF;

    -- Updated headers to include Product ID and Store Name
    DBMS_OUTPUT.PUT_LINE('Product ID | Store Name      | Product Name |    Refund Status  | Request Accepted |');
    DBMS_OUTPUT.PUT_LINE('-----------|-----------------|--------------|-------------------|------------------|');

    FOR r IN (
        SELECT 
            p.id AS product_id, 
            s.name AS store_name,
            p.name AS product_name,
            r.refund_status AS refund_status,
            r.request_accepted AS request_accepted
            
        FROM 
            customer c
            JOIN customer_order co ON c.id = co.customer_id
            JOIN order_product op ON co.id = op.customer_order_id
            JOIN product p ON op.product_id = p.id
            JOIN "RETURN" r ON op.id = r.order_product_id
            JOIN store s ON r.store_id = s.id -- Joining store table to get store name
        WHERE 
            c.email_id = p_email
            )
    LOOP
        -- Output with store name using RPAD for alignment
        DBMS_OUTPUT.PUT_LINE(
            RPAD(r.product_id, 10) || ' | ' || 
            RPAD(r.store_name, 15) || ' | ' || 
            RPAD(r.product_name, 12) || ' | ' || 
            RPAD(r.refund_status, 10) || ' | ' || 
            RPAD(CASE WHEN r.request_accepted = 1 THEN 'SUCCESSFUL' ELSE 'REJECTED' END, 16)
        );
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No products found for the given email.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-- Procedure to view store rating of the specific store user

CREATE OR REPLACE PROCEDURE get_store_rating(p_contact_no_str IN VARCHAR2) AS
    v_contact_no NUMBER;
    v_store_name store.name%TYPE;
    v_store_rating NUMBER;
    v_address_line store.address_line%TYPE;
    v_city store.city%TYPE;
    v_state store.state%TYPE;
    v_zip_code store.zip_code%TYPE;
BEGIN
    -- Attempt to convert string to NUMBER
    BEGIN
        v_contact_no := TO_NUMBER(p_contact_no_str);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid contact number format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- Proceed with fetching the store details and rating using the converted contact number
    BEGIN
        SELECT s.name, s.address_line, s.city, s.state, s.zip_code, vsr."Store_Average_Rating" 
        INTO v_store_name, v_address_line, v_city, v_state, v_zip_code, v_store_rating
        FROM store s
        JOIN view_store_ratings_comparison vsr ON s.id = vsr."Store_ID"
        WHERE s.contact_no = v_contact_no;
        
        DBMS_OUTPUT.PUT_LINE('Store Name: ' || v_store_name || ', Address: ' || v_address_line || ', ' || 
                             v_city || ', ' || v_state || ' ' || v_zip_code || 
                             ' has a rating of: ' || v_store_rating);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No store or rating found for the given contact number.');
        WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('More than one store found for the given contact number, or data inconsistency.');
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: check input');
END;
/


-- 1. To filter accepted returns list based on specific customer email

CREATE OR REPLACE PROCEDURE filter_accepted_returns (
    email_id IN VARCHAR2
) AS
    -- Declare variables
    v_seller_name accepted_returns_view.seller_name%TYPE;
    v_product_name accepted_returns_view.product_name%TYPE;
    v_product_id accepted_returns_view.product_id%TYPE;
    v_return_reason accepted_returns_view.return_reason%TYPE;
    v_return_date accepted_returns_view.return_date%TYPE;
    v_order_product_id accepted_returns_view.order_product_id%TYPE;
    v_quantity_returned accepted_returns_view.quantity_returned%TYPE;
    v_store_id accepted_returns_view.store_id%TYPE;
    v_customer_id customer.id%TYPE;

BEGIN
    -- Get customer_id from email_id
    SELECT id INTO v_customer_id FROM customer WHERE email_id = email_id;

    -- Fetch data into variables directly
    SELECT 
        arv.seller_name,
        arv.product_name,
        arv.product_id,
        arv.return_reason,
        arv.return_date,
        arv.order_product_id,
        arv.quantity_returned,
        arv.store_id
    INTO 
        v_seller_name,
        v_product_name,
        v_product_id,
        v_return_reason,
        v_return_date,
        v_order_product_id,
        v_quantity_returned,
        v_store_id
    FROM 
        accepted_returns_view arv
    INNER JOIN 
        customer_order co ON co.id = arv.order_product_id
    INNER JOIN 
        order_product op ON co.id = op.customer_order_id
    WHERE 
        co.customer_id = v_customer_id;

    -- Display the fetched data
    DBMS_OUTPUT.PUT_LINE('Seller Name: ' || v_seller_name);
    DBMS_OUTPUT.PUT_LINE('Product Name: ' || v_product_name);
    DBMS_OUTPUT.PUT_LINE('Product ID: ' || v_product_id);
    DBMS_OUTPUT.PUT_LINE('Return Reason: ' || v_return_reason);
    DBMS_OUTPUT.PUT_LINE('Return Date: ' || TO_CHAR(v_return_date, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('Order Product ID: ' || v_order_product_id);
    DBMS_OUTPUT.PUT_LINE('Quantity Returned: ' || v_quantity_returned);
    DBMS_OUTPUT.PUT_LINE('Store ID: ' || v_store_id);
    DBMS_OUTPUT.PUT_LINE('----------------------');

    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No accepted returns found for the specified customer.');
    WHEN OTHERS THEN
        -- Handle exceptions
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/


-- 2. Filtered stores for feedback based on customer email

CREATE OR REPLACE PROCEDURE filter_store_for_feedback (
    email_id IN VARCHAR2
) AS
    -- Declare variables
    v_store_id store_for_feedback.store_id%TYPE;
    v_product_name store_for_feedback.product_name%TYPE;
    v_customer_order_id store_for_feedback.customer_order_id%TYPE;
    v_customer_id customer.id%TYPE;

BEGIN
    -- Get customer_id from email_id
    SELECT id INTO v_customer_id FROM customer WHERE email_id = email_id;

    -- Fetch data into variables directly
    SELECT 
        sff.store_id,
        sff.product_name,
        sff.customer_order_id
    INTO 
        v_store_id,
        v_product_name,
        v_customer_order_id
    FROM 
        store_for_feedback sff
    INNER JOIN 
        customer_order co ON sff.customer_order_id = co.id
    WHERE 
        co.customer_id = v_customer_id;

    -- Display the fetched data
    DBMS_OUTPUT.PUT_LINE('Store ID: ' || v_store_id);
    DBMS_OUTPUT.PUT_LINE('Product Name: ' || v_product_name);
    DBMS_OUTPUT.PUT_LINE('Customer Order ID: ' || v_customer_order_id);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No records found for the specified customer.');
    WHEN OTHERS THEN
        -- Handle exceptions
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- procedure for seller to view the return requests that are pending approval
CREATE OR REPLACE PROCEDURE get_system_approved_returns(seller_contact_no IN VARCHAR2) AS
    s_contact_no NUMBER;
    s_return_id return.id%TYPE;
    s_product_name product.name%TYPE;
    s_reason return.reason%TYPE;
    s_return_date return.return_date%TYPE;
    s_quantity_returned return.quantity_returned%TYPE;
    seller_contact_if_exists NUMBER;
    invalid_seller_contact_exception EXCEPTION;
BEGIN
    -- Attempt to convert string to NUMBER
    BEGIN
        s_contact_no := TO_NUMBER(seller_contact_no);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid contact number format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- if return_id does not exists, raise exception   
    SELECT COUNT(1)INTO seller_contact_if_exists FROM SELLER WHERE CONTACT_NO = s_contact_no;
    IF seller_contact_if_exists = 0 THEN
        RAISE invalid_seller_contact_exception;
    END IF;
    
    -- Proceed with fetching the return details that needs to be approved/rejected
    BEGIN
        SELECT car.RETURN_ID, car.PRODUCT_NAME, car.REASON, car.RETURN_DATE, car.QUANTITY_RETURNED 
        INTO s_return_id, s_product_name, s_reason, s_return_date, s_quantity_returned
        FROM CHECK_APPROVED_RETURNS_BY_SYSTEM car
        WHERE car.SELLER_CONTACT = s_contact_no;
        
        DBMS_OUTPUT.PUT_LINE('RETURN ID    | PRODUCT NAME        | REASON                    | RETURN_DATE    | QUANTITY RETURNED |');
        DBMS_OUTPUT.PUT_LINE('-------------|---------------------|---------------------------|----------------|-------------------|');
    
        FOR r IN (
                SELECT car.RETURN_ID, car.PRODUCT_NAME, car.REASON, car.RETURN_DATE, car.QUANTITY_RETURNED 
                FROM CHECK_APPROVED_RETURNS_BY_SYSTEM car
                WHERE car.SELLER_CONTACT = s_contact_no
                )
        LOOP
            -- Output with return request details using RPAD for alignment
            DBMS_OUTPUT.PUT_LINE(
                RPAD(r.RETURN_ID, 12) || ' | ' || 
                RPAD(r.PRODUCT_NAME, 19) || ' | '||
                RPAD(r.REASON, 25) || ' | '||
                RPAD(r.RETURN_DATE, 14) || ' | '||
                RPAD(r.QUANTITY_RETURNED, 17) || ' | ');
        END LOOP;
    EXCEPTION
        WHEN invalid_seller_contact_exception THEN
            dbms_output.put_line('Invalid seller contact. Please check if contact entered is correct.');
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No returns requests are available to be approved.');
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: check input');
END;
/

-- prcedure for seller to view which products are return with their frequencies
CREATE OR REPLACE PROCEDURE GET_RETURNED_PRODUCT_ANALYSIS(seller_contact_no IN VARCHAR2) AS
    s_contact_no NUMBER;
    seller_contact_if_exists NUMBER;
    invalid_seller_contact_exception EXCEPTION;
BEGIN
    -- Attempt to convert string to NUMBER
    BEGIN
        s_contact_no := TO_NUMBER(seller_contact_no);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid contact number format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- if seller_contact_if_exists does not exists, raise exception   
    SELECT COUNT(1)INTO seller_contact_if_exists FROM SELLER WHERE CONTACT_NO = s_contact_no;
    IF seller_contact_if_exists=0 THEN
        RAISE invalid_seller_contact_exception;
    END IF;
    
    -- Proceed with fetching the return details that needs to be approved/rejected
    BEGIN        
        DBMS_OUTPUT.PUT_LINE('PRODUCT NAME | RETURN FREQUENCY    | REASON            |');
        DBMS_OUTPUT.PUT_LINE('-------------|---------------------|-------------------|');
    
        FOR r IN (
                SELECT rpd.PRODUCT_NAME, rpd.RETURN_FREQUENCY, rpd.REASON
                FROM RETURNED_PRODUCTS_DETAILS rpd
                )
        LOOP
            -- Output with product name using RPAD for alignment
            DBMS_OUTPUT.PUT_LINE(
                RPAD(r.PRODUCT_NAME, 12) || ' | ' || 
                RPAD(r.RETURN_FREQUENCY, 19) || ' | '||
                RPAD(r.REASON, 17) || ' | ');
        END LOOP;
    EXCEPTION
        WHEN invalid_seller_contact_exception THEN
            dbms_output.put_line('Invalid seller contact. Please check if contact entered is correct.');
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No store or rating found for the given contact number.');
        WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('More than one store found for the given contact number, or data inconsistency.');
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: check input');
END;
/

-- view for seller to check categories available in system
CREATE OR REPLACE PROCEDURE VIEW_CATEGORIES_AVAILABLE(seller_contact_no IN VARCHAR2) AS
    s_contact_no NUMBER;
    seller_contact_if_exists NUMBER;
    invalid_seller_contact_exception EXCEPTION;
BEGIN
    -- Attempt to convert string to NUMBER
    BEGIN
        s_contact_no := TO_NUMBER(seller_contact_no);
    EXCEPTION
        WHEN VALUE_ERROR THEN
            DBMS_OUTPUT.PUT_LINE('Invalid contact number format. Please provide a valid numeric contact number.');
            RETURN;
    END;
    
    -- if return_id does not exists, raise exception   
    SELECT COUNT(1)INTO seller_contact_if_exists FROM SELLER WHERE CONTACT_NO = s_contact_no;
    IF seller_contact_if_exists=0 THEN
        RAISE invalid_seller_contact_exception;
    END IF;
    
    -- Proceed with category view
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Category ID | Category Name    |');
        DBMS_OUTPUT.PUT_LINE('------------|------------------|');
    
        -- iterating over the records in view       
        FOR r IN (
                SELECT cv.id as category_id, cv.name as category_name
                FROM category_view cv
                )
        LOOP
            -- Output with category details using RPAD for alignment
            DBMS_OUTPUT.PUT_LINE(
                RPAD(r.category_id, 11) || ' | ' || 
                RPAD(r.category_name, 16) || ' | ');
        END LOOP;
        
    EXCEPTION
        WHEN invalid_seller_contact_exception THEN
            dbms_output.put_line('Invalid seller contact. Please check if contact entered is correct.');
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No store or rating found for the given contact number.');
        WHEN TOO_MANY_ROWS THEN
            DBMS_OUTPUT.PUT_LINE('More than one seller found for the given contact number, or data inconsistency.');
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error occurred: check input');
END;
/

-- CUSTOMER_USER
GRANT EXECUTE ON BUSINESS_MANAGER.CREATE_RETURN TO CUSTOMER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.SUBMIT_FEEDBACK TO CUSTOMER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.filter_accepted_returns TO CUSTOMER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.filter_store_for_feedback TO CUSTOMER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.get_returned_products TO CUSTOMER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.show_returns_request TO CUSTOMER_USER;



-- STORE_USER
GRANT EXECUTE ON BUSINESS_MANAGER.UPDATE_STORE_AVAILABILITY TO STORE_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.Get_Feedback_For_Store TO STORE_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.get_store_rating TO STORE_USER;

-- SELLER_USER
GRANT EXECUTE ON BUSINESS_MANAGER.ADD_PRODUCT TO SELLER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.UPDATE_SELLER_REFUND TO SELLER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.GET_SYSTEM_APPROVED_RETURNS TO SELLER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.GET_RETURNED_PRODUCT_ANALYSIS TO SELLER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.VIEW_CATEGORIES_AVAILABLE TO SELLER_USER;

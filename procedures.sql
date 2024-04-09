-------------------------------- STORED PROCEDURES --------------------------------------------------

--------------------- UPDATE_SELLER_REFUND procedure
CREATE OR REPLACE PROCEDURE UPDATE_SELLER_REFUND (
    return_id_if_exists OUT NUMBER,
    seller_contact_if_exists OUT NUMBER,
    seller_return_combination_if_exists OUT NUMBER,
    return_id         IN return.id%TYPE,
    accept_yes_no IN VARCHAR,
    seller_contact IN seller.contact_no%TYPE  
) AS
    invalid_input_exception EXCEPTION;
    invalid_contact_exception EXCEPTION;
    invalid_return_id_exception EXCEPTION;
    invalid_seller_return_combination_exception EXCEPTION;
    
    CUSTOMER_RI NUMBER(1);
    PRICE_CHARGED NUMBER(10,2);
BEGIN
    
    -- IF accept_yes_no IS RANDOM VALUE, RAISE invalid_input_exception
    IF UPPER(accept_yes_no) NOT IN ('YES', 'NO') THEN
        RAISE invalid_input_exception;
    END IF;
    dbms_output.put_line(1);
    
    -- if return_id does not exists, raise exception   
    SELECT COUNT(1)INTO return_id_if_exists FROM RETURN WHERE ID=return_id;
    IF return_id_if_exists=0 THEN
        RAISE invalid_return_id_exception;
    END IF;
    dbms_output.put_line(2);
    
    -- if seller_contact does not exists, raise exception   
    SELECT COUNT(1)INTO seller_contact_if_exists FROM SELLER WHERE CONTACT_NO = seller_contact;
    IF seller_contact_if_exists=0 THEN
        RAISE invalid_contact_exception;
    END IF;  
    dbms_output.put_line(3);
    
    -- if seller_return_id does not exists, raise exception   
    SELECT COUNT(1) INTO seller_return_combination_if_exists FROM CHECK_APPROVED_RETURNS_BY_SYSTEM WHERE RETURN_ID=return_id AND SELLER_CONTACT=seller_contact;
    IF seller_return_combination_if_exists=0 THEN
        RAISE invalid_seller_return_combination_exception;
    END IF;    
    dbms_output.put_line(4);
    
    -- UPDATE REFUND_STATUS BASED ON IF SELLER ACCEPTS/REJECTS THE RETURN
    UPDATE RETURN
    SET REFUND_STATUS = 
        CASE 
            WHEN UPPER(accept_yes_no) = 'YES' THEN 'COMPLETED'
            WHEN UPPER(accept_yes_no) = 'NO' THEN 'REJECTED'
        END
    WHERE
        id = return_id;
        
    -- UPDATE PROCESSING FEE BASED ON CUSTOMER_RI
    IF UPPER(accept_yes_no) = 'YES' THEN
        -- FETCHING CUSTOMER_RI OF CUSTOMER BASED ON RETURN_ID
        SELECT CRI.Reliability_Index INTO CUSTOMER_RI
        FROM Customer_Reliability_Index CRI
        JOIN CUSTOMER C ON C.ID = CRI.CUSTOMER_ID
        JOIN CUSTOMER_ORDER CO ON CO.CUSTOMER_ID = C.ID
        JOIN ORDER_PRODUCT OP ON OP.CUSTOMER_ORDER_ID = CO.ID
        JOIN RETURN R ON OP.ID = R.ORDER_PRODUCT_ID
        WHERE R.ID = return_id;
        
        -- FETCHING PRICE_CHARGED FOR ORDER_PRODUCT ASSOCIATED WITH THE RETURN
        SELECT NVL(RAV.PRICE - (RAV.PRICE * RAV.DISCOUNT_RATE/100), RAV.PRICE) INTO PRICE_CHARGED
        FROM REFUND_AMOUNT_VIEW RAV
        JOIN RETURN R ON R.ORDER_PRODUCT_ID = RAV.ID
        WHERE R.ID = return_id;
        
        -- UPDATE PROCESSING_FEE BASED ON CUSTOMER_RI AND PRICE_CHARGED
        UPDATE RETURN
        SET PROCESSING_FEE = (5-CUSTOMER_RI)*(0.01 * PRICE_CHARGED) -- 1% OF PRICE CHARGED IS CALCULATED AS PROCESSING FEE AND MULTIPLED WITH INVERSE OF CUSTOMER_RI
        WHERE id = return_id;
    ELSE
        UPDATE RETURN
        SET PROCESSING_FEE = 0 -- IF SELLER REJECTS THE RETURN, PROCESSING FEE IS SET TO ZERO
        WHERE id = return_id;
    END IF;
        
    COMMIT;
    dbms_output.put_line('Seller refund updated successfully.');
EXCEPTION
    WHEN dup_val_on_index THEN
        dbms_output.put_line('Primary/Unique key violation occured. Make sure to enter correct values.');
    WHEN invalid_input_exception THEN
        dbms_output.put_line('Invalid input. Please enter either YES or NO.');
    WHEN invalid_return_id_exception THEN
        dbms_output.put_line('Invalid return id. Please check if return_id entered is correct.');
    WHEN invalid_contact_exception THEN
        dbms_output.put_line('Invalid seller contact no. Please check if seller contact_no entered is correct.');
    WHEN OTHERS THEN
        dbms_output.put_line('Something else went wrong - '
                             || sqlcode
                             || ' : '
                             || sqlerrm);
END;
/

------------------------ create_return procedure
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
    
    
    -- Check if return is valid based on days remaining to return
    SELECT COUNT(*)
    INTO l_days_remaining
    FROM NUMBER_OF_RETURNABLE_DAYS
    WHERE ORDER_ID = (
        SELECT customer_order_id
        FROM ORDER_PRODUCT
        WHERE id = order_product_id
    );
    
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
    DBMS_OUTPUT.PUT_LINE(' Completed.');
    
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
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Procedure execution: Error - ' || SQLERRM);
END;
/


-------------------- submit_feedback procedure
CREATE OR REPLACE PROCEDURE submit_feedback(
    p_store_name IN VARCHAR2,
    p_customer_email IN VARCHAR2,
    p_customer_rating IN NUMBER,
    p_review IN VARCHAR2
) AS
  v_store_id VARCHAR2(10);
  v_customer_id VARCHAR2(10);
  v_feedback_exists NUMBER;
  v_accepted_return_exists NUMBER;

  -- Custom exceptions
  e_invalid_rating EXCEPTION;
  e_invalid_email_format EXCEPTION;
  e_store_name_too_long EXCEPTION;
  e_email_too_long EXCEPTION;
  e_empty_store_name EXCEPTION;
  e_review_format_error EXCEPTION; -- New exception for review format validation

BEGIN
  -- Validate the customer rating is between 1 and 5.
  IF p_customer_rating < 1 OR p_customer_rating > 5 THEN
    RAISE e_invalid_rating;
  END IF;

  -- Validate the store name is not empty and does not exceed expected length.
  IF TRIM(p_store_name) IS NULL THEN
    RAISE e_empty_store_name;
  ELSIF LENGTH(p_store_name) > 20 THEN -- 20 is the max length
    RAISE e_store_name_too_long;
  END IF;

  -- Validate the customer email is not empty, does not exceed expected length, and is in a valid format.
  IF LENGTH(p_customer_email) > 30 THEN -- 30 is the max length for email
    RAISE e_email_too_long;
  ELSIF NOT REGEXP_LIKE(p_customer_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
    RAISE e_invalid_email_format;
  END IF;

  -- New validation for p_review to check it is not a single integer.
  IF LENGTH(p_review) = 1 AND REGEXP_LIKE(p_review, '^\d$') THEN
    RAISE e_review_format_error;
  END IF;

  -- Lookup the store_id using the store name.
  SELECT id INTO v_store_id
  FROM store
  WHERE name = p_store_name;

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
    VALUES (feedback_id_seq.NEXTVAL, v_customer_id, v_store_id, p_customer_rating, p_review);
  ELSE
    -- Update existing feedback.
    UPDATE feedback
    SET customer_rating = p_customer_rating, review = p_review
    WHERE store_id = v_store_id AND customer_id = v_customer_id;
  END IF;

  COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Store name or customer email address not found.');
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
    ROLLBACK;
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/




----------------- update_store_availability procedure
CREATE OR REPLACE PROCEDURE update_store_availability (
    store_id         IN store.id%TYPE,
    accepting_return IN store.accepting_returns%TYPE
) AS
BEGIN
    UPDATE store
    SET
        accepting_returns = accepting_return
    WHERE
        id = store_id;

    COMMIT;
    dbms_output.put_line('Store status updated successfully.');
EXCEPTION
    WHEN dup_val_on_index THEN
        dbms_output.put_line('Primary/Unique key violation occured. Make sure to enter correct values.');
    WHEN OTHERS THEN
        dbms_output.put_line('Something else went wrong - '
                             || sqlcode
                             || ' : '
                             || sqlerrm);
END;
/

------------------ ADD_PRODUCT procedure
CREATE OR REPLACE PROCEDURE ADD_PRODUCT (
    category_id_ OUT product.category_id%TYPE,
    category_if_exists OUT NUMBER,
    name      IN product.name%TYPE,
    price         IN product.price%TYPE,
    mfg_date  IN product.mfg_date%TYPE,
    exp_date           IN product.exp_date%TYPE,
    category_name IN category.name%TYPE,
    seller_id IN product.seller_id%TYPE
) AS 
    invalid_category_exception EXCEPTION;
BEGIN
    -- check if category exists   
    SELECT COUNT(1)INTO category_if_exists FROM CATEGORY WHERE name=category_name;
    IF category_if_exists=0 THEN
        RAISE invalid_category_exception;
    END IF;   
    
    -- if category exists, fetch category_id    
    SELECT id into category_id_ from category where name=category_name;

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
        price,
        mfg_date,
        exp_date,
        category_id_,
        seller_id
    );

    COMMIT;
EXCEPTION
    WHEN dup_val_on_index THEN
        dbms_output.put_line('Primary/Unique key violation occured. Make sure to enter correct values.');
    WHEN invalid_category_exception THEN
        dbms_output.put_line('Category does not exist. Enter valid category');
    WHEN OTHERS THEN -- catch all other exceptions
        IF sqlcode = -2291 THEN -- Handle foreign key constraint violation
            dbms_output.put_line('Foreign key constraint violation occurred.');
        ELSE
            dbms_output.put_line('Something else went wrong - '
                                 || sqlcode
                                 || ' : '
                                 || sqlerrm);
        END IF;
END;
/

-- Get_Feedback_For_Store FUNCTION
CREATE OR REPLACE PROCEDURE Get_Feedback_For_Store(
    p_store_name IN VARCHAR2)
AS
BEGIN
    FOR rec IN (SELECT f.customer_rating, f.review
                FROM Feedback f
                JOIN Store s ON f.store_id = s.id
                WHERE s.name = p_store_name)
    LOOP
        DBMS_OUTPUT.PUT_LINE('Rating: ' || rec.customer_rating || ', Review: ' || rec.review);
    END LOOP;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No feedback found for the specified store.');
    WHEN OTHERS THEN
        RAISE;
END;
/

-- CUSTOMER_USER
GRANT EXECUTE ON BUSINESS_MANAGER.CREATE_RETURN TO CUSTOMER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.SUBMIT_FEEDBACK TO CUSTOMER_USER;

-- STORE_USER
GRANT EXECUTE ON BUSINESS_MANAGER.UPDATE_STORE_AVAILABILITY TO STORE_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.Get_Feedback_For_Store TO STORE_USER;

-- SELLER_USER
GRANT EXECUTE ON BUSINESS_MANAGER.ADD_PRODUCT TO SELLER_USER;
GRANT EXECUTE ON BUSINESS_MANAGER.UPDATE_SELLER_REFUND TO SELLER_USER;
-------------------------------- STORED PROCEDURES --------------------------------------------------

--------------------- UPDATE_SELLER_REFUND procedure
CREATE OR REPLACE PROCEDURE UPDATE_SELLER_REFUND (
    return_id         IN return.id%TYPE,
    accept_yes_no IN VARCHAR
) AS
    invalid_input_exception EXCEPTION;
    CUSTOMER_RI NUMBER(1);
    PRICE_CHARGED NUMBER(10,2);
BEGIN
    -- IF accept_yes_no IS RANDOM VALUE, RAISE invalid_input_exception
    IF UPPER(accept_yes_no) NOT IN ('YES', 'NO') THEN
        RAISE invalid_input_exception;
    END IF;
    
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
    WHEN OTHERS THEN
        dbms_output.put_line('Something else went wrong - '
                             || sqlcode
                             || ' : '
                             || sqlerrm);
END;
/

------------------------ create_return procedure
CREATE OR REPLACE PROCEDURE create_return (
    reason            IN return.reason%TYPE,
    quantity_returned IN return.quantity_returned%TYPE,
    store_id          IN return.store_id%TYPE,
    order_product_id  IN return.order_product_id%TYPE
) AS
    l_days_remaining NUMBER;
BEGIN
    -- Output debug message
    DBMS_OUTPUT.PUT_LINE('Procedure execution: Initiating return creation.');
    
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
        DBMS_OUTPUT.PUT_LINE('Procedure execution: Return created successfully.');
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
        DBMS_OUTPUT.PUT_LINE('Procedure execution: Return cannot be initiated due to insufficient days remaining.');
    END IF;
    
    -- Output debug message
    DBMS_OUTPUT.PUT_LINE('Procedure execution: Completed.');
    
    -- Commit transaction
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Output error message
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

  -- Define a custom exception for an invalid rating.
  e_invalid_rating EXCEPTION;
BEGIN
  -- Validate the customer rating is between 1 and 5.
  IF p_customer_rating < 1 OR p_customer_rating > 5 THEN
    RAISE e_invalid_rating;
  END IF;

  -- Validate the store name is not empty.
  IF TRIM(p_store_name) IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('Store name cannot be empty.');
    RETURN;
  END IF;

  -- Validate the customer email is not empty and is in a valid format.
  IF NOT REGEXP_LIKE(p_customer_email, '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$') THEN
    DBMS_OUTPUT.PUT_LINE('Invalid customer email address format.');
    RETURN;
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
    VALUES (FEEDBACK_ID_SEQ.NEXTVAL, v_customer_id, v_store_id, p_customer_rating, p_review);
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
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;x
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
    name      IN product.name%TYPE,
    price         IN product.price%TYPE,
    mfg_date  IN product.mfg_date%TYPE,
    exp_date           IN product.exp_date%TYPE,
    category_name IN category.name%TYPE,
    seller_id IN product.seller_id%TYPE
) AS 
BEGIN
    SELECT id into category_id_ from category where name=category_name;

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

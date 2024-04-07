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
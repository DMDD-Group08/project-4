SET SERVEROUTPUT ON;

-- view return requests to be approved/rejected
-- params: seller_contact_no
EXEC BUSINESS_MANAGER.GET_SYSTEM_APPROVED_RETURNS(8006927753);

-- Seller updates the status of the refund
--params: return_id, accept_yes_no, seller_contact
exec BUSINESS_MANAGER.UPDATE_SELLER_REFUND('9009', 'YES', 8006927753);



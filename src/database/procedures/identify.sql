CREATE OR REPLACE FUNCTION identify_contact(
    input_email VARCHAR(255) DEFAULT NULL,
    input_phone VARCHAR(20) DEFAULT NULL
) RETURNS JSON AS $$

DECLARE
    contact_cursor CURSOR FOR
        SELECT id, phone_number, email, linked_id, link_precedence, created_at
        FROM contacts 
        WHERE (email = input_email OR phone_number = input_phone)
        AND deleted_at IS NULL
        ORDER BY created_at ASC;

 
    v_count INTEGER := 0;
    v_primary_index INTEGER;
    v_oldest_created_date TIMESTAMP;
    
    v_id INTEGER;
    v_phone VARCHAR(20);
    v_email VARCHAR(255);
    v_linked_id INTEGER;
    v_link_precedence VARCHAR(20);
    v_created_at TIMESTAMP;
    
    
    v_emails TEXT := '[';
    v_phones TEXT := '[';
    v_secondary_ids TEXT := '[';
    v_result JSON;
    v_first BOOLEAN;
    v_exact_match BOOLEAN := FALSE;
    
    rec RECORD;

BEGIN

    OPEN contact_cursor;
    FETCH contact_cursor INTO v_id, v_phone, v_email, v_linked_id, v_link_precedence, v_created_at;
    
    IF NOT FOUND THEN
        CLOSE contact_cursor;
        
        INSERT INTO contacts (phone_number, email, link_precedence, created_at, updated_at)
        VALUES (input_phone, input_email, 'primary', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING id INTO v_primary_index;
        
    ELSE
        v_count := 0;
        v_oldest_created_date := NULL;
        v_primary_index := NULL;
        
        LOOP
            IF v_link_precedence = 'primary' THEN
                v_count := v_count + 1;

                IF v_oldest_created_date IS NULL OR v_created_at < v_oldest_created_date THEN
                    v_oldest_created_date := v_created_at;
                    v_primary_index := v_id;
                END IF;
            END IF;
            

            IF ((v_email = input_email) OR (v_email IS NULL AND input_email IS NULL))
            AND ((v_phone = input_phone) OR (v_phone IS NULL AND input_phone IS NULL)) THEN
                v_exact_match := TRUE;
            END IF;
            
            FETCH contact_cursor INTO v_id, v_phone, v_email, v_linked_id, v_link_precedence, v_created_at;
            EXIT WHEN NOT FOUND;
        END LOOP;
        
        CLOSE contact_cursor;
        
        -- Step 3: If count > 1, run loop again to convert primaries to secondary
        IF v_count > 1 THEN
            OPEN contact_cursor;
            LOOP
                FETCH contact_cursor INTO v_id, v_phone, v_email, v_linked_id, v_link_precedence, v_created_at;
                EXIT WHEN NOT FOUND;
                
                -- If primary and not the oldest, make it secondary
                IF v_link_precedence = 'primary' AND v_created_at != v_oldest_created_date THEN
                    UPDATE contacts 
                    SET link_precedence = 'secondary', 
                        linked_id = v_primary_index,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = v_id;
                END IF;
            END LOOP;
            CLOSE contact_cursor;
        END IF;
        

        IF NOT v_exact_match AND v_primary_index IS NOT NULL THEN
            INSERT INTO contacts (phone_number, email, linked_id, link_precedence, created_at, updated_at)
            VALUES (input_phone, input_email, v_primary_index, 'secondary', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        END IF;
    END IF;


    v_first := TRUE;
    FOR rec IN (
        SELECT DISTINCT email
        FROM contacts 
        WHERE (id = v_primary_index OR linked_id = v_primary_index)
        AND email IS NOT NULL
        AND deleted_at IS NULL
        ORDER BY email
    ) LOOP
        IF NOT v_first THEN
            v_emails := v_emails || ',';
        END IF;
        v_emails := v_emails || '"' || rec.email || '"';
        v_first := FALSE;
    END LOOP;
    v_emails := v_emails || ']';


    v_first := TRUE;
    FOR rec IN (
        SELECT DISTINCT phone_number
        FROM contacts 
        WHERE (id = v_primary_index OR linked_id = v_primary_index)
        AND phone_number IS NOT NULL
        AND deleted_at IS NULL
        ORDER BY phone_number
    ) LOOP
        IF NOT v_first THEN
            v_phones := v_phones || ',';
        END IF;
        v_phones := v_phones || '"' || rec.phone_number || '"';
        v_first := FALSE;
    END LOOP;
    v_phones := v_phones || ']';


    v_first := TRUE;
    FOR rec IN (
        SELECT id
        FROM contacts 
        WHERE linked_id = v_primary_index
        AND deleted_at IS NULL
        ORDER BY created_at
    ) LOOP
        IF NOT v_first THEN
            v_secondary_ids := v_secondary_ids || ',';
        END IF;
        v_secondary_ids := v_secondary_ids || rec.id;
        v_first := FALSE;
    END LOOP;
    v_secondary_ids := v_secondary_ids || ']';

    SELECT json_build_object(
        'contact', json_build_object(
            'primaryContactId', v_primary_index,
            'emails', v_emails::json,
            'phoneNumbers', v_phones::json,
            'secondaryContactIds', v_secondary_ids::json
        )
    ) INTO v_result;

    RETURN v_result;

END;
$$ LANGUAGE plpgsql;

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
    
    v_id INTEGER;
    v_phone VARCHAR(20);
    v_email VARCHAR(255);
    v_linked_id INTEGER;
    v_link_precedence VARCHAR(20);
    v_created_at TIMESTAMP;
    
    v_primary_id INTEGER;
    v_oldest_primary_date TIMESTAMP;
    v_exact_match BOOLEAN := FALSE;
    v_primary_ids INTEGER[] := '{}';
    v_contact_exists BOOLEAN := FALSE;
    
    v_emails JSON;
    v_phones JSON;
    v_secondary_ids JSON;
    v_result JSON;

BEGIN
    IF input_email IS NULL AND input_phone IS NULL THEN
        RAISE EXCEPTION 'Either email or phoneNumber must be provided';
    END IF;

    OPEN contact_cursor;
    LOOP
        FETCH contact_cursor INTO v_id, v_phone, v_email, v_linked_id, v_link_precedence, v_created_at;
        EXIT WHEN NOT FOUND;
        
        v_contact_exists := TRUE;
        
        IF v_link_precedence = 'primary' THEN
            v_primary_id := v_id;
        ELSE
            v_primary_id := v_linked_id;
        END IF;
        
        IF NOT (v_primary_id = ANY(v_primary_ids)) THEN
            v_primary_ids := array_append(v_primary_ids, v_primary_id);
        END IF;
        
        IF (COALESCE(v_email, '') = COALESCE(input_email, ''))
        AND (COALESCE(v_phone, '') = COALESCE(input_phone, '')) THEN
            v_exact_match := TRUE;
        END IF;
    END LOOP;
    CLOSE contact_cursor;
    
    IF NOT v_contact_exists THEN
        INSERT INTO contacts (phone_number, email, link_precedence, created_at, updated_at)
        VALUES (input_phone, input_email, 'primary', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        RETURNING id INTO v_primary_id;
        
    ELSIF array_length(v_primary_ids, 1) = 1 THEN
        v_primary_id := v_primary_ids[1];
        
        IF NOT v_exact_match THEN
            PERFORM 1 FROM contacts 
            WHERE (id = v_primary_id OR linked_id = v_primary_id)
            AND ((email = input_email AND phone_number = input_phone))
            AND deleted_at IS NULL;
            
            IF NOT FOUND THEN
                INSERT INTO contacts (phone_number, email, linked_id, link_precedence, created_at, updated_at)
                VALUES (input_phone, input_email, v_primary_id, 'secondary', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
            END IF;
        END IF;
        
    ELSE

        SELECT id INTO v_primary_id
        FROM contacts 
        WHERE id = ANY(v_primary_ids) AND link_precedence = 'primary'
        ORDER BY created_at ASC 
        LIMIT 1;
        

        UPDATE contacts 
        SET link_precedence = 'secondary', 
            linked_id = v_primary_id,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = ANY(v_primary_ids) AND id != v_primary_id AND link_precedence = 'primary';
        

        UPDATE contacts 
        SET linked_id = v_primary_id,
            updated_at = CURRENT_TIMESTAMP
        WHERE linked_id = ANY(v_primary_ids) AND linked_id != v_primary_id;
        
        IF NOT v_exact_match THEN
            PERFORM 1 FROM contacts 
            WHERE (id = v_primary_id OR linked_id = v_primary_id)
            AND ((email = input_email AND phone_number = input_phone))
            AND deleted_at IS NULL;
            
            IF NOT FOUND THEN
                INSERT INTO contacts (phone_number, email, linked_id, link_precedence, created_at, updated_at)
                VALUES (input_phone, input_email, v_primary_id, 'secondary', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
            END IF;
        END IF;
    END IF;
    

    SELECT COALESCE(json_agg(DISTINCT email ORDER BY email), '[]'::json) INTO v_emails
    FROM contacts 
    WHERE (id = v_primary_id OR linked_id = v_primary_id)
    AND email IS NOT NULL
    AND deleted_at IS NULL;

    SELECT COALESCE(json_agg(DISTINCT phone_number ORDER BY phone_number), '[]'::json) INTO v_phones
    FROM contacts 
    WHERE (id = v_primary_id OR linked_id = v_primary_id)
    AND phone_number IS NOT NULL
    AND deleted_at IS NULL;
    

    SELECT COALESCE(json_agg(id ORDER BY created_at), '[]'::json) INTO v_secondary_ids
    FROM contacts 
    WHERE linked_id = v_primary_id
    AND deleted_at IS NULL;
    

    SELECT json_build_object(
        'contact', json_build_object(
            'primaryContactId', v_primary_id,
            'emails', v_emails,
            'phoneNumbers', v_phones,
            'secondaryContactIds', v_secondary_ids
        )
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Errors';
END;
$$ LANGUAGE plpgsql;

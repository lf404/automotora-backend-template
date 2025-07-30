-- ====================================================================
-- Script 03: Creación del Cliente OAuth2 para el Frontend
-- ====================================================================
DECLARE
    v_client_name VARCHAR2(255) := 'automotora_frontend_client';
BEGIN
    OAUTH.CREATE_CLIENT(
        p_name          => v_client_name,
        p_grant_type    => 'client_credentials',
        p_owner         => 'AUTOMOTORA_ADMIN',
        p_description   => 'Cliente para el portal web de Laravel',
        p_support_email => 'admin@ejemplo.com'
    );
    
    OAUTH.GRANT_CLIENT_ROLE(
        p_client_name => v_client_name,
        p_role_name   => 'escritura_api'
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cliente OAuth2 "' || v_client_name || '" creado y rol asignado.');
END;
/

-- Consulta para obtener las credenciales. Ejecutar por separado.
PROMPT ================================================================================
PROMPT ¡¡IMPORTANTE!! Ejecuta la siguiente consulta por separado para obtener tus credenciales:
PROMPT SELECT name, client_id, client_secret FROM USER_ORDS_CLIENTS WHERE name = 'automotora_frontend_client';
PROMPT ================================================================================
```4.  **Guarda y sube este script a tu repositorio** de fábrica de la misma forma que hiciste con el `git push`.
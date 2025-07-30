-- =============================================================================
-- Script 02: Creación de los Mólogos y Endpoints de la API
-- Versión: 2.2 (Idempotente, con nombres de tipo de origen explícitos)
--
-- Descripción: Define todos los módulos, templates y handlers para la API.
--              Es "idempotente", lo que significa que se puede ejecutar de forma 
--              segura varias veces. Borrará la configuración de los módulos
--              viejos antes de crear la nueva.
--
-- ATENCIÓN: Este script asume que el esquema ya ha sido habilitado para ORDS
--            (a través de la interfaz gráfica o con un script separado).
-- =============================================================================

SET SERVEROUTPUT ON;

-- == BLOQUE DE LIMPIEZA: BORRA LA CONFIGURACIÓN VIEJA ANTES DE CREAR LA NUEVA ==
-- Esto asegura que el script se pueda volver a ejecutar sin errores de "nombre duplicado".
BEGIN
    ORDS.DELETE_MODULE(p_module_name => 'v1_public');
    DBMS_OUTPUT.PUT_LINE('Módulo v1_public eliminado (si existía).');
EXCEPTION
    WHEN OTHERS THEN -- Si el módulo no existe, ORDS lanza una excepción. La ignoramos.
        IF SQLCODE = -20942 THEN DBMS_OUTPUT.PUT_LINE('Módulo v1_public no existía, ignorado.');
        ELSE RAISE; END IF;
END;
/

BEGIN
    ORDS.DELETE_MODULE(p_module_name => 'v1_private');
    DBMS_OUTPUT.PUT_LINE('Módulo v1_private eliminado (si existía).');
EXCEPTION
    WHEN OTHERS THEN -- Si el módulo no existe, la ignoramos.
        IF SQLCODE = -20942 THEN DBMS_OUTPUT.PUT_LINE('Módulo v1_private no existía, ignorado.');
        ELSE RAISE; END IF;
END;
/


-- == BLOQUE DE CREACIÓN: DEFINE LA NUEVA ESTRUCTURA DE LA API ==
PROMPT Creando nueva estructura de API...

BEGIN

    -- == MÓDULO PÚBLICO: v1_public (Accesible por cualquiera) ==
    ORDS.DEFINE_MODULE(
        p_module_name    => 'v1_public',
        p_base_path      => '/v1_public/',
        p_items_per_page => 25,
        p_status         => 'PUBLISHED',
        p_comments       => 'Endpoints públicos para el catálogo de vehículos y datos generales.'
    );

    -- Template para la lista de vehículos
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'v1_public',
        p_pattern        => 'vehiculos'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'v1_public',
        p_pattern        => 'vehiculos',
        p_method         => 'GET',
        p_source_type    => 'json/collection',
        p_source         => 'SELECT * FROM VEHICulos WHERE ESTADO = ''DISPONIBLE'' ORDER BY FECHA_CREACION DESC',
        p_items_per_page => 25
    );

    -- Template para el detalle de un vehículo
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'v1_public',
        p_pattern        => 'vehiculos/:id'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'v1_public',
        p_pattern        => 'vehiculos/:id',
        p_method         => 'GET',
        p_source_type    => 'json/item',
        p_source         => 'SELECT * FROM VEHICULOS WHERE ID = :id',
        p_items_per_page => 1
    );


    -- == MÓDULO PRIVADO: v1_private (Requiere autenticación OAuth2) ==
    ORDS.DEFINE_MODULE(
        p_module_name    => 'v1_private',
        p_base_path      => '/v1_private/',
        p_items_per_page => 25,
        p_status         => 'PUBLISHED',
        p_comments       => 'Endpoints privados que requieren autenticación OAuth2 para operaciones transaccionales.'
    );

    -- Template para crear un pedido
    ORDS.DEFINE_TEMPLATE(
        p_module_name => 'v1_private',
        p_pattern     => 'pedidos'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name => 'v1_private',
        p_pattern     => 'pedidos',
        p_method      => 'POST',
        p_source_type => 'plsql/block',
        p_source      => 'BEGIN
                            INSERT INTO PEDIDOS (cliente_id, vehiculo_id, monto_transaccion, tipo_pago, moneda, estado_pago)
                            VALUES (:cliente_id, :vehiculo_id, :monto_transaccion, :tipo_pago, :moneda, ''PENDIENTE'')
                            RETURNING ID INTO :new_pedido_id;
                            
                            :status_code := 201;
                            :location := :new_pedido_id;
                            
                            apex_json.open_object;
                            apex_json.write(''pedido_id'', :new_pedido_id);
                            apex_json.close_object;
                        EXCEPTION
                            WHEN OTHERS THEN :status_code := 400;
                        END;'
    );
    -- Definimos los parámetros IN/OUT para el handler anterior
    ORDS.DEFINE_PARAMETER(p_module_name => 'v1_private', p_pattern => 'pedidos', p_method => 'POST', p_name => 'new_pedido_id', p_bind_variable_name => 'new_pedido_id', p_access_method => 'OUT', p_source_type => 'RESPONSE', p_param_type => 'INTEGER');
    ORDS.DEFINE_PARAMETER(p_module_name => 'v1_private', p_pattern => 'pedidos', p_method => 'POST', p_name => 'cliente_id', p_bind_variable_name => 'cliente_id', p_access_method => 'IN', p_source_type => 'PAYLOAD', p_param_type => 'INTEGER');
    ORDS.DEFINE_PARAMETER(p_module_name => 'v1_private', p_pattern => 'pedidos', p_method => 'POST', p_name => 'vehiculo_id', p_bind_variable_name => 'vehiculo_id', p_access_method => 'IN', p_source_type => 'PAYLOAD', p_param_type => 'INTEGER');
    ORDS.DEFINE_PARAMETER(p_module_name => 'v1_private', p_pattern => 'pedidos', p_method => 'POST', p_name => 'monto_transaccion', p_bind_variable_name => 'monto_transaccion', p_access_method => 'IN', p_source_type => 'PAYLOAD', p_param_type => 'NUMBER');
    ORDS.DEFINE_PARAMETER(p_module_name => 'v1_private', p_pattern => 'pedidos', p_method => 'POST', p_name => 'tipo_pago', p_bind_variable_name => 'tipo_pago', p_access_method => 'IN', p_source_type => 'PAYLOAD', p_param_type => 'STRING');
    ORDS.DEFINE_PARAMETER(p_module_name => 'v1_private', p_pattern => 'pedidos', p_method => 'POST', p_name => 'moneda', p_bind_variable_name => 'moneda', p_access_method => 'IN', p_source_type => 'PAYLOAD', p_param_type => 'STRING');

    -- Template para los webhooks (confirmaciones de pago)
    ORDS.DEFINE_TEMPLATE(
        p_module_name    => 'v1_private',
        p_pattern        => 'webhooks/transbank'
    );
    ORDS.DEFINE_HANDLER(
        p_module_name    => 'v1_private',
        p_pattern        => 'webhooks/transbank',
        p_method         => 'POST',
        p_source_type    => 'plsql/block',
        p_source         => 'BEGIN :status_code := 200; END;' -- Lógica de esqueleto por ahora
    );

    COMMIT;
END;
/

PROMPT ==========================================================
PROMPT >> Módulos y Endpoints de la API CREADOS EXITOSAMENTE <<
PROMPT ==========================================================
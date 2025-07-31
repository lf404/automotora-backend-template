# Manual de Configuración de la API REST (ORDS)

**Versión:** 2.0
**Método:** Manual a través de la interfaz de APEX

Este documento describe los pasos para configurar manualmente los módulos y endpoints de la API sobre una base de datos de ERP recién creada.

---

## 1. Habilitar el Esquema para REST

1.  Navega a `SQL Workshop` > `RESTful Services`.
2.  Haz clic en `Register Schema with ORDS`.
3.  **Schema Alias:** `automotora_erp`
4.  **Requires secure access:** `No`.
5.  Haz clic en `Save Schema Attributes`.

---

## 2. Crear Módulo Público: `v1_public`

-   **Name:** `v1_public`
-   **Base Path:** `/v1_public/`

### 2.1. Endpoint `GET /vehiculos` (Lista)

-   **URI Template:** `vehiculos`
-   **Handler:**
    -   **Method:** `GET`
    -   **Source Type:** `Query`
    -   **Source:**
        ```sql
        SELECT ID, MARCA, MODELO, ANO, PRECIO_CLP, FOTO_URL, DESCRIPCION
        FROM VEHICULOS
        WHERE ESTADO = 'DISPONIBLE'
        ORDER BY FECHA_CREACION DESC
        ```

### 2.2. Endpoint `GET /vehiculos/:id` (Detalle)

-   **URI Template:** `vehiculos/:id`
-   **Handler:**
    -   **Method:** `GET`
    -   **Source Type:** `Query Single Row`
    -   **Source:**
        ```sql
        SELECT ID, MARCA, MODELO, ANO, PRECIO_CLP, FOTO_URL, DESCRIPCION, ESTADO
        FROM VEHICULOS
        WHERE ID = :id
        ```
    -   **Parámetro Requerido:**
        -   **Name:** `id`
        -   **Bind Variable Name:** `id`
        -   **Source Type:** `URI`
        -   **Data Type:** `INTEGER`

---

## 3. Crear Módulo Privado: `v1_private`

-   **Name:** `v1_private`
-   **Base Path:** `/v1_private/`

### 3.1. Endpoint `POST /pedidos` (Crear Pedido)

-   **URI Template:** `pedidos`
-   **Handler:**
    -   **Method:** `POST`
    -   **Source Type:** `PL/SQL`
    -   **Source:**
        ```sql
        BEGIN
            INSERT INTO PEDIDOS (cliente_id, vehiculo_id, monto_transaccion, tipo_pago, moneda, estado_pago)
            VALUES (:cliente_id, :vehiculo_id, :monto_transaccion, :tipo_pago, :moneda, 'PENDIENTE')
            RETURNING ID INTO :new_pedido_id;
            
            :status_code := 201; 
            :location := :new_pedido_id; 
            apex_json.open_object;
            apex_json.write('pedido_id', :new_pedido_id);
            apex_json.close_object;
        EXCEPTION
            WHEN OTHERS THEN :status_code := 400;
        END;
        ```
    -   **Parámetro Requerido:**
        -   **Name:** `new_pedido_id`
        -   **Bind Variable Name:** `new_pedido_id`
        -   **Source Type:** `RESPONSE`
        -   **Access Method:** `OUT`
        -   **Data Type:** `INTEGER`
    -   **NOTA:** Los parámetros IN se gestionan implícitamente a través del payload JSON.

### 3.2. Endpoint `POST /webhooks/transbank` (Webhook)
-   **URI Template:** `webhooks/transbank`
-   **Handler:**
    -   **Method:** `POST`
    -   **Source Type:** `PL/SQL`
    -   **Source (Esqueleto):** `BEGIN :status_code := 200; END;`

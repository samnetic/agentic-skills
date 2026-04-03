# OpenAPI 3.1 Specification

## Schema-First vs Code-First

```
Which approach?
|
+-- Public API with external consumers?
|   -> Schema-first (write OpenAPI spec, then implement)
|   -> Spec is the contract. Implementation follows.
|
+-- Internal API, fast iteration?
|   -> Code-first (generate spec from code annotations)
|   -> Faster development, spec stays in sync automatically.
|
+-- TypeScript + tRPC?
    -> Neither — types ARE the spec
```

---

## Essential Schema Example

```yaml
openapi: 3.1.0
info:
  title: Order API
  version: 1.0.0
  description: Manage customer orders
  contact:
    email: api@example.com
  license:
    name: MIT

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://api.staging.example.com/v1
    description: Staging

paths:
  /orders:
    get:
      operationId: listOrders
      summary: List orders
      tags: [Orders]
      parameters:
        - name: status
          in: query
          schema:
            type: string
            enum: [pending, shipped, delivered, cancelled]
        - name: cursor
          in: query
          schema:
            type: string
        - name: limit
          in: query
          schema:
            type: integer
            minimum: 1
            maximum: 100
            default: 20
      responses:
        '200':
          description: Paginated list of orders
          content:
            application/json:
              schema:
                type: object
                required: [data, pagination]
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/Order'
                  pagination:
                    $ref: '#/components/schemas/CursorPagination'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '429':
          $ref: '#/components/responses/RateLimited'

    post:
      operationId: createOrder
      summary: Create an order
      tags: [Orders]
      parameters:
        - name: Idempotency-Key
          in: header
          required: true
          schema:
            type: string
            format: uuid
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateOrderRequest'
      responses:
        '201':
          description: Order created
          headers:
            Location:
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Order'
        '422':
          $ref: '#/components/responses/ValidationError'

components:
  schemas:
    Order:
      type: object
      required: [id, status, total, currency, created_at]
      properties:
        id:
          type: string
          example: ord_abc123
        status:
          type: string
          enum: [pending, shipped, delivered, cancelled]
        total:
          type: integer
          description: Amount in cents
          example: 5000
        currency:
          type: string
          example: usd
        created_at:
          type: string
          format: date-time

    CursorPagination:
      type: object
      required: [has_more]
      properties:
        next_cursor:
          type: [string, 'null']      # OpenAPI 3.1: use type array, not nullable
        has_more:
          type: boolean

    ProblemDetail:
      type: object
      required: [type, title, status]
      properties:
        type:
          type: string
          format: uri
        title:
          type: string
        status:
          type: integer
        detail:
          type: string
        instance:
          type: string

  responses:
    Unauthorized:
      description: Authentication required
      content:
        application/problem+json:
          schema:
            $ref: '#/components/schemas/ProblemDetail'
    RateLimited:
      description: Rate limit exceeded
      headers:
        Retry-After:
          schema:
            type: integer
      content:
        application/problem+json:
          schema:
            $ref: '#/components/schemas/ProblemDetail'
    ValidationError:
      description: Validation failed
      content:
        application/problem+json:
          schema:
            allOf:
              - $ref: '#/components/schemas/ProblemDetail'
              - type: object
                properties:
                  errors:
                    type: array
                    items:
                      type: object
                      properties:
                        field:
                          type: string
                        message:
                          type: string

  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key

security:
  - BearerAuth: []
  - ApiKeyAuth: []
```

---

## SDK Generation

```bash
# Generate TypeScript client from OpenAPI spec
npx openapi-typescript api.yaml -o src/api-types.ts          # Types only
npx @hey-api/openapi-ts -i api.yaml -o src/client            # Full client
npx orval --input api.yaml --output src/api                   # React Query hooks

# Generate server stubs
npx openapi-generator-cli generate -i api.yaml -g nodejs-express-server -o server/
```

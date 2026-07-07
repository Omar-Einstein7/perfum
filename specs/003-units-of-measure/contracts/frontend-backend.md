# Frontend-Backend Contract: Units of Measure

## Base URL

`{API_BASE_URL}/units` (e.g., `http://localhost:3000/api/v1/units`)

## Endpoints

### List Units

`GET /units?page=1&limit=20&search=kg&active=true`

- `page`: positive integer (default 1)
- `limit`: positive integer 1–100 (default 20)
- `search`: fuzzy search against name and abbreviation
- `active`: boolean filter (omit to include both active and inactive)

**200 Response:**
```json
{
  "data": [ /* Unit objects */ ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 5,
    "pages": 1
  }
}
```

### Get Unit

`GET /units/:id`

**200:** Single unit object. **404:** Not found.

### Create Unit

`POST /units`

**201:** Created unit with `_id`. **409:** Duplicate name/abbreviation. **422:** Validation error.

### Update Unit

`PUT /units/:id`

**200:** Updated unit. **409:** Duplicate name/abbreviation. **404:** Not found. **422:** Validation error.

### Deactivate Unit (Soft-Delete)

`DELETE /units/:id`

**200:** `{ "success": true }`. **409:** Referenced by materials (body includes `message` explaining). **404:** Not found.

## Error Response Shape

```json
{
  "message": "Human-readable error description",
  "errors": { "fieldName": "Specific field error" }
}
```

## Auth

All endpoints require `Authorization: Bearer <token>` header. 401 if missing/expired. 403 if user lacks `canEditMasters` permission.

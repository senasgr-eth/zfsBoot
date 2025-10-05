# API Authentication

NSBoot API uses JWT (JSON Web Token) for authentication.

## Overview

All API endpoints (except `/api/auth/*` and `/api/health`) require authentication using a JWT token.

## Getting a Token

### Login

**Endpoint:** `POST /api/auth/login`

**Request:**
```json
{
  "username": "admin",
  "password": "your-password"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "username": "admin",
    "role": "admin"
  },
  "expires_in": 86400
}
```

## Using the Token

Include the token in the `Authorization` header of your requests:

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost/api/system/info
```

### JavaScript Example

```javascript
// Login
const response = await fetch('/api/auth/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    username: 'admin',
    password: 'password'
  })
})

const { token } = await response.json()

// Use token for authenticated requests
const systemInfo = await fetch('/api/system/info', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
})
```

### Python Example

```python
import requests

# Login
response = requests.post('http://localhost/api/auth/login', json={
    'username': 'admin',
    'password': 'password'
})

token = response.json()['token']

# Use token
headers = {'Authorization': f'Bearer {token}'}
system_info = requests.get('http://localhost/api/system/info', headers=headers)
```

## Token Refresh

Tokens expire after 24 hours by default. Refresh before expiry:

**Endpoint:** `POST /api/auth/refresh`

**Request:**
```json
{
  "token": "your-current-token"
}
```

**Response:**
```json
{
  "success": true,
  "token": "new-token",
  "expires_in": 86400
}
```

## Logout

**Endpoint:** `POST /api/auth/logout`

**Headers:**
```
Authorization: Bearer YOUR_TOKEN
```

**Response:**
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

Note: Since JWT is stateless, logout only returns success. The client should discard the token.

## Security Best Practices

### 1. Store Tokens Securely

**Browser:**
- Use `httpOnly` cookies (if implementing server-side)
- Or use `sessionStorage` (cleared on tab close)
- Avoid `localStorage` for sensitive tokens

**Mobile:**
- Use secure storage (Keychain on iOS, KeyStore on Android)

### 2. Token Expiry

- Default: 24 hours
- Configure via `JWT_EXPIRY` environment variable
- Refresh tokens before expiry

### 3. HTTPS Only

Always use HTTPS in production to prevent token interception.

### 4. Environment Variables

Set a strong secret in production:

```bash
export JWT_SECRET="your-very-long-random-secret-key"
export JWT_EXPIRY=86400  # 24 hours in seconds
```

### 5. Rate Limiting

Login endpoint is rate-limited to prevent brute force attacks:
- 5 attempts per minute per IP
- 20 attempts per hour per IP

## Error Responses

### 401 Unauthorized

```json
{
  "error": "Unauthorized",
  "message": "Invalid credentials"
}
```

### 403 Forbidden

```json
{
  "error": "Forbidden",
  "message": "Insufficient permissions"
}
```

### Token Expired

```json
{
  "error": "Unauthorized",
  "message": "Token expired"
}
```

## Roles and Permissions

### Admin Role

Full access to all endpoints:
- System management
- Image management
- Client management
- Settings modification

### User Role (Future)

Limited access:
- View system info
- View images
- View clients
- No modification permissions

## Default Credentials

**Username:** `admin`  
**Password:** `admin`

⚠️ **Change immediately in production!**

## Changing Password

Currently, passwords are configured in the code. In production:

1. Use environment variables
2. Implement password change endpoint
3. Use external authentication (OAuth2, LDAP)

## OAuth2/OIDC Integration

For enterprise deployments, NSBoot supports OAuth2/OIDC:

See [OAuth2 Configuration](oauth2.md) for details.

## API Key Authentication (Future)

For service-to-service communication:

```bash
curl -H "X-API-Key: your-api-key" \
  http://localhost/api/system/info
```

## Testing Authentication

```bash
# Login
TOKEN=$(curl -s -X POST http://localhost/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}' \
  | jq -r '.token')

# Use token
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost/api/system/info

# Refresh token
NEW_TOKEN=$(curl -s -X POST http://localhost/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"token\":\"$TOKEN\"}" \
  | jq -r '.token')
```

## Troubleshooting

### Token Not Working

1. Check token format: `Bearer <token>`
2. Verify token hasn't expired
3. Check server logs for details

### Login Fails

1. Verify credentials
2. Check rate limiting
3. Ensure API is accessible

### CORS Issues

Configure CORS in nginx:
```nginx
add_header Access-Control-Allow-Origin * always;
add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
```

## Next Steps

- [API Reference](openapi.yaml) - Full API documentation
- [User Management](../admin/users.md) - Managing users
- [Security](../admin/security.md) - Security best practices

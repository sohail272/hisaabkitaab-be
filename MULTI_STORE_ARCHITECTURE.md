# Multi-Store / Multi-Tenant Architecture Proposal

## Overview
Transform HisaabKitaab into a multi-tenant system supporting:
- **Organizations** (e.g., "SMK Clothing") with multiple **Stores** (branches)
- Role-based access control with different permission levels
- Data isolation per store, with aggregated views for analysis

## Requirements Summary

### Business Requirements
1. One organization can have multiple stores (branches)
2. Each store has isolated data:
   - Products/Stock
   - Vendors
   - Customers
   - Invoices
   - Purchases
3. Cross-store analysis: View aggregated data across all stores
4. Role-based permissions:
   - **Store Worker**: Create invoices ONLY, cannot view/edit vendors, purchases, or customers
   - **Store Manager** (implied): Full access to their store's data
   - **Organization Admin**: Full access to all stores + aggregated analytics

## Proposed Architecture

### 1. Database Schema Changes

#### New Models

**Organization** (Company/Brand)
```ruby
- id
- name (e.g., "SMK Clothing")
- logo_url (string, for storing logo file path/URL)
- phone
- email
- address
- active
- created_at, updated_at
```

**Store** (Branch/Location)
```ruby
- id
- organization_id (foreign_key)
- name (e.g., "SMK Clothing - Downtown Branch")
- code (unique identifier, e.g., "SMK-DT-001")
- address
- phone
- active
- created_at, updated_at
```

**User** (Authentication & Authorization)
```ruby
- id
- organization_id (foreign_key)
- store_id (foreign_key, nullable - null = org admin)
- email (unique)
- password_digest (for authentication)
- name
- phone
- role (enum: 'store_worker', 'store_manager', 'org_admin')
- active
- created_at, updated_at
```

#### Existing Models - Add Store Association

All existing models need `store_id`:
- `products` → `store_id`
- `vendors` → `store_id`
- `customers` → `store_id`
- `invoices` → `store_id`
- `purchases` → `store_id`
- `stock_movements` → `store_id` (derived from invoice/purchase)

**Note**: Products might be shared across stores for the same organization? Need clarification.

### 2. Authentication & Authorization

#### Authentication Flow
1. User logs in with email/password
2. Backend validates and returns JWT token (or session)
3. Token contains: `user_id`, `organization_id`, `store_id`, `role`
4. Frontend stores token and includes in all API requests

#### Authorization Strategy

**Backend (Rails)**:
- Add `current_user` method to `ApplicationController`
- Add `before_action :authenticate_user!` to all API controllers
- Add store-scoped queries: `Product.where(store_id: current_user.store_id)`
- For org admins: `Product.where(organization_id: current_user.organization_id)`

**Permission Matrix**:

| Resource | Store Worker | Store Manager | Org Admin |
|----------|-------------|---------------|-----------|
| **Invoices** | Create only | Full CRUD (own store) | Full CRUD (all stores) |
| **Customers** | None | Full CRUD (own store) | Full CRUD (all stores) |
| **Vendors** | None | Full CRUD (own store) | Full CRUD (all stores) |
| **Purchases** | None | Full CRUD (own store) | Full CRUD (all stores) |
| **Products** | View (own store) | Full CRUD (own store) | Full CRUD (all stores) |
| **Dashboard** | Own store stats | Own store stats | Aggregated (all stores) |
| **Analytics** | None | Own store | All stores |

### 3. API Changes

#### New Endpoints

**Authentication & Onboarding**:
```
POST   /api/v1/auth/onboard        # Organization onboarding (public, one-time)
  Body: {
    organization: { name, logo (file) },
    store: { name, code, address, phone },
    user: { name, email, password }
  }
  Creates: Organization, first Store, first User (org_admin)
  
POST   /api/v1/auth/login          # Login
POST   /api/v1/auth/logout         # Logout
GET    /api/v1/auth/me             # Current user info
```

**Organization & Store Management**:
```
GET    /api/v1/organizations       # List organizations (for super admins)
GET    /api/v1/organizations/:id   # Get organization details
PUT    /api/v1/organizations/:id   # Update organization (org admin only)
POST   /api/v1/organizations/:id/logo  # Upload logo (org admin only)
GET    /api/v1/stores              # List stores (scoped by user)
POST   /api/v1/stores              # Create store (org admin only)
PUT    /api/v1/stores/:id          # Update store
GET    /api/v1/users               # List users (org admin only)
POST   /api/v1/users               # Create user (org admin only)
```

#### Modified Endpoints
All existing endpoints remain but:
- Automatically scoped by `store_id` (or `organization_id` for org admins)
- Include store context in responses
- Require authentication

Example:
```ruby
GET /api/v1/products
# Store Worker/Manager: Returns products for their store only
# Org Admin: Can filter by store_id query param or return all

GET /api/v1/products?store_id=5  # Org admin filtering
GET /api/v1/products?all_stores=true  # Org admin - all stores
```

#### Aggregated Analytics Endpoint
```
GET /api/v1/dashboard/analytics?store_ids[]=1&store_ids[]=2
# Returns aggregated stats across selected stores
```

### 4. Frontend Changes

#### New Components
1. **OnboardingPage** - Organization onboarding wizard
   - Step 1: Organization details (name, logo upload)
   - Step 2: First branch/store setup (name, code, address, phone)
   - Step 3: Admin user creation (name, email, password)
   - Creates everything in one flow, then redirects to login
2. **LoginPage** - User authentication
3. **StoreSelector** - Dropdown to switch/store context (shows org logo)
4. **UserContext** - React context for current user/store/organization
5. **ProtectedRoute** - Route wrapper requiring auth
6. **RoleGate** - Component wrapper hiding/showing based on role

#### Modified Components
- All pages check user role before showing/hiding features
- Store selector in header/navbar
- Menu items conditionally rendered based on role
- API client includes auth token in headers

#### State Management
```typescript
interface Organization {
  id: number;
  name: string;
  logo_url: string | null;
  phone?: string;
  email?: string;
  address?: string;
}

interface Store {
  id: number;
  name: string;
  code: string;
  organization_id: number;
  address?: string;
  phone?: string;
}

interface User {
  id: number;
  name: string;
  email: string;
  role: 'store_worker' | 'store_manager' | 'org_admin';
  organization: Organization;
  store: Store | null; // null for org admins
}

// Global state (Context/Redux)
- currentUser: User
- currentOrganization: Organization (with logo)
- currentStore: Store (for org admins - selected store context)
- availableStores: Store[] (for org admins)
```

#### Organization Onboarding Flow

**Backend Flow**:
1. `POST /api/v1/auth/onboard` endpoint receives:
   - Organization: `{ name, logo (file) }`
   - Store: `{ name, code, address, phone }`
   - User: `{ name, email, password }`
2. Validates all data (organization name, store code uniqueness, email uniqueness, password strength)
3. Uploads logo file to storage (`storage/organizations/logos/` or cloud storage)
4. Creates Organization with uploaded logo URL
5. Creates first Store linked to Organization
6. Creates first User (role: `org_admin`) linked to Organization
7. Returns authentication token (auto-login) OR success message (redirect to login)

**Frontend Flow**:
1. User visits app for first time
2. Check if any organization exists (via `GET /api/v1/organizations` or dedicated check endpoint)
3. If no org exists → Show OnboardingPage
4. If org exists → Show LoginPage
5. Onboarding wizard (3 steps):
   - **Step 1**: Organization details
     - Organization name (required)
     - Logo upload (optional, with preview)
     - Shows logo preview once selected
   - **Step 2**: First branch/store setup
     - Store name (required, e.g., "SMK Clothing - Downtown Branch")
     - Store code (required, unique identifier, e.g., "SMK-DT-001")
     - Address (optional)
     - Phone (optional)
   - **Step 3**: Admin user account
     - Admin name (required)
     - Email (required, unique)
     - Password (required, min 8 characters)
     - Confirm password (required, must match)
6. Submit → API call creates everything → Auto-login with token OR redirect to login
7. After login → Redirect to dashboard

**Logo Handling**:
- Upload via multipart form data
- Accept formats: `.jpg`, `.jpeg`, `.png`, `.webp` (max 5MB)
- Store in `storage/organizations/logos/{org_id}/logo.{ext}` or cloud storage (S3, Cloudinary)
- Store path/URL in `organizations.logo_url`
- Display in:
  - Header/navbar (top left or center)
  - Store selector dropdown
  - Invoices (optional, as header)
  - Email templates (optional)

**Validation Rules**:
- Organization name: Required, min 2 characters, max 100
- Logo: Optional, max 5MB, formats: jpg/png/webp
- Store name: Required, min 2 characters, max 100
- Store code: Required, unique, alphanumeric with hyphens, min 3 characters, max 20
- User email: Required, valid email format, unique across system
- Password: Required, min 8 characters, at least one letter and one number

### 5. Implementation Phases

#### Phase 1: Foundation (Week 1)
- [ ] Database migrations for Organizations, Stores, Users
- [ ] Add `logo_url` to Organizations table
- [ ] Add `store_id` to all existing models
- [ ] Basic User model with authentication (devise or custom)
- [ ] JWT token generation/validation
- [ ] Onboarding API endpoint (creates org, store, and first user)
- [ ] File upload handling for organization logo
- [ ] Login/logout API endpoints

#### Phase 2: Authorization (Week 2)
- [ ] Add `current_user` and authentication to ApplicationController
- [ ] Update all controllers to scope by store
- [ ] Implement role-based permission checks
- [ ] Update all API endpoints to require auth

#### Phase 3: Frontend Auth & Onboarding (Week 2-3)
- [ ] Onboarding wizard page (3-step flow)
- [ ] Logo upload component (with preview)
- [ ] Login page
- [ ] Check if user is already onboarded (redirect logic)
- [ ] Auth context/state management (includes org logo)
- [ ] Protected routes
- [ ] Token storage and auto-refresh
- [ ] API client with auth headers

#### Phase 4: Store Scoping & UI (Week 3-4)
- [ ] Store selector component
- [ ] Update all pages to use store context
- [ ] Role-based UI (hide/show based on permissions)
- [ ] Store-specific data fetching

#### Phase 5: Analytics & Cross-Store (Week 4-5)
- [ ] Aggregated dashboard for org admins
- [ ] Cross-store analytics endpoint
- [ ] Multi-store data visualization
- [ ] Store comparison views

#### Phase 6: Testing & Refinement (Week 5-6)
- [ ] Unit tests for models
- [ ] Integration tests for API endpoints
- [ ] E2E tests for critical flows
- [ ] Performance optimization
- [ ] Documentation

## Design Decisions & Questions

### Questions for Clarification

1. **Product Sharing**: 
   - Can the same product exist in multiple stores with different stock?
   - Or should products be shared across stores with one inventory pool?

2. **Customer Sharing**:
   - Can a customer purchase from multiple stores?
   - Should customers be organization-level or store-level?

3. **Vendor Sharing**:
   - Are vendors shared across stores or store-specific?
   - Can same vendor supply to multiple stores?

4. **Invoice Numbering**:
   - Per-store numbering (e.g., "SMK-DT-INV-001")?
   - Or organization-level sequential?

5. **Store Worker Permissions**:
   - Can they view existing invoices they created?
   - Can they view product list (for invoice creation)?
   - Can they search customers by phone (for invoice creation)?

6. **Organization Admin Store Context**:
   - Can they create/edit data for any store?
   - Or just view analytics?

7. **User Management**:
   - Who can create/manage users?
   - Can store managers create store workers?

### Recommended Approach (My Suggestions)

1. **Products**: Store-specific (different stock per store)
   - Each store has its own inventory
   - Same product can exist in multiple stores with different stock

2. **Customers**: Organization-level (can purchase from any store)
   - Customer belongs to organization, not store
   - Can see purchase history across all stores

3. **Vendors**: Store-specific initially (can be shared later)
   - Each store manages its own vendor relationships
   - Simpler to start, can enhance later

4. **Invoice Numbering**: Per-store
   - Format: `{STORE_CODE}-INV-YYYYMMDD-0001`
   - Example: `SMK-DT-INV-20260101-0001`

5. **Store Worker**: 
   - Can view products (read-only for invoice creation)
   - Can search customers by phone (read-only)
   - Can create and view their own invoices
   - Cannot view/edit vendors, purchases, or customers list

6. **Organization Admin**:
   - Full CRUD access to all stores
   - Can switch store context
   - Aggregated analytics dashboard

## Technical Stack Additions

### Backend
- **Authentication**: `devise` gem OR `jwt` gem (lightweight)
- **Authorization**: `pundit` gem (for policies) OR custom concerns
- **API Versioning**: Consider `/api/v2/` for multi-tenant endpoints

### Frontend
- **Auth Storage**: `localStorage` or `sessionStorage` for tokens
- **State Management**: React Context API (or Zustand/Redux if needed)
- **Route Protection**: Custom `ProtectedRoute` component
- **File Upload**: Native `input[type="file"]` or library like `react-dropzone`
- **Logo Display**: `<img>` tag with org logo URL in header/navbar

## Migration Strategy

1. **Database Migration**:
   - Create new tables (organizations, stores, users)
   - Add `store_id` columns to existing tables
   - Set default `store_id` for existing data (or create default store)
   - Run in production with care (backup first!)

2. **Code Migration**:
   - Implement auth system
   - Update all queries to include store scoping
   - Deploy incrementally (feature flags?)

3. **Data Migration**:
   - For existing deployments: Run onboarding flow to create org/store/user
   - OR create migration script to:
     - Create default organization (from env vars or defaults)
     - Create default store
     - Migrate existing data to default store
     - Create admin user (credentials from env vars)
   - For new deployments: Use onboarding flow (no migration needed)

## Security Considerations

1. **Token Security**: 
   - Use HTTPS only
   - Token expiration (1 hour?)
   - Refresh tokens

2. **Data Isolation**:
   - Always scope queries by store
   - Prevent cross-store data access
   - Validate store_id in all mutations

3. **Role Enforcement**:
   - Server-side checks only (never trust client)
   - Test all permission scenarios

## Next Steps

1. **Review this proposal** and answer clarification questions
2. **Confirm approach** for each design decision
3. **Prioritize phases** - which features are most critical?
4. **Start implementation** with Phase 1

---

**Estimated Timeline**: 5-6 weeks for full implementation
**Complexity**: High (affects entire codebase)
**Risk**: Medium-High (requires careful data migration)


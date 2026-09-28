# HostelGhar (HMS) — Production Django + DRF + MySQL Backend

Production-ready backend for the **HostelGhar / PG Manager** Flutter application. Built with **Django 5, Django REST Framework (DRF), Simple JWT, and MySQL 8+**.

---

## 1. Technology Stack
- **Framework:** Django 5.1+ & Django REST Framework 3.17+
- **Database:** MySQL 8+ (InnoDB, UTF8MB4) with PyMySQL
- **Authentication:** JWT (Simple JWT) with Bearer token header & refresh token rotation
- **CORS:** django-cors-headers configured for Flutter Web, Desktop, and Mobile (Android Emulator `10.0.2.2:8000`, Localhost `127.0.0.1:8000`)
- **Architecture:** 14 modular domain apps with transactional integrity

---

## 2. Directory Structure

```
backend/
├── manage.py
├── requirements.txt
├── .env.example
├── .env
├── .gitignore
├── README.md
│
├── config/
│   ├── settings/
│   │   ├── __init__.py
│   │   └── base.py
│   ├── urls.py
│   ├── asgi.py
│   └── wsgi.py
│
├── apps/
│   ├── accounts/       # Custom User model, Roles (Owner/Warden/Tenant), JWT Auth
│   ├── properties/     # Hostel / PG properties, capacity, occupancy stats
│   ├── wardens/        # Warden assignments, permissions, invitations
│   ├── rooms/          # Rooms, capacity, floor, room types
│   ├── beds/           # Bed slots, vacancy tracking, atomic assignment
│   ├── tenants/        # Resident profiles, KYC, move-in/out, guardian info
│   ├── payments/       # Invoices, Payments, Expenses, Meals, Utilities
│   ├── rent/           # Automated monthly rent invoice cycle generation
│   ├── maintenance/    # Maintenance tickets, priority, category, resolution
│   ├── complaints/     # Resident complaints & grievances
│   ├── notices/        # Announcements targeting specific roles/properties
│   ├── dashboard/      # Real-time aggregated financial & occupancy metrics
│   ├── bookings/       # Bed/room reservations and advance booking
│   └── notifications/  # User in-app notifications
│
└── media/              # Document, avatar and KYC image uploads
```

---

## 3. Quick Start & Setup Instructions

### Step 1: Activate Virtual Environment
Open PowerShell inside the `backend/` folder:
```powershell
python -m venv .venv
.\.venv\Scripts\activate
```

### Step 2: Install Dependencies
```powershell
pip install -r requirements.txt
```

### Step 3: Configure Environment Variables
Copy `.env.example` to `.env` and fill in your MySQL credentials:
```ini
# Database Settings (MySQL 8+)
DB_ENGINE=django.db.backends.mysql
DB_NAME=hms_db
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_HOST=127.0.0.1
DB_PORT=3306

SECRET_KEY=your-secure-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2,0.0.0.0
CORS_ALLOW_ALL_ORIGINS=True
```

### Step 4: Initialize MySQL Database
Run the automated database creator:
```powershell
python manage.py setup_mysql
```

### Step 5: Run Migrations
```powershell
python manage.py migrate
```

### Step 6: Seed Realistic Nepal Demo Data
```powershell
python manage.py seed_data
```

This creates:
- **Owner Account:** `owner@hostelghar.com` / `password123`
- **Warden Account:** `warden@hostelghar.com` / `password123`
- **Properties:** *HostelGhar Thamel* (Assigned to Warden) and *HostelGhar Pulchowk*
- **Rooms & Beds:** Full room directory with occupied and vacant beds
- **Tenants:** Active residents with Nepal KYC credentials, phone numbers, and overdue/paid statuses
- **Financial Ledger:** Invoices, payments via eSewa, expenses, and maintenance tickets

### Step 7: Start the Server
```powershell
python manage.py runserver 0.0.0.0:8000
```

### Step 8: Access the Owner Backend Dashboard
Open your browser (e.g. Chrome, Edge, or VS Code Simple Browser):
- **Web Dashboard:** [http://127.0.0.1:8000/dashboard/](http://127.0.0.1:8000/dashboard/)
- **Owner Registration:** [http://127.0.0.1:8000/register/](http://127.0.0.1:8000/register/)
- **Owner Login:** [http://127.0.0.1:8000/login/](http://127.0.0.1:8000/login/)
- **Warden Management:** [http://127.0.0.1:8000/dashboard/wardens/](http://127.0.0.1:8000/dashboard/wardens/)
- **Properties Overview:** [http://127.0.0.1:8000/dashboard/properties/](http://127.0.0.1:8000/dashboard/properties/)
- **Django Admin:** [http://127.0.0.1:8000/admin/](http://127.0.0.1:8000/admin/)
- **REST API Endpoints:** [http://127.0.0.1:8000/api/](http://127.0.0.1:8000/api/)

**Default Owner Credentials:**
- **Email / Username:** `owner@hostelghar.com` (or your registered owner account)
- **Password:** `password123`

---

## 4. API Endpoints Reference

### Web Dashboard & Management
- `GET /` — Smart entry (redirects browser to `/dashboard/` or `/login/`, serves JSON to API clients)
- `GET/POST /register/` — Owner self-registration portal with optional initial PG creation
- `GET/POST /login/` — Owner session login portal
- `GET /logout/` — Owner session logout
- `GET /dashboard/` — Interactive PG Manager Owner Analytics & Operational Dashboard (9 real-time KPI metrics, Properties table, Recent Activity)
- `GET /dashboard/properties/` — Property room and bed capacity directory
- `GET/POST /dashboard/properties/create/` — Add new property
- `GET /dashboard/properties/{id}/` — Property details, rooms, and assigned wardens
- `GET /dashboard/wardens/` — Warden assignment & permissions management interface
- `POST /dashboard/wardens/assign/` — Assign existing warden to property with permissions
- `POST /dashboard/wardens/invite/` — Create new warden user and assign to property
- `POST /dashboard/wardens/update-permissions/{id}/` — Edit permissions for assigned warden
- `POST /dashboard/wardens/unassign/{id}/` — Revoke warden property assignment
- `GET /dashboard/tenants/` — Tenant resident list
- `GET /dashboard/rooms/` — Room configurations
- `GET /dashboard/beds/` — Bed slots and occupancy tracking
- `GET /dashboard/payments/` — Payment collection ledger
- `GET /dashboard/expenses/` — Operational expenses
- `GET /dashboard/invoices/` — Billing statements
- `GET /dashboard/utilities/` — Utility meters and billing
- `GET /dashboard/maintenance/` — Maintenance tickets
- `GET /dashboard/meals/` — Meal records
- `GET /dashboard/security-deposits/` — Caution deposits held
- `GET /dashboard/reports/` — Profit & loss and occupancy reports
- `GET /dashboard/activity/` — Real-time operational audit log

### Authentication (`/api/auth/`)
- `POST /api/auth/register/` — Register owner or resident
- `POST /api/auth/login/` — JWT Login with email, phone, or username
- `POST /api/auth/token/refresh/` — Obtain new access token via refresh token
- `POST /api/auth/logout/` — Invalidate refresh token
- `GET /api/auth/me/` — Retrieve authenticated user profile
- `POST /api/auth/password-reset/` — Request password reset
- `POST /api/auth/change-password/` — Change user password

### Properties (`/api/properties/`)
- `GET /api/properties/properties/` — List owned or assigned properties
- `POST /api/properties/properties/` — Create new property
- `GET/PATCH/DELETE /api/properties/properties/{id}/` — Manage property

### Wardens (`/api/wardens/`)
- `GET /api/wardens/wardens/assigned/` — Retrieve current warden's assigned properties
- `GET /api/wardens/my-assigned-properties/` — Detailed assigned property listing
- `GET /api/wardens/my-permissions/?pg={id}` — Current permissions for selected PG
- `GET /api/wardens/wardens/?pg={id}` — List wardens assigned to a property
- `POST /api/wardens/wardens/invite/` — Invite or create warden and assign permissions
- `POST /api/wardens/wardens/assign/` — Assign existing warden to property
- `PATCH /api/wardens/wardens/{id}/` — Update permissions or active status
- `DELETE /api/wardens/wardens/remove/?warden={id}&property={id}` — Unassign warden
- `DELETE /api/wardens/wardens/delete-warden/?warden={id}` — Remove warden record

### Rooms & Beds (`/api/rooms/`, `/api/beds/`)
- `GET /api/rooms/rooms/?pg={id}` — List rooms
- `POST /api/rooms/rooms/` — Create room
- `PATCH/DELETE /api/rooms/rooms/{id}/` — Update or delete room
- `GET /api/beds/beds/?pg={id}&room={id}&status={status}` — Filter beds
- `POST /api/beds/beds/` — Create bed slot
- `PATCH/DELETE /api/beds/beds/{id}/` — Update bed or reassign

### Tenants (`/api/tenants/`)
- `GET /api/tenants/tenants/?pg={id}` — List residents
- `POST /api/tenants/tenants/` — Register resident (automatically marks assigned bed as occupied)
- `PATCH /api/tenants/tenants/{id}/` — Update resident profile
- `POST /api/tenants/tenants/{id}/checkout/` — Check out resident and release bed slot
- `DELETE /api/tenants/tenants/{id}/` — Remove resident record

### Billing & Financials (`/api/invoices/`, `/api/payments/`, `/api/expenses/`)
- `GET /api/invoices/invoices/?pg={id}` — List invoices
- `POST /api/invoices/invoices/` — Issue new invoice
- `PATCH /api/invoices/invoices/{id}/` — Update invoice
- `GET /api/payments/payments/?pg={id}` — List payment ledger
- `POST /api/payments/payments/` — Record payment (automatically updates invoice balance and marks as paid/partial)
- `GET /api/expenses/expenses/?pg={id}` — Operational expenses
- `POST /api/expenses/expenses/` — Log operational expense

### Facilities & Operations
- `GET/POST /api/maintenance/maintenance/?pg={id}` — Maintenance tickets
- `GET/POST /api/complaints/complaints/?pg={id}` — Resident grievances
- `GET/POST /api/notices/notices/?pg={id}` — Announcements
- `GET/POST /api/meals/meals/?pg={id}` — Resident meals and extra charges
- `GET/POST /api/utilities/utilities/?pg={id}` — Bulk utility tracking
- `GET /api/dashboard/stats/?pg={id}&month=YYYY-MM` — Real-time analytics

---

## 5. Running the Backend Tests

Run all unit and end-to-end integration tests:
```powershell
python manage.py test accounts properties
```


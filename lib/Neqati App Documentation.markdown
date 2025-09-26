# Neqati App Documentation

Neqati ("My Points" in Arabic) is a loyalty program application designed for construction material suppliers to reward contractors, engineers, and technicians. The app allows users to scan QR codes to earn points, which can be redeemed for gifts. The application has two main interfaces: User Side and Admin Side.

## System Architecture

The app is built using Flutter with a BLoC pattern for state management. It uses Supabase as the backend service for data storage and authentication. The app also implements QR code encryption for secure scanning.

### Key Technologies

- **Flutter**: Cross-platform UI framework
- **BLoC Pattern**: State management
- **Supabase**: Backend as a Service (BaaS)
- **QR Code**: For points collection mechanism
- **Encryption**: For secure QR code data
- **Mobile Scanner**: For QR code scanning functionality

## User Side

### User Journey

1. **Registration**: User registers with personal information
2. **Verification**: Admin approves the registration request
3. **Login**: User logs in with phone number and password
4. **Home Screen**: User views points, level, recent scans, and available gifts/offers
5. **Scanning**: User scans QR codes to earn points
6. **Redemption**: User requests gifts using accumulated points
7. **Level Progression**: User advances through levels as points increase

### Splash Screen
The initial loading screen displayed when the app starts, showing the app logo and name while the app initializes and checks authentication state.

### Authentication

#### Login Screen
- Mobile sign-in with phone number formatted as email (phone@neqati)
- Password authentication with show/hide password toggle
- Forgot password link for password reset functionality
- Registration link for new users
- Error handling for invalid credentials

#### Register Screen
Collects user information including:
- Name
- Address
- National ID
- Phone number
- Password (with validation)
- Position (مقاول/contractor, مهندس/engineer, فني/technician)
- Verification process (admin approval required)

#### Verification Pending Screen
- Shown after registration or when a non-verified user attempts to log in
- Displays status message that account is under review
- Provides contact support option for inquiries
- Option to return to login screen

#### Forgot Password Screen
- Allows users to reset their password via email
- Sends password reset link to the user's registered email
- Confirmation message when reset email is sent

### Main Features

#### Home Screen
- Welcome message with user name
- Points card showing current points and level
- Recent scans section with date, branch, and points earned
- Quick access to available gifts with images and point requirements
- Level information with current level and benefits
- Special offers section with limited-time promotions
- Bottom navigation for accessing other app sections

#### Scan Screen
- Camera interface with QR code detection frame
- Flash/torch toggle for low-light scanning
- Real-time QR code detection and processing
- Secure decryption of QR code data
- Success/failure feedback with points earned
- Points calculation: QR code points × User's level multiplier
- Automatic update of user's points balance

#### Profile Screen
- User information display (name, address, phone, ID, position)
- Points and level information
- Edit profile functionality for name, address, and position
- Non-editable fields (phone number, national ID)
- Logout option with confirmation dialog
- Profile picture placeholder (with future upload capability)

#### Gifts Screen
- Current points balance display
- Grid view of available gifts with images
- Gift details including name and point requirements
- Color-coded point requirements (red if insufficient points)
- Request gift button (enabled only if user has sufficient points)
- Confirmation dialog before gift redemption
- Pull-to-refresh to update gift listings
- Empty state when no gifts are available

#### Levels Info Screen
- List of all available levels with images and names
- Starting point requirements for each level
- Points multiplier benefits for each level
- Current level indicator
- Progress visualization towards next level
- Detailed benefits description for each level

#### Offers Screen
- Current active promotions and special offers
- Offer details including description, conditions, and validity period
- Visual indicators for expiring offers
- Categorized offers (new, popular, ending soon)
- Share offer functionality

#### Scan History
- Chronological list of all previous scans
- Points earned from each scan with multiplier applied
- Date, time, and branch information for each scan
- Filter options by date range and branch
- Total points earned summary
- Empty state when no scan history exists

## Admin Side

### Admin Journey

1. **Login**: Admin logs in with credentials
2. **Dashboard**: Views key metrics and recent activity
3. **User Management**: Reviews registration requests and manages users
4. **QR Code Management**: Creates and monitors QR codes
5. **Gift/Offer Management**: Manages available gifts and special offers
6. **Level Management**: Configures user levels and multipliers
7. **Request Handling**: Processes gift redemption requests

### Authentication

#### Admin Login Screen
- Email and password authentication
- Enhanced security measures for admin accounts
- One master account for all branches
- Each admin can only be assigned to one branch
- Session management with auto-logout for security

### Dashboard

#### Admin Dashboard Screen
- Key performance metrics at a glance
- Total users count (active, blocked, pending)
- Recent registrations and activity
- Total points issued and redeemed
- Recent gift redemption requests
- QR code usage statistics
- Quick action buttons for common tasks

### User Management

#### Registration Requests
- List of pending registration requests with timestamps
- User details preview (name, phone, position)
- Approve button with confirmation dialog
- Deny button with reason input field
- Batch approval/denial options for efficiency
- Notification system for approved/denied requests

#### Users List
- Comprehensive list of all registered users
- Advanced search by name, phone, ID, or position
- Filters by status (active, blocked, admin)
- Filters by level and points range
- Sorting options (newest, points high/low)
- Export user data functionality
- Pagination for large user bases

#### User Details
- Complete user profile information
- Points history with transaction details
- Gift redemption history
- Scan activity timeline
- Points management interface (increase/decrease with reason)
- Request management (view, approve, deny requests)
- User control options:
  - Block/unblock account
  - Reset password
  - Grant/revoke admin privileges
  - Assign to specific level
  - Edit user information

#### Create User
- Form to manually create new users
- Same fields as registration screen
- Option to set initial points balance
- Automatic verification (bypassing approval process)
- Admin role assignment option
- Branch assignment dropdown

### Notification Management
- Centralized notification dashboard
- List of all system notifications with status
- Create and send new notifications
- Target options:
  - All users
  - Specific user groups (by level, position)
  - Individual users
- Notification types (info, warning, promotion)
- Scheduling options for timed notifications
- Templates for common notification types
- Read receipt tracking

### QR Code Management

#### QR Code Creation
- User-friendly interface for generating QR codes
- Batch creation capability for multiple codes
- Customizable parameters:
  - Number of points
  - Branch assignment
  - Expiry duration (in days)
  - Custom notes/labels
- Preview of QR code before generation
- Download options (PNG, PDF, print-ready sheet)
- Encrypted information in QR codes:
  - Number of points
  - Branch
  - Unique ID
  - Status (active/scanned/expired)
  - Scanned by (user ID, initially null)
  - Date of scanning (initially null)
  - Date of creation
  - Expiry duration (in days)

#### Created QRs History
- Comprehensive list of all generated QR codes
- Status indicators (active, scanned, expired)
- Filter options:
  - By branch
  - By status
  - By date range
  - By point value
- Search by QR code ID
- Export functionality for reports
- QR code deactivation option
- Detailed view with scan information

### Gift Management
- Complete CRUD operations for gifts
- Gift catalog management interface
- Each gift includes:
  - Name and detailed description
  - High-quality image upload
  - Points required for redemption
  - Stock quantity management
  - Availability toggle (active/inactive)
  - Category assignment
- Gift redemption request management
- Stock alerts for low inventory
- Analytics on most popular gifts
- Bulk import/export functionality

### Offer Management
- CRUD operations for special offers and promotions
- Offer details configuration:
  - Title and description
  - Banner image upload
  - Start and end dates with time
  - Target user segments
  - Terms and conditions
- Automatic notifications on new offers
- Offer visibility settings
- Featured offer designation
- Offer performance metrics
- Scheduled offers for future activation

### Level Management
- Comprehensive level system configuration
- CRUD operations for user levels
- For each level:
  - Name configuration
  - Custom image/badge upload
  - Starting point threshold
  - Points multiplier setting
  - Special benefits description
  - Color theme assignment
- Level progression visualization
- User distribution by level analytics
- Automatic level assignment rules
- Manual level override options

### Scan History
- Master view of all QR code scans across the system
- Detailed information for each scan:
  - User who scanned
  - QR code details
  - Original points value
  - Multiplier applied
  - Final points awarded
  - Date and time of scan
  - Branch location
- Advanced filtering capabilities:
  - By user
  - By date range
  - By branch
  - By points range
- Suspicious activity flagging
- Export to CSV/Excel functionality
- Scan statistics and trends visualization

## Technical Details

### Architecture Overview
- **Frontend**: Flutter framework with BLoC pattern for state management
- **Backend**: Supabase for database, authentication, and storage
- **API Communication**: RESTful API calls between app and Supabase backend
- **State Management**: BLoC pattern with Cubit implementation for simpler state flows
- **Dependency Injection**: GetIt for service locator pattern
- **Responsive Design**: Adaptive UI for different screen sizes
- **Localization**: Arabic language support with RTL text direction

### QR Code System

#### QR Code Encryption
- **Algorithm**: AES-256 encryption for secure QR code data
- **Implementation**: Using the `encrypt` package for cryptographic operations
- **Secret Key**: 32-byte key stored securely (in production would use Firebase Remote Config)
- **Process Flow**:
  1. QR data is structured as JSON with points, branch, ID, and expiry
  2. JSON is converted to string and encrypted with AES
  3. Encrypted data is encoded as base64 string in QR code
  4. When scanned, base64 is decoded and decrypted back to original data
  5. Validation checks confirm authenticity and expiry status

#### QR Code Generation
- **Format**: Standard QR code format with error correction
- **Data Structure**: Contains encrypted payload with all necessary information
- **Security Features**:
  - Unique ID for each QR code
  - Timestamp for creation date
  - Expiry mechanism to prevent reuse
  - Branch-specific identification

### Authentication System

#### Authentication Flow
1. Users enter phone number in UI but system converts to email format (phone@neqati)
2. Password is securely hashed and stored
3. Registration creates unverified user account
4. Admin reviews and approves registration request
5. Upon approval, user account is marked as verified
6. User can then log in with phone number and password
7. JWT token is generated and stored for authenticated sessions
8. Password reset functionality sends reset link to email address

#### Security Measures
- Secure password storage with hashing
- JWT token-based authentication
- Session management with token expiration
- Admin approval requirement for new accounts
- Account blocking capability for suspicious activity
- Password complexity requirements

### Points System

#### Points Calculation
1. User scans valid QR code containing point value
2. System validates QR code (not expired, not already used)
3. Base points are extracted from QR code data
4. User's level multiplier is applied to base points
   - Formula: Final Points = Base Points × Level Multiplier
5. Final points are added to user's account
6. Transaction is recorded in scan history

#### Level Progression
1. System stores level thresholds in database
2. After points update, system checks if user has reached next level
3. Levels are ordered by starting point threshold (descending)
4. If threshold is reached, user's level is automatically updated
5. Each level has associated multiplier that affects future scans
6. Higher levels provide greater point multiplication benefits

### Gift Redemption Process

#### Request Flow
1. User selects gift and confirms redemption request
2. System validates user has sufficient points
3. Points are temporarily reserved (not yet deducted)
4. Notification is sent to admin dashboard
5. Admin reviews and processes the request
6. If approved:
   - Points are permanently deducted from user's account
   - Gift stock is reduced by one
   - Redemption is recorded in history
   - User receives confirmation notification
7. If denied:
   - Reserved points are returned to user's account
   - User receives notification with reason

#### Inventory Management
- Gift stock is tracked in real-time
- Low stock alerts for administrators
- Gifts with zero stock are automatically marked unavailable
- Analytics track most popular gifts for restocking decisions

### Database Structure

The app uses Supabase tables with the following schema:

#### Users Table
- `id`: Primary key (UUID)
- `name`: User's full name
- `address`: User's address
- `nationalId`: National identification number
- `phoneNumber`: Phone number
- `position`: User's job position (contractor, engineer, technician)
- `isVerified`: Boolean indicating admin verification status
- `points`: Current points balance
- `level`: Current level name
- `isBlocked`: Account status flag
- `isAdmin`: Administrator privileges flag
- `createdAt`: Account creation timestamp

#### Registration Requests Table
- `id`: Primary key
- `userId`: Foreign key to users table
- `status`: Request status (pending, approved, denied)
- `requestDate`: Timestamp of request
- `responseDate`: Timestamp of admin response
- `responseBy`: Admin who processed the request

#### QR Codes Table
- `id`: Primary key
- `points`: Point value
- `branch`: Branch identifier
- `status`: QR code status (active, scanned, expired)
- `scannedBy`: User ID who scanned (nullable)
- `scanDate`: Timestamp of scanning (nullable)
- `creationDate`: Timestamp of creation
- `expiryDuration`: Days until expiry
- `encryptedPayload`: Encrypted QR data

#### Scans Table
- `id`: Primary key
- `userId`: User who performed scan
- `qrCodeId`: QR code that was scanned
- `pointsEarned`: Points awarded after multiplier
- `scanDate`: Timestamp of scan
- `branch`: Branch where scan occurred

#### Gifts Table
- `id`: Primary key
- `name`: Gift name
- `description`: Gift description
- `points`: Points required for redemption
- `stock`: Available quantity
- `imageUrl`: URL to gift image
- `isAvailable`: Availability status
- `category`: Gift category

#### Levels Table
- `id`: Primary key
- `name`: Level name
- `startingPoints`: Points threshold to reach level
- `multiplier`: Points multiplier value
- `imageUrl`: URL to level badge image
- `description`: Level benefits description

#### Offers Table
- `id`: Primary key
- `title`: Offer title
- `description`: Offer details
- `imageUrl`: URL to offer image
- `startDate`: Offer start date
- `endDate`: Offer expiration date
- `isActive`: Offer status

#### Requests Table (Gift Redemptions)
- `id`: Primary key
- `userId`: User requesting gift
- `giftId`: Requested gift
- `status`: Request status (pending, approved, denied)
- `requestDate`: Timestamp of request
- `responseDate`: Timestamp of admin response
- `responseBy`: Admin who processed the request

#### Notifications Table
- `id`: Primary key
- `userId`: Target user (or 'all_admins', 'all_users')
- `message`: Notification content
- `type`: Notification type
- `createdAt`: Timestamp of creation
- `isRead`: Read status

### Performance Optimizations

- **Lazy Loading**: Images and data loaded on-demand
- **Caching**: Local caching of frequently accessed data
- **Pagination**: Implemented for large data sets
- **Background Processing**: Heavy tasks run in isolates
- **Efficient API Calls**: Minimized network requests
- **Optimized Database Queries**: Indexed fields for faster lookups

### Security Considerations

- **Data Encryption**: Sensitive data encrypted at rest and in transit
- **QR Code Security**: Encrypted to prevent forgery
- **Authentication**: Secure email/password authentication
- **Authorization**: Role-based access control
- **Input Validation**: All user inputs validated
- **Session Management**: Secure token handling
- **Admin Approval**: Required for registration
- **QR Code Expiry**: Prevents reuse of old codes
- **User Blocking**: Capability for suspicious activity

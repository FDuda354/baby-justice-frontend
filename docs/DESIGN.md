# Baby Justice — Design Contract

Single source of truth for the backend and the iOS app. Backend DTOs and iOS `Codable` models MUST match this document field by field.

## 1. Product summary

One parent account per family. Children register their own accounts (globally unique login + password) and receive a unique child code; the parent attaches a child to the family by that code (a child belongs to at most one family, and may temporarily belong to none). Children manage their own account (password change, avatar, logout); the parent manages the family: attaching/detaching children, point-scored tasks, per-child reward shops and manual point adjustments. Children accept tasks, mark them done, the parent approves (points granted only then), children buy rewards, the parent hands them out, children confirm receipt.

Roles: `PARENT`, `CHILD`. The child zone and the parent zone are strictly separated (API path prefixes and iOS feature folders).

## 2. Domain model (PostgreSQL, Flyway `V1__Create_schema.sql`)

Conventions: per-entity sequence `{table}_id_sequence`, `BIGINT` ids, lowercase snake_case, Polish `COMMENT ON COLUMN` comments, `TIMESTAMPTZ` for timestamps, FK indexes. All FKs to `family`/`child` use `ON DELETE CASCADE`.

Schema baseline is `V1__Create_schema.sql`; the child-code onboarding changes live in `V2__Child_code_onboarding.sql`; `V3__Child_email_login.sql` renames child.login to email (VARCHAR(150)) and extends password_reset_token to child accounts; `V4__Account_deletion.sql` changes the child.family_id FK to ON DELETE SET NULL (deleting a family must detach children, never delete their accounts). The tables below describe the FINAL state after V4.

### family
- id, name VARCHAR(100) NOT NULL
- created_at TIMESTAMPTZ NOT NULL

### parent_account
- id, family_id FK NOT NULL UNIQUE (one parent per family)
- email VARCHAR(150) NOT NULL UNIQUE (stored trimmed + lowercased)
- password_hash VARCHAR(100) NOT NULL (BCrypt strength 12)
- name VARCHAR(100) NOT NULL
- created_at TIMESTAMPTZ NOT NULL

### child
- id, family_id FK NULL (child may not belong to any family yet; at most one)
- child_code VARCHAR(8) NOT NULL UNIQUE — 6 chars, alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, SecureRandom, regenerate on collision
- name VARCHAR(100) NOT NULL
- birth_date DATE NOT NULL
- email VARCHAR(150) NOT NULL (trimmed + lowercased), UNIQUE globally; must also not collide with any parent_account.email (service-level check, 409)
- password_hash VARCHAR(100) NOT NULL
- points_balance INTEGER NOT NULL DEFAULT 0, CHECK (points_balance >= 0)
- avatar BYTEA NULL, avatar_content_type VARCHAR(50) NULL
- created_at TIMESTAMPTZ NOT NULL

### task
- id, family_id FK NOT NULL
- name VARCHAR(150) NOT NULL, description TEXT NOT NULL DEFAULT ''
- points INTEGER NOT NULL CHECK (points > 0)
- availability VARCHAR(20) NOT NULL — enum `TaskAvailability`: `SHARED` | `ASSIGNED`
- assigned_child_id FK NULL (required when ASSIGNED, null when SHARED)
- recurrence VARCHAR(20) NOT NULL — enum `TaskRecurrence`: `ONE_TIME` | `REPEATABLE`
- status VARCHAR(20) NOT NULL — enum `TaskStatus`: `ACTIVE` | `COMPLETED` | `CANCELLED`
- created_at TIMESTAMPTZ NOT NULL

### task_assignment
- id, task_id FK NOT NULL, child_id FK NOT NULL
- status VARCHAR(20) NOT NULL — enum `AssignmentStatus`: `IN_PROGRESS` | `PENDING_APPROVAL` | `APPROVED` | `REJECTED` | `ABANDONED`
- accepted_at TIMESTAMPTZ NOT NULL, completed_at TIMESTAMPTZ NULL, resolved_at TIMESTAMPTZ NULL
- rejection_reason VARCHAR(500) NULL

### reward
- id, family_id FK NOT NULL, child_id FK NOT NULL (shops are per child)
- name VARCHAR(150) NOT NULL, description TEXT NOT NULL DEFAULT ''
- cost_points INTEGER NOT NULL CHECK (cost_points > 0)
- reward_type VARCHAR(20) NOT NULL — enum `RewardType`: `ONE_TIME` | `REPEATABLE`
- image BYTEA NULL, image_content_type VARCHAR(50) NULL
- status VARCHAR(20) NOT NULL — enum `RewardStatus`: `ACTIVE` | `PURCHASED` | `ARCHIVED`
- created_at TIMESTAMPTZ NOT NULL

### reward_purchase
- id, reward_id FK NOT NULL, child_id FK NOT NULL
- reward_name VARCHAR(150) NOT NULL (snapshot), cost_points INTEGER NOT NULL (snapshot)
- status VARCHAR(20) NOT NULL — enum `PurchaseStatus`: `PENDING_DELIVERY` | `DELIVERED` | `RECEIVED`
- purchased_at TIMESTAMPTZ NOT NULL, delivered_at TIMESTAMPTZ NULL, received_at TIMESTAMPTZ NULL

### points_transaction
- id, child_id FK NOT NULL
- delta INTEGER NOT NULL (positive or negative), balance_after INTEGER NOT NULL
- type VARCHAR(30) NOT NULL — enum `PointsTransactionType`: `TASK_REWARD` | `MANUAL_ADJUSTMENT` | `PURCHASE`
- description VARCHAR(300) NOT NULL
- created_at TIMESTAMPTZ NOT NULL

### notification
- id, family_id FK NOT NULL
- recipient_role VARCHAR(10) NOT NULL — enum `Role`: `PARENT` | `CHILD`
- recipient_child_id FK NULL (set when recipient_role = CHILD)
- type VARCHAR(40) NOT NULL — enum `NotificationType`: `TASK_COMPLETED`, `TASK_APPROVED`, `TASK_REJECTED`, `TASK_CANCELLED`, `REWARD_PURCHASED`, `REWARD_DELIVERED`, `REWARD_RECEIVED`, `POINTS_ADJUSTED`, `CHILD_JOINED`
- message VARCHAR(300) NOT NULL (Polish, composed server-side)
- read_flag BOOLEAN NOT NULL DEFAULT FALSE
- created_at TIMESTAMPTZ NOT NULL

### password_reset_token
- id, parent_account_id FK NULL, child_id FK NULL — CHECK exactly one is set (both ON DELETE CASCADE)
- token VARCHAR(64) NOT NULL UNIQUE, expires_at TIMESTAMPTZ NOT NULL, used BOOLEAN NOT NULL DEFAULT FALSE

## 3. Business lifecycles

### Task availability (what a child sees under "available")
A task is available to child C when: `task.status = ACTIVE`, and (`SHARED` or `ASSIGNED` with `assigned_child_id = C`), and:
- `ONE_TIME`: no assignment exists in `IN_PROGRESS` or `PENDING_APPROVAL` (by anyone).
- `REPEATABLE`: child C has no own assignment in `IN_PROGRESS` or `PENDING_APPROVAL`.

### Task assignment flow
- accept → new assignment `IN_PROGRESS` (validate availability atomically).
- complete (child) → `PENDING_APPROVAL`, sets completed_at, notifies parent (`TASK_COMPLETED`).
- abandon (child, only from `IN_PROGRESS`) → `ABANDONED`; a shared one-time task thereby returns to the pool.
- approve (parent, only from `PENDING_APPROVAL`) → `APPROVED`, resolved_at set, points credited (`TASK_REWARD`, description = task name); if task is `ONE_TIME` → task.status = `COMPLETED`; notifies child (`TASK_APPROVED`).
- reject (parent, reason required) → `REJECTED`; task stays `ACTIVE` (returns to pool); notifies child (`TASK_REJECTED`).
- cancel task (parent) → task.status = `CANCELLED`; all its `IN_PROGRESS`/`PENDING_APPROVAL` assignments → `ABANDONED`; notifies affected children (`TASK_CANCELLED`).
- edit task (parent): allowed only while `ACTIVE`.

### Reward flow
- purchase (child): reward must be `ACTIVE` and belong to the child; balance >= cost, else 400 `InsufficientPointsException`; debit points (`PURCHASE`, description = reward name); purchase `PENDING_DELIVERY`; if reward `ONE_TIME` → reward.status = `PURCHASED`; notifies parent (`REWARD_PURCHASED`).
- deliver (parent, from `PENDING_DELIVERY`) → `DELIVERED`, notifies child (`REWARD_DELIVERED`).
- confirm receipt (child, from `DELIVERED`) → `RECEIVED`, notifies parent (`REWARD_RECEIVED`).
- archive reward (parent): status → `ARCHIVED` (hidden from shop; purchase history intact).

### Family membership
- attach (parent): by child code — 404 unknown code, 409 (`DuplicateResourceException`) when the child already belongs to a family; child is notified (`CHILD_JOINED`, Polish message with the family name).
- detach (parent): child.family becomes null; the child account, its points balance and all history SURVIVE; the child's `IN_PROGRESS`/`PENDING_APPROVAL` assignments become `ABANDONED`; child is notified (`CHILD_REMOVED`) before detaching.
- A family-less child can log in, see the dashboard (hasFamily false, child code, zeroed counts), manage the account; task/shop/purchase lists are empty and accept/purchase are impossible naturally.

### Points
Single choke point — `PointsService` (see §6). Every balance change writes a `points_transaction` row with `balance_after`. Manual adjustment by parent: any delta; resulting balance below zero → 400. Child is notified (`POINTS_ADJUSTED`).

## 4. Auth

Stateless JWT, HS256 via `com.auth0:java-jwt:4.5.0`. Token TTL 30 days. Claims: `sub` = account id (string), `role` = `PARENT`|`CHILD`, `familyId` (long, PARENT tokens ONLY — child tokens carry no familyId claim; every child endpoint loads the `Child` entity by `principal.accountId` and derives the family from it, so attach/detach takes effect without re-login). Secret from `${JWT_SECRET:...long-dev-default...}`.

- Parent registers with family name + own name + email + password.
- Parent login: email + password.
- Child registers itself: name + birth date + email + password; the response carries a generated child code the child gives to the parent.
- Child login: email + password (works also before joining any family).
- Emails are unique ACROSS parent_account and child: registering either account type with an email already used by the other type is a 409 (`DuplicateResourceException`).
- Password reset (parent AND child): request by email — the account is looked up among parents first, then children; email with link/token via SMTP; token TTL 1h, single-use; confirm sets the new password on whichever account owns the token. Request endpoint always returns 204 (no account enumeration). Mail failures are logged, never break the flow (`@Async`).
- Child password change: self-service in the app (current + new).
- The parent CANNOT edit a child's profile, password or avatar — only attach/detach children and adjust points.
- Account deletion (App Store guideline 5.1.1(v)), password-confirmed, both roles: parent deletion removes the family with its tasks, rewards, purchases and notifications and DETACHES all children (their accounts, balances and points history survive); child deletion removes the child account with its assignments, purchases, transactions, notifications and reset tokens. Both log the user out client-side.

Spring Security: `/api/auth/**` permitAll; `/api/parent/**` requires `ROLE_PARENT`; `/api/child/**` requires `ROLE_CHILD`; `/api/images/**` authenticated; everything else denied. Principal = `AuthenticatedUser` record `(Long accountId, Role role, Long familyId)`. Every service method MUST scope queries by the principal's familyId (and childId for child endpoints) — cross-family access returns 404, not 403.

## 5. REST API contract

Base error shape (all non-2xx): `ApiError(String path, String message, int statusCode, Instant timestamp)`.
Exceptions: `ResourceNotFoundException` (404), `DuplicateResourceException` (409), `RequestValidationException` (400), `UnauthorizedAccessException` (401), `InsufficientPointsException` (400), `TaskNotAvailableException` (409), `IllegalTransitionException` (409).

All timestamps on the wire: ISO-8601 UTC `Instant` truncated to seconds (e.g. `2026-07-03T17:20:11Z`) — truncate in mappers with `truncatedTo(ChronoUnit.SECONDS)`. Dates (`birthDate`): `yyyy-MM-dd`.

Images travel as base64 strings in JSON on upload, raw bytes (proper Content-Type) on download. Uploads are re-validated: max 2 MB decoded, content type in {image/jpeg, image/png, image/heic}.

### Shared DTOs (Java records; names and fields are binding for iOS models too)
- `AuthResponse(String token, Role role, Long accountId, Long familyId, String familyName, String displayName, String childCode)` (familyId/familyName null for unattached children; childCode null for parents)
- `FamilyDTO(Long id, String name, String parentName, String parentEmail)`
- `ChildDTO(Long id, String name, LocalDate birthDate, String email, String childCode, String familyName, int pointsBalance, boolean hasAvatar, Instant createdAt)` (familyName null when unattached)
- `ChildSummaryDTO(Long id, String name, int pointsBalance, boolean hasAvatar, int activeTasksCount, int pendingApprovalsCount, int pendingDeliveriesCount)`
- `TaskDTO(Long id, String name, String description, int points, TaskAvailability availability, Long assignedChildId, String assignedChildName, TaskRecurrence recurrence, TaskStatus status, Instant createdAt)`
- `TaskAssignmentDTO(Long id, Long taskId, String taskName, int points, Long childId, String childName, AssignmentStatus status, Instant acceptedAt, Instant completedAt, Instant resolvedAt, String rejectionReason)`
- `TaskDetailsDTO(TaskDTO task, List<TaskAssignmentDTO> assignments)` (assignments newest first)
- `RewardDTO(Long id, Long childId, String name, String description, int costPoints, RewardType rewardType, RewardStatus status, boolean hasImage, Instant createdAt)`
- `RewardPurchaseDTO(Long id, Long rewardId, String rewardName, Long childId, String childName, int costPoints, PurchaseStatus status, boolean rewardHasImage, Instant purchasedAt, Instant deliveredAt, Instant receivedAt)`
- `PointsTransactionDTO(Long id, Long childId, String childName, int delta, int balanceAfter, PointsTransactionType type, String description, Instant createdAt)`
- `NotificationDTO(Long id, NotificationType type, String message, boolean read, Instant createdAt)`
- `ParentDashboardDTO(String familyName, int pendingApprovalsCount, int pendingDeliveriesCount, int unreadNotificationsCount, List<ChildSummaryDTO> children)`
- `ChildDashboardDTO(String name, int pointsBalance, boolean hasAvatar, boolean hasFamily, String familyName, String childCode, int availableTasksCount, int activeTasksCount, int pendingApprovalsCount, int deliveredPurchasesCount, int unreadNotificationsCount, List<PointsTransactionDTO> recentTransactions)` (recent = 5 newest; familyName null and counts zero when hasFamily false)

DTO mapping: static factory on the record, e.g. `TaskDTO.from(Task task)`; aggregate DTOs built in services.

### Endpoints

Public (`/api/auth`):
| Method | Path | Body → Response |
|---|---|---|
| POST | /api/auth/parent/register | `ParentRegisterRequest(String familyName, String parentName, String email, String password)` → `AuthResponse` (password min 8) |
| POST | /api/auth/parent/login | `ParentLoginRequest(String email, String password)` → `AuthResponse` |
| POST | /api/auth/child/register | `ChildRegisterRequest(String name, LocalDate birthDate, String email, String password)` → `AuthResponse` (email unique across parents+children, password min 4) |
| POST | /api/auth/child/login | `ChildLoginRequest(String email, String password)` → `AuthResponse` |
| POST | /api/auth/password-reset/request | `PasswordResetRequest(String email)` → 204 |
| POST | /api/auth/password-reset/confirm | `PasswordResetConfirmRequest(String token, String newPassword)` → 204 |

Parent zone (`/api/parent`, ROLE_PARENT):
| Method | Path | Body → Response |
|---|---|---|
| GET | /dashboard | → `ParentDashboardDTO` |
| GET | /family | → `FamilyDTO` |
| PUT | /family | `UpdateFamilyRequest(String name)` → `FamilyDTO` |
| PUT | /account/password | `ChangePasswordRequest(String currentPassword, String newPassword)` → 204 |
| POST | /account/delete | `DeleteAccountRequest(String password)` → 204 (401 wrong password; deletes family + parent, detaches children) |
| GET | /children | → `List<ChildDTO>` |
| POST | /children | `AddChildRequest(String childCode)` → `ChildDTO` (404 unknown code, 409 child already in a family) |
| GET | /children/{childId} | → `ChildDTO` |
| DELETE | /children/{childId} | → 204 (detach from family per §3 Family membership) |
| POST | /children/{childId}/points | `AdjustPointsRequest(int delta, String description)` → `ChildDTO` |
| GET | /tasks?status={TaskStatus?} | → `List<TaskDTO>` (no param = all, newest first) |
| POST | /tasks | `CreateTaskRequest(String name, String description, int points, TaskAvailability availability, Long assignedChildId, TaskRecurrence recurrence)` → `TaskDTO` |
| GET | /tasks/{taskId} | → `TaskDetailsDTO` |
| PUT | /tasks/{taskId} | `CreateTaskRequest` → `TaskDTO` |
| POST | /tasks/{taskId}/cancel | → 204 |
| GET | /approvals | → `List<TaskAssignmentDTO>` (PENDING_APPROVAL, oldest first) |
| POST | /approvals/{assignmentId}/approve | → 204 |
| POST | /approvals/{assignmentId}/reject | `RejectAssignmentRequest(String reason)` → 204 |
| GET | /children/{childId}/rewards?includeArchived={bool=false} | → `List<RewardDTO>` |
| POST | /children/{childId}/rewards | `CreateRewardRequest(String name, String description, int costPoints, RewardType rewardType, String imageBase64, String imageContentType)` (image nullable) → `RewardDTO` |
| GET | /rewards/{rewardId} | → `RewardDTO` |
| PUT | /rewards/{rewardId} | `CreateRewardRequest` → `RewardDTO` |
| POST | /rewards/{rewardId}/archive | → 204 |
| GET | /deliveries | → `List<RewardPurchaseDTO>` (PENDING_DELIVERY, oldest first) |
| POST | /deliveries/{purchaseId}/deliver | → 204 |
| GET | /history/points?childId={optional} | → `List<PointsTransactionDTO>` (newest first) |
| GET | /history/purchases?childId={optional} | → `List<RewardPurchaseDTO>` (newest first) |
| GET | /history/tasks?childId={optional} | → `List<TaskAssignmentDTO>` (APPROVED/REJECTED/ABANDONED, newest first) |
| GET | /notifications | → `List<NotificationDTO>` (newest first, cap 100) |
| POST | /notifications/mark-read | → 204 (marks all) |

Child zone (`/api/child`, ROLE_CHILD):
| Method | Path | Body → Response |
|---|---|---|
| GET | /dashboard | → `ChildDashboardDTO` |
| GET | /profile | → `ChildDTO` |
| PUT | /account/password | `ChangeChildPasswordRequest(String currentPassword, String newPassword)` → 204 (401 on wrong current) |
| POST | /account/delete | `DeleteAccountRequest(String password)` → 204 (401 wrong password; deletes the child account and its data) |
| PUT | /avatar | `ImageUploadRequest(String imageBase64, String contentType)` → 204 |
| DELETE | /avatar | → 204 |
| GET | /tasks/available | → `List<TaskDTO>` |
| POST | /tasks/{taskId}/accept | → `TaskAssignmentDTO` |
| GET | /tasks/mine | → `List<TaskAssignmentDTO>` (IN_PROGRESS + PENDING_APPROVAL) |
| POST | /assignments/{assignmentId}/complete | → `TaskAssignmentDTO` |
| POST | /assignments/{assignmentId}/abandon | → 204 |
| GET | /rewards | → `List<RewardDTO>` (own shop, ACTIVE only) |
| POST | /rewards/{rewardId}/purchase | → `RewardPurchaseDTO` |
| GET | /purchases | → `List<RewardPurchaseDTO>` (own, newest first) |
| POST | /purchases/{purchaseId}/confirm-receipt | → `RewardPurchaseDTO` |
| GET | /history/points | → `List<PointsTransactionDTO>` |
| GET | /history/tasks | → `List<TaskAssignmentDTO>` (resolved) |
| GET | /notifications | → `List<NotificationDTO>` |
| POST | /notifications/mark-read | → 204 |

Images (authenticated, any role; access scoped to own family, children can fetch only their own resources):
| GET | /api/images/children/{childId}/avatar | → image bytes or 404 |
| GET | /api/images/rewards/{rewardId} | → image bytes or 404 |

## 6. Backend structure (separate repo `/Users/needxmafia/IdeaProjects/baby-justice-backend`, base package `pl.dudios.babyjustice`)

Spring Boot 4.0.5, Java 25 toolchain, Gradle Kotlin DSL (wrapper copied from hercu-pulpit). Dependencies: web, data-jpa, security, validation, mail, flyway starter, postgresql (runtime), lombok, `com.auth0:java-jwt:4.5.0`. Tests (added on Filip's explicit request): unit tests per ~/.claude/skills/java-test rules (BDDMockito, AssertJ, @Nested, boundaries-only mocking); integration tests on Testcontainers Postgres mirroring hercu-pulpit's AbstractIntegrationTest; Gradle `test` task excludes `*IntegrationTest`, a separate `integrationTest` task runs them (requires Docker).

`application.yml`: port 8080; datasource `jdbc:postgresql://${DB_HOST:localhost}:${DB_PORT:5435}/baby_justice`, user `${DB_USER:filip}`, password `${DB_PASSWORD:myszomen354}`; jpa `ddl-auto: validate`, open-in-view false; flyway enabled; mail host `mail.dudios.pl` port 465 username `no-reply@dudios.pl` password `${MAIL_PASSWORD:}` with smtp auth+ssl (trust `mail.dudios.pl`); `jwt.secret: ${JWT_SECRET:<64-char dev default>}`, `jwt.ttl-days: 30`; `app.reset-link-base-url: ${RESET_LINK_BASE_URL:https://baby-justice.dudios.pl/reset-password}`.

Feature-package layout and ownership (each fan-out agent stays inside its own packages):

```
pl.dudios.babyjustice
├── BabyJusticeApplication            [infra]
├── exception/** (+ handler/DefaultExceptionHandler, handler/ApiError)  [infra]
├── security/config/**, security/jwt/** (JwtService, JwtAuthenticationFilter, AuthenticatedUser)  [infra]
├── mail/MailService (@Async, never throws)  [infra]
├── common/ImageValidator  [infra]
├── family/model/Family, family/repository/FamilyRepository  [base]
├── children/model/Child, children/repository/ChildRepository  [base]
├── task/model/{Task,TaskAssignment,enums}, task/repository/**  [base]
├── reward/model/{Reward,RewardPurchase,enums}, reward/repository/**  [base]
├── points/model/{PointsTransaction,PointsTransactionType}, points/repository/**, points/service/PointsService  [base]
├── notification/model/**, notification/repository/**, notification/service/NotificationService  [base]
├── auth/** (AuthController, AuthService, PasswordResetService, request records, password_reset_token model+repo)  [agent auth]
├── family/controller/FamilyController, family/service/FamilyService  [agent auth]
├── children/controller/ChildrenController, children/service/ChildrenService, children/model/request/**  [agent children]
├── task/controller/{TaskController,ApprovalController,ChildTaskController}, task/service/{TaskService,AssignmentService}  [agent tasks]
├── reward/controller/{RewardController,DeliveryController,ChildShopController,ImagesController}, reward/service/{RewardService,PurchaseService}  [agent rewards]
├── dashboard/controller/**, dashboard/service/**  [agent overview]
├── notification/controller/NotificationController  [agent overview]
├── history/controller/HistoryController (parent) + ChildHistoryController  [agent overview]
```

All shared DTO records from §5 live in `{owning-feature}/model/dto/` and are created by the [base] stage: ChildDTO/ChildSummaryDTO in children, TaskDTO/TaskAssignmentDTO/TaskDetailsDTO in task, RewardDTO/RewardPurchaseDTO in reward, PointsTransactionDTO in points, NotificationDTO in notification, FamilyDTO/AuthResponse in family/auth, dashboard DTOs in dashboard.

Cross-domain services (created by [base], used by everyone — exact signatures binding):
```java
public class PointsService {
    @Transactional public PointsTransaction credit(Long childId, int amount, PointsTransactionType type, String description);
    @Transactional public PointsTransaction debit(Long childId, int amount, PointsTransactionType type, String description); // throws InsufficientPointsException
    @Transactional public PointsTransaction adjust(Long childId, int delta, String description); // manual, may be negative
}
public class NotificationService {
    public void notifyParent(Long familyId, NotificationType type, String message);
    public void notifyChild(Long familyId, Long childId, NotificationType type, String message);
}
```

House style: records for DTO/requests with Jakarta validation; entities Lombok `@Data @Builder @NoArgsConstructor @AllArgsConstructor @Entity`; `@RequiredArgsConstructor` services (concrete, no interfaces); `@Transactional` on mutating methods; `@RestController @RequestMapping("api/...")`; `ResponseEntity<T>`; custom exceptions with `@ResponseStatus`; NO code comments; small single-purpose methods; notification/mail texts in Polish.

## 7. iOS app structure (`baby-justice/` at the repo root, min iOS 17, SwiftUI)

The Xcode project uses a file-system-synchronized group: creating a file on disk adds it to the target. Delete `ContentView.swift` in the core stage.

```
baby-justice/
├── baby_justiceApp.swift          → @main, injects SessionStore, shows RootView   [core]
├── RootView.swift                 → switches Landing / ParentRootView / ChildRootView on session state  [core]
├── Core/
│   ├── Config/AppConfig.swift     → baseURL fixed per build configuration: #if DEBUG http://localhost:8080, #else https://baby-justice.dudios.pl; NO runtime override  [core]
│   ├── Networking/APIClient.swift, APIError.swift  → one method per endpoint of §5, async/await, JSON ISO8601 dates  [core]
│   ├── Session/SessionStore.swift (@Observable: token, role, displayName, familyCode; login/logout), KeychainStorage.swift  [core]
│   ├── Models/Models.swift        → all Codable structs + enums mirroring §5 DTOs (String-backed enums)  [core]
│   ├── DesignSystem/Theme.swift + Components/ (PrimaryButton, SecondaryButton, CardView, PointsBadge, StatusChip, EmptyStateView, ErrorBanner, LoadingOverlay, AvatarView, RemoteImageView, FormTextField, SectionHeader)  [core]
│   └── Utils/Formatters.swift     → date/points Polish formatting helpers  [core]
├── Features/
│   ├── Help/HelpView.swift          (zone-neutral in-app manual, linked from ParentSettingsView and ChildProfileView: founding a family and adding children by child code, tasks & points lifecycle, rewards flow)
│   ├── Landing/LandingView.swift  (hero + exactly TWO buttons: "Zaloguj się" and "Zarejestruj się"; no server-address UI)  [agent auth-ui]
│   ├── Auth/ (LoginView — single email+password form with a segmented role toggle "Rodzic"/"Dziecko" choosing the endpoint, plus "Nie pamiętam hasła" link; RegisterView — same role toggle switching between the parent form (family name, name, email, password) and the child form (name, birth date, email, password) followed by the child-code success screen; ForgotPasswordView — one email field, works for both roles; AuthViewModel)  [agent auth-ui]
│   ├── Parent/
│   │   ├── ParentRootView.swift   → TabView: Panel, Zadania, Dzieci, Nagrody, Więcej  [core]
│   │   ├── Dashboard/  (ParentDashboardView + VM: counters → quick links, children cards)  [agent parent-dash]
│   │   ├── Children/   (ChildrenListView, AddChildByCodeView — single child-code field, ChildDetailsView — points adjust + detach only, AdjustPointsView; NO editing of child profile/password/avatar)  [agent parent-dash]
│   │   ├── Tasks/      (ParentTasksView list+filters, AddTaskView, EditTaskView, TaskDetailsView, ApprovalsView, approve/reject sheet)  [agent parent-tasks]
│   │   ├── Rewards/    (child picker → RewardsListView, AddRewardView, EditRewardView, RewardDetailsView, DeliveriesView)  [agent parent-rewards]
│   │   ├── History/    (segmented: punkty / zakupy / zadania, child filter)  [agent parent-more]
│   │   ├── Notifications/ (NotificationsListView)  [agent parent-more]
│   │   └── Settings/   (family name, parent password change, logout)  [agent parent-more]
│   └── Child/
│       ├── ChildRootView.swift    → TabView: Start, Zadania, Sklep, Historia, Profil  [core]
│       ├── Profile/    (ChildProfileView: avatar via PhotosPicker + delete, change-password sheet with current+new, child code card with copy, family status, logout with confirmation)  [agent child-tasks]
│       ├── Dashboard/  (hero points card, active tasks, quick actions)  [agent child-tasks]
│       ├── Tasks/      (AvailableTasksView, MyTasksView, TaskDetailView, complete/abandon)  [agent child-tasks]
│       ├── Shop/       (ShopView grid, RewardDetailView, purchase confirmation)  [agent child-shop]
│       ├── Purchases/  (PurchasesView: awaiting delivery / to confirm / received)  [agent child-shop]
│       ├── History/    (points + resolved tasks, segmented)  [agent child-shop]
│       └── Notifications/ (bell from dashboard)  [agent child-tasks]
```

### iOS conventions
- View models: `@Observable` classes (`Observation` framework), owned by views via `@State`; async work with `.task {}` and `Task {}`; main-actor by default (project setting) — do not add `@MainActor` manually.
- iOS 17-compatible APIs ONLY: `NavigationStack`, `.tabItem` TabView style (NOT the iOS 18 `Tab` builder), `.onChange(of:) { old, new in }`, `PhotosPicker`, `.refreshable`, `.searchable`. No `@Query`/SwiftData, no UIKit.
- All code and identifiers in English; ALL user-visible strings in Polish (hardcoded, no localization catalogs).
- NO code comments. Small, well-named views and functions; extract subviews instead of nesting deeply.
- Every screen handles: loading (ProgressView), error (ErrorBanner with retry), empty (EmptyStateView with friendly Polish copy).
- `RemoteImageView` fetches via APIClient (auth header) — plain AsyncImage cannot send the JWT.
- Child zone visual language: bigger, bolder, more playful (but not babyish); parent zone: clean management panel. Both share Theme.

### Theme (Theme.swift, binding values)
- `Color.bjPrimary` #2FA96C (green), `bjPrimaryDark` #1D7A4C, `bjMint` #E6F4EC (tinted backgrounds), `bjAmber` #F5A623 (points), `bjDanger` #D64545, `bjInk` #17251D (dark text), adaptive backgrounds from system colors.
- Points always shown with a filled `star.circle.fill` in bjAmber next to the number.
- Cards: rounded 16, subtle shadow; primary buttons: bjPrimary background, white text, rounded 14, height 50.
- SF Symbols everywhere; tab icons: house.fill, checklist, person.2.fill, gift.fill, ellipsis.circle.fill (parent) / house.fill, checklist, storefront.fill (fallback: bag.fill), clock.fill, person.crop.circle.fill (child).

### Status chip colors and Polish labels
- Assignment: IN_PROGRESS "W trakcie" (blue), PENDING_APPROVAL "Czeka na akceptację" (amber), APPROVED "Zaliczone" (green), REJECTED "Odrzucone" (red), ABANDONED "Porzucone" (gray).
- Purchase: PENDING_DELIVERY "Do wydania" (amber), DELIVERED "Wydana — potwierdź odbiór" (blue), RECEIVED "Odebrana" (green).
- Task: ACTIVE "Aktywne", COMPLETED "Zakończone", CANCELLED "Anulowane".
- Availability: SHARED "Wspólne", ASSIGNED "Przypisane"; recurrence: ONE_TIME "Jednorazowe", REPEATABLE "Powtarzalne"; reward type: ONE_TIME "Jednorazowa", REPEATABLE "Powtarzalna".

## 8. Verification commands

- Backend: `cd /Users/needxmafia/IdeaProjects/baby-justice-backend && ./gradlew assemble`; unit tests `./gradlew test`, integration tests `./gradlew integrationTest` (Docker required). Write new tests only when Filip explicitly asks.
- iOS: `xcodebuild -project baby-justice.xcodeproj -scheme baby-justice -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO` (run from the repo root).
- Git is read-only. No Python scripts.

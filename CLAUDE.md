# Baby Justice

Family chores-and-rewards app: a parent creates point-scored tasks, children complete them, the parent approves, children spend points in their individual reward shops.

## Repository layout

- Repo root IS the Xcode project: `baby-justice.xcodeproj` + `baby-justice/` (Swift sources) + `Info.plist`. Native iOS app, SwiftUI, min iOS 17. The project uses file-system-synchronized groups: any `.swift` file placed under `baby-justice/` is automatically part of the target.
- The backend moved to its OWN repo: `/Users/needxmafia/IdeaProjects/baby-justice-backend` — Spring Boot 4 REST API, Java 25, Gradle Kotlin DSL, PostgreSQL (localhost:5435, db `baby_justice`), Flyway migrations. Changes there are allowed.
- `docs/DESIGN.md` — domain model and REST API contract for BOTH repos. The single source of truth; keep backend and iOS models in sync with it.

## Build commands

- Backend: `cd /Users/needxmafia/IdeaProjects/baby-justice-backend && ./gradlew assemble` (unit tests: `./gradlew test`; integration, needs Docker: `./gradlew integrationTest`)
- iOS: `xcodebuild -project baby-justice.xcodeproj -scheme baby-justice -destination 'platform=iOS Simulator,name=iPhone 17' build CODE_SIGNING_ALLOWED=NO`

## Collaboration rules (binding, set by Filip)

1. When something is unclear, contradictory, or blocking — ask Filip instead of guessing.
2. Chat with Filip in Polish; all code, identifiers, and code documentation in English. User-facing UI strings are Polish.
3. Commit message for a library/mini-app version bump: `{libraryName} -> {newVersion}`.
4. Be bold: if a new feature calls for a refactor, do the refactor with it — unless Filip explicitly asks for a backward-compatible, minimal change.
5. NEVER write or fix tests unless explicitly asked.
6. After changes, verify the project compiles.
7. Git is read-only: never commit, push, stage, or otherwise mutate repository state.
8. Never create Python scripts without asking for permission first.
9. No code comments unless explicitly requested.
10. Code should read like a good book — method names say what they do; one responsibility per method (unless it is two lines).

## Backend conventions (mirrors ~/IdeaProjects/hercu-pulpit)

- Base package `pl.dudios.babyjustice`, organized by feature/domain: `{feature}/controller|service|repository|model`.
- DTOs and requests are Java records with Jakarta validation annotations; entities are Lombok classes (`@Data @Builder @NoArgsConstructor @AllArgsConstructor`).
- Concrete `@Service` classes (no interfaces), `@RequiredArgsConstructor` injection, `@Transactional` on state-changing methods.
- Errors via `@ControllerAdvice` + `@ResponseStatus` custom exceptions extending `RuntimeException`.
- Flyway migrations `V{n}__Description.sql` with per-entity sequences and Polish column comments.
- Auth deviation from hercu-pulpit: stateless JWT (mobile client), not sessions.

## iOS conventions

- SwiftUI, MVVM with `@Observable` view models, async/await networking, iOS 17-compatible APIs only.
- Strict zone separation: `Features/Parent/**` and `Features/Child/**` never import from each other; shared code lives in `Core/`.
- Green-accented, modern, non-childish visual style (audience: kids 6–18 and their parent).

## Secrets

`MAIL_PASSWORD` is an environment variable for the backend process (never in Xcode or the iOS app). Dev database credentials have safe defaults in `application.yml`.

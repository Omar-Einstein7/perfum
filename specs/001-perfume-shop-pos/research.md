# Research: Perfume Shop POS & Management System

**Phase 0 — All NEEDS CLARIFICATION resolved via execution-plan.md + clarification session**

## Decisions

| Topic | Decision | Rationale | Alternatives Considered |
|-------|----------|-----------|------------------------|
| Session timeout | Persists while shift open; no expiry while offline | Offline-first operation; single-device-per-branch eliminates theft risk | Fixed 8h expiry; offline grace period |
| Sync trigger | Auto on connectivity change + 60s polling | Zero-touch for cashiers; guarantees pending writes don't accumulate | Manual-only; push-on-every-write |
| Tax/VAT | 14% VAT, tax-inclusive pricing | Egyptian retail standard; prices include VAT by law | Tax-exclusive; configurable per branch |
| Multi-device concurrency | Single device per branch | Constitutional branch independence; eliminates conflict probability | 1-2 devices; 3+ devices |
| ORM choice | Deferred to implementation (Prisma or Sequelize) | Backend implementation detail | — |
| Local DB | Hive CE (existing project stack) | Already wired via HiveService.instance | drift/sqflite (per execution plan) |
| DI | BlocProvider/RepositoryProvider (existing) | Already established project pattern | GetIt (per execution plan) |
| Error handling | Existing Failure classes + runTask() + FutureEither | Already established project pattern | — |
| User feedback | Existing showGlobalToast() / showAppDialog() | Already established project pattern | — |

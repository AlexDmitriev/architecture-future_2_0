# Моделирование домена и интеграций

DDD-декомпозиция, событийная архитектура и обоснование.

## Документы

| Файл | Описание |
| --- | --- |
| [bounded-contexts.drawio](bounded-contexts.drawio) | Схема bounded contexts и связей между доменами |
| [event-storming.drawio](event-storming.drawio) | Event Storming: события, команды, политики, подписчики |
| [aggregates.md](aggregates.md) | Агрегаты: границы, инварианты, ключи |
| [events.md](events.md) | Каталог доменных событий с контрактами |
| [justification.md](justification.md) | Обоснование событийного подхода vs Camel/DWH |

## Домены и bounded contexts

| Домен | Bounded contexts | Тип |
| --- | --- | --- |
| Healthcare | Patient Management, Clinical Care, Diagnostics, Billing, Workforce | Core / Supporting |
| Fintech | Retail Banking, Lending | Core |
| Medical AI | Medical AI | Core |
| Partners | Partner Commerce, Inventory & Supply | Generic |
| Cross-cutting | Identity & Customer Master | Shared Kernel |
| Analytics | Analytics & Self-Service (витрина) |  |

## Ключевые сквозные процессы (Event Storming)

1.  **Пациентский поток:** `PatientRegistered` → `AppointmentScheduled` → `MedicalEncounterCompleted`
2.  **Диагностика и ИИ:** `DiagnosticStudyCompleted` → `AIAnalysisCompleted` → `TreatmentPlanRecommended`
3.  **Финтех:** `KYCCompleted` → `CreditAgreementCreated` → `LoanDisbursed` → `PaymentReceived`
4.  **Партнёры:** `PartnerOrderPlaced` → `InventoryReserved` → `PartnerOrderDelivered`

Все события публикуются в Event Bus; Analytics подписывается только на агрегированные факты без медицинских карт.
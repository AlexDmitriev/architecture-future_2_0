# Агрегаты доменной модели

Описание ключевых агрегатов по bounded contexts. Каждый агрегат — граница транзакционной согласованности; между агрегатами и доменами — только доменные события или ACL.

---

## 1\. Patient Management (Управление пациентами)

**Bounded context:** идентификация пациента, согласия, контактные данные. Не содержит клинической истории.

### Агрегат: `Patient`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `Patient` |
| **ID** | `patientId` (UUID) |
| **Состав** | `PersonalData`, `Consent[]`, `ContactInfo` |

**Инварианты:**

-   Пациент не может быть удалён физически — только деактивация (`status = inactive`).
-   Согласие на обработку мед. данных обязательно перед передачей в Medical AI.
-   `nationalId` (СНИЛС/паспорт) уникален в пределах региона.

**Команды:** `RegisterPatient`, `UpdateContactInfo`, `GrantConsent`, `RevokeConsent`

**События:** `PatientRegistered`, `PatientConsentGranted`, `PatientDeactivated`

---

## 2\. Clinical Care (Клиническое обслуживание)

**Bounded context:** приёмы, эпизоды лечения, назначения. Операционные мед. данные.

### Агрегат: `MedicalEpisode`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `MedicalEpisode` |
| **ID** | `episodeId` |
| **Состав** | `Encounter[]`, `Diagnosis[]`, `Prescription[]` |
| **Внешние ссылки** | `patientId` (только ID, без денормализации PHI) |

**Инварианты:**

-   Эпизод привязан ровно к одному `patientId`.
-   Закрытый эпизод (`status = closed`) не принимает новые `Encounter`.
-   Диагноз фиксируется только лицензированным врачом (`physicianId`).

**Команды:** `OpenEpisode`, `RecordEncounter`, `CloseEpisode`

**События:** `MedicalEncounterCompleted`, `EpisodeClosed`

### Агрегат: `Appointment`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `Appointment` |
| **ID** | `appointmentId` |
| **Состав** | `slot`, `physicianId`, `clinicId`, `status` |

**Инварианты:**

-   Один слот — один активный приём.
-   Отмена возможна не позднее чем за N часов (доменное правило клиники).

**События:** `AppointmentScheduled`, `AppointmentCancelled`

---

## 3\. Diagnostics (Диагностика)

**Bounded context:** заказ и результат исследований (МРТ, анализы, снимки).

### Агрегат: `DiagnosticStudy`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `DiagnosticStudy` |
| **ID** | `studyId` |
| **Состав** | `StudyOrder`, `StudyResult?`, `attachments[]` |
| **Внешние ссылки** | `patientId`, `episodeId` |

**Инварианты:**

-   Результат публикуется только после верификации (`verifiedBy`).
-   Сырые DICOM/изображения не покидают контекст без шифрования и ссылки, не через события в Analytics.

**События:** `DiagnosticStudyOrdered`, `DiagnosticStudyCompleted`

---

## 4\. Medical AI (Медицинский ИИ)

**Bounded context:** inference, рекомендации. Не владеет мед. картой — потребляет события.

### Агрегат: `AIAnalysisJob`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `AIAnalysisJob` |
| **ID** | `jobId` |
| **Состав** | `modelVersion`, `inputRef`, `result?`, `confidence` |
| **Внешние ссылки** | `studyId`, `patientId` (через токенизированную ссылку) |

**Инварианты:**

-   Запуск только при наличии `PatientConsentGranted` для AI.
-   Результат — рекомендация, не финальный диагноз (`type = recommendation`).
-   Модель версионируется; `modelVersion` обязателен в событии.

**События:** `AIAnalysisStarted`, `AIAnalysisCompleted`, `TreatmentPlanRecommended`

---

## 5\. Retail Banking (Банковские операции)

**Bounded context:** счета, платежи, карты.

### Агрегат: `BankAccount`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `BankAccount` |
| **ID** | `accountId` |
| **Состав** | `balance`, `currency`, `holds[]`, `transactions[]` |
| **Внешние ссылки** | `customerId` (маппинг на `patientId` через Identity ACL) |

**Инварианты:**

-   Баланс не может быть отрицательным без одобренного овердрафта.
-   Каждая транзакция идемпотентна по `idempotencyKey`.

**События:** `AccountOpened`, `PaymentReceived`, `PaymentFailed`

---

## 6\. Lending (Кредитование)

**Bounded context:** кредитные договоры, выдача, погашение.

### Агрегат: `CreditAgreement`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `CreditAgreement` |
| **ID** | `agreementId` |
| **Состав** | `terms`, `schedule[]`, `status`, `disbursements[]` |
| **Внешние ссылки** | `customerId`, `accountId` |

**Инварианты:**

-   Сумма договора ≤ лимита скоринга на момент создания.
-   Переход `draft → active` только после подписания и проверки KYC.
-   Погашение обновляет график атомарно внутри агрегата.

**Команды:** `CreateCreditAgreement`, `SignAgreement`, `DisburseLoan`, `RecordRepayment`

**События:** `CreditAgreementCreated`, `LoanDisbursed`, `LoanRepaid`, `LoanDefaulted`

---

## 7\. Billing (Биллинг клиник)

**Bounded context:** счета за мед. услуги.

### Агрегат: `Invoice`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `Invoice` |
| **ID** | `invoiceId` |
| **Состав** | `lineItems[]`, `total`, `status` |
| **Внешние ссылки** | `patientId`, `episodeId?` |

**Инварианты:**

-   Сумма строк = `total`.
-   Оплаченный счёт (`paid`) не редактируется.

**События:** `InvoiceIssued`, `InvoicePaid`, `InvoiceCancelled`

---

## 8\. Inventory & Supply (Склад и поставки)

**Bounded context:** инвентаризация, расходники, оборудование.

### Агрегат: `InventoryItem`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `InventoryItem` |
| **ID** | `skuId` + `warehouseId` |
| **Состав** | `quantity`, `reservedQty`, `reorderLevel` |

**Инварианты:**

-   `quantity - reservedQty ≥ 0`.
-   Списание только при подтверждённом резервировании.

**События:** `InventoryReserved`, `InventoryDepleted`, `StockReplenished`

---

## 9\. Partner Commerce (Партнёрская интеграция)

**Bounded context:** заказы фармы и производителя оборудования.

### Агрегат: `PartnerOrder`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `PartnerOrder` |
| **ID** | `orderId` |
| **Состав** | `partnerId`, `items[]`, `deliveryStatus` |

**Инварианты:**

-   Партнёр авторизован в реестре (`partnerId` из whitelist).
-   Отмена после отгрузки запрещена.

**События:** `PartnerOrderPlaced`, `PartnerOrderDelivered`

---

## 10\. Analytics & Self-Service (Витрина данных)

**Bounded context:** агрегированные KPI, отчёты. **Не агрегаты операционных данных** — проекции (read models).

### Проекция: `PatientFlowDailyStats` (не классический агрегат)

| Атрибут | Описание |
| --- | --- |
| **ID** | `date + clinicId` |
| **Источник** | подписка на `PatientRegistered`, `AppointmentScheduled`, `MedicalEncounterCompleted` |
| **Инварианты** | не содержит PHI; только счётчики и агрегаты |

### Проекция: `LendingPortfolioSnapshot`

| Атрибут | Описание |
| --- | --- |
| **ID** | `snapshotDate` |
| **Источник** | `CreditAgreementCreated`, `LoanDisbursed`, `LoanRepaid` |

---

## 11\. Identity & Customer Master (Shared Kernel / Supporting)

**Bounded context:** единый `customerId` ↔ `patientId` маппинг для сквозных процессов.

### Агрегат: `CustomerIdentity`

| Атрибут | Описание |
| --- | --- |
| **Корень** | `CustomerIdentity` |
| **ID** | `customerId` |
| **Состав** | `patientId?`, `bankClientId?`, `kycStatus` |

**Инварианты:**

-   Один `patientId` — максимум один активный `customerId`.
-   KYC обязателен перед событиями в Lending.

**События:** `CustomerIdentityLinked`, `KYCCompleted`
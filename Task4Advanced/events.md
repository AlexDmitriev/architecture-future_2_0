# Каталог доменных событий

События — единственный способ междоменной интеграции в целевой архитектуре. Формат контракта: CloudEvents 1.0 + Avro/JSON Schema в Schema Registry.

Обозначения:

-   **Источник** — bounded context, публикующий событие
-   **Подписчики** — контексты, реагирующие на событие (асинхронно)

---

## Patient Management

### `PatientRegistered`

| Поле | Значение |
| --- | --- |
| **Источник** | Patient Management |
| **Семантика** | В системе зарегистрирован новый пациент |
| **Подписчики** | Identity & Customer Master, Analytics (агрегат счётчика), Billing |

**Минимальный контракт:**

```json
{
  "eventType": "PatientRegistered",
  "eventId": "uuid",
  "occurredAt": "2026-06-17T10:00:00Z",
  "patientId": "uuid",
  "clinicId": "string",
  "region": "string"
}
```

*PHI (ФИО, документы) в событие не включается.*

---

### `PatientConsentGranted`

| Поле | Значение |
| --- | --- |
| **Источник** | Patient Management |
| **Семантика** | Пациент дал согласие на обработку данных (в т.ч. для AI) |
| **Подписчики** | Medical AI, Clinical Care |

```json
{
  "eventType": "PatientConsentGranted",
  "patientId": "uuid",
  "consentType": "medical_ai | data_processing",
  "validUntil": "2027-06-17T00:00:00Z"
}
```

---

## Clinical Care

### `AppointmentScheduled`

| Поле | Значение |
| --- | --- |
| **Источник** | Clinical Care |
| **Семантика** | Запланирован приём пациента |
| **Подписчики** | Workforce (нагрузка врача), Analytics, Billing (предварительная оценка) |

```json
{
  "eventType": "AppointmentScheduled",
  "appointmentId": "uuid",
  "patientId": "uuid",
  "physicianId": "uuid",
  "clinicId": "string",
  "scheduledAt": "2026-06-20T14:00:00Z"
}
```

---

### `MedicalEncounterCompleted`

| Поле | Значение |
| --- | --- |
| **Источник** | Clinical Care |
| **Семантика** | Приём завершён, зафиксированы итоги эпизода |
| **Подписчики** | Diagnostics, Billing, Medical AI, Analytics |

```json
{
  "eventType": "MedicalEncounterCompleted",
  "episodeId": "uuid",
  "patientId": "uuid",
  "encounterId": "uuid",
  "clinicId": "string",
  "completedAt": "2026-06-17T11:30:00Z",
  "procedureCodes": ["A01", "B12"]
}
```

---

## Diagnostics

### `DiagnosticStudyCompleted`

| Поле | Значение |
| --- | --- |
| **Источник** | Diagnostics |
| **Семантика** | Пройдено диагностическое исследование, результат верифицирован |
| **Подписчики** | Medical AI, Clinical Care, Billing |

```json
{
  "eventType": "DiagnosticStudyCompleted",
  "studyId": "uuid",
  "patientId": "uuid",
  "episodeId": "uuid",
  "studyType": "mri | blood_test | xray",
  "resultSummary": "string",
  "dataRef": "encrypted-ref-to-internal-storage"
}
```

*`dataRef` — ссылка для AI-контекста, не бинарные данные в Kafka.*

---

## Medical AI

### `AIAnalysisCompleted`

| Поле | Значение |
| --- | --- |
| **Источник** | Medical AI |
| **Семантика** | ИИ завершил анализ исследования |
| **Подписчики** | Clinical Care (врачу в UI), Analytics (метрики качества модели) |

```json
{
  "eventType": "AIAnalysisCompleted",
  "jobId": "uuid",
  "studyId": "uuid",
  "patientId": "uuid",
  "modelVersion": "v2.3.1",
  "confidence": 0.94,
  "findingCode": "string"
}
```

---

### `TreatmentPlanRecommended`

| Поле | Значение |
| --- | --- |
| **Источник** | Medical AI |
| **Семантика** | Сформирована рекомендация по лечению (не назначение) |
| **Подписчики** | Clinical Care |

```json
{
  "eventType": "TreatmentPlanRecommended",
  "jobId": "uuid",
  "episodeId": "uuid",
  "recommendationId": "uuid",
  "priority": "routine | urgent"
}
```

---

## Retail Banking & Lending

### `CreditAgreementCreated`

| Поле | Значение |
| --- | --- |
| **Источник** | Lending |
| **Семантика** | Создан кредитный договор |
| **Подписчики** | Retail Banking, Analytics, Identity (KYC audit) |

```json
{
  "eventType": "CreditAgreementCreated",
  "agreementId": "uuid",
  "customerId": "uuid",
  "amount": 500000,
  "currency": "RUB",
  "termMonths": 36,
  "status": "draft | active"
}
```

---

### `LoanDisbursed`

| Поле | Значение |
| --- | --- |
| **Источник** | Lending |
| **Семантика** | Кредитные средства выданы на счёт |
| **Подписчики** | Retail Banking, Analytics |

```json
{
  "eventType": "LoanDisbursed",
  "agreementId": "uuid",
  "accountId": "uuid",
  "amount": 500000,
  "disbursedAt": "2026-06-17T12:00:00Z"
}
```

---

### `PaymentReceived`

| Поле | Значение |
| --- | --- |
| **Источник** | Retail Banking |
| **Семантика** | Зафиксирован входящий платёж |
| **Подписчики** | Billing, Lending (погашение), Analytics |

```json
{
  "eventType": "PaymentReceived",
  "paymentId": "uuid",
  "accountId": "uuid",
  "amount": 15000,
  "currency": "RUB",
  "referenceType": "invoice | loan_repayment",
  "referenceId": "uuid"
}
```

---

## Billing

### `InvoiceIssued`

| Поле | Значение |
| --- | --- |
| **Источник** | Billing |
| **Семантика** | Выставлен счёт за мед. услуги |
| **Подписчики** | Retail Banking (ожидание оплаты), Analytics, Patient (уведомление через gateway) |

```json
{
  "eventType": "InvoiceIssued",
  "invoiceId": "uuid",
  "patientId": "uuid",
  "totalAmount": 12500,
  "currency": "RUB",
  "dueDate": "2026-07-01"
}
```

---

## Inventory & Partner Commerce

### `InventoryReserved`

| Поле | Значение |
| --- | --- |
| **Источник** | Inventory & Supply |
| **Семантика** | Зарезервированы расходники/оборудование |
| **Подписчики** | Clinical Care, Partner Commerce |

```json
{
  "eventType": "InventoryReserved",
  "skuId": "string",
  "warehouseId": "string",
  "quantity": 10,
  "reservationId": "uuid",
  "reason": "procedure | partner_order"
}
```

---

### `PartnerOrderPlaced`

| Поле | Значение |
| --- | --- |
| **Источник** | Partner Commerce |
| **Семантика** | Партнёр (фарма/оборудование) принял заказ |
| **Подписчики** | Inventory, Clinical Care, Analytics |

```json
{
  "eventType": "PartnerOrderPlaced",
  "orderId": "uuid",
  "partnerId": "string",
  "partnerType": "pharma | equipment",
  "items": [{"skuId": "string", "qty": 5}],
  "expectedDelivery": "2026-06-25"
}
```

---

## Identity

### `KYCCompleted`

| Поле | Значение |
| --- | --- |
| **Источник** | Identity & Customer Master |
| **Семантика** | Клиент прошёл проверку для фин. услуг |
| **Подписчики** | Lending, Retail Banking |

```json
{
  "eventType": "KYCCompleted",
  "customerId": "uuid",
  "patientId": "uuid",
  "kycLevel": "standard | enhanced",
  "completedAt": "2026-06-17T09:00:00Z"
}
```

---

## Таблица «источник → подписчики»

| Событие | Источник | Подписчики |
| --- | --- | --- |
| `PatientRegistered` | Patient Mgmt | Identity, Analytics |
| `AppointmentScheduled` | Clinical Care | Workforce, Analytics, Billing |
| `MedicalEncounterCompleted` | Clinical Care | Diagnostics, Billing, Medical AI, Analytics |
| `DiagnosticStudyCompleted` | Diagnostics | Medical AI, Clinical Care, Billing |
| `AIAnalysisCompleted` | Medical AI | Clinical Care, Analytics |
| `TreatmentPlanRecommended` | Medical AI | Clinical Care |
| `CreditAgreementCreated` | Lending | Banking, Analytics |
| `LoanDisbursed` | Lending | Banking, Analytics |
| `PaymentReceived` | Banking | Billing, Lending, Analytics |
| `InvoiceIssued` | Billing | Banking, Analytics |
| `PartnerOrderPlaced` | Partner Commerce | Inventory, Analytics |
| `InventoryReserved` | Inventory | Clinical Care |

---

## Правила публикации

1.  Событие неизменяемо (append-only); отмена — новое компенсирующее событие (`InvoiceCancelled`).
2.  `eventId` + `idempotencyKey` для идемпотентных consumer’ов.
3.  Версия схемы в Schema Registry; backward-compatible изменения только.
4.  PHI/PCI — только ссылки (`dataRef`), не payload в топиках аналитики.
5.  Топики именуются: `{domain}.{eventType}.v{major}` (например, `lending.CreditAgreementCreated.v1`).
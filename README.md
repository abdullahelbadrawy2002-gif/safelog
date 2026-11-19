# SafeLog

SafeLog is a small mobile app that helps a small organisation record and track security incidents, such as phishing emails or lost devices.

It was built for **CN5009 Mental Wealth: Professional Life 2 – Project Phase 1 (Technical Development Evidence)** by Abdallah Adel Ahmed Elbadrawy.

## Features

| Requirement | How SafeLog does it |
|---|---|
| Data validation | Every field is checked before saving: title length and allowed characters, description length, severity, status, and no future dates. |
| Database operations | Create, read, update and delete (CRUD) incidents. |
| Local storage | Data is stored on the device with SQLite, so the app works offline. |
| Responsive interface | One list on phones; list and details side by side on tablets (width ≥ 720 px). |
| Security | All queries are parameterised (`?` placeholders) to prevent SQL injection. The database also has CHECK constraints. |

## Project structure

```
lib/
  main.dart                        App start and theme (light and dark)
  models/incident.dart             Incident data model
  validators.dart                  All input validation rules
  data/incident_db.dart            SQLite database (CRUD + search)
  screens/incident_list_screen.dart  List, search, details, responsive layout
  screens/incident_form_screen.dart  Create / edit form with validation
test/
  validators_test.dart             Unit tests for validation rules
  incident_db_test.dart            Database tests (CRUD, SQL injection, constraints)
  widget_test.dart                 Form tests (error messages on screen)
```

## Database design

One table, `incidents`:

| Field | Type | Rule |
|---|---|---|
| id | INTEGER | Primary key |
| title | TEXT | Required, 3 to 60 characters |
| description | TEXT | Optional, up to 500 characters |
| severity | TEXT | Low, Medium, High or Critical |
| date | TEXT | Date of the incident (not in the future) |
| status | TEXT | Open or Closed |

## How to run

You need [Flutter](https://docs.flutter.dev/get-started/install) installed.

```bash
# 1. Inside this folder, add the Android/iOS platform files (only the first time)
flutter create .

# 2. Download the packages
flutter pub get

# 3. Run the tests
flutter test

# 4. Run the app (with a phone or emulator connected)
flutter run
```

## Test plan

| Test case | Input | Expected result |
|---|---|---|
| Empty title | (blank) | Error: "Please enter a title" |
| Short title | ab | Error: "Title must be at least 3 characters" |
| Script injection (title) | `<script>alert(1)</script>` | Input rejected |
| SQL injection (title) | `x'; DROP TABLE incidents;--` | Input rejected |
| SQL injection (search) | `' OR 1=1 --` | Treated as normal text; no extra records shown |
| Future date | Tomorrow's date | Error: "The date cannot be in the future" |
| CRUD operations | Valid incident data | Records created, updated and deleted |
| Persistence | Close and reopen the app | Data is still stored |
| Responsive layout | Tablet screen width | Two-panel layout displayed |

## Code review note

The first version of the search function built the SQL query by inserting the user's text directly into the string:

```dart
db.rawQuery("SELECT * FROM incidents WHERE title LIKE '%$search%'");
```

Typing `' OR 1=1 --` would return every record (OWASP A03:2021 Injection). The final version uses a parameterised query:

```dart
db.query('incidents', where: 'title LIKE ?', whereArgs: ['%$text%']);
```

## Planned for Phase 2

- Encrypt the local database
- PIN protection to open the app

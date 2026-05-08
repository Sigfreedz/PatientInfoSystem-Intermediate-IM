# 🏥 Patient Info System - Intermediate IM Final Project
Diagnostic Clinic Database & CRUD Interface

## ️ Tech Stack
- **DBMS:** MySQL (XAMPP)
- **Backend/UI**: Python (Flask) + Jinja templates
- **Version Control:** GitHub

## 📥 Setup Instructions
1. Install [XAMPP](https://www.apachefriends.org/) (Apache + MySQL + phpMyAdmin)
2. Start Apache & MySQL in XAMPP Control Panel
3. Open `http://localhost/phpmyadmin`
4. Click **Import** → Choose `database/schema.sql` → Click **Go**
5. Click **Import** again → Choose `database/seed.sql` → Click **Go**
6. Verify: Browse `patients` table → should show 20 records

## ▶️ Run the UI
1. Install Python 3.8+ (Python 3.10+ recommended since 3.8/3.9 are end-of-life) from https://www.python.org/downloads/.
2. Install dependencies:
   - `pip install Flask PyMySQL`
3. From the repo root, run:
   - `python app.py`
4. Open `http://localhost:5000` in your browser.

## 👥 Team Roles & Tasks
| Member | Responsibility |
|--------|----------------|
| [Name] | Database Design, Normalization, SQL Queries |
| [Name] | UI |
| [Name] | Documentation, ERD, Presentation |

## 📋 Rubric Alignment
- ✅ 6 Tables (5–8 required) | ✅ UNF→3NF Normalization | ✅ 20+ Records/Table
- ✅ 20 SQL Queries (JOIN, Aggregate, Subquery, UPDATE, DELETE)
- ✅ Full CRUD Interface | ✅ Documentation & 5–10 min Demo

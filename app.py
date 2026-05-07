from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
import pymysql
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'your_secret_key_here'

DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'patient_db',
    'cursorclass': pymysql.cursors.DictCursor
}

def get_db_connection():
    return pymysql.connect(**DB_CONFIG)

@app.route('/')
def menu():
    return render_template('menu.html')

@app.route('/patient-info')
def patient_info():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Get all patients with their test history
            sql = """
                SELECT p.*, 
                       GROUP_CONCAT(DISTINCT t.test_name) as tests_taken,
                       MAX(o.order_date) as last_visit
                FROM patients p
                LEFT JOIN test_orders o ON p.patient_id = o.patient_id
                LEFT JOIN test_catalog t ON o.test_id = t.test_id
                GROUP BY p.patient_id
                ORDER BY p.last_name
            """
            cursor.execute(sql)
            patients = cursor.fetchall()
        return render_template('patient_info.html', patients=patients)
    finally:
        conn.close()

@app.route('/billing/<patient_id>')
def billing(patient_id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            # Get patient info
            cursor.execute("SELECT * FROM patients WHERE patient_id = %s", (patient_id,))
            patient = cursor.fetchone()
            
            # Get all orders for this patient
            sql = """
                SELECT o.order_id, o.order_date, t.test_name, t.price
                FROM test_orders o
                JOIN test_catalog t ON o.test_id = t.test_id
                WHERE o.patient_id = %s
                ORDER BY o.order_date
            """
            cursor.execute(sql, (patient_id,))
            orders = cursor.fetchall()
            
            # Calculate total
            total = sum(order['price'] for order in orders)
            
        return render_template('billing.html', patient=patient, orders=orders, total=total,current_date=datetime.now())
    finally:
        conn.close()

@app.route('/cbc-records')
def cbc_records():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                SELECT p.patient_id, CONCAT(p.first_name, ' ', p.last_name) as name,
                       o.order_date, c.*
                FROM cbc_results c
                JOIN test_orders o ON c.order_id = o.order_id
                JOIN patients p ON o.patient_id = p.patient_id
                ORDER BY o.order_date
            """
            cursor.execute(sql)
            cbc_records = cursor.fetchall()
        return render_template('cbc_records.html', records=cbc_records)
    finally:
        conn.close()

@app.route('/cbc-result/<int:order_id>')
def cbc_result(order_id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                SELECT p.patient_id, p.first_name, p.last_name, p.age, o.order_date, c.*
                FROM cbc_results c
                JOIN test_orders o ON c.order_id = o.order_id
                JOIN patients p ON o.patient_id = p.patient_id
                WHERE c.order_id = %s
            """
            cursor.execute(sql, (order_id,))
            result = cursor.fetchone()
        return render_template('cbc_result.html', result=result)
    finally:
        conn.close()

@app.route('/urinalysis-records')
def urinalysis_records():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                SELECT p.patient_id, CONCAT(p.first_name, ' ', p.last_name) as name,
                       o.order_date, u.*
                FROM urinalysis_results u
                JOIN test_orders o ON u.order_id = o.order_id
                JOIN patients p ON o.patient_id = p.patient_id
                ORDER BY o.order_date
            """
            cursor.execute(sql)
            records = cursor.fetchall()
        return render_template('urinalysis_records.html', records=records)
    finally:
        conn.close()

@app.route('/ua-result/<int:order_id>')
def ua_result(order_id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                SELECT p.patient_id, p.first_name, p.last_name, p.age, o.order_date, u.*
                FROM urinalysis_results u
                JOIN test_orders o ON u.order_id = o.order_id
                JOIN patients p ON o.patient_id = p.patient_id
                WHERE u.order_id = %s
            """
            cursor.execute(sql, (order_id,))
            result = cursor.fetchone()
        return render_template('ua_result.html', result=result)
    finally:
        conn.close()

@app.route('/fecalysis-records')
def fecalysis_records():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                SELECT p.patient_id, CONCAT(p.first_name, ' ', p.last_name) as name,
                       o.order_date, f.*
                FROM fecalysis_results f
                JOIN test_orders o ON f.order_id = o.order_id
                JOIN patients p ON o.patient_id = p.patient_id
                ORDER BY o.order_date
            """
            cursor.execute(sql)
            records = cursor.fetchall()
        return render_template('fecalysis_records.html', records=records)
    finally:
        conn.close()

@app.route('/fa-result/<int:order_id>')
def fa_result(order_id):
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
                SELECT p.patient_id, p.first_name, p.last_name, p.age, o.order_date, f.*
                FROM fecalysis_results f
                JOIN test_orders o ON f.order_id = o.order_id
                JOIN patients p ON o.patient_id = p.patient_id
                WHERE f.order_id = %s
            """
            cursor.execute(sql, (order_id,))
            result = cursor.fetchone()
        return render_template('fa_result.html', result=result)
    finally:
        conn.close()

@app.route('/patients/add', methods=['GET', 'POST'])
def add_patient():
    if request.method == 'POST':
        patient_id = request.form['patient_id']
        first_name = request.form['first_name']
        last_name = request.form['last_name']
        age = request.form['age']
        sex = request.form['sex']
        address = request.form['address']
        contact = request.form['contact']

        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                sql = """INSERT INTO patients (patient_id, first_name, last_name, age, sex, address, contact)
                         VALUES (%s, %s, %s, %s, %s, %s, %s)"""
                cursor.execute(sql, (patient_id, first_name, last_name, age, sex, address, contact))
                conn.commit()
            flash('Patient added successfully!', 'success')
            return redirect(url_for('patient_info'))
        except Exception as e:
            flash(f'Error: {str(e)}', 'danger')
        finally:
            conn.close()
    return render_template('add_patient.html')

@app.route('/add-order', methods=['GET', 'POST'])
def add_order():
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT patient_id, CONCAT(first_name, ' ', last_name) as full_name FROM patients ORDER BY last_name")
            patients = cursor.fetchall()
            cursor.execute("SELECT test_id, test_name FROM test_catalog WHERE test_name IN ('CBC', 'URINALYSIS', 'FECALYSIS')")
            tests = cursor.fetchall()

        if request.method == 'POST':
            patient_id = request.form['patient_id']
            test_id = request.form['test_id']
            order_date = request.form['order_date']

            with conn.cursor() as cursor:
                cursor.execute("INSERT INTO test_orders (patient_id, test_id, order_date, status) VALUES (%s, %s, %s, 'COMPLETED')",
                               (patient_id, test_id, order_date))
                order_id = cursor.lastrowid
                conn.commit()

            test_name = next(t['test_name'] for t in tests if t['test_id'] == int(test_id))
            return redirect(url_for('add_result', order_id=order_id, test_type=test_name))

        return render_template('add_order.html', patients=patients, tests=tests)
    finally:
        conn.close()

@app.route('/add-result/<int:order_id>/<test_type>', methods=['GET', 'POST'])
def add_result(order_id, test_type):
    conn = get_db_connection()
    try:
        if request.method == 'POST':
            with conn.cursor() as cursor:
                if test_type == 'CBC':
                    fields = ['wbc', 'rbc', 'hemoglobin', 'hematocrit', 'platelets', 'mcv', 'mch', 'neutrophils', 'lymphocytes', 'monocytes', 'eosinophils', 'basophils']
                    values = [request.form.get(f, 0) for f in fields]
                    sql = f"INSERT INTO cbc_results (order_id, {', '.join(fields)}) VALUES (%s, {', '.join(['%s']*len(fields))})"
                elif test_type == 'URINALYSIS':
                    fields = ['appearance', 'color', 'ph', 'specific_gravity', 'glucose', 'protein', 'ketones', 'nitrites', 'other_findings']
                    values = [request.form.get(f, '') for f in fields]
                    sql = f"INSERT INTO urinalysis_results (order_id, {', '.join(fields)}) VALUES (%s, {', '.join(['%s']*len(fields))})"
                elif test_type == 'FECALYSIS':
                    fields = ['appearance', 'consistency', 'occult_blood', 'parasite_id', 'wbc', 'rbc', 'bacteria', 'other_findings']
                    values = [request.form.get(f, '') for f in fields]
                    sql = f"INSERT INTO fecalysis_results (order_id, {', '.join(fields)}) VALUES (%s, {', '.join(['%s']*len(fields))})"
                
                cursor.execute(sql, [order_id] + values)
                conn.commit()
            flash('✅ Lab results added successfully!', 'success')
            return redirect(url_for('patient_info'))

        return render_template('add_result.html', order_id=order_id, test_type=test_type)
    finally:
        conn.close()

if __name__ == '__main__':
    app.run(debug=True)
-- =====================================================
-- PATIENT INFO SYSTEM - REQUIRED SQL QUERIES
-- Database: patient_db | Intermediate IM Final Project
-- =====================================================

-- =====================================================
-- SECTION 1: BASIC SELECT QUERIES (10 Required)
-- =====================================================

-- Q1: List all patients (Basic SELECT)
SELECT patient_id, first_name, last_name, age, sex, contact 
FROM patients 
ORDER BY last_name, first_name;

-- Q2: Find patients by age range (Advanced WHERE)
SELECT patient_id, CONCAT(first_name, ' ', last_name) AS full_name, age, address
FROM patients
WHERE age BETWEEN 20 AND 30
ORDER BY age;

-- Q3: Search patients by location (LIKE operator)
SELECT patient_id, first_name, last_name, address, contact
FROM patients
WHERE address LIKE '%Metro Manila%'
   OR address LIKE '%Cebu%'
   OR address LIKE '%Davao%';

-- Q4: List all available tests with prices (FROM test_catalog)
SELECT test_id, test_name, price, description
FROM test_catalog
ORDER BY price DESC;

-- Q5: Show test orders for a specific patient (Filter by patient_id)
SELECT order_id, patient_id, test_id, order_date, status
FROM test_orders
WHERE patient_id = 'PAT-004'
ORDER BY order_date DESC;

-- Q6: Display CBC results for completed orders only
SELECT c.cbc_id, c.order_id, c.hemoglobin, c.hematocrit, c.platelets
FROM cbc_results c
JOIN test_orders o ON c.order_id = o.order_id
WHERE o.status = 'COMPLETED'
ORDER BY c.hemoglobin DESC;

-- Q7: Find patients who had Urinalysis with abnormal protein levels
SELECT p.patient_id, CONCAT(p.first_name, ' ', p.last_name) AS patient_name, 
       u.ph, u.protein, u.other_findings
FROM urinalysis_results u
JOIN test_orders o ON u.order_id = o.order_id
JOIN patients p ON o.patient_id = p.patient_id
WHERE u.protein != 'Negative'
ORDER BY u.protein;

-- Q8: List all fecalysis results with parasite detection
SELECT p.first_name, p.last_name, f.appearance, f.parasite_id, f.other_findings
FROM fecalysis_results f
JOIN test_orders o ON f.order_id = o.order_id
JOIN patients p ON o.patient_id = p.patient_id
WHERE f.parasite_id != 'None'
ORDER BY f.parasite_id;

-- Q9: Show pending or cancelled orders (Status filter)
SELECT o.order_id, p.first_name, p.last_name, t.test_name, o.order_date, o.status
FROM test_orders o
JOIN patients p ON o.patient_id = p.patient_id
JOIN test_catalog t ON o.test_id = t.test_id
WHERE o.status IN ('PENDING', 'CANCELLED')
ORDER BY o.order_date;

-- Q10: Get patient registration timeline (Date functions)
SELECT patient_id, CONCAT(first_name, ' ', last_name) AS patient_name, 
       DATE(registered_at) AS reg_date, 
       DATE_FORMAT(registered_at, '%M %Y') AS reg_month
FROM patients
ORDER BY registered_at;


-- =====================================================
-- SECTION 2: JOIN QUERIES (3 Required)
-- =====================================================

-- Q11: JOIN - Patient + Order + Test Type (3-table JOIN)
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    t.test_name,
    t.price,
    o.order_date,
    o.status
FROM patients p
INNER JOIN test_orders o ON p.patient_id = o.patient_id
INNER JOIN test_catalog t ON o.test_id = t.test_id
ORDER BY o.order_date DESC;

-- Q12: JOIN - Order + CBC Results + Patient Info
SELECT 
    o.order_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    o.order_date,
    c.wbc, c.rbc, c.hemoglobin, c.platelets
FROM test_orders o
INNER JOIN patients p ON o.patient_id = p.patient_id
INNER JOIN cbc_results c ON o.order_id = c.order_id
WHERE c.hemoglobin < 13.0  -- Flag low hemoglobin
ORDER BY c.hemoglobin;

-- Q13: JOIN - Full Patient Diagnostic Summary (4-table JOIN)
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    t.test_name,
    o.order_date,
    CASE 
        WHEN t.test_name = 'CBC' THEN CONCAT('Hgb: ', c.hemoglobin, ' g/dL')
        WHEN t.test_name = 'URINALYSIS' THEN CONCAT('Protein: ', u.protein)
        WHEN t.test_name = 'FECALYSIS' THEN CONCAT('Parasite: ', f.parasite_id)
        ELSE 'N/A'
    END AS key_result
FROM patients p
JOIN test_orders o ON p.patient_id = o.patient_id
JOIN test_catalog t ON o.test_id = t.test_id
LEFT JOIN cbc_results c ON o.order_id = c.order_id
LEFT JOIN urinalysis_results u ON o.order_id = u.order_id
LEFT JOIN fecalysis_results f ON o.order_id = f.order_id
ORDER BY p.patient_id, o.order_date;


-- =====================================================
-- SECTION 3: AGGREGATE QUERIES (2 Required: SUM, AVG, COUNT)
-- =====================================================

-- Q14: AGGREGATE - Total revenue by test type (SUM + GROUP BY)
SELECT 
    t.test_name,
    COUNT(o.order_id) AS times_ordered,
    SUM(t.price) AS total_revenue
FROM test_catalog t
JOIN test_orders o ON t.test_id = o.test_id
GROUP BY t.test_id, t.test_name
ORDER BY total_revenue DESC;

-- Q15: AGGREGATE - Average lab values by patient demographic (AVG + COUNT)
SELECT 
    p.sex,
    COUNT(DISTINCT p.patient_id) AS patient_count,
    AVG(c.hemoglobin) AS avg_hemoglobin,
    AVG(c.platelets) AS avg_platelets,
    ROUND(AVG(c.wbc), 2) AS avg_wbc
FROM patients p
JOIN test_orders o ON p.patient_id = o.patient_id
JOIN cbc_results c ON o.order_id = c.order_id
GROUP BY p.sex;


-- =====================================================
-- SECTION 4: SUBQUERIES (2 Required)
-- =====================================================

-- Q16: SUBQUERY - Patients who had CBC but NOT Urinalysis
SELECT patient_id, CONCAT(first_name, ' ', last_name) AS patient_name
FROM patients
WHERE patient_id IN (
    SELECT DISTINCT patient_id 
    FROM test_orders 
    WHERE test_id = (SELECT test_id FROM test_catalog WHERE test_name = 'CBC')
)
AND patient_id NOT IN (
    SELECT DISTINCT patient_id 
    FROM test_orders 
    WHERE test_id = (SELECT test_id FROM test_catalog WHERE test_name = 'URINALYSIS')
)
ORDER BY patient_id;

-- Q17: SUBQUERY - Find most expensive test ordered per patient
SELECT 
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    (SELECT MAX(t.price) 
     FROM test_orders o2 
     JOIN test_catalog t ON o2.test_id = t.test_id 
     WHERE o2.patient_id = p.patient_id) AS max_test_price
FROM patients p
WHERE EXISTS (
    SELECT 1 FROM test_orders o3 WHERE o3.patient_id = p.patient_id
)
ORDER BY max_test_price DESC;


-- =====================================================
-- SECTION 5: UPDATE QUERIES (2 Required)
-- =====================================================

-- Q18: UPDATE - Change patient contact number
UPDATE patients
SET contact = '09179998888',
    address = 'Updated: Makati City, Metro Manila'
WHERE patient_id = 'PAT-001';

-- Verify the update:
SELECT patient_id, first_name, last_name, contact, address 
FROM patients WHERE patient_id = 'PAT-001';

-- Q19: UPDATE - Mark pending orders as completed
UPDATE test_orders
SET status = 'COMPLETED',
    created_at = CURRENT_TIMESTAMP
WHERE status = 'PENDING'
  AND order_date <= CURDATE() - INTERVAL 7 DAY;

-- Verify the update:
SELECT order_id, patient_id, status, order_date 
FROM test_orders 
WHERE status = 'COMPLETED' 
ORDER BY order_date DESC 
LIMIT 5;


-- =====================================================
-- SECTION 6: DELETE QUERIES (2 Required)
-- =====================================================

-- Q20: DELETE - Remove cancelled test orders (with CASCADE)
-- Note: Due to ON DELETE CASCADE, related results will auto-delete
DELETE FROM test_orders
WHERE status = 'CANCELLED';

-- Verify deletion:
SELECT COUNT(*) AS remaining_cancelled 
FROM test_orders 
WHERE status = 'CANCELLED';

-- Q21: DELETE - Remove test records for a specific patient (Soft delete alternative shown)
-- OPTION A: Hard delete (use with caution)
-- DELETE FROM test_orders WHERE patient_id = 'PAT-999';

-- OPTION B: Soft delete (recommended - just update status)
UPDATE test_orders
SET status = 'CANCELLED',
    created_at = CURRENT_TIMESTAMP
WHERE patient_id = 'PAT-999'  -- Non-existent ID, safe for demo
  AND order_date < '2023-01-01';

-- Verify: Show patient's order history
SELECT o.order_id, t.test_name, o.status, o.order_date
FROM test_orders o
JOIN test_catalog t ON o.test_id = t.test_id
WHERE o.patient_id = 'PAT-004'
ORDER BY o.order_date;

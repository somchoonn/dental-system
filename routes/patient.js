// routes/patient.js
const express = require('express');
const router = express.Router();
const db = require('../db');
const { allowRoles } = require('../utils/auth');

const fetchPatientId = async (req, res, next) => {
  try {
    if (!req.user || req.user.role !== 'patient') return next();
    const userId = req.user.id;
    const sql = `SELECT id FROM patients WHERE user_id = ?`;
    // ใช้ db.query() แทน db.get()
    const [rows] = await db.query(sql, [userId]);
    if (rows.length === 0) {
      console.error(`No patient record found for user_id: ${userId}`);
      return res.status(403).send('Access denied. No patient record associated with this account.');
    }
    // เพิ่ม patient_id ลงใน req.user
    req.user.patient_id = rows[0].id;
    next();
  } catch (err) {
    console.error('Database error while fetching patient ID:', err.message);
    return res.status(500).send('Server Error');
  }
};

router.use(fetchPatientId);

/* =========================================================================
   DASHBOARD: นัดหมายครั้งถัดไป
   ========================================================================= */
router.get('/dashboard', allowRoles('patient'), async (req, res, next) => {
  try {
    const patientId = req.user.patient_id;
    if (!patientId)
      return res.status(403).send('Could not identify patient account.');

    // ─────────────────────────────
    // Helper: แปลงวันที่ให้อยู่ในรูปแบบ YYYY-MM-DD HH:mm:ss
    // ─────────────────────────────
    function formatDate(dateStr, timeStr) {
  try {
    // ✅ ถ้าเป็น Date object → แปลงเป็น YYYY-MM-DD ก่อน
    if (dateStr instanceof Date) {
      const pad = n => n.toString().padStart(2, '0');
      dateStr = `${dateStr.getFullYear()}-${pad(dateStr.getMonth() + 1)}-${pad(dateStr.getDate())}`;
    }

    // ✅ ถ้าเป็น string → เอาเฉพาะส่วนวันที่ (กัน ISO format)
    if (typeof dateStr === 'string' && dateStr.includes('T')) {
      dateStr = dateStr.split('T')[0];
    }

    // ✅ แปลงเป็น datetime ที่แน่นอน
    const d = new Date(`${dateStr}T${timeStr}:00`);
    const pad = n => n.toString().padStart(2, '0');
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  } catch (e) {
    console.error('❌ formatDate error:', e.message);
    return `${dateStr} ${timeStr}:00`;
  }
}


    const apptSql = `
      SELECT 
        a.id,
        a.start_time,
        a.end_time,
        a.status,
        a.notes,
        CONCAT(d.first_name, ' ', d.last_name) AS dentist_name,
        du.unit_name AS unit_name,
        0 AS is_request
      FROM appointments a
      JOIN dentists d ON d.id = a.dentist_id
      LEFT JOIN dental_units du ON du.id = a.unit_id
      WHERE a.patient_id = ?
        AND a.start_time >= NOW()
        AND UPPER(a.status) IN ('PENDING','CONFIRMED')
      ORDER BY a.start_time ASC
      LIMIT 1;
    `;
    const [apptRows] = await db.query(apptSql, [patientId]);
    let appointmentOrRequest = apptRows.length > 0 ? apptRows[0] : null;

    if (!appointmentOrRequest) {
      const reqSql = `
        SELECT id, requested_date, requested_time_slot, treatment, notes, status
        FROM appointment_requests
        WHERE patient_id = ?
          AND requested_date >= CURDATE()
          AND UPPER(COALESCE(status,'NEW')) IN ('NEW','PENDING')
        ORDER BY requested_date ASC, requested_time_slot ASC
        LIMIT 1;
      `;
      const [reqRows] = await db.query(reqSql, [patientId]);

      if (reqRows.length > 0) {
        const reqRow = reqRows[0];
        let startTime = '00:00';
        let endTime = '00:00';

        if (reqRow.requested_time_slot) {
          const parts = reqRow.requested_time_slot.trim().split('-');
          startTime = parts[0]?.trim() || '00:00';
          endTime = parts[1]?.trim() || '00:00';
        }

        const start = formatDate(reqRow.requested_date, startTime);
        const end = formatDate(reqRow.requested_date, endTime);

        appointmentOrRequest = {
          id: reqRow.id,
          start_time: start,
          end_time: end,
          status: reqRow.status || 'PENDING',
          notes: reqRow.notes || `คำขอ: ${reqRow.treatment || ''}`,
          dentist_name: null,
          unit_name: null,
          is_request: 1
        };

        console.log('appointmentOrRequest:', appointmentOrRequest);
      }
    }


    let payment = null;
    try {
      const [cols] = await db.query(`SHOW COLUMNS FROM payments LIKE 'status';`);
      if (cols.length > 0) {
        const paymentSql = `
          SELECT p.*
          FROM payments p
          JOIN visits v ON p.visit_id = v.id
          WHERE v.patient_id = ? AND p.status = 'pending'
          ORDER BY COALESCE(p.payment_date, '0001-01-01') DESC, p.id DESC
          LIMIT 1;
        `;
        const [payRows] = await db.query(paymentSql, [patientId]);
        payment = payRows.length > 0 ? payRows[0] : null;
      } else {
        const paymentSql = `
          SELECT p.*
          FROM payments p
          JOIN visits v ON p.visit_id = v.id
          WHERE v.patient_id = ?
          ORDER BY COALESCE(p.payment_date, '0001-01-01') DESC, p.id DESC
          LIMIT 1;
        `;
        const [payRows] = await db.query(paymentSql, [patientId]);
        payment = payRows.length > 0 ? payRows[0] : null;
      }
    } catch (err) {
      console.warn('⚠️ Error checking payments:', err.message);
    }


    res.render('patient/dashboard', {
      user: req.user,
      userRole: req.user.role,
      page: 'dashboard',
      appointment: appointmentOrRequest,
      payment
    });

  } catch (err) {
    console.error('❌ Error in /patient/dashboard route:', err.message);
    next(err);
  }
});




async function hasColumn(tableName, columnName) {
  try {
    const [result] = await db.query(
      `SHOW COLUMNS FROM \`${tableName}\` LIKE ?`,
      [columnName]
    );
    return result.length > 0;
  } catch (err) {
    console.error('Error checking column:', err.message);
    return false;
  }
}
router.get('/payments', allowRoles('patient'), async (req, res, next) => {
  try {
    const patientId = req.user.patient_id;
    if (!patientId)
      return res.status(500).send('Could not identify patient.');

    const date_from = req.query.date_from || '';
    const date_to = req.query.date_to || '';
    const successMessage = req.query.success || '';

    // ---------- สร้าง WHERE clause ----------
    const whereClauses = ['v.patient_id = ?'];
    const params = [patientId];

    if (date_from) {
      whereClauses.push('DATE(p.payment_date) >= DATE(?)');
      params.push(date_from);
    }
    if (date_to) {
      whereClauses.push('DATE(p.payment_date) <= DATE(?)');
      params.push(date_to);
    }

    const whereSql = `WHERE ${whereClauses.join(' AND ')}`;

    // ---------- Query ----------
    const sql = `
      SELECT 
        p.id, 
        p.amount, 
        p.payment_date
        ${await hasColumn('payments', 'status') ? ', p.status' : ''} 
      FROM payments p
      JOIN visits v ON p.visit_id = v.id
      ${whereSql}
      ORDER BY COALESCE(p.payment_date, '0001-01-01') DESC, p.id DESC;
    `;

    const [rows] = await db.query(sql, params);

    res.render('patient/payments', {
      user: req.user,
      userRole: req.user.role,
      page: 'payments',
      payments: rows,
      date_from,
      date_to,
      successMessage
    });
  } catch (err) {
    console.error('Error in /payments route:', err.message);
    next(err);
  }
});


async function hasColumn(tableName, columnName) {
  try {
    const [result] = await db.query(
      `SHOW COLUMNS FROM \`${tableName}\` LIKE ?`,
      [columnName]
    );
    return result.length > 0;
  } catch (err) {
    console.error('Error checking column:', err.message);
    return false;
  }
}

router.post('/payments/:id/pay', allowRoles('patient'), async (req, res, next) => {
  try {
    const paymentId = req.params.id;
    const patientId = req.user.patient_id;

    // ตรวจสอบว่ารายการนี้เป็นของผู้ป่วยคนนี้จริงไหม
    const checkSql = `
      SELECT p.id ${await hasColumn('payments', 'status') ? ', p.status' : ''}
      FROM payments p
      JOIN visits v ON p.visit_id = v.id
      WHERE p.id = ? AND v.patient_id = ?;
    `;
    const [rows] = await db.query(checkSql, [paymentId, patientId]);

    if (rows.length === 0)
      return res.status(403).send('Forbidden: not your payment.');

    const payment = rows[0];

    if (payment.status && payment.status.toLowerCase() === 'paid') {
      const successMsg = encodeURIComponent('รายการนี้ชำระแล้วอยู่แล้ว');
      return res.redirect(`/patient/payments?success=${successMsg}`);
    }

    // อัปเดตสถานะเป็น "paid"
    let updSql;
    if (await hasColumn('payments', 'status')) {
      updSql = `
        UPDATE payments
        SET status = 'paid',
            payment_date = NOW()
        WHERE id = ?;
      `;
    } else {
      updSql = `
        UPDATE payments
        SET payment_date = NOW()
        WHERE id = ?;
      `;
    }

    await db.query(updSql, [paymentId]);

    const q = [];
    if (req.query.date_from)
      q.push(`date_from=${encodeURIComponent(req.query.date_from)}`);
    if (req.query.date_to)
      q.push(`date_to=${encodeURIComponent(req.query.date_to)}`);
    q.push(`success=${encodeURIComponent('ชำระเงินสำเร็จ')}`);

    const backUrl = `/patient/payments${q.length ? '?' + q.join('&') : ''}`;
    res.redirect(backUrl);

  } catch (err) {
    console.error('Error in /payments/:id/pay route:', err.message);
    next(err);
  }
});


/* =================== ฟอร์มขอนัด (ผู้ป่วยส่งคำขอ) =================== */
router.get('/patient_appointment', allowRoles('patient'), async (req, res, next) => {
  try {
    const patientId = req.user.patient_id;
    if (!patientId) {
      return res.status(403).send('Access denied. No patient record found.');
    }

    // ───────────────────────────────────────────────
    // 1) ดึงข้อมูลผู้ป่วย
    // ───────────────────────────────────────────────
    const patientSql = `
      SELECT pre_name, first_name, last_name, phone, email
      FROM patients
      WHERE id = ?
    `;
    const [patientRows] = await db.query(patientSql, [patientId]);
    const patient = patientRows.length > 0 ? patientRows[0] : null;

    // ───────────────────────────────────────────────
    // 2) ดึงรายการบริการ (procedure_codes)
    // ───────────────────────────────────────────────
    const servicesSql = `
      SELECT code, description, default_price, category
      FROM procedure_codes
      ORDER BY category, description
    `;
    const [services] = await db.query(servicesSql);

    // ───────────────────────────────────────────────
    // 3) จัดกลุ่มบริการตามหมวด
    // ───────────────────────────────────────────────
    const servicesByCategory = {};
    services.forEach(service => {
      if (!servicesByCategory[service.category]) {
        servicesByCategory[service.category] = [];
      }
      servicesByCategory[service.category].push(service);
    });

    // ───────────────────────────────────────────────
    // 4) แสดงผลใน EJS
    // ───────────────────────────────────────────────
    res.render('patient/patient_appointment', {
      user: req.user,
      userRole: req.user.role,
      page: 'patient_appointment',
      patient,
      servicesByCategory,
      services
    });
  } catch (err) {
    console.error('Error in /patient_appointment route:', err.message);
    next(err);
  }
});


/* =================== ผู้ป่วยส่งคำขอนัด =================== */
router.post('/appointment-request', allowRoles('patient'), async (req, res, next) => {
  try {
    const { requested_date, requested_time_slot, treatment, notes } = req.body;

    if (!requested_date || !requested_time_slot || !treatment) {
      return res.status(400).json({
        success: false,
        error: 'กรุณากรอกข้อมูลการนัดหมายให้ครบถ้วน'
      });
    }

    const patientId = req.user.patient_id;

    if (!patientId) {
      return res.status(400).json({
        success: false,
        error: 'ไม่พบข้อมูลผู้ป่วยในระบบ'
      });
    }

    //  Query MySQL ใช้ async/await
    const sql = `
      INSERT INTO appointment_requests (
        patient_id, requested_date, requested_time_slot, treatment, notes, status
      ) VALUES (?, ?, ?, ?, ?, 'NEW')
    `;
    const params = [patientId, requested_date, requested_time_slot, treatment, notes || null];

    const [result] = await db.query(sql, params);

    res.json({
      success: true,
      requestId: result.insertId, // ใช้ insertId ใน mysql2
      message: 'ส่งคำขอนัดหมายสำเร็จ'
    });

  } catch (err) {
    console.error('Database error creating appointment request:', err.message);
    res.status(500).json({
      success: false,
      error: 'เกิดข้อผิดพลาดในการบันทึกข้อมูล: ' + err.message
    });
  }
});


// เพิ่ม route สำหรับโหลดสถิติ
router.get('/dashboard-stats', allowRoles('patient'), async (req, res) => {
  try {
    const patientId = req.user.patient_id;
    if (!patientId) {
      return res.status(403).json({
        success: false,
        error: 'Access denied. No patient record found.'
      });
    }


    const totalAppointmentsSql = `
      SELECT COUNT(*) AS count
      FROM appointments
      WHERE patient_id = ?
    `;
    const [totalRows] = await db.query(totalAppointmentsSql, [patientId]);
    const totalAppointments = totalRows[0]?.count || 0;


    const completedAppointmentsSql = `
      SELECT COUNT(*) AS count
      FROM appointments
      WHERE patient_id = ? AND status = 'done'
    `;
    const [completedRows] = await db.query(completedAppointmentsSql, [patientId]);
    const completedAppointments = completedRows[0]?.count || 0;

    let pendingPayments = 0;
    const [statusColumn] = await db.query(
      "SHOW COLUMNS FROM payments LIKE 'status';"
    );

    if (statusColumn.length > 0) {
      const pendingPaymentsSql = `
        SELECT COUNT(*) AS count
        FROM payments p
        JOIN visits v ON p.visit_id = v.id
        WHERE v.patient_id = ? AND p.status = 'pending'
      `;
      const [pendingRows] = await db.query(pendingPaymentsSql, [patientId]);
      pendingPayments = pendingRows[0]?.count || 0;
    } else {
      const pendingPaymentsSql = `
        SELECT COUNT(*) AS count
        FROM payments p
        JOIN visits v ON p.visit_id = v.id
        WHERE v.patient_id = ?
      `;
      const [pendingRows] = await db.query(pendingPaymentsSql, [patientId]);
      pendingPayments = pendingRows[0]?.count || 0;
    }
    res.json({
      success: true,
      totalAppointments,
      completedAppointments,
      pendingPayments
    });

  } catch (error) {
    console.error('❌ Error loading dashboard stats:', error.message);
    res.status(500).json({
      success: false,
      error: 'เกิดข้อผิดพลาดในการโหลดสถิติ'
    });
  }
});



router.post('/appointment-requests/:id/cancel', allowRoles('patient'), async (req, res) => {
  try {
    const requestId = req.params.id;
    const patientId = req.user.patient_id;
    const checkSql = `
      SELECT id, status 
      FROM appointment_requests 
      WHERE id = ? AND patient_id = ?
    `;
    const [rows] = await db.query(checkSql, [requestId, patientId]);

    if (rows.length === 0) {
      return res.status(404).json({ success: false, error: 'ไม่พบคำขอนัดหมาย' });
    }

    const request = rows[0];

    if (request.status !== 'NEW' && request.status !== 'PENDING') {
      return res.status(400).json({
        success: false,
        error: 'ไม่สามารถยกเลิกคำขอในสถานะนี้ได้'
      });
    }

    const updateSql = `
      UPDATE appointment_requests 
      SET status = 'CANCELLED' 
      WHERE id = ?
    `;
    await db.query(updateSql, [requestId]);

    res.json({ success: true, message: 'ยกเลิกคำขอนัดหมายสำเร็จ' });

  } catch (err) {
    console.error('Error cancelling appointment request:', err.message);
    res.status(500).json({
      success: false,
      error: 'เกิดข้อผิดพลาดในการยกเลิกคำขอนัดหมาย: ' + err.message
    });
  }
});


router.get('/appointment-history', allowRoles('patient'), async (req, res) => {
  try {
    const patientId = req.user.patient_id;
    const limit = req.query.limit ? parseInt(req.query.limit) : null;

    let sql = `
      SELECT 
        id,
        requested_date,
        requested_time_slot,
        treatment,
        notes,
        status,
        created_at
      FROM appointment_requests
      WHERE patient_id = ?
      ORDER BY created_at DESC
    `;

    const params = [patientId];

    if (limit) {
      sql += ' LIMIT ?';
      params.push(limit);
    }

    const [requests] = await db.query(sql, params);

  
    if (limit) {
      return res.json({
        success: true,
        requests: requests
      });
    }


    res.render('patient/appointment_history', {
      user: req.user,
      userRole: req.user.role,
      page: 'appointment_history',
      requests
    });

  } catch (err) {
    console.error('Error fetching appointment history:', err.message);

    if (req.query.limit) {
      return res.status(500).json({
        success: false,
        error: 'เกิดข้อผิดพลาดในการโหลดข้อมูล'
      });
    }
    res.status(500).send('เกิดข้อผิดพลาดในการโหลดข้อมูล');
  }
});


router.post('/appointments/:id/reschedule', allowRoles('patient'), async (req, res) => {
  try {
    const apptId = req.params.id;
    const patientId = req.user.patient_id;
    const { requested_date, requested_time_slot, notes } = req.body || {};

    if (!requested_date || !requested_time_slot) {
      return res.status(400).json({
        success: false,
        error: 'กรุณาเลือกวันและช่วงเวลาใหม่'
      });
    }

    const checkSql = `
      SELECT 
        a.id, a.patient_id, a.status, a.start_time, a.notes,
        CONCAT(d.first_name, ' ', d.last_name) AS dentist_name
      FROM appointments a
      LEFT JOIN dentists d ON d.id = a.dentist_id
      WHERE a.id = ? AND a.patient_id = ?
    `;
    const [apptRows] = await db.query(checkSql, [apptId, patientId]);

    if (apptRows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'ไม่พบนัดของคุณ'
      });
    }

    const appt = apptRows[0];
    const allowed = ['PENDING', 'CONFIRMED'];
    const nowOk = new Date(appt.start_time) > new Date();

    if (!allowed.includes(String(appt.status).toUpperCase())) {
      return res.status(400).json({
        success: false,
        error: 'ไม่สามารถเลื่อนนัดสถานะนี้ได้'
      });
    }

    if (!nowOk) {
      return res.status(400).json({
        success: false,
        error: 'เลยเวลาเริ่มนัดแล้ว ไม่สามารถเลื่อนได้'
      });
    }


    const cancelSql = `UPDATE appointments SET status = 'cancelled' WHERE id = ?`;
    await db.query(cancelSql, [apptId]);

    const reqSql = `
      INSERT INTO appointment_requests (
        patient_id, requested_date, requested_time_slot, treatment, notes, status
      ) VALUES (?, ?, ?, ?, ?, 'NEW')
    `;
    const treatmentText = 'เลื่อนนัดจากคิวเดิม';
    const noteAll = [
      (notes || '').trim(),
      appt.dentist_name ? `ต้องการพบ: ${appt.dentist_name}` : '',
      appt.notes ? `หมายเหตุเดิม: ${appt.notes}` : ''
    ]
      .filter(Boolean)
      .join(' | ');

    const [insertResult] = await db.query(reqSql, [
      patientId,
      requested_date,
      requested_time_slot,
      treatmentText,
      noteAll || null
    ]);


    res.json({
      success: true,
      message: 'เลื่อนนัดสำเร็จ เปิดคำขอใหม่แล้ว',
      requestId: insertResult.insertId
    });

  } catch (err) {
    console.error('Error rescheduling appointment:', err.message);
    res.status(500).json({
      success: false,
      error: 'เกิดข้อผิดพลาดในการเลื่อนนัด: ' + err.message
    });
  }
});


module.exports = router;

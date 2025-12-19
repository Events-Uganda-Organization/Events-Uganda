import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

admin.initializeApp();

// Gmail SMTP configuration
const gmailEmail = 'alvin69david@gmail.com';
const gmailAppPassword = 'amvy yccv mjhx bhwb';

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  auth: {
    user: gmailEmail,
    pass: gmailAppPassword,
  },
});

// Firestore trigger - send email when document added to 'mail' collection
export const sendOTPEmail = functions.firestore
  .document('mail/{mailId}')
  .onCreate(async (snap) => {
    const data = snap.data();
    const to = data.to;
    const subject = data.message?.subject || 'Events Uganda';
    const html = data.message?.html || '';

    if (!to || typeof to !== 'string') {
      console.error("Missing or invalid 'to' field in mail document", data);
      await snap.ref.update({
        delivery: {
          state: 'ERROR',
          error: "Missing or invalid 'to' field",
          time: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
      return null;
    }

    try {
      // Verify SMTP connection before sending
      await transporter.verify();
      console.log('SMTP connection verified for Gmail');

      await transporter.sendMail({
        from: `Events Uganda <${gmailEmail}>`,
        to: to,
        subject: subject,
        html: html,
      });

      console.log(`Email sent to ${to}`);

      // Mark as delivered
      await snap.ref.update({
        delivery: {
          state: 'SUCCESS',
          time: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
    } catch (error) {
      console.error('Error sending email:', error);

      // Mark as failed
      await snap.ref.update({
        delivery: {
          state: 'ERROR',
          error: String(error),
          time: admin.firestore.FieldValue.serverTimestamp(),
        },
      });
    }

    return null;
  });

// Test endpoint to queue a test email to Firestore
export const testSendEmail = functions.https.onRequest(async (req, res) => {
  try {
    const to = (req.query.to as string) || 'alvin69david@gmail.com';
    const subject =
      (req.query.subject as string) || 'Test Email - Events Uganda';
    const html =
      (req.query.html as string) ||
      '<div style="font-family: Arial, sans-serif; padding: 16px;"><h2>Test Email</h2><p>This is a test email from Events Uganda.</p></div>';

    await admin.firestore().collection('mail').add({
      to,
      message: {subject, html},
    });

    res.status(200).send(`Queued email to ${to}`);
  } catch (err) {
    console.error('Failed to queue test email:', err);
    res.status(500).send('Failed to queue test email');
  }
});

export const ping = functions.https.onRequest((req, res) => {
  res.status(200).send('ok');
});

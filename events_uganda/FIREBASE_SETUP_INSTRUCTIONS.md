# Firebase OTP Setup Instructions

## 1. Firebase Phone Authentication Setup (SMS OTP)

### Enable Phone Authentication in Firebase Console:

1. Go to Firebase Console → Authentication → Sign-in method
2. Enable "Phone" provider
3. Add your SHA-1 and SHA-256 keys for Android:
   ```bash
   cd android
   ./gradlew signingReport
   ```
4. Copy the SHA keys to Firebase Console → Project Settings → Your apps

### Test Phone Auth:

- Firebase provides test phone numbers in development
- For production, SMS charges apply after free tier

---

## 2. Email OTP Setup Using Cloud Functions

### Install Firebase CLI:

```bash
npm install -g firebase-tools
firebase login
```

### Initialize Cloud Functions:

```bash
cd events_uganda
firebase init functions
```

Select:

- TypeScript or JavaScript
- Install dependencies

### Create Email OTP Cloud Function:

Create `functions/src/index.ts` (or `index.js`):

```typescript
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

admin.initializeApp();

// Configure email transporter (using Gmail example)
const transporter = nodemailer.createTransporter({
  service: "gmail",
  auth: {
    user: "your-email@gmail.com",
    pass: "your-app-password", // Use App Password, not regular password
  },
});

// Trigger when OTP document is created
export const sendOTPEmail = functions.firestore
  .document("otp_codes/{email}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const email = data.email;
    const otp = data.otp;

    const mailOptions = {
      from: "Events Uganda <your-email@gmail.com>",
      to: email,
      subject: "Your OTP Code - Events Uganda",
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>Password Reset OTP</h2>
          <p>Your OTP code is:</p>
          <h1 style="color: #D59A00; letter-spacing: 5px;">${otp}</h1>
          <p>This code will expire in 10 minutes.</p>
          <p>If you didn't request this, please ignore this email.</p>
          <br>
          <p>Best regards,<br>Events Uganda Team</p>
        </div>
      `,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log("OTP email sent to:", email);
    } catch (error) {
      console.error("Error sending email:", error);
    }
  });
```

### Install Dependencies:

```bash
cd functions
npm install nodemailer
npm install --save-dev @types/nodemailer
```

### Deploy Cloud Function:

```bash
firebase deploy --only functions
```

---

## 3. Alternative: Use Firebase Extensions

### Easier Option - Trigger Email Extension:

1. Go to Firebase Console → Extensions
2. Install "Trigger Email" extension
3. Configure SendGrid, Mailgun, or SMTP settings
4. Update Firestore trigger collection to `mail`

### Update Flutter code to use extension:

```dart
await _firestore.collection('mail').add({
  'to': email,
  'message': {
    'subject': 'Your OTP Code - Events Uganda',
    'html': '''
      <h2>Password Reset OTP</h2>
      <p>Your OTP code is: <strong>$otp</strong></p>
      <p>This code will expire in 10 minutes.</p>
    ''',
  },
});
```

---

## 4. SendGrid Setup (Recommended for Production)

### Create SendGrid Account:

1. Go to https://sendgrid.com
2. Create free account (100 emails/day free)
3. Get API key from Settings → API Keys

### Update Cloud Function:

```typescript
import * as sgMail from "@sendgrid/mail";

sgMail.setApiKey("YOUR_SENDGRID_API_KEY");

export const sendOTPEmail = functions.firestore
  .document("otp_codes/{email}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const msg = {
      to: data.email,
      from: "noreply@eventsuganda.com",
      subject: "Your OTP Code",
      html: `<h1>Your OTP: ${data.otp}</h1>`,
    };

    await sgMail.send(msg);
  });
```

---

## 5. Security Rules for Firestore

Add to `firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /otp_codes/{email} {
      // Only allow creation
      allow create: if true;
      // Allow read/delete only by authenticated users
      allow read, delete: if request.auth != null;
      // Deny updates
      allow update: if false;
    }
  }
}
```

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

---

## 6. Testing

### Test Phone OTP:

- Enter Ugandan phone: `0783546565` or `+256783546565`
- Check SMS for 6-digit code
- Enter code in OTP screen

### Test Email OTP:

- Enter email: `test@example.com`
- Check console for OTP (or email if Cloud Function is deployed)
- Enter 4-digit code in OTP screen

---

## 7. Production Checklist

- [ ] Remove `print('OTP for $email: $otp')` from code
- [ ] Deploy Cloud Functions for email
- [ ] Configure proper email sender (no-reply@yourdomain.com)
- [ ] Set up email templates with your branding
- [ ] Add rate limiting for OTP requests
- [ ] Monitor Firebase usage and costs
- [ ] Test on real devices
- [ ] Add analytics for OTP success/failure rates

---

## Need Help?

- Firebase Auth Docs: https://firebase.google.com/docs/auth
- Cloud Functions: https://firebase.google.com/docs/functions
- SendGrid Docs: https://docs.sendgrid.com

require('dotenv').config();
const express = require('express');
const africastalking = require('africastalking')({
  apiKey: process.env.AT_API_KEY,
  username: process.env.AT_USERNAME
});
const app = express();
app.use(express.json());

const otpStore = {}; // In-memory store for demo

// Send OTP endpoint
app.post('/send-otp', async (req, res) => {
  const { phone } = req.body;
  const otp = Math.floor(100000 + Math.random() * 900000); // 6-digit OTP
  otpStore[phone] = otp;

  try {
    await africastalking.SMS.send({
      to: [phone],
      message: `Your OTP is: ${otp}`
    });
    res.json({ success: true, message: 'OTP sent!' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Verify OTP endpoint
app.post('/verify-otp', (req, res) => {
  const { phone, otp } = req.body;
  if (otpStore[phone] && otpStore[phone] == otp) {
    delete otpStore[phone];
    res.json({ success: true, message: 'OTP verified!' });
  } else {
    res.status(400).json({ success: false, error: 'Invalid OTP' });
  }
});

app.listen(3000, () => console.log('Server running on port 3000'));
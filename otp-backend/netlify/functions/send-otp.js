const africastalking = require("africastalking")({
  apiKey: process.env.AT_API_KEY,
  username: process.env.AT_USERNAME,
});

exports.handler = async function (event, context) {
  const { phone } = JSON.parse(event.body);
  const otp = Math.floor(1000 + Math.random() * 9000); // 4-digit OTP

  // For demo: use Netlify's in-memory context (not persistent, use DB for production)
  // You can use FaunaDB, DynamoDB, or Netlify's environment variables for storage in production

  try {
    await africastalking.SMS.send({
      to: [phone],
      message: `Your OTP is: ${otp}`,
    });
    return {
      statusCode: 200,
      body: JSON.stringify({ success: true, message: "OTP sent!" }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ success: false, error: err.message }),
    };
  }
};

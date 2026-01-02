importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js");

// Initialize Firebase in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyBw7LZQY4Y4z4z4z4z4z4z4z4z4z4z4z4",
  authDomain: "events-uganda.firebaseapp.com",
  projectId: "events-uganda",
  storageBucket: "events-uganda.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcd1234"
});

// Get messaging instance
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log("Received background message ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/icon-192x192.png"
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});

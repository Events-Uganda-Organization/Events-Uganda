importScripts(
  "https://www.gstatic.com/firebasejs/9.10.0/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/9.10.0/firebase-messaging-compat.js"
);

// Initialize Firebase in the service worker
if (!firebase.apps.length) {
  firebase.initializeApp({});
}

// Get messaging instance
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function (payload) {
  console.log("Received background message ", payload);
  const notificationTitle = payload.notification?.title || "New Notification";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/icon-192x192.png",
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});
    notificationTitle,
    notificationOptions
  );
});

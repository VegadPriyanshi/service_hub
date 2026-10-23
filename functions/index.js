
const { setGlobalOptions } = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

setGlobalOptions({ maxInstances: 5 });

/**
 * Send a push notification to all registered devices of a user.
 */
async function sendUserNotification(userId, title, body, data = {}) {
  if (!userId) {
    logger.warn("Notification skipped: missing user ID.");
    return;
  }

  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    logger.warn("Notification skipped: user profile not found.", {
      userId,
    });
    return;
  }

  const tokens = userDoc.get("fcmTokens");

  if (!Array.isArray(tokens) || tokens.length === 0) {
    logger.info("Notification skipped: no FCM tokens found.", {
      userId,
    });
    return;
  }

  const validTokens = [
    ...new Set(
      tokens.filter(
        (token) => typeof token === "string" && token.length > 0,
      ),
    ),
  ];

  if (validTokens.length === 0) return;

  const response = await messaging.sendEachForMulticast({
    tokens: validTokens,
    notification: {
      title,
      body,
    },
    data: Object.fromEntries(
      Object.entries(data).map(([key, value]) => [
        key,
        String(value),
      ]),
    ),
    android: {
      priority: "high",
      notification: {
        channelId: "default",
      },
    },
  });

  logger.info("Push notification send result.", {
    userId,
    successCount: response.successCount,
    failureCount: response.failureCount,
  });

  // Remove invalid or expired tokens.
  const invalidTokens = [];

  response.responses.forEach((result, index) => {
    if (
      !result.success &&
      result.error &&
      [
        "messaging/invalid-registration-token",
        "messaging/registration-token-not-registered",
      ].includes(result.error.code)
    ) {
      invalidTokens.push(validTokens[index]);
    }
  });

  if (invalidTokens.length > 0) {
    await userRef.update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(
        ...invalidTokens,
      ),
    });
  }
}

/**
 * Notify the provider when a new booking is created.
 */
exports.notifyProviderOnNewBooking = onDocumentCreated(
  "bookings/{bookingId}",
  async (event) => {
    const booking = event.data?.data();

    if (!booking) return;

    if (!booking.providerId) {
      logger.warn("New booking has no provider ID.", {
        bookingId: event.params.bookingId,
      });
      return;
    }

    await sendUserNotification(
      booking.providerId,
      "New Service Booking",
      `You have a new ${booking.serviceName || "service"} booking request.`,
      {
        type: "new_booking",
        bookingId: event.params.bookingId,
      },
    );
  },
);

/**
 * Notify the customer when a booking status changes.
 */
exports.notifyCustomerOnBookingStatusChange = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Avoid notifications if the status has not changed.
    if (before.status === after.status) return;

    const statusMessages = {
      accepted: {
        title: "Booking Accepted",
        body: "Your service booking has been accepted by the provider.",
      },
      rejected: {
        title: "Booking Rejected",
        body: "Your service booking was rejected by the provider.",
      },
      completed: {
        title: "Service Completed",
        body: "Your service booking has been marked as completed.",
      },
    };

    const notification = statusMessages[after.status];

    // Ignore statuses that do not need a notification.
    if (!notification) return;

    if (!after.customerId) {
      logger.warn("Booking has no customer ID.", {
        bookingId: event.params.bookingId,
      });
      return;
    }

    await sendUserNotification(
      after.customerId,
      notification.title,
      notification.body,
      {
        type: "booking_status",
        bookingId: event.params.bookingId,
        status: after.status,
      },
    );
  },
);

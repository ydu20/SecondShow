/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {initializeApp} = require("firebase-admin/app");
const {
  onDocumentWritten,
  onDocumentCreated,
} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {error} = require("firebase-functions/logger");

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

exports.sendRecentMessageNotification = onDocumentWritten(
    "/recent_messages/{userEmail}/messages/{recentMessage}",
    async (event) => {
      const rmDoc = event.data.after.data();

      const userRef = db.collection("users").doc(event.params.userEmail);
      const userDoc = await userRef.get();
      if (userDoc.exists && userDoc.data().fcm_token) {
        const notification = {
          title: rmDoc.counterpartyUsername,
          body: rmDoc.message,
        };

        const message = {
          token: userDoc.data().fcm_token,
          notification: notification,
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        };

        messaging.send(message)
            .catch((err) => {
              error("Error sending recent message notification", err);
            });
      }
    },
);

exports.sendNewListingNotification = onDocumentCreated(
    "/events/{eventId}/listings/{newListing}",
    async (event) => {
      if (!event.data) return;
      const listingDoc = event.data.data();
      const subscribersRef = db
          .collection("events")
          .doc(event.params.eventId)
          .collection("subscribers");
      const subscribers = await subscribersRef.get();
      const notification = {
        title: `New Listing for ${listingDoc.eventName}`,
        body: `Open the app to check it out!`,
      };

      subscribers.forEach((doc) => {
        db.collection("users").doc(doc.id).get()
            .then((userDoc) => {
              if (userDoc.exists && userDoc.data().fcm_token) {
                console.log("Token!", userDoc.data().fcm_token);
                const message = {
                  token: userDoc.data().fcm_token,
                  notification: notification,
                  apns: {
                    payload: {
                      aps: {
                        sound: "default",
                      },
                    },
                  },
                };

                messaging.send(message)
                    .catch((err) => {
                      error("Error broadcasting new listing", err);
                    });
              }
            })
            .catch((err) => {
              error("Error broadcasting new listing", err);
            });
      });
    },
);

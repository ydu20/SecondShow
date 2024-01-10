/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const admin = require("firebase-admin");
const {
  onDocumentWritten,
  onDocumentCreated,
  onDocumentDeleted,
} = require("firebase-functions/v2/firestore");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {error} = require("firebase-functions/logger");
const functions = require("firebase-functions");

admin.initializeApp();
const db = getFirestore();
const messaging = getMessaging();

exports.removeUserAuth = onDocumentDeleted(
    "/users/{userEmail}", async (event) => {
      const rmDoc = event.data.data();
      const uid = rmDoc.uid;
      console.log(uid);

      admin.auth().deleteUser(uid)
          .catch((err) => {
            console.error("Error deleting user: ", error);
          });
    },
);

exports.updateExpiredListings = functions.pubsub.schedule("5 0 * * *")
    .timeZone("America/New_York")
    .onRun(async (context) => {
      console.log("EXECUTING UPDATE_EXPIRED_LISTINGS");
      console.log("TIME: " + context.timestamp);

      const currDay = new Date(context.timestamp);
      const prevDay = new Date(currDay.getTime() - (24 * 60 * 60 * 1000));

      const year = prevDay.getFullYear();
      const month = prevDay.getMonth() + 1;
      const day = prevDay.getDate();

      const formattedMonth = month < 10 ? `0${month}` : month;
      const formattedDay = day < 10 ? `0${day}` : day;

      const expireDateStr = `${year}-${formattedMonth}-${formattedDay}`;

      console.log("Expiry date: " + expireDateStr);

      const rmSnapshot = await db
          .collectionGroup("user_recent_messages")
          .get();

      rmSnapshot.forEach((doc) => {
        if (doc.id.startsWith(expireDateStr)) {
          doc.ref.update({expired: true});
        }
      });

      const userListingsSnapshot = await db
          .collectionGroup("user_listings")
          .get();

      userListingsSnapshot.forEach((doc) => {
        if (doc.id.startsWith(expireDateStr)) {
          doc.ref.update({expired: true});
        }
      });
    });


exports.sendRecentMessageNotification = onDocumentWritten(
    "/recent_messages/{userEmail}/user_recent_messages/{recentMessage}",
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
    "/events/{eventId}/event_listings/{newListing}",
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

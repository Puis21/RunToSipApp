/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.


// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {setGlobalOptions} = require("firebase-functions/v2/options");
const {initializeApp} = require("firebase-admin/app");
const admin = require("firebase-admin");

initializeApp();

setGlobalOptions({maxInstances: 10});

exports.notifyNewRun = onDocumentCreated("runs/{runId}", async (event) => {
  const runData = event.data;
  const runId = event.params.runId;

  const payload = {
    notification: {
      title: "🏃 New Run Available!",
      body: runData.title || "A new run has been posted",
    },
    data: {
      runId,
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
    topic: "all_users",
  };

  try {
    await admin.messaging().send(payload);
    console.log("Notification sent for run:", runId);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
});

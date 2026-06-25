const admin = require("firebase-admin");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const { createInterviewProxyHandler } = require("./openrouterProxy");

admin.initializeApp();

const openRouterApiKey = defineSecret("OPENROUTER_API_KEY");

exports.interview = onRequest(
  {
    cors: true,
    secrets: [openRouterApiKey],
    timeoutSeconds: 90,
  },
  createInterviewProxyHandler({
    apiKeyProvider: () => openRouterApiKey.value(),
    verifyIdToken: (token) => admin.auth().verifyIdToken(token),
  }),
);

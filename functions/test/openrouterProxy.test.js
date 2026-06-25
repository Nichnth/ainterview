const assert = require("node:assert/strict");
const { test } = require("node:test");

const { createInterviewProxyHandler } = require("../src/openrouterProxy");

test("requires a Firebase bearer token before calling OpenRouter", async () => {
  let openRouterCalled = false;
  const handler = createInterviewProxyHandler({
    apiKeyProvider: () => "openrouter-key",
    verifyIdToken: async () => ({ uid: "user_1" }),
    fetchImpl: async () => {
      openRouterCalled = true;
      return jsonResponse(200, {});
    },
  });
  const res = createResponse();

  await handler(
    createRequest({
      path: "/start",
      body: { level: "Junior Dev", stage: "HR", language: "English" },
    }),
    res,
  );

  assert.equal(res.statusCode, 401);
  assert.equal(res.body.code, "AUTH_REQUIRED");
  assert.equal(openRouterCalled, false);
});

test("sends start prompts to OpenRouter with the server-side API key", async () => {
  let verifiedToken;
  let openRouterRequest;
  const handler = createInterviewProxyHandler({
    apiKeyProvider: () => "openrouter-key",
    modelIds: ["openrouter/free"],
    verifyIdToken: async (token) => {
      verifiedToken = token;
      return { uid: "user_1" };
    },
    fetchImpl: async (url, options) => {
      openRouterRequest = { url, options };
      return jsonResponse(200, {
        choices: [{ message: { content: "Opening question" } }],
      });
    },
  });
  const res = createResponse();

  await handler(
    createRequest({
      path: "/start",
      headers: { authorization: "Bearer firebase-id-token" },
      body: { level: "Junior Dev", stage: "HR", language: "English" },
    }),
    res,
  );

  const requestBody = JSON.parse(openRouterRequest.options.body);
  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body, { text: "Opening question" });
  assert.equal(verifiedToken, "firebase-id-token");
  assert.equal(
    openRouterRequest.options.headers.Authorization,
    "Bearer openrouter-key",
  );
  assert.equal(requestBody.model, "openrouter/free");
  assert.equal(requestBody.messages[0].role, "system");
  assert.match(requestBody.messages[0].content, /AI interviewer/);
});

test("discovers free OpenRouter text models before using the default model list", async () => {
  const requestedUrls = [];
  const requestedModels = [];
  const handler = createInterviewProxyHandler({
    apiKeyProvider: () => "openrouter-key",
    verifyIdToken: async () => ({ uid: "user_1" }),
    fetchImpl: async (url, options) => {
      requestedUrls.push(String(url));
      if (options.method === "GET") {
        return jsonResponse(200, {
          data: [
            freeTextModel("free-text-one:free"),
            freeTextModel("free-text-two"),
            {
              id: "paid-text-model",
              pricing: { prompt: "0.000001", completion: "0" },
              architecture: {
                input_modalities: ["text"],
                output_modalities: ["text"],
              },
            },
            {
              id: "free-image-model:free",
              pricing: { prompt: "0", completion: "0" },
              architecture: {
                input_modalities: ["image"],
                output_modalities: ["image"],
              },
            },
          ],
        });
      }

      const requestBody = JSON.parse(options.body);
      requestedModels.push(requestBody.model);
      if (requestBody.model === "free-text-one:free") {
        return jsonResponse(429, { error: { message: "Rate limited" } });
      }

      return jsonResponse(200, {
        choices: [{ message: { content: "Fallback free response" } }],
      });
    },
  });
  const res = createResponse();

  await handler(
    createRequest({
      path: "/start",
      headers: { authorization: "Bearer firebase-id-token" },
      body: { level: "Junior Dev", stage: "HR", language: "English" },
    }),
    res,
  );

  assert.equal(res.statusCode, 200);
  assert.deepEqual(res.body, { text: "Fallback free response" });
  assert.match(requestedUrls[0], /\/api\/v1\/models/);
  assert.deepEqual(requestedModels, ["free-text-one:free", "free-text-two"]);
});

test("falls back to the next OpenRouter model when the first model fails", async () => {
  const requestedModels = [];
  const handler = createInterviewProxyHandler({
    apiKeyProvider: () => "openrouter-key",
    modelIds: ["first-model", "second-model"],
    verifyIdToken: async () => ({ uid: "user_1" }),
    fetchImpl: async (_url, options) => {
      const body = JSON.parse(options.body);
      requestedModels.push(body.model);
      if (body.model === "first-model") {
        return jsonResponse(429, { error: { message: "Rate limited" } });
      }

      return jsonResponse(200, {
        choices: [{ message: { content: "Fallback response" } }],
      });
    },
  });
  const res = createResponse();

  await handler(
    createRequest({
      path: "/reply",
      headers: { authorization: "Bearer firebase-id-token" },
      body: {
        level: "Senior Dev",
        stage: "Technical",
        language: "English",
        messages: [
          {
            sender: "user",
            text: "I use tests around retry behavior.",
            createdAt: "2026-06-24T00:00:00.000Z",
          },
        ],
      },
    }),
    res,
  );

  assert.equal(res.statusCode, 200);
  assert.deepEqual(requestedModels, ["first-model", "second-model"]);
  assert.deepEqual(res.body, { text: "Fallback response" });
});

test("returns normalized review JSON from prose-wrapped OpenRouter content", async () => {
  const handler = createInterviewProxyHandler({
    apiKeyProvider: () => "openrouter-key",
    now: () => new Date("2026-06-24T01:00:00.000Z"),
    verifyIdToken: async () => ({ uid: "user_1" }),
    fetchImpl: async () => {
      return jsonResponse(200, {
        choices: [
          {
            message: {
              content:
                'Here is the JSON:\n{"summary":"Good","communicationFeedback":"Clear","technicalFeedback":"Specific","improvementAreas":["Depth"],"recommendations":[{"title":"Practice testing","description":"Explain tests."}]}\nDone.',
            },
          },
        ],
      });
    },
  });
  const res = createResponse();

  await handler(
    createRequest({
      path: "/review",
      headers: { authorization: "Bearer firebase-id-token" },
      body: {
        level: "Junior Dev",
        stage: "Technical",
        language: "English",
        messages: [
          {
            sender: "user",
            text: "I test API failure handling.",
            createdAt: "2026-06-24T00:00:00.000Z",
          },
        ],
      },
    }),
    res,
  );

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.review.level, "junior");
  assert.equal(res.body.review.stage, "technical");
  assert.equal(res.body.review.language, "english");
  assert.equal(res.body.review.createdAt, "2026-06-24T01:00:00.000Z");
  assert.equal(res.body.review.summary, "Good");
  assert.equal(res.body.review.recommendations[0].id, "recommendation_1");
});

function createRequest({ path, headers = {}, body }) {
  return {
    method: "POST",
    path,
    headers,
    body,
  };
}

function createResponse() {
  return {
    statusCode: 200,
    headers: {},
    body: undefined,
    set(name, value) {
      this.headers[name] = value;
      return this;
    },
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
    end() {
      return this;
    },
  };
}

function jsonResponse(status, body) {
  return {
    status,
    ok: status >= 200 && status < 300,
    async json() {
      return body;
    },
    async text() {
      return JSON.stringify(body);
    },
  };
}

function freeTextModel(id) {
  return {
    id,
    pricing: { prompt: "0", completion: "0" },
    architecture: {
      input_modalities: ["text"],
      output_modalities: ["text"],
    },
  };
}

# Feature Request: Reliable API Client

We need a way to make our API calls more reliable. Some of our downstream services are flaky and return 500s or 503s occasionally.

I want a utility function that can wrap any async call and retry it if it fails. It should probably use some kind of backoff strategy so we don't spam the services when they are already struggling.

I started a stub in `src/retry.js` but I'm not sure what the parameters should be. Please finish it.

# Send your first request with ApiLens

<div align="center">
  <img src="../../assets/apilens_icon.svg" alt="ApiLens Icon" width="128" />
</div>

This guide will walk you through sending your first API request in ApiLens.
It only takes 5 minutes.

---

## Step 1: Launch ApiLens
Launch ApiLens. You’ll see an empty workspace ready for your first request.

![Launch](../assets/getting-started/01_launch.png)

---

## Step 2: Create a workgroup
Create a new group to manage your project.
1. Click **New Workgroup**(`+`) in the sidebar.
2. Enter a group name (e.g., `My First Project`).

![Create Workgroup](../assets/getting-started/02_create_workgroup.png)

---

## Step 3: Create a new request
1. Click the **New Request** button at the top.
2. Select **HTTP / REST**.

![New Request](../assets/getting-started/03_new_request.png)

---

## Step 4: Enter the request details
Let's call a simple health check API.
1. **Method**: Set to `GET`.
2. **URL**: Enter `https://api.apilens.dev/health`.

![Enter URL](../assets/getting-started/04_enter_url.png)

---

## Step 5: Send the request
Ready? Click the **Send** button.

![Send](../assets/getting-started/05_send_request.png)

---

## Step 6: View the response
Check the results in the bottom panel.
1. **Status Code**: Verify you see `200 OK`.
2. **Body**: The JSON response is displayed as a tree view.

![Response](../assets/getting-started/06_view_response.png)

---

## Step 7: Save the request
Save your successful request for later.
1. Press `Ctrl+S` (macOS: `Cmd+S`) or click the save icon.
2. Enter a name (e.g., `Health Check`) and save it to the Workgroup you just created.

![Save](../assets/getting-started/07_save_request.png)

---

## What’s next?
Congratulations! You've successfully sent your first request.
Now, explore the next steps:

- **OpenAPI Import**: Import existing API specs in one go.
- **Workflow**: Connect multiple requests to automate scenarios.
- **WebSocket / GraphQL**: Explore different protocols.

![Next](../assets/getting-started/08_next_steps.png)

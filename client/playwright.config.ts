import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "html",
  use: {
    baseURL: "http://localhost:5173",
    screenshot: "on",
    video: "retain-on-failure",
    ...devices["iPhone 13"],
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["iPhone 13"], browserName: "chromium" },
    },
  ],
  webServer: {
    command: "npm run dev -w client",
    cwd: "..",
    url: "http://localhost:5173",
    reuseExistingServer: !process.env.CI,
  },
});
